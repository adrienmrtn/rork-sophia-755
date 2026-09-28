import SwiftUI

/// One quiz question with its answer controls and the feedback bar. Same interaction as
/// `QuizView` and `TrainingView` for every question type, with the scoring left to
/// `QuizScoring`: this pane only reports the outcome. Give it a new identity per question
/// (`.id(question.id)`) so the answer state starts fresh.
struct QuizQuestionPane: View {
    @Environment(LanguageManager.self) private var languageManager
    let question: ShuffledQuestion
    let subject: Subject
    /// Course the question comes from, named above the question.
    let sourceTitle: String
    /// Changes the continue button's label on the last question.
    let isLast: Bool
    /// Called once, when the reader answers: points earned and whether the answer was fully correct.
    let onAnswered: (Int, Bool) -> Void
    let onContinue: () -> Void

    // Per-question answer state; only the fields of the question's type are meaningful.
    @State private var selectedOptionIndex: Int? = nil                 // .mcq / .trueFalse
    @State private var chronoSlots: [Int?]                             // .chronological
    @State private var chronoPool: [Int]
    @State private var sliderValue: Double                             // .numericSlider / .percentageSlider
    @State private var hasAnswered = false
    @State private var earnedPoints = 0
    @State private var showFeedback = false
    @State private var appeared = false

    init(
        question: ShuffledQuestion,
        subject: Subject,
        sourceTitle: String,
        isLast: Bool,
        onAnswered: @escaping (Int, Bool) -> Void,
        onContinue: @escaping () -> Void
    ) {
        self.question = question
        self.subject = subject
        self.sourceTitle = sourceTitle
        self.isLast = isLast
        self.onAnswered = onAnswered
        self.onContinue = onContinue
        _chronoSlots = State(initialValue: Array(repeating: nil, count: question.items.count))
        _chronoPool = State(initialValue: Array(question.items.indices))
        _sliderValue = State(initialValue: question.snapToStep((question.sliderMin + question.sliderMax) / 2))
    }

    private var isFullyCorrect: Bool {
        hasAnswered && earnedPoints == question.maxPoints
    }

