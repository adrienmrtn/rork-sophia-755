package app.rork.sophia.data

import android.content.Context

/**
 * Answers of the « about you » pages. Kept as they are given, like iOS's resume store, so
 * an app killed halfway through the flow resumes with them, and kept afterwards for the
 * app (first name, age range, self-rated knowledge, motivation, favourite subjects).
 */
data class OnboardingAnswers(
    val firstName: String = "",
    val ageRange: String? = null,
    val knowledgeLevel: Int = 1,
    val motivation: String? = null,
    val topics: List<String> = emptyList(),
)

class OnboardingStore(context: Context) {
    private val prefs = context.getSharedPreferences("sophia_prefs", Context.MODE_PRIVATE)

    val isCompleted: Boolean
        get() = prefs.getBoolean(KEY, false)

    fun markCompleted() {
        prefs.edit().putBoolean(KEY, true).remove(KEY_STEP).apply()
    }

    /**
     * The onboarding page the user last reached, by enum name, or null on a first run.
     *
     * Closing the app halfway through used to drop every answer and start again at the
     * welcome page — a flow with eighteen pages that has to be redone from scratch is a flow
     * people abandon. Stored by name rather than index so reordering the pages later cannot
     * resume someone onto a different one.
     */
    fun lastStep(): String? = prefs.getString(KEY_STEP, null)

    fun rememberStep(name: String) {
        prefs.edit().putString(KEY_STEP, name).apply()
    }

    /**
     * Whether the user chose to go on without an account. Signing in is optional, so this is
     * the signal that the app still owes them the offer — in the profile tab, and once after
     * their third course.
     */
    val skippedAccount: Boolean
        get() = prefs.getBoolean(KEY_SKIPPED_ACCOUNT, false)

    fun markSkippedAccount() {
        prefs.edit().putBoolean(KEY_SKIPPED_ACCOUNT, true).apply()
    }

    /** Cleared once an account exists, so the reminder stops for good. */
    fun markAccountOffered() {
        prefs.edit()
            .putBoolean(KEY_SKIPPED_ACCOUNT, false)
            .putBoolean(KEY_ACCOUNT_PROMPTED, true)
            .apply()
    }

    /** True once the after-third-course prompt has been shown, so it never nags twice. */
    val accountPrompted: Boolean
        get() = prefs.getBoolean(KEY_ACCOUNT_PROMPTED, false)

    fun markAccountPrompted() {
        prefs.edit().putBoolean(KEY_ACCOUNT_PROMPTED, true).apply()
    }

    fun answers(): OnboardingAnswers = OnboardingAnswers(
        firstName = prefs.getString(KEY_FIRST_NAME, null).orEmpty(),
        ageRange = prefs.getString(KEY_AGE_RANGE, null),
        knowledgeLevel = prefs.getInt(KEY_KNOWLEDGE, 1),
        motivation = prefs.getString(KEY_MOTIVATION, null),
        topics = prefs.getString(KEY_TOPICS, null)
            ?.split(',')
            ?.filter { it.isNotBlank() }
            .orEmpty(),
    )

    fun saveAnswers(answers: OnboardingAnswers) {
        prefs.edit()
            .putString(KEY_FIRST_NAME, answers.firstName.ifBlank { null })
            .putString(KEY_AGE_RANGE, answers.ageRange)
            .putInt(KEY_KNOWLEDGE, answers.knowledgeLevel)
            .putString(KEY_MOTIVATION, answers.motivation)
            .putString(KEY_TOPICS, answers.topics.joinToString(","))
            .apply()
    }

    companion object {
        private const val KEY = "sophia_onboarding_completed"
        private const val KEY_STEP = "sophia_onboarding_step"
        private const val KEY_SKIPPED_ACCOUNT = "sophia_onboarding_skipped_account"
        private const val KEY_ACCOUNT_PROMPTED = "sophia_account_prompted"

        // Same names as the iOS UserDefaults keys.
        private const val KEY_FIRST_NAME = "sophia_user_first_name"
        private const val KEY_AGE_RANGE = "sophia_user_age_range"
        private const val KEY_KNOWLEDGE = "sophia_user_knowledge_level"
        private const val KEY_MOTIVATION = "sophia_user_motivation"
        private const val KEY_TOPICS = "sophia_user_interests"
    }
}
