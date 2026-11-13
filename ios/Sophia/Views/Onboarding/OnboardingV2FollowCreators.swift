import SwiftUI

/// Page « Suis des profs », juste après « Ton profil » : une douzaine de créateurs à suivre
/// d'un geste, pour que l'onglet Abonnements de l'accueil ne soit pas vide au premier lancement.
///
/// Ceux qui écrivent dans les matières choisies pendant l'onboarding passent en premier, puis
/// les plus suivis. Rien n'est obligatoire : « Continuer » marche sans avoir suivi personne.
/// Le suivi est celui du reste de l'app (`UserProgress.followedCreatorSlugs`).
///
/// Toucher un prof ouvre une fenêtre qui le présente (portrait, nom, parcours, bio) et montre
/// ses cours ; la pastille « Suivre » de la ligne, elle, suit sans rien ouvrir. On peut aussi
/// suivre depuis la fenêtre.
struct OnboardingV2FollowCreators: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let progressManager: ProgressManager
    let onNext: () -> Void

    @State private var authors: [CourseAuthor] = []
    /// Le prof dont la fenêtre de présentation est ouverte.
    @State private var presented: CourseAuthor?

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
        // La présentation du prof monte du bas, en feuille : on la tire vers le haut pour tout
        // lire, vers le bas pour revenir à la liste.
        .sheet(item: $presented) { author in
            OnboardingV2CreatorPopup(
                author: author,
                isFollowing: progressManager.isFollowing(author.slug),
                onToggleFollow: { toggleFollow(author) },
                onClose: { presented = nil },
                asSheet: true
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .preferredColorScheme(.light)
        }
        .onAppear { if authors.isEmpty { authors = Self.suggestedAuthors(subjects: vm.selectedSubjects) } }
    }

    /// Une ligne par prof : portrait, nom, titre ou spécialité, et la pastille « Suivre » /
    /// « Abonné ». Le portrait et le texte ouvrent la présentation du prof ; la pastille suit.
    private func row(_ author: CourseAuthor) -> some View {
        let following: Bool = progressManager.isFollowing(author.slug)
        return HStack(spacing: 6) {
            Button {
                Haptics.tap()
                presented = author
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
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 9)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle(haptic: false))
            .accessibilityHint(Text(String(format: languageManager.text("onboardingV2.follow.about"), author.name)))

            Button {
                Haptics.select()
                toggleFollow(author)
            } label: {
                followPill(following: following)
                    // Zone tactile de 44 pt autour d'une pastille de 34 pt.
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle(scale: 0.94, haptic: false))
            .accessibilityLabel(Text(languageManager.text(following ? "creator.following" : "creator.follow") + ", " + author.name))
            .accessibilityAddTraits(following ? .isSelected : [])
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ov2EndCard()
    }

    /// Suit ou ne suit plus `author`, comme le reste de l'app, et le note dans l'analyse.
    private func toggleFollow(_ author: CourseAuthor) {
        let wasFollowing: Bool = progressManager.isFollowing(author.slug)
        progressManager.toggleFollow(author.slug)
        AnalyticsService.shared.log(
            wasFollowing ? .unfollow : .follow,
            screen: "onboarding",
            props: ["creator": .string(author.slug)]
        )
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
            .animation(DSCalmMotion.state, value: following)
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

// MARK: - Présentation d'un prof

/// Présentation d'un prof par-dessus la liste (en feuille montant du bas dans l'onboarding) : portrait, nom, parcours, « Suivre »,
/// bio, puis ses cours (couverture, titre, matière). Les données sont celles de la page d'un
/// créateur dans l'app (`CourseAuthor` et le catalogue).
///
/// La fenêtre épouse son contenu quand il tient à l'écran et défile sinon. Elle se ferme par
/// la croix, en touchant le fond assombri, ou par le geste d'échappement de VoiceOver.
struct OnboardingV2CreatorPopup: View {
    @Environment(LanguageManager.self) private var languageManager
    let author: CourseAuthor
    let isFollowing: Bool
    let onToggleFollow: () -> Void
    let onClose: () -> Void
    /// Présentée dans une feuille qui monte du bas (l'onboarding) : pas de fond assombri ni de
    /// croix, la feuille a sa poignée et se ferme en la tirant vers le bas.
    var asSheet: Bool = false

    @State private var courses: [Course] = []
    @AccessibilityFocusState private var nameFocused: Bool

    /// Au-delà, la fenêtre devient une page ; la page complète du prof est dans l'app.
    private static let maxCourses = 8

    var body: some View {
        Group {
            if asSheet {
                sheetContent
            } else {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onClose)
                        .accessibilityHidden(true)

                    card
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                }
            }
        }
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onClose)
        .onAppear {
            if courses.isEmpty { courses = Self.courses(of: author) }
            // VoiceOver commence par le nom du prof.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                nameFocused = true
            }
        }
    }

    /// Les cours du prof, les plus lus d'abord.
    private static func courses(of author: CourseAuthor) -> [Course] {
        let all: [Course] = author.courseIds.compactMap { ContentCatalog.course(withId: $0) }
        let sorted: [Course] = all.sorted { $0.readsCount > $1.readsCount }
        return Array(sorted.prefix(maxCourses))
    }

    /// Le contenu de la feuille : les mêmes éléments que la fenêtre, qui défilent sous la poignée.
    private var sheetContent: some View {
        ScrollView(.vertical) {
            details
                .padding(.top, 30)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(DS.surface.ignoresSafeArea())
    }

    private var card: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer(minLength: 0)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DS.inkSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle(scale: 0.9))
                .accessibilityLabel(Text(languageManager.text("common.close")))
            }
            .padding(.trailing, 6)
            .padding(.top, 6)

            // Le contenu à sa hauteur quand il tient ; sinon il défile dans la place restante.
            ViewThatFits(in: .vertical) {
                details
                ScrollView(.vertical) {
                    details
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(DS.surface)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        // Un appui sur la fenêtre elle-même ne la ferme pas (seul le fond assombri ferme).
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onTapGesture {}
    }

    private var details: some View {
        VStack(spacing: 0) {
            identity

            FollowButton(isFollowing: isFollowing, action: onToggleFollow)
                .padding(.top, 16)

            if let bio = author.bio(for: languageManager.current) {
                Text(bio)
                    .font(DS.sans(.subheadline, .regular))
                    .foregroundStyle(DS.inkSecondary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)
            }

            if !courses.isEmpty {
                DSEyebrow(text: languageManager.text("onboardingV2.follow.courses"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, 20)

                VStack(spacing: 10) {
                    ForEach(courses) { course in
                        courseRow(course)
                    }
                }
                .padding(.top, 10)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 22)
    }

    /// Portrait, nom (et coche des experts vérifiés), parcours : centrés.
    private var identity: some View {
        VStack(spacing: 8) {
            AuthorAvatarView(author: author, size: 88)

            HStack(spacing: 5) {
                Text(author.name)
                    .font(DS.title(.title3, .bold))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($nameFocused)
                if author.isVerified { VerifiedCheck(size: 15) }
            }

            if let pedigree = author.title(for: languageManager.current) {
                Text(pedigree)
                    .font(DS.sans(.subheadline, .regular))
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Un cours du prof : sa couverture, son titre et sa matière.
    private func courseRow(_ course: Course) -> some View {
        HStack(spacing: 12) {
            CourseCover(course: course, cornerRadius: 10)
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text(course.title.withoutInlineMarkup)
                    .font(DS.sans(.footnote, .semibold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(course.subject.localizedShortName(language: languageManager.current))
                    .font(DS.sans(.caption, .regular))
                    .foregroundStyle(DS.inkSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
