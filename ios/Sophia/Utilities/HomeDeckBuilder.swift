import Foundation

/// Builds the home course deck from incomplete courses in random order.
enum HomeDeckBuilder {
    /// Returns incomplete courses shuffled on each call (fresh random feed on every home visit).
    static func deck(
        from courses: [Course],
        isCompleted: (String) -> Bool
    ) -> [Course] {
        courses
            .filter { !isCompleted($0.id) }
            .shuffled()
    }
}
