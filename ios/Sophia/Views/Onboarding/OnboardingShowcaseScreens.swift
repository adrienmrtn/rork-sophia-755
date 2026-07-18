import SwiftUI

// MARK: - Shared layout

/// Minimal showcase layout: one factual title, a hero animation, and a CTA.
/// No subtitle — the visual does the talking.
private struct OnboardingShowcaseLayout<Hero: View>: View {
    @Environment(LanguageManager.self) private var languageManager
    let titleKey: String
    var heroEdgeToEdge: Bool = false
    let onNext: () -> Void
    @ViewBuilder let hero: () -> Hero

    @State private var titleAppeared = false
    @State private var heroAppeared = false
    @State private var ctaAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 38)

            Text(languageManager.text(titleKey))
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .lineSpacing(-2)
                .foregroundStyle(BrutalPalette.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(titleAppeared ? 1 : 0)
                .offset(y: titleAppeared ? 0 : 16)

            Spacer(minLength: 18)

            hero()
                .padding(.horizontal, heroEdgeToEdge ? 0 : 24)
                .opacity(heroAppeared ? 1 : 0)
                .scaleEffect(heroAppeared ? 1 : 0.92)

            Spacer(minLength: 18)

            OnboardingPrimaryButton(title: languageManager.text("common.continue"), action: onNext)
                .opacity(ctaAppeared ? 1 : 0)
                .offset(y: ctaAppeared ? 0 : 20)
        }
        .onOnboardingSlideSettled {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                titleAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.12)) {
                heroAppeared = true
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.5)) {
                ctaAppeared = true
            }
        }
    }
}

// MARK: - 4 · Cours — swipeable examples from real course content

struct OnboardingShowcaseCoursesScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var selectedCourse = 0

    private var courses: [Course] {
        Array(
            CuratedStarterCourses.ids
                .compactMap { ContentCatalog.course(withId: $0, language: languageManager.current) }
                .prefix(5)
        )
    }

    var body: some View {
        OnboardingShowcaseLayout(titleKey: "onboarding.showcase.courses.title", onNext: onNext) {
            VStack(spacing: 12) {
                TabView(selection: $selectedCourse) {
                    ForEach(Array(courses.enumerated()), id: \.element.id) { index, course in
                        OnboardingCourseExampleCard(
                            course: course,
                            accent: OnboardingPastels.at(index)
                        )
                        .padding(.horizontal, 2)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 348)

                HStack(spacing: 6) {
                    ForEach(0..<courses.count, id: \.self) { index in
                        Capsule()
                            .fill(index == selectedCourse ? BrutalPalette.ink : BrutalPalette.ink.opacity(0.18))
                            .frame(width: index == selectedCourse ? 24 : 8, height: 7)
                            .animation(.spring(response: 0.3), value: selectedCourse)
                    }
                }

                Text(languageManager.text("onboarding.showcase.courses.swipe"))
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.55))
                    .tracking(0.7)
            }
            .onAppear {
                CourseImageMap.preloadImages(for: courses.map(\.id))
            }
        }
    }
}

private struct OnboardingCourseExampleCard: View {
    @Environment(LanguageManager.self) private var languageManager
    let course: Course
    let accent: Color

    @State private var image: UIImage?

    private var inlineImages: [String] {
        var names: [String] = []
        for lesson in course.lessons {
            var searchRange = lesson.content.startIndex..<lesson.content.endIndex
            while let open = lesson.content[searchRange].firstIndex(of: "["),
                  let close = lesson.content[open...].firstIndex(of: "]") {
                let name = String(lesson.content[lesson.content.index(after: open)..<close])
                if !name.isEmpty, !names.contains(name) {
                    names.append(name)
                }
                searchRange = lesson.content.index(after: close)..<lesson.content.endIndex
                if names.count == 2 { return names }
            }
        }
        return names
    }

