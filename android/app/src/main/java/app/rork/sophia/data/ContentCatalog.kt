package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Course
import app.rork.sophia.domain.LearningCollection
import kotlinx.serialization.json.Json
import java.util.concurrent.ConcurrentHashMap

object ContentCatalog {
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    private val courseCache = ConcurrentHashMap<String, List<Course>>()
    private val collectionCache = ConcurrentHashMap<String, List<LearningCollection>>()

    fun courses(context: Context, language: AppLanguage): List<Course> {
        return courseCache.getOrPut(language.code) {
            loadList(context, "locales/courses.${language.code}.json")
        }
    }

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
        collectionCache.clear()
    }
}
