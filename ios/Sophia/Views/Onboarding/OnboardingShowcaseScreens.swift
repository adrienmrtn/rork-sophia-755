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
                .frame(height: 340)

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
    private let heroHeight: CGFloat = 116

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

                HStack(spacing: 8) {
                    ForEach(inlineImages, id: \.self) { name in
                        OnboardingInlineCourseImage(rawName: name, accent: accent)
                    }
                    if inlineImages.isEmpty {
                        OnboardingCourseStatChip(
                            icon: "doc.text.fill",
                            text: lessonCountText,
                            fill: accent
                        )
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
        }
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
        .frame(height: 52)
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

    @State private var revealedOption: Int? = nil
    @State private var showCheck = false
    @State private var showXPBadge = false

    private let ink = BrutalPalette.ink
    private let correctIndex = 1

    var body: some View {
        OnboardingShowcaseLayout(titleKey: "onboarding.showcase.quiz.title", onNext: onNext) {
            VStack(alignment: .leading, spacing: 16) {
                quizProgressDots

                Text(languageManager.text("onboarding.showcase.quiz.question"))
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { index in
                        quizOption(index: index)
                    }
                }
            }
            .padding(20)
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
                        .offset(x: 6, y: -12)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
        }
        .onOnboardingSlideSettled(delay: 0.5) {
            animateQuiz()
        }
    }

    private var quizProgressDots: some View {
        HStack(spacing: 5) {
            ForEach(0..<5, id: \.self) { i in
                Capsule()
                    .fill(i == 0 ? BrutalPalette.pink : ink.opacity(0.12))
                    .frame(width: i == 1 ? 22 : 10, height: 6)
            }
        }
    }

    @ViewBuilder
    private func quizOption(index: Int) -> some View {
        let isCorrect = index == correctIndex
        let isRevealed = revealedOption == index
        let bg: Color = isRevealed && isCorrect ? Color(red: 0.70, green: 0.95, blue: 0.80) : Color.white

        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isRevealed && isCorrect ? ink : Color.clear)
                    .overlay {
                        Circle().strokeBorder(ink.opacity(isRevealed && isCorrect ? 1 : 0.25), lineWidth: 2)
                    }
                    .frame(width: 22, height: 22)

                if isRevealed && isCorrect && showCheck {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white)
                        .transition(.scale)
                }
            }

            Text(languageManager.text("onboarding.showcase.quiz.option.\(index)"))
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(bg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(ink, lineWidth: 2.2)
        }
        .scaleEffect(isRevealed && isCorrect ? 1.02 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isRevealed)
    }

    private func animateQuiz() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                revealedOption = correctIndex
            }
            OnboardingHaptics.selection()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                showCheck = true
            }
            OnboardingHaptics.primaryCTA()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.45) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                showXPBadge = true
            }
        }
    }
}

// MARK: - 9 · Collections — two covers crossfading with a fill-up progress bar

struct OnboardingShowcaseCollectionsScreen: View {
    let onNext: () -> Void

    @State private var progress: CGFloat = 0
    @State private var activeIndex: Int = 0

    private var collections: [LearningCollection] {
        Array(ContentCatalog.activeCollections.prefix(2))
    }

