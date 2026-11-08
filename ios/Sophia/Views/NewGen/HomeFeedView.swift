import SwiftUI

/// L'accueil « nouvelle génération » : un seul fil vertical, « Pour toi » (le deck local de
/// `HomeDeckBuilder`, avec l'événement en cours et l'invitation à créer glissés dedans) ou
/// « Abonnements » (les cours des créateurs suivis). Chaque carte compte une impression après
/// une seconde à l'écran, et un passage si elle disparaît sans avoir été ouverte.
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
    @State private var impressed: Set<String> = []
    @State private var opened: Set<String> = []
    @State private var skipped: Set<String> = []
    @State private var impressionTasks: [String: Task<Void, Never>] = [:]

    private static let inviteDismissKey = "sophia_creator_invite_dismissed_at"

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 14) {
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
                .padding(.bottom, 4)

                if segment == 0 {
                    ForEach(Array(forYouItems.enumerated()), id: \.element.id) { index, item in
                        feedCard(for: item, position: index)
                            .padding(.horizontal, 16)
                    }
                } else {
                    followingSection
                }

                Color.clear.frame(height: 24)
            }
            .padding(.bottom, 8)
        }
        .scrollIndicators(.hidden)
        .background(DS.canvas.ignoresSafeArea())
        .onAppear { if deck.isEmpty { loadDeck() } }
        .onChange(of: languageManager.current) { _, _ in loadDeck() }
        .onChange(of: progressManager.completedCount) { _, _ in loadDeck() }
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

    // MARK: - Pour toi

    private var activeCampaign: Campaign? { CampaignStore.active().first }

    /// Le deck, l'événement en troisième position et l'invitation en septième.
    private var forYouItems: [FeedItem] {
        var items: [FeedItem] = deck.map { .course($0) }
        if let campaign = activeCampaign {
            items.insert(.campaign(campaign), at: min(2, items.count))
        }
        if !inviteDismissed, items.count >= 4 {
            items.insert(.creatorInvite, at: min(6, items.count))
        }
        return items
    }

    @ViewBuilder
    private func feedCard(for item: FeedItem, position: Int) -> some View {
        switch item {
        case .course(let course):
            let campaign = CampaignStore.activeCampaign(forCourseId: course.id)
            CourseFeedCard(
                course: course,
                progressManager: progressManager,
                tag: campaign?.title(for: languageManager.current),
                tagStyle: .warm,
                onOpen: { open(course, position: position) },
                onOpenCreator: onOpenCreator
            )
            .onAppear { scheduleImpression(for: course, position: position) }
            .onDisappear { cardLeft(course, position: position) }
        case .campaign(let campaign):
            EventFeedCard(campaign: campaign, progressManager: progressManager) {
                onOpenCampaign(campaign)
            }
        case .creatorInvite:
            CreatorInviteCard(
                onBecomeCreator: onBecomeCreator,
                onLater: {
                    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.inviteDismissKey)
                    withAnimation(.easeInOut(duration: 0.25)) { inviteDismissed = true }
                }
            )
        case .video(let id):
            VideoFeedCard(title: id)
        }
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
        impressionTasks.values.forEach { $0.cancel() }
        impressionTasks = [:]
        CourseImageMap.preloadImages(for: Array(deck.prefix(6)).map(\.id))
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

    @ViewBuilder
    private var followingSection: some View {
        if followedAuthors.isEmpty {
            emptyCard(
                title: languageManager.text("home.following.empty.title"),
                body: languageManager.text("home.following.empty.body"),
                cta: languageManager.text("home.following.discover"),
                action: onSearch
            )
            .padding(.horizontal, 16)
        } else {
            followedRow
                .padding(.horizontal, 20)

            let courses = followingCourses
            if courses.allSatisfy({ progressManager.courseStatus(for: $0.id) == .completed }) {
                emptyCard(
                    title: languageManager.text("home.following.upToDate.title"),
                    body: languageManager.text("home.following.upToDate.body"),
                    cta: languageManager.text("home.following.discover"),
                    action: onSearch
                )
                .padding(.horizontal, 16)
            } else {
                NewGenSectionTitle(text: languageManager.text("home.following.news"))
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
            }
            ForEach(Array(courses.enumerated()), id: \.element.id) { index, course in
                CourseFeedCard(
                    course: course,
                    progressManager: progressManager,
                    tag: progressManager.courseStatus(for: course.id) == .completed ? languageManager.text("common.read") : nil,
                    screen: "home_following",
                    onOpen: { open(course, position: index) },
                    onOpenCreator: onOpenCreator
                )
                .padding(.horizontal, 16)
            }
        }
    }

    private var followedRow: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(followedAuthors) { author in
                    Button {
                        onOpenCreator(author)
                    } label: {
                        VStack(spacing: 6) {
                            AuthorAvatarView(author: author, size: 56)
                            Text(author.name.split(separator: " ").first.map(String.init) ?? author.name)
                                .font(DS.sans(.caption, .semibold))
                                .foregroundStyle(DS.ink)
                                .lineLimit(1)
                        }
                        .frame(width: 64)
                    }
                    .buttonStyle(.plain)
                }
                Button(action: onSearch) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle().strokeBorder(DS.inkTertiary, style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(DS.inkSecondary)
                        }
                        .frame(width: 56, height: 56)
                        Text(languageManager.text("training.discover"))
                            .font(DS.sans(.caption, .semibold))
                            .foregroundStyle(DS.inkSecondary)
                            .lineLimit(1)
                    }
                    .frame(width: 64)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }

    private func emptyCard(title: String, body: String, cta: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(DS.title(.headline, .heavy))
                .foregroundStyle(DS.ink)
            Text(body)
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: action) {
                Text(cta)
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

    // MARK: - Ouverture et mesure

    private func open(_ course: Course, position: Int) {
        opened.insert(course.id)
        DeckSkipStore.clear(course.id)
        AnalyticsService.shared.log(
            .cardOpen,
            courseId: course.id,
            screen: segment == 0 ? "home" : "home_following",
            position: position,
            algoVersion: AnalyticsService.algoVersion
        )
        onOpenCourse(course)
    }

    /// Une carte compte comme vue après une seconde à l'écran (docs/events.md).
    private func scheduleImpression(for course: Course, position: Int) {
        guard !impressed.contains(course.id), impressionTasks[course.id] == nil else { return }
        impressionTasks[course.id] = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            impressed.insert(course.id)
            impressionTasks[course.id] = nil
            AnalyticsService.shared.log(
                .cardImpression,
                courseId: course.id,
                screen: "home",
                position: position,
                algoVersion: AnalyticsService.algoVersion
            )
            discountManager.registerSwipe()
        }
    }

    /// Vue puis quittée sans être ouverte : un passage, qui nourrit la fatigue du deck.
    private func cardLeft(_ course: Course, position: Int) {
        impressionTasks[course.id]?.cancel()
        impressionTasks[course.id] = nil
        guard impressed.contains(course.id), !opened.contains(course.id), !skipped.contains(course.id) else { return }
        skipped.insert(course.id)
        DeckSkipStore.registerSkip(course.id)
        AnalyticsService.shared.log(
            .cardSkip,
            courseId: course.id,
            screen: "home",
            position: position,
            algoVersion: AnalyticsService.algoVersion
        )
    }
}
