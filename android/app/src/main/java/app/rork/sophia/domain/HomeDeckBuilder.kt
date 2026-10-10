package app.rork.sophia.domain

import kotlinx.serialization.Serializable
import kotlin.random.Random

/**
 * The observed half of the home deck, generated with the iOS one by
 * `scripts/build_course_affinity.py` (`assets/course_affinity.json`): how often each course
 * is finished, and which courses are read by the same people.
 */
@Serializable
data class CourseAffinity(
    /** How often the deck should serve each subject before the reader's history bends it. */
    val subjectBaseWeight: Map<String, Double> = emptyMap(),
    /** Observed quality, 0–1 within the course's own subject. */
    val quality: Map<String, Double> = emptyMap(),
    /** Courses read by the same people, best lift first. */
    val neighbourIds: Map<String, List<String>> = emptyMap(),
    /** Lift of each pair in [neighbourIds], same order. */
    val neighbourLifts: Map<String, List<Double>> = emptyMap(),
) {
    /** Neighbours of [courseId] as (id, lift), strongest first. */
    fun neighbours(courseId: String): List<Pair<String, Double>> {
        val ids = neighbourIds[courseId] ?: return emptyList()
        val lifts = neighbourLifts[courseId] ?: return emptyList()
        return ids.zip(lifts)
    }

    companion object {
        /** No model at all: equal subjects, middling quality, no neighbours. */
        val NONE = CourseAffinity()
    }
}

/**
 * What the deck knows about a reader, gathered in one place so the builder stays a pure
 * function. Same signals as iOS's `DeckContext`.
 */
data class DeckContext(
    /** Courses finished, by subject storage key. Favourites are not used: the onboarding swipe writes its likes into them. */
    val completedBySubject: Map<String, Int> = emptyMap(),
    /** Courses read most recently, most recent first. */
    val recentCourseIds: List<String> = emptyList(),
    /** Subjects picked during onboarding: a hint for the first few cards, nothing more. */
    val objectiveSubjects: Set<String> = emptySet(),
    /** How many times each course has been dealt and swiped past without opening. */
    val skipCounts: Map<String, Int> = emptyMap(),
) {
    companion object {
        val EMPTY = DeckContext()

        /**
         * The signals out of stored progress: finished courses per subject, and the courses
         * most recently started or finished (ISO-8601 dates compare as strings).
         */
        fun from(
            progress: UserProgress,
            catalogue: List<CourseSummary>,
            objectiveSubjects: Set<String>,
            skipCounts: Map<String, Int>,
        ): DeckContext {
            val subjectsById = catalogue.associate { it.id to it.subjectEnum.storageKey }
            val completedBySubject = mutableMapOf<String, Int>()
            val recency = mutableListOf<Pair<String, String>>()
            for ((courseId, courseProgress) in progress.courseProgress) {
                val subject = subjectsById[courseId] ?: continue
                if (courseProgress.isCompleted) {
                    completedBySubject[subject] = (completedBySubject[subject] ?: 0) + 1
                }
                val stamp = maxOf(courseProgress.completedAt.orEmpty(), courseProgress.startedAt.orEmpty())
                if (stamp.isNotEmpty()) recency += courseId to stamp
            }
            val recent = recency.sortedByDescending { it.second }
                .take(HomeDeckBuilder.RECENT_WINDOW)
                .map { it.first }
            return DeckContext(completedBySubject, recent, objectiveSubjects, skipCounts)
        }
    }
}

/**
 * Builds the home course deck: which subject each card comes from, and which course within
 * it. Port of iOS's `HomeDeckBuilder`, which replaced a plain shuffle.
 *
 * - **Quotas, never filters.** No subject is ever excluded.
 * - **A pattern, not a ranking.** Subjects are drawn by weight, never three times in a row.
 * - **A floor under every subject**, so none quietly disappears from a reader's deck.
 * - One card in four is drawn at random outside the dominant subject: the exploration that
 *   keeps the affinity numbers refreshable without training on their own picks.
 */
