import Foundation

/// Locale-aware access to bundled learning content.
enum ContentCatalog {
    /// Courses withheld from a language. They are absent from the catalogue as if they
    /// had never been bundled: no home card, no library row, no collection slot, no
    /// deep link, no blocker pick. Switching language brings them back.
    static let withheldCourseIds: [AppLanguage: Set<String>] = [
        .turkish: ["course_25_le_genocide_armenien_1915_1916"],
    ]

    static func isWithheld(_ courseId: String, language: AppLanguage) -> Bool {
        withheldCourseIds[language]?.contains(courseId) == true
    }

    static func courses(for language: AppLanguage) -> [Course] {
        let all = language == .french
            ? CourseData.allCourses
            : LocalizedContentLoader.courses(for: language)
        guard let withheld = withheldCourseIds[language] else { return all }
        return all.filter { !withheld.contains($0.id) }
    }

    /// Collections lose their withheld courses too, so their counts and completion
    /// maths only see what the reader can open.
    static func collections(for language: AppLanguage) -> [LearningCollection] {
        let all = language == .french
            ? CollectionData.allCollections
            : LocalizedContentLoader.collections(for: language)
        guard let withheld = withheldCourseIds[language] else { return all }
        return all.map { collection in
            let kept = collection.courseIds.filter { !withheld.contains($0) }
            guard kept.count != collection.courseIds.count else { return collection }
            return LearningCollection(
                id: collection.id,
                title: collection.title,
                description: collection.description,
                coverAssetName: collection.coverAssetName,
                courseIds: kept
            )
        }
    }

    static var activeCourses: [Course] {
        courses(for: AppLanguage.currentPersisted())
    }

    static var activeCollections: [LearningCollection] {
        collections(for: AppLanguage.currentPersisted())
    }

    static func course(withId id: String, language: AppLanguage? = nil) -> Course? {
        let language = language ?? AppLanguage.currentPersisted()
        return courses(for: language).first { $0.id == id }
    }

    // MARK: - Structured (v2) content

    /// Whether a course has structured block content bundled for the active language.
    /// When true, `CourseView` renders it with `BlockContentView` instead of the legacy renderer.
    static func hasStructuredContent(courseId: String, language: AppLanguage? = nil) -> Bool {
        CourseContentStore.hasContent(
            courseId: courseId,
            language: language ?? AppLanguage.currentPersisted()
        )
    }

    static func structuredContent(courseId: String, language: AppLanguage? = nil) -> CourseContentV2? {
        CourseContentStore.content(
            courseId: courseId,
            language: language ?? AppLanguage.currentPersisted()
        )
    }
}
