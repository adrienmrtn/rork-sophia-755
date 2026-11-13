package app.rork.sophia.data

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import com.google.android.play.core.review.ReviewManagerFactory

/**
 * La demande de note Google Play. Deux occasions, chacune une seule fois dans la vie de
 * l'installation : la page Mission de l'onboarding (« L'équipe Sophia »), et le cinquième
 * « Continuer » dans le premier cours que l'utilisateur ouvre. Play plafonne de son côté la
 * fréquence à laquelle la fenêtre apparaît vraiment.
 */
object InAppReviewHelper {
    private const val PREFS = "sophia_prefs"
    private const val ONBOARDING_ASKED_KEY = "sophia_review_onboarding_asked"
    private const val FIRST_COURSE_TAPS_KEY = "sophia_review_first_course_continue_taps"

    /** Le « Continuer » du premier cours qui déclenche la demande. */
    const val FIRST_COURSE_CONTINUE_TAP = 5

    /** La demande de l'onboarding, sur la page Mission : une fois par installation. */
    fun requestInOnboarding(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (prefs.getBoolean(ONBOARDING_ASKED_KEY, false)) return
        prefs.edit().putBoolean(ONBOARDING_ASKED_KEY, true).apply()
        launch(context)
    }

    /**
     * Un clic sur « Continuer » dans le lecteur. Seul le premier cours ouvert compte ; au
     * cinquième clic, la demande part, une seule fois (`hasRequestedAppStoreReview`, qui
     * couvre aussi les installations déjà sollicitées par l'ancienne règle).
     */
    fun onReaderContinue(context: Context, progressManager: ProgressManager, courseId: String) {
        if (progressManager.hasRequestedAppStoreReview) return
        if (progressManager.firstCourseOpenedId != courseId) return
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val taps = prefs.getInt(FIRST_COURSE_TAPS_KEY, 0) + 1
        prefs.edit().putInt(FIRST_COURSE_TAPS_KEY, taps).apply()
        if (taps < FIRST_COURSE_CONTINUE_TAP) return
        progressManager.markAppStoreReviewRequested()
        launch(context)
    }

    private fun launch(context: Context) {
        val activity = context.findActivity() ?: return
        val manager = ReviewManagerFactory.create(context)
        manager.requestReviewFlow().addOnCompleteListener { task ->
            if (!task.isSuccessful) return@addOnCompleteListener
            manager.launchReviewFlow(activity, task.result)
        }
    }

    private fun Context.findActivity(): Activity? {
        var ctx: Context? = this
        while (ctx is ContextWrapper) {
            if (ctx is Activity) return ctx
            ctx = ctx.baseContext
        }
        return null
    }
}
