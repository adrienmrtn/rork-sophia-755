package app.rork.sophia.domain

import androidx.compose.ui.graphics.Color
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

enum class Subject(val storageKey: String, val color: Color) {
    HISTOIRE("histoire", Color(0xFFF59E0A)),
    SCIENCES("sciences", Color(0xFF33D499)),
    LITTERATURE("litterature", Color(0xFFED5973)),
    ART("art", Color(0xFFD98CF2)),
    MYTHOLOGIE("mythologie", Color(0xFF8F66EB)),
    COMPRENDRE_LE_MONDE("comprendreLeMonde", Color(0xFF40B8D9));

    companion object {
        fun fromStorageKey(key: String): Subject? =
            entries.firstOrNull { it.storageKey == key }
    }
}

@Serializable
data class LessonPage(
    val id: String,
    val title: String,
    val content: String,
)

@Serializable
enum class QuizQuestionType {
    @SerialName("mcq") MCQ,
    @SerialName("trueFalse") TRUE_FALSE,
    @SerialName("chronological") CHRONOLOGICAL,
    @SerialName("numericSlider") NUMERIC_SLIDER,
    @SerialName("percentageSlider") PERCENTAGE_SLIDER,
}

@Serializable
data class QuizQuestion(
    val id: String,
    val type: QuizQuestionType = QuizQuestionType.MCQ,
    val question: String,
    val explanation: String = "",
    val options: List<String>? = null,
    val correctIndex: Int? = null,
    val items: List<String>? = null,
    val correctValue: Double? = null,
    val sliderMin: Double? = null,
    val sliderMax: Double? = null,
    val tolerance: Double? = null,
    val unit: String? = null,
) {
    val maxPoints: Int
        get() = when (type) {
            QuizQuestionType.MCQ, QuizQuestionType.TRUE_FALSE -> 2
            else -> 3
        }
}

/** Home/library card fields only — avoids allocating lessons+quiz for the TikTok feed. */
@Serializable
data class CourseSummary(
    val id: String,
    val title: String,
    val description: String,
    val subject: String,
    val subcategory: String = "",
) {
    val subjectEnum: Subject
        get() = Subject.fromStorageKey(subject) ?: Subject.HISTOIRE
}

@Serializable
data class Course(
    val id: String,
    val title: String,
    val description: String,
    val subject: String,
    val subcategory: String,
    val lessons: List<LessonPage> = emptyList(),
    val quiz: List<QuizQuestion> = emptyList(),
) {
    val subjectEnum: Subject
        get() = Subject.fromStorageKey(subject) ?: Subject.HISTOIRE

    val hasQuiz: Boolean get() = quiz.isNotEmpty()

    val readsCount: Int
        get() {
            var hash = 0xcbf29ce484222325UL
            for (byte in id.encodeToByteArray()) {
                hash = hash xor byte.toULong()
                hash *= 0x100000001b3UL
            }
            val lower = 7_000
            val upper = 250_000
            val value = lower + (hash % (upper - lower).toULong()).toInt()
            return (value / 100) * 100
        }

    val readsCountShort: String
        get() {
            val count = readsCount
            return if (count < 10_000) {
                String.format("%.1f k", count / 1000.0).replace('.', ',')
            } else {
                "${count / 1000} k"
            }
        }
}

@Serializable
data class LearningCollection(
    val id: String,
    val title: String,
    val description: String,
    val coverAssetName: String = "",
    val courseIds: List<String> = emptyList(),
)

data class CollectionProgressEvent(
    val collection: LearningCollection,
    val previousCompletedCount: Int,
    val newCompletedCount: Int,
    val totalCount: Int,
) {
    val isComplete: Boolean get() = newCompletedCount >= totalCount && totalCount > 0
}

sealed class PostCompletionRewardStep {
    data class Streak(val days: Int) : PostCompletionRewardStep()
    data class RankUp(val rankKey: String, val level: Int) : PostCompletionRewardStep()
    data class Collection(val event: CollectionProgressEvent) : PostCompletionRewardStep()
    data class LevelUp(val level: Int) : PostCompletionRewardStep()
}

@Serializable
data class CourseProgress(
    val lastLessonIndex: Int = 0,
    val isCompleted: Boolean = false,
    val bestQuizScore: Int = 0,
    val lastQuizDate: String? = null,
)

@Serializable
data class TrainingQuestionState(
    val courseId: String = "",
    val intervalIndex: Int = 0,
    val nextReviewDate: String? = null,
)

@Serializable
data class PendingGlobalRankUp(
    val previousRankRawValue: String = "",
    val newRankRawValue: String = "",
    val newLevel: Int = 1,
)

enum class GlobalRank(val storageKey: String, val lowerLevel: Int, val upperLevel: Int) {
    CURIEUX("curieux", 1, 19),
    ERUDIT("erudit", 20, 39),
    SAVANT("savant", 40, 59),
    MAITRE("maitre", 60, 79),
    LEGENDE("legende", 80, 100);

    companion object {
        fun forLevel(level: Int): GlobalRank = entries.firstOrNull {
            level in it.lowerLevel..it.upperLevel
        } ?: CURIEUX
    }
}

data class GlobalLevelProgress(val level: Int, val rank: GlobalRank, val xpIntoLevel: Int, val xpForLevel: Int)

@Serializable
data class UserProgress(
    val courseProgress: Map<String, CourseProgress> = emptyMap(),
    val streak: Int = 0,
    val lastActiveDate: String? = null,
    val favoriteCourseIds: List<String> = emptyList(),
    val freeCoursesOpened: Int = 0,
    val hasSeenSwipeTutorial: Boolean = false,
    val hasSeenSpecialOffer: Boolean = false,
    val lastCourseCompletedDate: String? = null,
    val dailyFreeCourseId: String? = null,
    val dailyFreeCourseDate: String? = null,
    val lastStreakShownDate: String? = null,
    val subjectXP: Map<String, Int> = emptyMap(),
    val globalXP: Int = 0,
    val globalCourseXPAwardedIds: List<String> = emptyList(),
    val globalQuizXPAwardedIds: List<String> = emptyList(),
    val globalCollectionXPAwardedIds: List<String> = emptyList(),
    val completedQuizCourseIds: List<String> = emptyList(),
    val pendingGlobalRankUp: PendingGlobalRankUp? = null,
    val trainingQuestionStates: Map<String, TrainingQuestionState> = emptyMap(),
    val xpUnlockedCourseIds: List<String> = emptyList(),
    val spentGlobalXP: Int = 0,
    val firstCourseOpenedId: String? = null,
    val hasRequestedAppStoreReview: Boolean = false,
    val hasSeenCourseTermsCoachmark: Boolean = false,
)

/**
 * Freemium rules (parity with iOS):
 * - 1 free course / day: intro page readable; pages 2+ show lock overlay (CTA via lock only).
 * - Quiz / training always premium.
 */
object FreemiumGate {
    fun isLessonContentLocked(
        lessonIndex: Int,
        isPremium: Boolean,
        isDailyFreeCourse: Boolean,
    ): Boolean {
        if (isPremium || isDailyFreeCourse) return false
        return lessonIndex >= 1
    }

    fun canCompleteCourse(isPremium: Boolean, isDailyFreeCourse: Boolean): Boolean =
        isPremium || isDailyFreeCourse
}
