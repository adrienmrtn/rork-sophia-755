import Foundation
import Observation

/// Le catalogue de cours, en ligne : ce que l'app sait des cours d'une langue (`CatalogSnapshot`),
/// d'où ça vient, et comment ça se met à jour.
///
/// Trois couches, dans l'ordre où elles sont consultées :
/// 1. la mémoire (un snapshot par langue, les paquets de cours déjà décodés) ;
/// 2. le cache disque dans Application Support/Catalog (exclu des sauvegardes) : le dernier
///    manifeste, les trois fichiers de la langue (catalogue, quiz, glossaire) et un paquet par
///    cours téléchargé ;
/// 3. le pack de départ embarqué (`Resources/StarterPack/<lang>/`) : le catalogue complet de la
///    langue et les 40 premiers cours du Parcours, pour que l'app ait toujours quelque chose à
///    montrer, même sans réseau et avant le premier rafraîchissement.
///
/// Le manifeste (`catalog-manifest?lang=xx`) est relu au lancement et toutes les six heures
/// (`app_config.catalog.refresh_hours`) ; un fichier n'est téléchargé que si son hash a changé,
/// et un paquet de cours au moment où le lecteur en a besoin (`ensureContent`) ou en avance
/// (`prefetch`). Les API synchrones des anciens chargeurs (`ContentCatalog`, `CourseContentStore`,
/// `LocalizedContentLoader`, `AuthorStore`…) lisent le snapshot : elles n'attendent jamais le réseau.
@Observable
final class CatalogStore {
    static let shared = CatalogStore()

    /// Incrémenté à chaque nouveau snapshot : une vue qui le lit se redessine quand le
    /// catalogue change (fichiers mis à jour, paquet téléchargé qui apporte un quiz).
    private(set) var version = 0
    private(set) var isRefreshing = false
    private(set) var config = CatalogRemoteConfig()
    /// Les événements éditoriaux du dernier manifeste lu (disque ou réseau), du plus ancien au
    /// plus récent. `CampaignStore` les sert aux vues ; observable, donc elles se redessinent
    /// quand un rafraîchissement en apporte.
    private(set) var campaigns: [Campaign] = []
    /// Les tendances du dernier manifeste de chaque langue (ids de cours, les plus lus en premier).
    private(set) var trendingByLanguage: [String: [String]] = [:]

    private var snapshots: [AppLanguage: CatalogSnapshot] = [:]
    private var manifests: [AppLanguage: CatalogManifest] = [:]
    private var bundles: [String: CourseBundle] = [:]
    private var missingBundles: Set<String> = []
    private var downloads: [String: Task<CourseBundle?, Never>] = [:]
    private var lastRefresh: [String: Date]
    private var etags: [String: String]

    private static let lastRefreshKey = "sophia_catalog_last_refresh"
    private static let etagKey = "sophia_catalog_etags"
    private static let configKey = "sophia_catalog_config"
    static let bucket = "course-content"

    private init() {
        lastRefresh = (UserDefaults.standard.dictionary(forKey: Self.lastRefreshKey) as? [String: Double] ?? [:])
            .mapValues { Date(timeIntervalSince1970: $0) }
        etags = UserDefaults.standard.dictionary(forKey: Self.etagKey) as? [String: String] ?? [:]
        if let data = UserDefaults.standard.data(forKey: Self.configKey),
           let saved = try? JSONDecoder().decode(CatalogRemoteConfig.self, from: data) {
            config = saved
        }
    }

    // MARK: - Lecture

    /// Le catalogue d'une langue, construit à la demande depuis le disque ou le pack de départ.
    func snapshot(for language: AppLanguage) -> CatalogSnapshot {
        if let snapshot = snapshots[language] { return snapshot }
        let snapshot = buildSnapshot(for: language)
        snapshots[language] = snapshot
        return snapshot
    }

    /// Le contenu d'un cours s'il est déjà sur le téléphone (disque ou pack de départ) ; sinon nil,
    /// et c'est `ensureContent` qui ira le chercher.
    func localContent(courseId: String, language: AppLanguage) -> CourseContentV2? {
        localBundle(courseId: courseId, language: language)?.content
    }

    func hasLocalContent(courseId: String, language: AppLanguage) -> Bool {
        localBundle(courseId: courseId, language: language) != nil
    }

