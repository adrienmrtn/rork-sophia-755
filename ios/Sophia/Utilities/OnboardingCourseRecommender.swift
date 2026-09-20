import Foundation

/// Course recommendations for the screens that show a short list rather than the
/// home deck: the onboarding swipe, the profile screen's "waiting for you", and the
/// library's recommended row.
///
/// It used to be 24 course ids typed by hand, dealt round-robin by subject. Because
/// the round-robin took index 0 of each subject in `Subject.allCases` order and the
/// commonest objectives map to every subject, the first five cards were the same
/// five courses for everyone — which is why those five now sit in 38–62 % of all
/// accounts' favourites while the sixth-placed course sits at 1.3 %. A hand-picked
/// list also had no way of knowing that one of its five, "Napoléon à Ulm", is
/// finished by only 36 % of the people who open it, the worst rate of any course it
/// was competing against.
///
/// So this is now the same model as the home deck — observed quality, co-read
/// neighbours, subject quotas — asked for the first few cards instead of the whole
/// pack. The interests still matter, they just no longer filter: science belongs in
/// everyone's list, since roughly half the readers of every other subject read it too.
enum OnboardingCourseRecommender {
    /// Recommends up to `limit` courses for the given interests.
    ///
    /// `excluding` lets a caller skip courses already surfaced elsewhere (e.g. the
    /// onboarding swipe deck) so the profile screen shows *different* courses.
    ///
    /// Stable for a given install and exclusion set: these lists are read from SwiftUI
    /// computed properties, which are recomputed on every layout pass, so anything
    /// drawn from system randomness would reshuffle under the reader mid-screen.
    /// Different installs still get different lists — that is the point of no longer
    /// dealing everyone the same five cards.
    static func recommendedCourses(
        interests: Set<String>,
        language: AppLanguage,
        limit: Int = 4,
        excluding: Set<String> = []
    ) -> [Course] {
        let catalogue = ContentCatalog.courses(for: language)
        guard !catalogue.isEmpty, limit > 0 else { return [] }

        var generator = RecommendationSeed.generator(salt: "onboarding")
        let deck = HomeDeckBuilder.deck(
            from: catalogue,
            context: DeckContext(objectiveSubjects: interests),
            isCompleted: { excluding.contains($0) },
            using: &generator
        )
        return Array(deck.prefix(limit))
    }
}
