package app.rork.sophia

import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.LearningCollection
import app.rork.sophia.domain.LearningPathEngine
import app.rork.sophia.domain.LearningPathRules
import app.rork.sophia.domain.LearningPathSnapshot
import app.rork.sophia.domain.PathNodeState
import app.rork.sophia.domain.PathQuizBuilder
import app.rork.sophia.domain.QuizQuestion
import app.rork.sophia.domain.UserProgress
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.random.Random

/** The Parcours rules, which have to match iOS since the progress they read is shared. */
class LearningPathTest {

    private fun course(id: String) = CourseSummary(id = id, title = id, description = "", subject = "histoire")

    private val courses = listOf("a", "b", "c", "d", "e").associateWith { course(it) }

    private val collections = listOf(
        LearningCollection(id = "one", title = "One", description = "", courseIds = listOf("a", "b")),
        // A collection whose courses the language does not carry is not a level.
        LearningCollection(id = "empty", title = "Empty", description = "", courseIds = listOf("missing")),
        LearningCollection(id = "two", title = "Two", description = "", courseIds = listOf("c", "missing", "d")),
        LearningCollection(id = "three", title = "Three", description = "", courseIds = listOf("e")),
    )

    private fun snapshot(completed: Set<String> = emptySet(), passed: Set<String> = emptySet()) =
        LearningPathEngine.snapshot(collections, courses, { it in completed }, { it in passed })

    private fun LearningPathSnapshot.state(id: String) = nodeStates.getValue(id)

    @Test
    fun passMarkIsStrictlyMoreThanHalf() {
        assertEquals(11, LearningPathRules.passMark(20))
        assertEquals(10, LearningPathRules.passMark(19))
        assertEquals(1, LearningPathRules.passMark(1))
        assertEquals(0, LearningPathRules.passMark(0))
        assertTrue(LearningPathRules.isPassing(11, 20))
        assertFalse(LearningPathRules.isPassing(10, 20))
        assertFalse(LearningPathRules.isPassing(0, 0))
    }

    @Test
    fun freshPathOpensOnlyTheFirstCourse() {
        val path = snapshot()
        assertEquals(listOf("one", "two", "three"), path.levels.map { it.id })
        assertEquals(listOf(1, 2, 3), path.levels.map { it.number })
        assertEquals(PathNodeState.AVAILABLE, path.state("one|a"))
        assertEquals(PathNodeState.LOCKED, path.state("one|b"))
        assertEquals(PathNodeState.LOCKED, path.state("one|quiz"))
        assertEquals(PathNodeState.LOCKED, path.state("two|c"))
        assertEquals("one|a", path.currentNodeId)
        // Ids the language lacks are skipped, the rest keep their order.
        assertEquals(listOf("two|c", "two|d", "two|quiz"), path.levels[1].nodes.map { it.id })
    }

    @Test
    fun coursesOpenInOrderAndTheQuizOnceAllAreDone() {
        val half = snapshot(completed = setOf("a"))
        assertEquals(PathNodeState.COMPLETED, half.state("one|a"))
        assertEquals(PathNodeState.AVAILABLE, half.state("one|b"))
        assertEquals(PathNodeState.LOCKED, half.state("one|quiz"))

        // A course finished out of order (from the home) is completed, but does not skip ahead.
        val outOfOrder = snapshot(completed = setOf("b"))
        assertEquals(PathNodeState.AVAILABLE, outOfOrder.state("one|a"))
        assertEquals(PathNodeState.COMPLETED, outOfOrder.state("one|b"))
        assertEquals(PathNodeState.LOCKED, outOfOrder.state("one|quiz"))
        assertEquals(1, outOfOrder.levels[0].completedCourseCount)

        val done = snapshot(completed = setOf("a", "b"))
        assertEquals(PathNodeState.AVAILABLE, done.state("one|quiz"))
        assertEquals("one|quiz", done.currentNodeId)
        // Courses of a locked level stay locked even when already read.
        assertEquals(PathNodeState.LOCKED, snapshot(completed = setOf("a", "b", "c")).state("two|c"))
    }

