import SwiftUI

/// L'onglet Explorer : recherche (cours, créateurs, termes du glossaire), l'événement en
/// cours, les créateurs à découvrir, les cours les plus aimés et les matières. La rangée
/// vidéos n'apparaît que lorsqu'il y aura des vidéos (prompt 10).
struct ExploreView: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    let onOpenCourse: (Course) -> Void
    let onOpenCreator: (CourseAuthor) -> Void
    let onOpenCampaign: (Campaign) -> Void
    let onOpenSubject: (Subject) -> Void

    @State private var query = ""
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

                searchField

                if isSearching {
                    results
                } else {
                    if let campaign = CampaignStore.active().first {
                        campaignBanner(campaign)
                    }
                    creatorsSection
                    topLikedSection
                    subjectsSection
                }
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
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
                    CompactCourseRow(
                        course: course,
                        meta: "\(CreatorIdentity.forCourse(course.id).name) · \(course.subject.localizedShortName(language: language))",
                        onTap: { onOpenCourse(course) }
                    )
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

    // MARK: - Découverte

    private func campaignBanner(_ campaign: Campaign) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onOpenCampaign(campaign)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: campaign.symbol ?? "sparkles")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(DS.warm)
                VStack(alignment: .leading, spacing: 3) {
                    Text(campaign.title(for: language))
                        .font(DS.title(.headline, .heavy))
                        .foregroundStyle(.white)
                    Text(bannerSubtitle(campaign))
                        .font(DS.sans(.footnote))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.forward")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(DS.accent))
        }
        .buttonStyle(.plain)
    }

    private func bannerSubtitle(_ campaign: Campaign) -> String {
        var text = String(format: languageManager.text("event.card.summary"), campaign.courseIds.count, campaign.upcoming.count)
        if let end = campaign.endDate {
            text += " · " + String(format: languageManager.text("event.card.until"), NewGenFormat.shortDay(end, language: language)).lowercased()
        }
        return text
    }

    private var discoverableAuthors: [CourseAuthor] {
        AuthorStore.all.sorted { LocalCounters.followers(creatorSlug: $0.slug) > LocalCounters.followers(creatorSlug: $1.slug) }
    }

    private var creatorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            NewGenSectionTitle(text: languageManager.text("explore.creators"))
            ForEach(discoverableAuthors.prefix(7)) { author in
                creatorRow(author)
            }
        }
    }

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
                        Text("\((LocalCounters.followers(creatorSlug: author.slug) + (following ? 1 : 0)).compactCount) \(languageManager.text("creator.stat.followers"))")
                            .font(DS.sans(.caption, .semibold))
                            .foregroundStyle(DS.inkSecondary)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            FollowButton(isFollowing: following, compact: true) {
                progressManager.toggleFollow(author.slug)
                AnalyticsService.shared.log(following ? .unfollow : .follow, screen: "explore", props: ["creator": .string(author.slug)])
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(DS.surface))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
    }

    private var topLiked: [Course] {
        Array(ContentCatalog.activeCourses
            .sorted { $0.likesCount(liked: false) > $1.likesCount(liked: false) }
            .prefix(3))
    }

    private var topLikedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            NewGenSectionTitle(text: languageManager.text("explore.topLiked"))
            ForEach(Array(topLiked.enumerated()), id: \.element.id) { index, course in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onOpenCourse(course)
                } label: {
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(DS.title(.title2, .heavy))
                            .foregroundStyle(DS.ink)
                            .frame(width: 22)
                        CourseCover(course: course, cornerRadius: 14)
                            .frame(width: 64, height: 64)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(course.title.withoutInlineMarkup)
                                .font(DS.sans(.subheadline, .bold))
                                .foregroundStyle(DS.ink)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Text("\(CreatorIdentity.forCourse(course.id).name) · \(course.likesCount(liked: progressManager.isLiked(course.id)).compactCount) \(languageManager.text("common.likes"))")
                                .font(DS.sans(.caption))
                                .foregroundStyle(DS.inkSecondary)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(DS.surface))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var subjectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            NewGenSectionTitle(text: languageManager.text("explore.subjects"))
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Subject.allCases, id: \.self) { subject in
                    let count = ContentCatalog.activeCourses.filter { $0.subject == subject }.count
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onOpenSubject(subject)
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            Circle().fill(subject.color).frame(width: 12, height: 12)
                            Text(subject.localizedShortName(language: language))
                                .font(DS.title(.headline, .heavy))
                                .foregroundStyle(DS.ink)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Text(String(format: languageManager.text("subject.courses.count"), count))
                                .font(DS.sans(.footnote))
                                .foregroundStyle(DS.inkSecondary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(DS.surface))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// Recherche dans le glossaire : les termes français de `GlossaryData`, ou la table
/// localisée de la langue courante, avec le cours d'origine quand il est retrouvé.
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
        if language == .french {
            let coursesByTitle = Dictionary(ContentCatalog.courses(for: .french).map { ($0.title, $0) }, uniquingKeysWith: { first, _ in first })
            for (key, entry) in GlossaryData.entries where normalize(entry.displayTerm).contains(needle) {
                let courseTitle = String(key.split(separator: "|", maxSplits: 1).first ?? "")
                let dedupe = normalize(entry.displayTerm) + "|" + courseTitle
                guard !seen.contains(dedupe) else { continue }
                seen.insert(dedupe)
                hits.append(GlossaryHit(entry: entry, course: coursesByTitle[courseTitle]))
                if hits.count >= limit { break }
            }
        } else {
            for (key, entry) in LocalizedContentLoader.glossaryEntries(for: language) where normalize(entry.displayTerm).contains(needle) {
                let courseId = String(key.split(separator: "|", maxSplits: 1).first ?? "")
                let dedupe = normalize(entry.displayTerm) + "|" + courseId
                guard !seen.contains(dedupe) else { continue }
                seen.insert(dedupe)
                hits.append(GlossaryHit(entry: entry, course: ContentCatalog.course(withId: courseId)))
                if hits.count >= limit { break }
            }
        }
        return hits.sorted { $0.entry.displayTerm < $1.entry.displayTerm }
    }
}
