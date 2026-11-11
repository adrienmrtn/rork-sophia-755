package app.rork.sophia.ui.onboarding

import app.rork.sophia.data.CourseAuthor
import org.junit.Assert.assertEquals
import org.junit.Test

class SuggestedAuthorsTest {
    private fun author(slug: String, vararg courses: String) = CourseAuthor(slug = slug, name = slug, courseIds = courses.toList())

    private val subjects = mapOf("c1" to "history", "c2" to "science", "c3" to "art", "c4" to "history")
    private val followers = mapOf("a" to 100, "b" to 900, "c" to 500, "d" to 900)

    @Test
    fun chosenSubjectsComeFirstThenFollowersThenSlug() {
        val authors = listOf(author("a", "c1"), author("b", "c2"), author("c", "c3"), author("d", "c2"), author("empty"))
        val result = suggestedAuthors(authors, subjects, setOf("history"), followers = { followers[it] ?: 0 })
        assertEquals(listOf("a", "b", "d", "c"), result.map { it.slug })
    }

    @Test
    fun limitIsApplied() {
        val authors = (1..20).map { author("s%02d".format(it), "c1") }
        assertEquals(12, suggestedAuthors(authors, subjects, emptySet(), followers = { 0 }).size)
    }
}
