import SwiftUI

/// La page d'un événement : un en-tête plein écran (l'image de l'équipe ou un éventail des
/// couvertures, dates, titre, accroche, participants), la présentation, le défi avec le badge à
/// gagner, l'objectif commun, puis les cours de la collection. Les données viennent de
/// `CampaignStore`, donc du manifeste du catalogue (docs/evenements.md).
struct EventPageView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    let campaign: Campaign
    let progressManager: ProgressManager
    let onOpenCourse: (Course) -> Void
    /// Plus utilisés depuis que la page n'annonce plus de cours « en écriture » ni n'invite à
    /// écrire ; gardés pour que les appelants (`NewGenTabsView`) n'aient pas à changer.
    let onOpenCreator: (CourseAuthor) -> Void
    let onBecomeCreator: () -> Void

    private var language: AppLanguage { languageManager.current }
    private var courses: [Course] { campaign.courseIds.compactMap { ContentCatalog.course(withId: $0) } }
    private var done: Int { CampaignStore.challengeProgress(for: campaign, progressManager: progressManager) }
    private var complete: Bool { CampaignStore.isChallengeComplete(for: campaign, progressManager: progressManager) }

    var body: some View {
        let description = campaign.description(for: language)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                VStack(alignment: .leading, spacing: 22) {
                    if !description.isEmpty {
                        Text(description)
                            .font(DS.sans(.body))
                            .foregroundStyle(DS.ink)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    challengeBlock

                    if let goal = campaign.goalTarget, goal > 0 {
                        goalBlock(goal: goal)
                    }

                    coursesSection
                }
                .padding(20)
                .padding(.bottom, 24)
            }
        }
        .scrollIndicators(.hidden)
        .background(DS.canvas.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - En-tête

    /// L'illustration jusque sous la barre d'état, fondue dans le bleu marine, puis les dates,
    /// le titre, l'accroche et les participants.
    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .frame(height: 290)
                .overlay { EventArtwork(campaign: campaign, courses: courses, collageLift: -0.08) }
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [EventPalette.navy.opacity(0), EventPalette.navy],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                }
                .clipped()

            headerText
                .padding(.horizontal, 20)
                .padding(.top, -30)
                .padding(.bottom, 26)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(EventPalette.navy)
        .overlay(alignment: .topLeading) {
            RoundIconButton(systemImage: "chevron.left", accessibilityLabel: languageManager.text("common.close")) { dismiss() }
                .padding(.leading, 20)
                .padding(.top, 56)
        }
    }

    private var headerText: some View {
        let tagline = campaign.tagline(for: language)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if let start = campaign.startDate, let end = campaign.endDate {
                    EventPill(text: String(format: languageManager.text("event.page.dates"), NewGenFormat.longDay(start, language: language), NewGenFormat.longDay(end, language: language)))
                }
                if campaign.hasEnded() {
                    EventPill(text: languageManager.text("event.ended"), style: .dark)
                        .fixedSize()
                }
            }

            Text(campaign.title(for: language))
                .font(DS.title(.largeTitle, .heavy))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            if !tagline.isEmpty {
                Text(tagline)
                    .font(DS.sans(.headline, .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if campaign.participants > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(EventPalette.saffron)
                    Text(String(format: languageManager.text("event.participants"), campaign.participants.formatted(language: language)))
                        .font(DS.sans(.subheadline, .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Défi

    /// Le défi sur une feuille crème, comme les affiches du site : le badge à gagner dans son
    /// anneau, son nom, ce qu'il faut lire pour l'obtenir, et un segment par cours.
    private var challengeBlock: some View {
        let navy = EventPalette.navy
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                EventBadgeRing(campaign: campaign, done: done, size: 96, track: navy.opacity(0.14))
                VStack(alignment: .leading, spacing: 4) {
                    Text(languageManager.text("event.badge.toEarn").uppercasedInApp())
                        .font(DS.sans(.caption, .bold))
                        .tracking(0.6)
                        .foregroundStyle(navy.opacity(0.62))
                    Text(campaign.badgeName(for: language))
                        .font(DS.title(.title2, .heavy))
                        .foregroundStyle(navy)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(String(format: languageManager.text("event.challenge.title"), campaign.title(for: language)))
                        .font(DS.sans(.subheadline, .semibold))
                        .foregroundStyle(navy.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            Text(
                complete
                    ? String(format: languageManager.text("event.challenge.unlocked"), campaign.badgeName(for: language))
                    : String(format: languageManager.text("event.challenge.body"), campaign.challengeTarget, campaign.badgeName(for: language))
            )
            .font(DS.sans(.subheadline, complete ? .bold : .regular))
            .foregroundStyle(navy.opacity(complete ? 1 : 0.82))
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                EventChallengeMeter(done: done, target: campaign.challengeTarget, tint: EventPalette.saffron, track: navy.opacity(0.14), height: 10)
                Text(String(format: languageManager.text("event.challenge.progress"), done, campaign.challengeTarget))
                    .font(DS.sans(.footnote, .bold))
                    .foregroundStyle(navy)
                    .monospacedDigit()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(EventPalette.cream))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(EventPalette.saffron.opacity(0.55), lineWidth: 1.5)
        )
        .dsSoftShadow()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Objectif commun

    /// Tous les lecteurs ensemble : le chiffre recalculé par le serveur, sa barre et le pourcentage.
    private func goalBlock(goal: Int) -> some View {
        let read = campaign.goalCount ?? 0
        let fraction = min(1, Double(read) / Double(goal))
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle().fill(DS.accentTint)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DS.accentSoft)
                }
                .frame(width: 40, height: 40)
                Text(String(format: languageManager.text("event.goal.progress"), read.formatted(language: language), goal.formatted(language: language)))
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(DS.ink)
                    .monospacedDigit()
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Text(percentText(fraction))
                    .font(DS.title(.headline, .heavy))
                    .foregroundStyle(DS.accentSoft)
                    .monospacedDigit()
                    .fixedSize()
            }
            EventProgressBar(fraction: fraction, tint: DS.accentSoft, track: DS.surfaceMuted, height: 8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(DS.surface))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    /// « 62 % », « 62% » : le pourcentage écrit comme la langue de l'app l'écrit.
    private func percentText(_ fraction: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        formatter.roundingMode = .down
        formatter.locale = language.foundationLocale
        return formatter.string(from: NSNumber(value: fraction)) ?? "\(Int(fraction * 100)) %"
    }

    // MARK: - Cours

    private var coursesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            NewGenSectionTitle(text: languageManager.text("event.courses"), trailing: "· \(courses.count)")
                .padding(.bottom, 2)
            ForEach(courses) { course in
                let completed = progressManager.courseStatus(for: course.id) == .completed
                CompactCourseRow(
                    course: course,
                    meta: courseMeta(course, completed: completed),
                    secondMeta: course.statsLine(liked: progressManager.isLiked(course.id), language: language),
                    onTap: { onOpenCourse(course) }
                ) {
                    if completed { ReadCheck() }
                }
            }
        }
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
