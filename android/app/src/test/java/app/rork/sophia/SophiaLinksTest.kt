package app.rork.sophia

import app.rork.sophia.domain.SophiaLinks
import app.rork.sophia.domain.SophiaLinks.WebTarget
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class SophiaLinksTest {
    @Test
    fun courseLinkUsesTheNumber() {
        assertEquals("https://sophia-culture.com/courses/150", SophiaLinks.courseWebUrl("course_150_la_nuit_etoilee_van_gogh"))
        assertEquals("https://sophia-culture.com/c/special%20course", SophiaLinks.courseWebUrl("special course"))
        assertEquals("https://sophia-culture.com/authors/jane-doe", SophiaLinks.authorWebUrl("jane-doe"))
    }

    @Test
    fun siteAddressesAreRecognised() {
        assertEquals(WebTarget.CourseNumber(150), SophiaLinks.webTarget("https://sophia-culture.com/courses/150"))
        assertEquals(WebTarget.CourseNumber(150), SophiaLinks.webTarget("https://www.sophia-culture.com/courses/150-why-does-the-sky-swirl?x=1"))
        assertEquals(WebTarget.CourseId("course_x"), SophiaLinks.webTarget("https://sophia-culture.com/c/course_x"))
        assertEquals(WebTarget.Creator("jane-doe"), SophiaLinks.webTarget("http://sophia-culture.com/authors/jane-doe/"))
    }

    @Test
    fun otherAddressesAreIgnored() {
        assertNull(SophiaLinks.webTarget("https://example.com/courses/150"))
        assertNull(SophiaLinks.webTarget("https://sophia-culture.com/courses"))
        assertNull(SophiaLinks.webTarget("https://sophia-culture.com/courses/abc"))
        assertNull(SophiaLinks.webTarget("https://sophia-culture.com/explore/art"))
        assertNull(SophiaLinks.webTarget("sophia://course/course_1_x"))
        assertNull(SophiaLinks.webTarget("not a url"))
    }

    @Test
    fun aNumberIsResolvedAgainstTheCatalogue() {
        val ids = listOf("course_15_x", "course_150_la_nuit", "course_1500_y")
        assertEquals("course_150_la_nuit", SophiaLinks.resolvePendingCourse(SophiaLinks.pendingCourseNumber(150), ids))
        assertNull(SophiaLinks.resolvePendingCourse(SophiaLinks.pendingCourseNumber(7), ids))
        assertEquals("course_15_x", SophiaLinks.resolvePendingCourse("course_15_x", ids))
    }
}
