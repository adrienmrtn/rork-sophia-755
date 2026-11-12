import SwiftUI

/// L'accueil « nouvelle génération » : un fil **paginé**, une carte par écran, qu'on fait
/// défiler d'un geste vertical comme un réseau vidéo (la carte suivante dépasse un peu en bas
/// pour dire qu'il y en a d'autres). L'en-tête et le segment « Pour toi / Abonnements » restent
/// fixes en haut. « Pour toi » est le deck local de `HomeDeckBuilder`, avec l'événement en cours
/// glissé dedans ; « Abonnements », les cours des créateurs suivis.
///
/// La page courante compte une impression après une seconde, et un passage si on la quitte
/// sans l'avoir ouverte (docs/events.md).
struct HomeFeedView: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    let discountManager: DiscountOfferManager
    let onOpenCourse: (Course) -> Void
    let onOpenCreator: (CourseAuthor) -> Void
    let onOpenCampaign: (Campaign) -> Void
    let onSearch: () -> Void
    let onBecomeCreator: () -> Void
    /// Abonné Premium : pas de carte de parrainage (les cours gratuits ne lui apportent rien).
    var isPremium: Bool = false
    /// Ouvre la page « Invite un ami ».
    var onInviteFriend: () -> Void = {}

    @State private var segment = 0
    @State private var deck: [Course] = []
    @State private var scrolledId: String?
    @State private var impressed: Set<String> = []
    @State private var opened: Set<String> = []
    @State private var skipped: Set<String> = []
    @State private var impressionTask: Task<Void, Never>?
    /// Les premières cartes sont entrées (apparition en cascade, rejouée au changement d'onglet).
    @State private var revealed = false

    /// Ce que la carte suivante laisse voir en bas de l'écran.
    private let peekHeight: CGFloat = 44
    /// Marge latérale de l'écran (en-tête, cartes).
    private let sideMargin: CGFloat = 24

    private var screen: String { segment == 0 ? "home" : "home_following" }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, sideMargin)
                .padding(.top, 8)

            // Deux onglets sur toute la largeur, moitié-moitié ; le trait bleu glisse de l'un à l'autre.
            HomeFeedTabs(
                items: [
                    languageManager.text("home.segment.forYou"),
                    languageManager.text("home.segment.following"),
                ],
                selection: $segment,
                dotOn: followingHasUnread ? 1 : nil,
                dotLabel: languageManager.text("home.following.newDot")
            )
            .padding(.top, 10)

            if segment == 1, !followedAuthors.isEmpty {
                followedRow
                    .padding(.top, 14)
                    .padding(.bottom, 2)
                    .transition(.opacity)
            }

            GeometryReader { geo in
                let pageHeight = max(320, geo.size.height - peekHeight)
                let items = pages
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            page(for: item, position: index, width: geo.size.width, height: pageHeight)
                                .frame(width: geo.size.width, height: pageHeight, alignment: .top)
                                .id(item.id)
                        }
                    }
                    .scrollTargetLayout()
                    // Le tap sur une carte ne doit pas attendre la fin d'un swipe : voir
                    // `ImmediateTouchScrollFixer` dans l'accueil classique.
                    .background(ImmediateTouchScrollFixer())

                    // Espace de fin (hors cibles de snap) pour que la dernière page s'aligne
                    // en haut malgré des pages un peu plus courtes que la zone visible.
                    Color.clear.frame(height: peekHeight)
                }
                // `.viewAligned` s'ancre sur les bords réels de chaque page : une carte par
                // swipe, sans dérive, là où `.paging` avance par pas fixes.
                .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                .scrollPosition(id: $scrolledId)
                .scrollIndicators(.hidden)
                .scrollDisabled(items.count <= 1)
                // Tirer vers le bas : le catalogue est relu (nouveaux cours, événements), le deck redistribué.
                .refreshable { await refreshFeed() }
            }
        }
        .background(DS.canvas.ignoresSafeArea())
        .onAppear {
            if deck.isEmpty { loadDeck() }
            revealed = true
        }
        // Parrainage : à l'ouverture et à chaque connexion, le code d'un lien d'invitation est
        // déclaré et la récompense relue.
        .task(id: AuthService.shared.isSignedIn) { await ReferralService.shared.sync() }
        .onChange(of: languageManager.current) { _, _ in loadDeck() }
        .onChange(of: progressManager.completedCount) { _, _ in loadDeck() }
        .onChange(of: scrolledId) { old, new in pageChanged(from: old, to: new) }
        .onChange(of: segment) { _, _ in
            restartAtTop()
            replayReveal()
        }
    }

    /// Les cartes du nouvel onglet rentrent en cascade, comme au premier affichage.
    private func replayReveal() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { revealed = false }
        DispatchQueue.main.async { revealed = true }
    }

    // MARK: - En-tête

    private var header: some View {
        // `sophia_mark` est le logo complet : le symbole et le mot « Sophia ».
        HStack(spacing: 10) {
            Image("sophia_mark")
                .resizable()
                .scaledToFit()
                .frame(height: 30)
                .accessibilityLabel(Text("Sophia"))
            Spacer(minLength: 0)
            streakPill
        }
    }

    private var streakPill: some View {
        HStack(spacing: 5) {
            // Une flamme fixe : pleine et chaude quand la série est en cours, en creux sinon.
            Image(systemName: progressManager.streak > 0 ? "flame.fill" : "flame")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(progressManager.streak > 0 ? DS.warm : DS.inkTertiary)
                .symbolEffect(.bounce, value: progressManager.streak)
            Text("\(progressManager.streak)")
                .font(DS.sans(.subheadline, .heavy))
                .foregroundStyle(DS.ink)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(Capsule().fill(DS.accentTint))
        .animation(DS.Motion.snappy, value: progressManager.streak)
        .accessibilityLabel(Text("\(progressManager.streak) \(languageManager.text(progressManager.streak > 1 ? "common.streak.days" : "common.streak.day"))"))
    }

    // MARK: - Les pages

    private var activeCampaign: Campaign? { CampaignStore.active().first }

    /// Les pages du segment courant.
    private var pages: [FeedItem] {
        segment == 0 ? forYouItems : followingItems
    }

    /// Le deck, avec l'événement en troisième position.
    private var forYouItems: [FeedItem] {
        guard !deck.isEmpty else { return [.notice(.allCaughtUp)] }
        var items: [FeedItem] = deck.map { .course($0) }
        if let campaign = activeCampaign {
            items.insert(.campaign(campaign), at: min(2, items.count))
        }
        // Le parrainage, en sixième position : jamais avant le premier cours terminé.
        if items.count >= 4, InviteFriend.showsFeedCard(progressManager: progressManager, isPremium: isPremium) {
            items.insert(.friendInvite, at: min(5, items.count))
        }
        return items
    }

    /// Les cours des créateurs suivis, précédés d'un mot quand tout est lu.
    private var followingItems: [FeedItem] {
        guard !followedAuthors.isEmpty else { return [.notice(.followingEmpty)] }
        let courses = followingCourses
        var items: [FeedItem] = courses.map { .course($0) }
        if courses.allSatisfy({ progressManager.courseStatus(for: $0.id) == .completed }) {
            items.insert(.notice(.followingUpToDate), at: 0)
        }
        return items
    }

    @ViewBuilder
    private func page(for item: FeedItem, position: Int, width: CGFloat, height: CGFloat) -> some View {
        // La couverture occupe la hauteur que le texte laisse libre (plus de vide sous
        // l'accroche), jusqu'à un carré ; sur un petit écran elle se raccourcit d'elle-même.
        let coverMaxHeight = width - sideMargin * 2
        Group {
            switch item {
            case .course(let course):
                let campaign = segment == 0 ? CampaignStore.activeCampaign(forCourseId: course.id) : nil
                let completed = segment == 1 && progressManager.courseStatus(for: course.id) == .completed
                CourseFeedCard(
                    course: course,
                    progressManager: progressManager,
                    tag: campaign?.title(for: languageManager.current) ?? (completed ? languageManager.text("common.read") : nil),
                    tagStyle: campaign != nil ? .warm : .accent,
                    screen: screen,
                    fillsPage: true,
                    coverMaxHeight: coverMaxHeight,
                    onOpen: { open(course, position: position) },
                    onOpenCreator: onOpenCreator
                )
            case .campaign(let campaign):
                EventFeedCard(campaign: campaign, progressManager: progressManager, fillsPage: true) {
                    onOpenCampaign(campaign)
                }
            case .creatorInvite:
                // L'invitation à écrire n'est plus glissée dans le fil.
                EmptyView()
            case .friendInvite:
                InviteFriendFeedCard(fillsPage: true, onInvite: onInviteFriend)
            case .video(let id):
                VideoFeedCard(title: id)
            case .notice(let notice):
                noticeCard(notice)
            }
        }
        .padding(.horizontal, sideMargin)
        .padding(.top, 10)
        // Les deux premières cartes entrent l'une après l'autre ; les suivantes sont déjà là.
        .homeReveal(revealed || position > 1, index: position)
    }

    private func noticeCard(_ notice: FeedNotice) -> some View {
        let (title, body): (String, String) = switch notice {
        case .followingEmpty:
            (languageManager.text("home.following.empty.title"), languageManager.text("home.following.empty.body"))
        case .followingUpToDate:
            (languageManager.text("home.following.upToDate.title"), languageManager.text("home.following.upToDate.body"))
        case .allCaughtUp:
            (languageManager.text("home.allCompleted"), languageManager.text("home.following.upToDate.body"))
        }
        return VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(DS.title(.headline, .semibold))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(body)
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: onSearch) {
                Text(languageManager.text("home.following.discover"))
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .padding(.top, 6)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .homeCard()
    }

    private func refreshFeed() async {
        await CatalogStore.shared.refresh(language: languageManager.current, force: true)
        loadDeck()
    }

    private func loadDeck() {
        let context = DeckContext.current(progressManager: progressManager)
        deck = HomeDeckBuilder.deck(
            from: ContentCatalog.activeCourses,
            context: context,
            isCompleted: { progressManager.courseStatus(for: $0) == .completed }
        )
        impressed = []
        opened = []
        skipped = []
        CourseImageMap.preloadImages(for: Array(deck.prefix(6)).map(\.id))
        CatalogStore.shared.prefetch(courseIds: Array(deck.prefix(8)).map(\.id), language: languageManager.current)
        restartAtTop()
    }

    // MARK: - Abonnements

    private var followedAuthors: [CourseAuthor] {
        progressManager.progress.followedCreatorSlugs.compactMap { AuthorStore.author(slug: $0) }
    }

    /// Les cours des créateurs suivis, ceux pas encore lus en premier.
    private var followingCourses: [Course] {
        let ids = followedAuthors.flatMap(\.courseIds)
        let courses = ids.compactMap { ContentCatalog.course(withId: $0) }
        let unread = courses.filter { progressManager.courseStatus(for: $0.id) != .completed }
        let read = courses.filter { progressManager.courseStatus(for: $0.id) == .completed }
        return unread + read
    }

    private var followingHasUnread: Bool {
        !followedAuthors.isEmpty && followingCourses.contains { progressManager.courseStatus(for: $0.id) != .completed }
    }

    private var followedRow: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(followedAuthors) { author in
                    Button {
                        onOpenCreator(author)
                    } label: {
                        VStack(spacing: 5) {
                            AuthorAvatarView(author: author, size: 48)
                            Text(author.name.split(separator: " ").first.map(String.init) ?? author.name)
                                .font(DS.sans(.caption, .bold))
                                .foregroundStyle(DS.ink)
                                .lineLimit(1)
                        }
                        .frame(width: 56)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.pressable)
                }
                Button(action: onSearch) {
                    VStack(spacing: 5) {
                        ZStack {
                            Circle().strokeBorder(DS.inkSecondary, style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(DS.inkSecondary)
                        }
                        .frame(width: 48, height: 48)
                        Text(languageManager.text("training.discover"))
                            .font(DS.sans(.caption, .bold))
                            .foregroundStyle(DS.inkSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(width: 60)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
            }
            .padding(.horizontal, sideMargin)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Ouverture et mesure

    private func open(_ course: Course, position: Int) {
        opened.insert(course.id)
        DeckSkipStore.clear(course.id)
        AnalyticsService.shared.log(
            .cardOpen,
            courseId: course.id,
            screen: screen,
            position: position,
            algoVersion: AnalyticsService.algoVersion
        )
        onOpenCourse(course)
    }

    /// Changement de segment ou nouveau deck : on repart de la première page, qui compte
    /// comme vue si on y reste une seconde.
    private func restartAtTop() {
        impressionTask?.cancel()
        impressionTask = nil
        let first = pages.first
        scrolledId = first?.id
        if let course = first?.asCourse { scheduleImpression(for: course, position: 0) }
    }

    /// Une page qui part sans avoir été ouverte est un passage ; celle qui arrive compte comme
    /// vue après une seconde. Une légère vibration accompagne chaque swipe.
    private func pageChanged(from old: String?, to new: String?) {
        impressionTask?.cancel()
        impressionTask = nil
        let items = pages
        if let old, let oldIndex = items.firstIndex(where: { $0.id == old }), let course = items[oldIndex].asCourse {
            cardLeft(course, position: oldIndex)
        }
        // Un vrai swipe seulement : au changement d'onglet (l'ancienne page n'est plus dans la
        // liste), l'onglet a déjà vibré.
        if let old, new != nil, old != new, items.contains(where: { $0.id == old }) {
            Haptics.tap()
        }
        if let new, let newIndex = items.firstIndex(where: { $0.id == new }), let course = items[newIndex].asCourse {
            scheduleImpression(for: course, position: newIndex)
        }
    }

    /// Une carte compte comme vue après une seconde à l'écran (docs/events.md).
    private func scheduleImpression(for course: Course, position: Int) {
        guard !impressed.contains(course.id) else { return }
        let screen = screen
        impressionTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            impressed.insert(course.id)
            AnalyticsService.shared.log(
                .cardImpression,
                courseId: course.id,
                screen: screen,
                position: position,
                algoVersion: AnalyticsService.algoVersion
            )
            discountManager.registerSwipe()
        }
    }

    /// Vue puis quittée sans être ouverte : un passage, qui nourrit la fatigue du deck.
    private func cardLeft(_ course: Course, position: Int) {
        guard impressed.contains(course.id), !opened.contains(course.id), !skipped.contains(course.id) else { return }
        skipped.insert(course.id)
        DeckSkipStore.registerSkip(course.id)
        AnalyticsService.shared.log(
            .cardSkip,
            courseId: course.id,
            screen: screen,
            position: position,
            algoVersion: AnalyticsService.algoVersion
        )
    }
}
