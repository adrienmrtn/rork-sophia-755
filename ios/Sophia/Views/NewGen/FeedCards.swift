import SwiftUI

/// Un élément du fil d'accueil. Les cartes vidéo n'existent pas encore (prompt 10) : le cas
/// est là pour que la mise en page les accueille sans changer le fil.
enum FeedItem: Identifiable, Equatable {
    case course(Course)
    case campaign(Campaign)
    case creatorInvite
    case video(id: String)
    /// Une page de texte quand il n'y a rien à montrer (aucun abonnement, tout est lu…).
    case notice(FeedNotice)

    var id: String {
        switch self {
        case .course(let course): "course:\(course.id)"
        case .campaign(let campaign): "campaign:\(campaign.slug)"
        case .creatorInvite: "creator-invite"
        case .video(let id): "video:\(id)"
        case .notice(let notice): "notice:\(notice.rawValue)"
        }
    }

    /// Le cours derrière la page, s'il y en a un.
    var asCourse: Course? {
        if case .course(let course) = self { return course }
        return nil
    }

    var courseId: String? { asCourse?.id }
}

enum FeedNotice: String, Equatable {
    case followingEmpty, followingUpToDate, allCaughtUp
}

// MARK: - Carte cours

/// La carte de cours de la maquette : couverture 16:9 avec la pastille de matière, titre,
/// accroche, ligne créateur, puis lectures · j'aime · enregistrer · durée.
struct CourseFeedCard: View {
    @Environment(LanguageManager.self) private var languageManager
    let course: Course
    let progressManager: ProgressManager
    /// Étiquette à côté de la matière : « Nouveau » ou le nom d'un événement.
    var tag: String? = nil
    var tagStyle: TagPill.Style = .accent
    /// Petite ligne au-dessus du titre (« Publié il y a 5 heures », onglet Abonnements).
    var kicker: String? = nil
    /// Écran rapporté dans les événements `like` / `save`.
    var screen: String = "home"
    /// Dans le fil paginé, la carte remplit sa page : les compteurs descendent en bas.
    var fillsPage = false
    /// Hauteur imposée à la couverture (fil paginé) ; sinon 16:9.
    var coverHeight: CGFloat? = nil
    let onOpen: () -> Void
    let onOpenCreator: (CourseAuthor) -> Void

    @State private var minutes: Int?
    @State private var likeBurst = 0
    @State private var bigHeart = 0

    private var identity: CreatorIdentity { CreatorIdentity.forCourse(course.id) }
    private var liked: Bool { progressManager.isLiked(course.id) }
    private var saved: Bool { progressManager.isFavorite(course.id) }

    private var hook: String {
        let content = CourseContentStore.content(courseId: course.id, language: languageManager.current)
        return (content?.hero?.hook ?? course.description).withoutInlineMarkup
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if let coverHeight {
                    Color.clear.frame(height: coverHeight)
                } else {
                    Color.clear.aspectRatio(16 / 9, contentMode: .fit)
                }
            }
                .overlay { CourseCover(course: course, cornerRadius: 0) }
                .overlay(alignment: .topLeading) {
                    HStack(spacing: 6) {
                        SubjectPill(subject: course.subject)
                        if let tag { TagPill(text: tag, style: tagStyle) }
                    }
                    .padding(12)
                }
                .clipped()

