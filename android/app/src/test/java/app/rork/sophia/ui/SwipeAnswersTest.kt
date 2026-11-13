package app.rork.sophia.ui

import app.rork.sophia.ui.onboarding.swipeAnswers
import org.junit.Assert.assertEquals
import org.junit.Test

class SwipeAnswersTest {
    private val shown = listOf("course_150_la_nuit_etoilee_van_gogh", "course_42_pourquoi_reve_t_on", "course_7_x", "odd")

    @Test
    fun `kept and set aside courses go as sorted numbers`() {
        assertEquals(
            listOf("swipe_liked" to "42,150", "swipe_passed" to "7"),
            swipeAnswers(shown = shown, liked = listOf("course_42_pourquoi_reve_t_on", "course_150_la_nuit_etoilee_van_gogh")),
        )
    }

    @Test
    fun `an empty list is not sent`() {
        assertEquals(listOf("swipe_passed" to "7,42,150"), swipeAnswers(shown = shown, liked = emptyList()))
        assertEquals(emptyList<Pair<String, String>>(), swipeAnswers(shown = emptyList(), liked = emptyList()))
    }
}
