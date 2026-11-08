package app.rork.sophia.data

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.platform.LocalContext
import app.rork.sophia.data.catalog.CatalogStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Course
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.LearningCollection

// Les listes du catalogue pour la composition : la valeur en mémoire tout de suite, la lecture
// hors du fil principal ensuite, et une relecture à chaque changement du catalogue en ligne
// (`CatalogStore.version` : fichiers mis à jour, changement de langue).

@Composable
fun rememberCourseSummaries(language: AppLanguage): List<CourseSummary> {
    val context = LocalContext.current
    val version by CatalogStore.version.collectAsState()
    val initial = ContentCatalog.cachedSummaries(language).orEmpty()
    return produceState(initialValue = initial, language, version) {
        value = ContentCatalog.summariesAsync(context.applicationContext, language)
    }.value
}

@Composable
fun rememberCourses(language: AppLanguage): List<Course> {
    val context = LocalContext.current
    val version by CatalogStore.version.collectAsState()
    val initial = ContentCatalog.cachedCourses(language).orEmpty()
    return produceState(initialValue = initial, language, version) {
        value = ContentCatalog.coursesAsync(context.applicationContext, language)
    }.value
}

@Composable
fun rememberCollections(language: AppLanguage): List<LearningCollection> {
    val context = LocalContext.current
    val version by CatalogStore.version.collectAsState()
    val initial = ContentCatalog.cachedCollections(language).orEmpty()
    return produceState(initialValue = initial, language, version) {
        value = ContentCatalog.collectionsAsync(context.applicationContext, language)
    }.value
}