    var body: some View {
        OnboardingShowcaseLayout(titleKey: "onboarding.showcase.collections.title", onNext: onNext) {
            ZStack {
                ForEach(Array(collections.enumerated()), id: \.element.id) { index, collection in
                    mockCollectionCard(collection, accentIndex: index)
                        .opacity(activeIndex == index ? 1 : 0)
                        .scaleEffect(activeIndex == index ? 1 : 0.95)
                        .rotation3DEffect(
                            .degrees(activeIndex == index ? 0 : 8),
                            axis: (x: 0, y: 1, z: 0)
                        )
                }
            }
        }
        .onOnboardingSlideSettled(delay: 0.35) {
            animateFirst()
            guard collections.count > 1 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                    activeIndex = 1
                    progress = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeInOut(duration: 1.1)) { progress = 1 }
                }
                OnboardingHaptics.selection()
            }
        }
    }

    private func animateFirst() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeInOut(duration: 1.3)) { progress = 1 }
            OnboardingHaptics.selection()
        }
    }

    @ViewBuilder
    private func mockCollectionCard(_ collection: LearningCollection, accentIndex: Int) -> some View {
        let ink = BrutalPalette.ink
        let depth: CGFloat = 5
        let total = max(collection.courseIds.count, 1)
        let completed = min(Int((progress * 3).rounded()), total)

        VStack(alignment: .leading, spacing: 0) {
            CollectionCoverView(collection: collection, accentIndex: accentIndex)
                .frame(height: 128)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(ink).frame(height: 3)
                }

            VStack(alignment: .leading, spacing: 12) {
                Text(collection.title)
                    .font(.system(.title3, design: .rounded, weight: .black))
                    .foregroundStyle(ink)
                    .lineLimit(2)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(ink.opacity(0.1))
                        Capsule()
                            .fill(BrutalPalette.pink)
                            .frame(width: geo.size.width * min(progress, 1))
                    }
                }
                .frame(height: 10)

                HStack {
                    Text("\(completed) / \(total)")
                        .font(.system(.caption, design: .rounded, weight: .black))
                        .monospacedDigit()
                    Spacer()
                    Text("+\(total * ProgressManager.globalCollectionXPPerCourse) XP")
                        .font(.system(.caption2, design: .rounded, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(BrutalPalette.yellow, in: Capsule())
                        .overlay { Capsule().strokeBorder(ink, lineWidth: 1.5) }
                }
                .foregroundStyle(ink.opacity(0.7))
            }
            .padding(16)
            .background(Color.white)
        }
        .frame(maxWidth: 320)
        .clipShape(.rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(ink, lineWidth: 3)
        }
        .brutalOffsetPlate(depth: depth, corner: 22)
    }
}

// MARK: - 10 · Cartes — three-card fan with a legendary reveal

struct OnboardingShowcaseCardsScreen: View {
    let onNext: () -> Void

    @State private var fanned = false
    @State private var glow = false
    @State private var centerFlipped = false

    private var heroCards: [CollectibleCard] {
        let legendary = CardData.allCards.first { $0.rarity == .legendaire }
        let rare = CardData.allCards.first { $0.rarity == .rare }
        let commune = CardData.allCards.first { $0.rarity == .commune }
        return [commune, legendary, rare].compactMap { $0 }
    }

    var body: some View {
        OnboardingShowcaseLayout(titleKey: "onboarding.showcase.cards.title", onNext: onNext) {
            ZStack {
                if glow {
                    Circle()
                        .fill(BrutalPalette.yellow.opacity(0.4))
                        .frame(width: 190, height: 190)
                        .blur(radius: 28)
                        .scaleEffect(glow ? 1.1 : 0.85)
                        .animation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true), value: glow)
                }

                ForEach(Array(heroCards.enumerated()), id: \.element.id) { index, card in
                    let isCenter = index == 1
                    CollectibleMiniCard(card: card, unlocked: isCenter ? centerFlipped : true)
                        .rotationEffect(.degrees(fanned ? sideRotation(for: index) : 0))
                        .offset(
                            x: fanned ? sideOffset(for: index) : 0,
                            y: isCenter ? 0 : (fanned ? 16 : 0)
                        )
                        .scaleEffect(isCenter ? (centerFlipped ? 1.08 : 0.94) : 0.86)
                        .zIndex(isCenter ? 1 : 0)
                        .opacity(fanned ? 1 : 0)
                }
            }
            .frame(height: 220)
        }
        .onOnboardingSlideSettled(delay: 0.35) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.72)) {
                fanned = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.spring(response: 0.65, dampingFraction: 0.68)) {
                    centerFlipped = true
                }
                glow = true
                OnboardingHaptics.primaryCTA()
            }
        }
    }

    private func sideRotation(for index: Int) -> Double {
        switch index {
        case 0: return -14
        case 2: return 14
        default: return 0
        }
    }

    private func sideOffset(for index: Int) -> CGFloat {
        switch index {
        case 0: return -78
        case 2: return 78
        default: return 0
        }
    }
}

