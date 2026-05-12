import SwiftUI
import AVFoundation
import StoreKit
import RevenueCat
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentScreen: Int = 0
    @Published var phoneTimeSelection: Int? = nil
    @Published var objectives: Set<String> = []
    @Published var primaryObjective: String? = nil
    @Published var interests: Set<String> = []
    @Published var interestOrder: [String] = []
    @Published var ageRange: String? = nil
    @Published var dailyLearningGoal: Int = 1 {
        didSet {
            UserDefaults.standard.set(dailyLearningGoal, forKey: "sophia_daily_learning_goal")
        }
    }
    @Published var themeLevels: [Subject: Double] = [:]
    @Published var loadingProgress: Double = 0
    @Published var loadingStep: String = ""
    @Published var isLoadingComplete: Bool = false

    let totalScreens = 22

    init() {
        if let savedObjectives = UserDefaults.standard.array(forKey: "sophia_onboarding_objectives") as? [String] {
            objectives = Set(savedObjectives)
        }
        primaryObjective = UserDefaults.standard.string(forKey: "sophia_onboarding_primary_objective")

        if let savedInterests = UserDefaults.standard.array(forKey: "sophia_onboarding_interests_order") as? [String] {
            interestOrder = savedInterests
            interests = Set(savedInterests)
        }

        if UserDefaults.standard.object(forKey: "sophia_daily_learning_goal") != nil {
            dailyLearningGoal = UserDefaults.standard.integer(forKey: "sophia_daily_learning_goal")
        } else {
            UserDefaults.standard.set(dailyLearningGoal, forKey: "sophia_daily_learning_goal")
        }

        themeLevels = loadThemeLevels()
    }

    var wastedTimePerYear: String {
        guard let selection = phoneTimeSelection else { return "" }
        switch selection {
        case 0: return "365 heures"
        case 1: return "547 heures"
        case 2: return "1 095 heures"
        case 3: return "1 460 heures"
        default: return ""
        }
    }

    var wastedTimeDays: String {
        guard let selection = phoneTimeSelection else { return "" }
        switch selection {
        case 0: return "15 jours"
        case 1: return "23 jours"
        case 2: return "45 jours"
        case 3: return "60 jours"
        default: return ""
        }
    }

    var canProceed: Bool {
        switch currentScreen {
        case 3: return phoneTimeSelection != nil
        case 5: return !objectives.isEmpty
        case 10: return !interests.isEmpty
        case 14: return ageRange != nil
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
            primaryObjective = objective
        }

        if objectives.isEmpty {
            primaryObjective = nil
        } else if let value = primaryObjective, objectives.contains(value) {
            primaryObjective = value
        } else {
            primaryObjective = objectives.sorted().first
        }

        UserDefaults.standard.set(Array(objectives), forKey: "sophia_onboarding_objectives")
        UserDefaults.standard.set(primaryObjective, forKey: "sophia_onboarding_primary_objective")
    }

    func themeLevelValue(for subject: Subject) -> Double {
        themeLevels[subject] ?? 0
    }

    func themeTier(for subject: Subject) -> Int {
        tier(forValue: themeLevelValue(for: subject))
    }

    func setThemeLevelValue(_ value: Double, for subject: Subject) {
        let clamped = max(0, min(1, value))
        themeLevels[subject] = clamped
        saveThemeLevels(themeLevels)
        let best3 = bestFreemiumSubjects(from: themeLevels)
        UserDefaults.standard.set(best3, forKey: "sophia_freemium_subjects")
    }

    func toggleInterest(_ interest: String) {
        if interests.contains(interest) {
            interests.remove(interest)
            interestOrder.removeAll(where: { $0 == interest })
        } else {
            interests.insert(interest)
            interestOrder.append(interest)
        }

        UserDefaults.standard.set(interestOrder, forKey: "sophia_onboarding_interests_order")
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

    private func loadThemeLevels() -> [Subject: Double] {
        let defaults = Subject.allCases.reduce(into: [Subject: Double]()) { acc, subject in
            acc[subject] = 0
        }
        guard let data = UserDefaults.standard.data(forKey: "sophia_theme_levels") else {
            return defaults
        }

        if let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            var mapped = defaults
            for (raw, value) in decoded {
                if let subject = Subject(rawValue: raw) {
                    mapped[subject] = max(0, min(1, value))
                }
            }
            return mapped
        }

        if let decodedInt = try? JSONDecoder().decode([String: Int].self, from: data) {
            var mapped = defaults
            for (raw, level) in decodedInt {
                if let subject = Subject(rawValue: raw) {
                    let v: Double
                    switch max(0, min(2, level)) {
                    case 0: v = 0.15
                    case 1: v = 0.50
                    default: v = 0.85
                    }
                    mapped[subject] = v
                }
            }
            return mapped
        }

        return defaults
    }

    private func saveThemeLevels(_ levels: [Subject: Double]) {
        let encoded = Dictionary(uniqueKeysWithValues: levels.map { ($0.key.rawValue, $0.value) })
        guard let data = try? JSONEncoder().encode(encoded) else { return }
        UserDefaults.standard.set(data, forKey: "sophia_theme_levels")
    }

    private func bestFreemiumSubjects(from levels: [Subject: Double]) -> [String] {
        let ranked = Subject.allCases
            .map { subject in
                (subject: subject, tier: tier(forValue: levels[subject] ?? 0), value: levels[subject] ?? 0)
            }
            .sorted { lhs, rhs in
                if lhs.tier != rhs.tier { return lhs.tier > rhs.tier }
                if lhs.value != rhs.value { return lhs.value > rhs.value }
                return Subject.allCases.firstIndex(of: lhs.subject) ?? 0 < Subject.allCases.firstIndex(of: rhs.subject) ?? 0
            }
        return Array(ranked.prefix(3)).map(\.subject.rawValue)
    }

    private func tier(forValue value: Double) -> Int {
        if value < 0.34 { return 0 }
        if value < 0.67 { return 1 }
        return 2
    }

    private func subjectForInterestLabel(_ label: String) -> Subject? {
        Subject.allCases.first { $0.shortName == label }
    }
}
