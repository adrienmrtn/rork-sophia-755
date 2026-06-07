import Foundation

enum DeckBalancer {
    /// Builds an initial deck: first card is always unlocked when possible; never more than 2 consecutive locked-subject cards.
    static func balancedDeck(courses: [Course], unlockedSubjects: Set<Subject>, isPremium: Bool) -> [Course] {
        guard !isPremium, !courses.isEmpty else { return courses.shuffled() }

        var unlockedPool = courses.filter { unlockedSubjects.contains($0.subject) }.shuffled()
        var lockedPool = courses.filter { !unlockedSubjects.contains($0.subject) }.shuffled()

        if unlockedPool.isEmpty { return lockedPool }
        if lockedPool.isEmpty { return unlockedPool }

        var result: [Course] = []
        var consecutiveLocked = 0

        while !unlockedPool.isEmpty || !lockedPool.isEmpty {
            let mustPickUnlocked = !unlockedPool.isEmpty && (result.isEmpty || consecutiveLocked >= 2)

            if mustPickUnlocked || lockedPool.isEmpty {
                result.append(unlockedPool.removeFirst())
                consecutiveLocked = 0
            } else if unlockedPool.isEmpty {
                result.append(lockedPool.removeFirst())
                consecutiveLocked += 1
            } else if consecutiveLocked == 1 {
                result.append(unlockedPool.removeFirst())
                consecutiveLocked = 0
            } else {
                result.append(lockedPool.removeFirst())
                consecutiveLocked += 1
            }
        }

        return result
    }

    /// After a swipe, keep deck order (rotate only). Swap in an unlocked card if the
    /// visible stack would show 3 locked cards in a row — without reshuffling.
    static func afterSwipe(_ cards: [Course], unlockedSubjects: Set<Subject>, isPremium: Bool) -> [Course] {
        guard !isPremium, cards.count >= 3 else { return cards }

        func isLocked(_ course: Course) -> Bool {
            !unlockedSubjects.contains(course.subject)
        }

        var result = cards
        if isLocked(result[0]), isLocked(result[1]), isLocked(result[2]),
           let swapIndex = result.indices.first(where: { $0 >= 2 && !isLocked(result[$0]) }) {
            result.swapAt(2, swapIndex)
        }
        return result
    }
}
