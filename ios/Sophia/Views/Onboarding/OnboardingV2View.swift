import SwiftUI
import RevenueCat
import Supabase

/// Coordinateur d'onboarding V2 — séquence **fixe** (les pages valeur ne dépendent plus des
/// objectifs sélectionnés).
///
/// Welcome · Langue · Leçons · Chercheurs · Présentation (carrousel de 4 pages qui défilent
/// seules : quiz, parcours, duels, audio) · Preuve sociale (500 000 utilisateurs) · Prénom ·
/// Âge · Culture générale (curseur) · Motivation · Objectifs (multi) · Sujets (6 carrés) ·
/// « Sophia va t'aider » · Temps d'écran (slider) · Ta vie en années · « Transforme ce
/// temps » · « Me cultiver » (questions) · Mission (gratuite à l'essai) · « Fais bon usage » ·
/// Swipe · Heure de lecture · Courbe 90 jours · Notifications · Avis · Loading · Profil ·
/// **Login** · Ton profil (avatar, @) · Suis des profs · Bienvenue à bord · Atouts ·
/// Essai · Rappel · Paywall annuel · Paywall comparatif.
///
/// L'en-tête (flèche retour, segments du carrousel, barre de progression) est posé ici, une
/// fois, avec `safeAreaInset(edge: .top)` : les écrans se décalent sous lui sans le connaître.
struct OnboardingV2View: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AuthService.self) private var auth
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection

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
    /// Page et horloge du carrousel de présentation, partagées avec les segments de l'en-tête.
    @State private var carousel = OnboardingV2CarouselModel()
    /// Sens de la dernière navigation : la transition glisse dans l'autre sens au retour.
    @State private var slidesForward = true
    /// Logo animé joué une fois, à l'ouverture d'un onboarding qui démarre à la page d'accueil.
    @State private var showSplash: Bool = OnboardingV2View.startsAtWelcome

    private enum Screen: Hashable {
        case welcome, language, lessons, researchers, intro, socialProof, name, age, knowledge, motivation
        case objectives, topics, objectiveIntro, mission
        case questions, phoneTime, yearsGrid, transform, review, personalize
        case swipe, loading, profile, readingTime, curve90, notifications, login, account, followCreators
        case welcomeAboard, features, trialSteps, reminder, paywallAnnual, paywallComparison

        /// Nom stable de l'écran, mémorisé pour reprendre l'onboarding au bon endroit : la
        /// séquence étant dynamique (page d'essai retirée quand l'offering n'inclut pas
        /// d'essai), l'index seul ne désigne pas un écran stable.
        var analyticsName: String {
            switch self {
            case .welcome: "welcome"
            case .language: "language"
            case .lessons: "lessons"
            case .researchers: "researchers"
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
            case .curve90: "curve_90"
            case .notifications: "notifications"
            case .login: "login"
            case .account: "account"
            case .followCreators: "follow_creators"
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
        var list: [Screen] = [.welcome, .language, .lessons, .researchers, .intro, .socialProof,
                              .name, .age, .knowledge, .motivation, .objectives, .topics, .objectiveIntro,
                              .phoneTime, .yearsGrid, .transform, .questions, .mission, .personalize,
                              .swipe, .readingTime, .curve90, .notifications, .review, .loading, .profile,
                              .login, .account, .followCreators,
                              .welcomeAboard, .features]
        if store.offerings == nil || store.annualHasFreeTrial {
            list.append(.trialSteps)
        }
        list.append(contentsOf: [.reminder, .paywallAnnual, .paywallComparison])
        return list
    }

    // MARK: - En-tête

    private enum HeaderKind: Equatable {
        /// Aucun en-tête : accueil, puis connexion et tout ce qui suit.
        case none
        /// Flèche retour seule.
        case back
        /// Flèche retour + les quatre segments du carrousel.
        case segments
        /// Flèche retour + barre de progression de 200 pt.
        case progress
    }

    /// Écrans d'ouverture : la flèche retour, sans barre.
    private static let backOnlyScreens: Set<Screen> = [.language, .lessons, .researchers]

    /// Écrans comptés par la barre de progression, dans l'ordre du déroulé : de la preuve
    /// sociale au profil inclus.
    private static let progressScreens: [Screen] = [
        .socialProof, .name, .age, .knowledge, .motivation, .objectives, .topics, .objectiveIntro,
        .phoneTime, .yearsGrid, .transform, .questions, .mission, .personalize,
        .swipe, .readingTime, .curve90, .notifications, .review, .loading, .profile,
    ]

    private func headerKind(for screen: Screen) -> HeaderKind {
        if screen == .intro { return .segments }
        if Self.backOnlyScreens.contains(screen) { return .back }
        if Self.progressScreens.contains(screen) { return .progress }
        return .none
    }

    /// Avancement de la barre : le premier écran compté la montre à peine entamée, le
    /// dernier la remplit.
    private var progressValue: Double {
        guard let index = Self.progressScreens.firstIndex(of: current) else { return 0 }
        return Double(index + 1) / Double(Self.progressScreens.count)
    }

    /// L'onboarding démarre-t-il à la page d'accueil (premier lancement, ou reprise restée
    /// sur l'accueil) ? C'est le seul cas où le logo animé est joué.
    private static var startsAtWelcome: Bool {
        guard let step = OnboardingResumeStore.step else { return true }
        return step == Screen.welcome.analyticsName
    }

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
                .transition(.ov2Slide(
                    forward: slidesForward,
                    mirrored: layoutDirection == .rightToLeft,
                    distance: reduceMotion ? 0 : 64
                ))
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            header
        }
        .overlay {
            if showSplash {
                OnboardingV2Splash(onFinished: dismissSplash)
                    .transition(.opacity)
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
            // Une reprise en cours de route n'a pas à rejouer le logo.
            if current != .welcome { showSplash = false }
            AnalyticsService.shared.log(
                .onboardingStep,
                props: ["step": .string(current.analyticsName), "index": .int(stepIndex)]
            )
        }
        .task {
            notificationsSettled = await NotificationPermission.isSettled()
        }
    }

    /// L'en-tête de l'écran courant ; rien sur l'accueil, ni à partir de la connexion.
    @ViewBuilder
    private var header: some View {
        let kind: HeaderKind = headerKind(for: current)
        if kind != .none {
            OnboardingV2Header(
                backLabel: languageManager.text("training.backToTraining"),
                onBack: goBack
            ) {
                headerCenter(kind)
            }
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private func headerCenter(_ kind: HeaderKind) -> some View {
        switch kind {
        case .segments:
            OnboardingV2StorySegments(
                count: OnboardingV2CarouselModel.pageCount,
                current: carousel.page,
                startedAt: carousel.pageStartedAt,
                duration: OnboardingV2CarouselModel.pageDuration,
                isRunning: carousel.isRunning
            )
            .transition(.opacity)
        case .progress:
            DSProgressBar(value: progressValue)
                .transition(.opacity)
        case .none, .back:
            EmptyView()
        }
    }

    private func dismissSplash() {
        withAnimation(.easeOut(duration: 0.35)) {
            showSplash = false
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
                },
                // L'entrée de la page attend que le logo animé ait fini de jouer.
                entranceDelay: showSplash ? OnboardingV2Splash.totalDuration : 0
            )
        case .language:
            OnboardingV2Language(onNext: advance)
        case .lessons:
            OnboardingV2Lessons(onNext: advance)
        case .researchers:
            OnboardingV2Researchers(onNext: advance)
        case .intro:
            OnboardingV2IntroCarousel(model: carousel, onNext: advance)
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
        case .curve90:
            OnboardingV2Curve90(onNext: advance)
        case .notifications:
            OnboardingV2Notifications(vm: vm, onNext: advance)
        case .login:
            OnboardingV2Login(onSignedIn: advance)
        case .account:
            OnboardingV2Account(progressManager: progressManager, initialAvatarId: vm.avatarId, onNext: advance)
        case .followCreators:
            OnboardingV2FollowCreators(vm: vm, progressManager: progressManager, onNext: advance)
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

        // La page « Ton profil » (avatar, @) ne concerne qu'un compte qui vient d'être créé :
        // sans session (saut du simulateur) ou pour un compte existant, on passe.
        if list[next] == .account, !isNewAccount {
            next += 1
            guard next < list.count else { finish(); return }
        }

        // « Suis des profs » n'a rien à montrer sans créateur dans le catalogue.
        if list[next] == .followCreators, AuthorStore.all.isEmpty {
            next += 1
            guard next < list.count else { finish(); return }
        }

        // Skip les paywalls si déjà premium.
        if list[next] == .paywallAnnual, store.isPremium {
            finish()
            return
        }

        lastAdvanceAt = now
        // Le CTA vient de vibrer : on ne double pas. Les avances sans bouton (carrousel,
        // fin du swipe, « touche pour continuer ») gardent leur vibration légère.
        if !OV2HapticGate.justConfirmed {
            OnboardingHaptics.selection()
        }
        // Le carrousel repart toujours de sa première page quand on y entre en avançant.
        if list[next] == .intro {
            carousel.go(to: 0)
        }
        move(to: next, forward: true)
        // Remembered on every step, so the app being killed here resumes here.
        OnboardingResumeStore.step = list[next].analyticsName
        AnalyticsService.shared.log(
            .onboardingStep,
            props: ["step": .string(list[next].analyticsName), "index": .int(next)]
        )
    }

    /// Le compte connecté a été créé dans le dernier quart d'heure : c'est une inscription.
    private var isNewAccount: Bool {
        // `AuthService` apprend la session par un flux : au moment où la page de connexion
        // avance, elle peut ne pas l'avoir encore ; le client Supabase, lui, la connaît déjà.
        guard let created = (auth.currentUser ?? SupabaseManager.shared.auth.currentUser)?.createdAt else { return false }
        return Date().timeIntervalSince(created) < 15 * 60
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

    // MARK: - Retour arrière

    /// Revient d'un écran (ou d'une page du carrousel). Jamais avant l'accueil, et jamais
    /// une fois la connexion passée : ces écrans n'ont pas d'en-tête, donc pas de flèche.
    private func goBack() {
        guard headerKind(for: current) != .none else { return }

        // Dans le carrousel, la flèche remonte d'abord ses pages.
        if current == .intro, carousel.page > 0 {
            carousel.go(to: carousel.page - 1, hold: true)
            return
        }

        let list = screens
        var previous = stepIndex - 1
        while previous > 0, skipsWhenGoingBack(list[previous]) {
            previous -= 1
        }
        guard list.indices.contains(previous), previous < stepIndex else { return }

        // Revenu depuis la preuve sociale, le carrousel montre sa dernière page, à l'arrêt :
        // il ne doit pas renvoyer tout seul vers l'écran qu'on vient de quitter.
        if list[previous] == .intro {
            carousel.go(to: OnboardingV2CarouselModel.pageCount - 1, hold: true)
        }

        // La reprise suit aussi le retour : l'app tuée ici reprend ici.
        OnboardingResumeStore.step = list[previous].analyticsName
        move(to: previous, forward: false)
    }

    /// Écrans sautés au retour : ceux que `advance()` saute aussi, et ceux qui repartent
    /// seuls vers l'avant (le swipe déjà fait, le faux chargement) et renverraient
    /// l'utilisateur d'où il vient.
    private func skipsWhenGoingBack(_ screen: Screen) -> Bool {
        switch screen {
        case .notifications:
            return notificationsSettled
        case .swipe, .loading:
            return true
        default:
            return false
        }
    }

    /// Change d'écran. La transition d'un écran qui s'en va est celle qu'il portait à son
    /// dernier rendu : quand le sens change, il est donc posé d'abord, et l'index au tour de
    /// boucle suivant, pour que l'écran sortant glisse lui aussi dans le bon sens.
    private func move(to index: Int, forward: Bool) {
        if slidesForward == forward {
            stepIndex = index
        } else {
            slidesForward = forward
            DispatchQueue.main.async {
                stepIndex = index
            }
        }
    }
}
