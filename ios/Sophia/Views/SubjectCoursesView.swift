import SwiftUI

struct SubjectCoursesView: View {
    let subject: Subject
    let courses: [Course]
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?
    @Environment(\.dismiss) private var dismiss
    @State private var hapticTrigger: Int = 0

    private var subcategories: [String] {
        Array(Set(courses.map(\.subcategory))).sorted()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                headerView

                ForEach(subcategories, id: \.self) { subcategory in
                    let subCourses = courses.filter { $0.subcategory == subcategory }
                    VStack(alignment: .leading, spacing: 12) {
                        Text(subcategory)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.6))
                            .padding(.leading, 4)

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
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
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(SophiaTheme.background)
        .navigationTitle(subject.rawValue)
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
    }

    private var headerView: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(subject.color.opacity(0.2))
                    .frame(width: 52, height: 52)
                Image(systemName: subject.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(subject.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(courses.count) cours")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(SophiaTheme.textPrimary)
                let completed = courses.filter { progressManager.courseStatus(for: $0.id) == .completed }.count
                Text("\(completed) termine\(completed > 1 ? "s" : "")")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.5))
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
