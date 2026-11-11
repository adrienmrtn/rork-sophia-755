import SwiftUI

/// Le profil de la maquette : identité, compteurs, trophées et ligue des duels, les cartes
/// illustrées de l'Entraînement et de « Ma progression », Mes abonnements, le classement des
/// amis, Badges, listes À lire / Lus / Aimés, puis l'anti-scroll. L'ancien profil reste
/// accessible comme page « Ma progression ».
struct ProfileV2View: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AuthService.self) private var auth
    let progressManager: ProgressManager
    let store: StoreViewModel
    let onOpenCourse: (Course) -> Void
    /// Plus utilisé ici (la section « Reprendre » a quitté le profil) ; gardé pour l'appelant.
    let onResumeCourse: (Course) -> Void
    let onOpenCreator: (CourseAuthor) -> Void
    let onOpenList: (ProfileListKind) -> Void
    /// Plus utilisé ici (la carte « Deviens créateur » a quitté le profil) ; gardé pour l'appelant.
    let onOpenCampaign: (Campaign) -> Void
    let onOpenProgression: () -> Void
    let onOpenTraining: () -> Void
    let onOpenAntiScroll: () -> Void
    let onDiscoverCreators: () -> Void
    /// Plus utilisé ici (la carte « Deviens créateur » a quitté le profil) ; gardé pour l'appelant.
    let onBecomeCreator: () -> Void
    var onShowPaywall: (() -> Void)? = nil
    var onResetOnboarding: (() -> Void)? = nil

    @Bindable private var social = SocialService.shared
    @State private var listSegment = 0
    @State private var showSettings = false
    @State private var showAvatarPicker = false
    @State private var showBadges = false
    /// Un lien d'ami (`sophia://friend/<handle>`) ouvert depuis l'extérieur, à confirmer.
    @State private var friendLink: FriendLinkTarget?

    private var language: AppLanguage { languageManager.current }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                titleRow
                identity
                statsCard
                trophiesCard
                trainingCard
                progressCard
                followingSection
                // Les amis et leur classement, à même la page (plus de page à part).
                FriendsLeaderboardSection(social: social, myAvatarId: progressManager.avatarId)
                badgesSection
                listsSection
                secondaryPages
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(DS.canvas.ignoresSafeArea())
        // Le @ affiché en tête, le classement des amis et les demandes reçues.
        .task(id: auth.isSignedIn) {
            if auth.isSignedIn {
                await social.refreshAll()
            } else if !auth.isBootstrapping {
                social.clearLocalState()
            }
        }
        // Les trophées et la ligue, là où les duels existent.
        .task(id: duelsRefreshKey) {
            if auth.isSignedIn, duelsVisible {
                await DuelService.shared.refreshHome()
            }
        }
        .onChange(of: DeepLinkRouter.shared.pendingFriendHandle, initial: true) { _, _ in
            guard let handle = DeepLinkRouter.shared.pendingFriendHandle else { return }
            friendLink = FriendLinkTarget(handle: handle)
            // Retiré au tour suivant : les onglets lisent la même demande pour venir sur le profil.
            Task { _ = DeepLinkRouter.shared.consumeFriend() }
        }
        .sheet(item: $friendLink) { target in
            FriendLinkSheet(handle: target.handle) {
                Task { await social.refreshLeaderboard() }
            }
            .presentationDetents([.height(380)])
            .presentationDragIndicator(.visible)
            .sophiaSheetChrome()
        }
        .sheet(isPresented: $showBadges) {
            BadgesPageView(progressManager: progressManager)
        }
        .sheet(isPresented: $showAvatarPicker) {
            AvatarPickerSheet(current: progressManager.avatarId, initial: String(displayName.prefix(1)).uppercased()) { progressManager.setAvatar($0) }
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(
                progressManager: progressManager,
                store: store,
                onShowPaywall: onShowPaywall,
                onResetOnboarding: onResetOnboarding,
                onDismiss: { showSettings = false }
            )
            .sophiaColorScheme()
        }
    }

    // MARK: - Identité

    private var titleRow: some View {
        HStack {
            Text(languageManager.text("profile.title"))
                .font(DS.title(.largeTitle, .heavy))
                .foregroundStyle(DS.ink)
            Spacer()
            RoundIconButton(systemImage: "gearshape", accessibilityLabel: languageManager.text("settings.title")) {
                showSettings = true
            }
        }
    }

    private var hasHandle: Bool {
        guard let handle = social.myHandle else { return false }
        return !handle.isEmpty
    }

    private var displayName: String {
        if let handle = social.myHandle, !handle.isEmpty { return handle }
        let interests = OnboardingViewModel.userInterestKeys()
        let keys = Subject.allCases.map(\.storageKey).filter { interests.contains($0) }
        guard let first = keys.first else { return languageManager.text("onboarding.program.nickname.default") }
        return languageManager.text("onboarding.program.nickname.\(first)")
    }

    /// Le mois du premier cours ouvert, faute de date de création de compte.
    private var memberSince: String? {
        let starts = progressManager.progress.courseProgress.values.compactMap(\.startedAt).sorted()
        guard let first = starts.first, let date = Campaign.parseDay(String(first.prefix(10))) else { return nil }
        let formatter = DateFormatter()
        formatter.locale = language.foundationLocale
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter.string(from: date)
    }

    private var identity: some View {
        HStack(spacing: 14) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showAvatarPicker = true
            } label: {
                AvatarCircle(avatarId: progressManager.avatarId, initial: String(displayName.prefix(1)).uppercased(), size: 64)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(languageManager.text("profile.avatar.title"))
            VStack(alignment: .leading, spacing: 3) {
                // Le @ du compte ; sans compte (ou tant qu'il n'est pas lu), le surnom de l'onboarding.
                Text(hasHandle ? "@\(displayName)" : displayName)
                    .font(DS.title(.title3, .heavy))
                    .foregroundStyle(DS.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let memberSince {
                    Text(String(format: languageManager.text("profile.member.since"), memberSince))
                        .font(DS.sans(.footnote))
                        .foregroundStyle(DS.inkSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var statsCard: some View {
        HStack(spacing: 8) {
            StatCounter(
                systemImage: "flame.fill",
                iconTint: DS.warm,
                iconBackground: DS.warm.opacity(0.18),
                value: String(format: languageManager.text("common.daysShort"), progressManager.streak),
                label: languageManager.text("friends.stats.streak").lowercased()
            )
            Rectangle().fill(DS.hairline).frame(width: 1, height: 36)
            StatCounter(
                systemImage: "book",
                iconTint: DS.accent,
                iconBackground: DS.accentTint,
                value: "\(progressManager.completedCount)",
                label: languageManager.text("profile.stat.read")
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(DS.surface))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
    }

    // MARK: - Trophées et ligue

    /// Trophées, ligue et duels n'ont de sens que là où les duels existent.
    private var duelsVisible: Bool { FeatureFlags.duelsVisible(language: language) }

    private var duelsRefreshKey: String { "\(auth.isSignedIn)-\(duelsVisible)" }

    /// La ligue du lecteur sur son illustration, avec ses trophées : la même carte que sur le
    /// profil d'un ami. Rien sans compte, ni tant que la page des duels n'a jamais été lue.
    @ViewBuilder
    private var trophiesCard: some View {
        if duelsVisible, auth.isSignedIn, let home = DuelService.shared.home {
            let league = home.currentLeague
            let shape = RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
            ZStack(alignment: .bottomLeading) {
                DuelLeagueBackdrop(league: league, thumb: true)
                LinearGradient(
                    colors: [DuelPalette.night.opacity(0.05), DuelPalette.night.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                HStack(alignment: .bottom, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(languageManager.text("duel.trophies.title").uppercasedInApp())
                            .font(DS.sans(.caption2, .bold))
                            .tracking(1.1)
                            .foregroundStyle(.white.opacity(0.8))
                        Text(DuelFormat.leagueName(league, language: language))
                            .font(.jakarta(size: 22, weight: .heavy))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    Spacer(minLength: 8)
                    DuelTrophyCount(value: home.profile.trophies, size: 20, color: .white)
                }
                .padding(14)
            }
            .frame(height: 104)
            .frame(maxWidth: .infinity)
            .clipShape(shape)
            .overlay(shape.strokeBorder(DS.hairline, lineWidth: 1))
            .dsSoftShadow()
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: - Abonnements

    private var followedAuthors: [CourseAuthor] {
        progressManager.progress.followedCreatorSlugs.compactMap { AuthorStore.author(slug: $0) }
    }

    private var followingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            NewGenSectionTitle(text: languageManager.text("profile.following"), trailing: followedAuthors.isEmpty ? nil : "· \(followedAuthors.count)")
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(followedAuthors) { author in
                        Button { onOpenCreator(author) } label: {
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
                    Button(action: onDiscoverCreators) {
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
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Badges

    /// Trois badges : ceux que le lecteur a choisi d'afficher, complétés par ses derniers gagnés,
    /// puis par les plus proches d'être obtenus. « Tout voir » ouvre la collection.
    private var profileBadges: [Badge] {
        let all = BadgeCatalog.all(language: language)
        let stats = BadgeStats(progressManager: progressManager)
        var picked = progressManager.featuredBadgeIds.compactMap { id in all.first { $0.id == id } }
        let earned = all
            .filter { progressManager.isBadgeEarned($0.id) && !picked.contains($0) }
            .sorted { (progressManager.progress.earnedBadges[$0.id] ?? "") > (progressManager.progress.earnedBadges[$1.id] ?? "") }
        picked += earned
        if picked.count < 3 {
            let closest = all
                .filter { !progressManager.isBadgeEarned($0.id) && $0.metric != .league }
                .sorted { Double(stats.progress(for: $0)) / Double($0.target) > Double(stats.progress(for: $1)) / Double($1.target) }
            picked += closest
        }
        return Array(picked.prefix(3))
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                NewGenSectionTitle(text: languageManager.text("profile.badges"))
                Button {
                    showBadges = true
                } label: {
                    HStack(spacing: 4) {
                        Text(languageManager.text("badges.seeAll"))
                            .font(DS.sans(.subheadline, .bold))
                        Image(systemName: "chevron.forward")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(DS.accent)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            BadgeRow(
                badges: profileBadges,
                earned: { progressManager.isBadgeEarned($0.id) },
                onTap: { _ in showBadges = true }
            )
        }
        .onAppear { progressManager.refreshBadges() }
    }

    // MARK: - Listes

    private func courses(for kind: ProfileListKind) -> [Course] {
        switch kind {
        case .toRead: progressManager.favoriteCourses
        case .read: progressManager.progress.courseProgress
            .filter { $0.value.isCompleted }
            .sorted { ($0.value.completedAt ?? "") > ($1.value.completedAt ?? "") }
            .compactMap { ContentCatalog.course(withId: $0.key) }
        case .liked: progressManager.likedCourses
        }
    }

    private var listsSection: some View {
        let kinds = ProfileListKind.allCases
        let kind = kinds[min(listSegment, kinds.count - 1)]
        let items = courses(for: kind)
        return VStack(alignment: .leading, spacing: 12) {
            SegmentedPills(
                items: kinds.map { "\(languageManager.text($0.titleKey)) · \(courses(for: $0).count)" },
                selection: $listSegment
            )
            if items.isEmpty {
                Text(languageManager.text(kind.emptyKey))
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(items.prefix(3)) { course in
                    CompactCourseRow(
                        course: course,
                        meta: "\(CreatorIdentity.forCourse(course.id).name) · \(NewGenFormat.minutes(ReadingTime.minutes(for: course, language: language), language: language))",
                        onTap: { onOpenCourse(course) }
                    )
                }
                if items.count > 3 {
                    Button {
                        onOpenList(kind)
                    } label: {
                        Text(languageManager.text("library.seeMore"))
                            .font(DS.sans(.subheadline, .bold))
                            .foregroundStyle(DS.accentSoft)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Cartes illustrées (Entraînement, Ma progression)

    /// L'entrée de l'Entraînement, qui n'a plus d'onglet à lui.
    private var trainingCard: some View {
        posterCard(
            image: "training_poster",
            title: languageManager.text("training.title"),
            subtitle: languageManager.text("training.locked.tagline"),
            action: onOpenTraining
        )
    }

    /// L'entrée de la page « Ma progression » (rang, matières, quiz).
    private var progressCard: some View {
        posterCard(
            image: "progress_poster",
            title: languageManager.text("profile.progress.title"),
            subtitle: languageManager.text("profile.progress.subtitle"),
            action: onOpenProgression
        )
    }

    /// Une carte d'entrée illustrée (papier découpé du site) : vignette, titre, une ligne, chevron.
    private func posterCard(image: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(DS.title(.title3, .heavy))
                        .foregroundStyle(DS.ink)
                    Text(subtitle)
                        .font(DS.sans(.subheadline))
                        .foregroundStyle(DS.inkSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.inkTertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(DS.surface))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
            .dsSoftShadow()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Anti-scroll

    /// L'entrée de l'anti-scroll : une carte illustrée comme les autres, plus une ligne de liste.
    private var secondaryPages: some View {
        posterCard(
            image: "antiscroll_poster",
            title: languageManager.text("profile.page.antiScroll"),
            subtitle: languageManager.text("tiktokBlocker.card.off.subtitle"),
            action: onOpenAntiScroll
        )
    }
}

extension ProfileListKind {
    var titleKey: String {
        switch self {
        case .toRead: "profile.list.toRead"
        case .read: "profile.list.read"
        case .liked: "profile.list.liked"
        }
    }

    var emptyKey: String {
        switch self {
        case .toRead: "profile.list.toRead.empty"
        case .read: "profile.list.read.empty"
        case .liked: "profile.list.liked.empty"
        }
    }
}

/// Le @ d'un lien d'ami à confirmer, présenté en feuille.
private struct FriendLinkTarget: Identifiable {
    let handle: String
    var id: String { handle }
}

/// Une liste complète du profil (À lire, Lus, Aimés).
struct ProfileCourseListView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    let kind: ProfileListKind
    let progressManager: ProgressManager
    let onOpenCourse: (Course) -> Void

    private var courses: [Course] {
        switch kind {
        case .toRead: progressManager.favoriteCourses
        case .read: progressManager.progress.courseProgress
            .filter { $0.value.isCompleted }
            .sorted { ($0.value.completedAt ?? "") > ($1.value.completedAt ?? "") }
            .compactMap { ContentCatalog.course(withId: $0.key) }
        case .liked: progressManager.likedCourses
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    RoundIconButton(systemImage: "chevron.left", accessibilityLabel: languageManager.text("common.close")) { dismiss() }
                    Text("\(languageManager.text(kind.titleKey)) · \(courses.count)")
                        .font(DS.title(.title2, .heavy))
                        .foregroundStyle(DS.ink)
                    Spacer()
                }
                .padding(.bottom, 8)
                ForEach(courses) { course in
                    CompactCourseRow(
                        course: course,
                        meta: "\(CreatorIdentity.forCourse(course.id).name) · \(NewGenFormat.minutes(ReadingTime.minutes(for: course, language: languageManager.current), language: languageManager.current))",
                        onTap: { onOpenCourse(course) }
                    ) {
                        if progressManager.courseStatus(for: course.id) == .completed { ReadCheck() }
                    }
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .background(DS.canvas.ignoresSafeArea())
    }
}
