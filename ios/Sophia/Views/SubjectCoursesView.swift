import SwiftUI

struct SubjectCoursesView: View {
    let subject: Subject
    let courses: [Course]
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    @State private var hapticTrigger: Int = 0
    @State private var filter: CourseFilter = .all
    @State private var appeared = false

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream

    private enum CourseFilter: CaseIterable, Hashable {
        case all, todo, inProgress, done, favorites

        var labelKey: String {
            switch self {
            case .all: "library.filter.all"
            case .todo: "library.filter.todo"
            case .inProgress: "library.filter.inProgress"
            case .done: "library.filter.done"
            case .favorites: "library.filter.favorites"
            }
        }
    }

    // MARK: - Derived data

    private var completedCount: Int {
        courses.filter { progressManager.courseStatus(for: $0.id) == .completed }.count
    }

    private var subjectXP: Int { progressManager.xp(for: subject) }

    private var currentTier: (level: Int, lower: Int, upper: Int) {
        ProgressManager.subjectXPTiers.last(where: { subjectXP >= $0.lower }) ?? ProgressManager.subjectXPTiers[0]
    }

    private var progressInLevel: Double {
        let tier = currentTier
        if tier.level == ProgressManager.subjectXPTiers.count { return 1.0 }
        let span = max(1, tier.upper - tier.lower)
        return min(1.0, Double(max(0, subjectXP - tier.lower)) / Double(span))
    }

    private func matchesFilter(_ course: Course) -> Bool {
        switch filter {
        case .all: return true
        case .todo: return progressManager.courseStatus(for: course.id) == .notStarted
        case .inProgress: return progressManager.courseStatus(for: course.id) == .inProgress
        case .done: return progressManager.courseStatus(for: course.id) == .completed
        case .favorites: return progressManager.isFavorite(course.id)
        }
    }

    private var visibleCourses: [Course] { courses.filter(matchesFilter) }

    private var subcategories: [String] {
        Array(Set(visibleCourses.map(\.subcategory))).sorted()
    }

    /// Next course to tackle: first in-progress, otherwise first not-started.
    private var nextCourse: Course? {
        courses.first { progressManager.courseStatus(for: $0.id) == .inProgress }
            ?? courses.first { progressManager.courseStatus(for: $0.id) == .notStarted }
    }

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    topBar
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    header
                        .padding(.horizontal, 20)

                    filterChips

                    if filter == .all, let next = nextCourse {
                        nextUpSection(course: next)
                            .padding(.horizontal, 20)
                    }

                    if visibleCourses.isEmpty {
                        emptyState
                            .padding(.top, 40)
                    } else {
                        ForEach(subcategories, id: \.self) { subcategory in
                            subcategorySection(subcategory)
                        }
                    }
                }
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
            }
        }
        .navigationBarHidden(true)
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { appeared = true }
        }
    }

    // MARK: - Top bar (back button on its own row)

    private var topBar: some View {
        HStack {
            backButton
            Spacer()
        }
    }

    // MARK: - Immersive header

    private var header: some View {
        ZStack(alignment: .topLeading) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(ink)
                    .offset(y: 6)

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
                            Text(subject.emoji)
                                .font(.system(size: 34))
                        }
                        .frame(width: 64, height: 64)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(subject.localizedName(language: languageManager.current))
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(ink)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(format: languageManager.text("subject.level"), currentTier.level))
                            .font(.system(.caption, design: .rounded, weight: .black))
                            .foregroundStyle(.white)
                            .tracking(0.8)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(ink, in: Capsule())

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.white)
                                    .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                                Capsule()
                                    .fill(LinearGradient(colors: [BrutalPalette.pink, BrutalPalette.yellow], startPoint: .leading, endPoint: .trailing))
                                    .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                                    .frame(width: max(16, geo.size.width * progressInLevel))
                                    .animation(.spring(response: 0.6, dampingFraction: 0.82), value: progressInLevel)
                            }
                        }
                        .frame(height: 18)

                        Text(String(format: languageManager.text("subject.progress.stats"), subjectXP, completedCount, courses.count))
                            .font(.system(.caption, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink.opacity(0.6))
                            .monospacedDigit()
                    }
                }
                .padding(18)
                .padding(.top, 8)
                .background(BrutalPalette.pastel(for: subject))
                .clipShape(.rect(cornerRadius: 24))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(ink, lineWidth: 3)
                }
            }
            .padding(.bottom, 6)
        }
    }

    private var backButton: some View {
        Button {
            hapticTrigger += 1
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(ink)
                .frame(width: 40, height: 40)
                .background(Color.white, in: Circle())
                .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
        }
        .buttonStyle(BrutalIconButtonStyle())
    }

    // MARK: - Filter chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CourseFilter.allCases, id: \.self) { chip in
                    let isSelected = filter == chip
                    Button {
                        hapticTrigger += 1
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            filter = chip
                        }
                    } label: {
                        Text(languageManager.text(chip.labelKey))
                            .font(.system(.subheadline, design: .rounded, weight: .black))
                            .foregroundStyle(isSelected ? .white : ink)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(isSelected ? ink : Color.white, in: Capsule())
                            .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
                    }
                    .buttonStyle(BrutalIconButtonStyle(depth: 1))
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Next up

    private func nextUpSection(course: Course) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(languageManager.text("subject.next"))
                .font(.system(.caption, design: .rounded, weight: .black))
                .foregroundStyle(ink.opacity(0.55))
                .tracking(1.2)

            Button {
                hapticTrigger += 1
                selectedCourse = course
            } label: {
                HStack(spacing: 12) {
                    NextCourseThumb(course: course)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(course.subject.localizedShortName(language: languageManager.current).uppercased())
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(ink.opacity(0.5))
                            .tracking(0.5)
                        Text(course.title)
                            .font(.system(.subheadline, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: progressManager.courseStatus(for: course.id) == .inProgress ? "arrow.right" : "play.fill")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(ink)
                        .frame(width: 40, height: 40)
                        .background(BrutalPalette.pink, in: Circle())
                        .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
                }
                .padding(12)
                .background(Color.white)
            }
            .buttonStyle(BrutalCardButtonStyle(depth: 4))
            .brutalCard()
        }
    }

    // MARK: - Subcategory section

    private func subcategorySection(_ subcategory: String) -> some View {
        let subCourses = visibleCourses.filter { $0.subcategory == subcategory }
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(ink)
                    .frame(width: 4, height: 18)
                Text(subcategory)
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                Spacer()
                Text("\(subCourses.count)")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.45))
            }
            .padding(.horizontal, 20)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 18) {
                ForEach(subCourses) { course in
                    LibraryCardView(
                        course: course,
                        status: progressManager.courseStatus(for: course.id),
                        onTap: {
                            hapticTrigger += 1
                            selectedCourse = course
                        },
                        progressManager: progressManager
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(ink.opacity(0.3))
            Text(languageManager.text("subject.filter.empty"))
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(ink.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct NextCourseThumb: View {
    let course: Course
    @State private var image: UIImage?

    private let ink = BrutalPalette.ink

    var body: some View {
        ZStack {
            BrutalPalette.pastel(for: course.subject)
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Text(course.subject.emoji).font(.system(size: 24))
            }
        }
        .frame(width: 58, height: 58)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(ink, lineWidth: 2.5)
        }
        .onAppear { image = CourseImageMap.loadImage(for: course.id) }
    }
}
