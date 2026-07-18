import Foundation

/// Builds the randomized-for-display version of each question type. Centralizing this
/// here (rather than inline in `QuizView`) keeps the shuffle/scoring logic testable and
/// independent of the view layer.
nonisolated enum QuizShuffler {
    static func shuffle(_ question: QuizQuestion) -> ShuffledQuestion {
        switch question.type {
        case .mcq, .trueFalse:
            return shuffleChoice(question)
        case .chronological:
            return shuffleChronological(question)
        case .numericSlider, .percentageSlider:
            return shuffleSlider(question)
        }
    }

    private static func shuffleChoice(_ question: QuizQuestion) -> ShuffledQuestion {
        let options = question.options ?? []
        let correct = question.correctIndex ?? 0

        // .trueFalse keeps its authored order (conventionally "Vrai" then "Faux") — the
        // UI shows a fixed checkmark/cross icon per slot, and shuffling two options adds
        // no meaningful difficulty anyway.
        guard question.type != .trueFalse else {
            return ShuffledQuestion(
                id: question.id,
                type: question.type,
                question: question.question,
                explanation: question.explanation,
                maxPoints: question.maxPoints,
                options: options,
                correctIndex: correct,
                items: [],
                originalIndices: [],
                sliderMin: 0,
                sliderMax: 0,
                correctValue: 0,
                tolerance: 0,
                unit: ""
            )
        }

        var indexed = options.enumerated().map { ($0.offset, $0.element) }
        indexed.shuffle()
        let newCorrectIndex = indexed.firstIndex(where: { $0.0 == correct }) ?? 0
        return ShuffledQuestion(
            id: question.id,
            type: question.type,
            question: question.question,
            explanation: question.explanation,
            maxPoints: question.maxPoints,
            options: indexed.map(\.1),
            correctIndex: newCorrectIndex,
            items: [],
            originalIndices: [],
            sliderMin: 0,
            sliderMax: 0,
            correctValue: 0,
            tolerance: 0,
            unit: ""
        )
    }

    private static func shuffleChronological(_ question: QuizQuestion) -> ShuffledQuestion {
        let items = question.items ?? []
        var perm = Array(items.indices)
        perm.shuffle()
        // Avoid displaying the already-correct order when another arrangement exists.
        if perm == Array(items.indices), items.count > 1 {
            perm.shuffle()
        }
        let displayedItems = perm.map { items[$0] }
        return ShuffledQuestion(
            id: question.id,
            type: question.type,
            question: question.question,
            explanation: question.explanation,
            maxPoints: question.maxPoints,
            options: [],
            correctIndex: 0,
            items: displayedItems,
            originalIndices: perm,
            sliderMin: 0,
            sliderMax: 0,
            correctValue: 0,
            tolerance: 0,
            unit: ""
        )
    }

    private static func shuffleSlider(_ question: QuizQuestion) -> ShuffledQuestion {
        let isPercentage = question.type == .percentageSlider
        return ShuffledQuestion(
            id: question.id,
            type: question.type,
            question: question.question,
            explanation: question.explanation,
            maxPoints: question.maxPoints,
            options: [],
            correctIndex: 0,
            items: [],
            originalIndices: [],
            sliderMin: question.sliderMin ?? 0,
            sliderMax: question.sliderMax ?? (isPercentage ? 100 : 100),
            correctValue: question.correctValue ?? 0,
            tolerance: question.tolerance ?? (isPercentage ? 5 : 1),
            unit: question.unit ?? (isPercentage ? "%" : "")
        )
    }
}

/// Tiered scoring (see `content/CHARTE_QUIZ.md`): binary types are right-or-wrong,
/// the "closeness" types (chronological order, sliders) award partial credit for a
/// near-miss on a 0...3 scale.
nonisolated enum QuizScoring {
    /// Points earned for a given answer, from 0 to `question.maxPoints`.
    static func points(for question: ShuffledQuestion, answer: QuizAnswer) -> Int {
        switch (question.type, answer) {
        case (.mcq, .singleChoice(let index)), (.trueFalse, .singleChoice(let index)):
            return index == question.correctIndex ? question.maxPoints : 0

        case (.chronological, .order(let order)):
            return chronologicalPoints(question: question, order: order)

        case (.numericSlider, .value(let guess)), (.percentageSlider, .value(let guess)):
            return tieredPoints(
                guess: guess,
                target: question.correctValue,
                tolerance: max(question.tolerance, 0.0001),
                maxPoints: question.maxPoints
            )

        default:
            return 0
        }
    }

    /// Whether the answer earned full marks — drives the combo streak and the
    /// correct/incorrect feedback color, same as a classic right/wrong MCQ.
    static func isFullyCorrect(for question: ShuffledQuestion, answer: QuizAnswer) -> Bool {
        points(for: question, answer: answer) == question.maxPoints
    }

    private static func chronologicalPoints(question: ShuffledQuestion, order: [Int]) -> Int {
        let total = question.originalIndices.count
        guard total > 0, order.count == total else { return 0 }
        let correctSlots = order.enumerated().reduce(0) { count, pair in
            let (position, displaySlot) = pair
            guard question.originalIndices.indices.contains(displaySlot) else { return count }
            return question.originalIndices[displaySlot] == position ? count + 1 : count
        }
        if correctSlots == total { return 3 }
        let fraction = Double(correctSlots) / Double(total)
        if fraction >= 0.5 { return 2 }
        if correctSlots > 0 { return 1 }
        return 0
    }

    private static func tieredPoints(guess: Double, target: Double, tolerance: Double, maxPoints: Int) -> Int {
        let distance = abs(guess - target)
        if distance <= tolerance { return maxPoints }
        if distance <= tolerance * 2.5 { return max(0, maxPoints - 1) }
        if distance <= tolerance * 5 { return max(0, maxPoints - 2) }
        return 0
    }
}
