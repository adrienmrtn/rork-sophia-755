import SwiftUI

// MARK: - Phase enum used by CourseView to drive the end-of-course freemium flow.

nonisolated enum CourseEndPhase: Sendable {
    case none
    case completed
    case streak
}

// MARK: - Course Completed (full-screen celebration shown after the last slide in freemium)

struct CourseCompletedView: View {
    @Environment(LanguageManager.self) private var languageManager
    let course: Course
    let progressManager: ProgressManager
    /// XP for this subject BEFORE awarding the +10 course-completion bonus.
    let previousSubjectXP: Int
    /// XP awarded for finishing this course (typically +10, always granted).
    let earnedXP: Int
    /// Global XP reward result for finishing this course (+50 once per course).
    let globalAwardResult: GlobalXPAwardResult?
    /// Whether the locked freemium banner + Mini Quiz CTA are shown.
    let showFreemiumGate: Bool
    let onClose: () -> Void
    let onQuizTapped: () -> Void

    @State private var phase: EndFlowPhaseStep = .celebration
    @State private var appeared: Bool = false
    @State private var showTitle: Bool = false
    @State private var showCard: Bool = false
    @State private var showNote: Bool = false
    @State private var showButtons: Bool = false
    @State private var showLevelUp: Bool = false
    @State private var showGlobalRankUp: Bool = false
    @State private var thumbScale: CGFloat = 0.55
    @State private var displayedXP: Int = 0
    @State private var displayedLevel: Int = 1
    @State private var barFill: CGFloat = 0
    @State private var barShimmer: CGFloat = -80
    @State private var cachedThumb: UIImage?
    @State private var quizButtonShimmer: CGFloat = -100
    @State private var shimmerActive: Bool = false
    @State private var barShimmerActive: Bool = false
    @State private var barFillStarted: Bool = false

    private enum EndFlowPhaseStep {
        case celebration, progression, actions
    }

    private let ink = Color.black
    private let cream = Color(red: 0.984, green: 0.961, blue: 0.918)
    private let pink = Color(red: 1.0, green: 0.553, blue: 0.706)

    private var currentSubjectXP: Int {
        progressManager.xp(for: course.subject)
    }

    private var pastel: Color {
        switch course.subject {
        case .histoire: return Color(red: 1.0, green: 0.86, blue: 0.62)
        case .sciences: return Color(red: 0.70, green: 0.95, blue: 0.80)
        case .litterature: return Color(red: 1.0, green: 0.78, blue: 0.78)
        case .art: return Color(red: 0.66, green: 0.92, blue: 0.96)
        case .mythologie: return Color(red: 0.82, green: 0.78, blue: 1.0)
        case .comprendreLeMonde: return Color(red: 0.74, green: 0.90, blue: 1.0)
        }
    }

    private func tier(for xp: Int) -> (level: Int, lower: Int, upper: Int) {
        ProgressManager.subjectXPTiers.last(where: { xp >= $0.lower }) ?? ProgressManager.subjectXPTiers[0]
    }

    private var animatedXP: Int {
        displayedXP
    }

    private var startLevel: Int {
        tier(for: previousSubjectXP).level
    }

    private var endLevel: Int {
        tier(for: currentSubjectXP).level
    }

    private var didLevelUp: Bool {
        endLevel > startLevel
    }

    private var pendingGlobalRankUp: (previous: GlobalRank, new: GlobalRank, newLevel: Int)? {
        if let globalAwardResult, globalAwardResult.didRankUp {
            return (globalAwardResult.previousRank, globalAwardResult.newRank, globalAwardResult.newLevel)
        }
        return progressManager.pendingGlobalRankUp()
    }

