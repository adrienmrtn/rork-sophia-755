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
    /// Objectifs sélectionnés (multi-sélection), dans l'ordre de sélection.
    var objectiveKeys: [String] = []
    /// Cours « aimés » lors du swipe — utilisés pour préremplir les favoris.
    var likedCourseIds: [String] = []
    /// Temps d'écran quotidien déclaré (en minutes, par blocs de 30) — écran « temps téléphone ».
    /// Sert à l'écran « ta vie en années » (remplissage rouge).
    var phoneDailyMinutes: Int = 180

    /// Nombre d'années (sur une vie de 80 ans) équivalent au temps passé sur le téléphone.
    var phoneYearsOverLife: Double {
        80.0 * Double(phoneDailyMinutes) / (24.0 * 60.0)
    }

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

    func toggleObjective(_ key: String) {
        if let idx = objectiveKeys.firstIndex(of: key) {
            objectiveKeys.remove(at: idx)
        } else {
            objectiveKeys.append(key)
        }
    }

    func isSelected(_ key: String) -> Bool {
        objectiveKeys.contains(key)
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

    /// Union (ordonnée selon `Subject.allCases`) des matières de tous les objectifs sélectionnés.
    var selectedSubjects: [String] {
        let all = Set(objectiveKeys.flatMap { Self.subjects(for: $0) })
        return Subject.allCases.map(\.storageKey).filter { all.contains($0) }
    }

    // MARK: - Recommandations (swipe)

    /// 5 cours à swiper, dérivés des matières des objectifs (fallback : starters curatés).
    func recommendedCourses(language: AppLanguage) -> [Course] {
        let interests = Set(selectedSubjects)
        return OnboardingCourseRecommender.recommendedCourses(
            interests: interests,
            language: language,
            limit: 5
        )
    }

    func toggleLiked(_ courseId: String, liked: Bool) {
        if liked {
            if !likedCourseIds.contains(courseId) { likedCourseIds.append(courseId) }
        } else {
            likedCourseIds.removeAll { $0 == courseId }
        }
    }

    // MARK: - Persistance

    /// Persiste les intérêts dérivés (union des objectifs) + les favoris aimés, puis marque
    /// l'onboarding terminé.
    func persistAndComplete(progressManager: ProgressManager) {
        UserDefaults.standard.set(selectedSubjects.sorted(), forKey: OnboardingViewModel.interestsKey)

        for id in likedCourseIds where !progressManager.isFavorite(id) {
            progressManager.toggleFavorite(id)
        }

        if !objectiveKeys.isEmpty {
            UserDefaults.standard.set(objectiveKeys, forKey: "sophia_onboarding_objectives")
        }

        OnboardingViewModel().completeOnboarding()
    }
}
