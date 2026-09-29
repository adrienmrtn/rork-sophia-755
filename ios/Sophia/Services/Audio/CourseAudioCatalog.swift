import Foundation
import Observation

/// The five languages courses are narrated in. A subset of `AppLanguage`: the app reads in
/// 26 languages, narrations exist in these five.
nonisolated enum AudioLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case french = "fr"
    case english = "en"
    case spanish = "es"
    case german = "de"
    case turkish = "tr"

    var id: String { rawValue }

    /// Written in the language itself, like the app's own language picker.
    var displayName: String {
        switch self {
        case .french: "Français"
        case .english: "English"
        case .spanish: "Español"
        case .german: "Deutsch"
        case .turkish: "Türkçe"
        }
    }

    /// "FR", "EN"… for the compact chips.
    var shortCode: String { rawValue.uppercased() }

    var flag: String {
        switch self {
        case .french: "🇫🇷"
        case .english: "🇬🇧"
        case .spanish: "🇪🇸"
        case .german: "🇩🇪"
        case .turkish: "🇹🇷"
        }
    }

    /// The narration language matching an app language, nil for the 21 others.
    init?(appLanguageCode code: String) {
        self.init(rawValue: code)
    }
}

/// Which course has a narration in which language, read from `course-audio/manifest.json`.
///
/// The bucket is the source of truth: `scripts/upload_course_audio_to_supabase.py` rewrites
/// the manifest from a listing of what it actually holds, so a new narration or a new
/// language reaches the app without an App Store release. Objects live at
/// `<language>/<course_id>.mp3`.
///
/// The last manifest is kept on disk, so downloaded narrations stay listed offline and the
/// menus do not flash empty at launch while the network answers.
@Observable
final class CourseAudioCatalog {
    static let shared = CourseAudioCatalog()

    /// Course ids per narration language.
    private(set) var manifest: [AudioLanguage: Set<String>] = [:]
    private(set) var hasLoaded = false

    private static let preferredLanguageKey = "sophia_audio_language"

    private static let bucketURL: URL? = {
        URL(string: AppConfig.SUPABASE_URL)?
            .appendingPathComponent("storage/v1/object/public/course-audio")
    }()

    private static let manifestCacheURL: URL? = {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("course-audio-manifest.json")
    }()

    private var isRefreshing = false
    private var lastRefresh: Date?

    private init() {
        if let url = Self.manifestCacheURL, let data = try? Data(contentsOf: url) {
            apply(data)
        }
    }

    // MARK: - URLs

    static func remoteURL(courseId: String, language: AudioLanguage) -> URL? {
        bucketURL?
            .appendingPathComponent(language.rawValue)
            .appendingPathComponent(courseId + ".mp3")
    }

    // MARK: - Queries

    /// Narration languages for a course, in the fixed FR, EN, ES, DE, TR order.
    func languages(for courseId: String) -> [AudioLanguage] {
        AudioLanguage.allCases.filter { hasAudio(courseId, language: $0) }
    }

    func hasAudio(_ courseId: String) -> Bool {
        AudioLanguage.allCases.contains { hasAudio(courseId, language: $0) }
    }

    /// A narration counts as available when the manifest lists it, or when it is on the
    /// phone already: a download made yesterday keeps playing in a plane.
    func hasAudio(_ courseId: String, language: AudioLanguage) -> Bool {
        manifest[language]?.contains(courseId) == true
            || CourseAudioDownloads.shared.isDownloaded(courseId: courseId, language: language)
    }

    /// The listener's language: the last one they picked, else the app language when it is
    /// narrated, else English.
    var preferredLanguage: AudioLanguage {
        get {
            if let raw = UserDefaults.standard.string(forKey: Self.preferredLanguageKey),
               let saved = AudioLanguage(rawValue: raw) {
                return saved
            }
            return AudioLanguage(appLanguageCode: AppLanguage.currentPersisted().rawValue) ?? .english
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Self.preferredLanguageKey)
        }
    }

    /// Language a course plays in by default: the preferred one when this course has it,
    /// then the app language, then English, then whatever exists.
    func defaultLanguage(for courseId: String) -> AudioLanguage? {
        let available = languages(for: courseId)
        guard !available.isEmpty else { return nil }
        let appLanguage = AudioLanguage(appLanguageCode: AppLanguage.currentPersisted().rawValue)
        let candidates: [AudioLanguage?] = [preferredLanguage, appLanguage, .english]
        for candidate in candidates.compactMap({ $0 }) where available.contains(candidate) {
            return candidate
        }
        return available.first
    }

    // MARK: - Loading

    /// Fetches the manifest. Cheap and idempotent: called at launch and when the app comes
    /// back to the foreground, at most once every ten minutes.
    func refresh(force: Bool = false) async {
        guard !isRefreshing else { return }
        if !force, let lastRefresh, Date().timeIntervalSince(lastRefresh) < 600 { return }
        // The bucket's CDN keeps an object for up to an hour and ignores the upload that
        // replaced it; a query that changes every five minutes is a different object to it.
        let slot = Int(Date().timeIntervalSince1970 / 300)
        guard let base = Self.bucketURL?.appendingPathComponent("manifest.json"),
              var components = URLComponents(url: base, resolvingAgainstBaseURL: false) else { return }
        components.queryItems = [URLQueryItem(name: "v", value: String(slot))]
        guard let url = components.url else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 15
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200, apply(data) else { return }
            lastRefresh = Date()
            if let cacheURL = Self.manifestCacheURL {
                try? data.write(to: cacheURL, options: .atomic)
            }
        } catch {
            // Offline: the cached manifest and the downloads carry on.
        }
    }

    /// `{"fr": ["course_1_…", …], "en": […]}`. Unknown language keys are ignored, so the
    /// bucket can hold a sixth language before the app knows about it.
    @discardableResult
    private func apply(_ data: Data) -> Bool {
        guard let raw = try? JSONDecoder().decode([String: [String]].self, from: data) else { return false }
        var parsed: [AudioLanguage: Set<String>] = [:]
        for (code, ids) in raw {
            guard let language = AudioLanguage(rawValue: code) else { continue }
            parsed[language] = Set(ids)
        }
        manifest = parsed
        hasLoaded = true
        return true
    }
}
