import SwiftUI

/// The professor's page: portrait, pedigree, biography, and every course they wrote.
///
/// Presented as a sheet over the reader. Tapping one of the courses hands the choice back
/// to `CourseView`, which closes the reader and reopens on that course through the same door
/// as a deep link, so the freemium rules and analytics attribution stay in one place.
struct AuthorView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    let author: CourseAuthor
    /// The course the reader came from, marked in the list instead of being re-openable.
    let currentCourseId: String?
    let progressManager: ProgressManager
    let onOpenCourse: (Course) -> Void

    @State private var appeared = false

    private var courses: [Course] {
        let wanted = Set(author.courseIds)
        return ContentCatalog.activeCourses.filter { wanted.contains($0.id) }
    }

    private var countLabel: String {
        let count = courses.count
        if count == 1 { return languageManager.text("author.courses.one") }
        return String(format: languageManager.text("author.courses.many"), count)
    }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    topBar

                    header

                    if let bio = author.bio(for: languageManager.current) {
                        Text(bio)
                            .font(DS.sans(.body))
                            .foregroundStyle(DS.inkSecondary)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    coursesSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .presentationBackground(DS.canvas)
        .sophiaColorScheme()
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { appeared = true }
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.jakarta(size: 15, weight: .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .frame(width: 40, height: 40)
                    .background(DS.surface, in: Circle())
                    .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
            }
            .buttonStyle(SoftPressButtonStyle())
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            AuthorAvatarView(author: author, size: 96)

            VStack(alignment: .leading, spacing: 6) {
                Text(author.name)
                    .font(DS.title(.title, .semibold))
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let title = author.title(for: languageManager.current) {
                    Text(title)
                        .font(DS.sans(.subheadline, .medium))
                        .foregroundStyle(DS.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let institution = author.institution, !institution.isEmpty {
                    Text(institution)
                        .font(DS.sans(.caption))
                        .foregroundStyle(DS.inkTertiary)
                }
            }
        }
    }

    private var coursesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(languageManager.text("author.courses.title"))
                    .font(DS.title(.headline, .semibold))
                    .foregroundStyle(DS.ink)
                Spacer()
                Text(countLabel)
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(DS.inkTertiary)
            }

            VStack(spacing: 12) {
                ForEach(courses) { course in
                    AuthorCourseRow(
                        course: course,
                        status: progressManager.courseStatus(for: course.id),
                        isCurrent: course.id == currentCourseId,
                        onTap: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onOpenCourse(course)
                        }
                    )
                }
            }
        }
    }
}

private struct AuthorCourseRow: View {
    @Environment(LanguageManager.self) private var languageManager

    let course: Course
    let status: CourseStatus
    let isCurrent: Bool
    let onTap: () -> Void

    @State private var cover: UIImage?

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    DS.surfaceMuted
                    if let cover {
                        Image(uiImage: cover).resizable().scaledToFill()
                    } else {
                        Image(systemName: course.subject.icon)
                            .font(.jakarta(size: 20, weight: .light))
                            .foregroundStyle(DS.accentSoft.opacity(0.5))
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(course.subject.localizedShortName(language: languageManager.current).uppercasedInApp())
                        .font(DS.sans(.caption2, .semibold))
                        .foregroundStyle(DS.accentSoft)
                        .tracking(1.0)
                    Text(course.title)
                        .font(DS.title(.subheadline, .semibold))
                        .foregroundStyle(DS.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if isCurrent {
                        Text(languageManager.text("author.currentCourse"))
                            .font(DS.sans(.caption))
                            .foregroundStyle(DS.inkTertiary)
                    }
                }

                Spacer(minLength: 8)

                statusIcon
            }
            .padding(12)
        }
        .buttonStyle(SoftPressButtonStyle())
        .dsCard(padding: 0)
        .opacity(isCurrent ? 0.7 : 1)
        .onAppear {
            if cover == nil { cover = CourseImageMap.loadImage(for: course.id) }
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .completed:
            Image(systemName: "checkmark")
                .font(.jakarta(size: 13, weight: .semibold))
                .foregroundStyle(DS.success)
                .frame(width: 34, height: 34)
                .background(DS.successTint, in: Circle())
        case .inProgress:
            Image(systemName: "arrow.forward")
                .font(.jakarta(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(DS.accent, in: Circle())
        case .notStarted:
            Image(systemName: "play.fill")
                .font(.jakarta(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(DS.accent, in: Circle())
        }
    }
}