// MARK: - 13 · XP — bar fill with floating XP chips and a level-up pop

struct OnboardingShowcaseXPScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var barFill: CGFloat = 0
    @State private var levelBounce = false
    @State private var showLevelPop = false
    @State private var floatingChips: [FloatingXPChip] = []

    private let ink = BrutalPalette.ink

    var body: some View {
        OnboardingShowcaseLayout(titleKey: "onboarding.showcase.xp.title", onNext: onNext) {
            ZStack {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(BrutalPalette.pink)
                            .frame(width: 62, height: 62)
                            .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
                            .scaleEffect(levelBounce ? 1.15 : 1)
                            .animation(.spring(response: 0.4, dampingFraction: 0.5), value: levelBounce)

                        Text(showLevelPop ? "2" : "1")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundStyle(ink)
                            .contentTransition(.numericText())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(languageManager.text("onboarding.showcase.xp.level"))
                            .font(.system(.caption, design: .rounded, weight: .black))
                            .foregroundStyle(ink.opacity(0.5))
                            .tracking(0.8)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(ink.opacity(0.1))
                                Capsule()
                                    .fill(BrutalPalette.pink)
                                    .frame(width: geo.size.width * barFill)
                            }
                        }
                        .frame(height: 16)
                    }
                }
                .padding(20)
                .brutalOnboardingCard(depth: 5, corner: 24)

                ForEach(floatingChips) { chip in
                    Text("+\(chip.amount)")
                        .font(.system(.subheadline, design: .rounded, weight: .black))
                        .foregroundStyle(ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(BrutalPalette.yellow, in: Capsule())
                        .overlay { Capsule().strokeBorder(ink, lineWidth: 1.6) }
                        .offset(x: chip.x, y: chip.y)
                        .opacity(chip.opacity)
                }
            }
        }
        .onOnboardingSlideSettled(delay: 0.4) {
            animateXP()
        }
    }

    private func animateXP() {
        let chipPlan: [(amount: Int, x: CGFloat, delay: Double)] = [
            (10, -50, 0.15),
            (15, 8, 0.55),
            (8, 55, 0.95),
        ]
        for plan in chipPlan {
            DispatchQueue.main.asyncAfter(deadline: .now() + plan.delay) {
                spawnChip(amount: plan.amount, xOffset: plan.x)
            }
        }

        withAnimation(.timingCurve(0.12, 0.92, 0.18, 1.0, duration: 1.55)) {
            barFill = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.72) {
            levelBounce = true
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                showLevelPop = true
            }
            OnboardingHaptics.primaryCTA()
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                barFill = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.easeOut(duration: 0.65)) {
                    barFill = 0.22
                }
            }
        }
    }

    private func spawnChip(amount: Int, xOffset: CGFloat) {
        let chip = FloatingXPChip(amount: amount, x: xOffset, y: 30, opacity: 0)
        floatingChips.append(chip)
        let id = chip.id

        withAnimation(.easeOut(duration: 0.25)) {
            updateChip(id: id) { $0.opacity = 1 }
        }
        withAnimation(.easeOut(duration: 1.1)) {
            updateChip(id: id) { $0.y = -74 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            withAnimation(.easeIn(duration: 0.3)) {
                updateChip(id: id) { $0.opacity = 0 }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            floatingChips.removeAll { $0.id == id }
        }
    }

    private func updateChip(id: UUID, _ mutate: (inout FloatingXPChip) -> Void) {
        guard let idx = floatingChips.firstIndex(where: { $0.id == id }) else { return }
        mutate(&floatingChips[idx])
    }
}

private struct FloatingXPChip: Identifiable {
    let id = UUID()
    let amount: Int
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
}
