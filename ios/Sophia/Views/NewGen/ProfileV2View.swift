import SwiftUI

/// Le profil de la maquette : identité, trois compteurs, Reprendre, Mes abonnements, Badges,
/// listes À lire / Lus / Aimés, « Deviens créateur », puis les pages secondaires (progression,
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
    let onOpenFriends: () -> Void
    let onOpenAntiScroll: () -> Void
    let onDiscoverCreators: () -> Void
    let onBecomeCreator: () -> Void
    var onShowPaywall: (() -> Void)? = nil
    var onResetOnboarding: (() -> Void)? = nil

    @Bindable private var social = SocialService.shared
    @State private var listSegment = 0
    @State private var showSettings = false

    private var language: AppLanguage { languageManager.current }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                titleRow
                identity
                statsCard
                ResumeCoursesSection(progressManager: progressManager, onResume: onResumeCourse)
                    .padding(.horizontal, -20)
                followingSection
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
            ZStack {
                Circle().fill(DS.accentSoft)
                Text(String(displayName.prefix(1)).uppercased())
                    .font(DS.title(.title2, .heavy))
                    .foregroundStyle(.white)
            }
            .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 3) {
                Text(displayName)
                    .font(DS.title(.title3, .heavy))
                    .foregroundStyle(DS.ink)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if let handle = social.myHandle, !handle.isEmpty {
                        Text("@\(handle)")
                    }
                    if let memberSince {
                        if social.myHandle != nil { Text("·") }
                        Text(String(format: languageManager.text("profile.member.since"), memberSince))
                    }
                }
                .font(DS.sans(.footnote))
                .foregroundStyle(DS.inkSecondary)
                .lineLimit(1)
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
            Rectangle().fill(DS.hairline).frame(width: 1, height: 36)
            StatCounter(
                systemImage: "clock",
                iconTint: DS.success,
                iconBackground: DS.successTint,
                value: NewGenFormat.readingTime(seconds: progressManager.readingSeconds, language: language),
                label: languageManager.text("profile.stat.time")
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

    private var completedSubjectsCount: Int {
        Subject.allCases.filter { progressManager.completedCount(for: $0) > 0 }.count
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            NewGenSectionTitle(text: languageManager.text("profile.badges"))
            HStack(spacing: 10) {
                if let campaign = CampaignStore.all.last {
                    let done = CampaignStore.challengeProgress(for: campaign, progressManager: progressManager)
                    badge(
                        systemImage: campaign.symbol ?? "sparkles",
                        title: campaign.badgeName(for: language),
                        subtitle: String(format: languageManager.text("badge.progress"), done, campaign.challengeTarget),
                        earned: done >= campaign.challengeTarget
                    )
                }
                badge(
                    systemImage: "flame.fill",
                    title: languageManager.text("badge.streak7.title"),
                    subtitle: languageManager.text("friends.stats.streak"),
                    earned: progressManager.streak >= 7
                )
                badge(
                    systemImage: "safari",
                    title: languageManager.text("globalRank.curieux"),
                    subtitle: String(format: languageManager.text("badge.curious.sub"), completedSubjectsCount),
                    earned: completedSubjectsCount >= 3
                )
            }
        }
    }

    private func badge(systemImage: String, title: String, subtitle: String, earned: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(earned ? DS.warm.opacity(0.2) : DS.surfaceMuted)
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(earned ? DS.warm : DS.inkTertiary)
            }
            .frame(width: 48, height: 48)
            Text(title)
                .font(DS.sans(.subheadline, .bold))
                .foregroundStyle(DS.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(subtitle)
                .font(DS.sans(.caption))
                .foregroundStyle(DS.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(DS.surface))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
        .opacity(earned ? 1 : 0.75)
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

    // MARK: - Deviens créateur

    private var creatorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(DS.accentTint)
                    Image(systemName: "pencil")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(DS.accent)
                }
                .frame(width: 48, height: 48)
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
            pageRow(languageManager.text("profile.page.friends"), action: onOpenFriends)
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