    private func barFraction(for xp: Int) -> CGFloat {
        let t = tier(for: xp)
        if t.level == 5 { return 1.0 }
        let span = max(1, t.upper - t.lower)
        return CGFloat(min(1.0, max(0.0, Double(xp - t.lower) / Double(span))))
    }

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 12)

                thumbnail
                    .scaleEffect(thumbScale)
                    .opacity(appeared ? 1 : 0)

                Spacer(minLength: 18)

                VStack(spacing: 8) {
                    Text(languageManager.text("course.completed"))
                        .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : 14)

                Spacer(minLength: 20)

                if phase != .celebration {
                    progressionCard
                        .padding(.horizontal, 20)
                        .opacity(showCard ? 1 : 0)
                        .offset(y: showCard ? 0 : 18)
                        .transition(.opacity.combined(with: .offset(y: 18)))
                }

                if showFreemiumGate && phase == .actions {
                    freemiumNote
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .opacity(showNote ? 1 : 0)
                        .offset(y: showNote ? 0 : 10)
                }

                Spacer(minLength: 20)

                if phase == .actions {
                    actionButtons
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                        .opacity(showButtons ? 1 : 0)
                        .offset(y: showButtons ? 0 : 14)
                }
            }
        }
        .fullScreenCover(isPresented: $showLevelUp) {
            LevelUpCelebrationView(
                subject: course.subject,
                previousLevel: startLevel,
                newLevel: endLevel,
                onContinue: {
                    showLevelUp = false
                    revealAfterSubjectLevelUp()
                }
            )
        }
        .fullScreenCover(isPresented: $showGlobalRankUp) {
            if let pendingGlobalRankUp {
                GlobalRankUpCelebrationView(
                    previousRank: pendingGlobalRankUp.previous,
                    newRank: pendingGlobalRankUp.new,
                    newLevel: pendingGlobalRankUp.newLevel,
                    onContinue: {
                        progressManager.clearPendingGlobalRankUp()
                        showGlobalRankUp = false
                        revealActions()
                    }
                )
            }
        }
        .onAppear {
            cachedThumb = CourseImageMap.loadImage(for: course.id)
            displayedXP = previousSubjectXP
            displayedLevel = startLevel
            barFill = barFraction(for: previousSubjectXP)
            shimmerActive = true
            ShimmerAnimation.runLoop(offset: $quizButtonShimmer) { shimmerActive }
            runOpeningSequence()
        }
        .onDisappear {
            shimmerActive = false
            barShimmerActive = false
        }
    }

    private func runOpeningSequence() {
        // Phase 1 — celebration
        withAnimation(.spring(response: 0.85, dampingFraction: 0.78)) {
            appeared = true
            thumbScale = 1.0
            showTitle = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            phase = .progression
            withAnimation(.spring(response: 0.85, dampingFraction: 0.82)) {
                showCard = true
            }
            // Bar fill starts 0.5s after card appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateProgression()
            }
        }
    }

    private func animateProgression() {
        guard !barFillStarted else { return }
        barFillStarted = true
        barShimmerActive = true
        ShimmerAnimation.runLoop(offset: $barShimmer) { barShimmerActive }

        XPProgressAnimator.animate(
            from: previousSubjectXP,
            to: currentSubjectXP,
            setXP: { displayedXP = $0 },
            setLevel: { displayedLevel = $0 },
            setBarFill: { fill, animated in
                if animated {
                    barFill = fill
                } else {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) { barFill = fill }
                }
            },
            haptic: {
                XPProgressAnimator.progressionHaptic(intensity: 0.62)
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.35)
            },
            completion: {
                barShimmerActive = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                if didLevelUp {
                    showLevelUp = true
                } else if pendingGlobalRankUp != nil {
                    showGlobalRankUp = true
                } else {
                    revealActions()
                }
            }
        )
    }

    private func revealAfterSubjectLevelUp() {
        if pendingGlobalRankUp != nil {
            showGlobalRankUp = true
        } else {
            revealActions()
        }
    }

    private func revealActions() {
        phase = .actions
        if showFreemiumGate {
            withAnimation(.easeOut(duration: 0.55)) {
                showNote = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.75, dampingFraction: 0.82)) {
                showButtons = true
            }
        }
    }

    // MARK: Thumbnail

    private var thumbnail: some View {
        ZStack {
            ZStack {
                pastel
                if let img = cachedThumb {
                    Color.clear
                        .overlay {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                        }
                        .clipped()
                        .allowsHitTesting(false)
                } else {
                    SubjectBadgeView(subject: course.subject, emojiSize: 56, cornerRadius: 0)
                }
            }
            .frame(width: 160, height: 160)
            .clipShape(.rect(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(ink, lineWidth: 3)
            }
            .overlay(alignment: .bottomTrailing) {
                ZStack {
                    Circle().fill(pink)
                        .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(ink)
                }
                .frame(width: 44, height: 44)
                .offset(x: 10, y: 10)
            }
        }
        .frame(width: 160, height: 160)
        .background(alignment: .top) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(ink)
                .frame(width: 160, height: 160)
                .offset(y: 6)
        }
        .padding(.bottom, 6)
    }

    // MARK: Progression card

    private var progressionCard: some View {
        let tierNow = tier(for: animatedXP)
        let xpToNext = max(0, tierNow.upper - animatedXP)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                SubjectBadgeView(subject: course.subject, emojiSize: 22, cornerRadius: 10)
                    .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(course.subject.localizedShortName(language: languageManager.current))
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink)
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(ink.opacity(0.7))
                        Text("\(displayedXP) XP")
                            .font(.system(.caption, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink.opacity(0.55))
                            .monospacedDigit()
                        if tierNow.level < 5 {
                            Text(String(format: languageManager.text("common.xpBeforeNext"), xpToNext, tierNow.level + 1))
                                .font(.system(.caption, design: .rounded, weight: .heavy))
                                .foregroundStyle(ink.opacity(0.4))
                        }
                    }
                }
                Spacer()
                Text(String(format: languageManager.text("common.levelShort"), displayedLevel))
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .tracking(0.6)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(ink, in: Capsule())
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(white: 0.94))
                        .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
                    Capsule()
                        .fill(pastel)
                        .overlay {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.45), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .mask {
                                    Rectangle()
                                        .frame(width: 60, height: 20)
                                        .offset(x: barShimmer)
                                }
                                .allowsHitTesting(false)
                        }
                        .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
                        .frame(width: geo.size.width * barFill)
                }
            }
            .frame(height: 16)

            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(ink)
                Text(String(format: languageManager.text("common.xpEarned"), earnedXP))
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(pastel, in: Capsule())
            .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
        }
        .padding(16)
        .brutalOnboardingCard(depth: 4, corner: 20)
    }

    // MARK: Freemium note

    private var freemiumNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(ink)
            Text(languageManager.text("course.dailyFreeDone"))
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white, in: Capsule())
        .overlay { Capsule().strokeBorder(ink, lineWidth: 2.5) }
    }

    // MARK: Action buttons (X close · Mini Quiz)

    private var actionButtons: some View {
        HStack(spacing: 14) {
            // X close
            Button {
                let g = UIImpactFeedbackGenerator(style: .medium)
                g.impactOccurred()
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(ink)
                    .frame(width: 64, height: 60)
            }
            .buttonStyle(EndFlowCircleButtonStyle(fill: .white))

            // Mini Quiz
            Button {
                let g = UIImpactFeedbackGenerator(style: .medium)
                g.impactOccurred()
                onQuizTapped()
            } label: {
                HStack(spacing: 8) {
                    if showFreemiumGate {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .heavy))
                    }
                    Text(languageManager.text("common.miniQuiz"))
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .heavy))
                }
                .foregroundStyle(ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            }
            .buttonStyle(DuolingoButtonStyle(fill: pink, shimmer: quizButtonShimmer))
        }
    }

}

