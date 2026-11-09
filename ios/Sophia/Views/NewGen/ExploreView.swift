import SwiftUI

/// L'onglet Explorer, variante « univers » de la maquette : la recherche (cours, créateurs,
/// termes du glossaire), les sujets qu'on cherche beaucoup cette semaine, la grille des univers
/// (les grandes sous-catégories du catalogue, avec une couverture), et les créateurs à suivre
/// en carrousel. La rangée « En moins d'une minute » arrivera avec les vidéos (prompt 10).
struct ExploreView: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    let onOpenCourse: (Course) -> Void
    let onOpenCreator: (CourseAuthor) -> Void
    let onOpenCampaign: (Campaign) -> Void
    let onOpenUniverse: (String) -> Void

    @State private var query = ""
    @State private var selectedTrend: String?
    @FocusState private var searchFocused: Bool

    private var language: AppLanguage { languageManager.current }
    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isSearching: Bool { trimmedQuery.count >= 2 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(languageManager.text("tab.explore"))
                    .font(DS.title(.largeTitle, .heavy))
                    .foregroundStyle(DS.ink)
                    .padding(.top, 8)
                    .padding(.horizontal, 20)

                searchField
                    .padding(.horizontal, 20)

                if isSearching {
                    results
                        .padding(.horizontal, 20)
                } else {
                    trendingSection
                    universesSection
                        .padding(.horizontal, 20)
                    creatorsCarousel
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

    // MARK: - Recherche

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DS.inkTertiary)
            TextField(languageManager.text("explore.search.placeholder"), text: $query)
                .font(DS.sans(.body))
                .foregroundStyle(DS.ink)
                .focused($searchFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DS.inkTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(DS.surface))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
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
            VStack(spacing: 6) {
                Text(languageManager.text("library.empty.title"))
                    .font(DS.title(.headline, .heavy))
                    .foregroundStyle(DS.ink)
                Text(languageManager.text("library.empty.subtitle"))
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.inkSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else {
            if !courses.isEmpty {
                NewGenSectionTitle(text: languageManager.text("library.tab.courses"), trailing: "· \(courses.count)")
                ForEach(courses.prefix(12)) { course in
                    courseRow(course)
                }
            }
            if !authors.isEmpty {
                NewGenSectionTitle(text: languageManager.text("explore.results.creators"), trailing: "· \(authors.count)")
                ForEach(authors) { author in
                    creatorRow(author)
                }
            }
            if !terms.isEmpty {
                NewGenSectionTitle(text: languageManager.text("explore.results.glossary"), trailing: "· \(terms.count)")
                ForEach(terms) { hit in
                    glossaryRow(hit)
                }
            }
        }
    }

    private func courseRow(_ course: Course) -> some View {
        CompactCourseRow(
            course: course,
            meta: "\(CreatorIdentity.forCourse(course.id).name) · \(NewGenFormat.minutes(ReadingTime.minutes(for: course, language: language), language: language))",
            onTap: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onOpenCourse(course)
            }
        ) {
            if progressManager.courseStatus(for: course.id) == .completed { ReadCheck() }
        }
    }

    private func glossaryRow(_ hit: ExploreSearch.GlossaryHit) -> some View {
        Button {
            if let course = hit.course { onOpenCourse(course) }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(DS.accentTint)
                    Image(systemName: "text.book.closed")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(DS.accentSoft)
                }
                .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 3) {
                    Text(hit.entry.displayTerm)
                        .font(DS.sans(.subheadline, .bold))
                        .foregroundStyle(DS.ink)
                    Text(hit.entry.explanation)
                        .font(DS.sans(.caption))
                        .foregroundStyle(DS.inkSecondary)
                        .lineLimit(2)
                    if let course = hit.course {
                        Text(course.title.withoutInlineMarkup)
                            .font(DS.sans(.caption, .semibold))
                            .foregroundStyle(DS.accentSoft)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(DS.surface))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Un créateur dans les résultats de recherche : avatar, nom avec coche, pedigree, abonnés, Suivre.
    private func creatorRow(_ author: CourseAuthor) -> some View {
        let following = progressManager.isFollowing(author.slug)
        return HStack(spacing: 12) {
            Button { onOpenCreator(author) } label: {
                HStack(spacing: 12) {
                    AuthorAvatarView(author: author, size: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(author.name)
                                .font(DS.sans(.subheadline, .bold))
                                .foregroundStyle(DS.ink)
                                .lineLimit(1)
                            if author.isVerified { VerifiedCheck(size: 13) }
                        }
                        if let pedigree = author.title(for: language) {
                            Text(pedigree)
                                .font(DS.sans(.caption))
                                .foregroundStyle(DS.inkSecondary)
                                .lineLimit(1)
                        }
                        Text(followersLabel(author, following: following))
                            .font(DS.sans(.caption, .semibold))
                            .foregroundStyle(DS.inkSecondary)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            FollowButton(isFollowing: following, compact: true) { toggleFollow(author) }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(DS.surface))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
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

    /// Six cours au titre court, tirés une fois par semaine (graine = semaine ISO) parmi ceux
    /// que le lecteur n'a pas encore lus. Ils tiennent lieu de « tendances » jusqu'à ce que le
    /// serveur compte les vraies recherches.
    private var trendingCourses: [Course] {
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
                    .padding(.horizontal, 20)

                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(trends) { course in
                            let selected = selectedTrend == course.id
                            Button {
                                UISelectionFeedbackGenerator().selectionChanged()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                    selectedTrend = selected ? nil : course.id
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 12, weight: .bold))
                                    Text(course.title.withoutInlineMarkup)
                                        .font(DS.sans(.subheadline, .bold))
                                        .lineLimit(1)
                                }
                                .foregroundStyle(selected ? .white : DS.ink)
                                .padding(.horizontal, 14)
                                .frame(height: 38)
                                .background(Capsule().fill(selected ? DS.accent : DS.surface))
                                .overlay(Capsule().strokeBorder(selected ? DS.accent : DS.hairline, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .scrollIndicators(.hidden)

                if let selectedTrend, let course = trends.first(where: { $0.id == selectedTrend }) {
                    VStack(spacing: 8) {
                        ForEach(trendResults(for: course)) { result in
                            courseRow(result)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
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
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onOpenUniverse(universe.name)
                    } label: {
                        universeTile(universe)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func universeTile(_ universe: Universe) -> some View {
        ZStack(alignment: .bottomLeading) {
            CourseCover(course: universe.cover, cornerRadius: 0)
            VStack(alignment: .leading, spacing: 1) {
                Text(universe.name)
                    .font(DS.sans(.subheadline, .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(String(format: languageManager.text("subject.courses.count"), universe.courses.count))
                    .font(DS.sans(.caption))
                    .foregroundStyle(.white.opacity(0.88))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.043, green: 0.07, blue: 0.125).opacity(0.62))
        }
        .frame(height: 128)
        .frame(maxWidth: .infinity)
        .background(DS.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                .padding(.horizontal, 20)
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(discoverableAuthors.prefix(8)) { author in
                        creatorCard(author)
                    }
                }
                .padding(.horizontal, 20)
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
                    HStack(spacing: 4) {
                        Text(author.name)
                            .font(DS.sans(.subheadline, .heavy))
                            .foregroundStyle(DS.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        if author.isVerified { VerifiedCheck(size: 12) }
                    }
                    Text(author.title(for: language) ?? "")
                        .font(DS.sans(.caption))
                        .foregroundStyle(DS.inkSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(height: 32, alignment: .top)
                    Text(followersLabel(author, following: following))
                        .font(DS.sans(.caption, .bold))
                        .foregroundStyle(DS.inkSecondary)
                        .lineLimit(1)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            FollowButton(isFollowing: following, compact: true) { toggleFollow(author) }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
        .padding(14)
        .frame(width: 156)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(DS.surface))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
        .dsSoftShadow()
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
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    RoundIconButton(systemImage: "chevron.left", accessibilityLabel: languageManager.text("common.close")) { dismiss() }
                    Text("\(subcategory) · \(courses.count)")
                        .font(DS.title(.title2, .heavy))
                        .foregroundStyle(DS.ink)
                        .lineLimit(2)
                    Spacer()
                }
                .padding(.bottom, 8)
                ForEach(courses) { course in
                    CompactCourseRow(
                        course: course,
                        meta: "\(CreatorIdentity.forCourse(course.id).name) · \(NewGenFormat.minutes(ReadingTime.minutes(for: course, language: languageManager.current), language: languageManager.current))",
                        onTap: { onOpenCourse(course) }
                    ) {
                        if progressManager.courseStatus(for: course.id) == .completed { ReadCheck() }
                    }
                }
            }
            .padding(20)
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
