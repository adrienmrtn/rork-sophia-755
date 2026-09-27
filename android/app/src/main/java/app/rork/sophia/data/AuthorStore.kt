package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.domain.AppLanguage
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/**
 * A professor who wrote one or more courses, from `assets/authors.json`.
 *
 * The file is written by `scripts/build_courses.py` from `content/authors.json` and copied
 * by `scripts/export_ios_content_for_android.py`. Each author carries the ids of the
 * courses that name it, so "other courses by this professor" costs no course decode.
 */
@Serializable
data class CourseAuthor(
    val slug: String,
    val name: String,
    /** File name (no extension) under `assets/author_photos`; null shows the initials. */
    val photo: String? = null,
    val institution: String? = null,
    val country: String? = null,
    val links: Map<String, String> = emptyMap(),
    val title: Map<String, String> = emptyMap(),
    val bio: Map<String, String> = emptyMap(),
    val courseIds: List<String> = emptyList(),
) {
    fun title(language: AppLanguage): String? = localized(title, language)

    fun bio(language: AppLanguage): String? = localized(bio, language)

    /** Coil model for the portrait, or null when the author has none. */
    val photoModel: String?
        get() = photo?.takeIf { it.isNotBlank() }?.let { "file:///android_asset/author_photos/$it.jpg" }

    /** Up to two initials for the avatar fallback: "Dusan Nikolic" → "DN". */
    val initials: String
        get() {
            val parts = name.split(' ', '-').filter { it.isNotBlank() }
            val picked = if (parts.size >= 2) listOf(parts.first(), parts.last()) else parts.take(1)
            return picked.mapNotNull { it.firstOrNull()?.uppercaseChar() }.joinToString("")
        }

    private fun localized(table: Map<String, String>, language: AppLanguage): String? {
        for (code in listOf(language.code, "en", "fr")) {
            table[code]?.trim()?.takeIf { it.isNotEmpty() }?.let { return it }
        }
        return table.values.firstOrNull { it.isNotBlank() }
    }
}

@Serializable
private data class AuthorsPayload(val authors: List<CourseAuthor> = emptyList())

object AuthorStore {
    private val json = Json { ignoreUnknownKeys = true; isLenient = true }

    @Volatile
    private var loaded: List<CourseAuthor>? = null

    /** Reads the file once, off the main thread when called from the reader's loader. */
    fun preload(context: Context) {
        all(context)
    }

    fun all(context: Context): List<CourseAuthor> {
        loaded?.let { return it }
        synchronized(this) {
            loaded?.let { return it }
            val authors = try {
                val text = context.assets.open("authors.json").bufferedReader().use { it.readText() }
                json.decodeFromString<AuthorsPayload>(text).authors
            } catch (_: Exception) {
                emptyList()
            }
            loaded = authors
            return authors
        }
    }

    /** Only answers from what [preload] already read; null before that or for an unknown slug. */
    fun author(slug: String): CourseAuthor? = loaded?.firstOrNull { it.slug == slug }

    fun author(context: Context, slug: String): CourseAuthor? = all(context).firstOrNull { it.slug == slug }

    fun authorForCourse(context: Context, courseId: String): CourseAuthor? =
        all(context).firstOrNull { courseId in it.courseIds }

    fun clearCache() {
        loaded = null
    }
}
