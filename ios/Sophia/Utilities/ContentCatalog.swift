import Foundation

/// Locale-aware access to bundled learning content.
enum ContentCatalog {
    static func courses(for language: AppLanguage) -> [Course] {
        switch language {
        case .french:
            return CourseData.allCourses
        case .english:
            return LocalizedContentLoader.courses(for: .english)
        case .spanish:
            return LocalizedContentLoader.courses(for: .spanish)
        case .german:
            return LocalizedContentLoader.courses(for: .german)
        case .portuguese:
            return LocalizedContentLoader.courses(for: .portuguese)
        case .italian:
            return LocalizedContentLoader.courses(for: .italian)
        }
    }

    static func collections(for language: AppLanguage) -> [LearningCollection] {
        switch language {
        case .french:
            return CollectionData.allCollections
        case .english:
            return LocalizedContentLoader.collections(for: .english)
        case .spanish:
            return LocalizedContentLoader.collections(for: .spanish)
        case .german:
            return LocalizedContentLoader.collections(for: .german)
        case .portuguese:
            return LocalizedContentLoader.collections(for: .portuguese)
        case .italian:
            return LocalizedContentLoader.collections(for: .italian)
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
