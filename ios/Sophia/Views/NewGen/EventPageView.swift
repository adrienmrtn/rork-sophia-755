import SwiftUI

/// La page d'un événement : en-tête, défi avec barre et badge, les cours de la collection,
/// les cours en écriture avec « Me prévenir », et l'appel aux créateurs. Les données viennent
/// de `CampaignStore` (JSON de test embarqué, serveur au prompt 6).
struct EventPageView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    let campaign: Campaign
    let progressManager: ProgressManager
    let onOpenCourse: (Course) -> Void
    let onOpenCreator: (CourseAuthor) -> Void
    let onBecomeCreator: () -> Void

    /// Rafraîchit la vue après « Me prévenir » (l'état vit dans `UserDefaults`).
    @State private var notifyTick = 0

    private var language: AppLanguage { languageManager.current }
    private var courses: [Course] { campaign.courseIds.compactMap { ContentCatalog.course(withId: $0) } }
    private var done: Int { CampaignStore.challengeProgress(for: campaign, progressManager: progressManager) }
    private var complete: Bool { CampaignStore.isChallengeComplete(for: campaign, progressManager: progressManager) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    RoundIconButton(systemImage: "chevron.left", accessibilityLabel: languageManager.text("common.close")) { dismiss() }
                    Spacer()
                }

                hero
                challengeCard

                NewGenSectionTitle(text: languageManager.text("event.courses"))
                ForEach(courses) { course in
                    let completed = progressManager.courseStatus(for: course.id) == .completed
                    CompactCourseRow(
                        course: course,
                        meta: courseMeta(course, completed: completed),
                        secondMeta: "\(course.readsCount.compactCount) \(languageManager.text("creator.stat.reads")) · \(course.likesCount(liked: progressManager.isLiked(course.id)).compactCount) \(languageManager.text("common.likes"))",
                        onTap: { onOpenCourse(course) }
                    ) {
                        if completed { ReadCheck() }
                    }
                }

                if !campaign.upcoming.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        NewGenSectionTitle(text: languageManager.text("event.writing"))
                        Text(String(format: languageManager.text("event.writing.body"), campaign.title(for: language)))
                            .font(DS.sans(.subheadline))
                            .foregroundStyle(DS.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 6)
                    ForEach(Array(campaign.upcoming.enumerated()), id: \.offset) { _, upcoming in
                        upcomingRow(upcoming)
                    }
                }

                callCard
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(DS.canvas.ignoresSafeArea())
    }

    // MARK: - Pièces

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Image(systemName: campaign.symbol ?? "sparkles")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(DS.warm)
                Spacer(minLength: 8)
                if let start = campaign.startDate, let end = campaign.endDate {
                    Text(String(format: languageManager.text("event.page.dates"), NewGenFormat.longDay(start, language: language), NewGenFormat.longDay(end, language: language)))
                        .font(DS.sans(.caption, .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(Capsule().fill(.white.opacity(0.16)))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            Text(campaign.title(for: language))
                .font(DS.title(.largeTitle, .heavy))
                .foregroundStyle(.white)
            Text(campaign.description(for: language))
                .font(DS.sans(.body))
                .foregroundStyle(.white.opacity(0.88))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Text(String(format: languageManager.text("event.participants"), participantsText))
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(DS.accent))
    }

    private var participantsText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = language.foundationLocale
        return formatter.string(from: NSNumber(value: campaign.participants)) ?? "\(campaign.participants)"
    }

    private var challengeCard: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle().fill(complete ? DS.warm.opacity(0.25) : DS.surfaceMuted)
                Image(systemName: campaign.symbol ?? "sparkles")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(complete ? DS.warm : DS.inkTertiary)
            }
            .frame(width: 84, height: 84)

            VStack(alignment: .leading, spacing: 8) {
                Text(String(format: languageManager.text("event.challenge.title"), campaign.title(for: language)))
                    .font(DS.title(.headline, .heavy))
                    .foregroundStyle(DS.ink)
                Text(String(format: languageManager.text("event.challenge.body"), campaign.challengeTarget, campaign.badgeName(for: language)))
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.inkSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 12) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(DS.surfaceMuted)
                            Capsule()
                                .fill(DS.warm)
                                .frame(width: geo.size.width * CGFloat(min(1, Double(done) / Double(max(1, campaign.challengeTarget)))))
                        }
                    }
                    .frame(height: 6)
                    Text(String(format: languageManager.text("event.challenge.progress"), done, campaign.challengeTarget))
                        .font(DS.sans(.caption, .bold))
                        .foregroundStyle(DS.ink)
                        .monospacedDigit()
                        .fixedSize()
                }
                .padding(.top, 4)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(DS.surface))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
        .dsSoftShadow()
    }

    private func upcomingRow(_ upcoming: Campaign.Upcoming) -> some View {
        let author = upcoming.creator.flatMap { AuthorStore.author(slug: $0) }
        let wants = CampaignStore.wantsNotification(for: campaign, upcoming: upcoming)
        _ = notifyTick
        return HStack(spacing: 12) {
            if let author {
                Button { onOpenCreator(author) } label: { AuthorAvatarView(author: author, size: 44) }
                    .buttonStyle(.plain)
            } else {
                ZStack {
                    Circle().fill(DS.surfaceMuted)
                    Image(systemName: "pencil")
                        .foregroundStyle(DS.inkTertiary)
                }
                .frame(width: 44, height: 44)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(upcoming.title(for: language))
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 4) {
                    if let author { Text(author.name) }
                    if let date = Campaign.parseDay(upcoming.date) {
                        Text(author == nil ? "" : "·")
                        Text(String(format: languageManager.text("event.upcoming.date"), NewGenFormat.shortDay(date, language: language)))
                    }
                }
                .font(DS.sans(.caption))
                .foregroundStyle(DS.inkSecondary)
            }
            Spacer(minLength: 8)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                CampaignStore.setWantsNotification(!wants, for: campaign, upcoming: upcoming)
                notifyTick += 1
            } label: {
                Text(languageManager.text(wants ? "event.notified" : "event.notify"))
                    .font(DS.sans(.footnote, .bold))
                    .foregroundStyle(wants ? DS.success : DS.accent)
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(wants ? DS.successTint : DS.accentTint))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(DS.inkTertiary, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        )
    }

    private var callCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(format: languageManager.text("event.write.title"), campaign.title(for: language)))
                .font(DS.title(.headline, .heavy))
                .foregroundStyle(DS.ink)
            Text(String(format: languageManager.text("event.write.body"), AppLanguage.allCases.count))
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onBecomeCreator()
            } label: {
                Text(languageManager.text("event.write.cta"))
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(DS.accent))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(DS.accentTint))
    }

    private func courseMeta(_ course: Course, completed: Bool) -> String {
        var parts = [CreatorIdentity.forCourse(course.id).name]
        if completed {
            parts.append(languageManager.text("common.read"))
        } else {
            parts.append(NewGenFormat.minutes(ReadingTime.minutes(for: course, language: language), language: language))
        }
        return parts.joined(separator: " · ")
    }
}
