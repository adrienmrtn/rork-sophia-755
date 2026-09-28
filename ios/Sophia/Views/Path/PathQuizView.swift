import SwiftUI

/// End-of-level quiz of the learning path: a fresh draw of questions mixed from the level's
/// courses, passed with strictly more than half of them fully right. Attempts are unlimited
/// and free; passing for the first time opens the next level and grants global XP once.
struct PathQuizView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss
    let level: PathLevel
    let isLastLevel: Bool
    let progressManager: ProgressManager

    private struct Item: Identifiable {
        let course: Course
        let question: ShuffledQuestion
        var id: String { question.id }
    }

    private enum Phase {
        case intro, questions, result
    }

    @State private var phase: Phase = .intro
    @State private var items: [Item] = []
    @State private var currentIndex = 0
    @State private var correctCount = 0
    @State private var answeredCurrent = false
    @State private var counterBump = false
    @State private var didPass = false
    @State private var newlyPassed = false
    @State private var awardResult: GlobalXPAwardResult? = nil
    @State private var showRankUp = false
    @State private var showLeaveConfirm = false
    @State private var introAppeared = false

    // Result screen animation.
    @State private var resultAppeared = false
    @State private var ringProgress: CGFloat = 0
    @State private var displayedCorrect = 0
    @State private var showConfetti = false
    @State private var badgeScale: CGFloat = 0.6
    @State private var failShake: CGFloat = 0

    private var total: Int { items.count }
    private var passMark: Int { LearningPathRules.passMark(total: total) }

    private var plannedQuestionCount: Int {
        LearningPathRules.quizQuestionCount(for: level.collection)
    }

    private var bestResult: PathLevelResult? {
        progressManager.pathLevelResult(for: level.collection.id)
    }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            switch phase {
            case .intro:
                introView
                    .transition(.opacity)
            case .questions:
                questionsView
                    .transition(.opacity)
            case .result:
                resultView
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.96).combined(with: .opacity),
                        removal: .opacity
                    ))
            }

            if showConfetti {
                PathConfettiBurst(colors: confettiColors, pieceCount: 130, duration: 3.2, origin: CGPoint(x: 0.5, y: 0.3))
                    .ignoresSafeArea()
                    .zIndex(30)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: phase)
        .fullScreenCover(isPresented: $showRankUp) {
            if let pending = progressManager.pendingGlobalRankUp() {
                GlobalRankUpCelebrationView(
                    previousRank: pending.previous,
                    newRank: pending.new,
                    newLevel: pending.newLevel,
                    onContinue: {
                        progressManager.clearPendingGlobalRankUp()
                        showRankUp = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            dismiss()
                        }
                    }
                )
                .sophiaColorScheme()
            }
        }
        .confirmationDialog(
            languageManager.text("path.quiz.leave.title"),
            isPresented: $showLeaveConfirm,
            titleVisibility: .visible
        ) {
            Button(languageManager.text("path.quiz.leave.confirm"), role: .destructive) {
                dismiss()
            }
            Button(languageManager.text("path.quiz.leave.cancel"), role: .cancel) {}
        } message: {
            Text(languageManager.text("path.quiz.leave.body"))
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.05)) {
                introAppeared = true
            }
        }
        .sophiaColorScheme()
    }

    private func text(_ key: String) -> String {
        languageManager.text(key)
    }

    private var confettiColors: [Color] {
        var colors: [Color] = [PathPalette.gold, PathPalette.gold.mix(with: .white, by: 0.3), DS.accentSoft]
        var seen = Set<String>()
        for node in level.nodes {
            guard let subject = node.course?.subject, !seen.contains(subject.storageKey) else { continue }
            seen.insert(subject.storageKey)
            colors.append(PathPalette.tint(for: subject))
        }
        return colors
    }

    private func closeButton(action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
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

    // MARK: - Intro

    private var introView: some View {
        VStack(spacing: 0) {
            HStack {
                closeButton { dismiss() }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            ScrollView {
                VStack(spacing: 22) {
                    Spacer(minLength: 12)

                    ZStack {
                        Circle()
                            .fill(PathPalette.gold.opacity(0.16))
                            .frame(width: 148, height: 148)
                        Circle()
                            .fill(PathPalette.goldGradient)
                            .frame(width: 112, height: 112)
                        Image(systemName: "trophy.fill")
                            .font(.jakarta(size: 48, weight: .semibold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
                    }
                    .scaleEffect(introAppeared ? 1 : 0.7)
                    .opacity(introAppeared ? 1 : 0)

                    VStack(spacing: 8) {
                        Text(String(format: text("path.quiz.title"), level.number))
                            .font(DS.title(.title, .semibold))
                            .foregroundStyle(DS.ink)
                            .multilineTextAlignment(.center)
                        Text(level.collection.title)
                            .font(DS.sans(.subheadline))
                            .foregroundStyle(DS.inkSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }
                    .opacity(introAppeared ? 1 : 0)
                    .offset(y: introAppeared ? 0 : 12)

                    rulesCard
                        .padding(.horizontal, 20)
                        .opacity(introAppeared ? 1 : 0)
                        .offset(y: introAppeared ? 0 : 16)

                    if let best = bestResult, best.attempts > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: best.isPassed ? "checkmark.seal.fill" : "chart.bar.fill")
                                .font(.jakarta(size: 12, weight: .medium))
                            Text(String(format: text("path.quiz.bestScore"), best.bestCorrect, best.bestTotal))
                                .font(DS.sans(.caption, .semibold))
                                .monospacedDigit()
                        }
                        .foregroundStyle(best.isPassed ? DS.success : DS.accentSoft)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(best.isPassed ? DS.successTint : DS.accentTint, in: Capsule())
                        .opacity(introAppeared ? 1 : 0)
                    }

                    Spacer(minLength: 20)
                }
            }
            .scrollIndicators(.hidden)

            VStack(spacing: 12) {
                Button {
                    startQuiz()
                } label: {
                    HStack(spacing: 8) {
                        Text(text("path.quiz.go"))
                        Image(systemName: "arrow.forward")
                    }
                }
                .buttonStyle(DSPrimaryButtonStyle())

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
                } label: {
                    Text(text("path.quiz.later"))
                }
                .buttonStyle(DSSecondaryButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .opacity(introAppeared ? 1 : 0)
            .offset(y: introAppeared ? 0 : 12)
        }
    }

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            ruleRow(
                icon: "shuffle",
                text: String(format: text("path.quiz.rule.questions"), plannedQuestionCount, level.courseCount)
            )
            ruleRow(
                icon: "target",
                text: String(format: text("path.quiz.rule.pass"), LearningPathRules.passMark(total: plannedQuestionCount))
            )
            ruleRow(icon: "arrow.counterclockwise", text: text("path.quiz.rule.retries"))
        }
        .dsCard()
    }

    private func ruleRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.jakarta(size: 14, weight: .medium))
                .foregroundStyle(DS.accentSoft)
                .frame(width: 32, height: 32)
                .background(DS.accentTint, in: Circle())
            Text(text)
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 5)
        }
    }

    // MARK: - Session

    private func startQuiz() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let drawn = PathQuizBuilder.questions(for: level.collection)
        guard !drawn.isEmpty else {
            dismiss()
            return
        }
        items = drawn.map { Item(course: $0.course, question: QuizShuffler.shuffle($0.question)) }
        currentIndex = 0
        correctCount = 0
        answeredCurrent = false
        didPass = false
        newlyPassed = false
        awardResult = nil
        resetResultAnimation()
        AnalyticsService.trackPathQuizStarted(
            collectionId: level.collection.id,
            level: level.number,
            questionCount: items.count
        )
        phase = .questions
    }

    private var questionsView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                closeButton { showLeaveConfirm = true }

                CalmProgressBar(
                    fraction: Double(currentIndex + (answeredCurrent ? 1 : 0)) / Double(max(total, 1)),
                    height: 6
                )
                .animation(.spring(response: 0.4), value: currentIndex)
                .animation(.spring(response: 0.4), value: answeredCurrent)

                Text("\(currentIndex + 1)/\(total)")
                    .font(DS.sans(.caption, .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .monospacedDigit()
                    .fixedSize()

                correctPill
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 4)

            if items.indices.contains(currentIndex) {
                let item = items[currentIndex]
                QuizQuestionPane(
                    question: item.question,
                    subject: item.course.subject,
                    sourceTitle: item.course.title,
                    isLast: currentIndex == total - 1,
                    onAnswered: { _, fullyCorrect in
                        handleAnswer(fullyCorrect: fullyCorrect)
                    },
                    onContinue: {
                        advance()
                    }
                )
                .id(item.id)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: currentIndex)
    }

    private var correctPill: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark")
                .font(.jakarta(size: 10, weight: .bold))
            Text("\(correctCount)")
                .font(DS.sans(.caption, .bold))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: false))
        }
        .foregroundStyle(DS.success)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(DS.successTint, in: Capsule())
        .scaleEffect(counterBump ? 1.18 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: counterBump)
        .accessibilityLabel(String(format: text("path.quiz.correctSoFar"), correctCount))
    }

    private func handleAnswer(fullyCorrect: Bool) {
        answeredCurrent = true
        guard fullyCorrect else { return }
        withAnimation(.snappy) {
            correctCount += 1
        }
        counterBump = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            counterBump = false
        }
    }

    private func advance() {
        if currentIndex < total - 1 {
            currentIndex += 1
            answeredCurrent = false
        } else {
            finishQuiz()
        }
    }

    private func finishQuiz() {
        let passed = LearningPathRules.isPassing(correct: correctCount, total: total)
        didPass = passed
        newlyPassed = progressManager.recordPathQuizAttempt(
            collectionId: level.collection.id,
            correct: correctCount,
            total: total,
            passed: passed
        )
        if newlyPassed {
            awardResult = progressManager.awardGlobalXP(
                reason: .pathLevelPassed(collectionId: level.collection.id),
                amount: ProgressManager.pathLevelPassedXP
            )
        } else {
            awardResult = nil
        }
        AnalyticsService.trackPathQuizCompleted(
            collectionId: level.collection.id,
            level: level.number,
            correct: correctCount,
            total: total,
            passed: passed,
            attempt: bestResult?.attempts ?? 1
        )
        phase = .result
    }

    // MARK: - Result

    private var resultView: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 22) {
                        Spacer(minLength: 20)

                        scoreBadge

                        VStack(spacing: 10) {
                            Text(didPass ? String(format: text("path.quiz.passed.title"), level.number) : text("path.quiz.failed.title"))
                                .font(DS.title(.title, .semibold))
                                .foregroundStyle(DS.ink)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)

                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("\(displayedCorrect)")
                                    .font(.jakarta(size: 48, weight: .semibold))
                                    .foregroundStyle(DS.ink)
                                    .monospacedDigit()
                                    .contentTransition(.numericText(countsDown: false))
                                Text("/ \(total)")
                                    .font(DS.title(.title2, .medium))
                                    .foregroundStyle(DS.inkTertiary)
                            }

                            Text(resultSubtitle)
                                .font(DS.sans(.subheadline))
                                .foregroundStyle(DS.inkSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 28)

                            if didPass, let award = awardResult, award.awardedXP > 0 {
                                HStack(spacing: 8) {
                                    Image(systemName: "star.fill")
                                        .font(.jakarta(size: 13, weight: .medium))
                                    Text(String(format: text("cards.globalXP"), award.awardedXP))
                                        .font(DS.sans(.subheadline, .semibold))
                                        .monospacedDigit()
                                }
                                .foregroundStyle(DS.accentSoft)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .background(DS.accentTint, in: Capsule())
                                .padding(.top, 4)
                            }
                        }
                        .opacity(resultAppeared ? 1 : 0)
                        .offset(y: resultAppeared ? 0 : 14)

                        Spacer(minLength: 20)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geo.size.height)
                }
                .scrollIndicators(.hidden)
            }

            resultButtons
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .opacity(resultAppeared ? 1 : 0)
                .offset(y: resultAppeared ? 0 : 12)
        }
        .onAppear {
            startResultAnimations()
        }
    }

    private var scoreBadge: some View {
        ZStack {
            Circle()
                .stroke(DS.hairline, lineWidth: 10)
                .frame(width: 168, height: 168)
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(didPass ? PathPalette.gold : DS.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .frame(width: 168, height: 168)
                .rotationEffect(.degrees(-90))
            // The pass mark, so the ring reads as "this far to go".
            Circle()
                .fill(DS.inkTertiary)
                .frame(width: 8, height: 8)
                .offset(y: -84)
                .rotationEffect(.degrees(360 * Double(passMark) / Double(max(total, 1))))
            ZStack {
                if didPass {
                    Circle().fill(PathPalette.goldGradient)
                } else {
                    Circle().fill(DS.surfaceMuted)
                }
                Image(systemName: didPass ? "trophy.fill" : "arrow.counterclockwise")
                    .font(.jakarta(size: 52, weight: .semibold))
                    .foregroundStyle(didPass ? .white : DS.inkSecondary)
                    .shadow(color: .black.opacity(didPass ? 0.18 : 0), radius: 2, y: 1)
            }
            .frame(width: 132, height: 132)
            .scaleEffect(badgeScale)
        }
        .modifier(PathShakeEffect(shakes: failShake, amplitude: 9))
        .opacity(resultAppeared ? 1 : 0)
    }

    private var resultSubtitle: String {
        if didPass {
            if !newlyPassed { return text("path.quiz.passed.again") }
            return isLastLevel ? text("path.quiz.passed.last") : text("path.quiz.passed.next")
        }
        return String(format: text("path.quiz.failed.body"), passMark, total)
    }

    @ViewBuilder
    private var resultButtons: some View {
        if didPass {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                finishAfterPass()
            } label: {
                HStack(spacing: 8) {
                    Text(text("common.continue"))
                    Image(systemName: "arrow.forward")
                }
            }
            .buttonStyle(DSPrimaryButtonStyle())
        } else {
            VStack(spacing: 12) {
                Button {
                    startQuiz()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text(text("path.quiz.retry"))
                    }
                }
                .buttonStyle(DSPrimaryButtonStyle())

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
                } label: {
                    Text(text("path.quiz.review"))
                }
                .buttonStyle(DSSecondaryButtonStyle())
            }
        }
    }

    private func finishAfterPass() {
        if awardResult?.didRankUp == true || progressManager.pendingGlobalRankUp() != nil {
            showRankUp = true
        } else {
            dismiss()
        }
    }

    private func resetResultAnimation() {
        resultAppeared = false
        ringProgress = 0
        displayedCorrect = 0
        badgeScale = 0.6
        showConfetti = false
    }

    private func startResultAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
            resultAppeared = true
            badgeScale = 1
        }

        let target = correctCount
        let count = max(total, 1)
        withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
            ringProgress = CGFloat(target) / CGFloat(count)
        }

        let steps = max(target, 1)
        for step in 1...steps {
            let delay = 0.3 + Double(step) * (0.8 / Double(steps))
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard step <= target else { return }
                withAnimation(.spring(response: 0.2)) {
                    displayedCorrect = step
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.6)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
            if didPass {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) {
                    badgeScale = 1.12
                }
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        badgeScale = 1
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.4) {
                    showConfetti = false
                }
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                withAnimation(.linear(duration: 0.45)) {
                    failShake += 1
                }
            }
        }
    }
}
