package app.rork.sophia.audio

import android.content.Context
import app.rork.sophia.AppConfig
import app.rork.sophia.domain.AppLanguage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

/**
 * The two languages courses are narrated in, a subset of the app's 26. Spanish, German and
 * Turkish were dropped: a saved queue item, a download or a manifest key in one of them is
 * ignored or cleaned up, never played.
 */
enum class AudioLanguage(val code: String, val displayName: String, val flag: String) {
    FRENCH("fr", "Français", "🇫🇷"),
    ENGLISH("en", "English", "🇬🇧"),
    ;

    val shortCode: String get() = code.uppercase()

    companion object {
        fun fromCode(code: String?): AudioLanguage? = entries.firstOrNull { it.code == code }
    }
}

/**
 * Which course has a narration in which language, read from `course-audio/manifest.json`
 * (written by `scripts/upload_course_audio_to_supabase.py` from what the bucket really
 * holds), so a new narration reaches the app without a Play release. Objects live at
 * `<language>/<course_id>.mp3`, the same ones iOS plays.
 *
 * The last manifest is kept on disk: downloads stay listed offline and menus do not
 * flash empty at launch.
 */
object CourseAudioCatalog {
    private const val PREFS = "sophia_audio"
    private const val PREFERRED_LANGUAGE_KEY = "preferred_language"
    private val json = Json { ignoreUnknownKeys = true }

    private val _manifest = MutableStateFlow<Map<AudioLanguage, Set<String>>>(emptyMap())
    val manifest: StateFlow<Map<AudioLanguage, Set<String>>> = _manifest.asStateFlow()

    @Volatile private var lastRefreshMs = 0L
    @Volatile private var loadedFromDisk = false

    private fun bucketUrl(): String =
        AppConfig.SUPABASE_URL.trimEnd('/') + "/storage/v1/object/public/course-audio"

    fun remoteUrl(courseId: String, language: AudioLanguage): String =
        "${bucketUrl()}/${language.code}/$courseId.mp3"

    private fun cacheFile(context: Context) = File(context.filesDir, "course_audio_manifest.json")

    fun loadFromDisk(context: Context) {
        if (loadedFromDisk) return
        loadedFromDisk = true
        runCatching { apply(cacheFile(context).readText()) }
    }

    /**
     * Fetches the manifest, at most every ten minutes unless forced. The query changes every
     * five minutes: the bucket's CDN otherwise keeps serving the previous manifest for up to
     * an hour after an upload.
     */
    suspend fun refresh(context: Context, force: Boolean = false) = withContext(Dispatchers.IO) {
        loadFromDisk(context)
        val now = System.currentTimeMillis()
        if (!force && now - lastRefreshMs < 10 * 60_000L) return@withContext
        val slot = now / 300_000L
        runCatching {
            val connection = URL("${bucketUrl()}/manifest.json?v=$slot").openConnection() as HttpURLConnection
            connection.connectTimeout = 15_000
            connection.readTimeout = 15_000
            connection.useCaches = false
            try {
                if (connection.responseCode != 200) return@runCatching
                val text = connection.inputStream.bufferedReader().use { it.readText() }
                if (apply(text)) {
                    lastRefreshMs = now
                    cacheFile(context).writeText(text)
                }
            } finally {
                connection.disconnect()
            }
        }
    }

    /** `{"fr": ["course_1_…", …], …}`; unknown language keys are ignored. */
    private fun apply(text: String): Boolean {
        val raw = runCatching { json.decodeFromString<Map<String, List<String>>>(text) }.getOrNull()
            ?: return false
        _manifest.value = raw.mapNotNull { (code, ids) ->
            AudioLanguage.fromCode(code)?.let { it to ids.toSet() }
        }.toMap()
        return true
    }

    /** Narrated in the manifest, or already on the phone (a download keeps playing offline). */
    fun hasAudio(courseId: String, language: AudioLanguage): Boolean =
        _manifest.value[language]?.contains(courseId) == true ||
            CourseAudioDownloads.isDownloaded(courseId, language)

    fun hasAudio(courseId: String): Boolean = AudioLanguage.entries.any { hasAudio(courseId, it) }

    fun languages(courseId: String): List<AudioLanguage> =
        AudioLanguage.entries.filter { hasAudio(courseId, it) }

    /** Every course with a narration in any language. */
    fun narratedCourseIds(): Set<String> =
        _manifest.value.values.flatten().toSet() + CourseAudioDownloads.downloaded.value.map { it.courseId }

    fun preferredLanguage(context: Context, appLanguage: AppLanguage): AudioLanguage {
        val saved = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(PREFERRED_LANGUAGE_KEY, null)
        return AudioLanguage.fromCode(saved) ?: AudioLanguage.fromCode(appLanguage.code) ?: AudioLanguage.ENGLISH
    }

    fun setPreferredLanguage(context: Context, language: AudioLanguage) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(PREFERRED_LANGUAGE_KEY, language.code)
            .apply()
    }

    /** The preferred language when this course has it, then the app's, then English. */
    fun defaultLanguage(context: Context, courseId: String, appLanguage: AppLanguage): AudioLanguage? {
        val available = languages(courseId)
        if (available.isEmpty()) return null
        val candidates = listOfNotNull(
            preferredLanguage(context, appLanguage),
            AudioLanguage.fromCode(appLanguage.code),
            AudioLanguage.ENGLISH,
        )
        return candidates.firstOrNull { it in available } ?: available.first()
    }
}
