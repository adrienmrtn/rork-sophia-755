import SwiftUI

struct LibraryView: View {
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?
    @State private var searchText: String = ""

    private let previewCount = 4

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
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
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
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(SophiaTheme.background)
            .navigationTitle("Bibliothèque")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Rechercher un cours...")

        }
    }

    private func previewSection(subject: Subject, courses: [Course]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            NavigationLink(value: subject) {
                HStack(spacing: 8) {
                    Image(systemName: subject.icon)
                        .foregroundStyle(subject.color)
                    Text(subject.rawValue)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(SophiaTheme.textPrimary)
                    Spacer()
                    Text("Voir plus")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.5))
                    Image(systemName: "chevron.right")
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.3))
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
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
                        .frame(width: 160)
                    }
                }
            }
            .contentMargins(.horizontal, 16)
        }
        .navigationDestination(for: Subject.self) { subject in
            let courses = CourseData.allCourses.filter { $0.subject == subject }
            SubjectCoursesView(
                subject: subject,
                courses: courses,
                progressManager: progressManager,
                selectedCourse: $selectedCourse
            )
        }
    }

    private func searchSection(subject: Subject, courses: [Course]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: subject.icon)
                    .foregroundStyle(subject.color)
                Text(subject.rawValue)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(SophiaTheme.textPrimary)
                Spacer()
                Text("\(courses.count)")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.4))
            }
            .padding(.horizontal, 16)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
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
            .padding(.horizontal, 16)
        }
    }
}

struct LibraryCardView: View {
    let course: Course
    let status: CourseStatus
    let onTap: () -> Void
    var progressManager: ProgressManager? = nil
    @State private var favTrigger: Int = 0

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Color(.secondarySystemBackground)
                    .frame(height: 100)
                    .overlay {
                        if let uiImage = CourseImageMap.loadImage(for: course.id) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        } else {
                            ZStack {
                                course.subject.color.opacity(0.2)
                                LinearGradient(
                                    colors: [course.subject.color.opacity(0.4), course.subject.color.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                Image(systemName: course.subject.icon)
                                    .font(.system(size: 32, weight: .light))
                                    .foregroundStyle(Color.black.opacity(0.2))
                                    .rotationEffect(.degrees(-12))
                            }
                        }
                    }
                    .clipShape(.rect(cornerRadii: .init(topLeading: 16, topTrailing: 16)))
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
                                    .font(.callout)
                                    .foregroundStyle(pm.isFavorite(course.id) ? .pink : Color.black.opacity(0.7))
                                    .frame(width: 30, height: 30)
                                    .background(.black.opacity(0.45), in: Circle())
                            }

                            .padding(8)
                        }
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(course.subject.shortName)
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(course.subject.color)
                    Text(course.title)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(SophiaTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(SophiaTheme.cardBackground)
                .clipShape(.rect(cornerRadii: .init(bottomLeading: 16, bottomTrailing: 16)))
            }
            .opacity(status == .completed ? 0.7 : 1.0)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch status {
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(SophiaTheme.emerald)
                .background(Circle().fill(.black.opacity(0.5)).padding(-2))
        case .inProgress:
            Image(systemName: "play.circle.fill")
                .font(.title3)
                .foregroundStyle(SophiaTheme.streakOrange)
                .background(Circle().fill(.black.opacity(0.5)).padding(-2))
        case .notStarted:
            EmptyView()
        }
    }
}
