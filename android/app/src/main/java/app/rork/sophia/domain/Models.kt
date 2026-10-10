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

    fun toStub(quizAvailable: Boolean = true) = Course(
        id = id,
        title = title,
        description = description,
        subject = subject,
        subcategory = subcategory,
        quizAvailable = quizAvailable,
    )
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
    val quizAvailable: Boolean = false,
) {
    val subjectEnum: Subject
        get() = Subject.fromStorageKey(subject) ?: Subject.HISTOIRE

    val hasQuiz: Boolean get() = quizAvailable || quiz.isNotEmpty()

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
    /** Points the quiz was out of, so a stored score can be shown as a ratio. */
    val quizMaxPoints: Int = 0,
    val lastQuizDate: String? = null,
    /**
     * When the course was first opened and when it was finished, ISO-8601. Both default to
     * null so progress saved by an older build still decodes: those courses simply sort
     * last, which is the honest answer for a date nobody recorded.
     */
    val startedAt: String? = null,
    val completedAt: String? = null,
    /**
     * Pages this course had when it was last read. Recorded by the reader because the slim
     * home catalogue carries no lesson count, and loading every course's body just to show
     * "3 of 5" would cost more than the line is worth. 0 means "not known yet" — progress
     * saved by an older build — and the ratio is simply not shown.
     */
    val lessonCount: Int = 0,
)

@Serializable
data class TrainingQuestionState(
    val courseId: String = "",
    val intervalIndex: Int = 0,
    val nextReviewDate: String? = null,
)

/**
 * Outcome of the end-of-level quiz of one Parcours level, keyed by collection id in
 * [UserProgress.pathLevelResults]. Same fields and JSON names as iOS, so a level passed on
 * one platform is passed on the other.
 */
@Serializable
data class PathLevelResult(
    /** Most fully-correct answers reached in a single attempt. */
    val bestCorrect: Int = 0,
    /** Question count of the attempt that set [bestCorrect]. */
    val bestTotal: Int = 0,
    val attempts: Int = 0,
    /** ISO-8601 date of the first passing attempt; null while the level is not passed. */
    val passedAt: String? = null,
    /** Whether the one-time global XP reward for passing was already granted. */
    val xpAwarded: Boolean = false,
) {
    val isPassed: Boolean get() = passedAt != null
}

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
    /**
     * Highest "n of m" already celebrated per collection. Finishing or skipping the quiz of
     * a course that was already complete used to replay the collection celebration, because
     * the previous count was assumed to be "one less" rather than looked up.
     */
    val celebratedCollectionCounts: Map<String, Int> = emptyMap(),
    /**
     * Parcours levels, by collection id. Written by iOS too: before Android knew the field,
     * `ignoreUnknownKeys` dropped it on read and the next push erased the levels passed on
     * the iPhone.
     */
    val pathLevelResults: Map<String, PathLevelResult> = emptyMap(),
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