    @Test
    fun passingTheQuizOpensTheNextLevel() {
        val path = snapshot(completed = setOf("a", "b", "c"), passed = setOf("one"))
        assertEquals(PathNodeState.COMPLETED, path.state("one|quiz"))
        assertTrue(path.levels[1].isUnlocked)
        assertEquals(PathNodeState.COMPLETED, path.state("two|c"))
        assertEquals(PathNodeState.AVAILABLE, path.state("two|d"))
        assertEquals("two", path.activeLevel?.id)
        assertFalse(path.levels[2].isUnlocked)
    }

    @Test
    fun aLevelPassedElsewhereStaysOpenAndEverythingPassedEndsThePath() {
        // Passed on the other platform while an earlier level is not: it stays open.
        val path = snapshot(passed = setOf("two"))
        assertTrue(path.levels[1].isUnlocked)
        assertTrue(path.levels[2].isUnlocked)

        val all = snapshot(completed = setOf("a", "b", "c", "d", "e"), passed = setOf("one", "two", "three"))
        assertTrue(all.isEverythingPassed)
        assertNull(all.currentNodeId)
    }

    @Test
    fun theWaveCarriesOnAcrossLevels() {
        val path = snapshot()
        assertEquals(listOf(0, 3, 6), path.levels.map { it.wavePhase })
        assertEquals("two", path.levelContaining("two|d")?.id)
        assertEquals(PathNodeState.COMPLETED > PathNodeState.AVAILABLE, true)
        assertEquals(PathNodeState.AVAILABLE > PathNodeState.LOCKED, true)
    }

    private fun questions(courseId: String, count: Int) = List(count) { index ->
        QuizQuestion(id = "$courseId-$index", question = "?")
    }

    @Test
    fun quizDrawSpreadsOverCoursesAndCapsAtTwenty() {
        val pools = listOf(
            course("a") to questions("a", 15),
            course("b") to questions("b", 15),
            course("c") to questions("c", 3),
            course("d") to emptyList(),
        )
        val drawn = PathQuizBuilder.questions(pools, random = Random(7))
        assertEquals(20, drawn.size)
        assertEquals(20, drawn.map { it.question.id }.distinct().size)
        val perCourse = drawn.groupingBy { it.course.id }.eachCount()
        // Round robin: the small pool is used up, the others share the rest evenly.
        assertEquals(3, perCourse["c"])
        assertTrue(perCourse.getValue("a") in 8..9 && perCourse.getValue("b") in 8..9)
        assertTrue(drawn.all { it.question.id.startsWith(it.course.id) })
    }

    @Test
    fun quizDrawUsesEverythingWhenTheLevelHasFewerQuestions() {
        val drawn = PathQuizBuilder.questions(listOf(course("a") to questions("a", 4), course("b") to questions("b", 2)))
        assertEquals(6, drawn.size)
        assertEquals(6, PathQuizBuilder.plannedCount(6))
        assertEquals(20, PathQuizBuilder.plannedCount(42))
        assertTrue(PathQuizBuilder.questions(listOf(course("a") to emptyList())).isEmpty())
    }

    @Test
    fun levelResultsWrittenByIosSurviveARoundTrip() {
        val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }
        // As iOS writes it: no `passedAt` while the level is not passed.
        val ios = """
            {"courseProgress":{},"streak":3,"pathLevelResults":{
              "one":{"bestCorrect":14,"bestTotal":20,"attempts":2,"passedAt":"2026-10-01T09:30:00Z","xpAwarded":true},
              "two":{"bestCorrect":6,"bestTotal":20,"attempts":1,"xpAwarded":false}
            }}
        """.trimIndent()
        val progress = json.decodeFromString<UserProgress>(ios)
        assertTrue(progress.pathLevelResults.getValue("one").isPassed)
        assertTrue(progress.pathLevelResults.getValue("one").xpAwarded)
        assertFalse(progress.pathLevelResults.getValue("two").isPassed)
        assertEquals(6, progress.pathLevelResults.getValue("two").bestCorrect)

        val again = json.decodeFromString<UserProgress>(json.encodeToString(UserProgress.serializer(), progress))
        assertEquals(progress.pathLevelResults, again.pathLevelResults)
    }
}
