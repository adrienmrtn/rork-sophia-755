import Foundation

extension DeckContext {
    /// Reads the signals the deck needs out of stored progress.
    ///
    /// Note what is *not* here: favourites. The onboarding swipe writes its likes
    /// straight into `favoriteCourseIds`, so five courses sit in 38–62 % of all
    /// accounts and everything else below 1.3 % — the field records which cards the
    /// app dealt, not what anyone liked. Finished courses are the honest signal, and
    /// they are what this uses.
    @MainActor
    static func current(
        progressManager: ProgressManager,
        catalogue: [Course] = ContentCatalog.activeCourses,
        objectiveSubjects: Set<String> = OnboardingViewModel.userInterestKeys(),
        skipCounts: [String: Int] = DeckSkipStore.counts()
    ) -> DeckContext {
        let subjectsById = Dictionary(
            catalogue.map { ($0.id, $0.subject.storageKey) },
            uniquingKeysWith: { first, _ in first }
        )

        var completedBySubject: [String: Int] = [:]
        // `(courseId, sortKey)`, built in the same pass rather than by sorting the
        // whole progress dictionary: only the handful most recently touched matter.
        var recency: [(id: String, key: String)] = []

        for (courseId, courseProgress) in progressManager.progress.courseProgress {
            guard let subject = subjectsById[courseId] else { continue }
            if courseProgress.isCompleted {
                completedBySubject[subject, default: 0] += 1
            }
            // Both dates are ISO-8601, so the later string is the later moment and
            // they compare without being parsed. Progress written by a build that
            // recorded neither simply sorts last, which is where an unknown date
            // belongs.
            let stamp = max(courseProgress.completedAt ?? "", courseProgress.startedAt ?? "")
            if !stamp.isEmpty {
                recency.append((courseId, stamp))
            }
        }

        let recent = recency
            .sorted { $0.key > $1.key }
            .prefix(HomeDeckBuilder.recentWindow)
            .map(\.id)

        return DeckContext(
            completedBySubject: completedBySubject,
            recentCourseIds: Array(recent),
            objectiveSubjects: objectiveSubjects,
            skipCounts: skipCounts
        )
    }
}

/// The per-install seed behind every deck that has to come back identical.
///
/// Two things need it. Recommendations read from a SwiftUI computed property are
/// recomputed on each layout pass and would otherwise deal a new hand mid-scroll.
/// And the onboarding swipe should differ between people — showing all 114 888
/// accounts the same five cards is what made favourites useless as a signal in the
/// first place — while staying the same for one person across relaunches.
enum RecommendationSeed {
    private static let key = "sophia_recommendation_seed"

    static func value(defaults: UserDefaults = .standard) -> UInt64 {
        if let stored = defaults.object(forKey: key) as? NSNumber {
            return stored.uint64Value
        }
        let seed = UInt64.random(in: 1...UInt64.max)
        defaults.set(NSNumber(value: seed), forKey: key)
        return seed
    }

    /// A generator seeded for one purpose, so two different screens of the same
    /// install do not deal the same cards in the same order.
    static func generator(
        salt: String,
        defaults: UserDefaults = .standard
    ) -> SeededGenerator {
        var mixed = value(defaults: defaults)
        for byte in salt.utf8 {
            mixed = (mixed ^ UInt64(byte)) &* 0x0000_0100_0000_01B3  // FNV-1a
        }
        return SeededGenerator(seed: mixed)
    }
}
