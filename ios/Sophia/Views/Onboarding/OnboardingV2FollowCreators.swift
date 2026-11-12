import SwiftUI

/// Page « Suis des profs », juste après « Ton profil » : une douzaine de créateurs à suivre
/// d'un geste, pour que l'onglet Abonnements de l'accueil ne soit pas vide au premier lancement.
///
/// Ceux qui écrivent dans les matières choisies pendant l'onboarding passent en premier, puis
/// les plus suivis. Rien n'est obligatoire : « Continuer » marche sans avoir suivi personne.
/// Le suivi est celui du reste de l'app (`UserProgress.followedCreatorSlugs`).
struct OnboardingV2FollowCreators: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let progressManager: ProgressManager
    let onNext: () -> Void

    @State private var authors: [CourseAuthor] = []

    /// Au-delà, la page devient une liste à faire défiler plus qu'un choix.
    private static let maxAuthors = 12

    var body: some View {
        OV2ScrollableContent {
            VStack(spacing: 0) {
                OV2EndTitle(text: languageManager.text("onboardingV2.follow.title"))
                    .padding(.top, OV2End.topWithoutHeader)
                    .dsStagger(0)

                OV2EndSubtitle(text: languageManager.text("onboardingV2.follow.subtitle"))
                    .padding(.top, 10)
                    .dsStagger(1)

                VStack(spacing: 8) {
                    ForEach(Array(authors.enumerated()), id: \.element.id) { index, author in
                        row(author)
                            .dsStagger(index, step: 0.05, base: 0.14)
                    }
                }
                .padding(.top, 18)
            }
            .padding(.horizontal, OV2End.side)
            .padding(.bottom, 28)
            .ov2ReadableWidth()
        } footer: {
            OnboardingV2Button(
                title: languageManager.text("common.continue"),
                action: onNext
            )
            // La liste s'efface sous le bouton au lieu d'être coupée net.
            .background(alignment: .top) { OV2EndBottomFade() }
        }
        .ov2Background()
        .onAppear { if authors.isEmpty { authors = Self.suggestedAuthors(subjects: vm.selectedSubjects) } }
    }

    /// Une ligne par prof : portrait, nom, titre ou spécialité, et la pastille « Suivre » /
    /// « Abonné ». Toute la ligne est le bouton.
    private func row(_ author: CourseAuthor) -> some View {
        let following: Bool = progressManager.isFollowing(author.slug)
        return Button {
            Haptics.select()
            progressManager.toggleFollow(author.slug)
            AnalyticsService.shared.log(
                following ? .unfollow : .follow,
                screen: "onboarding",
                props: ["creator": .string(author.slug)]
            )
        } label: {
            HStack(spacing: 11) {
                AuthorAvatarView(author: author, size: 46)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(author.name)
                            .font(DS.sans(.subheadline, .bold))
                            .foregroundStyle(DS.ink)
                            .lineLimit(1)
                        if author.isVerified { VerifiedCheck(size: 13) }
                    }
                    if let pedigree = author.title(for: languageManager.current) {
                        Text(pedigree)
                            .font(DS.sans(.caption, .regular))
                            .foregroundStyle(DS.inkSecondary)
                            .lineSpacing(1)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 6)
                followPill(following: following)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .ov2EndCard()
        }
        .buttonStyle(PressableStyle(haptic: false))
        .accessibilityAddTraits(following ? .isSelected : [])
    }

    /// Pastille de suivi : pleine et bleue une fois abonné, cerclée de bleu sinon.
    private func followPill(following: Bool) -> some View {
        Text(languageManager.text(following ? "creator.following" : "creator.follow"))
            .font(DS.sans(.footnote, .bold))
            .foregroundStyle(following ? Color.white : DS.accent)
            .lineLimit(1)
            .padding(.horizontal, 13)
            .frame(height: 34)
            .background(
                Capsule(style: .continuous)
                    .fill(following ? DS.accent : DS.surface)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(DS.accent, lineWidth: 1.5)
            )
            .fixedSize()
            .contentTransition(.opacity)
            .animation(DS.Motion.snappy, value: following)
    }

    /// Les créateurs proposés : d'abord ceux qui ont le plus de cours dans les matières
    /// choisies, puis les plus suivis. Vide quand le catalogue n'a aucun créateur (la page est
    /// alors sautée par le coordinateur).
    static func suggestedAuthors(subjects: [String]) -> [CourseAuthor] {
        let chosen = Set(subjects)
        func matches(_ author: CourseAuthor) -> Int {
            author.courseIds.reduce(0) { count, id in
                guard let course = ContentCatalog.course(withId: id) else { return count }
                return count + (chosen.contains(course.subject.storageKey) ? 1 : 0)
            }
        }
        let ranked = AuthorStore.all
            .filter { !$0.courseIds.isEmpty }
            .map { (author: $0, matches: matches($0), followers: LocalCounters.followers(creatorSlug: $0.slug)) }
            .sorted { a, b in
                // Une matière choisie compte avant le nombre d'abonnés ; le slug départage.
                if (a.matches > 0) != (b.matches > 0) { return a.matches > 0 }
                if a.followers != b.followers { return a.followers > b.followers }
                return a.author.slug < b.author.slug
            }
        return ranked.prefix(maxAuthors).map { $0.author }
    }
}
