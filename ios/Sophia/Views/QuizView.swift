import SwiftUI

struct QuizView: View {
    @Environment(LanguageManager.self) private var languageManager
    let course: Course
    let progressManager: ProgressManager
    var initialCollectionEvents: [CollectionProgressEvent] = []
    let onReturnHome: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var currentQuestionIndex: Int = 0

    // Per-question answer state — only the fields relevant to the current question's
    // type are meaningful at any given time; the rest sit at their default.
    @State private var selectedOptionIndex: Int? = nil          // .mcq / .trueFalse
    // .chronological — `chronoSlots[position]` is the display-slot index placed at
    // that position (nil = still empty); `chronoPool` holds the not-yet-placed ones.
    @State private var chronoSlots: [Int?] = []
    @State private var chronoPool: [Int] = []
    @State private var sliderValue: Double = 0                   // .numericSlider / .percentageSlider
    @State private var hasAnswered: Bool = false
    /// Quand la question en cours s'est affichée, pour le temps de réponse de `quiz_answer`.
    @State private var questionShownAt = Date()
    @State private var currentQuestionPoints: Int = 0

    @State private var totalPointsEarned: Int = 0
    @State private var isFinished: Bool = false
    @State private var showFeedback: Bool = false
    @State private var showXPProgress: Bool = false
    @State private var showStreak: Bool = false
    @State private var streakBefore: Int = 0
    @State private var completedBefore: Int = 0
    @State private var subjectXPBefore: Int = 0
    @State private var resultAppeared: Bool = false
    @State private var scoreAnimated: Int = 0
    @State private var starsRevealed: Int = 0
    @State private var ringProgress: CGFloat = 0
    @State private var xpScreenAppeared: Bool = false
    @State private var xpBarFill: CGFloat = 0
    @State private var displayedXP: Int = 0
    @State private var xpButtonAppeared: Bool = false
    @State private var showLevelUpCelebration: Bool = false
    @State private var showGlobalRankUpCelebration: Bool = false
    @State private var cachedCourseThumb: UIImage?
    @State private var shuffledQuestions: [ShuffledQuestion] = []
    @State private var questionAppeared: Bool = false
    @State private var comboCount: Int = 0
    @State private var showCombo: Bool = false
    @State private var xpEarned: Int = 0
    @State private var showXPPopup: Bool = false
    @State private var popupXPAmount: Int = 0
    @State private var globalQuizAwardResult: GlobalXPAwardResult?
    @State private var courseWasCompletedBeforeQuiz: Bool = false
    @State private var pendingCollectionEvents: [CollectionProgressEvent] = []
    @State private var currentCollectionEvent: CollectionProgressEvent?
    @State private var collectionCompletionAwardResult: GlobalXPAwardResult?
    @State private var showCollectionProgress: Bool = false
    @State private var showCollectionCompleted: Bool = false
    @State private var showCollectionRankUp: Bool = false
    @State private var rewardSteps: [PostCompletionRewardStep] = []
    @State private var showRewardFlow: Bool = false
    /// Confettis du résultat, quand le quiz finit sur trois étoiles.
    @State private var showResultConfetti: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Fixed XP bonus awarded when the quiz is fully completed.
    private let quizCompletionXPBonus: Int = 10

    private var currentQuestion: ShuffledQuestion {
        shuffledQuestions[currentQuestionIndex]
    }

    /// Valid only for `.mcq` / `.trueFalse` — whether the tapped option is the correct one.
    private var isCorrect: Bool {
        selectedOptionIndex == currentQuestion.correctIndex
    }

    private var isFullyCorrect: Bool {
        currentQuestionPoints == currentQuestion.maxPoints
    }

    private var progressValue: Double {
        Double(currentQuestionIndex + 1) / Double(shuffledQuestions.count)
    }

