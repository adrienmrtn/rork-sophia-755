import SwiftUI

struct SubjectCoursesView: View {
    let subject: Subject
    let courses: [Course]
    let progressManager: ProgressManager
    @Binding var selectedCourse: Course?
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    @State private var hapticTrigger: Int = 0

    private let ink = BrutalPalette.ink
    private let cream = BrutalPalette.cream

    private var subcategories: [String] {
        Array(Set(courses.map(\.subcategory))).sorted()
    }

    private var completedCount: Int {
        courses.filter { progressManager.courseStatus(for: $0.id) == .completed }.count
    }

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    headerView
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                    ForEach(subcategories, id: \.self) { subcategory in
                        let subCourses = courses.filter { $0.subcategory == subcategory }
                        VStack(alignment: .leading, spacing: 14) {
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
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(subject.localizedName(language: languageManager.current))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(cream, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
    }

    private var headerView: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(ink)
                .offset(y: 5)

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(BrutalPalette.pastel(for: subject))
                        .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
                        .frame(width: 56, height: 56)
                    Text(subject.emoji)
                        .font(.system(size: 28))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: languageManager.text("subject.courses.count"), courses.count))
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink)
                    Text(String(
                        format: languageManager.text(completedCount > 1 ? "subject.completed.plural" : "subject.completed.singular"),
                        completedCount
                    ))
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.55))
                }

                Spacer()
            }
            .padding(16)
            .background(Color.white)
            .clipShape(.rect(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(ink, lineWidth: 2.5)
            }
        }
        .padding(.bottom, 5)
    }
}
