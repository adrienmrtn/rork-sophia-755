package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Course
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.LearningCollection
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import java.util.concurrent.ConcurrentHashMap

object ContentCatalog {
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    private val courseCache = ConcurrentHashMap<String, List<Course>>()
    private val summaryCache = ConcurrentHashMap<String, List<CourseSummary>>()
    private val collectionCache = ConcurrentHashMap<String, List<LearningCollection>>()

    fun cachedSummaries(language: AppLanguage): List<CourseSummary>? =
        summaryCache[language.code]

    fun cachedCourse(language: AppLanguage, id: String): Course? =
        courseCache[language.code]?.firstOrNull { it.id == id }

    fun summaries(context: Context, language: AppLanguage): List<CourseSummary> {
        summaryCache[language.code]?.let { return it }
        val fromFull = courseCache[language.code]
        if (fromFull != null) {
            val mapped = fromFull.map {
                CourseSummary(it.id, it.title, it.description, it.subject, it.subcategory)
            }
            summaryCache[language.code] = mapped
            return mapped
        }
        return summaryCache.getOrPut(language.code) {
            loadList(context, "locales/courses.${language.code}.json")
        }
    }

    suspend fun summariesAsync(context: Context, language: AppLanguage): List<CourseSummary> =
        withContext(Dispatchers.IO) { summaries(context, language) }

    fun courses(context: Context, language: AppLanguage): List<Course> {
        return courseCache.getOrPut(language.code) {
            loadList(context, "locales/courses.${language.code}.json")
        }
    }

    /** Prefer this from UI — avoids ANR while parsing ~3MB locale catalogs. */
    suspend fun coursesAsync(context: Context, language: AppLanguage): List<Course> =
        withContext(Dispatchers.IO) { courses(context, language) }

    suspend fun courseAsync(context: Context, language: AppLanguage, id: String): Course? =
        withContext(Dispatchers.IO) { course(context, language, id) }

    fun collections(context: Context, language: AppLanguage): List<LearningCollection> {
        return collectionCache.getOrPut(language.code) {
            loadList(context, "locales/collections.${language.code}.json")
        }
    }

    fun course(context: Context, language: AppLanguage, id: String): Course? =
        courses(context, language).firstOrNull { it.id == id }

    fun hasStructuredContent(context: Context, language: AppLanguage, courseId: String): Boolean {
        return try {
            context.assets.open("courses_v2/${language.code}/$courseId.json").close()
            true
        } catch (_: Exception) {
            false
        }
    }

    fun structuredContentJson(context: Context, language: AppLanguage, courseId: String): String? {
        return try {
            context.assets.open("courses_v2/${language.code}/$courseId.json")
                .bufferedReader()
                .use { it.readText() }
        } catch (_: Exception) {
            null
        }
    }

    private inline fun <reified T> loadList(context: Context, path: String): List<T> {
        return try {
            val text = context.assets.open(path).bufferedReader().use { it.readText() }
            json.decodeFromString<List<T>>(text)
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun clearCache() {
        courseCache.clear()
        summaryCache.clear()
        collectionCache.clear()
    }
}
