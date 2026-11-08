import Foundation

nonisolated struct LearningCollection: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let description: String
    let coverAssetName: String
    let courseIds: [String]

    var courses: [Course] {
        let catalog = ContentCatalog.activeCourses
        return courseIds.compactMap { courseId in
            catalog.first { $0.id == courseId }
        }
    }
}

/// Les collections du Parcours, en français. Elles vivaient ici en Swift ; elles viennent
/// désormais du catalogue en ligne (`CatalogStore`), l'API est restée pour ses appelants.
enum CollectionData {
    static var allCollections: [LearningCollection] {
        CatalogStore.shared.snapshot(for: .french).collections
    }
}
