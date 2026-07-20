import SwiftUI

struct OnboardingProgramScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    @Bindable var viewModel: OnboardingViewModel
    let onNext: () -> Void

    @State private var headerIn = false
    @State private var profileIn = false
    @State private var statsIn = false
    @State private var coursesTitleIn = false
    @State private var featuredIn = false
    @State private var revealedRows = 0
    @State private var ctaIn = false

    private let ink = BrutalPalette.ink
    private let pink = BrutalPalette.pink
    private let gold = BrutalPalette.yellow

    private var courses: [Course] {
        viewModel.recommendedProgramCourses(language: languageManager.current)
    }

    private var nicknames: [String] {
        viewModel.profileNicknames(language: languageManager.current)
    }

    private var primarySubject: Subject? {
        Subject.allCases.first { viewModel.interests.contains($0.storageKey) }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    profileCard
                    statsRow
                    coursesSection
                }
                .padding(.horizontal, 22)
                .padding(.top, 56)
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)

            OnboardingPrimaryButton(title: languageManager.text("common.continue"), action: onNext)
                .opacity(ctaIn ? 1 : 0)
                .offset(y: ctaIn ? 0 : 22)
        }
        .onboardingFullBleedBackground(BrutalPalette.cream)
        .onOnboardingSlideSettled {
            CourseImageMap.preloadImages(for: courses.map(\.id))
            animateIn()
        }
    }

    private func animateIn() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) { headerIn = true }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.72).delay(0.12)) { profileIn = true }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.72).delay(0.26)) { statsIn = true }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4)) { coursesTitleIn = true }
        withAnimation(.spring(response: 0.62, dampingFraction: 0.72).delay(0.5)) { featuredIn = true }

        // Reveal each compact course row one after another for a satisfying cascade.
        let rowCount = max(0, courses.count - 1)
        for row in 0..<rowCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.64 + Double(row) * 0.12) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    revealedRows = row + 1
                }
                OnboardingHaptics.selection()
            }
        }

        let ctaDelay = 0.7 + Double(rowCount) * 0.12
        DispatchQueue.main.asyncAfter(deadline: .now() + ctaDelay) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78)) { ctaIn = true }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            BrutalPill(
                text: languageManager.text("onboarding.program.badge"),
                icon: "sparkles",
                background: gold,
                foreground: ink
            )

            Text(languageManager.text("onboarding.program.title"))
                .font(.jakarta(size: 36, weight: .heavy, design: .rounded))
                .lineSpacing(-3)
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(headerIn ? 1 : 0)
        .offset(y: headerIn ? 0 : 18)
        .scaleEffect(headerIn ? 1 : 0.96, anchor: .leading)
    }

    // MARK: - Profile identity card

    private var profileCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(pink)
                    .frame(width: 66, height: 66)
                    .overlay { Circle().strokeBorder(ink, lineWidth: 3) }
                Text(primarySubject?.emoji ?? "✨")
                    .font(.jakarta(size: 32))
            }
            .background(alignment: .center) {
                Circle().fill(ink).frame(width: 66, height: 66).offset(x: 3, y: 4)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(languageManager.text("onboarding.program.profileLabel"))
                    .font(.jakarta(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(ink.opacity(0.45))
                    .tracking(1.0)

                Text(nicknames.first ?? "")
                    .font(.jakarta(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)

                if nicknames.count > 1 {
                    FlowLayout(spacing: 6) {
                        ForEach(Array(nicknames.dropFirst().enumerated()), id: \.offset) { index, nickname in
                            Text(nickname)
                                .font(.jakarta(.caption, design: .rounded, weight: .heavy))
                                .foregroundStyle(ink)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(OnboardingPastels.at(index + 1), in: Capsule())
                                .overlay { Capsule().strokeBorder(ink, lineWidth: 1.8) }
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(ink, lineWidth: 3)
        }
        .brutalOffsetPlate(depth: 6, corner: 24)
        .opacity(profileIn ? 1 : 0)
        .offset(y: profileIn ? 0 : 20)
        .scaleEffect(profileIn ? 1 : 0.94)
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 12) {
            statTile(
                emoji: "🎯",
                fill: OnboardingPastels.at(1),
                value: "\(viewModel.dailyLearningGoal)",
                unit: viewModel.dailyLearningGoalLabel(language: languageManager.current),
                caption: languageManager.text("onboarding.program.dailyGoalCaption")
            )
            .opacity(statsIn ? 1 : 0)
            .offset(y: statsIn ? 0 : 18)
            .scaleEffect(statsIn ? 1 : 0.9)

            statTile(
                emoji: "⏳",
                fill: OnboardingPastels.at(0),
                value: "\(viewModel.projectedHoursSavedPerYear)",
                unit: languageManager.text("onboarding.program.hoursUnit"),
                caption: languageManager.text("onboarding.program.hoursSavedCaption")
            )
            .opacity(statsIn ? 1 : 0)
            .offset(y: statsIn ? 0 : 18)
            .scaleEffect(statsIn ? 1 : 0.9)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.08), value: statsIn)
        }
    }

    private func statTile(emoji: String, fill: Color, value: String, unit: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(emoji)
                .font(.jakarta(size: 24))

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.jakarta(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(ink)
                Text(unit)
                    .font(.jakarta(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Text(caption)
                .font(.jakarta(.caption2, design: .rounded, weight: .heavy))
                .foregroundStyle(ink.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(fill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(ink, lineWidth: 3)
        }
        .brutalOffsetPlate(depth: 5, corner: 22)
    }

    // MARK: - Courses

    private var coursesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(languageManager.text("onboarding.program.coursesTitle"))
                .font(.jakarta(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(coursesTitleIn ? 1 : 0)
                .offset(y: coursesTitleIn ? 0 : 12)

            if let featured = courses.first {
                FeaturedCourseCard(course: featured, accent: OnboardingPastels.at(0))
                    .opacity(featuredIn ? 1 : 0)
                    .offset(y: featuredIn ? 0 : 24)
                    .scaleEffect(featuredIn ? 1 : 0.93)
            }

            VStack(spacing: 12) {
                ForEach(Array(courses.dropFirst().enumerated()), id: \.element.id) { index, course in
                    CompactCourseRow(course: course, accent: OnboardingPastels.at(index + 1), rank: index + 2)
                        .opacity(index < revealedRows ? 1 : 0)
                        .offset(x: index < revealedRows ? 0 : 40)
                        .scaleEffect(index < revealedRows ? 1 : 0.96, anchor: .leading)
                }
            }
        }
    }
}

// MARK: - Featured course card (editorial hero)

private struct FeaturedCourseCard: View {
    @Environment(LanguageManager.self) private var languageManager
    let course: Course
    let accent: Color

    @State private var image: UIImage?

    private let ink = BrutalPalette.ink

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                accent
                    .overlay {
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        }
                    }
                LinearGradient(colors: [.clear, .black.opacity(0.35)], startPoint: .center, endPoint: .bottom)

                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.jakarta(size: 10, weight: .black))
                    Text(languageManager.text("onboarding.program.topPick").uppercased())
                        .font(.jakarta(.caption2, design: .rounded, weight: .black))
                        .tracking(0.6)
                }
                .foregroundStyle(ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(BrutalPalette.yellow, in: Capsule())
                .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
                .padding(12)
            }
            .frame(height: 132)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(alignment: .bottom) { Rectangle().fill(ink).frame(height: 3) }

            VStack(alignment: .leading, spacing: 8) {
                BrutalPill(
                    text: course.subject.localizedShortName(language: languageManager.current),
                    icon: course.subject.icon,
                    background: accent.opacity(0.6),
                    foreground: ink
                )

                Text(course.title)
                    .font(.jakarta(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    statChip(icon: "rectangle.stack.fill", text: String(format: languageManager.text("onboarding.showcase.courses.lessons"), course.lessons.count))
                    statChip(icon: "checkmark.circle.fill", text: String(format: languageManager.text("onboarding.showcase.courses.quizCount"), course.quiz.count))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(ink, lineWidth: 3)
        }
        .brutalOffsetPlate(depth: 6, corner: 24)
        .onAppear { image = CourseImageMap.loadImage(for: course.id) }
    }

    private func statChip(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.jakarta(size: 10, weight: .black))
            Text(text).font(.jakarta(.caption2, design: .rounded, weight: .black))
        }
        .foregroundStyle(ink)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(Color(red: 0.96, green: 0.93, blue: 0.88), in: Capsule())
        .overlay { Capsule().strokeBorder(ink.opacity(0.5), lineWidth: 1.5) }
    }
}

// MARK: - Compact course row

private struct CompactCourseRow: View {
    @Environment(LanguageManager.self) private var languageManager
    let course: Course
    let accent: Color
    let rank: Int

    @State private var image: UIImage?

    private let ink = BrutalPalette.ink

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                accent
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                }
            }
            .frame(width: 58, height: 58)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(ink, lineWidth: 2.5)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(course.subject.localizedShortName(language: languageManager.current).uppercased())
                    .font(.jakarta(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(ink.opacity(0.5))
                    .tracking(0.5)
                Text(course.title)
                    .font(.jakarta(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(ink, lineWidth: 2.5)
        }
        .onAppear { image = CourseImageMap.loadImage(for: course.id) }
    }
}

// MARK: - Flow layout for nickname pills

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