            VStack(alignment: .leading, spacing: 10) {
                if let kicker {
                    Text(kicker)
                        .font(DS.sans(.caption, .semibold))
                        .foregroundStyle(DS.inkSecondary)
                }
                Text(course.title.withoutInlineMarkup)
                    .font(DS.title(.title3, .heavy))
                    .foregroundStyle(DS.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(hook)
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.inkSecondary)
                    .lineSpacing(2)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                CreatorLine(identity: identity, onTap: identity.author.map { author in { onOpenCreator(author) } })
                    .padding(.top, 2)

                if fillsPage { Spacer(minLength: 0) }

                Rectangle().fill(DS.hairline).frame(height: 1)

                statsRow
            }
            .padding(16)
            .frame(maxHeight: fillsPage ? .infinity : nil, alignment: .top)
        }
        .frame(maxHeight: fillsPage ? .infinity : nil, alignment: .top)
        .background(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(DS.surface))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
        .overlay { BigHeartOverlay(trigger: bigHeart) }
        .dsSoftShadow()
        .contentShape(Rectangle())
        // Un tap ouvre le cours, deux taps l'aiment (le simple tap attend donc un instant,
        // le temps de savoir s'il est doublé).
        .gesture(
            TapGesture(count: 2)
                .onEnded { toggleLike(fromDoubleTap: true) }
                .exclusively(before: TapGesture().onEnded {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onOpen()
                })
        )
        .task(id: course.id) {
            minutes = ReadingTime.minutes(for: course, language: languageManager.current)
        }
        .accessibilityElement(children: .contain)
    }

    /// Le cœur : au bouton, il bascule ; au double-tap, il n'allume jamais vers l'éteint (comme
    /// sur les réseaux vidéo), mais le grand cœur s'affiche quand même.
    private func toggleLike(fromDoubleTap: Bool = false) {
        UIImpactFeedbackGenerator(style: fromDoubleTap ? .medium : .light).impactOccurred()
        let wasLiked = liked
        if fromDoubleTap {
            bigHeart += 1
            if wasLiked { return }
        }
        progressManager.toggleLike(course.id)
        if !wasLiked {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { likeBurst += 1 }
        }
        AnalyticsService.shared.log(wasLiked ? .unlike : .like, courseId: course.id, screen: screen)
    }

    private var statsRow: some View {
        HStack(spacing: 18) {
            StatChip(systemImage: "eye", text: course.readsCount.compactCount)

            Button {
                toggleLike()
            } label: {
                HStack(spacing: 5) {
                    LikeHeartIcon(liked: liked, burst: likeBurst)
                    Text(course.likesCount(liked: liked).compactCount)
                        .font(DS.sans(.footnote, .semibold))
                        .foregroundStyle(liked ? DS.liked : DS.inkSecondary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(AppLocalizable.string(liked ? "common.unlike" : "common.like", language: languageManager.current)))

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                let wasSaved = saved
                progressManager.toggleFavorite(course.id)
                AnalyticsService.shared.log(wasSaved ? .unsave : .save, courseId: course.id, screen: screen)
            } label: {
                Image(systemName: saved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(saved ? DS.accent : DS.inkSecondary)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 2)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(AppLocalizable.string(saved ? "common.unsave" : "common.save", language: languageManager.current)))

            Spacer(minLength: 0)

            if let minutes {
                StatChip(systemImage: "clock", text: NewGenFormat.minutes(minutes, language: languageManager.current))
            }
        }
    }
}

// MARK: - Carte événement

/// L'événement dans le fil : fond bleu nuit, symbole or, trois couvertures, barre du défi.
struct EventFeedCard: View {
    @Environment(LanguageManager.self) private var languageManager
    let campaign: Campaign
    let progressManager: ProgressManager
    /// Dans le fil paginé, la carte remplit sa page.
    var fillsPage = false
    let onOpen: () -> Void

    private var courses: [Course] {
        campaign.courseIds.compactMap { ContentCatalog.course(withId: $0) }
    }