object HomeDeckBuilder {
    const val EXPLORATION_EVERY = 4
    const val SUBJECT_FLOOR = 0.05
    const val AFFINITY_STRENGTH = 1.5
    const val OBJECTIVE_BONUS = 1.2
    const val OBJECTIVE_FADES_AFTER = 3
    const val RECENT_WINDOW = 5
    const val MAX_CONSECUTIVE_SAME_SUBJECT = 2

    private const val LIFT_FOR_FULL_BOOST = 10.0
    private const val NEIGHBOUR_BOOST_CEILING = 0.8
    private const val FATIGUE_PER_SKIP = 0.15
    private const val FATIGUE_CEILING = 0.6
    /** Quality of a course the model has never seen: the middle, neither buried nor promoted. */
    private const val UNKNOWN_QUALITY = 0.5

    private val SUBJECT_KEYS = Subject.entries.map { it.storageKey }

    /** The deck for this visit, unfinished courses only, best first. */
    fun deck(
        courses: List<CourseSummary>,
        affinity: CourseAffinity,
        context: DeckContext = DeckContext.EMPTY,
        isCompleted: (String) -> Boolean,
        random: Random = Random.Default,
    ): List<CourseSummary> {
        val candidates = courses.filterNot { isCompleted(it.id) }
        if (candidates.isEmpty()) return emptyList()

        val weights = subjectWeights(affinity, context)
        val dominant = weights.maxByOrNull { it.value }?.key

        // Best-scoring course first within each subject; the draw only ever takes the head.
        val pools = candidates
            .groupBy { it.subjectEnum.storageKey }
            .mapValues { (_, pool) ->
                pool.sortedByDescending { score(it, affinity, context) }.toMutableList()
            }
            .toMutableMap()

        val deck = ArrayList<CourseSummary>(candidates.size)
        val recentSubjects = ArrayDeque<String>()

        while (pools.isNotEmpty()) {
            val blocked = blockedSubject(recentSubjects)
            val isExploration = (deck.size + 1) % EXPLORATION_EVERY == 0

            val key = (if (isExploration) explorationSubject(pools, blocked, dominant, random) else null)
                ?: drawSubject(pools, weights, blocked, random)
                ?: break
            val pool = pools[key]
            if (pool.isNullOrEmpty()) {
                pools.remove(key)
                continue
            }
            // Exploration deliberately ignores the score: a card nobody would have ranked
            // highly is the only kind that teaches the model something new.
            val index = if (isExploration) random.nextInt(pool.size) else 0
            deck += pool.removeAt(index)
            if (pool.isEmpty()) pools.remove(key)

            recentSubjects.addLast(key)
            if (recentSubjects.size > MAX_CONSECUTIVE_SAME_SUBJECT) recentSubjects.removeFirst()
        }
        return deck
    }

    /**
     * How much of the deck each subject gets, summing to 1: the average reader's shares, bent
     * by how the reader's finished courses differ from them, the objective's subjects nudged
     * while the reader is new, and every subject lifted to [SUBJECT_FLOOR].
     */
    fun subjectWeights(affinity: CourseAffinity, context: DeckContext): Map<String, Double> {
        val totalCompleted = context.completedBySubject.values.sum()
        val weights = SUBJECT_KEYS.associateWith { key ->
            val base = affinity.subjectBaseWeight[key] ?: (1.0 / SUBJECT_KEYS.size)
            var weight = base
            if (totalCompleted > 0) {
                val share = (context.completedBySubject[key] ?: 0).toDouble() / totalCompleted
                val bend = (share - base).coerceIn(-1.0, 1.0)
                weight = base * (1 + AFFINITY_STRENGTH * bend)
            }
            if (totalCompleted < OBJECTIVE_FADES_AFTER && key in context.objectiveSubjects) {
                weight *= OBJECTIVE_BONUS
            }
            maxOf(weight, 0.0)
        }
        return applyFloor(normalised(weights))
    }

