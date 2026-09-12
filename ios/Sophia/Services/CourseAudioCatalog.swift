import Foundation

/// Which courses can be listened to, in which languages.
///
/// The list is not compiled in: `course-audio/manifest.json` is written by
/// `scripts/upload_course_audio_to_supabase.py` from what the bucket really
/// holds, so adding a course or a language never needs an App Store release.
///
/// The bucket is public (see the `course_audio_public_bucket` migration), so
/// reads need no session and the MP3 URL can be handed straight to AVPlayer.
@Observable
final class CourseAudioCatalog {
    static let shared = CourseAudioCatalog()

    /// language code -> course ids that have a narration.
    private(set) var availability: [String: Set<String>] = [:]
    private(set) var isLoaded = false

    private static let bucket = "course-audio"
    private static let cacheKey = "courseAudioManifest.v1"

    private init() {
        // Last known manifest, so the Listen button is right on the first frame
        // of a cold launch instead of appearing a second later.
        if let data = UserDefaults.standard.data(forKey: Self.cacheKey) {
            apply(data, persist: false)
        }
    }

    // MARK: - URLs

    private static var base: URL? {
        URL(string: AppConfig.SUPABASE_URL)?
            .appendingPathComponent("storage/v1/object/public")
            .appendingPathComponent(bucket)
    }

    /// Remote MP3 for a course in a language. One file per course, ~4 minutes.
    static func url(courseId: String, language: AppLanguage) -> URL? {
        base?
            .appendingPathComponent(language.rawValue)
            .appendingPathComponent("\(courseId).mp3")
    }

    // MARK: - Availability

    func hasAudio(courseId: String, language: AppLanguage) -> Bool {
        availability[language.rawValue]?.contains(courseId) ?? false
    }

    /// Languages this course can be heard in, in the app's own language order.
    func languages(forCourse courseId: String) -> [AppLanguage] {
        AppLanguage.allCases.filter { hasAudio(courseId: courseId, language: $0) }
    }

    /// Every course with a narration in this language, catalogue order.
    func courses(in language: AppLanguage) -> [Course] {
        guard let ids = availability[language.rawValue], !ids.isEmpty else { return [] }
        return ContentCatalog.courses(for: language).filter { ids.contains($0.id) }
    }

    var hasAnyAudio: Bool {
        availability.values.contains { !$0.isEmpty }
    }

    // MARK: - Loading

    func refresh() async {
        guard let url = Self.base?.appendingPathComponent("manifest.json") else { return }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadRevalidatingCacheData
        request.timeoutInterval = 15
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200
        else {
            // Offline, or the manifest was never uploaded. Whatever was cached
            // stays in place: downloaded courses must remain playable offline.
            isLoaded = availability.isEmpty == false
            return
        }
        apply(data, persist: true)
    }

    private func apply(_ data: Data, persist: Bool) {
        guard let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) else { return }
        availability = decoded.mapValues(Set.init)
        isLoaded = true
        if persist {
            UserDefaults.standard.set(data, forKey: Self.cacheKey)
        }
    }
}
