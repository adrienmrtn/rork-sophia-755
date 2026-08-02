package app.rork.sophia.data

import android.content.Context

/** Local one-shot tutorial flags (not synced with cloud progress). */
class TutorialFlags(context: Context) {
    private val prefs = context.getSharedPreferences("sophia_tutorial_flags", Context.MODE_PRIVATE)

    enum class Id(val key: String) {
        HOME_SWIPE("sophia_tut_home_swipe"),
        COURSE_TERMS("sophia_tut_course_terms"),
        COLLECTIONS("sophia_tut_collections"),
        TRAINING("sophia_tut_training"),
        TRAINING_ONBOARDING("sophia_tut_training_onboarding"),
    }

    fun seen(id: Id): Boolean = prefs.getBoolean(id.key, false)

    fun markSeen(id: Id) {
        prefs.edit().putBoolean(id.key, true).apply()
    }
}
