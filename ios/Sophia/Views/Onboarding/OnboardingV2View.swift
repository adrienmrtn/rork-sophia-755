import SwiftUI
import RevenueCat

/// Coordinateur d'onboarding V2 — séquence **dynamique** selon les objectifs sélectionnés.
///
/// Fixe : Welcome · Langue · Objectifs (multi) · « Sophia va t'aider » · [pages objectifs] ·
/// Swipe · Avis · Loading · **Login** · Essai · Rappel · Paywall annuel · Paywall comparatif.
/// Les pages objectifs dépendent de la sélection (dédupliquées).
struct OnboardingV2View: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AuthService.self) private var auth

    let onComplete: () -> Void

    @State private var vm = OnboardingV2ViewModel()
    @State private var store = StoreViewModel()
    @State private var progressManager = ProgressManager()
    @State private var stepIndex: Int = 0
    @State private var didFinish = false

    private enum Screen: Hashable {
        case welcome, language, objectives, objectiveIntro
        case questions, screenTime, exams
        case swipe, review, loading, login, trialSteps, reminder, paywallAnnual, paywallComparison
    }

    /// Séquence complète, recalculée à partir des objectifs (stable une fois passés les objectifs).
    private var screens: [Screen] {
        var s: [Screen] = [.welcome, .language, .objectives, .objectiveIntro]
        for page in vm.objectivePages {
            switch page {
            case .questions: s.append(.questions)
            case .screenTime: s.append(.screenTime)
            case .exams: s.append(.exams)
            }
        }
        s += [.swipe, .review, .loading, .login, .trialSteps, .reminder, .paywallAnnual, .paywallComparison]
        return s
    }

    private static let dotScreens: Set<Screen> = [
        .objectives, .objectiveIntro, .questions, .screenTime, .exams, .swipe, .review, .loading,
    ]

    private var current: Screen {
        let list = screens
        return list.indices.contains(stepIndex) ? list[stepIndex] : .paywallComparison
    }

    var body: some View {
        ZStack {
            OV2.bg.ignoresSafeArea()

            page(for: current)
                .id(current)
                .transition(.ov2)
        }
        .overlay(alignment: .top) {
            if Self.dotScreens.contains(current) {
                OnboardingV2ProgressDots(current: dotIndex, total: dotTotal)
                    .padding(.top, 14)
                    .allowsHitTesting(false)
            }
        }
        .preferredColorScheme(.light)
        .animation(.spring(response: 0.55, dampingFraction: 0.9), value: stepIndex)
        .onChange(of: auth.isSignedIn) { _, signedIn in
            if signedIn, current == .login { advance() }
        }
        .onAppear {
            AnalyticsService.trackOnboardingStarted()
            AnalyticsService.trackOnboardingStepViewed(stepIndex: 0)
        }
    }

    // MARK: - Pages

    @ViewBuilder
    private func page(for screen: Screen) -> some View {
        switch screen {
        case .welcome:
            OnboardingV2Welcome(onNext: advance)
        case .language:
            OnboardingV2Language(onNext: advance)
        case .objectives:
            OnboardingV2Objective(vm: vm, onNext: advance)
        case .objectiveIntro:
            OnboardingV2ObjectiveIntro(onNext: advance)
        case .questions:
            OnboardingV2QuestionsScreen(onNext: advance)
        case .screenTime:
            OnboardingV2ScreenTimeGraph(onNext: advance)
        case .exams:
            OnboardingV2ExamsReviews(onNext: advance)
        case .swipe:
            OnboardingV2SwipeCourses(vm: vm, onNext: advance)
        case .review:
            OnboardingV2Review(onNext: advance)
        case .loading:
            OnboardingV2Loading(onNext: advance)
        case .login:
            OnboardingV2Login(onSignedIn: advance)
        case .trialSteps:
            OnboardingV2TrialSteps(onNext: advance)
        case .reminder:
            OnboardingV2Reminder(onNext: advance)
        case .paywallAnnual:
            OnboardingV2PaywallAnnual(store: store, onSubscribed: finish, onClose: advance)
        case .paywallComparison:
            OnboardingV2PaywallComparison(store: store, onSubscribed: finish, onClose: finish)
        }
    }

    // MARK: - Navigation

    private func advance() {
        let list = screens
        let next = stepIndex + 1
        guard next < list.count else { finish(); return }

        // Skip les paywalls si déjà premium.
        if list[next] == .paywallAnnual, store.isPremium {
            finish()
            return
        }

        OnboardingHaptics.selection()
        stepIndex = next
        AnalyticsService.trackOnboardingStepViewed(stepIndex: next)
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        vm.persistAndComplete(progressManager: progressManager)
        AnalyticsService.trackOnboardingCompleted(
            sawPaywall: current == .paywallAnnual || current == .paywallComparison,
            isPremiumAtExit: store.isPremium
        )
        onComplete()
    }

    // MARK: - Progress dots

    private var dotTotal: Int {
        screens.filter { Self.dotScreens.contains($0) }.count
    }

    private var dotIndex: Int {
        let dots = screens.filter { Self.dotScreens.contains($0) }
        return dots.firstIndex(of: current) ?? 0
    }
}
