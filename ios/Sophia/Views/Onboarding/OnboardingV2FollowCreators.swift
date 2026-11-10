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
            VStack(spacing: 22) {
                VStack(spacing: 10) {
                    Text(languageManager.text("onboardingV2.follow.title"))
                        .font(DS.title(.title, .heavy))
                        .foregroundStyle(OV2.ink)
                        .multilineTextAlignment(.center)
                    Text(languageManager.text("onboardingV2.follow.subtitle"))
                        .font(DS.sans(.body, .medium))
                        .foregroundStyle(OV2.inkSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 36)
                .ov2Reveal(delay: 0.05)

                VStack(spacing: 10) {
                    ForEach(authors) { author in
                        row(author)
                    }
                }
                .ov2Reveal(delay: 0.14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            .ov2ReadableWidth()
        } footer: {
            OnboardingV2Button(
                title: languageManager.text("common.continue"),
                action: onNext
            )
        }
        .ov2Background()
        .onAppear { if authors.isEmpty { authors = Self.suggestedAuthors(subjects: vm.selectedSubjects) } }
    }

    private func row(_ author: CourseAuthor) -> some View {
        let following = progressManager.isFollowing(author.slug)
        return HStack(spacing: 12) {
            AuthorAvatarView(author: author, size: 48)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(author.name)
                        .font(DS.sans(.subheadline, .bold))
                        .foregroundStyle(OV2.ink)
                        .lineLimit(1)
                    if author.isVerified { VerifiedCheck(size: 13) }
                }
                if let pedigree = author.title(for: languageManager.current) {
                    Text(pedigree)
                        .font(DS.sans(.caption))
                        .foregroundStyle(OV2.inkSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            FollowButton(isFollowing: following, compact: true) {
                progressManager.toggleFollow(author.slug)
                AnalyticsService.shared.log(
                    following ? .unfollow : .follow,
                    screen: "onboarding",
                    props: ["creator": .string(author.slug)]
                )
            }
        }
        .padding(12)
        .background(OV2.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(following ? OV2.accent : OV2.hairline, lineWidth: following ? 1.5 : 1)
        }
        .animation(.easeInOut(duration: 0.15), value: following)
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
