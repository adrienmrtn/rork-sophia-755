import SwiftUI
import AVFoundation
import StoreKit
import RevenueCat

@Observable
class OnboardingViewModel {
    var currentScreen: Int = 0
    var phoneTimeSelection: Int? = nil
    var objectives: Set<String> = []
    var interests: Set<String> = []
    var loadingBarProgress: [Double] = [0, 0, 0]
    var isLoadingComplete: Bool = false
    var dailyLearningGoal: Int = 1

    let totalScreens = 18
    let dailyLearningGoalRange: ClosedRange<Int> = 1...5

    var projectedYearlyLearnings: Int {
        dailyLearningGoal * 365
    }

    func dailyLearningGoalLabel(language: AppLanguage) -> String {
        let key = dailyLearningGoal == 1 ? "onboarding.dailyGoal.singular" : "onboarding.dailyGoal.plural"
        return AppLocalizable.string(key, language: language)
    }

    func phoneHoursPerDayLabel(language: AppLanguage) -> String {
        guard let selection = phoneTimeSelection else { return "" }
        let keys = [
            "onboarding.phone.hours.1",
            "onboarding.phone.hours.2",
            "onboarding.phone.hours.3",
            "onboarding.phone.hours.5",
        ]
        guard selection >= 0, selection < keys.count else { return "" }
        return AppLocalizable.string(keys[selection], language: language)
    }

    func wastedTimeDays(language: AppLanguage) -> String {
        guard let selection = phoneTimeSelection else { return "" }
        let keys = [
            "onboarding.wasted.days.7",
            "onboarding.wasted.days.23",
            "onboarding.wasted.days.45",
            "onboarding.wasted.days.91",
        ]
        guard selection >= 0, selection < keys.count else { return "" }
        return AppLocalizable.string(keys[selection], language: language)
    }

    static let objectiveKeys = ["curious", "learnNew", "impress", "social", "reduceScroll"]

    static func objectiveLabel(_ key: String, language: AppLanguage) -> String {
        AppLocalizable.string("onboarding.objective.\(key)", language: language)
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
    }

    func adjustDailyLearningGoal(by delta: Int) {
        let proposedGoal = dailyLearningGoal + delta
        dailyLearningGoal = min(max(proposedGoal, dailyLearningGoalRange.lowerBound), dailyLearningGoalRange.upperBound)
    }

    static let interestsKey = "sophia_user_interests"

    static func loadPersistedInterests() -> Set<String> {
        guard let arr = UserDefaults.standard.array(forKey: interestsKey) as? [String] else { return [] }
        return Set(arr.map(migrateInterestKey))
    }

    static func userInterestKeys() -> Set<String> {
        loadPersistedInterests()
    }

    /// Migrates legacy French display labels to stable subject storage keys.
    static func migrateInterestKey(_ value: String) -> String {
        if Subject.from(storageKey: value) != nil { return value }
        switch value {
        case "Histoire": return Subject.histoire.storageKey
        case "Sciences": return Subject.sciences.storageKey
        case "Littérature": return Subject.litterature.storageKey
        case "Art": return Subject.art.storageKey
        case "Mythologie": return Subject.mythologie.storageKey
        case "Monde actuel": return Subject.comprendreLeMonde.storageKey
        default: return value
        }
    }

    func startProfileLoading() {
        loadingBarProgress = [0, 0, 0]
        isLoadingComplete = false

        let barDuration: Double = 2.0
        let barStarts: [Double] = [0, 1.2, 2.4]

        for (index, start) in barStarts.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + start) { [weak self] in
                guard let self else { return }
                withAnimation(.easeInOut(duration: barDuration)) {
                    var bars = self.loadingBarProgress
                    guard bars.indices.contains(index) else { return }
                    bars[index] = 1.0
                    self.loadingBarProgress = bars
                }
            }
        }

        let totalDuration = barStarts.last! + barDuration + 0.2
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) { [weak self] in
            guard let self else { return }
            self.isLoadingComplete = true
        }
    }

    func completeOnboarding() {
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
