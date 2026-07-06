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
    private enum LibraryTab: CaseIterable, Hashable {
        case courses
        case collections

        func label(language: AppLanguage) -> String {
            switch self {
            case .courses:
                AppLocalizable.string("library.tab.courses", language: language)
            case .collections:
                AppLocalizable.string("library.tab.collections", language: language)
            }
        }
    }

    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?
    @State private var searchText: String = ""
    @State private var selectedTab: LibraryTab = .courses
    @FocusState private var searchFocused: Bool

    private let previewCount = 4
    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream

    private var filteredCourses: [Course] {
        if searchText.isEmpty { return ContentCatalog.activeCourses }
        return ContentCatalog.activeCourses.filter {
            $0.title.localizedStandardContains(searchText) ||
            $0.subcategory.localizedStandardContains(searchText) ||
            $0.subject.localizedShortName(language: languageManager.current).localizedStandardContains(searchText)
        }
    }

    private var isSearching: Bool { !searchText.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                cream.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        HStack {
                            Text(languageManager.text("library.title"))
                                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                                .foregroundStyle(ink)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        tabSwitcher
                            .padding(.horizontal, 20)

                        if selectedTab == .courses {
                            searchBar
                                .padding(.horizontal, 20)

                            ForEach(Subject.allCases, id: \.self) { subject in
                                let courses = filteredCourses.filter { $0.subject == subject }
                                if !courses.isEmpty {
                                    if isSearching {
                                        searchSection(subject: subject, courses: courses)
                                    } else {
                                        previewSection(subject: subject, courses: courses)
                                    }
                                }
                            }

                            if isSearching && filteredCourses.isEmpty {
                                emptyResults
                                    .padding(.top, 60)
                            }
                        } else {
                            CollectionsOverviewView(
                                progressManager: progressManager,
                                selectedCourse: $selectedCourse
                            )
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
            .navigationDestination(for: LearningCollection.self) { collection in
                CollectionDetailView(
                    collection: collection,
                    progressManager: progressManager,
                    selectedCourse: $selectedCourse
                )
            }
        }
    }

    private var tabSwitcher: some View {
        HStack(spacing: 8) {
            ForEach(LibraryTab.allCases, id: \.self) { tab in
                Button {
                    let g = UIImpactFeedbackGenerator(style: .light)
                    g.impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        selectedTab = tab
                        if tab == .collections {
                            searchText = ""
                            searchFocused = false
                        }
                    }
                } label: {
                    Text(tab.label(language: languageManager.current))
                        .font(.system(.subheadline, design: .rounded, weight: .black))
                        .foregroundStyle(selectedTab == tab ? .white : ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTab == tab ? ink : Color.white, in: Capsule())
                        .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                }
                .buttonStyle(BrutalIconButtonStyle(depth: 1))
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(ink)

            ZStack(alignment: .leading) {
                if searchText.isEmpty {
                    Text(languageManager.text("library.search.placeholder"))
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.38))
                        .allowsHitTesting(false)
                }
                TextField("", text: $searchText)
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                    .tint(ink)
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
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(ink.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(ink, lineWidth: 2.5)
        }
    }

    private var emptyResults: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(ink.opacity(0.3))
            Text(languageManager.text("library.empty.title"))
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
            Text(languageManager.text("library.empty.subtitle"))
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(ink.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
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
                Text(subject.emoji)
                    .font(.system(size: 16))
                Text(subject.localizedShortName(language: languageManager.current).uppercased())
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .tracking(0.5)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(ink, in: Capsule())

            Spacer()

            HStack(spacing: 4) {
                Text(languageManager.text("library.seeMore"))
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(ink)
            }
        }
    }

    private func searchSection(subject: Subject, courses: [Course]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Text(subject.emoji)
                        .font(.system(size: 16))
                    Text(subject.localizedShortName(language: languageManager.current).uppercased())
                        .font(.system(.caption, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white)
                        .tracking(0.5)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(ink, in: Capsule())

                Spacer()

                Text("\(courses.count)")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.5))
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

/// Neo-brutalist library card — white body, black border, solid black offset shadow,
/// pastel bottom panel matching the Home FlashCard style.
struct LibraryCardView: View {
    @Environment(LanguageManager.self) private var languageManager
    let course: Course
    let status: CourseStatus
    let onTap: () -> Void
    var progressManager: ProgressManager? = nil
    @State private var favTrigger: Int = 0

    private let ink = BrutalPalette.ink
    private let depth: CGFloat = 4

    private var pastel: Color { BrutalPalette.pastel(for: course.subject) }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ink)
                    .offset(y: depth)

                VStack(spacing: 0) {
                    illustration
                    bottomPanel
                }
                .background(Color.white)
                .clipShape(.rect(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(ink, lineWidth: 2.5)
                }
            }
            .opacity(status == .completed ? 0.78 : 1.0)
            .padding(.bottom, depth)
        }
        .buttonStyle(BrutalCardButtonStyle(depth: 2))
    }

    private var illustration: some View {
        Color(.secondarySystemBackground)
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
                    ZStack {
                        pastel
                        Text(course.subject.emoji)
                            .font(.system(size: 36))
                    }
                }
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(ink)
                    .frame(height: 2.5)
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
                        Image(systemName: pm.isFavorite(course.id) ? "heart.fill" : "heart")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(pm.isFavorite(course.id) ? BrutalPalette.pink : ink)
                            .frame(width: 30, height: 30)
                            .background(Color.white, in: Circle())
                            .overlay { Circle().strokeBorder(ink, lineWidth: 2) }
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
                .font(.system(.caption2, design: .rounded, weight: .heavy))
                .foregroundStyle(ink.opacity(0.55))
                .tracking(0.5)

            Text(course.title)
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
                .multilineTextAlignment(.leading)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(pastel)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch status {
        case .completed:
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .heavy))
                Text("FAIT")
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .tracking(0.5)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(ink, in: Capsule())
        case .inProgress:
            HStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.system(size: 9, weight: .heavy))
                Text("EN COURS")
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .tracking(0.5)
            }
            .foregroundStyle(ink)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.white, in: Capsule())
            .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
        case .notStarted:
            EmptyView()
        }
    }
}