    /// La couverture d'un cours d'après le catalogue (pour un cours arrivé en ligne après le build,
    /// absent de la carte embarquée `CourseImageMap`).
    func coverSlug(courseId: String, language: AppLanguage = AppLanguage.currentPersisted()) -> String? {
        snapshot(for: language).entryById[courseId]?.cover
    }

    /// Les crédits d'images connus localement pour un cours (paquet téléchargé ou embarqué).
    func credits(courseId: String, language: AppLanguage) -> [String: ImageCredit] {
        localBundle(courseId: courseId, language: language)?.credits ?? [:]
    }

    /// Oublie les snapshots : ils seront reconstruits à la prochaine lecture (changement de langue,
    /// fichiers mis à jour). Les paquets déjà décodés restent valables.
    func resetMemory() {
        snapshots.removeAll()
        version += 1
    }

    /// Ce qu'affiche la ligne « Catalogue » des réglages développeur.
    func debugSummary(language: AppLanguage) -> String {
        let snapshot = snapshot(for: language)
        let local = snapshot.courses.filter { hasLocalContent(courseId: $0.id, language: language) }.count
        let since: String
        if let date = lastRefresh[language.rawValue] {
            let minutes = Int(Date().timeIntervalSince(date) / 60)
            since = minutes < 60 ? "\(minutes) min" : "\(minutes / 60) h"
        } else {
            since = "—"
        }
        return "\(snapshot.courses.count) cours · \(local) sur le téléphone · \(snapshot.source.label) · maj \(since)"
    }

    // MARK: - Contenu à la demande

    /// Le contenu d'un cours, téléchargé s'il le faut. Rend la copie locale tout de suite quand
    /// il y en a une (et rafraîchit en arrière-plan si le manifeste annonce une version plus
    /// récente) ; sinon attend le réseau. Nil : hors ligne et jamais téléchargé.
    func ensureContent(courseId: String, language: AppLanguage) async -> CourseContentV2? {
        if let local = localBundle(courseId: courseId, language: language) {
            if let wanted = manifests[language]?.courses[courseId]?.hash, wanted != local.hash {
                Task { _ = await download(courseId: courseId, language: language) }
            }
            return local.content
        }
        guard config.enabled else { return nil }
        if manifests[language] == nil {
            await refresh(language: language, force: false)
        }
        return await download(courseId: courseId, language: language)?.content
    }

    /// Télécharge en avance les paquets qui manquent (les premières cartes du fil, les cours
    /// d'une collection), sans bloquer personne.
    func prefetch(courseIds: [String], language: AppLanguage = AppLanguage.currentPersisted()) {
        guard config.enabled else { return }
        let missing = courseIds.filter { !hasLocalContent(courseId: $0, language: language) }.prefix(8)
        guard !missing.isEmpty else { return }
        Task {
            if manifests[language] == nil { await refresh(language: language, force: false) }
            for courseId in missing {
                _ = await download(courseId: courseId, language: language)
            }
        }
    }

    // MARK: - Rafraîchissement

    /// Au lancement et au retour au premier plan : relit le manifeste si le dernier date de plus
    /// de `refresh_hours` (six heures par défaut), ou s'il n'y en a jamais eu pour cette langue.
    func refreshIfNeeded(language: AppLanguage) async {
        if manifests[language] == nil, let saved = readManifestFromDisk(language) {
            adopt(saved, for: language)
        }
        if let last = lastRefresh[language.rawValue], manifests[language] != nil,
           Date().timeIntervalSince(last) < config.refreshHours * 3_600 {
            return
        }
        await refresh(language: language, force: false)
    }

