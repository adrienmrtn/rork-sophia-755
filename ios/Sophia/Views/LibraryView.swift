import SwiftUI

/// Neo-brutalist palette shared by Library / SubjectCourses screens.
enum BrutalPalette {
    static let cream = Color(red: 0.984, green: 0.961, blue: 0.918)
    static let ink = Color.black
    static let pink = Color(red: 1.0, green: 0.553, blue: 0.706)
    static let yellow = Color(red: 1.0, green: 0.84, blue: 0.35)

    /// Pastel tint matching the Home FlashCard for each subject.
    static func pastel(for subject: Subject) -> Color {
        switch subject {
        case .histoire: return Color(red: 1.0, green: 0.86, blue: 0.62)
        case .sciences: return Color(red: 0.70, green: 0.95, blue: 0.80)
        case .litterature: return Color(red: 1.0, green: 0.78, blue: 0.78)
        case .art: return Color(red: 0.66, green: 0.92, blue: 0.96)
        case .mythologie: return Color(red: 0.82, green: 0.78, blue: 1.0)
        case .comprendreLeMonde: return Color(red: 0.74, green: 0.90, blue: 1.0)
        }
    }
}

struct LibraryView: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?
    @State private var searchText: String = ""
    @State private var featuredIndex: Int = 0
    @FocusState private var searchFocused: Bool

    private let previewCount = 4
    private let cream = DS.canvas

    private var filteredCourses: [Course] {
        if searchText.isEmpty { return ContentCatalog.activeCourses }
        return ContentCatalog.activeCourses.filter {
            $0.title.localizedStandardContains(searchText) ||
            $0.subcategory.localizedStandardContains(searchText) ||
            $0.subject.localizedShortName(language: languageManager.current).localizedStandardContains(searchText)
        }
    }

    private var isSearching: Bool { !searchText.isEmpty }

    /// Hand-picked editorial highlights for the top swipeable carousel.
    private var featuredCourses: [Course] {
        let lang = languageManager.current
        let curated = CuratedStarterCourses.ids.compactMap { ContentCatalog.course(withId: $0, language: lang) }
        return Array(curated.prefix(6))
    }

    /// Courses the user already started — surfaced as a "continue" row.
    private var inProgressCourses: [Course] {
        ContentCatalog.activeCourses.filter { progressManager.courseStatus(for: $0.id) == .inProgress }
    }

    /// Personalized picks based on the interests chosen during onboarding.
    private var recommendedCourses: [Course] {
        let recos = OnboardingCourseRecommender.recommendedCourses(
            interests: OnboardingViewModel.userInterestKeys(),
            language: languageManager.current,
            limit: 10
        )
        let featuredIds = Set(featuredCourses.map(\.id))
        return recos.filter { !featuredIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                cream.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        HStack {
                            Text(languageManager.text("library.title"))
                                .font(DS.title(.largeTitle, .semibold))
                                .foregroundStyle(DS.ink)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        searchBar
                            .padding(.horizontal, 20)

                        if isSearching {
                            ForEach(Subject.allCases, id: \.self) { subject in
                                let courses = filteredCourses.filter { $0.subject == subject }
                                if !courses.isEmpty {
                                    searchSection(subject: subject, courses: courses)
                                }
                            }
                            if filteredCourses.isEmpty {
                                emptyResults
                                    .padding(.top, 60)
                            }
                        } else {
                            if !featuredCourses.isEmpty {
                                featuredCarousel
                            }

                            if !inProgressCourses.isEmpty {
                                courseRow(
                                    title: languageManager.text("library.section.continue"),
                                    courses: inProgressCourses
                                )
                            }

                            if !recommendedCourses.isEmpty {
                                courseRow(
                                    title: languageManager.text("library.section.recommended"),
                                    courses: recommendedCourses
                                )
                            }

                            ForEach(Subject.allCases, id: \.self) { subject in
                                let courses = filteredCourses.filter { $0.subject == subject }
                                if !courses.isEmpty {
                                    previewSection(subject: subject, courses: courses)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Subject.self) { subject in
                let courses = ContentCatalog.activeCourses.filter { $0.subject == subject }
                SubjectCoursesView(
                    subject: subject,
                    courses: courses,
                    progressManager: progressManager,
                    selectedCourse: $selectedCourse
                )
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.jakarta(size: 16, weight: .regular))
                .foregroundStyle(DS.inkTertiary)

            ZStack(alignment: .leading) {
                if searchText.isEmpty {
                    Text(languageManager.text("library.search.placeholder"))
                        .font(DS.sans(.subheadline))
                        .foregroundStyle(DS.inkTertiary)
                        .allowsHitTesting(false)
                }
                TextField("", text: $searchText)
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.ink)
                    .tint(DS.accentSoft)
                    .focused($searchFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    let g = UIImpactFeedbackGenerator(style: .light)
                    g.impactOccurred()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.jakarta(size: 16, weight: .regular))
                        .foregroundStyle(DS.inkTertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.control))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
    }

    private var emptyResults: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.jakarta(size: 38, weight: .light))
                .foregroundStyle(DS.inkTertiary)
            Text(languageManager.text("library.empty.title"))
                .font(DS.title(.title3, .semibold))
                .foregroundStyle(DS.ink)
            Text(languageManager.text("library.empty.subtitle"))
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Featured swipeable carousel

    private var featuredCarousel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(languageManager.text("library.section.featured"))
                    .font(DS.title(.title3, .semibold))
                    .foregroundStyle(DS.ink)
                Spacer()
            }
            .padding(.horizontal, 20)

            TabView(selection: $featuredIndex) {
                ForEach(Array(featuredCourses.enumerated()), id: \.element.id) { index, course in
                    LibraryFeaturedCard(
                        course: course,
                        status: progressManager.courseStatus(for: course.id),
                        onTap: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedCourse = course
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 350)
            .onAppear {
                CourseImageMap.preloadImages(for: featuredCourses.map(\.id))
            }

            HStack(spacing: 6) {
                ForEach(featuredCourses.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == featuredIndex ? DS.accentSoft : DS.hairline)
                        .frame(width: i == featuredIndex ? 22 : 7, height: 7)
                        .animation(.spring(response: 0.3), value: featuredIndex)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Generic horizontal course row (continue / recommended)

    private func courseRow(title: String, courses: [Course]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(DS.title(.title3, .semibold))
                    .foregroundStyle(DS.ink)
                Spacer()
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(courses) { course in
                        LibraryCardView(
                            course: course,
                            status: progressManager.courseStatus(for: course.id),
                            onTap: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedCourse = course
                            },
                            progressManager: progressManager
                        )
                        .frame(width: 180)
                    }
                }
            }
            .contentMargins(.horizontal, 20)
        }
    }

    private func previewSection(subject: Subject, courses: [Course]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(subject: subject)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(Array(courses.prefix(previewCount))) { course in
                        LibraryCardView(
                            course: course,
                            status: progressManager.courseStatus(for: course.id),
                            onTap: {
                                let g = UIImpactFeedbackGenerator(style: .light)
                                g.impactOccurred()
                                selectedCourse = course
                            },
                            progressManager: progressManager
                        )
                        .frame(width: 180)
                    }
                }
            }
            .contentMargins(.horizontal, 20)
        }
    }

    private func sectionHeader(subject: Subject) -> some View {
        NavigationLink(value: subject) {
            sectionHeaderContent(subject: subject)
        }
        .buttonStyle(.plain)
    }

    private func sectionHeaderContent(subject: Subject) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: subject.icon)
                    .font(.jakarta(size: 14, weight: .medium))
                    .foregroundStyle(DS.accentSoft)
                Text(subject.localizedShortName(language: languageManager.current))
                    .font(DS.title(.headline, .semibold))
                    .foregroundStyle(DS.ink)
            }

            Spacer()

            HStack(spacing: 4) {
                Text(languageManager.text("library.seeMore"))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(DS.accentSoft)
                Image(systemName: "chevron.right")
                    .font(.jakarta(size: 12, weight: .semibold))
                    .foregroundStyle(DS.accentSoft)
            }
        }
    }

    private func searchSection(subject: Subject, courses: [Course]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: subject.icon)
                        .font(.jakarta(size: 14, weight: .medium))
                        .foregroundStyle(DS.accentSoft)
                    Text(subject.localizedShortName(language: languageManager.current))
                        .font(DS.title(.headline, .semibold))
                        .foregroundStyle(DS.ink)
                }

                Spacer()

                Text("\(courses.count)")
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(DS.inkTertiary)
            }
            .padding(.horizontal, 20)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 18) {
                ForEach(courses) { course in
                    LibraryCardView(
                        course: course,
                        status: progressManager.courseStatus(for: course.id),
                        onTap: {
                            let g = UIImpactFeedbackGenerator(style: .light)
                            g.impactOccurred()
                            selectedCourse = course
                        },
                        progressManager: progressManager
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

/// Button style that gives the press-down 3D feel without intercepting scroll gestures.
struct BrutalCardButtonStyle: ButtonStyle {
    var depth: CGFloat = 2

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? depth : 0)
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Large editorial "featured" card used in the swipeable Library carousel.
struct LibraryFeaturedCard: View {
    @Environment(LanguageManager.self) private var languageManager
    let course: Course
    let status: CourseStatus
    let onTap: () -> Void

    @State private var image: UIImage?

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                cover
                infoPanel
            }
            .background(DS.surface)
            .clipShape(.rect(cornerRadius: DS.Radius.card))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                    .strokeBorder(DS.hairline, lineWidth: 1)
            }
            .dsSoftShadow()
        }
        .buttonStyle(BrutalCardButtonStyle(depth: 2))
        .onAppear {
            if image == nil { image = CourseImageMap.loadImage(for: course.id) }
        }
    }

    private var cover: some View {
        DS.surfaceMuted
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .allowsHitTesting(false)
                } else {
                    Image(systemName: course.subject.icon)
                        .font(.jakarta(size: 40, weight: .light))
                        .foregroundStyle(DS.accentSoft.opacity(0.5))
                }
            }
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .clipped()
    }

    private var infoPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.subject.localizedShortName(language: languageManager.current).uppercased())
                .font(DS.sans(.caption2, .semibold))
                .foregroundStyle(DS.accentSoft)
                .tracking(1.2)

            Text(course.title)
                .font(DS.title(.title3, .semibold))
                .foregroundStyle(DS.ink)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)

            Text(course.description)
                .font(DS.sans(.caption))
                .foregroundStyle(DS.inkSecondary)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)

            HStack(spacing: 8) {
                metaChip(icon: "rectangle.stack", text: String(format: languageManager.text("onboarding.showcase.courses.lessons"), course.lessons.count))
                metaChip(icon: "book.pages", text: String(format: languageManager.text("course.reads"), course.readsCountShort))

                Spacer(minLength: 0)

                Image(systemName: status == .completed ? "checkmark" : "arrow.right")
                    .font(.jakarta(size: 14, weight: .semibold))
                    .foregroundStyle(status == .completed ? DS.accentSoft : Color.white)
                    .frame(width: 34, height: 34)
                    .background(status == .completed ? DS.accentTint : DS.accent, in: Circle())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metaChip(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.jakarta(size: 10, weight: .medium))
            Text(text).font(DS.sans(.caption2, .medium))
        }
        .foregroundStyle(DS.inkSecondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(DS.accentTint, in: Capsule())
    }
}

