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
            DS.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    backButton
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
            .scrollIndicators(.hidden)
        }
        .navigationBarHidden(true)
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { appeared = true }
        }
    }

    // MARK: - Back button

    private var backButton: some View {
        HStack {
            Button {
                hapticTrigger += 1
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.inkSecondary)
                    .frame(width: 40, height: 40)
                    .background(DS.surface, in: Circle())
                    .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
            }
            .buttonStyle(SoftPressButtonStyle())
            Spacer()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: subject.icon)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(DS.accentSoft)
                    .frame(width: 60, height: 60)
                    .background(DS.accentTint, in: RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(subject.localizedName(language: languageManager.current))
                        .font(DS.title(.title, .semibold))
                        .foregroundStyle(DS.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(format: languageManager.text("subject.level"), currentTier.level))
                        .font(DS.sans(.caption, .semibold))
                        .foregroundStyle(DS.accentSoft)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(DS.accentTint, in: Capsule())
                    Spacer()
                }

                CalmProgressBar(fraction: progressInLevel, height: 8)

                Text(String(format: languageManager.text("subject.progress.stats"), subjectXP, completedCount, courses.count))
                    .font(DS.sans(.caption, .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .monospacedDigit()
            }
        }
        .dsCard()
    }

    // MARK: - Filter chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CourseFilter.allCases, id: \.self) { chip in
                    let isSelected = filter == chip
                    Button {
                        hapticTrigger += 1
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            filter = chip
                        }
                    } label: {
                        Text(languageManager.text(chip.labelKey))
                            .font(DS.sans(.subheadline, .semibold))
                            .foregroundStyle(isSelected ? .white : DS.ink)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(isSelected ? DS.accent : DS.surface, in: Capsule())
                            .overlay {
                                if !isSelected {
                                    Capsule().strokeBorder(DS.hairline, lineWidth: 1)
                                }
                            }
                    }
                    .buttonStyle(SoftPressButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Next up

    private func nextUpSection(course: Course) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(languageManager.text("subject.next").uppercased())
                .font(DS.sans(.caption2, .semibold))
                .foregroundStyle(DS.inkTertiary)
                .tracking(1.2)

            Button {
                hapticTrigger += 1
                selectedCourse = course
            } label: {
                HStack(spacing: 12) {
                    NextCourseThumb(course: course)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(course.subject.localizedShortName(language: languageManager.current).uppercased())
                            .font(DS.sans(.caption2, .semibold))
                            .foregroundStyle(DS.accentSoft)
                            .tracking(1.0)
                        Text(course.title)
                            .font(DS.title(.subheadline, .semibold))
                            .foregroundStyle(DS.ink)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: progressManager.courseStatus(for: course.id) == .inProgress ? "arrow.right" : "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(DS.accent, in: Circle())
                }
                .padding(12)
            }
            .buttonStyle(SoftPressButtonStyle())
            .dsCard(padding: 0)
        }
    }

    // MARK: - Subcategory section

    private func subcategorySection(_ subcategory: String) -> some View {
        let subCourses = visibleCourses.filter { $0.subcategory == subcategory }
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(subcategory)
                    .font(DS.title(.headline, .semibold))
                    .foregroundStyle(DS.ink)
                Spacer()
                Text("\(subCourses.count)")
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(DS.inkTertiary)
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
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(DS.inkTertiary)
            Text(languageManager.text("subject.filter.empty"))
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct NextCourseThumb: View {
    let course: Course
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            DS.surfaceMuted
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: course.subject.icon)
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(DS.accentSoft.opacity(0.5))
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))
        .onAppear { image = CourseImageMap.loadImage(for: course.id) }
    }
}
