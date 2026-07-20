import SwiftUI
import RevenueCat

/// Nouveau coordinateur d'onboarding (V2) — 14 pages, transition douce fondu + glissement.
///
/// Flow : 0 Welcome · 1 Langue · 2 Objectif · 3 « Right place » · 4 Swipe cours ·
/// 5 Temps d'écran · 6 Semaines perdues · 7 Avis · 8 Loading · 9 **Login obligatoire** ·
/// 10 Fonctionnement de l'essai · 11 Rappel · 12 Paywall annuel · 13 Paywall comparatif.
struct OnboardingV2View: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AuthService.self) private var auth

    let onComplete: () -> Void

    @State private var vm = OnboardingV2ViewModel()
    @State private var store = StoreViewModel()
    // Persiste favoris/intérêts dans UserDefaults ; le `ProgressManager` de `ContentView`
    // les relira ensuite au lancement de l'app.
    @State private var progressManager = ProgressManager()
    @State private var step: Int = 0
    @State private var didFinish = false

    private let loginStep = 9
    private let paywallAnnualStep = 12
    private let paywallComparisonStep = 13
    private let lastStep = 13

    /// Étapes affichant les points de progression (objectif → loading).
    private static let dotSteps = Array(2...8)

    var body: some View {
        ZStack {
            OV2.bg.ignoresSafeArea()

            page(for: step)
                .id(step)
                .transition(.ov2)
        }
        .overlay(alignment: .top) {
            if Self.dotSteps.contains(step) {
                OnboardingV2ProgressDots(
                    current: (Self.dotSteps.firstIndex(of: step) ?? 0),
                    total: Self.dotSteps.count
                )
                .padding(.top, 14)
                .allowsHitTesting(false)
            }
        }
        .preferredColorScheme(.light)
        .animation(.spring(response: 0.55, dampingFraction: 0.9), value: step)
        .onChange(of: auth.isSignedIn) { _, signedIn in
            if signedIn, step == loginStep {
                advance()
            }
        }
        .onAppear {
            AnalyticsService.trackOnboardingStarted()
            trackStep(0)
        }
    }

    // MARK: - Pages

    @ViewBuilder
    private func page(for step: Int) -> some View {
        switch step {
        case 0:
            OnboardingV2Welcome(onNext: advance)
        case 1:
            OnboardingV2Language(onNext: advance)
        case 2:
            OnboardingV2Objective(vm: vm, onNext: advance)
        case 3:
            OnboardingV2RightPlace(vm: vm, onNext: advance)
        case 4:
            OnboardingV2SwipeCourses(vm: vm, onNext: advance)
        case 5:
            OnboardingV2PhoneTime(vm: vm, onNext: advance)
        case 6:
            OnboardingV2WeeksLost(vm: vm, onNext: advance)
        case 7:
            OnboardingV2Review(onNext: advance)
        case 8:
            OnboardingV2Loading(onNext: advance)
        case 9:
            OnboardingV2Login(onSignedIn: advance)
        case 10:
            OnboardingV2TrialSteps(onNext: advance)
        case 11:
            OnboardingV2Reminder(onNext: advance)
        case 12:
            OnboardingV2PaywallAnnual(
                store: store,
                onSubscribed: finish,
                onClose: advance
            )
        case 13:
            OnboardingV2PaywallComparison(
                store: store,
                onSubscribed: finish,
                onClose: finish
            )
        default:
            Color.clear
        }
    }

    // MARK: - Navigation

    private func advance() {
        // Skip les paywalls si déjà premium.
        if step == paywallAnnualStep - 1, store.isPremium {
            finish()
            return
        }
        guard step < lastStep else { finish(); return }
        OnboardingHaptics.selection()
        step += 1
        trackStep(step)
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        vm.persistAndComplete(progressManager: progressManager)
        AnalyticsService.trackOnboardingCompleted(
            sawPaywall: step >= paywallAnnualStep,
            isPremiumAtExit: store.isPremium
        )
        onComplete()
    }

    private func trackStep(_ step: Int) {
        AnalyticsService.trackOnboardingStepViewed(stepIndex: step)
    }
}