/// Calm library card — white surface, hairline border, soft diffuse shadow.
struct LibraryCardView: View {
    @Environment(LanguageManager.self) private var languageManager
    let course: Course
    let status: CourseStatus
    let onTap: () -> Void
    var progressManager: ProgressManager? = nil
    @State private var favTrigger: Int = 0

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                illustration
                bottomPanel
            }
            .background(DS.surface)
            .clipShape(.rect(cornerRadius: DS.Radius.control))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .strokeBorder(DS.hairline, lineWidth: 1)
            }
            .dsSoftShadow()
            .opacity(status == .completed ? 0.82 : 1.0)
        }
        .buttonStyle(BrutalCardButtonStyle(depth: 2))
    }

    private var illustration: some View {
        DS.surfaceMuted
            .frame(height: 110)
            .overlay {
                if let uiImage = CourseImageMap.loadImage(for: course.id) {
                    Color.clear
                        .overlay {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        }
                        .clipped()
                        .allowsHitTesting(false)
                } else {
                    Image(systemName: course.subject.icon)
                        .font(.jakarta(size: 30, weight: .light))
                        .foregroundStyle(DS.accentSoft.opacity(0.5))
                }
            }
            .overlay(alignment: .topLeading) {
                statusBadge
                    .padding(8)
            }
            .overlay(alignment: .topTrailing) {
                if let pm = progressManager {
                    Button {
                        let g = UIImpactFeedbackGenerator(style: .light)
                        g.impactOccurred()
                        favTrigger += 1
                        pm.toggleFavorite(course.id)
                    } label: {
                        Image(systemName: pm.isFavorite(course.id) ? "bookmark.fill" : "bookmark")
                            .font(.jakarta(size: 13, weight: .medium))
                            .foregroundStyle(pm.isFavorite(course.id) ? DS.accent : DS.inkSecondary)
                            .frame(width: 30, height: 30)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.impact(weight: .light), trigger: favTrigger)
                    .padding(8)
                }
            }
    }

    private var bottomPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(course.subject.localizedShortName(language: languageManager.current).uppercased())
                .font(DS.sans(.caption2, .semibold))
                .foregroundStyle(DS.accentSoft)
                .tracking(1.0)

            Text(course.title)
                .font(DS.title(.subheadline, .semibold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.leading)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(DS.surface)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch status {
        case .completed:
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.jakarta(size: 9, weight: .semibold))
                Text(languageManager.text("library.status.done"))
                    .font(DS.sans(.caption2, .semibold))
                    .tracking(0.3)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(DS.accent, in: Capsule())
        case .inProgress:
            HStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.jakarta(size: 8, weight: .semibold))
                Text(languageManager.text("library.status.inProgress"))
                    .font(DS.sans(.caption2, .semibold))
                    .tracking(0.3)
            }
            .foregroundStyle(DS.accentSoft)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay { Capsule().strokeBorder(DS.hairline, lineWidth: 1) }
        case .notStarted:
            EmptyView()
        }
    }
}
