import Foundation

/// Compteurs affichés sur les cartes, la page créateur et l'événement. Les ouvertures et les
/// j'aime des cours viennent du serveur (`CatalogStore.courseStats`) ; seuls les abonnés d'un
/// créateur restent dérivés d'un hash FNV-1a stable. Les gestes locaux (j'aime, suivre)
/// s'ajoutent par-dessus.
enum LocalCounters {
    static func hash(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }

    /// Les j'aime du cours tels que le serveur les donne (deuxième valeur de `stats`) ; 0 sans chiffre.
    static func likes(courseId: String) -> Int {
        let stats = CatalogStore.shared.courseStats[courseId] ?? []
        return stats.count > 1 ? stats[1] : 0
    }

    /// Abonnés d'un créateur : entre 800 et 5 800, arrondi à la dizaine.
    static func followers(creatorSlug: String) -> Int {
        800 + Int(hash(creatorSlug + "|followers") % 5_000) / 10 * 10
    }

    /// Lectures cumulées d'un créateur : la somme de celles de ses cours.
    static func reads(for author: CourseAuthor) -> Int {
        author.courseIds.reduce(0) { total, courseId in
            total + (ContentCatalog.course(withId: courseId)?.readsCount ?? 0)
        }
    }
}

extension Course {
    /// Nombre de « j'aime » affiché : le compteur local plus le geste de l'utilisateur.
    func likesCount(liked: Bool) -> Int {
        LocalCounters.likes(courseId: id) + (liked ? 1 : 0)
    }

    /// « 1,2 k lectures · 96 j'aime » pour les lignes de liste ; `nil` tant que le serveur n'a
    /// pas envoyé les compteurs (on n'affiche alors rien plutôt qu'un zéro).
    func statsLine(liked: Bool, language: AppLanguage) -> String? {
        guard let reads = realReadsCount else { return nil }
        return "\(reads.compactCount) \(AppLocalizable.string("creator.stat.reads", language: language)) · \(likesCount(liked: liked).compactCount) \(AppLocalizable.string("common.likes", language: language))"
    }
}

extension Int {
    /// Format compact des compteurs : « 940 », « 7,2 k », « 18 k », « 1,2 M ».
    /// Le séparateur décimal suit la langue de l'app.
    var compactCount: String {
        let language = AppLanguage.currentPersisted()
        let separator = Locale(identifier: language.localeIdentifier).decimalSeparator ?? ","
        func one(_ value: Double, _ suffix: String) -> String {
            if value >= 10 { return "\(Int(value.rounded(.down))) \(suffix)" }
            let text = String(format: "%.1f", value).replacingOccurrences(of: ".", with: separator)
            return "\(text.hasSuffix("\(separator)0") ? String(text.dropLast(2)) : text) \(suffix)"
        }
        if self >= 1_000_000 { return one(Double(self) / 1_000_000, "M") }
        if self >= 1_000 { return one(Double(self) / 1_000, "k") }
        return "\(self)"
    }
}

/// Temps de lecture estimé d'un cours, à partir du nombre de mots de son contenu structuré
/// (180 mots par minute), borné entre 2 et 20 minutes. Sans contenu structuré, une minute et
/// demie par page. Mis en cache par cours et par langue.
enum ReadingTime {
    private static var cache: [String: Int] = [:]
    static let wordsPerMinute = 180

    static func minutes(for course: Course, language: AppLanguage = AppLanguage.currentPersisted()) -> Int {
        let key = "\(course.id)|\(language.rawValue)"
        if let cached = cache[key] { return cached }
        let minutes: Int
        if let content = CourseContentStore.content(courseId: course.id, language: language) {
            let words = content.sections.reduce(0) { $0 + wordCount(of: $1) }
            minutes = min(20, max(2, Int((Double(words) / Double(wordsPerMinute)).rounded())))
        } else {
            minutes = min(20, max(2, Int((Double(course.lessons.count) * 1.5).rounded())))
        }
        cache[key] = minutes
        return minutes
    }

    static func sectionCount(for course: Course, language: AppLanguage = AppLanguage.currentPersisted()) -> Int {
        if let content = CourseContentStore.content(courseId: course.id, language: language) {
            return content.sections.count
        }
        return course.lessons.count
    }

    private static func wordCount(of section: CourseSectionV2) -> Int {
        var text = section.title
        for block in section.blocks {
            switch block {
            case .heading(let value), .paragraph(let value), .funFact(let value), .takeaway(let value):
                text += " " + value
            case .quote(let value, _):
                text += " " + value
            case .timeline(let events):
                text += " " + events.map { "\($0.date) \($0.title) \($0.detail ?? "")" }.joined(separator: " ")
            case .image(let image):
                text += " " + (image.caption ?? "")
            }
        }
        return text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }
}
