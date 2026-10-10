package app.rork.sophia.domain

import kotlin.random.Random

/**
 * The learning path ("Parcours" tab): every collection is a level, laid out in catalogue
 * order. Inside a level the courses open one after the other, the level ends with a quiz
 * mixing questions from its courses, and passing that quiz opens the next level.
 * Same rules as iOS (`LearningPath.swift`).
 */
object LearningPathRules {
    /** Questions drawn for an end-of-level quiz. A level with fewer questions uses them all. */
    const val QUIZ_QUESTION_COUNT = 20

    /** Fully correct answers needed to pass: strictly more than half, so 11 of 20. */
    fun passMark(total: Int): Int = if (total <= 0) 0 else total / 2 + 1

    fun isPassing(correct: Int, total: Int): Boolean = total > 0 && correct >= passMark(total)
}

/** Declared from least to most advanced, so states compare by progress. */
enum class PathNodeState(val storageKey: String) {
    LOCKED("locked"),
    AVAILABLE("available"),
    COMPLETED("completed");

    companion object {
        fun fromStorageKey(key: String): PathNodeState? = entries.firstOrNull { it.storageKey == key }
    }
}

/** One pod on the trail: a course of the level, or the quiz that closes it ([course] null). */
data class PathNode(
    val id: String,
    val course: CourseSummary?,
    val state: PathNodeState,
    /** Position within the level, the quiz last. */
    val index: Int,
) {
    val isQuiz: Boolean get() = course == null
}

data class PathLevel(
    val collection: LearningCollection,
    /** Level number shown to the reader, from 1. */
    val number: Int,
    /** Course nodes in collection order, then the quiz node. */
    val nodes: List<PathNode>,
    val isUnlocked: Boolean,
    val isPassed: Boolean,
    val completedCourseCount: Int,
    /** Where the zigzag was when this level started, so the curve flows across levels. */
    val wavePhase: Int,
) {
    val id: String get() = collection.id
    val courseCount: Int get() = (nodes.size - 1).coerceAtLeast(0)
    val courses: List<CourseSummary> get() = nodes.mapNotNull { it.course }

    /** The node the reader plays next, when this is the active level. */
    val currentNodeId: String?
        get() = if (!isUnlocked || isPassed) null else nodes.firstOrNull { it.state == PathNodeState.AVAILABLE }?.id
}

data class LearningPathSnapshot(val levels: List<PathLevel>) {
    /** The level being played: unlocked but not yet passed. Null once everything is passed. */
    val activeLevel: PathLevel? get() = levels.firstOrNull { it.isUnlocked && !it.isPassed }

    val currentNodeId: String? get() = activeLevel?.currentNodeId

    val isEverythingPassed: Boolean get() = levels.isNotEmpty() && levels.all { it.isPassed }

    /** Every node's state, keyed by node id, for diffing against what the reader last saw. */
    val nodeStates: Map<String, PathNodeState>
        get() = buildMap { levels.forEach { level -> level.nodes.forEach { put(it.id, it.state) } } }

    val orderedNodeIds: List<String> get() = levels.flatMap { level -> level.nodes.map { it.id } }

    fun levelContaining(nodeId: String): PathLevel? =
        levels.firstOrNull { level -> level.nodes.any { it.id == nodeId } }

    companion object {
        val EMPTY = LearningPathSnapshot(emptyList())

        /** A course can belong to several collections, so its node id carries the collection. */
        fun courseNodeId(collectionId: String, courseId: String): String = "$collectionId|$courseId"

        fun quizNodeId(collectionId: String): String = "$collectionId|quiz"
    }
}

/**
 * Derives the whole path from the catalogue and the reader's progress. A course finished
 * anywhere in the app (home, library) counts as a completed pod.
 */
object LearningPathEngine {
    fun snapshot(
        collections: List<LearningCollection>,
        coursesById: Map<String, CourseSummary>,
        isCourseCompleted: (String) -> Boolean,
        isLevelPassed: (String) -> Boolean,
    ): LearningPathSnapshot {
        val levels = mutableListOf<PathLevel>()
        var previousPassed = true
        var wavePhase = 0

        for (collection in collections) {
            // Ids the language does not carry (withheld, not translated) are not pods.
            val courses = collection.courseIds.mapNotNull { coursesById[it] }
            if (courses.isEmpty()) continue

            val isPassed = isLevelPassed(collection.id)
            val isUnlocked = previousPassed || isPassed
            val nodes = mutableListOf<PathNode>()
            var everythingBeforeDone = true
            var completedCount = 0

            courses.forEachIndexed { position, course ->
                val isDone = isCourseCompleted(course.id)
                if (isDone) completedCount += 1
                val state = when {
                    !isUnlocked -> PathNodeState.LOCKED
                    isDone -> PathNodeState.COMPLETED
                    // The first unfinished course is the one to play; the ones after wait.
                    everythingBeforeDone -> PathNodeState.AVAILABLE
                    else -> PathNodeState.LOCKED
                }
                everythingBeforeDone = everythingBeforeDone && isDone
                nodes += PathNode(
                    id = LearningPathSnapshot.courseNodeId(collection.id, course.id),
                    course = course,
                    state = state,
                    index = position,
                )
            }

            val quizState = when {
                !isUnlocked -> PathNodeState.LOCKED
                isPassed -> PathNodeState.COMPLETED
                everythingBeforeDone -> PathNodeState.AVAILABLE
                else -> PathNodeState.LOCKED
            }
            nodes += PathNode(
                id = LearningPathSnapshot.quizNodeId(collection.id),
                course = null,
                state = quizState,
                index = courses.size,
            )

            levels += PathLevel(
                collection = collection,
                number = levels.size + 1,
                nodes = nodes,
                isUnlocked = isUnlocked,
                isPassed = isPassed,
                completedCourseCount = completedCount,
                wavePhase = wavePhase,
            )
            wavePhase += nodes.size
            previousPassed = isPassed
        }
        return LearningPathSnapshot(levels)
    }
}

/** A question drawn for a level quiz, with the course it comes from. */
data class PathQuizItem(val course: CourseSummary, val question: QuizQuestion)

object PathQuizBuilder {
    /**
     * Up to [count] questions spread as evenly as possible over the level's courses, in
     * random order. Every attempt draws afresh, so a retry is never the same quiz.
     */
    fun questions(
        quizzes: List<Pair<CourseSummary, List<QuizQuestion>>>,
        count: Int = LearningPathRules.QUIZ_QUESTION_COUNT,
        random: Random = Random.Default,
    ): List<PathQuizItem> {
        val pools = quizzes
            .filter { it.second.isNotEmpty() }
            .map { (course, quiz) -> course to quiz.shuffled(random).toMutableList() }
            .shuffled(random)
        if (pools.isEmpty()) return emptyList()

        val picked = mutableListOf<PathQuizItem>()
        var exhausted = false
        while (picked.size < count && !exhausted) {
            exhausted = true
            for ((course, remaining) in pools) {
                if (picked.size >= count) break
                if (remaining.isNotEmpty()) {
                    picked += PathQuizItem(course, remaining.removeAt(remaining.lastIndex))
                    exhausted = false
                }
            }
        }
        return picked.shuffled(random)
    }

    /** How many questions a quiz over these courses actually draws. */
    fun plannedCount(availableQuestions: Int): Int =
        minOf(LearningPathRules.QUIZ_QUESTION_COUNT, availableQuestions)
}
