import SwiftUI

/// Spaced-repetition review of quiz questions the learner has already answered once, in a
/// completed course. Deliberately neutral: no XP, no streak, no combo — a pure memorization
/// aid layered on top of the courses/quizzes system (see `ProgressManager`'s training methods
/// and `content/CHARTE_QUIZ.md` for the underlying question types).
///
/// Only questions whose scheduled review date has arrived are shown (`ProgressManager
/// .dueTrainingQuestions`); a session is a fixed snapshot of that due list, shuffled once at
/// the start — answering a question wrong resets it to due-immediately, but it doesn't
/// re-enter the *current* session, only the next one.
struct TrainingView: View {
    @Environment(LanguageManager.self) private var languageManager
    let progressManager: ProgressManager

    private struct SessionItem: Identifiable {
        let course: Course
        let question: ShuffledQuestion
        var id: String { question.id }
    }

    @State private var sessionQuestions: [SessionItem] = []
    @State private var isSessionActive = false
    @State private var isSessionComplete = false
    @State private var currentIndex = 0
    @State private var correctCount = 0

    // Per-question answer state — mirrors QuizView's, minus anything XP/combo-related.
    @State private var selectedOptionIndex: Int? = nil
    @State private var chronoSlots: [Int?] = []
    @State private var chronoPool: [Int] = []
    @State private var sliderValue: Double = 0
    @State private var hasAnswered = false
    @State private var wasFullyCorrect = false
    @State private var questionAppeared = false
    @State private var showFeedback = false
    @State private var showExplain = false

    private var currentQuestion: ShuffledQuestion { sessionQuestions[currentIndex].question }
    private var currentCourse: Course { sessionQuestions[currentIndex].course }

    private var isCorrect: Bool {
        selectedOptionIndex == currentQuestion.correctIndex
    }

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            if isSessionComplete {
                summaryView
            } else if isSessionActive, sessionQuestions.indices.contains(currentIndex) {
                sessionView
            } else {
                entryView
            }