    private var maxPossiblePoints: Int {
        shuffledQuestions.reduce(0) { $0 + $1.maxPoints }
    }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            if showStreak {
                StreakCelebrationView(
                    streak: progressManager.streak,
                    subject: course.subject,
                    lastActiveDate: progressManager.progress.lastActiveDate,
                    onReturnHome: { onReturnHome() }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else if showXPProgress {
                xpProgressionView
                    .transition(.opacity)
            } else if isFinished {
                resultView
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.96).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else if !shuffledQuestions.isEmpty {
                questionView
            }

            if showRewardFlow {
                PostCompletionRewardFlowView(
                    steps: rewardSteps,
                    progressManager: progressManager,
                    onFinished: {
                        showRewardFlow = false
                        onReturnHome()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.985)))
                .zIndex(100)
            }
        }
        .fullScreenCover(isPresented: $showLevelUpCelebration) {
            LevelUpCelebrationView(
                subject: course.subject,
                previousLevel: levelBefore,
                newLevel: levelAfter,
                onContinue: {
                    showLevelUpCelebration = false
                    revealAfterSubjectLevelUp()
                }
            )
            .sophiaColorScheme()
        }
        .fullScreenCover(isPresented: $showGlobalRankUpCelebration) {
            if let pendingGlobalRankUp {
                GlobalRankUpCelebrationView(
                    previousRank: pendingGlobalRankUp.previous,
                    newRank: pendingGlobalRankUp.new,
                    newLevel: pendingGlobalRankUp.newLevel,
                    onContinue: {
                        progressManager.clearPendingGlobalRankUp()
                        globalQuizAwardResult = nil
                        showGlobalRankUpCelebration = false
                        revealXPContinueButton()
                    }
                )
                .sophiaColorScheme()
            }
        }
        .fullScreenCover(isPresented: $showCollectionProgress) {
            if let currentCollectionEvent {
                CollectionProgressCelebrationView(event: currentCollectionEvent) {
                    showCollectionProgress = false
                    if currentCollectionEvent.didCompleteCollection {
                        collectionCompletionAwardResult = progressManager.awardGlobalXP(
                            reason: .collectionCompleted(id: currentCollectionEvent.collection.id),
                            amount: progressManager.collectionCompletionXP(for: currentCollectionEvent.collection)
                        )
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            showCollectionCompleted = true
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            continueAfterQuizCompletion()
                        }
                    }
                }
                .sophiaColorScheme()
            }
        }
        .fullScreenCover(isPresented: $showCollectionCompleted) {
            if let currentCollectionEvent {
                CollectionCompletedCelebrationView(
                    event: currentCollectionEvent,
                    awardedXP: collectionCompletionAwardResult?.awardedXP ?? 0,
                    onContinue: {
                        showCollectionCompleted = false
                        if collectionCompletionAwardResult?.didRankUp == true || progressManager.pendingGlobalRankUp() != nil {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                showCollectionRankUp = true
                            }
                        } else {
                            collectionCompletionAwardResult = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                continueAfterQuizCompletion()
                            }
                        }
                    }
                )
                .sophiaColorScheme()
            }
        }
        .fullScreenCover(isPresented: $showCollectionRankUp) {
            if let pending = progressManager.pendingGlobalRankUp() {
                GlobalRankUpCelebrationView(
                    previousRank: pending.previous,
                    newRank: pending.new,
                    newLevel: pending.newLevel,
                    onContinue: {
                        progressManager.clearPendingGlobalRankUp()
                        collectionCompletionAwardResult = nil
                        showCollectionRankUp = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            continueAfterQuizCompletion()
                        }
                    }
                )
                .sophiaColorScheme()
            }
        }
        .onAppear {
            streakBefore = progressManager.streak
            completedBefore = progressManager.completedCount
            subjectXPBefore = progressManager.xp(for: course.subject)
            courseWasCompletedBeforeQuiz = progressManager.courseStatus(for: course.id) == .completed
            questionShownAt = Date()
            AnalyticsService.shared.log(
                .quizStart,
                courseId: course.id,
                props: ["context": "course", "total": .int(shuffledQuestions.count)]
            )
            pendingCollectionEvents = initialCollectionEvents
            shuffleAllQuestions()
        }
        .sophiaColorScheme()
    }

    private func shuffleAllQuestions() {
        shuffledQuestions = course.quiz.map { QuizShuffler.shuffle($0) }
        questionAppeared = false
        resetAnswerState()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                questionAppeared = true
            }
        }
    }

    /// Clears the answer state for whichever question is now `currentQuestionIndex`.
    private func resetAnswerState() {
        selectedOptionIndex = nil
        if shuffledQuestions.indices.contains(currentQuestionIndex) {
            let q = shuffledQuestions[currentQuestionIndex]
            chronoSlots = Array(repeating: nil, count: q.items.count)
            chronoPool = Array(q.items.indices)
            sliderValue = q.snapToStep((q.sliderMin + q.sliderMax) / 2)
        } else {
            chronoSlots = []
            chronoPool = []
            sliderValue = 0
        }
        hasAnswered = false
        currentQuestionPoints = 0
    }

    // MARK: - Answer submission

    private func submitAnswer(_ answer: QuizAnswer) {
        guard !hasAnswered else { return }
        let question = currentQuestion
        let earned = QuizScoring.points(for: question, answer: answer)
        let fullyCorrect = QuizScoring.isFullyCorrect(for: question, answer: answer)

        var props: [String: AnalyticsValue] = [
            "question_id": .string(question.id),
            "context": "course",
            "correct": .bool(fullyCorrect),
            "points": .int(earned),
            "max_points": .int(question.maxPoints),
            "seconds": .int(max(0, Int(Date().timeIntervalSince(questionShownAt).rounded()))),
        ]
        if case .singleChoice(let index) = answer { props["option_index"] = .int(index) }
        AnalyticsService.shared.log(.quizAnswer, courseId: course.id, props: props)

        hasAnswered = true
        currentQuestionPoints = earned
        totalPointsEarned += earned

        if fullyCorrect {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            comboCount += 1
            if comboCount >= 2 {
                withAnimation(.spring(response: 0.3)) { showCombo = true }
            }
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(earned > 0 ? .warning : .error)
            comboCount = 0
            withAnimation(.spring(response: 0.3)) { showCombo = false }
        }

        if earned > 0 {
            xpEarned += earned
            progressManager.addXP(subject: course.subject, amount: earned)
            showXPBubble(xp: earned)
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showFeedback = true
        }
    }

    private func selectOption(_ index: Int) {
        guard !hasAnswered else { return }
        selectedOptionIndex = index
        submitAnswer(.singleChoice(index))
    }

    private func submitChronoOrder() {
        guard chronoSlots.allSatisfy({ $0 != nil }) else { return }
        submitAnswer(.order(chronoSlots.compactMap { $0 }))
    }

    private func submitSlider() {
        submitAnswer(.value(sliderValue))
    }

    // MARK: - Question screen

    /// « Question 2 sur 8 » : le sur-titre et le libellé VoiceOver de la progression.
    private var questionCountText: String {
        String(
            format: languageManager.text("elevateCourse.quiz.questionOf"),
            currentQuestionIndex + 1,
            shuffledQuestions.count
        )
    }

    private var questionView: some View {
        VStack(spacing: 0) {
            CourseQuizTopBar(
                total: shuffledQuestions.count,
                filled: currentQuestionIndex + 1,
                closeLabel: languageManager.text("common.close"),
                progressLabel: questionCountText,
                combo: showCombo ? comboCount : 0,
                onClose: { dismiss() }
            )
            .animation(DS.Motion.pop, value: showCombo)
            .animation(DS.Motion.snappy, value: comboCount)

            ScrollView {
                VStack(spacing: 26) {
                    questionHeader
                        .opacity(questionAppeared ? 1 : 0)
                        .offset(y: questionAppeared ? 0 : 12)
                        .padding(.top, 26)

                    Group {
                        switch currentQuestion.type {
                        case .mcq, .trueFalse:
                            choiceAnswerBody
                        case .chronological:
                            chronologicalAnswerBody
                        case .numericSlider, .percentageSlider:
                            sliderAnswerBody
                        }
                    }
                    .opacity(questionAppeared ? 1 : 0)
                    .offset(y: questionAppeared ? 0 : 12)
                    .id("answer_\(currentQuestionIndex)")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)

            if showFeedback {
                feedbackBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    /// Sur-titre « MATIÈRE · QUESTION n SUR N », puis la question centrée.
    private var questionHeader: some View {
        CourseQuizQuestionHeader(
            subject: course.subject,
            eyebrow: "\(course.subject.localizedShortName(language: languageManager.current)) · \(questionCountText)",
            question: currentQuestion.question
        )
        .id("question_\(currentQuestionIndex)")
    }

    // MARK: - Choice answer (.mcq / .trueFalse)

    @ViewBuilder
    private var choiceAnswerBody: some View {
        if currentQuestion.type == .trueFalse {
            HStack(spacing: 10) {
                ForEach(Array(currentQuestion.options.enumerated()), id: \.offset) { index, option in
                    trueFalseButton(index: index, text: option)
                }
            }
        } else {
            VStack(spacing: 10) {
                ForEach(Array(currentQuestion.options.enumerated()), id: \.offset) { index, option in
                    optionRow(index: index, text: option)
                }
            }
        }
    }

    /// État visuel d'une réponse : au repos tant que rien n'est choisi ; ensuite la bonne en
    /// vert, la mauvaise choisie en rouge, les autres estompées.
    private func optionState(for index: Int) -> DSOptionState {
        guard hasAnswered else { return .idle }
        if index == currentQuestion.correctIndex { return .correct }
        if index == selectedOptionIndex { return .wrong }
        return .dimmed
    }

    // Pas de vibration au toucher : le verdict (`submitAnswer`) vibre aussitôt.
    private func optionRow(index: Int, text: String) -> some View {
        let state: DSOptionState = optionState(for: index)
        return Button {
            selectOption(index)
        } label: {
            CourseQuizOptionCard(text: text, state: state)
        }
        .buttonStyle(PressableStyle(haptic: false))
        .dsShake(trigger: state == .wrong ? 1 : 0)
        .dsStagger(index)
    }

    private func trueFalseButton(index: Int, text: String) -> some View {
        let state: DSOptionState = optionState(for: index)
        return Button {
            selectOption(index)
        } label: {
            CourseQuizTrueFalseCard(text: text, isTrue: index == 0, state: state)
        }
        .buttonStyle(PressableStyle(haptic: false))
        .dsShake(trigger: state == .wrong ? 1 : 0)
        .dsStagger(index)
    }

    // MARK: - Chronological ordering answer (tap or drag into slots, then drag to reorder)

    private var chronologicalAnswerBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(languageManager.text("quiz.chronological.instruction"))
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)

            VStack(spacing: 8) {
                ForEach(Array(chronoSlots.indices), id: \.self) { position in
                    chronoSlotView(position: position)
                        .dsStagger(position)
                }
            }

            if !chronoPool.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(languageManager.text("quiz.chronological.remaining").uppercasedInApp())
                        .font(DS.sans(.caption2, .heavy))
                        .foregroundStyle(DS.inkSecondary)
                        .tracking(0.9)

                    VStack(spacing: 8) {
                        ForEach(chronoPool, id: \.self) { slot in
                            chronoPoolChip(slot: slot)
                        }
                    }
                }
            }

            if hasAnswered {
                correctOrderCard
            } else if chronoSlots.allSatisfy({ $0 != nil }) {
                // Pas de vibration au toucher : le verdict vibre aussitôt.
                Button {
                    submitChronoOrder()
                } label: {
                    Text(languageManager.text("quiz.chronological.validate"))
                }
                .buttonStyle(CourseCTAStyle())
                .padding(.top, 4)
                .transition(.opacity.combined(with: .offset(y: 8)))
            }
        }
    }

    private var correctOrderCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(languageManager.text("quiz.chronological.correctOrder").uppercasedInApp())
                .font(DS.sans(.caption2, .heavy))
                .foregroundStyle(DS.inkSecondary)
                .tracking(0.9)
            Text(correctChronologicalOrderText)
                .font(DS.sans(.footnote, .medium))
                .foregroundStyle(DS.ink)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .dsCard(padding: 14)
    }

    /// One numbered slot. Tapping a filled slot returns its card to the pool below;
    /// while unanswered, every slot (empty or filled) accepts a drop from either the
    /// pool or another slot, and a filled slot can itself be dragged out.
    @ViewBuilder
    private func chronoSlotView(position: Int) -> some View {
        let content = chronoSlotContent(position: position)
        if hasAnswered {
            content
        } else if let slot = chronoSlots[position] {
            content
                .onTapGesture { tapFilledSlot(position) }
                .draggable(String(slot))
                .dropDestination(for: String.self) { items, _ in
                    guard let raw = items.first, let draggedSlot = Int(raw) else { return false }
                    handleChronoDrop(draggedSlot: draggedSlot, targetPosition: position)
                    return true
                }
        } else {
            content
                .dropDestination(for: String.self) { items, _ in
                    guard let raw = items.first, let draggedSlot = Int(raw) else { return false }
                    handleChronoDrop(draggedSlot: draggedSlot, targetPosition: position)
                    return true
                }
        }
    }

    private func chronoSlotContent(position: Int) -> some View {
        let slot: Int? = chronoSlots[position]
        var verdict: CourseQuizSlotVerdict = .pending
        if hasAnswered, let slot {
            var isCorrectSlot = false
            if currentQuestion.originalIndices.indices.contains(slot) {
                isCorrectSlot = currentQuestion.originalIndices[slot] == position
            }
            verdict = isCorrectSlot ? .correct : .wrong
        }
        var text: String? = nil
        if let slot { text = currentQuestion.items[slot] }

        return CourseQuizChronoSlotRow(
            position: position,
            text: text,
            emptyText: languageManager.text("quiz.chronological.emptySlot"),
            verdict: verdict
        )
        .dsShake(trigger: verdict == .wrong ? 1 : 0)
    }

    private func chronoPoolChip(slot: Int) -> some View {
        CourseQuizChronoPoolRow(text: currentQuestion.items[slot])
            .onTapGesture { tapPoolItem(slot) }
            .draggable(String(slot))
    }

    /// Tapping a pool card places it in the leftmost empty slot.
    private func tapPoolItem(_ slot: Int) {
        guard !hasAnswered,
              let emptyPosition = chronoSlots.firstIndex(where: { $0 == nil }),
              let poolIndex = chronoPool.firstIndex(of: slot) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            chronoPool.remove(at: poolIndex)
            chronoSlots[emptyPosition] = slot
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Tapping a filled slot sends its card back to the pool (undo).
    private func tapFilledSlot(_ position: Int) {
        guard !hasAnswered, chronoSlots.indices.contains(position), let slot = chronoSlots[position] else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            chronoSlots[position] = nil
            chronoPool.append(slot)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Dropping a card that's already in a slot onto another slot swaps the two (this
    /// also correctly "moves" it if the target slot is empty, since swapping with `nil`
    /// just vacates the source). Dropping a card from the pool bumps whatever already
    /// occupies the target slot back to the pool.
    private func handleChronoDrop(draggedSlot: Int, targetPosition: Int) {
        guard !hasAnswered, chronoSlots.indices.contains(targetPosition) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if let sourcePosition = chronoSlots.firstIndex(of: draggedSlot) {
                chronoSlots.swapAt(sourcePosition, targetPosition)
            } else if let poolIndex = chronoPool.firstIndex(of: draggedSlot) {
                chronoPool.remove(at: poolIndex)
                if let bumped = chronoSlots[targetPosition] {
                    chronoPool.append(bumped)
                }
                chronoSlots[targetPosition] = draggedSlot
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private var correctChronologicalOrderText: String {
        let items = currentQuestion.items
        let originalIndices = currentQuestion.originalIndices
        guard !items.isEmpty, items.count == originalIndices.count else { return "" }
        let orderedSlots = items.indices.sorted { originalIndices[$0] < originalIndices[$1] }
        return orderedSlots.map { items[$0] }.joined(separator: " → ")
    }

    // MARK: - Slider answer (.numericSlider / .percentageSlider)

    private var sliderAnswerBody: some View {
        VStack(spacing: 20) {
            Text(sliderValueLabel(sliderValue))
                .font(CourseType.font(44, .heavy, relativeTo: .largeTitle))
                .foregroundStyle(DS.ink)
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity)

            VStack(spacing: 6) {
                // The step comes from the question: a whole-number slider made an answer
                // like 2.4 impossible to select, and impossible to score.
                Slider(value: $sliderValue, in: sliderBounds, step: currentQuestion.sliderStep)
                    .tint(DS.accent)
                    .disabled(hasAnswered)
                    .sensoryFeedback(.selection, trigger: sliderValue)

                HStack {
                    Text(sliderValueLabel(currentQuestion.sliderMin))
                    Spacer()
                    Text(sliderValueLabel(currentQuestion.sliderMax))
                }
                .font(DS.sans(.caption, .semibold))
                .foregroundStyle(DS.inkSecondary)
            }

            if hasAnswered {
                HStack(spacing: 10) {
                    CourseQuizSliderResultPill(
                        label: languageManager.text("quiz.slider.yourGuess"),
                        value: sliderValueLabel(sliderValue),
                        tint: sliderGuessTint,
                        fill: sliderGuessFill
                    )
                    .dsShake(trigger: currentQuestionPoints == 0 ? 1 : 0)

                    CourseQuizSliderResultPill(
                        label: languageManager.text("quiz.slider.correctAnswer"),
                        value: sliderValueLabel(currentQuestion.correctValue),
                        tint: CoursePalette.successInk,
                        fill: DS.successTint
                    )
                }
                .dsPopIn()
            } else {
                // Pas de vibration au toucher : le verdict vibre aussitôt.
                Button {
                    submitSlider()
                } label: {
                    Text(languageManager.text("quiz.slider.validate"))
                }
                .buttonStyle(CourseCTAStyle())
            }
        }
        .dsCard()
        .dsStagger(0)
    }

    private var sliderGuessTint: Color {
        if currentQuestionPoints == currentQuestion.maxPoints { return CoursePalette.successInk }
        if currentQuestionPoints > 0 { return DS.accent }
        return DS.danger
    }

    private var sliderGuessFill: Color {
        if currentQuestionPoints == currentQuestion.maxPoints { return DS.successTint }
        if currentQuestionPoints > 0 { return DS.accentTint }
        return DS.dangerTint
    }

    private var sliderBounds: ClosedRange<Double> {
        let lo = currentQuestion.sliderMin
        let hi = currentQuestion.sliderMax
        return lo < hi ? lo...hi : 0...100
    }

    private func sliderValueLabel(_ value: Double) -> String {
        // Truncating to an Int showed "23" for an answer of 23.5, telling the learner they
        // were wrong when they were not. The precision follows the question's own step.
        let formatter = NumberFormatter()
        formatter.locale = languageManager.locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = currentQuestion.sliderDecimals
        formatter.maximumFractionDigits = currentQuestion.sliderDecimals
        formatter.usesGroupingSeparator = currentQuestion.sliderDecimals == 0
        let text = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        let unit = currentQuestion.unit
        return unit.isEmpty ? text : "\(text) \(unit)"
    }

    // MARK: - XP popup

    // L'XP gagné s'affiche désormais dans le panneau de verdict (`feedbackBar`) : la bulle
    // flottante n'est plus dessinée, son état reste tenu tel quel.
    private func showXPBubble(xp: Int) {
        guard xp > 0 else { return }
        popupXPAmount = xp
        withAnimation(.easeOut(duration: 0.25)) {
            showXPPopup = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                showXPPopup = false
            }
        }
    }

    // MARK: - Feedback bar

    /// Le panneau de verdict : il monte du bas avec le titre, les XP gagnés, l'explication
    /// et « Continuer » (la vibration du bouton vient de son style).
    private var feedbackBar: some View {
        CourseQuizVerdictPanel(
            tone: feedbackTone,
            title: feedbackTitle,
            xpText: currentQuestionPoints > 0 ? "+\(currentQuestionPoints) XP" : nil,
            explanation: currentQuestion.explanation,
            continueTitle: languageManager.text("common.continue"),
            onContinue: { nextQuestion() }
        ) {
            feedbackDetail
        }
    }

    @ViewBuilder
    private var feedbackDetail: some View {
        if isFullyCorrect, comboCount >= 2 {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(CoursePalette.goldDeep)
                Text(String(format: languageManager.text("quiz.combo"), comboCount))
                    .font(DS.sans(.caption, .bold))
                    .foregroundStyle(CoursePalette.goldInk)
            }
        }

        if currentQuestion.maxPoints > 2 {
            Text("+\(currentQuestionPoints)/\(currentQuestion.maxPoints) \(languageManager.text("quiz.pointsEarned"))")
                .font(DS.sans(.caption, .semibold))
                .foregroundStyle(DS.inkSecondary)
        }
    }

    private var feedbackTone: CourseQuizVerdictTone {
        if isFullyCorrect { return .success }
        if currentQuestionPoints > 0 { return .partial }
        return .failure
    }

    private var feedbackTitle: String {
        switch currentQuestion.type {
        case .mcq, .trueFalse:
            guard isFullyCorrect else { return languageManager.text("quiz.feedback.wrong") }
            if comboCount >= 3 { return languageManager.text("quiz.feedback.amazing") }
            if comboCount >= 2 { return languageManager.text("quiz.feedback.excellent") }
            return languageManager.text("quiz.feedback.correct")
        case .chronological, .numericSlider, .percentageSlider:
            switch currentQuestionPoints {
            case 3: return languageManager.text("quiz.feedback.correct")
            case 2: return languageManager.text("quiz.feedback.close")
            case 1: return languageManager.text("quiz.feedback.far")
            default: return languageManager.text("quiz.feedback.wrong")
            }
        }
    }

    private func nextQuestion() {
        if currentQuestionIndex < shuffledQuestions.count - 1 {
            withAnimation(.easeOut(duration: 0.2)) {
                showFeedback = false
                questionAppeared = false
            }
            Task {
                try? await Task.sleep(for: .milliseconds(200))
                currentQuestionIndex += 1
                resetAnswerState()
                questionShownAt = Date()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    questionAppeared = true
                }
            }
        } else {
            withAnimation(.easeOut(duration: 0.25)) {
                showFeedback = false
            }
            AnalyticsService.shared.log(
                .quizComplete,
                courseId: course.id,
                props: [
                    "context": "course",
                    "score": .int(totalPointsEarned),
                    "max_score": .int(maxPossiblePoints),
                    "total": .int(shuffledQuestions.count),
                ]
            )
            // Award the fixed quiz-completion XP bonus once, before transitioning to the result screen.
            progressManager.addXP(subject: course.subject, amount: quizCompletionXPBonus)
            xpEarned += quizCompletionXPBonus
            globalQuizAwardResult = progressManager.awardGlobalXP(
                reason: .quizCompleted(courseId: course.id),
                amount: ProgressManager.globalQuizCompletionXP
            )
            progressManager.completeCourse(
                courseId: course.id,
                quizScore: totalPointsEarned,
                completedQuiz: true,
                quizTotalPoints: maxPossiblePoints
            )
            progressManager.registerTrainingQuestions(courseId: course.id, questionIds: course.quiz.map(\.id))
            if !courseWasCompletedBeforeQuiz {
                pendingCollectionEvents = progressManager.collectionProgressEvents(forNewlyCompletedCourseId: course.id)
            }
            // A finished quiz is a finished course too (belt and braces for a course whose
            // completion the blocker missed).
            TikTokBlockerManager.shared.registerDailyCourseCompleted(courseId: course.id)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                isFinished = true
            }
        }
    }

    // MARK: - Result screen

    private var resultView: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ScrollView {
                    resultSummary
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: geo.size.height)
                }
                .scrollIndicators(.hidden)
            }

            resultButtons
        }
        .overlay {
            if showResultConfetti {
                PathConfettiBurst(
                    colors: [CoursePalette.gold, CoursePalette.goldTint, DS.accent, DS.success],
                    pieceCount: 60,
                    duration: 2.6,
                    origin: CGPoint(x: 0.5, y: 0.3)
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
        .onAppear {
            startResultAnimations()
        }
    }

    private var resultSummary: some View {
        VStack(spacing: 12) {
            resultRing

            Text(languageManager.text("quiz.completed"))
                .font(CourseType.font(24, .semibold, relativeTo: .title2))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .opacity(resultAppeared ? 1 : 0)
                .offset(y: resultAppeared ? 0 : 12)
                .animation(DS.Motion.reveal.delay(0.25), value: resultAppeared)

            // Le score défile jusqu'à sa valeur (`startResultAnimations`).
            Text("\(scoreAnimated) / \(maxPossiblePoints)")
                .font(CourseType.font(44, .heavy, relativeTo: .largeTitle))
                .foregroundStyle(DS.ink)
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(scoreAnimated)))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .opacity(resultAppeared ? 1 : 0)
                .animation(DS.Motion.reveal.delay(0.4), value: resultAppeared)

            Text(languageManager.text("quiz.pointsEarned"))
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)
                .opacity(resultAppeared ? 1 : 0)
                .animation(DS.Motion.reveal.delay(0.5), value: resultAppeared)

            if xpEarned > 0 {
                CourseGoldPill(text: "+\(xpEarned) XP", font: DS.sans(.subheadline, .heavy))
                    .scaleEffect(resultAppeared ? 1 : 0.6)
                    .opacity(resultAppeared ? 1 : 0)
                    .animation(DS.Motion.pop.delay(0.65), value: resultAppeared)
            }

            animatedScoreStars
                .padding(.top, 4)
        }
    }

    /// L'anneau doré se remplit à hauteur du score, autour du trophée.
    private var resultRing: some View {
        ZStack {
            Circle()
                .stroke(CoursePalette.goldTint, lineWidth: 10)
                .padding(5)
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(CoursePalette.gold, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(5)
            Image(systemName: "trophy")
                .font(.system(size: 54, weight: .medium))
                .foregroundStyle(CoursePalette.goldDeep)
        }
        .frame(width: 150, height: 150)
        .scaleEffect(resultAppeared ? 1 : 0.7)
        .opacity(resultAppeared ? 1 : 0)
        .animation(DS.Motion.pop.delay(0.1), value: resultAppeared)
        .accessibilityHidden(true)
    }

    // Les deux boutons vibrent par leur style.
    private var resultButtons: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showXPProgress = true
                }
                startXPProgressionSequence()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "house")
                        .font(.subheadline.weight(.semibold))
                    Text(languageManager.text("common.backHome"))
                }
            }
            .buttonStyle(DSPrimaryButtonStyle())

            Button {
                resetQuiz()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline.weight(.semibold))
                    Text(languageManager.text("common.retryQuiz"))
                }
            }
            .buttonStyle(DSSecondaryButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .opacity(resultAppeared ? 1 : 0)
        .offset(y: resultAppeared ? 0 : 20)
        .animation(DS.Motion.reveal.delay(0.9), value: resultAppeared)
    }

    private func resetQuiz() {
        withAnimation(.easeOut(duration: 0.25)) {
            isFinished = false
        }
        resultAppeared = false
        showResultConfetti = false
        scoreAnimated = 0
        starsRevealed = 0
        ringProgress = 0
        currentQuestionIndex = 0
        showFeedback = false
        comboCount = 0
        showCombo = false
        totalPointsEarned = 0
        xpEarned = 0
        shuffleAllQuestions()
    }

    private func startResultAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
            resultAppeared = true
        }

        let targetScore = totalPointsEarned
        let totalPoints = max(maxPossiblePoints, 1)
        let percentage = Double(targetScore) / Double(totalPoints)
        let starCount = percentage >= 0.8 ? 3 : (percentage >= 0.5 ? 2 : 1)

        // Quiz réussi (au moins la moitié des points) : la vibration de récompense.
        if percentage >= 0.5 {
            Haptics.celebrate()
        } else {
            Haptics.soft()
        }

        withAnimation(.easeOut(duration: 0.9).delay(0.35)) {
            ringProgress = CGFloat(targetScore) / CGFloat(totalPoints)
        }

        let steps = max(targetScore, 1)
        for i in 1...steps {
            let delay = 0.35 + Double(i) * (0.7 / Double(steps))
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if i <= targetScore {
                    withAnimation(.spring(response: 0.2)) {
                        scoreAnimated = i
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }

        for i in 0..<starCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2 + Double(i) * 0.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    starsRevealed = i + 1
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }

        // Trois étoiles : une pluie de confettis quand la dernière se pose.
        if starCount == 3, !reduceMotion {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                guard isFinished else { return }
                showResultConfetti = true
            }
        }
    }

    private var animatedScoreStars: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                let isFilled = index < starsRevealed
                Image(systemName: isFilled ? "star.fill" : "star")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundStyle(isFilled ? CoursePalette.gold : DS.hairline)
                    .scaleEffect(isFilled ? 1.05 : 0.85)
                    .animation(.spring(response: 0.4, dampingFraction: 0.55), value: starsRevealed)
            }
        }
        .opacity(resultAppeared ? 1 : 0)
        .animation(DS.Motion.reveal.delay(1.1), value: resultAppeared)
    }

    // MARK: - Post-quiz XP progression screen

    /// XP-based tiers (mirrors ProgressManager).
    private var subjectTier: (level: Int, lower: Int, upper: Int) {
        let xp = displayedXP
        return ProgressManager.subjectXPTiers.last(where: { xp >= $0.lower }) ?? ProgressManager.subjectXPTiers[0]
    }

    private var didLevelUp: Bool {
        let before = ProgressManager.subjectXPTiers.last(where: { subjectXPBefore >= $0.lower })?.level ?? 1
        let after = ProgressManager.subjectXPTiers.last(where: { progressManager.xp(for: course.subject) >= $0.lower })?.level ?? 1
        return after > before
    }

    private func startXPProgressionSequence() {
        xpScreenAppeared = false
        xpButtonAppeared = false
        displayedXP = subjectXPBefore
        xpBarFill = XPProgressAnimator.barFraction(for: subjectXPBefore)
        cachedCourseThumb = CourseImageMap.loadImage(for: course.id)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                xpScreenAppeared = true
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let endXP = progressManager.xp(for: course.subject)
            XPProgressAnimator.animate(
                from: subjectXPBefore,
                to: endXP,
                setXP: { displayedXP = $0 },
                setLevel: { _ in },
                setBarFill: { fill, animated in
                    if animated {
                        xpBarFill = fill
                    } else {
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) { xpBarFill = fill }
                    }
                },
                haptic: {
                    XPProgressAnimator.progressionHaptic(intensity: 0.5)
                },
                completion: {
                    displayedXP = endXP
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    if didLevelUp {
                        showLevelUpCelebration = true
                    } else if pendingGlobalRankUp != nil {
                        showGlobalRankUpCelebration = true
                    } else {
                        revealXPContinueButton()
                    }
                }
            )
        }
    }

    private func revealXPContinueButton() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                xpButtonAppeared = true
            }
        }
    }

    private func revealAfterSubjectLevelUp() {
        if pendingGlobalRankUp != nil {
            showGlobalRankUpCelebration = true
        } else {
            revealXPContinueButton()
        }
    }

    private func continueAfterQuizCompletion() {
        rewardSteps = buildRewardSteps()
        if rewardSteps.isEmpty {
            onReturnHome()
        } else {
            showRewardFlow = true
        }
    }

    private func buildRewardSteps() -> [PostCompletionRewardStep] {
        var steps: [PostCompletionRewardStep] = []

        if progressManager.pendingGlobalRankUp() != nil {
            if let pending = progressManager.pendingGlobalRankUp() {
                steps.append(.globalRankUp(previous: pending.previous, new: pending.new, newLevel: pending.newLevel))
            }
        }

        while !pendingCollectionEvents.isEmpty {
            let event = pendingCollectionEvents.removeFirst()
            steps.append(.collectionProgress(event))
            if event.didCompleteCollection {
                let award = progressManager.awardGlobalXP(
                    reason: .collectionCompleted(id: event.collection.id),
                    amount: progressManager.collectionCompletionXP(for: event.collection)
                )
                steps.append(.collectionCompleted(event, awardedXP: award.awardedXP))
                if award.didRankUp {
                    steps.append(.globalRankUp(previous: award.previousRank, new: award.newRank, newLevel: award.newLevel))
                }
            }
        }

        if progressManager.shouldShowStreakToday {
            progressManager.markStreakShownToday()
            steps.append(.streak(streak: progressManager.streak, subject: course.subject, lastActiveDate: progressManager.progress.lastActiveDate))
        }
        return steps
    }

    private var pendingGlobalRankUp: (previous: GlobalRank, new: GlobalRank, newLevel: Int)? {
        if let globalQuizAwardResult, globalQuizAwardResult.didRankUp {
            return (globalQuizAwardResult.previousRank, globalQuizAwardResult.newRank, globalQuizAwardResult.newLevel)
        }
        return progressManager.pendingGlobalRankUp()
    }

    private var levelBefore: Int {
        ProgressManager.subjectXPTiers.last(where: { subjectXPBefore >= $0.lower })?.level ?? 1
    }

    private var levelAfter: Int {
        ProgressManager.subjectXPTiers.last(where: { progressManager.xp(for: course.subject) >= $0.lower })?.level ?? 1
    }

    private var xpProgressionView: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ScrollView {
                    xpProgressionSummary
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: geo.size.height)
                }
                .scrollIndicators(.hidden)
            }

            // Vibre par son style.
            Button {
                continueAfterQuizCompletion()
            } label: {
                HStack(spacing: 8) {
                    Text(languageManager.text("common.continue"))
                    Image(systemName: "arrow.forward")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .scaleEffect(xpButtonAppeared ? 1 : 0.9)
            .opacity(xpButtonAppeared ? 1 : 0)
        }
    }

    private var xpProgressionSummary: some View {
        VStack(spacing: 18) {
            xpCourseThumbnail
                .scaleEffect(xpScreenAppeared ? 1 : 0.7)
                .opacity(xpScreenAppeared ? 1 : 0)

            Text(didLevelUp ? languageManager.text("quiz.levelUp") : languageManager.text("quiz.xpProgress"))
                .font(CourseType.font(26, .semibold, relativeTo: .title))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .opacity(xpScreenAppeared ? 1 : 0)

            xpProgressionCard
                .opacity(xpScreenAppeared ? 1 : 0)
                .offset(y: xpScreenAppeared ? 0 : 10)
        }
    }

    private var xpCourseThumbnail: some View {
        ZStack {
            DS.accentTint
            if let thumb = cachedCourseThumb {
                Image(uiImage: thumb)
                    .resizable()
                    .scaledToFill()
            } else {
                SubjectBadgeView(subject: course.subject, iconSize: 60, cornerRadius: 0)
            }
        }
        .frame(width: 152, height: 152)
        .clipShape(.rect(cornerRadius: 28, style: .continuous))
    }

    /// La carte de progression de la matière : XP qui défile, barre dorée, détail des gains.
    private var xpProgressionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                CourseSubjectAvatar(subject: course.subject, size: 36)
                Text(course.subject.localizedShortName(language: languageManager.current))
                    .font(DS.sans(.callout, .bold))
                    .foregroundStyle(DS.ink)
                    .lineLimit(2)
                Spacer(minLength: 8)
                Text(String(format: languageManager.text("common.levelShort"), subjectTier.level))
                    .font(DS.sans(.caption, .heavy))
                    .foregroundStyle(DS.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(DS.accentTint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(displayedXP)")
                    .font(CourseType.font(32, .heavy, relativeTo: .title))
                    .foregroundStyle(DS.ink)
                    .monospacedDigit()
                Text("XP")
                    .font(DS.sans(.headline, .bold))
                    .foregroundStyle(DS.inkSecondary)
            }

            CourseXPBar(fraction: Double(xpBarFill), height: 8)

            Text(xpProgressLabel)
                .font(DS.sans(.footnote, .medium))
                .foregroundStyle(DS.inkSecondary)

            Rectangle()
                .fill(DS.hairline)
                .frame(height: 1)

            breakdownRow(
                icon: "checkmark",
                label: languageManager.text("quiz.breakdown.correct"),
                amount: xpEarned - quizCompletionXPBonus
            )
            breakdownRow(
                icon: "trophy",
                label: languageManager.text("quiz.breakdown.completed"),
                amount: quizCompletionXPBonus
            )
        }
        .dsCard(padding: 16)
    }

    private var xpProgressLabel: String {
        let t = subjectTier
        if t.level == ProgressManager.maxSubjectLevel {
            return String(format: languageManager.text("quiz.xpProgress.max"), displayedXP)
        }
        let toNext = max(0, t.upper - displayedXP)
        return String(format: languageManager.text("quiz.xpProgress.toNext"), toNext, t.level + 1)
    }

    private func breakdownRow(icon: String, label: String, amount: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(DS.accent)
                .frame(width: 28, height: 28)
                .background(DS.accentTint, in: Circle())

            Text(label)
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(DS.ink)

            Spacer(minLength: 4)

            CourseGoldPill(text: "+\(amount) XP")
        }
    }
}