    private let corner: CGFloat = 24
    private let heroHeight: CGFloat = 108
    private let cardHeight: CGFloat = 316

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                accent
                    .overlay {
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .allowsHitTesting(false)
                        }
                    }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.48)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                BrutalPill(
                    text: course.subject.localizedShortName(language: languageManager.current),
                    icon: course.subject.icon,
                    background: Color.white,
                    foreground: BrutalPalette.ink
                )
                .padding(12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: heroHeight)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: corner,
                    topTrailingRadius: corner,
                    style: .continuous
                )
            )
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(BrutalPalette.ink)
                    .frame(height: 3)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(course.title)
                    .font(.system(.title3, design: .rounded, weight: .black))
                    .foregroundStyle(BrutalPalette.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(course.description)
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.58))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 10)

                if !inlineImages.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(inlineImages, id: \.self) { name in
                            OnboardingInlineCourseImage(rawName: name, accent: accent)
                        }
                    }
                }

                HStack(spacing: 8) {
                    OnboardingCourseStatChip(
                        icon: "rectangle.stack.fill",
                        text: lessonCountText,
                        fill: BrutalPalette.yellow
                    )
                    OnboardingCourseStatChip(
                        icon: "checkmark.circle.fill",
                        text: quizCountText,
                        fill: accent
                    )
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.white)
        }
        .frame(height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .strokeBorder(BrutalPalette.ink, lineWidth: 3)
        }
        .brutalOffsetPlate(depth: 5, corner: corner)
        .onAppear {
            image = CourseImageMap.loadImage(for: course.id)
        }
    }

    private var lessonCountText: String {
        String(format: languageManager.text("onboarding.showcase.courses.lessons"), course.lessons.count)
    }

    private var quizCountText: String {
        String(format: languageManager.text("onboarding.showcase.courses.quizCount"), course.quiz.count)
    }
}

private struct OnboardingInlineCourseImage: View {
    let rawName: String
    let accent: Color

    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(accent.opacity(0.65))

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.45))
            }

            Text(rawName)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                .padding(6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(BrutalPalette.ink, lineWidth: 2)
        }
        .onAppear {
            image = CourseInlineImage.loadImage(named: CourseInlineImage.slug(rawName))
        }
    }
}

private struct OnboardingCourseStatChip: View {
    let icon: String
    let text: String
    let fill: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .black))
            Text(text)
                .font(.system(.caption2, design: .rounded, weight: .black))
        }
        .foregroundStyle(BrutalPalette.ink)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(fill, in: Capsule())
        .overlay { Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 1.6) }
    }
}

// MARK: - 6 · Quiz — brutal quiz card with a real answer reveal

struct OnboardingShowcaseQuizScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    private struct QuizPrompt: Identifiable {
        let id = UUID()
        let question: String
        let options: [String]
        let correctIndex: Int
    }

    @State private var prompts: [QuizPrompt] = []
    @State private var qIndex = 0
    @State private var revealed = false
    @State private var showCheck = false
    @State private var showXPBadge = false

    private let ink = BrutalPalette.ink

    private var fallbackPrompt: QuizPrompt {
        QuizPrompt(
            question: languageManager.text("onboarding.showcase.quiz.question"),
            options: (0..<4).map { languageManager.text("onboarding.showcase.quiz.option.\($0)") },
            correctIndex: 1
        )
    }

    private var current: QuizPrompt {
        prompts.indices.contains(qIndex) ? prompts[qIndex] : fallbackPrompt
    }

    private var dotCount: Int { max(prompts.count, 1) }

    var body: some View {
        OnboardingShowcaseLayout(titleKey: "onboarding.showcase.quiz.title", onNext: onNext) {
            VStack(alignment: .leading, spacing: 16) {
                quizProgressDots

                VStack(alignment: .leading, spacing: 16) {
                    Text(current.question)
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 10) {
                        ForEach(Array(current.options.enumerated()), id: \.offset) { index, option in
                            quizOption(index: index, option: option)
                        }
                    }
                }
                .id(qIndex)
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 330, alignment: .topLeading)
            .brutalOnboardingCard(depth: 5, corner: 24)
            .overlay(alignment: .topTrailing) {
                if showXPBadge {
                    Text("+10 XP")
                        .font(.system(.caption, design: .rounded, weight: .black))
                        .foregroundStyle(ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(BrutalPalette.yellow, in: Capsule())
                        .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
                        .offset(x: -2, y: -10)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
        }
        .onOnboardingSlideSettled(delay: 0.4) {
            if prompts.isEmpty { prompts = buildPrompts() }
            runQuestion(0)
        }
    }

    private var quizProgressDots: some View {
        HStack(spacing: 5) {
            ForEach(0..<dotCount, id: \.self) { i in
                Capsule()
                    .fill(i == qIndex ? BrutalPalette.pink : ink.opacity(0.12))
                    .frame(width: i == qIndex ? 22 : 10, height: 6)
                    .animation(.spring(response: 0.3), value: qIndex)
            }
        }
    }

    @ViewBuilder
    private func quizOption(index: Int, option: String) -> some View {
        let isCorrect = index == current.correctIndex
        let isRevealed = revealed && isCorrect
        let bg: Color = isRevealed ? Color(red: 0.70, green: 0.95, blue: 0.80) : Color.white

        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isRevealed ? ink : Color.clear)
                    .overlay {
                        Circle().strokeBorder(ink.opacity(isRevealed ? 1 : 0.25), lineWidth: 2)
                    }
                    .frame(width: 22, height: 22)

                if isRevealed && showCheck {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white)
                        .transition(.scale)
                }
            }

            Text(option)
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(bg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(ink, lineWidth: 2.2)
        }
        .scaleEffect(isRevealed ? 1.02 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isRevealed)
    }

    /// Onboarding question first, then a couple of real (already-localized) course
    /// quiz questions, kept short so the card height stays stable.
    private func buildPrompts() -> [QuizPrompt] {
        var list: [QuizPrompt] = [fallbackPrompt]
        let extra = CuratedStarterCourses.ids
            .compactMap { ContentCatalog.course(withId: $0, language: languageManager.current) }
            .flatMap(\.quiz)
            .filter { q in
                q.options.count == 4
                    && q.question.count <= 80
                    && q.options.allSatisfy { $0.count <= 34 }
            }
        for q in extra {
            list.append(QuizPrompt(question: q.question, options: q.options, correctIndex: q.correctIndex))
            if list.count == 3 { break }
        }
        return list
    }

    private func runQuestion(_ i: Int) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            qIndex = i
            revealed = false
            showCheck = false
            showXPBadge = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            guard qIndex == i else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) { revealed = true }
            OnboardingHaptics.selection()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            guard qIndex == i else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { showCheck = true }
            OnboardingHaptics.primaryCTA()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.45) {
            guard qIndex == i else { return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) { showXPBadge = true }
        }

        // Chain to the next question, then stop on the last one (revealed).
        guard i + 1 < max(prompts.count, 1) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            runQuestion(i + 1)
        }
    }
}

