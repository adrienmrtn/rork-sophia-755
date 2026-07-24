package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.domain.CourseProgress
import app.rork.sophia.domain.UserProgress
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.time.LocalDate
import java.time.format.DateTimeFormatter

class ProgressManager(context: Context) {
    private val prefs = context.getSharedPreferences("sophia_prefs", Context.MODE_PRIVATE)
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }
    private val _progress = MutableStateFlow(load())
    val progress: StateFlow<UserProgress> = _progress.asStateFlow()

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
    }

    fun isFavorite(courseId: String): Boolean =
        courseId in _progress.value.favoriteCourseIds

    fun toggleFavorite(courseId: String) {
        _progress.update { current ->
            val favs = current.favoriteCourseIds.toMutableList()
            if (courseId in favs) favs.remove(courseId) else favs.add(courseId)
            current.copy(favoriteCourseIds = favs).also { persist(it) }
        }
    }

    fun incrementFreeCoursesOpened() {
        _progress.update { current ->
            current.copy(freeCoursesOpened = current.freeCoursesOpened + 1).also { persist(it) }
        }
    }

    fun claimDailyFreeCourseIfNeeded(courseId: String) {
        val today = today()
        _progress.update { current ->
            if (current.dailyFreeCourseDate == today && current.dailyFreeCourseId != null) {
                current
            } else {
                current.copy(
                    dailyFreeCourseId = courseId,
                    dailyFreeCourseDate = today,
                ).also { persist(it) }
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
        _progress.update { current ->
            val map = current.courseProgress.toMutableMap()
            val existing = map[courseId] ?: CourseProgress()
            map[courseId] = existing.copy(lastLessonIndex = maxOf(existing.lastLessonIndex, index))
            current.copy(courseProgress = map).also { persist(it) }
        }
    }

    fun markCourseCompleted(courseId: String) {
        _progress.update { current ->
            val map = current.courseProgress.toMutableMap()
            val existing = map[courseId] ?: CourseProgress()
            map[courseId] = existing.copy(isCompleted = true)
            val awarded = current.globalCourseXPAwardedIds.toMutableList()
            var globalXP = current.globalXP
            if (courseId !in awarded) {
                awarded.add(courseId)
                globalXP += 50
            }
            current.copy(
                courseProgress = map,
                globalCourseXPAwardedIds = awarded,
                globalXP = globalXP,
                lastCourseCompletedDate = today(),
                streak = bumpStreak(current),
                lastActiveDate = today(),
            ).also { persist(it) }
        }
    }

    private fun bumpStreak(current: UserProgress): Int {
        val today = today()
        val last = current.lastActiveDate
        return when {
            last == today -> current.streak.coerceAtLeast(1)
            last == LocalDate.now().minusDays(1).format(DateTimeFormatter.ISO_LOCAL_DATE) ->
                current.streak + 1
            else -> 1
        }
    }

    fun replaceAll(progress: UserProgress) {
        persist(progress)
    }

    companion object {
        private const val KEY = "sophia_user_progress"
    }
}