            if showExplain {
                FirstOpenExplanation(
                    icon: "arrow.triangle.2.circlepath",
                    title: languageManager.text("explain.training.title"),
                    message: languageManager.text("explain.training.body"),
                    onDismiss: {
                        showExplain = false
                        TutorialFlags.markSeen(.training)
                    }
                )
                .transition(.opacity)
                .zIndex(20)
            }
        }
        .onAppear {
            guard !TutorialFlags.seen(.training) else { return }
            guard !isSessionActive, !isSessionComplete else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard !TutorialFlags.seen(.training) else { return }
                guard !isSessionActive, !isSessionComplete else { return }
                withAnimation(.easeIn(duration: 0.3)) { showExplain = true }
            }
        }
    }

    // MARK: - Entry screen

    private var entryView: some View {
        let due = progressManager.dueTrainingQuestions
        let hasAnyQuestions = !progressManager.progress.trainingQuestionStates.isEmpty
        return VStack(spacing: 0) {
            HStack {
                Text(languageManager.text("training.title"))
                    .font(DS.title(.title2, .semibold))
                    .foregroundStyle(DS.ink)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 4)

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    if !due.isEmpty {
                        readyContent(due: due)
                    } else if hasAnyQuestions {
                        allReviewedContent
                    } else {
                        lockedContent
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .frame(minHeight: 520)
            }
            .scrollIndicators(.hidden)
        }
    }

    // Des questions sont à réviser maintenant.
    private func readyContent(due: [(course: Course, question: QuizQuestion)]) -> some View {
        VStack(spacing: 24) {
            trainingIcon("arrow.triangle.2.circlepath")

            VStack(spacing: 10) {
                Text(languageManager.text("training.readyTitle"))
                    .font(DS.title(.title2, .semibold))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.center)
                Text(String(format: languageManager.text("training.dueCount"), due.count))
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                startSession(due: due)
            } label: {
                Text(languageManager.text("training.start"))
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
    }

    // Tout est révisé pour l'instant (mais l'utilisateur a déjà des questions).
    private var allReviewedContent: some View {
        VStack(spacing: 24) {
            trainingIcon("checkmark.seal.fill")

            VStack(spacing: 10) {
                Text(languageManager.text("training.emptyTitle"))
                    .font(DS.title(.title2, .semibold))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.center)
                Text(languageManager.text("training.emptyMessage"))
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
        }
    }

    // Aucun quiz terminé encore : on explique clairement comment l'entraînement se remplit.
    private var lockedContent: some View {
        VStack(spacing: 22) {
            trainingIcon("brain.head.profile")

            VStack(spacing: 10) {
                Text(languageManager.text("training.locked.title"))
                    .font(DS.title(.title2, .semibold))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.center)
                Text(languageManager.text("training.locked.message"))
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)

            howItWorksCard
        }
    }

    private func trainingIcon(_ systemName: String) -> some View {
        ZStack {
            Circle().fill(DS.accentTint).frame(width: 128, height: 128)
            Image(systemName: systemName)
                .font(.jakarta(size: 50, weight: .regular))
                .foregroundStyle(DS.accent)
        }
    }

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(languageManager.text("training.how.title"))
                .font(DS.sans(.caption2, .semibold))
                .foregroundStyle(DS.inkTertiary)
                .tracking(1.2)

            howStep(1, languageManager.text("training.how.step1"))
            howStep(2, languageManager.text("training.how.step2"))
            howStep(3, languageManager.text("training.how.step3"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard()
    }

    private func howStep(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(DS.sans(.subheadline, .bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(DS.accent, in: Circle())
            Text(text)
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func startSession(due: [(course: Course, question: QuizQuestion)]) {
        sessionQuestions = due.shuffled().map { SessionItem(course: $0.course, question: QuizShuffler.shuffle($0.question)) }
        guard !sessionQuestions.isEmpty else { return }
        currentIndex = 0
        correctCount = 0
        isSessionComplete = false
        resetAnswerState()
        questionAppeared = false
        isSessionActive = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                questionAppeared = true
            }
        }
    }

    private func resetAnswerState() {
        selectedOptionIndex = nil
        if sessionQuestions.indices.contains(currentIndex) {
            let q = sessionQuestions[currentIndex].question
            chronoSlots = Array(repeating: nil, count: q.items.count)
            chronoPool = Array(q.items.indices)
            sliderValue = ((q.sliderMin + q.sliderMax) / 2).rounded()
        } else {
            chronoSlots = []
            chronoPool = []
            sliderValue = 0
        }
        hasAnswered = false
        wasFullyCorrect = false
    }

    // MARK: - Answer submission

    private func submitAnswer(_ answer: QuizAnswer) {
        guard !hasAnswered else { return }
        let item = sessionQuestions[currentIndex]
        let fullyCorrect = QuizScoring.isFullyCorrect(for: item.question, answer: answer)

        hasAnswered = true
        wasFullyCorrect = fullyCorrect
        if fullyCorrect {
            correctCount += 1
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        progressManager.recordTrainingAnswer(questionId: item.question.id, courseId: item.course.id, correct: fullyCorrect)

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

    // MARK: - Session screen

    private var sessionView: some View {
        VStack(spacing: 0) {
            sessionHeader
            sessionProgressBar

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
                    .id("training_answer_\(currentIndex)")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, showFeedback ? 220 : 32)
            }
            .scrollIndicators(.hidden)

            if showFeedback {
                feedbackBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var sessionHeader: some View {
        HStack {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                exitSession()
            } label: {
                Image(systemName: "xmark")
                    .font(.jakarta(size: 15, weight: .medium))
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

    private func exitSession() {
        withAnimation(.easeOut(duration: 0.2)) {
            isSessionActive = false
            showFeedback = false
        }
        sessionQuestions = []
        currentIndex = 0
    }

    private var sessionProgressBar: some View {
        HStack(spacing: 12) {
            CalmProgressBar(fraction: Double(currentIndex + 1) / Double(sessionQuestions.count), height: 6)

            Text("\(currentIndex + 1)/\(sessionQuestions.count)")
                .font(DS.sans(.caption, .medium))
                .foregroundStyle(DS.inkSecondary)
                .monospacedDigit()
                .fixedSize()
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: currentCourse.subject.icon)
                    .font(.jakarta(size: 11, weight: .medium))
                Text(currentCourse.title)
                    .font(DS.sans(.caption, .semibold))
                    .lineLimit(2)
            }
            .foregroundStyle(DS.accentSoft)

            Text(currentQuestion.question)
                .font(DS.title(.title3, .semibold))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .dsCard()
    }

    // MARK: - Choice answer (.mcq / .trueFalse) — identical styling to QuizView

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
                    .font(.jakarta(size: 26, weight: .regular))
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
                .font(.jakarta(size: 20, weight: .medium))
                .foregroundStyle(DS.success)
                .transition(.scale.combined(with: .opacity))
        } else if hasAnswered && index == selectedOptionIndex && !isCorrect {
            Image(systemName: "xmark.circle.fill")
                .font(.jakarta(size: 20, weight: .medium))
                .foregroundStyle(DS.danger)
                .transition(.scale.combined(with: .opacity))
        } else {
            Color.clear
        }
    }

    // MARK: - Chronological ordering answer — identical interaction to QuizView

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
                .font(.jakarta(size: 18, weight: .regular))
                .foregroundStyle(isCorrect ? DS.success : DS.danger)
        } else if filled {
            Image(systemName: "line.3.horizontal")
                .font(.jakarta(size: 13, weight: .medium))
                .foregroundStyle(DS.inkTertiary)
        } else {
            Color.clear
        }
    }

    private func chronoPoolChip(slot: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle")
                .font(.jakarta(size: 16, weight: .regular))
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

    private func tapFilledSlot(_ position: Int) {
        guard !hasAnswered, chronoSlots.indices.contains(position), let slot = chronoSlots[position] else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            chronoSlots[position] = nil
            chronoPool.append(slot)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

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

    // MARK: - Slider answer — identical styling to QuizView

    private var sliderAnswerBody: some View {
        VStack(spacing: 20) {
            Text(sliderValueLabel(sliderValue))
                .font(.jakarta(size: 42, weight: .semibold))
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
                        tint: wasFullyCorrect ? DS.success : DS.danger
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

    // MARK: - Feedback bar (simplified — no XP/combo)

    private var feedbackBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(DS.hairline)
                .frame(height: 1)

            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: wasFullyCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.jakarta(size: 30, weight: .regular))
                        .foregroundStyle(wasFullyCorrect ? DS.success : DS.danger)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(wasFullyCorrect ? languageManager.text("quiz.feedback.correct") : languageManager.text("quiz.feedback.wrong"))
                            .font(DS.title(.headline, .semibold))
                            .foregroundStyle(DS.ink)

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
                        Text(currentIndex < sessionQuestions.count - 1 ? languageManager.text("common.continue") : languageManager.text("training.finish"))
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

    private func nextQuestion() {
        if currentIndex < sessionQuestions.count - 1 {
            withAnimation(.easeOut(duration: 0.2)) {
                showFeedback = false
                questionAppeared = false
            }
            Task {
                try? await Task.sleep(for: .milliseconds(200))
                currentIndex += 1
                resetAnswerState()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    questionAppeared = true
                }
            }
        } else {
            withAnimation(.easeOut(duration: 0.25)) {
                showFeedback = false
                isSessionActive = false
                isSessionComplete = true
            }
        }
    }

    // MARK: - Session summary

    private var summaryView: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 40)

            ZStack {
                Circle().fill(DS.accentTint).frame(width: 128, height: 128)
                Image(systemName: "checkmark.seal.fill")
                    .font(.jakarta(size: 50, weight: .regular))
                    .foregroundStyle(DS.accent)
            }

            VStack(spacing: 10) {
                Text(languageManager.text("training.sessionComplete.title"))
                    .font(DS.title(.title2, .semibold))
                    .foregroundStyle(DS.ink)

                Text(String(format: languageManager.text("training.sessionComplete.summary"), correctCount, sessionQuestions.count))
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.inkSecondary)
            }

            Spacer(minLength: 40)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                finishSession()
            } label: {
                Text(languageManager.text("training.backToTraining"))
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .padding(.horizontal, 40)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 20)
    }

    private func finishSession() {
        isSessionComplete = false
        sessionQuestions = []
        currentIndex = 0
        correctCount = 0
    }
}
