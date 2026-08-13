package app.rork.sophia.data

import android.content.Context
import android.content.Intent
import app.rork.sophia.domain.Course

object ShareHelper {
    fun courseDeepLink(courseId: String): String = "sophia://course/$courseId"

    fun shareCourse(context: Context, course: Course) {
        shareCourse(context, course.id, course.title)
    }

    fun shareCourse(context: Context, courseId: String, title: String) {
        val link = courseDeepLink(courseId)
        val text = "$title\n$link"
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_SUBJECT, title)
            putExtra(Intent.EXTRA_TEXT, text)
        }
        context.startActivity(Intent.createChooser(intent, title))
        MetaAdsService.logShare(context, courseId)
    }
}
