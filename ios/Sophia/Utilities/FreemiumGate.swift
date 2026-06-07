import Foundation

/// Centralized freemium rules.
///
/// In freemium the user unlocks **3 subjects** matching the interest labels picked
/// during onboarding. The other 3 subjects are visible everywhere but locked, and
/// any tap that tries to open one of their courses opens the paywall instead.
///
/// Premium users have everything unlocked.
enum FreemiumGate {
    /// Maps a persisted onboarding interest key to a `Subject`.
    static func subject(fromInterestKey key: String) -> Subject? {
        Subject.from(storageKey: OnboardingViewModel.migrateInterestKey(key))
    }

    /// Set of subjects accessible to the user.
    /// Premium → all subjects. Freemium → the (up to 3) onboarding interests.
    /// Falls back to the first 3 subjects if onboarding interests are missing.
    static func unlockedSubjects(isPremium: Bool) -> Set<Subject> {
        if isPremium { return Set(Subject.allCases) }
        let keys = OnboardingViewModel.userInterestKeys()
        let mapped = keys.compactMap { subject(fromInterestKey: $0) }
        if mapped.isEmpty { return Set(Subject.allCases.prefix(3)) }
        return Set(mapped)
    }

    static func isUnlocked(_ subject: Subject, isPremium: Bool) -> Bool {
        unlockedSubjects(isPremium: isPremium).contains(subject)
    }

    /// Returns the paywall to show when a free user taps a course, or `nil`
    /// if the course can be opened normally.
    ///
    /// Priority (per product decision):
    /// 1. Daily quota reached → `cours_gratuit` (wins even if subject is also locked).
    /// 2. Subject not in the user's 3 picked interests → `matiere_block_<subject>`.
    static func paywallContext(
        for course: Course,
        isPremium: Bool,
        hasCompletedCourseToday: Bool
    ) -> SophiaPaywallContext? {
        if isPremium { return nil }
        if hasCompletedCourseToday { return .coursGratuit }
        if !isUnlocked(course.subject, isPremium: false) {
            return .matiereBlock(for: course.subject)
        }
        return nil
    }
}
