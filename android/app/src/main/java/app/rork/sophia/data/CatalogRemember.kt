package app.rork.sophia.data

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.produceState
import androidx.compose.ui.platform.LocalContext
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Course
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.LearningCollection

@Composable
fun rememberCourseSummaries(language: AppLanguage): List<CourseSummary> {
    val context = LocalContext.current
    val initial = ContentCatalog.cachedSummaries(language).orEmpty()
    return produceState(initialValue = initial, language) {
        value = ContentCatalog.summariesAsync(context.applicationContext, language)
    }.value
}

@Composable
fun rememberCourses(language: AppLanguage): List<Course> {
    val context = LocalContext.current
    val initial = ContentCatalog.cachedCourses(language).orEmpty()
    return produceState(initialValue = initial, language) {
        value = ContentCatalog.coursesAsync(context.applicationContext, language)
    }.value
}

@Composable
fun rememberCollections(language: AppLanguage): List<LearningCollection> {
    val context = LocalContext.current
    val initial = ContentCatalog.cachedCollections(language).orEmpty()
    return produceState(initialValue = initial, language) {
        value = ContentCatalog.collectionsAsync(context.applicationContext, language)
    }.value
}
