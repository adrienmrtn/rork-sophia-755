import SwiftUI

/// L'onglet « Apprendre » : ce qui est commencé, puis deux portes vers les pages qui ne
/// changent pas, le Parcours (style Duolingo) et l'Entraînement.
struct LearnHubView: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager
    let onResumeCourse: (Course) -> Void
    let onOpenPath: () -> Void
    let onOpenTraining: () -> Void

    private var snapshot: LearningPathSnapshot { LearningPathEngine.snapshot(progressManager: progressManager) }
    private var dueCount: Int { progressManager.dueTrainingQuestions.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(languageManager.text("tab.learn"))
                        .font(DS.title(.largeTitle, .heavy))
                        .foregroundStyle(DS.ink)
                    Text(languageManager.text("learn.subtitle"))
                        .font(DS.sans(.body))
                        .foregroundStyle(DS.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                ResumeCoursesSection(progressManager: progressManager, onResume: onResumeCourse)

                pathCard
                    .padding(.horizontal, 20)
                trainingCard
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(DS.canvas.ignoresSafeArea())
    }

    private var pathCard: some View {
        let level = snapshot.activeLevel
        let completed = level?.completedCourseCount ?? 0
        let total = max(1, level?.courseCount ?? 1)
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onOpenPath()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text(languageManager.text("tab.path").uppercasedInApp())
                    .font(DS.sans(.caption, .bold))
                    .foregroundStyle(DS.accentSoft)
                    .tracking(0.8)
                if let level {
                    Text(String(format: languageManager.text("path.levelCaption"), level.number))
                        .font(DS.title(.title, .heavy))
                        .foregroundStyle(DS.ink)
                    Text(String(format: languageManager.text("learn.path.remaining"), max(0, level.courseCount - level.completedCourseCount)))
                        .font(DS.sans(.body))
                        .foregroundStyle(DS.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    CalmProgressBar(fraction: Double(completed) / Double(total), height: 8)
                        .frame(height: 8)
                        .padding(.top, 4)
                } else {
                    Text(languageManager.text(snapshot.isEverythingPassed ? "path.end.doneTitle" : "path.title"))
                        .font(DS.title(.title, .heavy))
                        .foregroundStyle(DS.ink)
                    Text(languageManager.text(snapshot.isEverythingPassed ? "path.end.doneBody" : "explain.path.body"))
                        .font(DS.sans(.body))
                        .foregroundStyle(DS.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(DS.surface))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
            .dsSoftShadow()
        }
        .buttonStyle(.plain)
    }

    private var trainingCard: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onOpenTraining()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text(languageManager.text("tab.training").uppercasedInApp())
                    .font(DS.sans(.caption, .bold))
                    .foregroundStyle(DS.accentSoft)
                    .tracking(0.8)
                Text(dueCount > 0 ? String(format: languageManager.text("learn.training.due"), dueCount) : languageManager.text("training.emptyTitle"))
                    .font(DS.title(.title, .heavy))
                    .foregroundStyle(DS.ink)
                Text(languageManager.text("learn.training.body"))
                    .font(DS.sans(.body))
                    .foregroundStyle(DS.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).fill(DS.surface))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous).strokeBorder(DS.hairline, lineWidth: 1))
            .dsSoftShadow()
        }
        .buttonStyle(.plain)
    }
}

/// « Reprendre » : les cours commencés, du plus avancé au moins avancé, en cartes horizontales
/// avec leur barre de progression. Partagé par l'onglet Apprendre et le profil.
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
