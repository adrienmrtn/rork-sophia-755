package app.rork.sophia.data

import android.content.Context

class OnboardingStore(context: Context) {
    private val prefs = context.getSharedPreferences("sophia_prefs", Context.MODE_PRIVATE)

    val isCompleted: Boolean
        get() = prefs.getBoolean(KEY, false)

    fun markCompleted() {
        prefs.edit().putBoolean(KEY, true).apply()
    }

    companion object {
        private const val KEY = "sophia_onboarding_completed"
    }
}