// MARK: - Streak Celebration screen

struct StreakCelebrationView: View {
    @Environment(LanguageManager.self) private var languageManager
    let streak: Int
    let subject: Subject
    let lastActiveDate: String?
    let onReturnHome: () -> Void

    @State private var appeared: Bool = false
    @State private var flameScale: CGFloat = 0.4
    @State private var flameRotation: Double = -8
    @State private var numberAppeared: Bool = false
    @State private var displayedStreak: Int = 0

    private let ink = Color.black
    private let cream = Color(red: 0.984, green: 0.961, blue: 0.918)
    private let pink = Color(red: 1.0, green: 0.553, blue: 0.706)
    private let orange = Color(red: 1.0, green: 0.55, blue: 0.18)
    private let yellow = Color(red: 1.0, green: 0.84, blue: 0.35)

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 16)

                flameView
                    .scaleEffect(flameScale)
                    .rotationEffect(.degrees(flameRotation))

                Spacer(minLength: 8)

                VStack(spacing: 4) {
                    Text("\(displayedStreak)")
                        .font(.system(size: 96, weight: .heavy, design: .rounded))
                        .foregroundStyle(ink)
                        .contentTransition(.numericText())
                        .scaleEffect(numberAppeared ? 1 : 0.5)
                        .opacity(numberAppeared ? 1 : 0)

                    Text(streak <= 1 ? languageManager.text("course.streak.day") : languageManager.text("course.streak.days"))
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink)
                        .opacity(numberAppeared ? 1 : 0)
                }

                Text(String(format: languageManager.text("course.streak.message"), subject.localizedShortName(language: languageManager.current)))
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 14)
                    .opacity(appeared ? 1 : 0)

                Spacer(minLength: 22)

                weekStrip
                    .padding(.horizontal, 22)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                Spacer(minLength: 18)

                Text(languageManager.text("course.streak.onTrack"))
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(ink)
                    .opacity(appeared ? 1 : 0)

                Spacer(minLength: 20)

                Button {
                    let g = UIImpactFeedbackGenerator(style: .medium)
                    g.impactOccurred()
                    onReturnHome()
                } label: {
                    HStack(spacing: 8) {
                        Text(languageManager.text("common.backHome"))
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                        Image(systemName: "house.fill")
                            .font(.system(size: 14, weight: .heavy))
                    }
                    .foregroundStyle(ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }
                .buttonStyle(EndFlowPillButtonStyle(fill: pink))
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
            }
        }
        .onAppear {
            displayedStreak = max(0, streak - 1)

            withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.05)) {
                flameScale = 1.0
                flameRotation = 0
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
                numberAppeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.snappy) { displayedStreak = streak }
                let g = UINotificationFeedbackGenerator()
                g.notificationOccurred(.success)
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.55)) {
                appeared = true
            }
            // Idle flicker
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(0.6)) {
                flameScale = 1.06
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true).delay(0.6)) {
                flameRotation = 4
            }
        }
    }

    private var flameView: some View {
        ZStack {
            // Outer glow plate (peach circle for brutalist depth)
            Circle()
                .fill(yellow.opacity(0.5))
                .frame(width: 200, height: 200)
                .blur(radius: 30)

            Image(systemName: "flame.fill")
                .font(.system(size: 140, weight: .heavy))
                .foregroundStyle(
                    LinearGradient(
                        colors: [orange, yellow],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .symbolEffect(.variableColor.iterative.reversing)
                .shadow(color: orange.opacity(0.45), radius: 18, y: 8)
        }
        .frame(height: 200)
    }

    private var weekStrip: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayLetters = ["L", "M", "M", "J", "V", "S", "D"]
        let weekday = calendar.component(.weekday, from: today)
        let mondayOffset = ((weekday + 5) % 7)
        let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: today) ?? today

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        return HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { i in
                let date = calendar.date(byAdding: .day, value: i, to: monday) ?? today
                let isToday = calendar.isDate(date, inSameDayAs: today)
                let isFuture = date > today
                let dateStr = fmt.string(from: date)

                let isDone: Bool = {
                    guard let last = lastActiveDate,
                          let lastDate = fmt.date(from: last) else { return false }
                    let daysFromLast = calendar.dateComponents([.day], from: date, to: lastDate).day ?? 999
                    if isFuture { return false }
                    return dateStr <= last && daysFromLast >= 0 && daysFromLast < streak
                }()

                VStack(spacing: 6) {
                    Text(dayLetters[i])
                        .font(.system(.caption2, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink.opacity(isFuture ? 0.25 : 0.55))
                    ZStack {
                        Circle()
                            .fill(isDone ? ink : Color.white)
                            .overlay { Circle().strokeBorder(ink, lineWidth: 2) }
                        if isDone {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundStyle(.white)
                        } else if isToday {
                            Circle().fill(ink).frame(width: 7, height: 7)
                        }
                    }
                    .frame(width: 36, height: 36)
                    .opacity(isFuture ? 0.4 : 1)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Local button styles for the end-of-course flow

private struct EndFlowPillButtonStyle: ButtonStyle {
    let fill: Color
    private let depth: CGFloat = 5

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Capsule().fill(fill)
                    .overlay { Capsule().strokeBorder(.black, lineWidth: 3) }
            )
            .offset(y: configuration.isPressed ? depth : 0)
            .background(
                Capsule().fill(Color.black).offset(y: depth)
            )
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: configuration.isPressed)
            .padding(.bottom, depth)
    }
}

private struct EndFlowCircleButtonStyle: ButtonStyle {
    let fill: Color
    private let depth: CGFloat = 5

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Capsule().fill(fill)
                    .overlay { Capsule().strokeBorder(.black, lineWidth: 3) }
            )
            .offset(y: configuration.isPressed ? depth : 0)
            .background(
                Capsule().fill(Color.black).offset(y: depth)
            )
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: configuration.isPressed)
            .padding(.bottom, depth)
    }
}
