package app.rork.sophia.data

/**
 * Tracks in-course engagement for `course_session_ended` (parity with iOS CourseSessionTracker).
 */
class CourseSessionTracker(
    private val courseId: String,
    private val subject: String,
    private val lessonCount: Int,
) {
    private val startedAtMs = System.currentTimeMillis()
    private var maxLessonReached = 0
    private var continueTaps = 0
    private var scrolledOnFirstLesson = false
    private var completed = false
    private var exitReason = "back"

    fun recordLessonReached(index: Int) {
        if (index > maxLessonReached) maxLessonReached = index
    }

    fun recordContinueTap() {
        continueTaps += 1
    }

    fun recordScrollOnFirstLesson() {
        scrolledOnFirstLesson = true
    }

    fun markCompleted() {
        completed = true
        exitReason = "completed"
    }

    fun markQuiz() {
        exitReason = "quiz"
    }

    fun engagementTier(): String {
        val durationSec = ((System.currentTimeMillis() - startedAtMs) / 1000).toInt()
        val progress = if (lessonCount <= 0) 0f else (maxLessonReached + 1).toFloat() / lessonCount
        return when {
            completed || progress >= 0.9f -> "deep"
            progress >= 0.4f || continueTaps >= 3 || durationSec >= 90 -> "engaged"
            else -> "bounce"
        }
    }

    fun endProps(): Map<String, Any?> {
        val durationSec = ((System.currentTimeMillis() - startedAtMs) / 1000).toInt()
        val progressPct = if (lessonCount <= 0) {
            0
        } else {
            (((maxLessonReached + 1).toFloat() / lessonCount) * 100).toInt().coerceIn(0, 100)
        }
        return mapOf(
            "course_id" to courseId,
            "subject" to subject,
            "lesson_index" to maxLessonReached,
            "lesson_count" to lessonCount,
            "lessons_reached" to (maxLessonReached + 1),
            "progress_pct" to progressPct,
            "duration_seconds" to durationSec,
            "continue_taps" to continueTaps,
            "scrolled_on_first_lesson" to scrolledOnFirstLesson,
            "engagement_tier" to engagementTier(),
            "exit_reason" to exitReason,
            "completed" to completed,
        )
    }
}
