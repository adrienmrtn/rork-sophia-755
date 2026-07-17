import Foundation

/// Loads structured ("v2") course content bundled under `Resources/CoursesV2/`.
///
/// File naming: `<courseId>.<languageCode>.json` (e.g. `course_1_..._622.fr.json`).
/// A course renders with the v2 block engine only when its resource exists for the
/// active language; otherwise callers fall back to the legacy string renderer.
enum CourseContentStore {
    private static var cache: [String: CourseContentV2] = [:]
    private static var missing: Set<String> = []

    static func resetCache() {
        cache.removeAll()
        missing.removeAll()
    }

    /// Full structured content for a course, or nil when no v2 resource is bundled.
    static func content(
        courseId: String,
        language: AppLanguage = AppLanguage.currentPersisted()
    ) -> CourseContentV2? {
        let key = cacheKey(courseId: courseId, language: language)
        if let cached = cache[key] { return cached }
        if missing.contains(key) { return nil }

        guard let url = resourceURL(courseId: courseId, language: language) else {
            missing.insert(key)
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(CourseContentV2.self, from: data)
            cache[key] = decoded
            return decoded
        } catch {
            assertionFailure("Failed to decode v2 content \(courseId) [\(language.rawValue)]: \(error)")
            missing.insert(key)
            return nil
        }
    }

    static func hasContent(
        courseId: String,
        language: AppLanguage = AppLanguage.currentPersisted()
    ) -> Bool {
        content(courseId: courseId, language: language) != nil
    }

    /// Resolves a single section plus whether it is the first (intro) section.
    static func section(
        courseId: String,
        sectionId: String,
        language: AppLanguage = AppLanguage.currentPersisted()
    ) -> (content: CourseContentV2, section: CourseSectionV2, isFirst: Bool)? {
        guard let content = content(courseId: courseId, language: language) else { return nil }
        guard let index = content.sections.firstIndex(where: { $0.id == sectionId }) else { return nil }
        return (content, content.sections[index], index == 0)
    }

    private static func cacheKey(courseId: String, language: AppLanguage) -> String {
        "\(language.rawValue)|\(courseId)"
    }

    /// Resolves the resource for the exact language only. A language without a v2
    /// resource intentionally falls back (in the caller) to the legacy localized
    /// renderer, so we never show French content to a non-French user.
    private static func resourceURL(courseId: String, language: AppLanguage) -> URL? {
        resourceURL(courseId: courseId, code: language.rawValue)
    }

    private static func resourceURL(courseId: String, code: String) -> URL? {
        let resource = "\(courseId).\(code)"
        let subdirectories = ["Resources/CoursesV2", "CoursesV2"]

        for subdirectory in subdirectories {
            if let url = Bundle.main.url(
                forResource: resource,
                withExtension: "json",
                subdirectory: subdirectory
            ) {
                return url
            }
        }
        if let url = Bundle.main.url(forResource: resource, withExtension: "json") {
            return url
        }

        guard let resourceRoot = Bundle.main.resourceURL else { return nil }
        let relativePaths = [
            "Resources/CoursesV2/\(resource).json",
            "CoursesV2/\(resource).json",
        ]
        for relativePath in relativePaths {
            let candidate = resourceRoot.appendingPathComponent(relativePath)
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }
}