    var body: some View {
        let language = languageManager.current
        let done = CampaignStore.challengeProgress(for: campaign, progressManager: progressManager)
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Image(systemName: campaign.symbol ?? "sparkles")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(DS.warm)
                Spacer(minLength: 8)
                if let end = campaign.endDate {
                    Text(String(format: AppLocalizable.string("event.card.until", language: language), NewGenFormat.shortDay(end, language: language)))
                        .font(DS.sans(.caption, .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(Capsule().fill(.white.opacity(0.16)))
                }
            }

            Text(campaign.title(for: language))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(.white)

            Text("\(campaign.tagline(for: language)) \(String(format: AppLocalizable.string("event.card.summary", language: language), courses.count, campaign.upcoming.count))")
                .font(DS.sans(.subheadline))
                .foregroundStyle(.white.opacity(0.86))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                ForEach(courses.prefix(3)) { course in
                    CourseCover(course: course, cornerRadius: 14)
                        .frame(width: 64, height: 64)
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(.white.opacity(0.6), lineWidth: 2))
                }
                if !campaign.upcoming.isEmpty {
                    Text(String(format: AppLocalizable.string("event.card.soon", language: language), campaign.upcoming.count))
                        .font(DS.sans(.subheadline, .semibold))
                        .foregroundStyle(.white)
                        .padding(.leading, 4)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 12) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.2))
                        Capsule()
                            .fill(DS.warm)
                            .frame(width: geo.size.width * CGFloat(min(1, Double(done) / Double(max(1, campaign.challengeTarget)))))
                    }
                }
                .frame(height: 6)
                Text(String(format: AppLocalizable.string("event.card.challenge", language: language), done, campaign.challengeTarget))
                    .font(DS.sans(.caption, .semibold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .fixedSize()
            }

            if fillsPage { Spacer(minLength: 0) }

            HStack(spacing: 4) {
                Text(AppLocalizable.string("event.card.seeCollection", language: language))
                    .font(DS.sans(.subheadline, .bold))
                Image(systemName: "chevron.forward")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(DS.warm)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(maxHeight: fillsPage ? .infinity : nil, alignment: .top)
        .background(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(DS.accent))
        .dsSoftShadow()
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onOpen()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Carte « Deviens créateur »

/// L'invitation à écrire, glissée dans le fil (jamais en tête) : quelques auteurs déjà
/// présents, la promesse en une phrase, trois atouts, et deux boutons.
struct CreatorInviteCard: View {
    @Environment(LanguageManager.self) private var languageManager
    /// Dans le fil paginé, la carte remplit sa page.
    var fillsPage = false
    let onBecomeCreator: () -> Void
    let onLater: () -> Void

    private var authors: [CourseAuthor] { Array(AuthorStore.all.prefix(4)) }
    private var languagesCount: Int { AppLanguage.allCases.count }

    var body: some View {
        let language = languageManager.current
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                HStack(spacing: -10) {
                    ForEach(authors) { author in
                        AuthorAvatarView(author: author, size: 32)
                            .overlay(Circle().strokeBorder(DS.surface, lineWidth: 2))
                    }
                }
                Text(AppLocalizable.string("creator.invite.kicker", language: language))
                    .font(DS.sans(.caption, .semibold))
                    .foregroundStyle(DS.inkSecondary)
                    .lineLimit(2)
            }

            Text(AppLocalizable.string("creator.invite.title", language: language))
                .font(DS.title(.title2, .heavy))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(String(format: AppLocalizable.string("creator.invite.body", language: language), languagesCount))
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            FlowChips {
                perk("pencil", AppLocalizable.string("creator.invite.perk.write", language: language))
                perk("globe", String(format: AppLocalizable.string("creator.invite.perk.languages", language: language), languagesCount))
                perk("chart.bar", AppLocalizable.string("creator.invite.perk.paid", language: language))
            }

            if fillsPage { Spacer(minLength: 0) }

            HStack(spacing: 10) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onBecomeCreator()
                } label: {
                    Text(AppLocalizable.string("creator.invite.cta", language: language))
                        .font(DS.sans(.subheadline, .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(DS.accent))
                }
                .buttonStyle(.plain)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onLater()
                } label: {
                    Text(AppLocalizable.string("path.quiz.later", language: language))
                        .font(DS.sans(.subheadline, .bold))
                        .foregroundStyle(DS.ink)
                        .padding(.horizontal, 18)
                        .frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(DS.surface))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(maxHeight: fillsPage ? .infinity : nil, alignment: .top)
        .background(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(DS.surface))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
        .dsSoftShadow()
    }

    private func perk(_ systemImage: String, _ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.accent)
            Text(text)
                .font(DS.sans(.footnote, .bold))
                .foregroundStyle(DS.ink)
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(Capsule().fill(DS.canvas))
    }
}

/// Rangée de chips qui passe à la ligne quand la place manque (petits écrans, langues longues).
struct FlowChips<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { content() }
            VStack(alignment: .leading, spacing: 8) { content() }
        }
    }
}

// MARK: - Carte vidéo (emplacement)

/// Emplacement d'une carte vidéo du fil. Aucune vidéo n'existe encore : la vue n'est jamais
/// montrée, elle fixe seulement la place et le gabarit (prompt 10).
struct VideoFeedCard: View {
    let title: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(DS.ink)
            Text(title)
                .font(DS.title(.title3, .heavy))
                .foregroundStyle(.white)
                .padding(20)
        }
        .frame(maxHeight: .infinity)
    }
}
