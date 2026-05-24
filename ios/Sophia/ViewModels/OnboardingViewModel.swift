import SwiftUI
import AVFoundation
import StoreKit
import RevenueCat

@Observable
class OnboardingViewModel {
    var currentScreen: Int = 0
    var phoneTimeSelection: Int? = nil
    var objectives: Set<String> = []
    var interests: Set<String> = OnboardingViewModel.loadPersistedInterests()
    var loadingProgress: Double = 0
    var loadingStep: String = ""
    var isLoadingComplete: Bool = false
    var dailyLearningGoal: Int = 1

    let totalScreens = 16
    let dailyLearningGoalRange: ClosedRange<Int> = 1...5

    var projectedYearlyLearnings: Int {
        dailyLearningGoal * 365
    }

    var dailyLearningGoalLabel: String {
        dailyLearningGoal == 1 ? "apprentissage" : "apprentissages"
    }

    var wastedTimePerYear: String {
        guard let selection = phoneTimeSelection else { return "" }
        switch selection {
        case 0: return "182 heures"
        case 1: return "547 heures"
        case 2: return "1 095 heures"
        case 3: return "2 190 heures"
        default: return ""
        }
    }

    var wastedTimeDays: String {
        guard let selection = phoneTimeSelection else { return "" }
        switch selection {
        case 0: return "7 jours"
        case 1: return "23 jours"
        case 2: return "45 jours"
        case 3: return "91 jours"
        default: return ""
        }
    }

    var canProceed: Bool {
        switch currentScreen {
        case 2: return phoneTimeSelection != nil
        case 4: return !objectives.isEmpty
        default: return true
        }
    }

    func nextScreen() {
        guard currentScreen < totalScreens - 1 else { return }
        currentScreen += 1
    }

    func toggleObjective(_ objective: String) {
        if objectives.contains(objective) {
            objectives.remove(objective)
        } else {
            objectives.insert(objective)
        }
    }

    func toggleInterest(_ interest: String) {
        if interests.contains(interest) {
            interests.remove(interest)
        } else {
            interests.insert(interest)
        }
        persistInterests()
    }

    func adjustDailyLearningGoal(by delta: Int) {
        let proposedGoal = dailyLearningGoal + delta
        dailyLearningGoal = min(max(proposedGoal, dailyLearningGoalRange.lowerBound), dailyLearningGoalRange.upperBound)
    }

    private func persistInterests() {
        UserDefaults.standard.set(Array(interests), forKey: OnboardingViewModel.interestsKey)
    }

    /// All available interest labels (mirrors the cards on OnboardingInterestsScreen).
    static let allInterestLabels: [String] = [
        "Histoire", "Sciences", "Littérature", "Art", "Mythologie", "Monde actuel"
    ]

    /// Normalize the user's selection to **exactly 3** interests, one-shot:
    /// - 0 selected → pick 3 fully random.
    /// - 1 or 2 selected → keep them, complete randomly from the remaining pool.
    /// - 3 selected → keep as-is.
    /// - 4+ selected → keep 3 random from the user's selection.
    /// Then persist. Should be called once when leaving the interests step.
    func finalizeInterests() {
        let all = OnboardingViewModel.allInterestLabels
        let selected = interests
        var result: Set<String>
        if selected.count == 3 {
            result = selected
        } else if selected.count < 3 {
            let pool = all.filter { !selected.contains($0) }.shuffled()
            let needed = 3 - selected.count
            result = selected.union(pool.prefix(needed))
        } else {
            result = Set(selected.shuffled().prefix(3))
        }
        interests = result
        persistInterests()
    }

    static let interestsKey = "sophia_user_interests"

    static func loadPersistedInterests() -> Set<String> {
        guard let arr = UserDefaults.standard.array(forKey: interestsKey) as? [String] else { return [] }
        return Set(arr)
    }

    static func userInterestLabels() -> Set<String> {
        loadPersistedInterests()
    }

    func startProfileLoading() {
        loadingProgress = 0
        isLoadingComplete = false

        let steps = [
            "Analyse de tes objectifs...",
            "Sélection des sujets...",
            "Personnalisation du contenu...",
            "Création de ton profil..."
        ]

        for (index, step) in steps.enumerated() {
            let delay = Double(index) * 1.0
            let progress = Double(index + 1) / Double(steps.count)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self else { return }
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.loadingStep = step
                    self.loadingProgress = progress
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) { [weak self] in
            guard let self else { return }
            self.isLoadingComplete = true
        }
    }

    func completeOnboarding() {
        persistInterests()
        UserDefaults.standard.set(true, forKey: "sophia_onboarding_completed")
    }

    static var isOnboardingCompleted: Bool {
        UserDefaults.standard.bool(forKey: "sophia_onboarding_completed")
    }

    static var hasSeenSpecialOfferGlobal: Bool {
        UserDefaults.standard.bool(forKey: "sophia_special_offer_seen")
    }

    static func markSpecialOfferSeenGlobal() {
        UserDefaults.standard.set(true, forKey: "sophia_special_offer_seen")
    }
}
