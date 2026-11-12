import SwiftUI

/// L'onglet Explorer, variante « univers » de la maquette : la recherche (cours, créateurs,
/// termes du glossaire), les événements (en cours, puis terminés en gris), les sujets qu'on
/// cherche beaucoup cette semaine, la grille des univers (les grandes sous-catégories du
/// catalogue, avec une couverture), les créateurs à suivre en carrousel et, tout en bas,
/// l'entrée du Parcours. La rangée « En moins d'une minute » arrivera avec les vidéos (prompt 10).
struct ExploreView: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    let onOpenCourse: (Course) -> Void
    let onOpenCreator: (CourseAuthor) -> Void
    let onOpenCampaign: (Campaign) -> Void
    let onOpenUniverse: (String) -> Void
    let onOpenPath: () -> Void

    @State private var query = ""
    @State private var selectedTrend: String?
    @FocusState private var searchFocused: Bool

    /// Marge latérale de l'écran.
    private static let sideMargin: CGFloat = 24

    private var language: AppLanguage { languageManager.current }
    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isSearching: Bool { trimmedQuery.count >= 2 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(languageManager.text("tab.explore"))
                        .font(DS.title(.largeTitle, .medium))
                        .foregroundStyle(DS.ink)
                        .padding(.top, 8)

                    searchField
                }
                .padding(.horizontal, Self.sideMargin)

                if isSearching {
                    results
                        .padding(.horizontal, Self.sideMargin)
                } else {
                    eventsSection
                        .dsStagger(0)
                    trendingSection
                        .dsStagger(1)
                    universesSection
                        .padding(.horizontal, Self.sideMargin)
                        .dsStagger(2)
                    creatorsCarousel
                        .dsStagger(3)
                    pathCard
                        .padding(.horizontal, Self.sideMargin)
                        .dsStagger(4)
                }
            }
            .padding(.vertical, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        // Tirer vers le bas relit le catalogue en ligne tout de suite (nouveaux cours, corrections).
        .refreshable {
            await CatalogStore.shared.refresh(language: language, force: true)
        }
        .background(DS.canvas.ignoresSafeArea())
    }

    // MARK: - Parcours

    /// Le niveau où en est le lecteur : le premier qui n'est pas réussi, sinon le dernier.
    private var currentPathLevel: Int {
        let levels = LearningPathEngine.snapshot(progressManager: progressManager).levels
        return (levels.first { !$0.isPassed } ?? levels.last)?.number ?? 1
    }

    /// L'entrée du Parcours, qui n'a plus d'onglet à lui : tout en bas de la page, sur fond marine,
    /// avec son illustration en papier découpé (`path_poster`, même direction que le site).
    private var pathCard: some View {
        Button {
            onOpenPath()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(languageManager.text("path.title"))
                    .font(DS.title(.title3, .heavy))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(languageManager.text("explore.path.subtitle"))
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(Self.pathSoftText)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 4) {
                    Text(String(format: languageManager.text("path.levelCaption"), currentPathLevel))
                        .font(DS.sans(.subheadline, .heavy))
                        .lineLimit(1)
                    Image(systemName: "chevron.forward")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(EventPalette.ink)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Capsule().fill(EventPalette.saffron))
                .padding(.top, 4)
            }
            .padding(16)
            .padding(.trailing, Self.pathPosterWidth)
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
            .background(alignment: .trailing) {
                Color.clear
                    .frame(width: Self.pathPosterWidth)
                    .overlay {
                        Image("path_poster")
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
                    .accessibilityHidden(true)
            }
            .background(EventPalette.navy)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
    }

    private static let pathPosterWidth: CGFloat = 130
    /// Le bleu clair du sous-titre posé sur le marine.
    private static let pathSoftText = Color(red: 201.0 / 255.0, green: 214.0 / 255.0, blue: 238.0 / 255.0)

    // MARK: - Événements

    private struct ExploreEvent: Identifiable {
        let campaign: Campaign
        let ended: Bool
        var id: String { campaign.slug }
    }

    /// Les événements que le serveur sert (publiés, dans la région du téléphone) : ceux en cours
    /// d'abord (le plus proche de sa fin en tête), puis les terminés, du plus récent au plus
    /// ancien, grisés. Un événement terminé reste là tant qu'il est en ligne et disparaît quand
    /// il n'est plus publié ; ceux qui n'ont pas commencé ne sont pas montrés.
    private var events: [ExploreEvent] {
        let now = Date()
        return CampaignStore.active(on: now).map { ExploreEvent(campaign: $0, ended: false) }
            + CampaignStore.ended(on: now).map { ExploreEvent(campaign: $0, ended: true) }
    }

    @ViewBuilder
    private var eventsSection: some View {
        let items = events
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                NewGenSectionTitle(text: languageManager.text("badges.family.events"))
                    .padding(.horizontal, Self.sideMargin)
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(items) { item in
                            eventCard(item.campaign, ended: item.ended)
                        }
                    }
                    .padding(.horizontal, Self.sideMargin)
                    .padding(.bottom, 8)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private static let eventCardWidth: CGFloat = 232

    /// Une carte d'événement du carrousel. Toutes ont la même taille : l'illustration a une
    /// hauteur fixe et chaque ligne de texte réserve sa place (le titre toujours deux lignes).
    private func eventCard(_ campaign: Campaign, ended: Bool) -> some View {
        let courses = campaign.courseIds.compactMap { ContentCatalog.course(withId: $0) }
        return Button {
            onOpenCampaign(campaign)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Color.clear
                    .frame(width: Self.eventCardWidth, height: 130)
                    .overlay { EventArtwork(campaign: campaign, courses: courses) }
                    .overlay(alignment: .topLeading) {
                        if ended {
                            EventPill(text: languageManager.text("event.ended"), style: .dark)
                                .padding(10)
                        }
                    }
                    .clipped()
                VStack(alignment: .leading, spacing: 4) {
                    Text(eventDates(campaign, ended: ended))
                        .font(DS.sans(.caption, .bold))
                        .foregroundStyle(ended ? DS.inkTertiary : DS.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(campaign.title(for: language))
                        .font(DS.sans(.callout, .bold))
                        .foregroundStyle(DS.ink)
                        .lineLimit(2, reservesSpace: true)
                        .multilineTextAlignment(.leading)
                    Text(String(format: languageManager.text("event.card.coursesToRead"), courses.count))
                        .font(DS.sans(.footnote))
                        .foregroundStyle(DS.inkSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .frame(width: Self.eventCardWidth, alignment: .leading)
            }
            .homeCard()
            // Terminé : la carte passe en gris et s'efface un peu, mais reste ouvrable.
            .saturation(ended ? 0 : 1)
            .opacity(ended ? 0.6 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
    }

    /// « Jusqu'au 30 nov. » pour un événement en cours, « 1 nov. – 30 nov. » pour un terminé.
    /// Jamais vide, pour que la ligne garde sa hauteur.
    private func eventDates(_ campaign: Campaign, ended: Bool) -> String {
        guard let end = campaign.endDate else { return " " }
        if !ended {
            return String(format: languageManager.text("event.until"), NewGenFormat.shortDay(end, language: language))
        }
        guard let start = campaign.startDate else { return NewGenFormat.shortDay(end, language: language) }
        return "\(NewGenFormat.shortDay(start, language: language)) – \(NewGenFormat.shortDay(end, language: language))"
    }

    // MARK: - Recherche

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(searchFocused ? DS.accent : DS.inkSecondary)
            TextField(languageManager.text("explore.search.placeholder"), text: $query)
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.ink)
                .focused($searchFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DS.ink)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(DS.accentTint))
                        .contentShape(Circle())
                }
                .buttonStyle(PressableStyle(scale: 0.88))
                .accessibilityLabel(Text(languageManager.text("explore.search.clear")))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
        // Le champ actif prend la bordure bleue des états sélectionnés.
        .homeCard(border: searchFocused ? DS.accent : DS.hairline)
        .animation(DS.Motion.snappy, value: searchFocused)
        .animation(DS.Motion.snappy, value: query.isEmpty)
    }

    private var matchingCourses: [Course] {
        let needle = ExploreSearch.normalize(trimmedQuery)
        return ContentCatalog.activeCourses.filter { course in
            ExploreSearch.normalize(course.title).contains(needle)
                || ExploreSearch.normalize(course.subcategory).contains(needle)
                || ExploreSearch.normalize(course.subject.localizedName(language: language)).contains(needle)
        }
    }

    private var matchingAuthors: [CourseAuthor] {
        let needle = ExploreSearch.normalize(trimmedQuery)
        return AuthorStore.all.filter { author in
            ExploreSearch.normalize(author.name).contains(needle)
                || ExploreSearch.normalize(author.title(for: language) ?? "").contains(needle)
        }
    }

    private var matchingTerms: [ExploreSearch.GlossaryHit] {
        ExploreSearch.glossary(trimmedQuery, language: language, limit: 8)
    }

    @ViewBuilder
    private var results: some View {
        let courses = matchingCourses
        let authors = matchingAuthors
        let terms = matchingTerms
        if courses.isEmpty, authors.isEmpty, terms.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(languageManager.text("library.empty.title"))
                    .font(DS.sans(.callout, .bold))
                    .foregroundStyle(DS.ink)
                Text(languageManager.text("library.empty.subtitle"))
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .homeCard()
        } else {
            // Chaque famille de résultats : son titre, puis ses lignes serrées dessous.
            VStack(alignment: .leading, spacing: 24) {
                if !courses.isEmpty {
                    VStack(alignment: .leading, spacing: 9) {
                        NewGenSectionTitle(text: languageManager.text("library.tab.courses"), trailing: "· \(courses.count)")
                        ForEach(courses.prefix(12)) { course in
                            courseRow(course)
                        }
                    }
                }
                if !authors.isEmpty {
                    VStack(alignment: .leading, spacing: 9) {
                        NewGenSectionTitle(text: languageManager.text("explore.results.creators"), trailing: "· \(authors.count)")
                        ForEach(authors) { author in
                            creatorRow(author)
                        }
                    }
                }
                if !terms.isEmpty {
                    VStack(alignment: .leading, spacing: 9) {
                        NewGenSectionTitle(text: languageManager.text("explore.results.glossary"), trailing: "· \(terms.count)")
                        ForEach(terms) { hit in
                            glossaryRow(hit)
                        }
                    }
                }
            }
        }
    }

    private func courseRow(_ course: Course) -> some View {
        CompactCourseRow(
            course: course,
            meta: "\(CreatorIdentity.forCourse(course.id).name) · \(NewGenFormat.minutes(ReadingTime.minutes(for: course, language: language), language: language))",
            onTap: { onOpenCourse(course) }
        ) {
            if progressManager.courseStatus(for: course.id) == .completed { ReadCheck() }
        }
    }

    private func glossaryRow(_ hit: ExploreSearch.GlossaryHit) -> some View {
        Button {
            if let course = hit.course { onOpenCourse(course) }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "book")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DS.accent)
                    .frame(width: 22, height: 22)
                VStack(alignment: .leading, spacing: 3) {
                    Text(hit.entry.displayTerm)
                        .font(DS.sans(.subheadline, .bold))
                        .foregroundStyle(DS.ink)
                        .multilineTextAlignment(.leading)
                    Text(hit.entry.explanation)
                        .font(DS.sans(.footnote))
                        .foregroundStyle(DS.inkSecondary)
                        .lineSpacing(2)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    if let course = hit.course {
                        Text(course.title.withoutInlineMarkup)
                            .font(DS.sans(.caption, .bold))
                            .foregroundStyle(DS.accent)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .homeCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
    }

    /// Un créateur dans les résultats de recherche : avatar, nom avec coche, pedigree, abonnés, Suivre.
    private func creatorRow(_ author: CourseAuthor) -> some View {
        let following = progressManager.isFollowing(author.slug)
        return HStack(spacing: 12) {
            Button { onOpenCreator(author) } label: {
                HStack(spacing: 12) {
                    AuthorAvatarView(author: author, size: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Text(author.name)
                                .font(DS.sans(.subheadline, .bold))
                                .foregroundStyle(DS.ink)
                                .lineLimit(1)
                            if author.isVerified { VerifiedCheck(size: 14) }
                        }
                        if let pedigree = author.title(for: language) {
                            Text(pedigree)
                                .font(DS.sans(.caption))
                                .foregroundStyle(DS.inkSecondary)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                        }
                        Text(followersLabel(author, following: following))
                            .font(DS.sans(.caption, .semibold))
                            .foregroundStyle(DS.ink)
                            .contentTransition(.numericText())
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            FollowButton(isFollowing: following, compact: true) { toggleFollow(author) }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .homeCard()
    }

    private func followersLabel(_ author: CourseAuthor, following: Bool) -> String {
        "\((LocalCounters.followers(creatorSlug: author.slug) + (following ? 1 : 0)).compactCount) \(languageManager.text("creator.stat.followers"))"
    }

    private func toggleFollow(_ author: CourseAuthor) {
        let following = progressManager.isFollowing(author.slug)
        progressManager.toggleFollow(author.slug)
        AnalyticsService.shared.log(following ? .unfollow : .follow, screen: "explore", props: ["creator": .string(author.slug)])
    }

    // MARK: - On cherche beaucoup cette semaine

    /// Les cours les plus ouverts de la semaine dans la langue, comptés chaque nuit par le serveur
    /// (`trending` du manifeste), moins ceux déjà lus. Faute de données (pas encore d'événements),
    /// six cours au titre court tirés une fois par semaine (graine = semaine ISO) parmi les non lus.
    private var trendingCourses: [Course] {
        let fromServer = CatalogStore.shared.trending(for: languageManager.current)
            .compactMap { ContentCatalog.course(withId: $0) }
            .filter { progressManager.courseStatus(for: $0.id) != .completed }
        if fromServer.count >= 3 { return Array(fromServer.prefix(6)) }
        let calendar = Calendar(identifier: .iso8601)
        let now = Date()
        let seed = "\(calendar.component(.yearForWeekOfYear, from: now))-\(calendar.component(.weekOfYear, from: now))"
        return Array(
            ContentCatalog.activeCourses
                .filter { $0.title.withoutInlineMarkup.count <= 22 && progressManager.courseStatus(for: $0.id) != .completed }
                .sorted { LocalCounters.hash("\(seed)|\($0.id)") < LocalCounters.hash("\(seed)|\($1.id)") }
                .prefix(6)
        )
    }

    /// Le cours de la tendance choisie, puis deux voisins de la même sous-catégorie.
    private func trendResults(for course: Course) -> [Course] {
        let neighbours = ContentCatalog.activeCourses
            .filter { $0.id != course.id && $0.subcategory == course.subcategory }
            .sorted { $0.readsCount > $1.readsCount }
            .prefix(2)
        return [course] + neighbours
    }

    @ViewBuilder
    private var trendingSection: some View {
        let trends = trendingCourses
        if !trends.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(languageManager.text("explore.trending"))
                    .font(DS.sans(.footnote, .bold))
                    .foregroundStyle(DS.inkSecondary)
                    .padding(.horizontal, Self.sideMargin)

                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(trends) { course in
                            let selected = selectedTrend == course.id
                            Button {
                                Haptics.select()
                                withAnimation(DS.Motion.snappy) {
                                    selectedTrend = selected ? nil : course.id
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 12, weight: .bold))
                                    Text(course.title.withoutInlineMarkup)
                                        .font(DS.sans(.subheadline, .bold))
                                        .lineLimit(1)
                                }
                                .foregroundStyle(selected ? Color.white : DS.ink)
                                .padding(.horizontal, 14)
                                .frame(height: 44)
                                .homeCard(fill: selected ? DS.accent : DS.surface, border: selected ? DS.accent : DS.hairline)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PressableStyle(scale: 0.96, haptic: false))
                        }
                    }
                    .padding(.horizontal, Self.sideMargin)
                    .padding(.bottom, 2)
                }
                .scrollIndicators(.hidden)

                if let selectedTrend, let course = trends.first(where: { $0.id == selectedTrend }) {
                    VStack(spacing: 9) {
                        ForEach(trendResults(for: course)) { result in
                            courseRow(result)
                        }
                    }
                    .padding(.horizontal, Self.sideMargin)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    // MARK: - Univers

    /// Une sous-catégorie du catalogue, avec la couverture de son cours le plus lu.
    private struct Universe: Identifiable {
        let name: String
        let courses: [Course]
        let cover: Course
        var id: String { name }
    }

    /// Les six plus grandes sous-catégories de la langue courante.
    private var universes: [Universe] {
        let groups = Dictionary(grouping: ContentCatalog.activeCourses.filter { !$0.subcategory.isEmpty }, by: \.subcategory)
        return Array(
            groups.compactMap { name, courses -> Universe? in
                guard let cover = courses.max(by: { $0.readsCount < $1.readsCount }) else { return nil }
                return Universe(name: name, courses: courses, cover: cover)
            }
            .sorted { lhs, rhs in
                lhs.courses.count != rhs.courses.count ? lhs.courses.count > rhs.courses.count : lhs.name < rhs.name
            }
            .prefix(6)
        )
    }

    private var universesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            NewGenSectionTitle(text: languageManager.text("explore.universes"))
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(universes) { universe in
                    Button {
                        onOpenUniverse(universe.name)
                    } label: {
                        universeTile(universe)
                    }
                    .buttonStyle(.pressable)
                }
            }
        }
    }

    /// Une tuile d'univers : la couverture en haut, le nom (deux lignes réservées) et le nombre
    /// de cours dessous, sur fond blanc.
    private func universeTile(_ universe: Universe) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .frame(height: 84)
                .frame(maxWidth: .infinity)
                .overlay { CourseCover(course: universe.cover, cornerRadius: 0) }
                .clipped()
            VStack(alignment: .leading, spacing: 2) {
                Text(universe.name)
                    .font(DS.sans(.footnote, .bold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                Text(String(format: languageManager.text("subject.courses.count"), universe.courses.count))
                    .font(DS.sans(.caption))
                    .foregroundStyle(DS.inkSecondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .homeCard()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    // MARK: - Créateurs à suivre

    private var discoverableAuthors: [CourseAuthor] {
        AuthorStore.all.sorted { LocalCounters.followers(creatorSlug: $0.slug) > LocalCounters.followers(creatorSlug: $1.slug) }
    }

    private var creatorsCarousel: some View {
        VStack(alignment: .leading, spacing: 10) {
            NewGenSectionTitle(text: languageManager.text("explore.creatorsToFollow"))
                .padding(.horizontal, Self.sideMargin)
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(discoverableAuthors.prefix(8)) { author in
                        creatorCard(author)
                    }
                }
                .padding(.horizontal, Self.sideMargin)
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
        }
    }

    /// La carte verticale de la maquette : avatar, nom, pedigree sur deux lignes, abonnés, Suivre.
    private func creatorCard(_ author: CourseAuthor) -> some View {
        let following = progressManager.isFollowing(author.slug)
        return VStack(spacing: 6) {
            Button { onOpenCreator(author) } label: {
                VStack(spacing: 6) {
                    AuthorAvatarView(author: author, size: 60)
                    HStack(spacing: 5) {
                        Text(author.name)
                            .font(DS.sans(.subheadline, .bold))
                            .foregroundStyle(DS.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        if author.isVerified { VerifiedCheck(size: 13) }
                    }
                    Text(author.title(for: language) ?? "")
                        .font(DS.sans(.caption))
                        .foregroundStyle(DS.inkSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2, reservesSpace: true)
                    Text(followersLabel(author, following: following))
                        .font(DS.sans(.footnote, .semibold))
                        .foregroundStyle(DS.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            FollowButton(isFollowing: following, compact: true) { toggleFollow(author) }
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .frame(width: 168)
        .homeCard()
    }
}

/// Les cours d'un univers (une sous-catégorie), ouverts depuis la grille de l'onglet Explorer.
struct UniverseCoursesView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    let subcategory: String
    let progressManager: ProgressManager
    let onOpenCourse: (Course) -> Void

    private var courses: [Course] {
        ContentCatalog.activeCourses
            .filter { $0.subcategory == subcategory }
            .sorted { $0.readsCount > $1.readsCount }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 12) {
                    RoundIconButton(systemImage: "chevron.left", accessibilityLabel: languageManager.text("common.close")) { dismiss() }
                    Text("\(subcategory) · \(courses.count)")
                        .font(DS.title(.title2, .semibold))
                        .foregroundStyle(DS.ink)
                        .lineLimit(2)
                    Spacer()
                }
                .padding(.bottom, 8)
                ForEach(Array(courses.enumerated()), id: \.element.id) { index, course in
                    CompactCourseRow(
                        course: course,
                        meta: "\(CreatorIdentity.forCourse(course.id).name) · \(NewGenFormat.minutes(ReadingTime.minutes(for: course, language: languageManager.current), language: languageManager.current))",
                        onTap: { onOpenCourse(course) }
                    ) {
                        if progressManager.courseStatus(for: course.id) == .completed { ReadCheck() }
                    }
                    .dsStagger(min(index, 10))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(DS.canvas.ignoresSafeArea())
    }
}

/// Recherche dans le glossaire de la langue courante (catalogue en ligne), avec le cours
/// d'origine quand il est retrouvé.
enum ExploreSearch {
    struct GlossaryHit: Identifiable {
        let entry: GlossaryEntry
        let course: Course?
        var id: String { "\(course?.id ?? "")|\(entry.displayTerm)" }
    }

    static func normalize(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: nil).lowercased()
    }

    static func glossary(_ query: String, language: AppLanguage, limit: Int) -> [GlossaryHit] {
        let needle = normalize(query)
        guard needle.count >= 2 else { return [] }
        var hits: [GlossaryHit] = []
        var seen: Set<String> = []
        for (key, entry) in LocalizedContentLoader.glossaryEntries(for: language) where normalize(entry.displayTerm).contains(needle) {
            let courseId = String(key.split(separator: "|", maxSplits: 1).first ?? "")
            let dedupe = normalize(entry.displayTerm) + "|" + courseId
            guard !seen.contains(dedupe) else { continue }
            seen.insert(dedupe)
            hits.append(GlossaryHit(entry: entry, course: ContentCatalog.course(withId: courseId)))
            if hits.count >= limit { break }
        }
        return hits.sorted { $0.entry.displayTerm < $1.entry.displayTerm }
    }
}
