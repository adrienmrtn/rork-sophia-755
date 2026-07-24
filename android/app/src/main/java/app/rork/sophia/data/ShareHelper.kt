package app.rork.sophia.data

import android.content.Context
import android.content.Intent
import app.rork.sophia.domain.Course

object ShareHelper {
    fun courseDeepLink(courseId: String): String = "sophia://course/$courseId"

    fun shareCourse(context: Context, course: Course) {
        val link = courseDeepLink(course.id)
        val text = "${course.title}\n$link"
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_SUBJECT, course.title)
            putExtra(Intent.EXTRA_TEXT, text)
        }
        context.startActivity(Intent.createChooser(intent, course.title))
        MetaAdsService.logShare(context, course.id)
    }
}
