import SwiftUI

/// « Reprendre » : les cours commencés et pas finis, dans le profil. Vivait dans l'onglet
/// « Apprendre » (retiré le 9 novembre au profit des onglets Parcours et Entraînement).
struct ResumeCoursesSection: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    let onResume: (Course) -> Void

    private var inProgress: [(course: Course, index: Int, count: Int)] {
        progressManager.progress.courseProgress.compactMap { id, progress -> (Course, Int, Int)? in
            guard !progress.isCompleted, progress.lastLessonIndex > 0, let course = ContentCatalog.course(withId: id) else { return nil }
            let count = max(progress.lessonCount ?? 0, course.lessons.count, 1)
            return (course, progress.lastLessonIndex, count)
        }
        .sorted { Double($0.1) / Double($0.2) > Double($1.1) / Double($1.2) }
        .map { (course: $0.0, index: $0.1, count: $0.2) }
    }

    var body: some View {
        if !inProgress.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                NewGenSectionTitle(text: languageManager.text("common.resume"))
                    .padding(.horizontal, 20)
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(inProgress, id: \.course.id) { item in
                            ResumeCourseCard(
                                course: item.course,
                                sectionIndex: item.index,
                                sectionCount: item.count,
                                onTap: { onResume(item.course) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

struct ResumeCourseCard: View {
    @Environment(LanguageManager.self) private var languageManager
    let course: Course
    let sectionIndex: Int
    let sectionCount: Int
    let onTap: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Color.clear
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .overlay { CourseCover(course: course, cornerRadius: 14) }
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                Text(course.title.withoutInlineMarkup)
                    .font(DS.sans(.subheadline, .bold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(CreatorIdentity.forCourse(course.id).name) · \(NewGenFormat.section(min(sectionIndex + 1, sectionCount), of: sectionCount, language: languageManager.current))")
                    .font(DS.sans(.caption))
                    .foregroundStyle(DS.inkSecondary)
                    .lineLimit(1)
                CalmProgressBar(fraction: Double(sectionIndex) / Double(max(1, sectionCount)), height: 6)
                    .frame(height: 6)
            }
            .padding(12)
            .frame(width: 220, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(DS.surface))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
