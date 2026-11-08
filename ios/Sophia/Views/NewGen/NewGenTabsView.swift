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

/// Les 4 onglets de la maquette : Accueil, Explorer, Apprendre, Profil. Chaque onglet a sa
/// pile de navigation ; le lecteur reste présenté par `ContentView` au-dessus de tout, via
/// `selectedCourse`.
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
    @State private var learnPath: [NewGenRoute] = []
    @State private var profilePath: [NewGenRoute] = []

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(languageManager.text("tab.home"), systemImage: "house", value: 0) {
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

            Tab(languageManager.text("tab.explore"), systemImage: "safari", value: 1) {
                NavigationStack(path: $explorePath) {
                    ExploreView(
                        progressManager: progressManager,
                        onOpenCourse: { explorePath.append(.course(id: $0.id, source: .search)) },
                        onOpenCreator: { explorePath.append(.creator(slug: $0.slug)) },
                        onOpenCampaign: { explorePath.append(.campaign(slug: $0.slug)) },
                        onOpenSubject: { explorePath.append(.subject($0)) }
                    )
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(for: NewGenRoute.self) { route in
                        destination(route) { explorePath.append($0) }
                    }
                }
                .audioMiniPlayerInset(onOpen: openAudioPlayer)
            }

            Tab(languageManager.text("tab.learn"), systemImage: "graduationcap", value: 2) {
                NavigationStack(path: $learnPath) {
                    LearnHubView(
                        progressManager: progressManager,
                        onResumeCourse: { openReader($0, source: .myCourses) },
                        onOpenPath: { learnPath.append(.path) },
                        onOpenTraining: { learnPath.append(.training) }
                    )
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(for: NewGenRoute.self) { route in
                        destination(route) { learnPath.append($0) }
                    }
                }
                .audioMiniPlayerInset(onOpen: openAudioPlayer)
            }

            Tab(languageManager.text("tab.profile"), systemImage: "person", value: 3) {
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
        }
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
        case .subject(let subject):
            SubjectCoursesView(
                subject: subject,
                courses: ContentCatalog.activeCourses.filter { $0.subject == subject },
                progressManager: progressManager,
                selectedCourse: $selectedCourse
            )
            .toolbar(.hidden, for: .navigationBar)
        case .progression:
            ProfileView(
                progressManager: progressManager,
                store: storeVM,
                selectedCourse: $selectedCourse,
                onShowPaywall: { onShowPaywall(.debloquerCours) },
                onShowBlockerPaywall: { onShowPaywall(.blocker) },
                onResetOnboarding: onResetOnboarding
            )
            .toolbar(.hidden, for: .navigationBar)
        case .friends:
            FriendsHubView()
                .toolbar(.hidden, for: .navigationBar)
        case .path:
            LearningPathView(progressManager: progressManager, selectedCourse: $selectedCourse)
                .toolbar(.hidden, for: .navigationBar)
        case .training:
            TrainingView(
                progressManager: progressManager,
                store: storeVM,
                isPremium: storeVM.isPremium,
                onShowQuizPaywall: { onShowPaywall(.entrainement) }
            )
            .toolbar(.hidden, for: .navigationBar)
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
