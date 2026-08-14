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

    private val summaryCache = ConcurrentHashMap<String, List<CourseSummary>>()
    private val collectionCache = ConcurrentHashMap<String, List<LearningCollection>>()
    private val singleCourseCache = ConcurrentHashMap<String, Course>()

    fun cachedCourses(language: AppLanguage): List<Course>? = null

    fun cachedCollections(language: AppLanguage): List<LearningCollection>? =
        collectionCache[language.code]

    fun cachedSummaries(language: AppLanguage): List<CourseSummary>? =
        summaryCache[language.code]

    fun cachedCourse(language: AppLanguage, id: String): Course? =
        singleCourseCache["${language.code}:$id"]

    fun summaries(context: Context, language: AppLanguage): List<CourseSummary> {
        summaryCache[language.code]?.let { return it }
        val loaded = readSummaries(context, language)
        summaryCache[language.code] = loaded
        return loaded
    }

    private fun readSummaries(context: Context, language: AppLanguage): List<CourseSummary> {
        val indexPath = "locales/course_index.${language.code}.json"
        val catalogPath = "locales/courses.${language.code}.json"
        return try {
            context.assets.open(indexPath).use { CatalogStream.readSummaries(it) }
        } catch (_: Exception) {
            try {
                context.assets.open(catalogPath).use { CatalogStream.readSummaries(it) }
            } catch (_: Exception) {
                emptyList()
            }
        }
    }

    suspend fun summariesAsync(context: Context, language: AppLanguage): List<CourseSummary> =
        withContext(Dispatchers.IO) { summaries(context, language) }

    /**
     * Lightweight stubs only (no lessons/quiz). Feed/library never touch quiz JSON.
     */
    fun courses(context: Context, language: AppLanguage): List<Course> {
        return summaries(context, language).map {
            Course(it.id, it.title, it.description, it.subject, it.subcategory)
        }
    }

    suspend fun coursesAsync(context: Context, language: AppLanguage): List<Course> =
        withContext(Dispatchers.IO) { courses(context, language) }

    suspend fun courseAsync(context: Context, language: AppLanguage, id: String): Course? =
        withContext(Dispatchers.IO) { course(context, language, id) }

    fun collections(context: Context, language: AppLanguage): List<LearningCollection> {
        return collectionCache.getOrPut(language.code) {
            loadList(context, "locales/collections.${language.code}.json")
        }
    }

    suspend fun collectionsAsync(context: Context, language: AppLanguage): List<LearningCollection> =
        withContext(Dispatchers.IO) { collections(context, language) }

    fun course(context: Context, language: AppLanguage, id: String): Course? {
        val key = "${language.code}:$id"
        singleCourseCache[key]?.let { return it }
        val loaded = try {
            context.assets.open("locales/courses.${language.code}.json").use { stream ->
                CatalogStream.readOneCourse(stream, id)
            }
        } catch (_: Exception) {
            summaries(context, language).firstOrNull { it.id == id }?.let {
                Course(it.id, it.title, it.description, it.subject, it.subcategory)
            }
        }
        if (loaded != null) singleCourseCache[key] = loaded
        return loaded
    }

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
        summaryCache.clear()
        collectionCache.clear()
        singleCourseCache.clear()
    }
}
