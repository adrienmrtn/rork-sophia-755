import SwiftUI

struct OnboardingProgramScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    @Bindable var viewModel: OnboardingViewModel
    let onNext: () -> Void

    @State private var appeared = false
    @State private var statsAppeared = false
    @State private var coursesAppeared = false

    private var courses: [Course] {
        viewModel.recommendedProgramCourses(language: languageManager.current)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    headerSection
                    nicknameSection
                    statsSection
                    coursesSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 52)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)

            OnboardingPrimaryButton(title: languageManager.text("common.continue"), action: onNext)
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
        }
        .onboardingFullBleedBackground(Color(red: 0.98, green: 0.96, blue: 0.93))
        .onOnboardingSlideSettled {
            CourseImageMap.preloadImages(for: courses.map(\.id))
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                appeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.18)) {
                statsAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.38)) {
                coursesAppeared = true
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            BrutalPill(
                text: languageManager.text("onboarding.program.badge"),
                icon: "sparkles",
                background: BrutalPalette.pink,
                foreground: BrutalPalette.ink
            )

            Text(languageManager.text("onboarding.program.title"))
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .lineSpacing(-2)
                .foregroundStyle(BrutalPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
    }

    private var nicknameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(languageManager.text("onboarding.program.profileLabel"))
                .font(.system(.caption, design: .rounded, weight: .black))
                .foregroundStyle(BrutalPalette.ink.opacity(0.5))
                .tracking(0.8)

            FlowLayout(spacing: 8) {
                ForEach(Array(viewModel.profileNicknames(language: languageManager.current).enumerated()), id: \.offset) { index, nickname in
                    Text(nickname)
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(OnboardingPastels.at(index), in: Capsule())
                        .overlay { Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 2) }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "target",
                value: String(
                    format: languageManager.text("onboarding.program.dailyGoal"),
                    viewModel.dailyLearningGoal,
                    viewModel.dailyLearningGoalLabel(language: languageManager.current)
                ),
                caption: languageManager.text("onboarding.program.dailyGoalCaption")
            )

            statCard(
                icon: "hourglass.bottomhalf.filled",
                value: String(
                    format: languageManager.text("onboarding.program.hoursSaved"),
                    viewModel.projectedHoursSavedPerYear
                ),
                caption: languageManager.text("onboarding.program.hoursSavedCaption")
            )
        }
        .opacity(statsAppeared ? 1 : 0)
        .offset(y: statsAppeared ? 0 : 14)
    }

    private func statCard(icon: String, value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(BrutalPalette.ink)
                .padding(8)
                .background(BrutalPalette.yellow, in: Circle())
                .overlay { Circle().strokeBorder(BrutalPalette.ink, lineWidth: 1.8) }

            Text(value)
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(caption)
                .font(.system(.caption2, design: .rounded, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
        }
        .brutalOffsetPlate(depth: 4, corner: 18)
    }

    private var coursesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(languageManager.text("onboarding.program.coursesTitle"))
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 12) {
                ForEach(Array(courses.enumerated()), id: \.element.id) { index, course in
                    OnboardingProgramCourseRow(
                        course: course,
                        accent: OnboardingPastels.at(index)
                    )
                    .opacity(coursesAppeared ? 1 : 0)
                    .offset(y: coursesAppeared ? 0 : 12)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.08), value: coursesAppeared)
                }
            }
        }
        .opacity(coursesAppeared ? 1 : 0)
    }
}

private struct OnboardingProgramCourseRow: View {
    @Environment(LanguageManager.self) private var languageManager
    let course: Course
    let accent: Color

    @State private var image: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                accent
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(BrutalPalette.ink, lineWidth: 2)
            }

            VStack(alignment: .leading, spacing: 4) {
                BrutalPill(
                    text: course.subject.localizedShortName(language: languageManager.current),
                    icon: course.subject.icon,
                    background: accent.opacity(0.55),
                    foreground: BrutalPalette.ink
                )

                Text(course.title)
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(BrutalPalette.ink.opacity(0.35))
        }
        .padding(12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(BrutalPalette.ink.opacity(0.15), lineWidth: 1.5)
        }
        .onAppear {
            image = CourseImageMap.loadImage(for: course.id)
        }
    }
}

/// Simple wrapping layout for nickname pills.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}
