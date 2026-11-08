import Foundation

/// Le catalogue français. Il était compilé en Swift (21 fichiers `CourseData+ChunkNN`) ; il vient
/// désormais du catalogue en ligne (`CatalogStore`). L'API est restée pour ses appelants.
enum CourseData {
    static var allCourses: [Course] {
        ContentCatalog.courses(for: .french)
    }
}
