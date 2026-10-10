package app.rork.sophia

import app.rork.sophia.domain.CourseAffinity
import app.rork.sophia.domain.CourseProgress
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.DeckContext
import app.rork.sophia.domain.HomeDeckBuilder
import app.rork.sophia.domain.Subject
import app.rork.sophia.domain.UserProgress
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import kotlin.math.abs
import kotlin.random.Random

/** The home deck, ported from iOS: affinity-ordered, never a filter, never a long run. */
class HomeDeckBuilderTest {

    private val subjects = Subject.entries.map { it.storageKey }

    private val catalogue = subjects.flatMap { subject ->
        List(12) { CourseSummary(id = "${subject}_$it", title = "", description = "", subject = subject) }
    }

    private val affinity = CourseAffinity(
        subjectBaseWeight = mapOf(
            "histoire" to 0.143, "sciences" to 0.353, "litterature" to 0.112,
            "art" to 0.114, "mythologie" to 0.099, "comprendreLeMonde" to 0.178,
        ),
        quality = catalogue.associate { it.id to (it.id.substringAfterLast('_').toInt() / 12.0) },
        neighbourIds = mapOf("histoire_0" to listOf("art_1")),
        neighbourLifts = mapOf("histoire_0" to listOf(10.0)),
    )

    private fun deck(context: DeckContext = DeckContext.EMPTY, completed: Set<String> = emptySet(), seed: Int = 1) =
        HomeDeckBuilder.deck(catalogue, affinity, context, { it in completed }, Random(seed))

    @Test
    fun everyUnfinishedCourseIsDealtOnceAndFinishedOnesNever() {
        val completed = setOf("sciences_3", "art_0", "histoire_11")
        val dealt = deck(completed = completed)
        assertEquals(catalogue.size - completed.size, dealt.size)
        assertEquals(dealt.size, dealt.map { it.id }.distinct().size)
        assertTrue(dealt.none { it.id in completed })
    }

    @Test
    fun noSubjectThreeTimesInARowWhileOthersRemain() {
        repeat(20) { seed ->
            val dealt = deck(seed = seed)
            dealt.windowed(3).forEachIndexed { start, window ->
                if (window.map { it.subject }.distinct().size == 1) {
                    // Only allowed once every other subject is exhausted.
                    val rest = dealt.drop(start)
                    assertTrue("seed $seed at $start", rest.all { it.subject == window[0].subject })
                }
            }
        }
    }

    @Test
    fun weightsSumToOneFollowTheReaderAndKeepAFloor() {
        val base = HomeDeckBuilder.subjectWeights(affinity, DeckContext.EMPTY)
        assertEquals(1.0, base.values.sum(), 1e-9)
        assertEquals(0.353, base.getValue("sciences"), 1e-3)

        val scienceReader = DeckContext(completedBySubject = mapOf("sciences" to 10))
        val bent = HomeDeckBuilder.subjectWeights(affinity, scienceReader)
        assertEquals(1.0, bent.values.sum(), 1e-9)
        assertTrue(bent.getValue("sciences") > base.getValue("sciences"))
        assertTrue(bent.values.all { it >= HomeDeckBuilder.SUBJECT_FLOOR - 1e-9 })

        // The onboarding objective nudges only while the reader is new.
        val newcomer = HomeDeckBuilder.subjectWeights(affinity, DeckContext(objectiveSubjects = setOf("art")))
        assertTrue(newcomer.getValue("art") > base.getValue("art"))
        val settled = HomeDeckBuilder.subjectWeights(
            affinity,
            DeckContext(completedBySubject = mapOf("histoire" to 3), objectiveSubjects = setOf("art")),
        )
        val withoutObjective = HomeDeckBuilder.subjectWeights(affinity, DeckContext(completedBySubject = mapOf("histoire" to 3)))
        assertEquals(withoutObjective.getValue("art"), settled.getValue("art"), 1e-9)
    }