    /// Relit la configuration distante puis le manifeste ; télécharge les fichiers de la langue
    /// dont le hash a changé. Le manifeste porte un ETag : rien n'a bougé, la réponse est un 304.
    func refresh(language: AppLanguage, force: Bool) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        await loadRemoteConfig()
        if manifests[language] == nil, let saved = readManifestFromDisk(language) {
            adopt(saved, for: language)
        }
        guard config.enabled, let url = Self.manifestURL(language: language) else { return }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 20
        request.setValue(AppConfig.SUPABASE_ANON_KEY, forHTTPHeaderField: "apikey")
        if !force, let etag = etags[language.rawValue], manifests[language] != nil {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        guard let result = try? await URLSession.shared.data(for: request),
              let http = result.1 as? HTTPURLResponse else { return }
        let data = result.0
        if http.statusCode == 304 {
            markRefreshed(language)
            return
        }
        guard http.statusCode == 200, let manifest = try? JSONDecoder().decode(CatalogManifest.self, from: data) else { return }
        adopt(manifest, for: language)
        write(data, language: language, name: "manifest.json")
        if let etag = http.value(forHTTPHeaderField: "ETag") {
            etags[language.rawValue] = etag
            UserDefaults.standard.set(etags, forKey: Self.etagKey)
        }

        var hashes = readHashes(language)
        var changed = false
        for kind in ["catalog", "quizzes", "glossary"] {
            guard let entry = manifest.files[kind], hashes[kind] != entry.hash,
                  let fileURL = entry.downloadURL,
                  let fileData = await fetch(fileURL),
                  Self.looksValid(kind: kind, data: fileData) else { continue }
            write(fileData, language: language, name: "\(kind).json")
            hashes[kind] = entry.hash
            changed = true
        }
        if changed {
            writeHashes(hashes, language: language)
            snapshots[language] = nil
            version += 1
        }
        markRefreshed(language)
    }

    /// Changement de langue dans les réglages : le snapshot de la nouvelle langue se construit à
    /// la lecture ; on lance tout de suite le rafraîchissement pour elle.
    func languageDidChange(to language: AppLanguage) {
        Task { await refreshIfNeeded(language: language) }
    }

    private func markRefreshed(_ language: AppLanguage) {
        lastRefresh[language.rawValue] = Date()
        UserDefaults.standard.set(lastRefresh.mapValues { $0.timeIntervalSince1970 }, forKey: Self.lastRefreshKey)
    }

    /// `app_config` → `catalog`. Une erreur réseau garde la dernière valeur connue.
    private func loadRemoteConfig() async {
        guard let base = URL(string: AppConfig.SUPABASE_URL) else { return }
        var components = URLComponents(url: base.appendingPathComponent("rest/v1/app_config"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "key", value: "eq.catalog"), URLQueryItem(name: "select", value: "value")]
        guard let url = components?.url else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue(AppConfig.SUPABASE_ANON_KEY, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(AppConfig.SUPABASE_ANON_KEY)", forHTTPHeaderField: "Authorization")
        struct Row: Decodable { let value: CatalogRemoteConfig }
        guard let result = try? await URLSession.shared.data(for: request),
              (result.1 as? HTTPURLResponse)?.statusCode == 200,
              let rows = try? JSONDecoder().decode([Row].self, from: result.0),
              let value = rows.first?.value else { return }
        config = value
        if let encoded = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(encoded, forKey: Self.configKey)
        }
    }

    // MARK: - Téléchargement des paquets

    private func download(courseId: String, language: AppLanguage) async -> CourseBundle? {
        let key = Self.key(courseId, language)
        if let running = downloads[key] { return await running.value }
        let task = Task<CourseBundle?, Never> { [self] in
            guard let entry = manifests[language]?.courses[courseId],
                  let url = entry.downloadURL,
                  let data = await fetch(url),
                  let bundle = try? JSONDecoder().decode(CourseBundle.self, from: data) else { return nil }
            write(data, language: language, name: "courses/\(courseId).json")
            bundles[key] = bundle
            missingBundles.remove(key)
            return bundle
        }
        downloads[key] = task
        let result = await task.value
        downloads[key] = nil
        // Le paquet apporte le quiz d'un cours qui n'en avait pas encore : le snapshot le reflète.
        if result != nil, snapshots[language]?.courseById[courseId]?.quiz.isEmpty == true {
            snapshots[language] = nil
            version += 1
        }
        return result
    }

    private func fetch(_ url: URL) async -> Data? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        guard let result = try? await URLSession.shared.data(for: request),
              (result.1 as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return result.0
    }

    // MARK: - Construction du snapshot

