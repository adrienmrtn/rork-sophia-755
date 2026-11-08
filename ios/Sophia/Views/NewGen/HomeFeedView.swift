import SwiftUI

/// L'accueil « nouvelle génération » : un fil **paginé**, une carte par écran, qu'on fait
/// défiler d'un geste vertical comme un réseau vidéo (la carte suivante dépasse un peu en bas
/// pour dire qu'il y en a d'autres). L'en-tête et le segment « Pour toi / Abonnements » restent
/// fixes en haut. « Pour toi » est le deck local de `HomeDeckBuilder`, avec l'événement en cours
/// et l'invitation à créer glissés dedans ; « Abonnements », les cours des créateurs suivis.
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

    @State private var segment = 0
    @State private var deck: [Course] = []
    @State private var inviteDismissed = HomeFeedView.isInviteDismissed()
    @State private var scrolledId: String?
    @State private var impressed: Set<String> = []
    @State private var opened: Set<String> = []
    @State private var skipped: Set<String> = []
    @State private var impressionTask: Task<Void, Never>?

    private static let inviteDismissKey = "sophia_creator_invite_dismissed_at"

    /// Ce que la carte suivante laisse voir en bas de l'écran.
    private let peekHeight: CGFloat = 44

    private var screen: String { segment == 0 ? "home" : "home_following" }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 8)

            SegmentedPills(
                items: [
                    languageManager.text("home.segment.forYou"),
                    languageManager.text("home.segment.following"),
                ],
                selection: $segment,
                dotOn: followingHasUnread ? 1 : nil
            )
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 10)

            if segment == 1, !followedAuthors.isEmpty {
                followedRow
                    .padding(.horizontal, 20)
                    .padding(.bottom, 6)
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
            }
        }
        .background(DS.canvas.ignoresSafeArea())
        .onAppear { if deck.isEmpty { loadDeck() } }
        .onChange(of: languageManager.current) { _, _ in loadDeck() }
        .onChange(of: progressManager.completedCount) { _, _ in loadDeck() }
        .onChange(of: scrolledId) { old, new in pageChanged(from: old, to: new) }
        .onChange(of: segment) { _, _ in restartAtTop() }
    }

    // MARK: - En-tête

    private var header: some View {
        HStack(spacing: 10) {
            Image("sophia_mark")
                .resizable()
                .scaledToFit()
                .frame(height: 28)
                .accessibilityLabel(Text("Sophia"))
            Spacer(minLength: 0)
            streakPill
            RoundIconButton(
                systemImage: "magnifyingglass",
                accessibilityLabel: languageManager.text("tab.explore"),
                action: onSearch
            )
        }
    }

    private var streakPill: some View {
        HStack(spacing: 5) {
            if progressManager.streak > 0 {
                AnimatedFlameBadge(size: 16)
            } else {
                Image(systemName: "flame")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.inkTertiary)
            }
            Text("\(progressManager.streak)")
                .font(DS.sans(.subheadline, .bold))
                .foregroundStyle(DS.ink)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(Capsule().fill(DS.surface))
        .overlay(Capsule().strokeBorder(DS.hairline, lineWidth: 1))
        .accessibilityLabel(Text("\(progressManager.streak) \(languageManager.text(progressManager.streak > 1 ? "common.streak.days" : "common.streak.day"))"))
    }

    // MARK: - Les pages

    private var activeCampaign: Campaign? { CampaignStore.active().first }

    /// Les pages du segment courant.
    private var pages: [FeedItem] {
        segment == 0 ? forYouItems : followingItems
    }

    /// Le deck, l'événement en troisième position et l'invitation en septième.
    private var forYouItems: [FeedItem] {
        guard !deck.isEmpty else { return [.notice(.allCaughtUp)] }
        var items: [FeedItem] = deck.map { .course($0) }
        if let campaign = activeCampaign {
            items.insert(.campaign(campaign), at: min(2, items.count))
        }
        if !inviteDismissed, items.count >= 4 {
            items.insert(.creatorInvite, at: min(6, items.count))
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
        // La couverture garde son 16:9 tant que la page est assez haute ; sur un petit écran
        // elle se raccourcit pour laisser la place au texte et aux compteurs.
        let coverHeight = min((width - 32) * 9 / 16, height * 0.42)
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
                    coverHeight: coverHeight,
                    onOpen: { open(course, position: position) },
                    onOpenCreator: onOpenCreator
                )
            case .campaign(let campaign):
                EventFeedCard(campaign: campaign, progressManager: progressManager, fillsPage: true) {
                    onOpenCampaign(campaign)
                }
            case .creatorInvite:
                CreatorInviteCard(
                    fillsPage: true,
                    onBecomeCreator: onBecomeCreator,
                    onLater: {
                        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.inviteDismissKey)
                        withAnimation(.easeInOut(duration: 0.25)) { inviteDismissed = true }
                    }
                )
            case .video(let id):
                VideoFeedCard(title: id)
            case .notice(let notice):
                noticeCard(notice)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
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
        return VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(DS.title(.headline, .heavy))
                .foregroundStyle(DS.ink)
            Text(body)
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: onSearch) {
                Text(languageManager.text("home.following.discover"))
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(DS.accent))
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(DS.surface))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
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
        restartAtTop()
    }

    /// Masquée pour deux semaines après « Plus tard ».
    private static func isInviteDismissed() -> Bool {
        let stamp = UserDefaults.standard.double(forKey: inviteDismissKey)
        guard stamp > 0 else { return false }
        return Date().timeIntervalSince1970 - stamp < 14 * 24 * 3_600
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
            HStack(alignment: .top, spacing: 14) {
                ForEach(followedAuthors) { author in
                    Button {
                        onOpenCreator(author)
                    } label: {
                        VStack(spacing: 5) {
                            AuthorAvatarView(author: author, size: 48)
                            Text(author.name.split(separator: " ").first.map(String.init) ?? author.name)
                                .font(DS.sans(.caption, .semibold))
                                .foregroundStyle(DS.ink)
                                .lineLimit(1)
                        }
                        .frame(width: 60)
                    }
                    .buttonStyle(.plain)
                }
                Button(action: onSearch) {
                    VStack(spacing: 5) {
                        ZStack {
                            Circle().strokeBorder(DS.inkTertiary, style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(DS.inkSecondary)
                        }
                        .frame(width: 48, height: 48)
                        Text(languageManager.text("training.discover"))
                            .font(DS.sans(.caption, .semibold))
                            .foregroundStyle(DS.inkSecondary)
                            .lineLimit(1)
                    }
                    .frame(width: 60)
                }
                .buttonStyle(.plain)
            }
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
        if old != nil, new != nil, old != new {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
