import SwiftUI

/// Everything the reader has opened, in two tabs.
///
/// There was nowhere to find a course again: the home feed only moves forwards and hides
/// what is finished, and the library is the whole catalogue rather than your own history.
/// Reached from the button beside the streak badge on home.
struct MyCoursesView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    let progressManager: ProgressManager
    /// Opens a course. The caller dismisses this screen and presents the reader.
    let onOpenCourse: (Course) -> Void
    /// Sends the reader back to the feed from the empty state.
    let onDiscover: () -> Void

    @State private var showCompleted = false

    private struct Row: Identifiable {
        let course: Course
        let progress: CourseProgress
        var id: String { course.id }
    }

    /// Most advanced first while reading, most recently finished first once done — the order
    /// each list is actually looked at in.
    private var inProgress: [Row] {
        rows(where: { !$0.isCompleted && $0.lastLessonIndex > 0 })
            .sorted {
                if $0.progress.fraction != $1.progress.fraction {
                    return $0.progress.fraction > $1.progress.fraction
                }
                return ($0.progress.startedAt ?? "") > ($1.progress.startedAt ?? "")
            }
    }

    private var completed: [Row] {
        // Progress saved before completion dates existed sorts last rather than first, which
        // is the honest place for a date nobody recorded.
        rows(where: \.isCompleted)
            .sorted { ($0.progress.completedAt ?? "") > ($1.progress.completedAt ?? "") }
    }

    private func rows(where predicate: (CourseProgress) -> Bool) -> [Row] {
        let catalog = ContentCatalog.courses(for: languageManager.current)
        let byId = Dictionary(uniqueKeysWithValues: catalog.map { ($0.id, $0) })
        return progressManager.progress.courseProgress.compactMap { id, entry in
            guard predicate(entry), let course = byId[id] else { return nil }
            return Row(course: course, progress: entry)
        }
    }

    private var visibleRows: [Row] { showCompleted ? completed : inProgress }

    var body: some View {
        VStack(spacing: 0) {
            header
            tabs

            if visibleRows.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(visibleRows) { row in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                onOpenCourse(row.course)
                            } label: {
                                MyCourseRow(
                                    course: row.course,
                                    progress: row.progress,
                                    showCompleted: showCompleted
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: OV2.readableWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.canvas.ignoresSafeArea())
        .sophiaColorScheme()
    }

    private var header: some View {
        HStack {
            Text(languageManager.text("myCourses.title"))
                .font(DS.title(.title, .semibold))
                .foregroundStyle(DS.ink)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.jakarta(size: 15, weight: .semibold))
                    .foregroundStyle(DS.inkSecondary)
                    .frame(width: 44, height: 44)
                    .background(DS.surface, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(languageManager.text("common.close")))
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var tabs: some View {
        HStack(spacing: 8) {
            tabButton(
                title: languageManager.text("myCourses.tab.inProgress"),
                count: inProgress.count,
                selected: !showCompleted
            ) { showCompleted = false }
            tabButton(
                title: languageManager.text("myCourses.tab.completed"),
                count: completed.count,
                selected: showCompleted
            ) { showCompleted = true }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func tabButton(
        title: String,
        count: Int,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(count > 0 ? "\(title) · \(count)" : title)
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(selected ? .white : DS.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(selected ? DS.accent : DS.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                Circle().fill(DS.accentTint).frame(width: 96, height: 96)
                Image(systemName: "book")
                    .font(.jakarta(size: 36, weight: .light))
                    .foregroundStyle(DS.accent)
            }
            Spacer().frame(height: 20)
            Text(languageManager.text("myCourses.empty.title"))
                .font(DS.title(.headline, .semibold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer().frame(height: 24)
            Button {
                dismiss()
                onDiscover()
            } label: {
                Text(languageManager.text("myCourses.empty.cta"))
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .padding(.horizontal, 32)
            Spacer()
        }
    }
}

private struct MyCourseRow: View {
    @Environment(LanguageManager.self) private var languageManager

    let course: Course
    let progress: CourseProgress
    let showCompleted: Bool

    var body: some View {
        HStack(spacing: 12) {
            cover
            VStack(alignment: .leading, spacing: 4) {
                Text(course.subject.localizedShortName(language: languageManager.current)
                    .uppercased(with: languageManager.current.foundationLocale))
                    .font(DS.sans(.caption2, .semibold))
                    .foregroundStyle(DS.accentSoft)
                    .tracking(0.6)
                    .lineLimit(1)
                Text(course.title)
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                detail
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(DS.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
    }

    @ViewBuilder
    private var detail: some View {
        if showCompleted {
            if progress.bestQuizScore > 0, let total = progress.quizTotalPoints, total > 0 {
                Text(String(
                    format: languageManager.text("myCourses.quizScore"),
                    progress.bestQuizScore,
                    total
                ))
                .font(DS.sans(.caption, .medium))
                .foregroundStyle(DS.inkSecondary)
            }
        } else if let count = progress.lessonCount, count > 0 {
            Text(String(
                format: languageManager.text("myCourses.progress"),
                min(progress.lastLessonIndex + 1, count),
                count
            ))
            .font(DS.sans(.caption, .medium))
            .foregroundStyle(DS.inkSecondary)
            ProgressView(value: Double(progress.fraction))
                .tint(DS.accent)
                .frame(height: 4)
        }
    }

    private var cover: some View {
        Group {
            if let image = CourseImageMap.loadImage(for: course.id) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                LinearGradient(
                    colors: [course.subject.color, course.subject.color.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(.rect(cornerRadius: DS.Radius.small))
    }
}

extension CourseProgress {
    /// How far through a course the reader got, 0…1. An unrecorded page count reads as
    /// "just started" rather than as complete.
    var fraction: Double {
        guard let lessonCount, lessonCount > 0 else { return 0 }
        return Double(lastLessonIndex + 1) / Double(lessonCount)
    }
}
