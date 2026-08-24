import SwiftUI
import RevenueCat

/// Coordinateur d'onboarding V2 — séquence **fixe** (les pages valeur ne dépendent plus des
/// objectifs sélectionnés).
///
/// Welcome · Langue · Objectifs (multi) · « Sophia va t'aider » · « Me cultiver » (questions) ·
/// Temps d'écran (slider) · Ta vie en années · « Transforme ce temps » · « Fais bon usage » ·
/// Swipe · Loading · Profil · Notifications · **Login** · Essai · Rappel · Paywall annuel ·
/// Paywall comparatif.
struct OnboardingV2View: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AuthService.self) private var auth

    let onComplete: () -> Void

    @State private var vm = OnboardingV2ViewModel()
    @State private var store = StoreViewModel()
    @State private var progressManager = ProgressManager()
    @State private var stepIndex: Int = 0
    @State private var didFinish = false
    /// Blocks a second `advance()` fired within a short window (e.g. racing timers
    /// after the last swipe card), which would skip the loading screen.
    @State private var lastAdvanceAt: Date?
    /// `true` once iOS has settled the notification authorization: the page asking for it can
    /// no longer achieve anything, so it is skipped. Resolved at launch, long before the page
    /// is reached; defaulting to `false` shows the page while the status is still unknown.
    @State private var notificationsSettled = false

    private enum Screen: Hashable {
        case welcome, language, objectives, objectiveIntro
        case questions, phoneTime, yearsGrid, transform, review, personalize
        case swipe, loading, profile, notifications, login
        case trialSteps, reminder, paywallAnnual, paywallComparison

        /// Nom envoyé à l'analytics : la séquence étant dynamique (page d'essai retirée quand
        /// l'offering n'inclut pas d'essai), l'index seul ne désigne pas un écran stable.
        var analyticsName: String {
            switch self {
            case .welcome: "welcome"
            case .language: "language"
            case .objectives: "objective"
            case .objectiveIntro: "objective_intro"
            case .questions: "questions"
            case .phoneTime: "phone_time"
            case .yearsGrid: "years_grid"
            case .transform: "transform"
            case .review: "review"
            case .personalize: "personalize"
            case .swipe: "swipe_courses"
            case .loading: "loading"
            case .profile: "profile"
            case .notifications: "notifications"
            case .login: "login"
            case .trialSteps: "trial_steps"
            case .reminder: "reminder"
            case .paywallAnnual: "paywall_annual"
            case .paywallComparison: "paywall_comparison"
            }
        }
    }

    /// Séquence complète et fixe. Les pages « valeur » (me cultiver → temps d'écran) sont
    /// désormais montrées quel que soit l'objectif choisi. `profile` est l'écran de
    /// récompense « Voici ton profil » inséré juste avant la création de compte.
    ///
    /// `trialSteps` détaille la chronologie de l'essai gratuit : la page est retirée quand
    /// l'offering servie (variante d'expérience RevenueCat) n'inclut pas d'essai, sinon on
    /// promettrait un essai que l'utilisateur n'aura pas.
    private var screens: [Screen] {
        var list: [Screen] = [.welcome, .language, .objectives, .objectiveIntro,
                              .questions, .phoneTime, .yearsGrid, .transform, .review, .personalize,
                              .swipe, .loading, .profile, .notifications, .login]
        if store.offerings == nil || store.annualHasFreeTrial {
            list.append(.trialSteps)
        }
        list.append(contentsOf: [.reminder, .paywallAnnual, .paywallComparison])
        return list
    }

    private static let dotScreens: Set<Screen> = [
        .objectives, .objectiveIntro, .questions, .phoneTime, .yearsGrid, .review, .swipe, .loading,
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
            AnalyticsService.trackOnboardingStepViewed(stepIndex: 0, stepName: Screen.welcome.analyticsName)
        }
        .task {
            notificationsSettled = await NotificationPermission.isSettled()
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
        case .phoneTime:
            OnboardingV2PhoneTime(vm: vm, onNext: advance)
        case .yearsGrid:
            OnboardingV2YearsGrid(vm: vm, onNext: advance)
        case .transform:
            OnboardingV2Transform(onNext: advance)
        case .review:
            OnboardingV2Review(onNext: advance)
        case .personalize:
            OnboardingV2Personalize(onNext: advance)
        case .swipe:
            OnboardingV2SwipeCourses(vm: vm, onNext: advance)
        case .loading:
            OnboardingV2Loading(onNext: advance)
        case .profile:
            OnboardingV2Profile(vm: vm, onNext: advance)
        case .notifications:
            OnboardingV2Notifications(vm: vm, onNext: advance)
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
        let now = Date()
        if let lastAdvanceAt, now.timeIntervalSince(lastAdvanceAt) < 0.4 {
            return
        }

        let list = screens
        var next = stepIndex + 1
        guard next < list.count else { finish(); return }

        // La demande de notifications n'a rien à obtenir quand iOS a déjà tranché : le système
        // n'affiche son alerte qu'une fois, la page ne coûterait qu'un tap de plus.
        if list[next] == .notifications, notificationsSettled {
            next += 1
            guard next < list.count else { finish(); return }
        }

        // Skip les paywalls si déjà premium.
        if list[next] == .paywallAnnual, store.isPremium {
            finish()
            return
        }

        lastAdvanceAt = now
        OnboardingHaptics.selection()
        stepIndex = next
        AnalyticsService.trackOnboardingStepViewed(stepIndex: next, stepName: list[next].analyticsName)
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
