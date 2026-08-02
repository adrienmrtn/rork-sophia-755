package app.rork.sophia.data

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import com.google.android.play.core.review.ReviewManagerFactory

object InAppReviewHelper {
    fun requestIfEligible(
        context: Context,
        progressManager: ProgressManager,
        courseId: String,
        lessonIndex: Int,
    ) {
        if (lessonIndex != 2) return
        if (progressManager.firstCourseOpenedId != courseId) return
        if (progressManager.hasRequestedAppStoreReview) return
        progressManager.markAppStoreReviewRequested()
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
