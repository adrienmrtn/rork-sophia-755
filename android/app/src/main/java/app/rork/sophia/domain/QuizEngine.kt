package app.rork.sophia.domain

data class ShuffledQuestion(
    val id: String,
    val type: QuizQuestionType,
    val question: String,
    val explanation: String,
    val maxPoints: Int,
    val options: List<String> = emptyList(),
    val correctIndex: Int = 0,
    val items: List<String> = emptyList(),
    /** For chronological: originalIndices[displaySlot] = correct position. */
    val originalIndices: List<Int> = emptyList(),
    val sliderMin: Double = 0.0,
    val sliderMax: Double = 0.0,
    val correctValue: Double = 0.0,
    val tolerance: Double = 0.0,
    val unit: String = "",
)

sealed class QuizAnswer {
    data class SingleChoice(val index: Int) : QuizAnswer()
    data class Order(val order: List<Int>) : QuizAnswer()
    data class Value(val value: Double) : QuizAnswer()
}

object QuizShuffler {
    fun shuffle(question: QuizQuestion): ShuffledQuestion = when (question.type) {
        QuizQuestionType.MCQ, QuizQuestionType.TRUE_FALSE -> shuffleChoice(question)
        QuizQuestionType.CHRONOLOGICAL -> shuffleChronological(question)
        QuizQuestionType.NUMERIC_SLIDER, QuizQuestionType.PERCENTAGE_SLIDER -> shuffleSlider(question)
    }

    private fun shuffleChoice(question: QuizQuestion): ShuffledQuestion {
        val options = question.options.orEmpty()
        val correct = question.correctIndex ?: 0
        if (question.type == QuizQuestionType.TRUE_FALSE) {
            return ShuffledQuestion(
                id = question.id,
                type = question.type,
                question = question.question,
                explanation = question.explanation,
                maxPoints = question.maxPoints,
                options = options,
                correctIndex = correct,
            )
        }
        val indexed = options.withIndex().shuffled()
        val newCorrect = indexed.indexOfFirst { it.index == correct }.coerceAtLeast(0)
        return ShuffledQuestion(
            id = question.id,
            type = question.type,
            question = question.question,
            explanation = question.explanation,
            maxPoints = question.maxPoints,
            options = indexed.map { it.value },
            correctIndex = newCorrect,
        )
    }

    private fun shuffleChronological(question: QuizQuestion): ShuffledQuestion {
        val items = question.items.orEmpty()
        var perm = items.indices.toList().shuffled()
        if (perm == items.indices.toList() && items.size > 1) {
            perm = items.indices.toList().shuffled()
        }
        return ShuffledQuestion(
            id = question.id,
            type = question.type,
            question = question.question,
            explanation = question.explanation,
            maxPoints = question.maxPoints,
            items = perm.map { items[it] },
            originalIndices = perm,
        )
    }

    private fun shuffleSlider(question: QuizQuestion): ShuffledQuestion {
        val isPct = question.type == QuizQuestionType.PERCENTAGE_SLIDER
        return ShuffledQuestion(
            id = question.id,
            type = question.type,
            question = question.question,
            explanation = question.explanation,
            maxPoints = question.maxPoints,
            sliderMin = question.sliderMin ?: 0.0,
            sliderMax = question.sliderMax ?: if (isPct) 100.0 else 100.0,
            correctValue = question.correctValue ?: 0.0,
            tolerance = question.tolerance ?: if (isPct) 5.0 else 1.0,
            unit = question.unit ?: if (isPct) "%" else "",
        )
    }
}

object QuizScoring {
    fun points(question: ShuffledQuestion, answer: QuizAnswer): Int = when {
        question.type == QuizQuestionType.MCQ || question.type == QuizQuestionType.TRUE_FALSE -> {
            val index = (answer as? QuizAnswer.SingleChoice)?.index ?: return 0
            if (index == question.correctIndex) question.maxPoints else 0
        }
        question.type == QuizQuestionType.CHRONOLOGICAL -> {
            val order = (answer as? QuizAnswer.Order)?.order ?: return 0
            chronologicalPoints(question, order)
        }
        question.type == QuizQuestionType.NUMERIC_SLIDER ||
            question.type == QuizQuestionType.PERCENTAGE_SLIDER -> {
            val guess = (answer as? QuizAnswer.Value)?.value ?: return 0
            tieredPoints(
                guess = guess,
                target = question.correctValue,
                tolerance = maxOf(question.tolerance, 0.0001),
                maxPoints = question.maxPoints,
            )
        }
        else -> 0
    }

    fun isFullyCorrect(question: ShuffledQuestion, answer: QuizAnswer): Boolean =
        points(question, answer) == question.maxPoints

    private fun chronologicalPoints(question: ShuffledQuestion, order: List<Int>): Int {
        val total = question.originalIndices.size
        if (total == 0 || order.size != total) return 0
        val correctSlots = order.withIndex().count { (position, displaySlot) ->
            question.originalIndices.getOrNull(displaySlot) == position
        }
        if (correctSlots == total) return 3
        val fraction = correctSlots.toDouble() / total
        if (fraction >= 0.5) return 2
        if (correctSlots > 0) return 1
        return 0
    }

    private fun tieredPoints(guess: Double, target: Double, tolerance: Double, maxPoints: Int): Int {
        val distance = kotlin.math.abs(guess - target)
        if (distance <= tolerance) return maxPoints
        if (distance <= tolerance * 2.5) return maxOf(0, maxPoints - 1)
        if (distance <= tolerance * 5) return maxOf(0, maxPoints - 2)
        return 0
    }
}