    private func buildSnapshot(for language: AppLanguage) -> CatalogSnapshot {
        let decoder = JSONDecoder()
        var file: CatalogFile?
        var source = CatalogSnapshot.Source.empty
        if let data = readDisk(language, "catalog.json"), let decoded = try? decoder.decode(CatalogFile.self, from: data) {
            file = decoded
            source = .disk
        } else if let data = readStarter(language, "catalog.json"), let decoded = try? decoder.decode(CatalogFile.self, from: data) {
            file = decoded
            source = .starterPack
        }
        guard let file else { return CatalogSnapshot(language: language, source: .empty) }

        let quizzes = readDisk(language, "quizzes.json").flatMap { try? decoder.decode([String: [QuizQuestion]].self, from: $0) } ?? [:]
        var glossary: [String: GlossaryEntry] = [:]
        if let data = readDisk(language, "glossary.json"), let decoded = try? decoder.decode([String: GlossaryEntryDTO].self, from: data) {
            glossary = decoded.compactMapValues { $0.entry }
        }

        var courses: [Course] = []
        var entryById: [String: CatalogFile.CourseEntry] = [:]
        courses.reserveCapacity(file.courses.count)
        for entry in file.courses {
            guard let subject = Subject.from(storageKey: entry.subject) else { continue }
            entryById[entry.id] = entry
            var quiz = quizzes[entry.id]
            // Un paquet local (pack de départ ou téléchargé) complète ce que les fichiers de la
            // langue n'ont pas encore : son quiz, et son glossaire.
            if let bundle = localBundle(courseId: entry.id, language: language) {
                if quiz == nil { quiz = bundle.quiz }
                for (term, dto) in bundle.glossary ?? [:] where glossary["\(entry.id)|\(term)"] == nil {
                    if let value = dto.entry { glossary["\(entry.id)|\(term)"] = value }
                }
            }
            courses.append(Course(
                id: entry.id,
                title: entry.title,
                description: entry.description,
                subject: subject,
                subcategory: entry.subcategory,
                lessons: entry.sections.map { LessonPage(id: $0.id, title: $0.title) },
                quiz: quiz ?? []
            ))
        }

        let collections = file.collections.map {
            LearningCollection(id: $0.id, title: $0.title, description: $0.description, coverAssetName: $0.cover ?? "", courseIds: $0.courseIds)
        }
        let authors = file.creators.map { creator in
            CourseAuthor(
                slug: creator.slug,
                name: creator.name,
                photo: creator.photo,
                photoUrl: creator.photoUrl,
                institution: creator.institution,
                country: creator.country,
                links: creator.links,
                title: creator.title.map { [language.rawValue: $0] },
                bio: creator.bio.map { [language.rawValue: $0] },
                courseIds: creator.courseIds ?? [],
                verified: creator.verified
            )
        }
        return CatalogSnapshot(
            language: language, source: source, hash: file.hash, courses: courses,
            entryById: entryById, collections: collections, authors: authors, glossary: glossary
        )
    }

    private func localBundle(courseId: String, language: AppLanguage) -> CourseBundle? {
        let key = Self.key(courseId, language)
        if let bundle = bundles[key] { return bundle }
        if missingBundles.contains(key) { return nil }
        let data = readDisk(language, "courses/\(courseId).json") ?? readStarter(language, "courses/\(courseId).json")
        guard let data, let bundle = try? JSONDecoder().decode(CourseBundle.self, from: data) else {
            missingBundles.insert(key)
            return nil
        }
        bundles[key] = bundle
        return bundle
    }

    private static func key(_ courseId: String, _ language: AppLanguage) -> String {
        "\(language.rawValue)|\(courseId)"
    }

    /// Un fichier de langue n'est écrit que s'il se décode : un téléchargement tronqué ne doit
    /// jamais remplacer un catalogue qui marchait.
    private static func looksValid(kind: String, data: Data) -> Bool {
        let decoder = JSONDecoder()
        switch kind {
        case "catalog": return (try? decoder.decode(CatalogFile.self, from: data)) != nil
        case "quizzes": return (try? decoder.decode([String: [QuizQuestion]].self, from: data)) != nil
        case "glossary": return (try? decoder.decode([String: GlossaryEntryDTO].self, from: data)) != nil
        default: return false
        }
    }

    // MARK: - URLs

    private static func manifestURL(language: AppLanguage) -> URL? {
        guard let base = URL(string: AppConfig.SUPABASE_URL) else { return nil }
        var components = URLComponents(url: base.appendingPathComponent("functions/v1/catalog-manifest"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "lang", value: language.rawValue)]
        return components?.url
    }

    static func objectURL(path: String) -> URL? {
        guard let base = URL(string: AppConfig.SUPABASE_URL) else { return nil }
        return base.appendingPathComponent("storage/v1/object/public/\(bucket)/\(path)")
    }

    // MARK: - Disque

