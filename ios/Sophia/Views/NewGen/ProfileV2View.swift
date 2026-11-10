import SwiftUI

/// Le profil de la maquette : identité, trois compteurs, Reprendre, Mes abonnements, Badges,
/// l'entrée de l'Entraînement, listes À lire / Lus / Aimés, « Deviens créateur », puis les pages secondaires (progression,
/// amis, anti-scroll). L'ancien profil reste accessible comme page « Ma progression ».
struct ProfileV2View: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AuthService.self) private var auth
    let progressManager: ProgressManager
    let store: StoreViewModel
    let onOpenCourse: (Course) -> Void
    let onResumeCourse: (Course) -> Void
    let onOpenCreator: (CourseAuthor) -> Void
    let onOpenList: (ProfileListKind) -> Void
    let onOpenCampaign: (Campaign) -> Void
    let onOpenProgression: () -> Void
    let onOpenTraining: () -> Void
    let onOpenAntiScroll: () -> Void
    let onDiscoverCreators: () -> Void
    let onBecomeCreator: () -> Void
    var onShowPaywall: (() -> Void)? = nil
    var onResetOnboarding: (() -> Void)? = nil

    @Bindable private var social = SocialService.shared
    @State private var listSegment = 0
    @State private var showSettings = false
    @State private var showAvatarPicker = false
    @State private var showBadges = false

    private var language: AppLanguage { languageManager.current }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                titleRow
                identity
                statsCard
                ResumeCoursesSection(progressManager: progressManager, onResume: onResumeCourse)
                    .padding(.horizontal, -20)
                trainingCard
                followingSection
                // Les amis et leur classement, à même la page (plus de page à part).
                FriendsLeaderboardSection(social: social)
                badgesSection
                listsSection
                creatorCard
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

    // MARK: - Entraînement

    /// L'entrée de l'Entraînement, qui n'a plus d'onglet à lui.
    private var trainingCard: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onOpenTraining()
        } label: {
            HStack(spacing: 14) {
                Image("training_poster")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(languageManager.text("training.title"))
                        .font(DS.title(.title3, .heavy))
                        .foregroundStyle(DS.ink)
                    Text(languageManager.text("training.locked.tagline"))
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

    // MARK: - Deviens créateur

    private var creatorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image("creator_writing")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityHidden(true)
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(languageManager.text("profile.creator.title"))
                        .font(DS.title(.title3, .heavy))
                        .foregroundStyle(DS.ink)
                    Text(languageManager.text("profile.creator.subtitle"))
                        .font(DS.sans(.subheadline))
                        .foregroundStyle(DS.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                step(1, languageManager.text("profile.creator.step1"))
                step(2, String(format: languageManager.text("profile.creator.step2"), AppLanguage.allCases.count))
                step(3, languageManager.text("profile.creator.step3"))
            }
            if let campaign = CampaignStore.active().first {
                Button { onOpenCampaign(campaign) } label: {
                    HStack(spacing: 10) {
                        Image(systemName: campaign.symbol ?? "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(DS.warm)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(languageManager.text("profile.creator.call"))
                                .font(DS.sans(.footnote, .bold))
                                .foregroundStyle(DS.ink)
                            Text("\(campaign.title(for: language)), \(campaign.tagline(for: language).lowercasedFirst)")
                                .font(DS.sans(.footnote))
                                .foregroundStyle(DS.inkSecondary)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.forward")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(DS.inkTertiary)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(DS.canvas))
                }
                .buttonStyle(.plain)
            }
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onBecomeCreator()
            } label: {
                Text(languageManager.text("home.start"))
                    .font(DS.sans(.headline, .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(DS.accent))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(DS.surface))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
        .dsSoftShadow()
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(DS.sans(.footnote, .bold))
                .foregroundStyle(DS.accent)
                .frame(width: 26, height: 26)
                .background(Circle().fill(DS.accentTint))
            Text(text)
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Pages secondaires

    private var secondaryPages: some View {
        VStack(spacing: 0) {
            pageRow(languageManager.text("profile.page.progression"), action: onOpenProgression)
            Rectangle().fill(DS.hairline).frame(height: 1).padding(.leading, 16)
            pageRow(languageManager.text("profile.page.antiScroll"), action: onOpenAntiScroll)
        }
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(DS.surface))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
    }

    private func pageRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack {
                Text(title)
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
                Spacer()
                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.inkTertiary)
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

private extension String {
    var lowercasedFirst: String {
        guard let first = first else { return self }
        return first.lowercased() + dropFirst()
    }
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
