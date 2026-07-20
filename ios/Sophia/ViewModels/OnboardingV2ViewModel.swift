import SwiftUI
import Observation

/// État du nouvel onboarding (V2).
///
/// Contrairement à l'ancien funnel, on ne demande plus explicitement les « centres d'intérêt » :
/// on les **dérive de l'objectif** choisi (mapping ci-dessous) et on les persiste sous la même
/// clé (`sophia_user_interests`) pour que l'accueil et les recommandations existants restent
/// pertinents sans autre changement.
@Observable
@MainActor
final class OnboardingV2ViewModel {
    /// Objectif principal (page 3), clé stable.
    var objectiveKey: String?
    /// Temps d'écran quotidien en heures (page 6), slider 0…8 par pas de 0,5.
    var phoneDailyHours: Double = 3.0
    /// Cours « aimés » lors du swipe (page 5) — utilisés pour préremplir les favoris.
    var likedCourseIds: [String] = []

    // MARK: - Objectifs

    static let objectiveKeys = ["cultivate", "reduceScreen", "exams", "impress", "curiosity"]

    static func objectiveLabel(_ key: String, language: AppLanguage) -> String {
        AppLocalizable.string("onboardingV2.objective.\(key)", language: language)
    }

    static func objectiveEmoji(_ key: String) -> String {
        switch key {
        case "cultivate": "🧠"
        case "reduceScreen": "📵"
        case "exams": "🎓"
        case "impress": "✨"
        case "curiosity": "🔭"
        default: "📚"
        }
    }

    /// Pourcentage « social proof » affiché page 4 (marketing, par objectif).
    static func objectiveStatPercent(_ key: String?) -> Int {
        switch key {
        case "cultivate": 92
        case "reduceScreen": 88
        case "exams": 90
        case "impress": 87
        case "curiosity": 94
        default: 89
        }
    }

    /// Matières associées à chaque objectif (source des recommandations + swipe).
    static func subjects(for objectiveKey: String?) -> [String] {
        switch objectiveKey {
        case "exams":
            return ["histoire", "sciences", "litterature", "comprendreLeMonde"]
        case "impress":
            return ["histoire", "art", "litterature", "mythologie"]
        case "curiosity":
            return ["sciences", "mythologie", "art", "comprendreLeMonde"]
        case "cultivate", "reduceScreen":
            return Subject.allCases.map(\.storageKey)
        default:
            return Subject.allCases.map(\.storageKey)
        }
    }

    // MARK: - Recommandations (page 5)

    /// 8 cours à swiper, dérivés des matières de l'objectif (fallback : starters curatés).
    func recommendedCourses(language: AppLanguage) -> [Course] {
        let interests = Set(Self.subjects(for: objectiveKey))
        return OnboardingCourseRecommender.recommendedCourses(
            interests: interests,
            language: language,
            limit: 8
        )
    }

    func toggleLiked(_ courseId: String, liked: Bool) {
        if liked {
            if !likedCourseIds.contains(courseId) { likedCourseIds.append(courseId) }
        } else {
            likedCourseIds.removeAll { $0 == courseId }
        }
    }

    // MARK: - Temps d'écran (pages 6-7)

    func phoneHoursLabel() -> String {
        let whole = Int(phoneDailyHours)
        let hasHalf = (phoneDailyHours - Double(whole)) >= 0.25
        return hasHalf ? "\(whole)h30" : "\(whole)h"
    }

    /// Nombre de semaines « perdues » par an à ce rythme (page 7).
    /// heures/jour × 365 ÷ 168 (168 h dans une semaine), borné à 52.
    var weeksLostPerYear: Int {
        let weeks = Int((phoneDailyHours * 365.0 / 168.0).rounded())
        return min(52, max(1, weeks))
    }

    // MARK: - Persistance

    /// Persiste les intérêts dérivés + les favoris aimés, puis marque l'onboarding terminé.
    func persistAndComplete(progressManager: ProgressManager) {
        let subjects = Self.subjects(for: objectiveKey)
        UserDefaults.standard.set(subjects.sorted(), forKey: OnboardingViewModel.interestsKey)

        for id in likedCourseIds where !progressManager.isFavorite(id) {
            progressManager.toggleFavorite(id)
        }

        if let objectiveKey {
            UserDefaults.standard.set(objectiveKey, forKey: "sophia_onboarding_objective")
        }

        OnboardingViewModel().completeOnboarding()
    }
}