// MARK: - Collections — a single collection with a segmented fill-in animation

struct OnboardingShowcaseCollectionsScreen: View {
    let onNext: () -> Void

    @State private var filledCount: Int = 0
    @State private var cardPop = false

    private var collection: LearningCollection? {
        ContentCatalog.activeCollections.first
    }

    private var stepCount: Int {
        max(collection?.courseIds.count ?? 3, 1)
    }

    var body: some View {
        OnboardingShowcaseLayout(titleKey: "onboarding.showcase.collections.title", onNext: onNext) {
            if let collection {
                collectionCard(collection)
                    .scaleEffect(cardPop ? 1 : 0.96)
            }
        }
        .onOnboardingSlideSettled(delay: 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                cardPop = true
            }
            animateSteps()
        }
    }

    private func animateSteps() {
        for step in 1...stepCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35 * Double(step)) {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.68)) {
                    filledCount = step
                }
                OnboardingHaptics.selection()
            }
        }
    }

    @ViewBuilder
    private func collectionCard(_ collection: LearningCollection) -> some View {
        let ink = BrutalPalette.ink
        let total = stepCount
        let isComplete = filledCount >= total

        VStack(alignment: .leading, spacing: 0) {
            CollectionCoverView(collection: collection, accentIndex: 0)
                .frame(height: 150)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(ink).frame(height: 3)
                }

            VStack(alignment: .leading, spacing: 16) {
                Text(collection.title)
                    .font(.system(.title3, design: .rounded, weight: .black))
                    .foregroundStyle(ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Segmented progress — one crisp segment per course, filling in sequence.
                HStack(spacing: 6) {
                    ForEach(0..<total, id: \.self) { index in
                        let filled = index < filledCount
                        Capsule()
                            .fill(filled ? BrutalPalette.pink : ink.opacity(0.1))
                            .frame(height: 12)
                            .overlay {
                                Capsule().strokeBorder(ink.opacity(filled ? 1 : 0.2), lineWidth: 1.8)
                            }
                            .scaleEffect(y: filled ? 1 : 0.82)
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: isComplete ? "checkmark.seal.fill" : "square.stack.3d.up.fill")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(ink.opacity(0.75))
                        .contentTransition(.symbolEffect(.replace))

                    Text("\(filledCount) / \(total)")
                        .font(.system(.caption, design: .rounded, weight: .black))
                        .monospacedDigit()
                        .foregroundStyle(ink.opacity(0.75))

                    Spacer()

                    Text("+\(total * ProgressManager.globalCollectionXPPerCourse) XP")
                        .font(.system(.caption2, design: .rounded, weight: .black))
                        .foregroundStyle(ink)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(BrutalPalette.yellow, in: Capsule())
                        .overlay { Capsule().strokeBorder(ink, lineWidth: 1.5) }
                        .scaleEffect(isComplete ? 1.06 : 1)
                }
            }
            .padding(16)
            .background(Color.white)
        }
        .frame(maxWidth: 330)
        .clipShape(.rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(ink, lineWidth: 3)
        }
        .brutalOffsetPlate(depth: 5, corner: 22)
    }
}
