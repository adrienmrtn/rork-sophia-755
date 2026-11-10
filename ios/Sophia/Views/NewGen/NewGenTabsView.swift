import SwiftUI

/// Les écrans qu'un onglet peut pousser. Les cours sont désignés par leur id : `Course` n'est
/// pas `Hashable`, et un id suffit à le retrouver dans le catalogue.
enum NewGenRoute: Hashable {
    /// La fiche d'un cours, avec l'origine rapportée quand le lecteur s'ouvrira.
    case course(id: String, source: CourseOpenSource)
    case creator(slug: String)
    case campaign(slug: String)
    case courseList(ProfileListKind)
    case subject(Subject)
    /// Un « univers » de l'onglet Explorer : une sous-catégorie du catalogue, dans la langue courante.
    case universe(subcategory: String)
    /// L'ancien profil (rang, matières, quiz, amis, anti-scroll), désormais page secondaire.
    case progression
    case friends
    case path
    case training
}

/// Les listes du profil : à lire (favoris), lus, aimés.
enum ProfileListKind: String, Hashable, CaseIterable {
    case toRead, read, liked
}

/// Les onglets : Accueil, Explorer, Parcours, Entraînement, Profil, et Duels quand l'app est en anglais. Parcours et Entraînement
/// sont les écrans de la navigation classique, gardés tels quels pour ne pas perdre les anciens
/// lecteurs (l'onglet « Apprendre » de la maquette a été retiré). Chaque onglet a sa pile de
/// navigation ; le lecteur reste présenté par `ContentView` au-dessus de tout, via `selectedCourse`.
struct NewGenTabsView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.openURL) private var openURL
    let progressManager: ProgressManager
    let storeVM: StoreViewModel
    let discountManager: DiscountOfferManager
    @Binding var selectedTab: Int
    @Binding var selectedCourse: Course?
    let onShowPaywall: (SophiaPaywallContext) -> Void
    let onOpenAntiScroll: () -> Void
    var onResetOnboarding: (() -> Void)? = nil
    let openAudioPlayer: () -> Void

    @State private var homePath: [NewGenRoute] = []
    @State private var explorePath: [NewGenRoute] = []
    @State private var profilePath: [NewGenRoute] = []

    /// L'onglet Duels n'existe qu'en anglais pour l'instant (questions de la bêta) : il fait six
    /// onglets, que la barre du système ne sait pas montrer (voir `SophiaTabScaffold`).
    private var showsDuels: Bool { FeatureFlags.duelsVisible(language: languageManager.current) }

    var body: some View {
        Group {
            if showsDuels {
                SophiaTabScaffold(selection: $selectedTab, items: tabItems, onReselect: popToRoot) { tab in
                    switch tab {
                    case 0: homeTab
                    case 1: exploreTab
                    case 2: pathTab
                    case 3: trainingTab
                    case FeatureFlags.duelsTab: duelsTab
                    default: profileTab
                    }
                }
            } else {
                TabView(selection: $selectedTab) {
                    Tab(languageManager.text("tab.home"), systemImage: "house", value: 0) {
                        homeTab
                    }
                    Tab(languageManager.text("tab.explore"), systemImage: "safari", value: 1) {
                        exploreTab
                    }
                    Tab(languageManager.text("tab.path"), systemImage: "point.bottomleft.forward.to.point.topright.scurvepath", value: 2) {
                        pathTab
                    }
                    Tab(languageManager.text("tab.training"), systemImage: "arrow.triangle.2.circlepath", value: 3) {
                        trainingTab
                    }
                    Tab(languageManager.text("tab.profile"), systemImage: "person", value: 4) {
                        profileTab
                    }
                }
            }
        }
        .onChange(of: showsDuels) { _, visible in
            if !visible, selectedTab == FeatureFlags.duelsTab { selectedTab = 0 }
        }
        // `sophia://author/<slug>` : la page du créateur dans l'onglet Accueil.
        .onChange(of: DeepLinkRouter.shared.token, initial: true) { _, _ in openPendingCreator() }
    }

    // MARK: - Onglets

    /// Les six onglets de la barre maison, Duels entre Entraînement et Profil. Accueil et
    /// Explorer restent en vie (fil, recherche) ; les autres rejouent leur `onAppear` à chaque visite.
    private var tabItems: [SophiaTabItem] {
        [
            SophiaTabItem(value: 0, title: languageManager.text("tab.home"), systemImage: "house", keepsAlive: true),
            SophiaTabItem(value: 1, title: languageManager.text("tab.explore"), systemImage: "safari", keepsAlive: true),
            SophiaTabItem(value: 2, title: languageManager.text("tab.path"), systemImage: "point.bottomleft.forward.to.point.topright.scurvepath"),
            SophiaTabItem(value: 3, title: languageManager.text("tab.training"), systemImage: "arrow.triangle.2.circlepath"),
            SophiaTabItem(value: FeatureFlags.duelsTab, title: languageManager.text("tab.duels"), systemImage: "trophy"),
            SophiaTabItem(value: 4, title: languageManager.text("tab.profile"), systemImage: "person"),
        ]
    }

    /// Toucher l'onglet déjà affiché ramène sa pile à la racine, comme la barre du système.
    private func popToRoot(_ tab: Int) {
        switch tab {
        case 0: homePath.removeAll()
        case 1: explorePath.removeAll()
        case 4: profilePath.removeAll()
        default: break
        }
    }

    private var homeTab: some View {
        NavigationStack(path: $homePath) {
            HomeFeedView(
                progressManager: progressManager,
                discountManager: discountManager,
                onOpenCourse: { homePath.append(.course(id: $0.id, source: .feed)) },
                onOpenCreator: { homePath.append(.creator(slug: $0.slug)) },
                onOpenCampaign: { homePath.append(.campaign(slug: $0.slug)) },
                onSearch: { selectedTab = 1 },
                onBecomeCreator: openCreatorStudio
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: NewGenRoute.self) { route in
                destination(route) { homePath.append($0) }
            }
        }
        .audioMiniPlayerInset(onOpen: openAudioPlayer)
    }

    private var exploreTab: some View {
        NavigationStack(path: $explorePath) {
            ExploreView(
                progressManager: progressManager,
                onOpenCourse: { explorePath.append(.course(id: $0.id, source: .search)) },
                onOpenCreator: { explorePath.append(.creator(slug: $0.slug)) },
                onOpenCampaign: { explorePath.append(.campaign(slug: $0.slug)) },
                onOpenUniverse: { explorePath.append(.universe(subcategory: $0)) }
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: NewGenRoute.self) { route in
                destination(route) { explorePath.append($0) }
            }
        }
        .audioMiniPlayerInset(onOpen: openAudioPlayer)
    }

    private var pathTab: some View {
        LearningPathView(progressManager: progressManager, selectedCourse: $selectedCourse)
            .audioMiniPlayerInset(onOpen: openAudioPlayer)
    }

    private var trainingTab: some View {
        TrainingView(
            progressManager: progressManager,
            store: storeVM,
            isPremium: storeVM.isPremium,
            onShowQuizPaywall: { onShowPaywall(.entrainement) }
        )
        .audioMiniPlayerInset(onOpen: openAudioPlayer)
    }

    private var profileTab: some View {
        NavigationStack(path: $profilePath) {
            ProfileV2View(
                progressManager: progressManager,
                store: storeVM,
                onOpenCourse: { profilePath.append(.course(id: $0.id, source: .profile)) },
                onResumeCourse: { openReader($0, source: .profile) },
                onOpenCreator: { profilePath.append(.creator(slug: $0.slug)) },
                onOpenList: { profilePath.append(.courseList($0)) },
                onOpenCampaign: { profilePath.append(.campaign(slug: $0.slug)) },
                onOpenProgression: { profilePath.append(.progression) },
                onOpenFriends: { profilePath.append(.friends) },
                onOpenAntiScroll: onOpenAntiScroll,
                onDiscoverCreators: { selectedTab = 1 },
                onBecomeCreator: openCreatorStudio,
                onShowPaywall: { onShowPaywall(.debloquerCours) },
                onResetOnboarding: onResetOnboarding
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: NewGenRoute.self) { route in
                destination(route) { profilePath.append($0) }
            }
        }
        .audioMiniPlayerInset(onOpen: openAudioPlayer)
    }

    private var duelsTab: some View {
        DuelsHomeView(progressManager: progressManager)
            .audioMiniPlayerInset(onOpen: openAudioPlayer)
    }

    private func openPendingCreator() {
        let router = DeepLinkRouter.shared
        guard let slug = router.pendingCreatorSlug else { return }
        guard AuthorStore.author(slug: slug) != nil else {
            router.discardCreator()
            return
        }
        _ = router.consumeCreator()
        selectedTab = 0
        homePath.append(.creator(slug: slug))
    }

    // MARK: - Destinations

    @ViewBuilder
    private func destination(_ route: NewGenRoute, push: @escaping (NewGenRoute) -> Void) -> some View {
        switch route {
        case .course(let id, let source):
            if let course = ContentCatalog.course(withId: id) {
                CourseDetailView(
                    course: course,
                    progressManager: progressManager,
                    onStart: { openReader(course, source: source) },
                    onOpenCreator: { push(.creator(slug: $0.slug)) },
                    onOpenCourse: { push(.course(id: $0.id, source: .author)) }
                )
                .toolbar(.hidden, for: .navigationBar)
            } else {
                missing
            }
        case .creator(let slug):
            if let author = AuthorStore.author(slug: slug) {
                CreatorPageView(
                    author: author,
                    progressManager: progressManager,
                    onOpenCourse: { push(.course(id: $0.id, source: .author)) },
                    onOpenCampaign: { push(.campaign(slug: $0.slug)) }
                )
                .toolbar(.hidden, for: .navigationBar)
            } else {
                missing
            }
        case .campaign(let slug):
            if let campaign = CampaignStore.campaign(slug: slug) {
                EventPageView(
                    campaign: campaign,
                    progressManager: progressManager,
                    onOpenCourse: { push(.course(id: $0.id, source: .event)) },
                    onOpenCreator: { push(.creator(slug: $0.slug)) },
                    onBecomeCreator: openCreatorStudio
                )
                .toolbar(.hidden, for: .navigationBar)
            } else {
                missing
            }
        case .courseList(let kind):
            ProfileCourseListView(
                kind: kind,
                progressManager: progressManager,
                onOpenCourse: { push(.course(id: $0.id, source: .profile)) }
            )
            .toolbar(.hidden, for: .navigationBar)
        case .universe(let subcategory):
            UniverseCoursesView(
                subcategory: subcategory,
                progressManager: progressManager,
                onOpenCourse: { push(.course(id: $0.id, source: .search)) }
            )
            .toolbar(.hidden, for: .navigationBar)
        case .subject(let subject):
            SubjectCoursesView(
                subject: subject,
                courses: ContentCatalog.activeCourses.filter { $0.subject == subject },
                progressManager: progressManager,
                selectedCourse: $selectedCourse
            )
            .toolbar(.hidden, for: .navigationBar)
        // Les trois pages ci-dessous étaient des racines d'onglet : elles n'ont pas de bouton
        // retour, c'est la barre de navigation système (et le geste de bord) qui le fournit.
        case .progression:
            ProfileView(
                progressManager: progressManager,
                store: storeVM,
                selectedCourse: $selectedCourse,
                onShowPaywall: { onShowPaywall(.debloquerCours) },
                onShowBlockerPaywall: { onShowPaywall(.blocker) },
                onResetOnboarding: onResetOnboarding
            )
            .modifier(SystemBackBar())
        case .friends:
            FriendsHubView()
                .toolbar(.hidden, for: .navigationBar)
        case .path:
            LearningPathView(progressManager: progressManager, selectedCourse: $selectedCourse)
                .modifier(SystemBackBar())
        case .training:
            TrainingView(
                progressManager: progressManager,
                store: storeVM,
                isPremium: storeVM.isPremium,
                onShowQuizPaywall: { onShowPaywall(.entrainement) }
            )
            .modifier(SystemBackBar())
        }
    }

    private var missing: some View {
        Text(languageManager.text("library.empty.title"))
            .font(DS.sans(.body))
            .foregroundStyle(DS.inkSecondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DS.canvas.ignoresSafeArea())
    }

    // MARK: - Actions

    /// Le lecteur plein écran, par la porte unique de `ContentView` (cours gratuit du jour,
    /// événement `course_open` avec sa source).
    private func openReader(_ course: Course, source: CourseOpenSource) {
        AnalyticsService.shared.pendingCourseOpenSource = source
        selectedCourse = course
    }

    private func openCreatorStudio() {
        guard let url = AppConfig.creatorStudioURL(language: languageManager.current) else { return }
        openURL(url)
    }
}

/// Barre de navigation système réduite à son bouton retour, sur le fond de l'app, pour les
/// pages qui n'ont pas de bouton retour à elles.
private struct SystemBackBar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DS.canvas, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(DS.accent)
    }
}

/// Les amis et leur classement, en page secondaire du profil.
struct FriendsHubView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    RoundIconButton(systemImage: "chevron.left", accessibilityLabel: languageManager.text("common.close")) { dismiss() }
                    Text(languageManager.text("profile.page.friends"))
                        .font(DS.title(.title2, .heavy))
                        .foregroundStyle(DS.ink)
                    Spacer()
                }
                FriendsLeaderboardSection(social: SocialService.shared)
            }
            .padding(20)
        }
        .background(DS.canvas.ignoresSafeArea())
    }
}