    /// Valid only for `.mcq` / `.trueFalse`.
    private var isCorrect: Bool {
        selectedOptionIndex == question.correctIndex
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    questionCard
                    answerBody
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, showFeedback ? 240 : 32)
            }
            .scrollIndicators(.hidden)

            if showFeedback {
                feedbackBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85).delay(0.05)) {
                appeared = true
            }
        }
    }

    // MARK: - Question

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: subject.icon)
                    .font(.jakarta(size: 11, weight: .medium))
                Text(sourceTitle)
                    .font(DS.sans(.caption, .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .foregroundStyle(DS.accentSoft)

            Text(question.question)
                .font(DS.title(.title3, .semibold))
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .dsCard()
    }

    @ViewBuilder
    private var answerBody: some View {
        switch question.type {
        case .mcq, .trueFalse:
            choiceAnswerBody
        case .chronological:
            chronologicalAnswerBody
        case .numericSlider, .percentageSlider:
            sliderAnswerBody
        }
    }

    // MARK: - Answer submission

    private func submitAnswer(_ answer: QuizAnswer) {
        guard !hasAnswered else { return }
        let points = QuizScoring.points(for: question, answer: answer)
        let fullyCorrect = QuizScoring.isFullyCorrect(for: question, answer: answer)

        hasAnswered = true
        earnedPoints = points
        if fullyCorrect {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(points > 0 ? .warning : .error)
        }
        onAnswered(points, fullyCorrect)

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

    // MARK: - Choice answer (.mcq / .trueFalse)

    @ViewBuilder
    private var choiceAnswerBody: some View {
        if question.type == .trueFalse {
            HStack(spacing: 12) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    trueFalseButton(index: index, text: option)
                }
            }
        } else {
            VStack(spacing: 10) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
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
                    .strokeBorder(optionRowBorder(for: index), lineWidth: hasAnswered && (index == question.correctIndex || index == selectedOptionIndex) ? 1.5 : 1)
            }
            .opacity(hasAnswered && index != question.correctIndex && index != selectedOptionIndex ? 0.55 : 1)
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
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 22)
            .background(optionRowBg(for: index))
            .clipShape(.rect(cornerRadius: DS.Radius.control))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .strokeBorder(optionRowBorder(for: index), lineWidth: hasAnswered && (index == question.correctIndex || index == selectedOptionIndex) ? 1.5 : 1)
            }
            .opacity(hasAnswered && index != question.correctIndex && index != selectedOptionIndex ? 0.55 : 1)
        }
        .buttonStyle(SoftPressButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hasAnswered)
    }

    private func trueFalseIconColor(for index: Int) -> Color {
        guard hasAnswered else { return DS.accentSoft }
        if index == question.correctIndex { return DS.success }
        if index == selectedOptionIndex { return DS.danger }
        return DS.accentSoft
    }

    private func optionRowBg(for index: Int) -> Color {
        guard hasAnswered else { return DS.surface }
        if index == question.correctIndex { return DS.successTint }
        if index == selectedOptionIndex, index != question.correctIndex { return DS.dangerTint }
        return DS.surface
    }

    private func optionRowBorder(for index: Int) -> Color {
        guard hasAnswered else { return DS.hairline }
        if index == question.correctIndex { return DS.success }
        if index == selectedOptionIndex, index != question.correctIndex { return DS.danger }
        return DS.hairline
    }

    private func optionTextColor(for index: Int) -> Color {
        guard hasAnswered else { return DS.ink }
        if index == question.correctIndex { return DS.success }
        if index == selectedOptionIndex, index != question.correctIndex { return DS.danger }
        return DS.ink
    }

    private func optionLetterFg(for index: Int) -> Color {
        guard hasAnswered,
              index == question.correctIndex || (index == selectedOptionIndex && index != question.correctIndex) else {
            return DS.accentSoft
        }
        return .white
    }

    private func optionLetterBg(for index: Int) -> Color {
        guard hasAnswered else { return DS.accentTint }
        if index == question.correctIndex { return DS.success }
        if index == selectedOptionIndex, index != question.correctIndex { return DS.danger }
        return DS.accentTint
    }

    @ViewBuilder
    private func optionTrailingIcon(for index: Int) -> some View {
        if hasAnswered && index == question.correctIndex {
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
        if hasAnswered, let slot, question.originalIndices.indices.contains(slot) {
            isCorrectSlot = question.originalIndices[slot] == position
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
                    Text(question.items[slot])
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
            Text(question.items[slot])
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

    /// Tapping a pool card places it in the first empty slot.
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

    /// Tapping a filled slot sends its card back to the pool.
    private func tapFilledSlot(_ position: Int) {
        guard !hasAnswered, chronoSlots.indices.contains(position), let slot = chronoSlots[position] else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            chronoSlots[position] = nil
            chronoPool.append(slot)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// A card dropped from another slot swaps places with the target; one dropped from the
    /// pool bumps whatever occupied the target back to the pool.
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
        let items = question.items
        let originalIndices = question.originalIndices
        guard !items.isEmpty, items.count == originalIndices.count else { return "" }
        let orderedSlots = items.indices.sorted { originalIndices[$0] < originalIndices[$1] }
        return orderedSlots.map { items[$0] }.joined(separator: " → ")
    }

    // MARK: - Slider answer (.numericSlider / .percentageSlider)

    private var sliderAnswerBody: some View {
        VStack(spacing: 20) {
            Text(sliderValueLabel(sliderValue))
                .font(.jakarta(size: 42, weight: .semibold))
                .foregroundStyle(DS.ink)
                .monospacedDigit()
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity)

            VStack(spacing: 6) {
                // The step comes from the question: a whole-number slider made an answer
                // like 2.4 impossible to select, and impossible to score.
                Slider(value: $sliderValue, in: sliderBounds, step: question.sliderStep)
                    .tint(DS.accent)
                    .disabled(hasAnswered)

                HStack {
                    Text(sliderValueLabel(question.sliderMin))
                    Spacer()
                    Text(sliderValueLabel(question.sliderMax))
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
                        value: sliderValueLabel(question.correctValue),
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
        if isFullyCorrect { return DS.success }
        if earnedPoints > 0 { return DS.accentSoft }
        return DS.danger
    }

    private var sliderBounds: ClosedRange<Double> {
        let lo = question.sliderMin
        let hi = question.sliderMax
        return lo < hi ? lo...hi : 0...100
    }

    private func sliderValueLabel(_ value: Double) -> String {
        // The precision follows the question's own step: truncating to an Int showed "23"
        // for an answer of 23.5, telling the learner they were wrong when they were not.
        let formatter = NumberFormatter()
        formatter.locale = languageManager.locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = question.sliderDecimals
        formatter.maximumFractionDigits = question.sliderDecimals
        formatter.usesGroupingSeparator = question.sliderDecimals == 0
        let text = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        let unit = question.unit
        return unit.isEmpty ? text : "\(text) \(unit)"
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
                        .font(.jakarta(size: 30, weight: .regular))
                        .foregroundStyle(feedbackColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(feedbackTitle)
                            .font(DS.title(.headline, .semibold))
                            .foregroundStyle(DS.ink)

                        if question.maxPoints > 2 {
                            Text("+\(earnedPoints)/\(question.maxPoints) \(languageManager.text("quiz.pointsEarned"))")
                                .font(DS.sans(.caption, .medium))
                                .foregroundStyle(DS.inkTertiary)
                        }

                        if !question.explanation.isEmpty {
                            Text(question.explanation)
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
                    onContinue()
                } label: {
                    HStack(spacing: 8) {
                        Text(isLast ? languageManager.text("path.quiz.seeResult") : languageManager.text("common.continue"))
                        Image(systemName: "arrow.forward")
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
        if earnedPoints > 0 { return "circle.lefthalf.filled" }
        return "xmark.circle.fill"
    }

    private var feedbackColor: Color {
        if isFullyCorrect { return DS.success }
        if earnedPoints > 0 { return DS.accentSoft }
        return DS.danger
    }

    private var feedbackTitle: String {
        switch question.type {
        case .mcq, .trueFalse:
            return isFullyCorrect ? languageManager.text("quiz.feedback.correct") : languageManager.text("quiz.feedback.wrong")
        case .chronological, .numericSlider, .percentageSlider:
            switch earnedPoints {
            case 3: return languageManager.text("quiz.feedback.correct")
            case 2: return languageManager.text("quiz.feedback.close")
            case 1: return languageManager.text("quiz.feedback.far")
            default: return languageManager.text("quiz.feedback.wrong")
            }
        }
    }
}
