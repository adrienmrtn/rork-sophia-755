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

            if showXPPopup {
                xpPopupView
                    .transition(.opacity.combined(with: .offset(y: 6)))
                    .zIndex(20)
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
            }
        }
        .onAppear {
            streakBefore = progressManager.streak
            completedBefore = progressManager.completedCount
            subjectXPBefore = progressManager.xp(for: course.subject)
            courseWasCompletedBeforeQuiz = progressManager.courseStatus(for: course.id) == .completed
            pendingCollectionEvents = initialCollectionEvents
            shuffleAllQuestions()
            if !course.quiz.isEmpty {
                AnalyticsService.trackQuizStarted(course: course)
            }
        }
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
            sliderValue = ((q.sliderMin + q.sliderMax) / 2).rounded()
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

    private var questionView: some View {
        VStack(spacing: 0) {
            quizHeader
            progressBar

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    questionCard
                        .opacity(questionAppeared ? 1 : 0)
                        .offset(y: questionAppeared ? 0 : 12)
                        .padding(.top, 16)

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
                .padding(.horizontal, 20)
                .padding(.bottom, showFeedback ? 260 : 32)
            }
            .scrollIndicators(.hidden)

            if showFeedback {
                feedbackBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: course.subject.icon)
                    .font(.system(size: 11, weight: .medium))
                Text(course.subject.localizedShortName(language: languageManager.current).uppercased())
                    .font(DS.sans(.caption2, .semibold))
                    .tracking(0.8)
            }
            .foregroundStyle(DS.accentSoft)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(DS.accentTint, in: Capsule())

            Text(currentQuestion.question)
                .font(DS.title(.title3, .semibold))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .id("question_\(currentQuestionIndex)")
        }
        .dsCard()
    }

    private var progressBar: some View {
        HStack(spacing: 12) {
            CalmProgressBar(fraction: progressValue, height: 6)

            Text("\(currentQuestionIndex + 1)/\(shuffledQuestions.count)")
                .font(DS.sans(.caption, .medium))
                .foregroundStyle(DS.inkSecondary)
                .monospacedDigit()
                .fixedSize()

            if showCombo && comboCount >= 2 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text("x\(comboCount)")
                        .font(DS.sans(.caption2, .semibold))
                }
                .foregroundStyle(DS.accentSoft)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(DS.accentTint, in: Capsule())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    private var quizHeader: some View {
        HStack {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .frame(width: 40, height: 40)
                    .background(DS.surface, in: Circle())
                    .overlay { Circle().strokeBorder(DS.hairline, lineWidth: 1) }
            }
            .buttonStyle(SoftPressButtonStyle())

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    // MARK: - Choice answer (.mcq / .trueFalse)

    @ViewBuilder
    private var choiceAnswerBody: some View {
        if currentQuestion.type == .trueFalse {
            HStack(spacing: 12) {
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

    private func optionRow(index: Int, text: String) -> some View {
        Button {
            selectOption(index)
        } label: {
            HStack(spacing: 14) {
                Text("\(Character(UnicodeScalar(65 + index)!))")
                    .font(DS.title(.subheadline, .semibold))
                    .foregroundStyle(optionLetterFg(for: index))
                    .frame(width: 34, height: 34)
                    .background(optionLetterBg(for: index), in: Circle())

                Text(text)
                    .font(DS.sans(.body, .medium))
                    .foregroundStyle(optionTextColor(for: index))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                optionTrailingIcon(for: index)
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(minHeight: 64)
            .background(optionRowBg(for: index))
            .clipShape(.rect(cornerRadius: DS.Radius.control))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .strokeBorder(optionRowBorder(for: index), lineWidth: hasAnswered && (index == currentQuestion.correctIndex || index == selectedOptionIndex) ? 1.5 : 1)
            }
            .opacity(hasAnswered && index != currentQuestion.correctIndex && index != selectedOptionIndex ? 0.55 : 1)
        }
        .buttonStyle(SoftPressButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hasAnswered)
    }

    private func trueFalseButton(index: Int, text: String) -> some View {
        Button {
            selectOption(index)
        } label: {
            VStack(spacing: 10) {
                Image(systemName: index == 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(trueFalseIconColor(for: index))
                Text(text)
                    .font(DS.title(.headline, .semibold))
                    .foregroundStyle(optionTextColor(for: index))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(optionRowBg(for: index))
            .clipShape(.rect(cornerRadius: DS.Radius.control))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .strokeBorder(optionRowBorder(for: index), lineWidth: hasAnswered && (index == currentQuestion.correctIndex || index == selectedOptionIndex) ? 1.5 : 1)
            }
            .opacity(hasAnswered && index != currentQuestion.correctIndex && index != selectedOptionIndex ? 0.55 : 1)
        }
        .buttonStyle(SoftPressButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hasAnswered)
    }

    private func trueFalseIconColor(for index: Int) -> Color {
        guard hasAnswered else { return DS.accentSoft }
        if index == currentQuestion.correctIndex { return DS.success }
        if index == selectedOptionIndex { return DS.danger }
        return DS.accentSoft
    }

    private func optionRowBg(for index: Int) -> Color {
        guard hasAnswered else { return DS.surface }
        if index == currentQuestion.correctIndex { return DS.successTint }
        if index == selectedOptionIndex, index != currentQuestion.correctIndex { return DS.dangerTint }
        return DS.surface
    }

    private func optionRowBorder(for index: Int) -> Color {
        guard hasAnswered else { return DS.hairline }
        if index == currentQuestion.correctIndex { return DS.success }
        if index == selectedOptionIndex, index != currentQuestion.correctIndex { return DS.danger }
        return DS.hairline
    }

    private func optionTextColor(for index: Int) -> Color {
        guard hasAnswered else { return DS.ink }
        if index == currentQuestion.correctIndex { return DS.success }
        if index == selectedOptionIndex, index != currentQuestion.correctIndex { return DS.danger }
        return DS.ink
    }

    private func optionLetterFg(for index: Int) -> Color {
        guard hasAnswered,
              index == currentQuestion.correctIndex || (index == selectedOptionIndex && index != currentQuestion.correctIndex) else {
            return DS.accentSoft
        }
        return .white
    }

    private func optionLetterBg(for index: Int) -> Color {
        guard hasAnswered else { return DS.accentTint }
        if index == currentQuestion.correctIndex { return DS.success }
        if index == selectedOptionIndex, index != currentQuestion.correctIndex { return DS.danger }
        return DS.accentTint
    }

    @ViewBuilder
    private func optionTrailingIcon(for index: Int) -> some View {
        if hasAnswered && index == currentQuestion.correctIndex {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(DS.success)
                .transition(.scale.combined(with: .opacity))
        } else if hasAnswered && index == selectedOptionIndex && !isCorrect {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(DS.danger)
                .transition(.scale.combined(with: .opacity))
        } else {
            Color.clear
        }
    }

    // MARK: - Chronological ordering answer (tap or drag into slots, then drag to reorder)

    private var chronologicalAnswerBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(languageManager.text("quiz.chronological.instruction"))
                .font(DS.sans(.subheadline))
                .foregroundStyle(DS.inkSecondary)

            VStack(spacing: 8) {
                ForEach(Array(chronoSlots.indices), id: \.self) { position in
                    chronoSlotView(position: position)
                }
            }

            if !chronoPool.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(languageManager.text("quiz.chronological.remaining").uppercased())
                        .font(DS.sans(.caption2, .semibold))
                        .foregroundStyle(DS.inkTertiary)
                        .tracking(1.0)

                    VStack(spacing: 8) {
                        ForEach(chronoPool, id: \.self) { slot in
                            chronoPoolChip(slot: slot)
                        }
                    }
                }
            }

            if hasAnswered {
                Text("\(languageManager.text("quiz.chronological.correctOrder")) : \(correctChronologicalOrderText)")
                    .font(DS.sans(.caption, .medium))
                    .foregroundStyle(DS.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if chronoSlots.allSatisfy({ $0 != nil }) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    submitChronoOrder()
                } label: {
                    Text(languageManager.text("quiz.chronological.validate"))
                }
                .buttonStyle(DSPrimaryButtonStyle())
                .padding(.top, 4)
            }
        }
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
        let slot = chronoSlots[position]
        let filled = slot != nil
        var isCorrectSlot = false
        if hasAnswered, let slot, currentQuestion.originalIndices.indices.contains(slot) {
            isCorrectSlot = currentQuestion.originalIndices[slot] == position
        }
        let isWrongSlot = hasAnswered && filled && !isCorrectSlot

        return HStack(spacing: 12) {
            Text("\(position + 1)")
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(slotBadgeFg(isCorrect: isCorrectSlot, isWrong: isWrongSlot, filled: filled))
                .frame(width: 28, height: 28)
                .background(slotBadgeBg(isCorrect: isCorrectSlot, isWrong: isWrongSlot, filled: filled), in: Circle())

            Group {
                if let slot {
                    Text(currentQuestion.items[slot])
                        .foregroundStyle(DS.ink)
                } else {
                    Text(languageManager.text("quiz.chronological.emptySlot"))
                        .foregroundStyle(DS.inkTertiary)
                }
            }
            .font(DS.sans(.body, .medium))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)

            chronoSlotTrailingIcon(isCorrect: isCorrectSlot, isWrong: isWrongSlot, filled: filled)
                .frame(width: 20, height: 20)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(minHeight: 56)
        .background(slotRowBg(isCorrect: isCorrectSlot, isWrong: isWrongSlot, filled: filled))
        .clipShape(.rect(cornerRadius: DS.Radius.control))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .strokeBorder(
                    slotRowBorder(isCorrect: isCorrectSlot, isWrong: isWrongSlot, filled: filled),
                    style: StrokeStyle(lineWidth: 1, dash: filled ? [] : [5, 4])
                )
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func chronoSlotTrailingIcon(isCorrect: Bool, isWrong: Bool, filled: Bool) -> some View {
        if hasAnswered && filled {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(isCorrect ? DS.success : DS.danger)
        } else if filled {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.inkTertiary)
        } else {
            Color.clear
        }
    }

    private func chronoPoolChip(slot: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(DS.accentSoft)
            Text(currentQuestion.items[slot])
                .font(DS.sans(.body, .medium))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.control))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
        .contentShape(Rectangle())
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

    private func slotRowBg(isCorrect: Bool, isWrong: Bool, filled: Bool) -> Color {
        if isCorrect { return DS.successTint }
        if isWrong { return DS.dangerTint }
        return filled ? DS.surface : DS.surfaceMuted
    }

    private func slotRowBorder(isCorrect: Bool, isWrong: Bool, filled: Bool) -> Color {
        if isCorrect { return DS.success }
        if isWrong { return DS.danger }
        return DS.hairline
    }

    private func slotBadgeBg(isCorrect: Bool, isWrong: Bool, filled: Bool) -> Color {
        if isCorrect { return DS.success }
        if isWrong { return DS.danger }
        return filled ? DS.accentTint : DS.surfaceMuted
    }

    private func slotBadgeFg(isCorrect: Bool, isWrong: Bool, filled: Bool) -> Color {
        if isCorrect || isWrong { return .white }
        return filled ? DS.accentSoft : DS.inkTertiary
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
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(DS.ink)
                .monospacedDigit()
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity)

            VStack(spacing: 6) {
                Slider(value: $sliderValue, in: sliderBounds, step: 1)
                    .tint(DS.accent)
                    .disabled(hasAnswered)

                HStack {
                    Text(sliderValueLabel(currentQuestion.sliderMin))
                    Spacer()
                    Text(sliderValueLabel(currentQuestion.sliderMax))
                }
                .font(DS.sans(.caption2, .medium))
                .foregroundStyle(DS.inkTertiary)
            }

            if hasAnswered {
                HStack(spacing: 10) {
                    sliderResultPill(
                        label: languageManager.text("quiz.slider.yourGuess"),
                        value: sliderValueLabel(sliderValue),
                        tint: sliderGuessTint
                    )
                    sliderResultPill(
                        label: languageManager.text("quiz.slider.correctAnswer"),
                        value: sliderValueLabel(currentQuestion.correctValue),
                        tint: DS.success
                    )
                }
            } else {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    submitSlider()
                } label: {
                    Text(languageManager.text("quiz.slider.validate"))
                }
                .buttonStyle(DSPrimaryButtonStyle())
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
        .dsSoftShadow()
    }

    private func sliderResultPill(label: String, value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(DS.sans(.caption2, .semibold))
                .foregroundStyle(DS.inkTertiary)
                .tracking(0.5)
            Text(value)
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(DS.surfaceMuted)
        .clipShape(.rect(cornerRadius: DS.Radius.small))
    }

    private var sliderGuessTint: Color {
        if currentQuestionPoints == currentQuestion.maxPoints { return DS.success }
        if currentQuestionPoints > 0 { return DS.accentSoft }
        return DS.danger
    }

    private var sliderBounds: ClosedRange<Double> {
        let lo = currentQuestion.sliderMin
        let hi = currentQuestion.sliderMax
        return lo < hi ? lo...hi : 0...100
    }

    private func sliderValueLabel(_ value: Double) -> String {
        let rounded = Int(value.rounded())
        let unit = currentQuestion.unit
        return unit.isEmpty ? "\(rounded)" : "\(rounded) \(unit)"
    }

    // MARK: - XP popup

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

    private var xpPopupView: some View {
        VStack {
            Spacer().frame(height: 96)
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11, weight: .medium))
                Text("+\(popupXPAmount) XP")
                    .font(DS.sans(.subheadline, .semibold))
            }
            .foregroundStyle(DS.accentSoft)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(DS.accentTint, in: Capsule())
            Spacer()
        }
        .allowsHitTesting(false)
    }

    // MARK: - Feedback bar

    private var feedbackBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(DS.hairline)
                .frame(height: 1)

            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: feedbackIconName)
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(feedbackColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(feedbackTitle)
                            .font(DS.title(.headline, .semibold))
                            .foregroundStyle(DS.ink)

                        if isFullyCorrect, comboCount >= 2 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                Text("Combo x\(comboCount)")
                                    .font(DS.sans(.caption, .medium))
                            }
                            .foregroundStyle(DS.accentSoft)
                        }

                        if currentQuestion.maxPoints > 2 {
                            Text("+\(currentQuestionPoints)/\(currentQuestion.maxPoints) \(languageManager.text("quiz.pointsEarned"))")
                                .font(DS.sans(.caption, .medium))
                                .foregroundStyle(DS.inkTertiary)
                        }

                        if !currentQuestion.explanation.isEmpty {
                            Text(currentQuestion.explanation)
                                .font(DS.sans(.subheadline))
                                .foregroundStyle(DS.inkSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 2)
                        }
                    }

                    Spacer(minLength: 0)
                }

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    nextQuestion()
                } label: {
                    HStack(spacing: 8) {
                        Text(languageManager.text("common.continue"))
                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .buttonStyle(DSPrimaryButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 16)
            .background(DS.surface)
        }
    }

    private var feedbackIconName: String {
        if isFullyCorrect { return "checkmark.circle.fill" }
        if currentQuestionPoints > 0 { return "circle.lefthalf.filled" }
        return "xmark.circle.fill"
    }

    private var feedbackColor: Color {
        if isFullyCorrect { return DS.success }
        if currentQuestionPoints > 0 { return DS.accentSoft }
        return DS.danger
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
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    questionAppeared = true
                }
            }
        } else {
            withAnimation(.easeOut(duration: 0.25)) {
                showFeedback = false
            }
            // Award the fixed quiz-completion XP bonus once, before transitioning to the result screen.
            progressManager.addXP(subject: course.subject, amount: quizCompletionXPBonus)
            xpEarned += quizCompletionXPBonus
            globalQuizAwardResult = progressManager.awardGlobalXP(
                reason: .quizCompleted(courseId: course.id),
                amount: ProgressManager.globalQuizCompletionXP
            )
            progressManager.completeCourse(courseId: course.id, quizScore: totalPointsEarned, completedQuiz: true)
            if !courseWasCompletedBeforeQuiz {
                pendingCollectionEvents = progressManager.collectionProgressEvents(forNewlyCompletedCourseId: course.id)
            }
            AnalyticsService.trackQuizCompleted(
                course: course,
                score: totalPointsEarned,
                total: maxPossiblePoints
            )
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                isFinished = true
            }
        }
    }

    // MARK: - Result screen

    private var resultView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 24)

                ZStack {
                    Circle()
                        .stroke(DS.hairline, lineWidth: 8)
                        .frame(width: 156, height: 156)
                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(DS.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 156, height: 156)
                        .rotationEffect(.degrees(-90))
                    ZStack {
                        Circle().fill(DS.accentTint)
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 46, weight: .regular))
                            .foregroundStyle(DS.accent)
                    }
                    .frame(width: 128, height: 128)
                }
                .scaleEffect(resultAppeared ? 1 : 0.7)
                .opacity(resultAppeared ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1), value: resultAppeared)

                VStack(spacing: 10) {
                    Text(languageManager.text("quiz.completed"))
                        .font(DS.title(.title, .semibold))
                        .foregroundStyle(DS.ink)
                        .opacity(resultAppeared ? 1 : 0)
                        .offset(y: resultAppeared ? 0 : 12)
                        .animation(.spring(response: 0.5).delay(0.25), value: resultAppeared)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(scoreAnimated)")
                            .font(.system(size: 48, weight: .semibold, design: .default))
                            .foregroundStyle(DS.ink)
                            .contentTransition(.numericText(countsDown: false))
                        Text("/ \(maxPossiblePoints)")
                            .font(DS.title(.title2, .medium))
                            .foregroundStyle(DS.inkTertiary)
                    }
                    .opacity(resultAppeared ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.4), value: resultAppeared)

                    Text(languageManager.text("quiz.pointsEarned"))
                        .font(DS.sans(.subheadline))
                        .foregroundStyle(DS.inkSecondary)
                        .opacity(resultAppeared ? 1 : 0)
                        .animation(.spring(response: 0.5).delay(0.5), value: resultAppeared)

                    if xpEarned > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.caption.weight(.medium))
                            Text("+\(xpEarned) XP")
                                .font(DS.sans(.subheadline, .semibold))
                        }
                        .foregroundStyle(DS.accentSoft)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(DS.accentTint, in: Capsule())
                        .scaleEffect(resultAppeared ? 1 : 0.6)
                        .opacity(resultAppeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.65), value: resultAppeared)
                    }
                }

                animatedScoreStars

                Spacer(minLength: 12)

                VStack(spacing: 12) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showXPProgress = true
                        }
                        startXPProgressionSequence()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "house.fill")
                            Text(languageManager.text("common.backHome"))
                        }
                    }
                    .buttonStyle(DSPrimaryButtonStyle())

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        resetQuiz()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                            Text(languageManager.text("common.retryQuiz"))
                        }
                    }
                    .buttonStyle(DSSecondaryButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .opacity(resultAppeared ? 1 : 0)
                .offset(y: resultAppeared ? 0 : 20)
                .animation(.spring(response: 0.6).delay(0.9), value: resultAppeared)
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            startResultAnimations()
        }
    }

    private func resetQuiz() {
        withAnimation(.easeOut(duration: 0.25)) {
            isFinished = false
        }
        resultAppeared = false
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
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        let targetScore = totalPointsEarned
        let totalPoints = max(maxPossiblePoints, 1)
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

        let percentage = Double(targetScore) / Double(totalPoints)
        let starCount = percentage >= 0.8 ? 3 : (percentage >= 0.5 ? 2 : 1)
        for i in 0..<starCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2 + Double(i) * 0.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    starsRevealed = i + 1
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }

    private var animatedScoreStars: some View {
        HStack(spacing: 14) {
            ForEach(0..<3, id: \.self) { index in
                let isFilled = index < starsRevealed
                Image(systemName: isFilled ? "star.fill" : "star")
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(isFilled ? DS.accentSoft : DS.hairline)
                    .scaleEffect(isFilled ? 1.05 : 0.85)
                    .animation(.spring(response: 0.4, dampingFraction: 0.55), value: starsRevealed)
            }
        }
        .opacity(resultAppeared ? 1 : 0)
        .animation(.spring(response: 0.5).delay(1.1), value: resultAppeared)
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
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 20)

                HStack(spacing: 6) {
                    Image(systemName: course.subject.icon)
                        .font(.system(size: 12, weight: .medium))
                    Text(course.subject.localizedShortName(language: languageManager.current).uppercased())
                        .font(DS.sans(.caption, .semibold))
                        .tracking(0.8)
                }
                .foregroundStyle(DS.accentSoft)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(DS.accentTint, in: Capsule())
                .scaleEffect(xpScreenAppeared ? 1 : 0.7)
                .opacity(xpScreenAppeared ? 1 : 0)

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
                .frame(width: 176, height: 176)
                .clipShape(.rect(cornerRadius: DS.Radius.card))
                .overlay {
                    RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                        .strokeBorder(DS.hairline, lineWidth: 1)
                }
                .dsSoftShadow()
                .scaleEffect(xpScreenAppeared ? 1 : 0.7)
                .opacity(xpScreenAppeared ? 1 : 0)

                VStack(spacing: 6) {
                    Text(didLevelUp ? languageManager.text("quiz.levelUp") : languageManager.text("quiz.xpProgress"))
                        .font(DS.title(.title2, .semibold))
                        .foregroundStyle(DS.ink)
                        .opacity(xpScreenAppeared ? 1 : 0)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(displayedXP)")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundStyle(DS.ink)
                            .monospacedDigit()
                        Text("XP")
                            .font(DS.title(.title3, .medium))
                            .foregroundStyle(DS.inkTertiary)
                    }
                    .opacity(xpScreenAppeared ? 1 : 0)
                }

                VStack(alignment: .leading, spacing: 8) {
                    CalmProgressBar(fraction: Double(xpBarFill), height: 10)

                    Text(xpProgressLabel)
                        .font(DS.sans(.caption, .medium))
                        .foregroundStyle(DS.inkSecondary)
                }
                .padding(.horizontal, 24)
                .opacity(xpScreenAppeared ? 1 : 0)

                VStack(spacing: 10) {
                    breakdownRow(
                        icon: "checkmark.circle",
                        label: languageManager.text("quiz.breakdown.correct"),
                        amount: xpEarned - quizCompletionXPBonus
                    )
                    breakdownRow(
                        icon: "trophy",
                        label: languageManager.text("quiz.breakdown.completed"),
                        amount: quizCompletionXPBonus
                    )
                }
                .padding(.horizontal, 24)
                .opacity(xpScreenAppeared ? 1 : 0)
                .offset(y: xpScreenAppeared ? 0 : 10)

                Spacer(minLength: 12)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    continueAfterQuizCompletion()
                } label: {
                    HStack(spacing: 8) {
                        Text(languageManager.text("common.continue"))
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(DSPrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .scaleEffect(xpButtonAppeared ? 1 : 0.9)
                .opacity(xpButtonAppeared ? 1 : 0)
            }
        }
        .scrollIndicators(.hidden)
    }

    private var xpProgressLabel: String {
        let t = subjectTier
        if t.level == 5 {
            return String(format: languageManager.text("quiz.xpProgress.max"), displayedXP)
        }
        let toNext = max(0, t.upper - displayedXP)
        return String(format: languageManager.text("quiz.xpProgress.toNext"), toNext, t.level + 1)
    }

    private func breakdownRow(icon: String, label: String, amount: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(DS.accentSoft)
                .frame(width: 36, height: 36)
                .background(DS.accentTint, in: Circle())

            Text(label)
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.ink)

            Spacer(minLength: 4)

            Text("+\(amount) XP")
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(DS.accentSoft)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.control))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
    }
}
