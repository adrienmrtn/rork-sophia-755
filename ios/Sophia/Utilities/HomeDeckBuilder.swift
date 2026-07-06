import Foundation

/// Builds the home course deck: curated starters first, then the rest of the catalog.
enum HomeDeckBuilder {
    /// Returns incomplete courses with the curated starter block first (shuffled), then all others (shuffled).
    static func deck(
        from courses: [Course],
        isCompleted: (String) -> Bool
    ) -> [Course] {
        let pool = courses.filter { !isCompleted($0.id) }
        let curatedIDs = Set(CuratedStarterCourses.ids)

        let curated = CuratedStarterCourses.ids
            .compactMap { id in pool.first(where: { $0.id == id }) }
            .shuffled()

        let remaining = pool
            .filter { !curatedIDs.contains($0.id) }
            .shuffled()

        return curated + remaining
    }
}