    /// Application Support/Catalog, exclu des sauvegardes iCloud : tout s'y retélécharge.
    private static let root: URL? = {
        guard let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let url = support.appendingPathComponent("Catalog", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            var mutable = url
            try mutable.setResourceValues(values)
        } catch {
            return nil
        }
        return url
    }()

    private func diskURL(_ language: AppLanguage, _ name: String) -> URL? {
        Self.root?.appendingPathComponent(language.rawValue, isDirectory: true).appendingPathComponent(name)
    }

    private func readDisk(_ language: AppLanguage, _ name: String) -> Data? {
        guard let url = diskURL(language, name) else { return nil }
        return try? Data(contentsOf: url)
    }

    private func write(_ data: Data, language: AppLanguage, name: String) {
        guard let url = diskURL(language, name) else { return }
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
        } catch {
            #if DEBUG
            print("CatalogStore: écriture impossible \(name) : \(error)")
            #endif
        }
    }

    /// Garde le manifeste et publie ses événements éditoriaux (le même jeu quelle que soit la langue).
    private func adopt(_ manifest: CatalogManifest, for language: AppLanguage) {
        manifests[language] = manifest
        if let events = manifest.events {
            campaigns = events.sorted { $0.startsAt < $1.startsAt }
        }
        trendingByLanguage[language.rawValue] = manifest.trending ?? []
    }

    /// Les cours tendance de la langue, tels que le serveur les a comptés ; vide sans manifeste.
    func trending(for language: AppLanguage) -> [String] {
        trendingByLanguage[language.rawValue] ?? []
    }

    private func readManifestFromDisk(_ language: AppLanguage) -> CatalogManifest? {
        guard let data = readDisk(language, "manifest.json") else { return nil }
        return try? JSONDecoder().decode(CatalogManifest.self, from: data)
    }

    private func readHashes(_ language: AppLanguage) -> [String: String] {
        guard let data = readDisk(language, "hashes.json") else { return [:] }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }

    private func writeHashes(_ hashes: [String: String], language: AppLanguage) {
        guard let data = try? JSONEncoder().encode(hashes) else { return }
        write(data, language: language, name: "hashes.json")
    }

    /// Le pack de départ : `StarterPack/<lang>/<name>` dans le bundle. Xcode peut aplatir le
    /// dossier `Resources`, les deux dispositions sont essayées, puis la racine des ressources.
    private func readStarter(_ language: AppLanguage, _ name: String) -> Data? {
        let bundle = Bundle.main
        let parts = name.split(separator: "/").map(String.init)
        guard let file = parts.last else { return nil }
        let resource = file.replacingOccurrences(of: ".json", with: "")
        let folder = (["StarterPack", language.rawValue] + parts.dropLast()).joined(separator: "/")
        for subdirectory in ["Resources/\(folder)", folder] {
            if let url = bundle.url(forResource: resource, withExtension: "json", subdirectory: subdirectory),
               let data = try? Data(contentsOf: url) {
                return data
            }
        }
        guard let root = bundle.resourceURL else { return nil }
        for subdirectory in ["Resources/\(folder)", folder] {
            let candidate = root.appendingPathComponent(subdirectory).appendingPathComponent(file)
            if let data = try? Data(contentsOf: candidate) { return data }
        }
        return nil
    }
}

/// Ce que l'app sait des cours d'une langue à un instant donné.
final class CatalogSnapshot {
    enum Source {
        case disk, starterPack, empty

        var label: String {
            switch self {
            case .disk: "disque"
            case .starterPack: "pack embarqué"
            case .empty: "vide"
            }
        }
    }

    let language: AppLanguage
    let source: Source
    let hash: String
    let courses: [Course]
    let courseById: [String: Course]
    let entryById: [String: CatalogFile.CourseEntry]
    let collections: [LearningCollection]
    let authors: [CourseAuthor]
    let glossary: [String: GlossaryEntry]

    init(
        language: AppLanguage, source: Source, hash: String = "", courses: [Course] = [],
        entryById: [String: CatalogFile.CourseEntry] = [:], collections: [LearningCollection] = [],
        authors: [CourseAuthor] = [], glossary: [String: GlossaryEntry] = [:]
    ) {
        self.language = language
        self.source = source
        self.hash = hash
        self.courses = courses
        self.courseById = Dictionary(courses.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        self.entryById = entryById
        self.collections = collections
        self.authors = authors
        self.glossary = glossary
    }
}
