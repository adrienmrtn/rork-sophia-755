import SwiftUI

/// Neo-brutalist palette shared by Library / SubjectCourses screens.
enum BrutalPalette {
    static let cream = Color(red: 0.984, green: 0.961, blue: 0.918)
    static let ink = Color.black
    static let pink = Color(red: 1.0, green: 0.553, blue: 0.706)

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
    let progressManager: ProgressManager
    var isPremium: Bool = true
    var onShowPaywall: ((SophiaPaywallContext) -> Void)? = nil
    @Binding var selectedCourse: Course?
    @State private var searchText: String = ""
    @FocusState private var searchFocused: Bool

    private var unlockedSubjects: Set<Subject> {
        FreemiumGate.unlockedSubjects(isPremium: isPremium)
    }

    private let previewCount = 4
    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream

    private var filteredCourses: [Course] {
        if searchText.isEmpty { return CourseData.allCourses }
        return CourseData.allCourses.filter {
            $0.title.localizedStandardContains(searchText) ||
            $0.subcategory.localizedStandardContains(searchText) ||
            $0.subject.rawValue.localizedStandardContains(searchText)
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
                            Text("Bibliothèque")
                                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                                .foregroundStyle(ink)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        searchBar
                            .padding(.horizontal, 20)

                        ForEach(Subject.allCases, id: \.self) { subject in
                            let courses = filteredCourses.filter { $0.subject == subject }
                            let unlocked = unlockedSubjects.contains(subject)
                            if !courses.isEmpty {
                                if isSearching {
                                    searchSection(subject: subject, courses: courses, unlocked: unlocked)
                                } else {
                                    previewSection(subject: subject, courses: courses, unlocked: unlocked)
                                }
                            }
                        }

                        if isSearching && filteredCourses.isEmpty {
                            emptyResults
                                .padding(.top, 60)
                        }
                    }
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Subject.self) { subject in
                let courses = CourseData.allCourses.filter { $0.subject == subject }
                SubjectCoursesView(
                    subject: subject,
                    courses: courses,
                    progressManager: progressManager,
                    isPremium: isPremium,
                    unlocked: unlockedSubjects.contains(subject),
                    onShowPaywall: { ctx in onShowPaywall?(ctx) },
                    selectedCourse: $selectedCourse
                )
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(ink)

            TextField("Rechercher un cours...", text: $searchText)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(ink)
                .tint(ink)
                .focused($searchFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

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
            Text("Aucun résultat")
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
            Text("Essaie un autre mot-clé.")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(ink.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    private func previewSection(subject: Subject, courses: [Course], unlocked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(subject: subject, unlocked: unlocked)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(Array(courses.prefix(previewCount))) { course in
                        LibraryCardView(
                            course: course,
                            status: progressManager.courseStatus(for: course.id),
                            locked: !unlocked,
                            onTap: {
                                let g = UIImpactFeedbackGenerator(style: .light)
                                g.impactOccurred()
                                if unlocked {
                                    selectedCourse = course
                                } else {
                                    onShowPaywall?(.matiereBlock(for: subject))
                                }
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

    @ViewBuilder
    private func sectionHeader(subject: Subject, unlocked: Bool) -> some View {
        if unlocked {
            NavigationLink(value: subject) {
                sectionHeaderContent(subject: subject, unlocked: true)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                let g = UIImpactFeedbackGenerator(style: .light)
                g.impactOccurred()
                onShowPaywall?(.matiereBlock(for: subject))
            } label: {
                sectionHeaderContent(subject: subject, unlocked: false)
            }
            .buttonStyle(.plain)
        }
    }

    private func sectionHeaderContent(subject: Subject, unlocked: Bool) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: unlocked ? subject.icon : "lock.fill")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(.white)
                Text(subject.shortName.uppercased())
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .tracking(0.5)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(ink, in: Capsule())

            Spacer()

            if unlocked {
                HStack(spacing: 4) {
                    Text("Voir plus")
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(ink)
                }
            } else {
                HStack(spacing: 4) {
                    Text("Débloquer")
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(ink)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(BrutalPalette.pink, in: Capsule())
                .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
            }
        }
    }

    private func searchSection(subject: Subject, courses: [Course], unlocked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: unlocked ? subject.icon : "lock.fill")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(.white)
                    Text(subject.shortName.uppercased())
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
                        locked: !unlocked,
                        onTap: {
                            let g = UIImpactFeedbackGenerator(style: .light)
                            g.impactOccurred()
                            if unlocked {
                                selectedCourse = course
                            } else {
                                onShowPaywall?(.matiereBlock(for: subject))
                            }
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
    let course: Course
    let status: CourseStatus
    var locked: Bool = false
    let onTap: () -> Void
    var progressManager: ProgressManager? = nil
    @State private var favTrigger: Int = 0

    private let ink = BrutalPalette.ink
    private let depth: CGFloat = 4

    private var pastel: Color { BrutalPalette.pastel(for: course.subject) }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .top) {
                // Solid black offset plate
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
            .overlay {
                if locked {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.55))
                        .overlay {
                            VStack(spacing: 6) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 22, weight: .heavy))
                                    .foregroundStyle(ink)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white, in: Circle())
                                    .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
                                Text("VERROUILLÉ")
                                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                                    .foregroundStyle(ink)
                                    .tracking(0.8)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.white, in: Capsule())
                                    .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
                            }
                        }
                }
            }
            .padding(.bottom, depth)
        }
        .buttonStyle(BrutalCardButtonStyle(depth: 2))
    }

    private var illustration: some View {
        Color(.secondarySystemBackground)
            .frame(height: 110)
            .overlay {
                if let uiImage = CourseImageMap.loadImage(for: course.id) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                } else {
                    ZStack {
                        pastel
                        Image(systemName: course.subject.icon)
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(ink.opacity(0.25))
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
            Text(course.subject.shortName.uppercased())
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
