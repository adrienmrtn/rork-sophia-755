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

    /// L'annonce « en écriture » de ce créateur dans un événement actif, s'il y en a une.
    private var writingFor: (Campaign, Campaign.Upcoming)? {
        for campaign in CampaignStore.active() {
            if let upcoming = campaign.upcoming.first(where: { $0.creator == author.slug }) {
                return (campaign, upcoming)
            }
        }
        return nil
    }

    private var listedCourses: [Course] {
        switch segment {
        case 0: courses.sorted { $0.readsCount > $1.readsCount }
        case 1: Array(courses.reversed())
        default: []
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    RoundIconButton(systemImage: "chevron.left", accessibilityLabel: languageManager.text("common.close")) { dismiss() }
                    Spacer()
                    ShareLink(item: SophiaDeepLink.shareText(for: author, language: languageManager.current)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(DS.ink)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(DS.surface))
                            .overlay(Circle().strokeBorder(DS.hairline, lineWidth: 1))
                    }
                }

                VStack(spacing: 8) {
                    AuthorAvatarView(author: author, size: 92)
                    Text(author.name)
                        .font(DS.title(.title, .heavy))
                        .foregroundStyle(DS.ink)
                        .multilineTextAlignment(.center)
                    CreatorBadge(verified: author.isVerified)
                    if let pedigree = author.title(for: language) {
                        Text(pedigree)
                            .font(DS.sans(.body))
                            .foregroundStyle(DS.inkSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)

                statsCard

                HStack(spacing: 10) {
                    FollowButton(isFollowing: isFollowing, action: toggleFollow)
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if !isFollowing { toggleFollow() }
                    } label: {
                        Image(systemName: isFollowing ? "bell.fill" : "bell")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(DS.ink)
                            .frame(width: 54, height: 44)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(DS.surface))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(languageManager.text("creator.notify")))
                }

                if let bio = author.bio(for: language) {
                    Text(bio)
                        .font(DS.sans(.body))
                        .foregroundStyle(DS.ink)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if showsCampaignCard, let writing = writingFor {
                    let campaign = writing.0
                    let upcoming = writing.1
                    Button {
                        onOpenCampaign(campaign)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: languageManager.text("creator.writingFor"), campaign.title(for: language)))
                                .font(DS.sans(.footnote, .bold))
                                .foregroundStyle(DS.accentSoft)
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(upcoming.title(for: language))
                                    .font(DS.sans(.subheadline, .bold))
                                    .foregroundStyle(DS.ink)
                                if let date = Campaign.parseDay(upcoming.date) {
                                    Text("· \(String(format: languageManager.text("event.upcoming.date"), NewGenFormat.shortDay(date, language: language)))")
                                        .font(DS.sans(.subheadline))
                                        .foregroundStyle(DS.inkSecondary)
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(DS.inkTertiary, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        )
                    }
                    .buttonStyle(.plain)
                }

                SegmentedPills(
                    items: [
                        languageManager.text("creator.tab.popular"),
                        languageManager.text("creator.tab.recent"),
                        languageManager.text("creator.tab.series"),
                    ],
                    selection: $segment
                )

                if segment == 2 {
                    Text(languageManager.text("creator.series.empty"))
                        .font(DS.sans(.subheadline))
                        .foregroundStyle(DS.inkSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else {
                    ForEach(listedCourses) { course in
                        let completed = progressManager.courseStatus(for: course.id) == .completed
                        CompactCourseRow(
                            course: course,
                            meta: courseMeta(course, completed: completed),
                            secondMeta: course.statsLine(liked: progressManager.isLiked(course.id), language: languageManager.current),
                            onTap: { onOpenCourse(course) }
                        ) {
                            if completed { ReadCheck() }
                        }
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(DS.canvas.ignoresSafeArea())
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            stat(followers.compactCount, languageManager.text("creator.stat.followers"))
            stat(LocalCounters.reads(for: author).compactCount, languageManager.text("creator.stat.reads"))
            stat("\(courses.count)", languageManager.text("creator.stat.courses"))
            stat("\(AppLanguage.allCases.count)", languageManager.text("creator.stat.languages"))
        }
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(DS.surface))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(DS.title(.title3, .heavy))
                .foregroundStyle(DS.ink)
                .monospacedDigit()
            Text(label)
                .font(DS.sans(.caption))
                .foregroundStyle(DS.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
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
