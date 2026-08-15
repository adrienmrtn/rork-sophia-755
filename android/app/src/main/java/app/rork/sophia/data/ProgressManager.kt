package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.SophiaApplication
import app.rork.sophia.domain.CollectionProgressEvent
import app.rork.sophia.domain.Course
import app.rork.sophia.domain.CourseProgress
import app.rork.sophia.domain.GlobalLevelProgress
import app.rork.sophia.domain.GlobalRank
import app.rork.sophia.domain.LearningCollection
import app.rork.sophia.domain.PendingGlobalRankUp
import app.rork.sophia.domain.QuizQuestion
import app.rork.sophia.domain.TrainingQuestionState
import app.rork.sophia.domain.UserProgress
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.time.Instant
import java.time.LocalDate
import java.time.format.DateTimeFormatter

class ProgressManager(context: Context) {
    private val prefs = context.getSharedPreferences("sophia_prefs", Context.MODE_PRIVATE)
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }
    private val lock = Any()
    private val _progress = MutableStateFlow(load())
    val progress: StateFlow<UserProgress> = _progress.asStateFlow()

    var onProgressChanged: ((UserProgress) -> Unit)? = null

    private fun today(): String = LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE)

    private fun load(): UserProgress {
        val raw = prefs.getString(KEY, null) ?: return UserProgress()
        return try {
            json.decodeFromString<UserProgress>(raw)
        } catch (_: Exception) {
            UserProgress()
        }
    }

    private fun persist(value: UserProgress) {
        prefs.edit().putString(KEY, json.encodeToString(value)).apply()
        _progress.value = value
        onProgressChanged?.invoke(value)
    }

    /**
     * Single entry point for progress writes.
     *
     * [transform] must stay free of side effects on [_progress]: it is a plain
     * read-modify-write under [lock], not a compare-and-set retry, so writing the
     * flow from inside it would publish an intermediate state.
     */
    private fun mutate(transform: (UserProgress) -> UserProgress) {
        synchronized(lock) {
            val current = _progress.value
            val next = transform(current)
            if (next == current) return
            persist(next)
        }
    }

    fun isFavorite(courseId: String): Boolean =
        courseId in _progress.value.favoriteCourseIds

    fun toggleFavorite(courseId: String) {
        mutate { current ->
            val favs = current.favoriteCourseIds.toMutableList()
            if (courseId in favs) favs.remove(courseId) else favs.add(courseId)
            current.copy(favoriteCourseIds = favs)
        }
    }

    fun incrementFreeCoursesOpened() {
        mutate { current ->
            current.copy(freeCoursesOpened = current.freeCoursesOpened + 1)
        }
    }

    fun claimDailyFreeCourseIfNeeded(courseId: String) {
        val today = today()
        mutate { current ->
            if (current.dailyFreeCourseDate == today && current.dailyFreeCourseId != null) {
                current
            } else {
                current.copy(
                    dailyFreeCourseId = courseId,
                    dailyFreeCourseDate = today,
                )
            }
        }
    }

    fun isDailyFreeCourse(courseId: String): Boolean {
        val p = _progress.value
        return p.dailyFreeCourseDate == today() && p.dailyFreeCourseId == courseId
    }

    fun courseProgress(courseId: String): CourseProgress? =
        _progress.value.courseProgress[courseId]

    fun updateLessonIndex(courseId: String, index: Int) {
        mutate { current ->
            val map = current.courseProgress.toMutableMap()
            val existing = map[courseId] ?: CourseProgress()
            map[courseId] = existing.copy(lastLessonIndex = maxOf(existing.lastLessonIndex, index))
            current.copy(courseProgress = map)
        }
    }

    fun markCourseCompleted(courseId: String) {
        mutate { current ->
            val map = current.courseProgress.toMutableMap()
            val existing = map[courseId] ?: CourseProgress()
            map[courseId] = existing.copy(isCompleted = true)
            val awarded = current.globalCourseXPAwardedIds.toMutableList()
            var globalXP = current.globalXP
            var pending = current.pendingGlobalRankUp
            if (courseId !in awarded) {
                awarded.add(courseId)
                val before = globalLevelProgress(globalXP)
                globalXP += 50
                val after = globalLevelProgress(globalXP)
                if (before.rank != after.rank) {
                    pending = PendingGlobalRankUp(
                        previousRankRawValue = before.rank.storageKey,
                        newRankRawValue = after.rank.storageKey,
                        newLevel = after.level,
                    )
                }
            }
            current.copy(
                courseProgress = map,
                globalCourseXPAwardedIds = awarded,
                globalXP = globalXP,
                pendingGlobalRankUp = pending,
                lastCourseCompletedDate = today(),
                streak = bumpStreak(current),
                lastActiveDate = today(),
            )
        }
    }

    fun completeQuiz(courseId: String, score: Int, questionIds: List<String>, subjectKey: String) {
        mutate { current ->
            val map = current.courseProgress.toMutableMap()
            val existing = map[courseId] ?: CourseProgress()
            map[courseId] = existing.copy(
                isCompleted = true,
                bestQuizScore = maxOf(existing.bestQuizScore, score),
                lastQuizDate = Instant.now().toString(),
            )
            val completedQuizzes = current.completedQuizCourseIds.toMutableList()
            if (courseId !in completedQuizzes) completedQuizzes.add(courseId)

            val quizAwarded = current.globalQuizXPAwardedIds.toMutableList()
            var globalXP = current.globalXP
            var pending = current.pendingGlobalRankUp
            if (courseId !in quizAwarded) {
                quizAwarded.add(courseId)
                val before = globalLevelProgress(globalXP)
                globalXP += 50
                val after = globalLevelProgress(globalXP)
                if (before.rank != after.rank) {
                    pending = PendingGlobalRankUp(
                        previousRankRawValue = before.rank.storageKey,
                        newRankRawValue = after.rank.storageKey,
                        newLevel = after.level,
                    )
                }
            }

            val subjectXP = current.subjectXP.toMutableMap()
            subjectXP[subjectKey] = (subjectXP[subjectKey] ?: 0) + 10

            val training = current.trainingQuestionStates.toMutableMap()
            for (qid in questionIds) {
                if (qid !in training) {
                    training[qid] = TrainingQuestionState(courseId = courseId)
                }
            }

            current.copy(
                courseProgress = map,
                completedQuizCourseIds = completedQuizzes,
                globalQuizXPAwardedIds = quizAwarded,
                globalXP = globalXP,
                pendingGlobalRankUp = pending,
                subjectXP = subjectXP,
                trainingQuestionStates = training,
                streak = bumpStreak(current),
                lastActiveDate = today(),
                lastCourseCompletedDate = today(),
            )
        }
    }

    fun dueTrainingQuestionIds(): List<String> {
        val now = Instant.now()
        return _progress.value.trainingQuestionStates.mapNotNull { (id, state) ->
            val due = state.nextReviewDate
            if (due == null) id
            else {
                runCatching { Instant.parse(due) <= now }.getOrDefault(true).let { if (it) id else null }
            }
        }
    }

    fun recordTrainingAnswer(questionId: String, courseId: String, correct: Boolean) {
        mutate { current ->
            val map = current.trainingQuestionStates.toMutableMap()
            var state = map[questionId] ?: TrainingQuestionState(courseId = courseId)
            state = if (correct) {
                val days = TRAINING_INTERVALS[minOf(state.intervalIndex, TRAINING_INTERVALS.lastIndex)]
                val next = Instant.now().plusSeconds(days * 24L * 3600L).toString()
                state.copy(
                    nextReviewDate = next,
                    intervalIndex = minOf(state.intervalIndex + 1, TRAINING_INTERVALS.lastIndex),
                )
            } else {
                state.copy(intervalIndex = 0, nextReviewDate = null)
            }
            map[questionId] = state
            current.copy(trainingQuestionStates = map)
        }
    }

    fun resolveDueQuestions(courses: List<Course>): List<Pair<Course, QuizQuestion>> {
        val due = dueTrainingQuestionIds().toSet()
        val out = mutableListOf<Pair<Course, QuizQuestion>>()
        for (course in courses) {
            for (q in course.quiz) {
                if (q.id in due) out += course to q
            }
        }
        return out
    }

    private fun bumpStreak(current: UserProgress): Int {
        val today = today()
        val last = current.lastActiveDate
        val next = when {
            last == today -> current.streak.coerceAtLeast(1)
            last == LocalDate.now().minusDays(1).format(DateTimeFormatter.ISO_LOCAL_DATE) ->
                current.streak + 1
            else -> 1
        }
        if (next > current.streak) {
            runCatching {
                SophiaApplication.instance.analytics.trackStreakUpdated(
                    streakDays = next,
                    isNewRecord = true,
                )
            }
        }
        return next
    }

    fun replaceAll(progress: UserProgress) {
        synchronized(lock) { persist(progress) }
    }

    fun resetProgress() {
        synchronized(lock) { persist(UserProgress()) }
    }

    fun clearPendingRankUp() {
        mutate { current ->
            current.copy(pendingGlobalRankUp = null)
        }
    }

    fun markStreakShownToday() {
        mutate { current ->
            current.copy(lastStreakShownDate = today())
        }
    }

    fun shouldShowStreakCelebration(): Boolean {
        val p = _progress.value
        return p.streak > 0 && p.lastStreakShownDate != today()
    }

    fun recordFirstCourseOpenedIfNeeded(courseId: String) {
        mutate { current ->
            if (current.firstCourseOpenedId != null) current
            else current.copy(firstCourseOpenedId = courseId)
        }
    }

    val firstCourseOpenedId: String?
        get() = _progress.value.firstCourseOpenedId

    val hasRequestedAppStoreReview: Boolean
        get() = _progress.value.hasRequestedAppStoreReview

    fun markAppStoreReviewRequested() {
        mutate { current ->
            current.copy(hasRequestedAppStoreReview = true)
        }
    }

    val hasSeenCourseTermsCoachmark: Boolean
        get() = _progress.value.hasSeenCourseTermsCoachmark

    fun markCourseTermsCoachmarkSeen() {
        mutate { current ->
            current.copy(hasSeenCourseTermsCoachmark = true)
        }
    }

    fun completedCount(collection: LearningCollection): Int =
        completedCount(_progress.value, collection)

    private fun completedCount(progress: UserProgress, collection: LearningCollection): Int =
        collection.courseIds.count { id ->
            progress.courseProgress[id]?.isCompleted == true
        }

    fun collectionProgressEvents(
        newlyCompletedCourseId: String,
        collections: List<LearningCollection>,
    ): List<CollectionProgressEvent> {
        return collections.mapNotNull { collection ->
            if (newlyCompletedCourseId !in collection.courseIds) return@mapNotNull null
            val newCount = completedCount(collection)
            val previousCount = (newCount - 1).coerceAtLeast(0)
            if (newCount <= previousCount) return@mapNotNull null
            CollectionProgressEvent(
                collection = collection,
                previousCompletedCount = previousCount,
                newCompletedCount = newCount,
                totalCount = collection.courseIds.size,
            )
        }
    }

    fun awardCollectionCompletionXpIfNeeded(collection: LearningCollection) {
        mutate { current ->
            if (collection.id in current.globalCollectionXPAwardedIds) return@mutate current
            if (completedCount(current, collection) < collection.courseIds.size ||
                collection.courseIds.isEmpty()
            ) {
                return@mutate current
            }
            val awarded = current.globalCollectionXPAwardedIds.toMutableList()
            awarded.add(collection.id)
            val xpGain = collection.courseIds.size * 25
            var globalXP = current.globalXP
            var pending = current.pendingGlobalRankUp
            val before = globalLevelProgress(globalXP)
            globalXP += xpGain
            val after = globalLevelProgress(globalXP)
            if (before.rank != after.rank) {
                pending = PendingGlobalRankUp(
                    previousRankRawValue = before.rank.storageKey,
                    newRankRawValue = after.rank.storageKey,
                    newLevel = after.level,
                )
            }
            current.copy(
                globalCollectionXPAwardedIds = awarded,
                globalXP = globalXP,
                pendingGlobalRankUp = pending,
            )
        }
    }

    companion object {
        private const val KEY = "sophia_user_progress"
        val TRAINING_INTERVALS = listOf(1, 3, 7, 14, 30)

        fun globalLevelProgress(xp: Int): GlobalLevelProgress {
            // Same curve spirit as iOS: level 1..100 from cumulative XP.
            var level = 1
            var remaining = xp
            var need = 50
            while (level < 100 && remaining >= need) {
                remaining -= need
                level += 1
                need = 50 + (level - 1) * 10
            }
            val rank = GlobalRank.forLevel(level)
            return GlobalLevelProgress(level, rank, remaining, need)
        }
    }
}
