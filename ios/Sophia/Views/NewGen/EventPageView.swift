import SwiftUI

/// La page d'un événement : un en-tête plein écran (l'image de l'équipe ou un éventail des
/// couvertures, dates, titre, accroche, participants, présentation), le défi avec le badge à
/// gagner, puis les cours de la collection. Les données viennent de
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
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                VStack(alignment: .leading, spacing: 24) {
                    challengeBlock
                        .dsStagger(0)

                    coursesSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 48)
            }
        }
        .scrollIndicators(.hidden)
        .background(DS.canvas.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - En-tête

    /// Le bleu clair des textes secondaires posés sur l'en-tête sombre.
    private static let headerSoftText = Color(red: 201.0 / 255.0, green: 214.0 / 255.0, blue: 238.0 / 255.0)

    /// L'illustration jusque sous la barre d'état, un voile uni en bas, puis les dates, le titre,
    /// l'accroche, les participants et la présentation, sur le bleu nuit de l'en-tête.
    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .frame(height: 270)
                .overlay { EventArtwork(campaign: campaign, courses: courses, collageLift: -0.08) }
                .overlay(alignment: .bottom) {
                    EventPalette.pageHeader.opacity(0.7)
                        .frame(height: 90)
                }
                .clipped()

            headerText
                .padding(.horizontal, 24)
                .padding(.top, -30)
                .padding(.bottom, 22)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(EventPalette.pageHeader)
        .overlay(alignment: .topLeading) {
            RoundIconButton(systemImage: "chevron.left", accessibilityLabel: languageManager.text("common.close")) { dismiss() }
                .padding(.leading, 20)
                .padding(.top, 56)
        }
    }

    private var headerText: some View {
        let tagline: String = campaign.tagline(for: language)
        let description: String = campaign.description(for: language)
        return VStack(alignment: .leading, spacing: 10) {
            headerPills

            Text(campaign.title(for: language))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            if !tagline.isEmpty {
                Text(tagline)
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(Self.headerSoftText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if campaign.participants > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "person.2")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(EventPalette.saffron)
                    Text(String(format: languageManager.text("event.participants"), campaign.participants.formatted(language: language)))
                        .font(DS.sans(.subheadline, .bold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !description.isEmpty {
                Text(description)
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(Self.headerSoftText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headerPills: some View {
        HStack(spacing: 6) {
            if let start = campaign.startDate, let end = campaign.endDate {
                EventPill(text: String(format: languageManager.text("event.page.dates"), NewGenFormat.longDay(start, language: language), NewGenFormat.longDay(end, language: language)))
            }
            if campaign.hasEnded() {
                EventPill(text: languageManager.text("event.ended"), style: .dark)
                    .fixedSize()
            }
        }
    }

    // MARK: - Défi

    /// Le défi sur une feuille crème bordée de safran, centré : le badge à gagner dans son
    /// anneau, son nom, ce qu'il faut lire pour l'obtenir, et un segment par cours.
    /// (L'objectif commun « Ensemble : N cours lus » n'est plus affiché.)
    private var challengeBlock: some View {
        let badgeName: String = campaign.badgeName(for: language)
        let challengeText: String = complete
            ? String(format: languageManager.text("event.challenge.unlocked"), badgeName)
            : String(format: languageManager.text("event.challenge.body"), campaign.challengeTarget, badgeName)
        return VStack(spacing: 8) {
            EventBadgeRing(campaign: campaign, done: done, size: 96, track: EventPalette.ink.opacity(0.14))

            Text(languageManager.text("event.badge.toEarn").uppercasedInApp())
                .font(DS.sans(.caption, .heavy))
                .tracking(0.8)
                .foregroundStyle(EventPalette.gold)

            Text(badgeName)
                .font(DS.title(.headline, .heavy))
                .fixedSize(horizontal: false, vertical: true)

            Text(String(format: languageManager.text("event.challenge.title"), campaign.title(for: language)))
                .font(DS.sans(.footnote, .bold))
                .fixedSize(horizontal: false, vertical: true)

            Text(challengeText)
                .font(DS.sans(.subheadline, complete ? .bold : .regular))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            EventChallengeMeter(done: done, target: campaign.challengeTarget, tint: EventPalette.saffron, track: EventPalette.ink.opacity(0.14), height: 8)
                .padding(.top, 2)

            Text(String(format: languageManager.text("event.challenge.progress"), done, campaign.challengeTarget))
                .font(DS.sans(.footnote, .bold))
                .monospacedDigit()
        }
        .foregroundStyle(EventPalette.ink)
        .multilineTextAlignment(.center)
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(EventPalette.cream))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(EventPalette.saffron, lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Cours

    private var coursesSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            NewGenSectionTitle(text: languageManager.text("event.courses"), trailing: "· \(courses.count)")
                .dsStagger(1)
            ForEach(Array(courses.enumerated()), id: \.element.id) { index, course in
                let completed = progressManager.courseStatus(for: course.id) == .completed
                CompactCourseRow(
                    course: course,
                    meta: courseMeta(course, completed: completed),
                    secondMeta: course.statsLine(liked: progressManager.isLiked(course.id), language: language),
                    onTap: { onOpenCourse(course) }
                ) {
                    if completed { ReadCheck() }
                }
                .dsStagger(min(index, 8) + 2)
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
