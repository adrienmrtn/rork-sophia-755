package app.rork.sophia

import app.rork.sophia.domain.BadgeCatalog
import app.rork.sophia.domain.BadgeCounter
import app.rork.sophia.domain.BadgeFamily
import app.rork.sophia.domain.BadgeMetric
import app.rork.sophia.domain.BadgeRules
import app.rork.sophia.domain.BadgeStats
import app.rork.sophia.domain.Campaign
import app.rork.sophia.domain.CourseProgress
import app.rork.sophia.domain.UserProgress
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.ZoneOffset

class BadgesTest {
    private fun done(at: String) = CourseProgress(isCompleted = true, completedAt = at)

    private fun stats(
        progress: UserProgress,
        campaigns: List<Campaign> = emptyList(),
        counters: Map<BadgeCounter, Int> = emptyMap(),
    ) = BadgeStats(
        progress = progress,
        campaigns = campaigns,
        subjectOf = { id -> id.substringBefore('-') },
        counter = { counters[it] ?: 0 },
        zone = ZoneOffset.UTC,
    )

    @Test
    fun `the catalogue matches the one of iOS`() {
        assertEquals(35, BadgeCatalog.permanent.size)
        assertEquals(30, BadgeCatalog.leagues.size)
        assertEquals("badge_league_19_vermeer", BadgeCatalog.leagues[18].imageName)
        assertEquals("badge_subject_comprendrelemonde", BadgeCatalog.permanent.first { it.id == "subject_comprendreLeMonde" }.imageName)
        val all = BadgeCatalog.everything(emptyList())
        assertEquals(all.size, all.map { it.id }.toSet().size)
        // Sans les duels, ni badges de duel ni ligues.
        assertTrue(BadgeCatalog.all(emptyList(), duelsVisible = false).none { it.family.needsDuels })
        assertEquals(24, BadgeCatalog.all(emptyList(), duelsVisible = false).size)
    }

    @Test
    fun `measures are read from the progress the counters and the events`() {
        val campaign = Campaign(slug = "movember", challengeTarget = 2, courseIds = listOf("art-1", "art-2", "art-3"))
        val progress = UserProgress(
            streak = 7,
            courseProgress = mapOf(
                "art-1" to done("2026-11-10T06:30:00Z"),
                "art-2" to done("2026-11-10T23:10:00Z"),
                "histoire-1" to done("2026-11-10T12:00:00Z"),
                "histoire-2" to CourseProgress(isCompleted = false),
            ),
            completedQuizCourseIds = listOf("art-1"),
            likedCourseIds = List(10) { "c$it" },
        )
        val s = stats(progress, listOf(campaign), mapOf(BadgeCounter.BEST_LEAGUE to 4))
        assertEquals(7, s.value(BadgeMetric.Streak))
        assertEquals(3, s.value(BadgeMetric.Courses))
        assertEquals(1, s.value(BadgeMetric.EarlyCourse))
        assertEquals(1, s.value(BadgeMetric.LateCourse))
        assertEquals(3, s.value(BadgeMetric.CoursesInOneDay))
        assertEquals(2, s.value(BadgeMetric.SubjectCourses("art")))
        assertEquals(2, s.value(BadgeMetric.SubjectsCovered))
        assertEquals(2, s.value(BadgeMetric.Event("movember")))
        val reached = BadgeCatalog.everything(listOf(campaign)).filter { s.isReached(it) }.map { it.id }.toSet()
        assertEquals(
            setOf("streak_3", "streak_7", "courses_1", "early", "late", "likes_10", "league_aesop", "league_homer", "league_sappho", "league_confucius", "event_movember"),
            reached,
        )
    }

    @Test
    fun `only the highest step of a measure is celebrated`() {
        val fresh = BadgeCatalog.permanent.filter { it.id in setOf("streak_3", "streak_7", "courses_1", "likes_10") }
        val (shown, silent) = BadgeRules.winners(fresh)
        assertEquals(listOf("streak_7", "courses_1", "likes_10"), shown.map { it.id })
        assertEquals(listOf("streak_3"), silent.map { it.id })
        val many = BadgeCatalog.leagues.take(1) + BadgeCatalog.permanent.filter { it.family == BadgeFamily.SOCIAL || it.family == BadgeFamily.QUIZ || it.id in setOf("early", "late", "binge") }
        assertEquals(5, BadgeRules.winners(many).first.size)
    }

    @Test
    fun `the profile shows chosen badges then the latest then the closest`() {
        val all = BadgeCatalog.all(emptyList(), duelsVisible = true)
        val progress = UserProgress(
            streak = 2,
            earnedBadges = mapOf("courses_1" to "2026-11-01T10:00:00Z", "likes_10" to "2026-11-05T10:00:00Z"),
            featuredBadgeIds = listOf("courses_1", "streak_365"),
        )
        val picked = BadgeRules.profileBadges(all, progress, stats(progress))
        // Le badge choisi et gagné, le dernier gagné, puis le plus proche (série de 3 : 2 sur 3).
        assertEquals(listOf("courses_1", "likes_10", "streak_3"), picked.map { it.id })
        assertFalse(picked.any { it.metric == BadgeMetric.League })
    }
}
