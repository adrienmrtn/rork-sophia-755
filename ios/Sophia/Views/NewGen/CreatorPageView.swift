import SwiftUI

/// La page d'un créateur, plein écran dans l'onglet : portrait, badge, pedigree, quatre
/// compteurs, « Suivre », bio, ce qu'il écrit pour l'événement en cours, puis ses cours
/// (populaires, récents, séries). Remplace la feuille `AuthorView`.
struct CreatorPageView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    let author: CourseAuthor
    let progressManager: ProgressManager
    let onOpenCourse: (Course) -> Void
    let onOpenCampaign: (Campaign) -> Void
    /// L'encart « En écriture pour … » mène à l'événement ; faux là où rien ne peut l'ouvrir
    /// (la page présentée depuis le lecteur).
    var showsCampaignCard = true

    @State private var segment = 0

    private var language: AppLanguage { languageManager.current }
    private var isFollowing: Bool { progressManager.isFollowing(author.slug) }
    private var courses: [Course] { author.courseIds.compactMap { ContentCatalog.course(withId: $0) } }
    private var followers: Int { LocalCounters.followers(creatorSlug: author.slug) + (isFollowing ? 1 : 0) }

    private var listedCourses: [Course] {
        switch segment {
        case 0: courses.sorted { $0.readsCount > $1.readsCount }
        case 1: Array(courses.reversed())
        default: []
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                topBar

                identityBlock
                    .padding(.top, 6)
                    .dsStagger(0)

                statsCard
                    .padding(.top, 16)
                    .dsStagger(1)

                actionsRow
                    .padding(.top, 12)
                    .dsStagger(2)

                if let bio = author.bio(for: language) {
                    Text(bio)
                        .font(DS.sans(.subheadline))
                        .foregroundStyle(DS.inkSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 14)
                        .dsStagger(3)
                }

                SegmentedPills(
                    items: [
                        languageManager.text("creator.tab.popular"),
                        languageManager.text("creator.tab.recent"),
                        languageManager.text("creator.tab.series"),
                    ],
                    selection: $segment
                )
                .padding(.top, 16)
                .dsStagger(4)

                courseList
                    .padding(.top, 9)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 48)
        }
        .scrollIndicators(.hidden)
        .background(DS.canvas.ignoresSafeArea())
    }

    // MARK: - Blocs

    private var topBar: some View {
        HStack {
            RoundIconButton(systemImage: "chevron.left", accessibilityLabel: languageManager.text("common.close")) { dismiss() }
            Spacer()
            ShareLink(item: SophiaDeepLink.shareText(for: author, language: languageManager.current)) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.ink)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(DS.surface))
                    .overlay(Circle().strokeBorder(DS.hairline, lineWidth: 1.5))
            }
        }
    }

    /// Portrait, nom, statut et pedigree, centrés.
    private var identityBlock: some View {
        VStack(spacing: 8) {
            AuthorAvatarView(author: author, size: 92)
            Text(author.name)
                .font(DS.title(.title2, .semibold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
            CreatorBadge(verified: author.isVerified)
            if let pedigree = author.title(for: language) {
                Text(pedigree)
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// « Suivre » sur toute la largeur et, à côté, la cloche (qui abonne si ce n'est pas fait).
    private var actionsRow: some View {
        HStack(spacing: 10) {
            FollowButton(isFollowing: isFollowing, action: toggleFollow)
            Button {
                Haptics.select()
                if !isFollowing { toggleFollow() }
            } label: {
                Image(systemName: isFollowing ? "bell.fill" : "bell")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(isFollowing ? DS.accent : DS.ink)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: isFollowing)
                    .frame(width: 46, height: 46)
                    .homeCard()
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle(scale: 0.93, haptic: false))
            .accessibilityLabel(Text(languageManager.text("creator.notify")))
        }
    }

    /// Les cours de l'onglet choisi, ou le mot de l'onglet Séries tant qu'il est vide.
    @ViewBuilder
    private var courseList: some View {
        if segment == 2 {
            Text(languageManager.text("creator.series.empty"))
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .transition(.opacity)
        } else {
            VStack(spacing: 9) {
                ForEach(Array(listedCourses.enumerated()), id: \.element.id) { index, course in
                    let completed = progressManager.courseStatus(for: course.id) == .completed
                    CompactCourseRow(
                        course: course,
                        meta: courseMeta(course, completed: completed),
                        secondMeta: course.statsLine(liked: progressManager.isLiked(course.id), language: languageManager.current),
                        onTap: { onOpenCourse(course) }
                    ) {
                        if completed { ReadCheck() }
                    }
                    .dsStagger(min(index, 8), base: 0.2)
                }
            }
        }
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            stat(followers.compactCount, languageManager.text("creator.stat.followers"))
            stat(LocalCounters.reads(for: author).compactCount, languageManager.text("creator.stat.reads"))
            stat("\(courses.count)", languageManager.text("creator.stat.courses"))
            stat("\(AppLanguage.allCases.count)", languageManager.text("creator.stat.languages"))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .homeCard()
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(DS.title(.headline, .heavy))
                .foregroundStyle(DS.ink)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(label)
                .font(DS.sans(.caption))
                .foregroundStyle(DS.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .animation(DS.Motion.snappy, value: value)
    }

    private func courseMeta(_ course: Course, completed: Bool) -> String {
        var parts = [course.subject.localizedShortName(language: language)]
        if completed {
            parts.append(languageManager.text("common.read"))
        } else {
            parts.append(NewGenFormat.minutes(ReadingTime.minutes(for: course, language: language), language: language))
        }
        return parts.joined(separator: " · ")
    }

    private func toggleFollow() {
        let wasFollowing = isFollowing
        progressManager.toggleFollow(author.slug)
        AnalyticsService.shared.log(wasFollowing ? .unfollow : .follow, screen: "creator", props: ["creator": .string(author.slug)])
    }
}
