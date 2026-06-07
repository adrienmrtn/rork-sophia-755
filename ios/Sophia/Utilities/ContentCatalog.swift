import Foundation

/// Locale-aware access to bundled learning content.
///
/// Phase 1: French catalog only (`CourseData.allCourses`).
/// Phase 2: load per-locale JSON bundles from CSV exports; omit entries without a translation.
enum ContentCatalog {
    static func courses(for language: AppLanguage) -> [Course] {
        switch language {
        case .french:
            return CourseData.allCourses
        case .english:
            // Phase 2 — JSON bundle keyed by stable course IDs.
            return CourseData.allCourses
        }
    }

    static var activeCourses: [Course] {
        courses(for: AppLanguage.currentPersisted())
    }
}
