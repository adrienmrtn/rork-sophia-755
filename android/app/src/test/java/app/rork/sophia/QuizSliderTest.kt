package app.rork.sophia

import app.rork.sophia.domain.QuizQuestion
import app.rork.sophia.domain.QuizQuestionType
import app.rork.sophia.domain.QuizScoring
import app.rork.sophia.domain.QuizAnswer
import app.rork.sophia.domain.QuizShuffler
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs

/**
 * The slider questions have to be answerable.
 *
 * "La photosynthèse expliquée simplement" expects 2.4 on a 1-4 slider with a ±0.3 tolerance.
 * With a whole-number step the nearest reachable value was 2 — outside the tolerance — so
 * nobody could score the question, and the value shown was truncated to "2" anyway.
 */
class QuizSliderTest {

    private fun slider(
        min: Double,
        max: Double,
        correct: Double,
        tolerance: Double,
        type: QuizQuestionType = QuizQuestionType.NUMERIC_SLIDER,
    ) = QuizShuffler.shuffle(
        QuizQuestion(
            id = "q",
            type = type,
            question = "",
            explanation = "",
            sliderMin = min,
            sliderMax = max,
            correctValue = correct,
            tolerance = tolerance,
        ),
    )

    @Test
    fun `the photosynthesis answer is reachable and scores full marks`() {
        val q = slider(min = 1.0, max = 4.0, correct = 2.4, tolerance = 0.3)
        val landed = q.snapToStep(2.41)
        assertEquals(2.4, landed, 1e-9)
        assertEquals(q.maxPoints, QuizScoring.points(q, QuizAnswer.Value(landed)))
        assertEquals(1, q.sliderDecimals)
    }

    @Test
    fun `every fractional answer in the catalogue is exactly selectable`() {
        // The nine slider questions whose expected answer is not a whole number.
        val cases = listOf(
            Triple(62.6, 0.0 to 100.0, 5.0),
            Triple(23.5, 0.0 to 45.0, 2.0),
            Triple(13.8, 5.0 to 20.0, 1.0),
            Triple(3.8, 0.0 to 8.0, 1.0),
            Triple(2.4, 1.0 to 4.0, 0.3),
            Triple(4.32, 0.0 to 10.0, 1.0),
            Triple(2.7, 0.0 to 8.0, 0.5),
            Triple(3.6, 0.0 to 10.0, 1.0),
            Triple(9.5, 0.0 to 100.0, 2.0),
        )
        for ((correct, range, tolerance) in cases) {
            val q = slider(range.first, range.second, correct, tolerance)
            val landed = q.snapToStep(correct + q.sliderStep / 3)
            assertEquals("$correct is not selectable", correct, landed, 1e-9)
            assertEquals(
                "$correct does not score full marks",
                q.maxPoints,
                QuizScoring.points(q, QuizAnswer.Value(landed)),
            )
        }
    }

    @Test
    fun `a whole-number answer keeps a whole-number slider`() {
        val q = slider(min = 0.0, max = 100.0, correct = 50.0, tolerance = 5.0)
        assertEquals(1.0, q.sliderStep, 1e-9)
        assertEquals(0, q.sliderDecimals)
        assertEquals(50.0, q.snapToStep(50.4), 1e-9)
    }

    @Test
    fun `a very wide range stays draggable`() {
        // Casualty counts run to the hundreds of thousands; a 0.01 step there would be
        // a slider nobody can aim.
        val q = slider(min = 300_000.0, max = 1_200_000.0, correct = 700_000.0, tolerance = 100_000.0)
        assertTrue(q.sliderStep >= 1.0)
        assertEquals(700_000.0, q.snapToStep(700_000.4), 1e-9)
    }

    @Test
    fun `snapping never leaves the range`() {
        val q = slider(min = 1.0, max = 4.0, correct = 2.4, tolerance = 0.3)
        assertTrue(q.snapToStep(-50.0) >= q.sliderMin)
        assertTrue(q.snapToStep(50.0) <= q.sliderMax)
    }

    @Test
    fun `percentage sliders behave the same way`() {
        val q = slider(0.0, 100.0, 62.6, 5.0, QuizQuestionType.PERCENTAGE_SLIDER)
        assertTrue(abs(q.snapToStep(62.63) - 62.6) < 1e-9)
        assertEquals("%", q.unit)
    }
}
