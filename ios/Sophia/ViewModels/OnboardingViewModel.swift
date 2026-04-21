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
    var ageRange: String? = nil
    var loadingProgress: Double = 0
    var loadingStep: String = ""
    var isLoadingComplete: Bool = false

    let totalScreens = 18

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
        case 8: return !interests.isEmpty
        case 10: return ageRange != nil
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
}
