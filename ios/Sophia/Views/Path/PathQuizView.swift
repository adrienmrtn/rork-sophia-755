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
        // The pressable style carries the tap's vibration.
        Button {
            action()
        } label: {
            Image(systemName: "xmark")
                .font(.jakarta(size: 15, weight: .semibold))
                .foregroundStyle(DS.ink)
                .frame(width: 44, height: 44)
                .background(DS.surface, in: Circle())
                .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
                .contentShape(Circle())
        }
        .buttonStyle(.pressable)
    }

    // MARK: - Intro

    private var introView: some View {
        VStack(spacing: 0) {
            HStack {
                closeButton { dismiss() }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)

            GeometryReader { geo in
                ScrollView {
                    introContent
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: geo.size.height)
                }
                .scrollIndicators(.hidden)
            }

            introButtons
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .dsStagger(3)
        }
    }

    private var introContent: some View {
        VStack(spacing: 14) {
            introTrophy
                .dsPopIn(delay: 0.05)

            VStack(spacing: 8) {
                Text(String(format: text("path.quiz.title"), level.number))
                    .font(DS.title(.title, .semibold))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.center)
                Text(level.collection.title)
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 16)
            }
            .padding(.top, 4)
            .dsStagger(0)

            rulesCard
                .dsStagger(1)

            if let best = bestResult, best.attempts > 0 {
                bestScoreChip(best)
                    .dsStagger(2)
            }
        }
        .frame(maxWidth: 520)
    }

    private var introTrophy: some View {
        ZStack {
            Circle()
                .fill(PathCardPalette.goldTint)
                .frame(width: 132, height: 132)
            Circle()
                .fill(PathPalette.gold)
                .frame(width: 100, height: 100)
            Image(systemName: "trophy.fill")
                .font(.jakarta(size: 42, weight: .semibold))
                .foregroundStyle(Color.white)
        }
        .accessibilityHidden(true)
    }

    private func bestScoreChip(_ best: PathLevelResult) -> some View {
        HStack(spacing: 6) {
            Image(systemName: best.isPassed ? "checkmark.seal.fill" : "chart.bar.fill")
                .font(.jakarta(size: 12, weight: .semibold))
                .foregroundStyle(best.isPassed ? DS.success : DS.accent)
            Text(String(format: text("path.quiz.bestScore"), best.bestCorrect, best.bestTotal))
                .font(DS.sans(.footnote, .bold))
                .monospacedDigit()
                .foregroundStyle(best.isPassed ? DS.success : DS.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            best.isPassed ? DS.successTint : DS.accentTint,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    private var introButtons: some View {
        // Both button styles vibrate on the press: no vibration is added here.
        VStack(spacing: 10) {
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
                dismiss()
            } label: {
                Text(text("path.quiz.later"))
            }
            .buttonStyle(DSSecondaryButtonStyle())
        }
        .frame(maxWidth: 520)
    }

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
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
        .dsCard(padding: 16)
    }

    private func ruleRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.jakarta(size: 13, weight: .semibold))
                .foregroundStyle(DS.accent)
                .frame(width: 30, height: 30)
                .background(DS.accentTint, in: Circle())
            Text(text)
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 5)
        }
    }

    // MARK: - Session

    private func startQuiz() {
        // Called from primary buttons only, whose style already vibrates on the press.
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
        phase = .questions
        AnalyticsService.shared.log(
            .quizStart,
            props: ["context": "path", "level": .string(level.collection.id), "total": .int(items.count)]
        )
    }

    private var questionsView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                closeButton { showLeaveConfirm = true }

                DSSegmentedProgress(
                    total: total,
                    filled: currentIndex + (answeredCurrent ? 1 : 0),
                    height: 6,
                    spacing: 3
                )

                Text("\(currentIndex + 1)/\(total)")
                    .font(DS.sans(.caption, .bold))
                    .foregroundStyle(DS.inkSecondary)
                    .monospacedDigit()
                    .fixedSize()

                correctPill
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 4)

            if items.indices.contains(currentIndex) {
                let item = items[currentIndex]
                QuizQuestionPane(
                    question: item.question,
                    subject: item.course.subject,
                    sourceTitle: item.course.title,
                    isLast: currentIndex == total - 1,
                    onAnswered: { points, fullyCorrect in
                        AnalyticsService.shared.log(
                            .quizAnswer,
                            courseId: item.course.id,
                            props: [
                                "question_id": .string(item.question.id),
                                "context": "path",
                                "correct": .bool(fullyCorrect),
                                "points": .int(points),
                                "max_points": .int(item.question.maxPoints),
                            ]
                        )
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
        .animation(DS.Motion.reveal, value: currentIndex)
    }

    private var correctPill: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark")
                .font(.jakarta(size: 10, weight: .heavy))
            Text("\(correctCount)")
                .font(DS.sans(.footnote, .heavy))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: false))
        }
        .foregroundStyle(DS.success)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(DS.successTint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .scaleEffect(counterBump ? 1.18 : 1)
        .animation(DS.Motion.pop, value: counterBump)
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
        phase = .result
        AnalyticsService.shared.log(
            .quizComplete,
            props: [
                "context": "path",
                "level": .string(level.collection.id),
                "correct": .int(correctCount),
                "total": .int(total),
                "passed": .bool(passed),
            ]
        )
    }

    // MARK: - Result

    private var resultView: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 12) {
                        Spacer(minLength: 20)

                        scoreBadge

                        resultTexts
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
                .frame(maxWidth: 520)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .opacity(resultAppeared ? 1 : 0)
                .offset(y: resultAppeared ? 0 : 12)
        }
        .onAppear {
            startResultAnimations()
        }
    }

    private var resultTexts: some View {
        VStack(spacing: 12) {
            Text(didPass ? String(format: text("path.quiz.passed.title"), level.number) : text("path.quiz.failed.title"))
                .font(DS.title(.title2, .semibold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 8)

            scoreLine

            Text(resultSubtitle)
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)

            if didPass, let award = awardResult, award.awardedXP > 0 {
                xpChip(award.awardedXP)
                    .dsPopIn(delay: 1.3)
            }
        }
    }

    /// "14 / 20": the first number counts up (and ticks) once the screen is in.
    private var scoreLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            DSCountUp(
                value: displayedCorrect,
                duration: 0.8,
                font: .jakarta(size: 44, weight: .heavy),
                color: DS.ink
            )
            Text("/ \(total)")
                .font(.jakarta(size: 44, weight: .heavy))
                .foregroundStyle(DS.ink)
                .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(correctCount) / \(total)"))
    }

    private func xpChip(_ amount: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.jakarta(size: 12, weight: .semibold))
            Text(String(format: text("cards.globalXP"), amount))
                .font(DS.sans(.subheadline, .heavy))
                .monospacedDigit()
        }
        .foregroundStyle(PathCardPalette.goldInk)
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(PathCardPalette.goldTint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var scoreBadge: some View {
        ZStack {
            Circle()
                .stroke(DS.hairline, lineWidth: 10)
                .frame(width: 140, height: 140)
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(didPass ? PathPalette.gold : DS.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))
            // The pass mark, so the ring reads as "this far to go".
            Circle()
                .fill(DS.inkTertiary)
                .frame(width: 8, height: 8)
                .offset(y: -70)
                .rotationEffect(.degrees(360 * Double(passMark) / Double(max(total, 1))))
            Image(systemName: didPass ? "trophy.fill" : "arrow.counterclockwise")
                .font(.jakarta(size: didPass ? 56 : 46, weight: .semibold))
                .foregroundStyle(didPass ? PathPalette.gold : DS.inkSecondary)
                .scaleEffect(badgeScale)
        }
        .frame(width: 150, height: 150)
        .modifier(PathShakeEffect(shakes: failShake, amplitude: 9))
        .opacity(resultAppeared ? 1 : 0)
        .accessibilityHidden(true)
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
        // The button styles vibrate on the press: no vibration is added here.
        if didPass {
            Button {
                finishAfterPass()
            } label: {
                HStack(spacing: 8) {
                    Text(text("common.continue"))
                    Image(systemName: "arrow.forward")
                }
            }
            .buttonStyle(DSPrimaryButtonStyle())
        } else {
            VStack(spacing: 10) {
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

        // The score counts up with the ring: `DSCountUp` runs (and ticks) when its value changes.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            guard phase == .result else { return }
            displayedCorrect = target
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
            guard phase == .result else { return }
            if didPass {
                Haptics.celebrate()
                withAnimation(DS.Motion.pop) {
                    badgeScale = 1.12
                }
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        badgeScale = 1
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.4) {
                    showConfetti = false
                }
            } else {
                Haptics.error()
                withAnimation(.linear(duration: 0.45)) {
                    failShake += 1
                }
            }
        }
    }
}