    @Test
    fun scoreIsQualityPlusNeighboursMinusFatigue() {
        val art1 = catalogue.first { it.id == "art_1" }
        val plain = HomeDeckBuilder.score(art1, affinity, DeckContext.EMPTY)
        assertEquals(1 / 12.0, plain, 1e-9)
        // Read « histoire_0 » last: its strongest neighbour gets the full boost.
        val boosted = HomeDeckBuilder.score(art1, affinity, DeckContext(recentCourseIds = listOf("histoire_0")))
        assertEquals(plain + 0.8, boosted, 1e-9)
        // Skipped past twice: demoted, and the demotion is capped.
        val tired = HomeDeckBuilder.score(art1, affinity, DeckContext(skipCounts = mapOf("art_1" to 2)))
        assertEquals(plain - 0.3, tired, 1e-9)
        val worn = HomeDeckBuilder.score(art1, affinity, DeckContext(skipCounts = mapOf("art_1" to 8)))
        assertEquals(plain - 0.6, worn, 1e-9)
    }

    @Test
    fun theBestCourseOfASubjectComesFirstOutsideExploration() {
        val dealt = deck(seed = 3)
        // Cards 1-3 are never exploration: each is the best left of its subject.
        val seen = mutableMapOf<String, Int>()
        dealt.take(3).forEach { course ->
            val rank = seen.getOrDefault(course.subject, 0)
            assertEquals("${course.subject}_${11 - rank}", course.id)
            seen[course.subject] = rank + 1
        }
    }

    @Test
    fun aScienceReaderGetsMoreScience() {
        val reader = DeckContext(completedBySubject = mapOf("sciences" to 12))
        val firstTwenty = (0 until 30).map { seed ->
            HomeDeckBuilder.deck(catalogue, affinity, reader, { false }, Random(seed)).take(20)
                .count { it.subject == "sciences" }
        }.average()
        val baseline = (0 until 30).map { seed -> deck(seed = seed).take(20).count { it.subject == "sciences" } }.average()
        assertTrue("$firstTwenty vs $baseline", firstTwenty > baseline)
    }

    @Test
    fun recentCoursesComeFromProgressDates() {
        val progress = UserProgress(
            courseProgress = mapOf(
                "art_1" to CourseProgress(isCompleted = true, completedAt = "2026-10-01T10:00:00Z"),
                "sciences_2" to CourseProgress(startedAt = "2026-10-05T10:00:00Z"),
                "histoire_3" to CourseProgress(isCompleted = true),
                "unknown" to CourseProgress(isCompleted = true, completedAt = "2026-10-09T10:00:00Z"),
            ),
        )
        val context = DeckContext.from(progress, catalogue, setOf("art"), mapOf("art_2" to 1))
        assertEquals(mapOf("art" to 1, "histoire" to 1), context.completedBySubject)
        assertEquals(listOf("sciences_2", "art_1"), context.recentCourseIds)
        assertEquals(setOf("art"), context.objectiveSubjects)
    }

    @Test
    fun theBundledModelIsTheIosOne() {
        val file = listOf("src/main/assets/course_affinity.json", "app/src/main/assets/course_affinity.json")
            .map(::File).first { it.exists() }
        val model = Json { ignoreUnknownKeys = true }.decodeFromString(CourseAffinity.serializer(), file.readText())
        assertEquals(238, model.quality.size)
        assertEquals(228, model.neighbourIds.size)
        assertEquals(1.0, model.subjectBaseWeight.values.sum(), 0.002)
        assertEquals(0.353, model.subjectBaseWeight.getValue("sciences"), 1e-9)
        assertFalse(model.neighbourIds.any { (id, ids) -> ids.size != model.neighbourLifts.getValue(id).size })
        assertTrue(model.quality.values.all { it in 0.0..1.0 })
        assertTrue(abs(model.neighbours("course_94_candide_voltaire").first().second - 12.2) < 1e-9)
    }
}
