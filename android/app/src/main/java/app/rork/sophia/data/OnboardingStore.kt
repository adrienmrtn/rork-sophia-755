package app.rork.sophia.data

import android.content.Context

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

    companion object {
        private const val KEY = "sophia_onboarding_completed"
        private const val KEY_STEP = "sophia_onboarding_step"
        private const val KEY_SKIPPED_ACCOUNT = "sophia_onboarding_skipped_account"
        private const val KEY_ACCOUNT_PROMPTED = "sophia_account_prompted"
    }
}
