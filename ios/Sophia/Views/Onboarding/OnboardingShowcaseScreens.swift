import SwiftUI

// MARK: - Shared layout

private struct OnboardingShowcaseLayout<Hero: View>: View {
    @Environment(LanguageManager.self) private var languageManager
    let titleKey: String
    var subtitleKey: String? = nil
    let onNext: () -> Void
    @ViewBuilder let hero: () -> Hero

    @State private var titleAppeared = false
    @State private var heroAppeared = false
    @State private var ctaAppeared = false

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: subtitleKey == nil ? 0 : 10) {
                    Text(languageManager.text(titleKey))
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .lineSpacing(-2)
                        .foregroundStyle(BrutalPalette.ink)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(titleAppeared ? 1 : 0)
                        .offset(y: titleAppeared ? 0 : 16)

                    if let subtitleKey {
                        Text(languageManager.text(subtitleKey))
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(BrutalPalette.ink.opacity(0.58))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 34)
                            .opacity(titleAppeared ? 1 : 0)
                            .offset(y: titleAppeared ? 0 : 12)
                    }
                }
                .padding(.top, 58)

                Spacer(minLength: 12)

                hero()
                    .opacity(heroAppeared ? 1 : 0)
                    .scaleEffect(heroAppeared ? 1 : 0.92)
                    .padding(.horizontal, 24)

                Spacer(minLength: 12)

                OnboardingPrimaryButton(title: languageManager.text("common.continue"), action: onNext)
                    .opacity(ctaAppeared ? 1 : 0)
                    .offset(y: ctaAppeared ? 0 : 20)
            }
        }
        .onOnboardingSlideSettled {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                titleAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.15)) {
                heroAppeared = true
            }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.55)) {
                ctaAppeared = true
            }
        }
    }
}

// MARK: - 3 · Cours

struct OnboardingShowcaseCoursesScreen: View {
    let onNext: () -> Void

    private let heroCourses: [FloatingCardInfo] = [
        FloatingCardInfo(title: "", courseId: "course_12_la_strategie_de_napoleon_a_ulm_1805", rotation: -10, xRatio: 0.28, yRatio: 0.42, scale: 1.1),
        FloatingCardInfo(title: "", courseId: "course_67_qu_est_ce_qu_un_trou_noir", rotation: 5, xRatio: 0.72, yRatio: 0.38, scale: 0.95),
        FloatingCardInfo(title: "", courseId: "course_150_la_nuit_etoilee_van_gogh", rotation: -2, xRatio: 0.5, yRatio: 0.62, scale: 1.05),
    ]

    var body: some View {
        OnboardingShowcaseLayout(titleKey: "onboarding.showcase.courses.title", onNext: onNext) {
            ZStack {
                FloatingCardsBackground(dismissing: false, cards: heroCourses)
            }
            .frame(height: 320)
            .clipped()
        }
    }
}

// MARK: - 6 · Quiz

struct OnboardingShowcaseQuizScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var revealedOption: Int? = nil
    @State private var showCheck = false
    @State private var pulseCombo = false

    private let ink = BrutalPalette.ink

    var body: some View {
        OnboardingShowcaseLayout(
            titleKey: "onboarding.showcase.quiz.title",
            subtitleKey: "onboarding.showcase.quiz.subtitle",
            onNext: onNext
        ) {
            VStack(spacing: 14) {
                HStack {
                    BrutalPill(text: languageManager.text("common.miniQuiz"), background: BrutalPalette.pink)
                    Spacer()
                    if pulseCombo {
                        BrutalPill(text: "x2", icon: "flame.fill", background: BrutalPalette.yellow, foreground: ink)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                Text(languageManager.text("onboarding.showcase.quiz.question"))
                    .font(.system(.body, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .brutalOnboardingCard()

                VStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { index in
                        quizOption(index: index)
                    }
                }
            }
            .onOnboardingSlideSettled(delay: 0.5) {
                animateQuiz()
            }
        }
    }

    @ViewBuilder
    private func quizOption(index: Int) -> some View {
        let isCorrect = index == 1
        let isRevealed = revealedOption == index
        let bg: Color = isRevealed && isCorrect
            ? Color(red: 0.70, green: 0.95, blue: 0.80)
            : Color.white

        HStack(spacing: 12) {
            Text(languageManager.text("onboarding.showcase.quiz.option.\(index)"))
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isRevealed && isCorrect && showCheck {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(ink)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(bg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(ink, lineWidth: 2.5)
        }
        .brutalOffsetPlate(depth: 3, corner: 14)
        .scaleEffect(isRevealed && isCorrect ? 1.02 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isRevealed)
    }

    private func animateQuiz() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                revealedOption = 1
            }
            OnboardingHaptics.primaryCTA()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                showCheck = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                pulseCombo = true
            }
        }
    }
}

// MARK: - 9 · Collections

struct OnboardingShowcaseCollectionsScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var progress: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -140

    private var collection: LearningCollection? {
        ContentCatalog.activeCollections.first
    }

    var body: some View {
        OnboardingShowcaseLayout(
            titleKey: "onboarding.showcase.collections.title",
            subtitleKey: "onboarding.showcase.collections.subtitle",
            onNext: onNext
        ) {
            if let collection {
                mockCollectionCard(collection)
            }
        }
        .onOnboardingSlideSettled(delay: 0.45) {
            withAnimation(.easeInOut(duration: 1.6)) {
                progress = 0.42
            }
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                shimmerOffset = 300
            }
        }
    }

    @ViewBuilder
    private func mockCollectionCard(_ collection: LearningCollection) -> some View {
        let ink = BrutalPalette.ink
        let depth: CGFloat = 5

        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(ink)
                .offset(y: depth)

            VStack(alignment: .leading, spacing: 0) {
                CollectionCoverView(collection: collection, accentIndex: 0)
                    .frame(height: 130)
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
                                .frame(width: geo.size.width * progress)
                                .overlay {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [.clear, .white.opacity(0.45), .clear],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .offset(x: shimmerOffset)
                                        .mask(Capsule())
                                }
                        }
                    }
                    .frame(height: 10)

                    HStack {
                        Text(String(format: languageManager.text("collections.progress"), 3, collection.courseIds.count))
                            .font(.system(.caption, design: .rounded, weight: .black))
                        Spacer()
                        Text("+\(collection.courseIds.count * ProgressManager.globalCollectionXPPerCourse) XP")
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
            .clipShape(.rect(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(ink, lineWidth: 3)
            }
        }
        .padding(.bottom, depth)
    }
}

// MARK: - 11 · Cartes

struct OnboardingShowcaseCardsScreen: View {
    let onNext: () -> Void

    @State private var flipped = false
    @State private var glow = false

    private var heroCard: CollectibleCard? {
        CardData.allCards.first { $0.rarity == .legendaire } ?? CardData.allCards.first
    }

    var body: some View {
        OnboardingShowcaseLayout(
            titleKey: "onboarding.showcase.cards.title",
            subtitleKey: "onboarding.showcase.cards.subtitle",
            onNext: onNext
        ) {
            if let card = heroCard {
                ZStack {
                    if glow {
                        Circle()
                            .fill(BrutalPalette.yellow.opacity(0.35))
                            .frame(width: 200, height: 200)
                            .blur(radius: 30)
                            .scaleEffect(glow ? 1.15 : 0.9)
                            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glow)
                    }

                    CollectibleMiniCard(card: card, unlocked: flipped)
                        .rotation3DEffect(.degrees(flipped ? 0 : 12), axis: (x: 0.2, y: 1, z: 0))
                        .scaleEffect(flipped ? 1.05 : 0.92)
                        .animation(.spring(response: 0.65, dampingFraction: 0.72), value: flipped)
                }
                .frame(height: 220)
            }
        }
        .onOnboardingSlideSettled(delay: 0.5) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.68).delay(0.3)) {
                flipped = true
            }
            glow = true
            OnboardingHaptics.primaryCTA()
        }
    }
}

// MARK: - 13 · XP

struct OnboardingShowcaseXPScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var barFill: CGFloat = 0
    @State private var displayedXP = 0
    @State private var levelBounce = false
    @State private var showSparkles = false

    private let targetXP = 48
    private let ink = BrutalPalette.ink

    var body: some View {
        OnboardingShowcaseLayout(
            titleKey: "onboarding.showcase.xp.title",
            subtitleKey: "onboarding.showcase.xp.subtitle",
            onNext: onNext
        ) {
            VStack(spacing: 20) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(BrutalPalette.pink)
                            .frame(width: 58, height: 58)
                            .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
                            .scaleEffect(levelBounce ? 1.12 : 1)
                            .animation(.spring(response: 0.35, dampingFraction: 0.55), value: levelBounce)

                        Text("2")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundStyle(ink)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(languageManager.text("onboarding.showcase.xp.level"))
                            .font(.system(.caption, design: .rounded, weight: .black))
                            .foregroundStyle(ink.opacity(0.55))
                            .tracking(0.8)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(ink.opacity(0.12))
                                Capsule()
                                    .fill(BrutalPalette.pink)
                                    .frame(width: geo.size.width * barFill)
                            }
                        }
                        .frame(height: 14)

                        Text(String(format: languageManager.text("common.xpBeforeNext"), max(0, 50 - displayedXP), 3))
                            .font(.system(.caption2, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink.opacity(0.55))
                            .monospacedDigit()
                    }
                }
                .padding(18)
                .brutalOnboardingCard()

                if showSparkles {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text(languageManager.text("onboarding.showcase.xp.bonus"))
                            .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        Text("+\(targetXP) XP")
                            .font(.system(.headline, design: .rounded, weight: .black))
                            .foregroundStyle(ink)
                    }
                    .foregroundStyle(ink.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(BrutalPalette.yellow.opacity(0.85), in: Capsule())
                    .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onOnboardingSlideSettled(delay: 0.45) {
            animateXP()
        }
    }

    private func animateXP() {
        let steps = 24
        let duration = 1.4
        let interval = duration / Double(steps)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(step)) {
                let progress = Double(step) / Double(steps)
                withAnimation(.easeOut(duration: interval * 1.2)) {
                    barFill = CGFloat(progress) * 0.85
                    displayedXP = Int(Double(targetXP) * progress)
                }
                if step == steps {
                    levelBounce = true
                    OnboardingHaptics.primaryCTA()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.15)) {
                        showSparkles = true
                    }
                }
            }
        }
    }
}
