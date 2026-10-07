import SwiftUI
import RevenueCat

/// Coordinateur d'onboarding V2 — séquence **fixe** (les pages valeur ne dépendent plus des
/// objectifs sélectionnés).
///
/// Welcome · Langue · Présentation (4 pages reliées par des points) · Preuve sociale (500 000
/// utilisateurs) · Prénom · Âge · Culture générale (curseur) · Motivation · Objectifs (multi) ·
/// Sujets (6 carrés) · « Sophia va t'aider » · Mission (gratuite à l'essai) · « Me cultiver »
/// (questions) ·
/// Temps d'écran (slider) · Ta vie en années · « Transforme ce temps » · Avis · « Fais bon
/// usage » · Swipe · Loading · Profil · Notifications · **Login** · Bienvenue à bord · Atouts ·
/// Essai · Rappel · Paywall
/// annuel · Paywall comparatif. Les pages « Se cultiver, c'est long et cher » et « Des cours
/// écrits par des docteurs et des profs » ont été retirées le 29/09/2026.
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
    /// Sign-in sheet opened from the welcome page by someone who already has an account.
    @State private var showExistingAccountSignIn = false

    private enum Screen: Hashable {
        case welcome, language, intro, socialProof, name, age, knowledge, motivation
        case objectives, topics, objectiveIntro, mission
        case questions, phoneTime, yearsGrid, transform, review, personalize
        case swipe, loading, profile, readingTime, notifications, login
        case welcomeAboard, features, trialSteps, reminder, paywallAnnual, paywallComparison

        /// Nom stable de l'écran, mémorisé pour reprendre l'onboarding au bon endroit : la
        /// séquence étant dynamique (page d'essai retirée quand l'offering n'inclut pas
        /// d'essai), l'index seul ne désigne pas un écran stable.
        var analyticsName: String {
            switch self {
            case .welcome: "welcome"
            case .language: "language"
            case .intro: "intro"
            case .socialProof: "social_proof"
            case .name: "name"
            case .age: "age"
            case .knowledge: "knowledge"
            case .motivation: "motivation"
            case .objectives: "objective"
            case .topics: "topics"
            case .objectiveIntro: "objective_intro"
            case .mission: "mission"
            case .questions: "questions"
            case .phoneTime: "phone_time"
            case .yearsGrid: "years_grid"
            case .transform: "transform"
            case .review: "review"
            case .personalize: "personalize"
            case .swipe: "swipe_courses"
            case .loading: "loading"
            case .profile: "profile"
            case .readingTime: "reading_time"
            case .notifications: "notifications"
            case .login: "login"
            case .welcomeAboard: "welcome_aboard"
            case .features: "features"
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
        var list: [Screen] = [.welcome, .language, .intro, .socialProof,
                              .name, .age, .knowledge, .motivation, .objectives, .topics, .objectiveIntro, .mission,
                              .questions, .phoneTime, .yearsGrid, .transform, .review, .personalize,
                              .swipe, .loading, .profile, .readingTime, .notifications, .login,
                              .welcomeAboard, .features]
        if store.offerings == nil || store.annualHasFreeTrial {
            list.append(.trialSteps)
        }
        list.append(contentsOf: [.reminder, .paywallAnnual, .paywallComparison])
        return list
    }

    private static let dotScreens: Set<Screen> = [
        .name, .age, .knowledge, .motivation, .objectives, .topics, .objectiveIntro, .mission,
        .questions, .phoneTime, .yearsGrid, .review, .swipe, .loading,
    ]

    private var current: Screen {
        let list = screens
        return list.indices.contains(stepIndex) ? list[stepIndex] : .paywallComparison
    }

    /// Where a resumed session picks up. Stored by name, so a sequence that gained or lost
    /// the trial page since cannot resume onto the wrong screen; an unknown name, or a page
    /// no longer in the sequence, simply starts from the beginning.
    private func restoreStepIndex() {
        guard let name = OnboardingResumeStore.step,
              let index = screens.firstIndex(where: { $0.analyticsName == name })
        else { return }
        stepIndex = index
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
        .sheet(isPresented: $showExistingAccountSignIn) {
            OnboardingV2ExistingAccountSheet(onSignedIn: {
                showExistingAccountSignIn = false
                finish()
            })
        }
        .onAppear {
            restoreStepIndex()
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
            OnboardingV2Welcome(
                onNext: advance,
                onExistingAccount: {
                    showExistingAccountSignIn = true
                }
            )
        case .language:
            OnboardingV2Language(onNext: advance)
        case .intro:
            OnboardingV2IntroCarousel(onNext: advance)
        case .socialProof:
            OnboardingV2SocialProof(onNext: advance)
        case .name:
            OnboardingV2Name(vm: vm, onNext: advance)
        case .age:
            OnboardingV2Age(vm: vm, onNext: advance)
        case .knowledge:
            OnboardingV2Knowledge(vm: vm, onNext: advance)
        case .motivation:
            OnboardingV2Motivation(vm: vm, onNext: advance)
        case .objectives:
            OnboardingV2Objective(vm: vm, onNext: advance)
        case .topics:
            OnboardingV2Topics(vm: vm, onNext: advance)
        case .objectiveIntro:
            OnboardingV2ObjectiveIntro(firstName: vm.trimmedFirstName, onNext: advance)
        case .mission:
            OnboardingV2Mission(onNext: advance)
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
            OnboardingV2Loading(firstName: vm.trimmedFirstName, onNext: advance)
        case .profile:
            OnboardingV2Profile(vm: vm, onNext: advance)
        case .readingTime:
            OnboardingV2ReadingTime(vm: vm, onNext: advance)
        case .notifications:
            OnboardingV2Notifications(vm: vm, onNext: advance)
        case .login:
            OnboardingV2Login(onSignedIn: advance)
        case .welcomeAboard:
            OnboardingV2WelcomeAboard(vm: vm, onNext: advance)
        case .features:
            OnboardingV2Features(vm: vm, onNext: advance)
        case .trialSteps:
            OnboardingV2TrialSteps(trialDays: store.annualTrialDays, onNext: advance)
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
        // Remembered on every step, so the app being killed here resumes here.
        OnboardingResumeStore.step = list[next].analyticsName
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        // The flow is over: a later reset should start from the welcome page, not resume
        // into a paywall.
        OnboardingResumeStore.clear()
        vm.persistAndComplete(progressManager: progressManager)
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
