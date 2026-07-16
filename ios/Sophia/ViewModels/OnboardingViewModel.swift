import SwiftUI
import AVFoundation
import StoreKit
import RevenueCat

@Observable
class OnboardingViewModel {
    var currentScreen: Int = 0
    var phoneTimeSelection: Int? = nil
    /// Continuous daily phone-time in hours, chosen via the slider (0...8, 0.5 steps).
    var phoneDailyHours: Double = 3.0
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

    /// Updates the slider hours and derives the downstream bucket selection.
    func setPhoneDailyHours(_ hours: Double) {
        phoneDailyHours = hours
        phoneTimeSelection = Self.phoneBucket(forHours: hours)
    }

    /// Maps continuous hours to the 4 legacy buckets used for the "wasted time" projection.
    static func phoneBucket(forHours hours: Double) -> Int {
        if hours < 1 { return 0 }
        if hours < 2 { return 1 }
        if hours < 4 { return 2 }
        return 3
    }

    func phoneHoursPerDayLabel(language: AppLanguage) -> String {
        let whole = Int(phoneDailyHours)
        let hasHalf = (phoneDailyHours - Double(whole)) >= 0.25
        return hasHalf ? "\(whole)h30" : "\(whole)h"
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
        case 3: return phoneTimeSelection != nil
        case 5: return !objectives.isEmpty
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

    func profileNicknames(language: AppLanguage) -> [String] {
        let keys = Subject.allCases.map(\.storageKey).filter { interests.contains($0) }
        if keys.isEmpty {
            return [AppLocalizable.string("onboarding.program.nickname.default", language: language)]
        }
        return keys.map { AppLocalizable.string("onboarding.program.nickname.\($0)", language: language) }
    }

    func recommendedProgramCourses(language: AppLanguage) -> [Course] {
        OnboardingCourseRecommender.recommendedCourses(interests: interests, language: language, limit: 4)
    }

    /// Rough estimate: ~12 minutes reclaimed per daily lesson, compounded over a year.
    var projectedHoursSavedPerYear: Int {
        max(24, (dailyLearningGoal * 12 * 365) / 60)
    }

    func persistInterests() {
        UserDefaults.standard.set(Array(interests).sorted(), forKey: Self.interestsKey)
    }

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

        let plans: [(index: Int, start: Double, duration: Double, checkpoints: [Double])] = [
            (0, 0.0, 2.4, [0.12, 0.28, 0.46, 0.63, 0.81, 0.94, 1.0]),
            (1, 1.1, 2.8, [0.08, 0.22, 0.39, 0.55, 0.72, 0.88, 1.0]),
            (2, 2.6, 3.1, [0.1, 0.24, 0.41, 0.58, 0.74, 0.9, 1.0]),
        ]

        for plan in plans {
            for checkpoint in plan.checkpoints {
                let delay = plan.start + plan.duration * checkpoint
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let self else { return }
                    withAnimation(.easeOut(duration: 0.35)) {
                        var bars = self.loadingBarProgress
                        guard bars.indices.contains(plan.index) else { return }
                        bars[plan.index] = checkpoint
                        self.loadingBarProgress = bars
                    }
                }
            }
        }

        let finishDelay = plans.map { $0.start + $0.duration }.max() ?? 5.5
        DispatchQueue.main.asyncAfter(deadline: .now() + finishDelay + 0.35) { [weak self] in
            self?.isLoadingComplete = true
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