    private fun normalised(weights: Map<String, Double>): Map<String, Double> {
        val total = weights.values.sum()
        if (total <= 0) return weights.mapValues { 1.0 / maxOf(weights.size, 1) }
        return weights.mapValues { it.value / total }
    }

    /** Lifts every subject to the floor, paid for by those above it, exactly, in one pass. */
    private fun applyFloor(weights: Map<String, Double>): Map<String, Double> {
        val deficit = weights.values.sumOf { maxOf(0.0, SUBJECT_FLOOR - it) }
        if (deficit <= 0) return weights
        val surplus = weights.values.sumOf { maxOf(0.0, it - SUBJECT_FLOOR) }
        if (surplus <= 0) return weights.mapValues { 1.0 / maxOf(weights.size, 1) }
        val scale = 1 - deficit / surplus
        return weights.mapValues { (_, w) ->
            if (w <= SUBJECT_FLOOR) SUBJECT_FLOOR else SUBJECT_FLOOR + (w - SUBJECT_FLOOR) * scale
        }
    }

    /** How well a course fits this reader, within its own subject. */
    fun score(course: CourseSummary, affinity: CourseAffinity, context: DeckContext): Double {
        val quality = affinity.quality[course.id] ?: UNKNOWN_QUALITY
        return quality + neighbourBoost(course, affinity, context) - fatigue(course, context)
    }

    /** How strongly the courses just read pull this one up (both directions are checked). */
    private fun neighbourBoost(course: CourseSummary, affinity: CourseAffinity, context: DeckContext): Double {
        var best = 0.0
        context.recentCourseIds.take(RECENT_WINDOW).forEachIndexed { position, recentId ->
            if (recentId == course.id) return@forEachIndexed
            val lift = maxOf(
                affinity.neighbours(recentId).firstOrNull { it.first == course.id }?.second ?: 0.0,
                affinity.neighbours(course.id).firstOrNull { it.first == recentId }?.second ?: 0.0,
            )
            if (lift <= 0) return@forEachIndexed
            val recency = 1 - 0.15 * position
            val strength = minOf(lift / LIFT_FOR_FULL_BOOST, 1.0) * NEIGHBOUR_BOOST_CEILING * recency
            best = maxOf(best, strength)
        }
        return best
    }

    /** Swiped past too often: demoted, never banished. */
    private fun fatigue(course: CourseSummary, context: DeckContext): Double {
        val skips = context.skipCounts[course.id] ?: 0
        return minOf(skips * FATIGUE_PER_SKIP, FATIGUE_CEILING)
    }

    /** The subject to keep out of the next draw, if the last cards were all from it. */
    private fun blockedSubject(recent: ArrayDeque<String>): String? {
        if (recent.size < MAX_CONSECUTIVE_SAME_SUBJECT) return null
        val last = recent.last()
        return if (recent.all { it == last }) last else null
    }

    private fun drawSubject(
        pools: Map<String, List<CourseSummary>>,
        weights: Map<String, Double>,
        blocked: String?,
        random: Random,
    ): String? {
        // Sorted: the draw must not depend on hash order.
        var available = pools.keys.filter { it != blocked }.sorted()
        // Blocking must never end the deck: when the run is all that is left, it continues.
        if (available.isEmpty()) available = pools.keys.sorted()
        if (available.isEmpty()) return null
        val total = available.sumOf { weights[it] ?: 0.0 }
        if (total <= 0) return available.random(random)
        var ticket = random.nextDouble(total)
        for (key in available) {
            ticket -= weights[key] ?: 0.0
            if (ticket <= 0) return key
        }
        return available.last()
    }

    private fun explorationSubject(
        pools: Map<String, List<CourseSummary>>,
        blocked: String?,
        dominant: String?,
        random: Random,
    ): String? {
        val available = pools.keys.filter { it != blocked && it != dominant }.sorted()
        // Uniform over subjects rather than courses: three courses left are as worth
        // exploring as thirty.
        return if (available.isEmpty()) null else available.random(random)
    }
}
