package app.rork.sophia.audio

import android.content.Context
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

/** One narration: a course in one language. Also its path, `fr/course_5_…`. */
data class AudioTrackKey(val courseId: String, val language: AudioLanguage) {
    val path: String get() = "${language.code}/$courseId"
}

/**
 * Offline narrations: `filesDir/course_audio/<lang>/<course_id>.mp3`. Not the cache
 * directory, which the system empties when space runs low: a download the listener asked
 * for must still be there in the plane. What is on disk is the truth.
 */
object CourseAudioDownloads {
    data class Item(val key: AudioTrackKey, val bytes: Long)

    sealed interface State {
        data object None : State
        data class Downloading(val fraction: Float) : State
        data object Downloaded : State
    }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val jobs = mutableMapOf<AudioTrackKey, Job>()
    @Volatile private var root: File? = null

    private val _downloaded = MutableStateFlow<Set<AudioTrackKey>>(emptySet())
    val downloaded: StateFlow<Set<AudioTrackKey>> = _downloaded.asStateFlow()

    private val _inFlight = MutableStateFlow<Map<AudioTrackKey, Float>>(emptyMap())
    val inFlight: StateFlow<Map<AudioTrackKey, Float>> = _inFlight.asStateFlow()

    fun init(context: Context) {
        if (root != null) return
        val dir = File(context.filesDir, "course_audio")
        root = dir
        // Folders of a language no longer narrated (es, de, tr): unreachable from the app,
        // so the settings screen could never free that space.
        val kept = AudioLanguage.entries.map { it.code }.toSet()
        dir.listFiles()?.filter { it.name !in kept }?.forEach { it.deleteRecursively() }
        _downloaded.value = AudioLanguage.entries.flatMap { language ->
            File(dir, language.code).listFiles { f -> f.name.endsWith(".mp3") }
                ?.map { AudioTrackKey(it.name.removeSuffix(".mp3"), language) }
                .orEmpty()
        }.toSet()
    }

    private fun file(key: AudioTrackKey): File? =
        root?.let { File(File(it, key.language.code), "${key.courseId}.mp3") }

    fun isDownloaded(courseId: String, language: AudioLanguage): Boolean =
        AudioTrackKey(courseId, language) in _downloaded.value

    fun state(courseId: String, language: AudioLanguage): State {
        val key = AudioTrackKey(courseId, language)
        if (key in _downloaded.value) return State.Downloaded
        _inFlight.value[key]?.let { return State.Downloading(it) }
        return State.None
    }

    /** The file to play from, when the narration is on the phone. */
    fun localFile(courseId: String, language: AudioLanguage): File? {
        val key = AudioTrackKey(courseId, language)
        if (key !in _downloaded.value) return null
        return file(key)?.takeIf { it.exists() }
    }

    fun items(): List<Item> = _downloaded.value
        .map { Item(it, file(it)?.length() ?: 0L) }
        .sortedByDescending { it.bytes }

    fun totalBytes(): Long = items().sumOf { it.bytes }

    fun download(courseId: String, language: AudioLanguage) {
        val key = AudioTrackKey(courseId, language)
        val target = file(key) ?: return
        synchronized(jobs) {
            if (key in _downloaded.value || jobs[key] != null) return
            _inFlight.update { it + (key to 0f) }
            val job = scope.launch(start = CoroutineStart.LAZY) {
                val saved = runCatching { fetch(CourseAudioCatalog.remoteUrl(courseId, language), target, key) }
                    .getOrDefault(false)
                val self = coroutineContext[Job]
                // Cancelled and restarted meanwhile: the new download owns the key now.
                val owner = synchronized(jobs) {
                    (jobs[key] === self).also { if (it) jobs.remove(key) }
                }
                if (!owner) return@launch
                _inFlight.update { it - key }
                if (saved) _downloaded.update { it + key }
            }
            jobs[key] = job
            job.start()
        }
    }

    private suspend fun fetch(url: String, target: File, key: AudioTrackKey): Boolean {
        val partial = File(target.parentFile, target.name + ".part")
        target.parentFile?.mkdirs()
        val connection = URL(url).openConnection() as HttpURLConnection
        connection.connectTimeout = 20_000
        connection.readTimeout = 30_000
        try {
            // A 404 would otherwise "download" its error page.
            if (connection.responseCode != 200) return false
            val total = connection.contentLengthLong
            var received = 0L
            var lastReport = 0L
            connection.inputStream.use { input ->
                partial.outputStream().use { output ->
                    val buffer = ByteArray(64 * 1024)
                    while (true) {
                        kotlin.coroutines.coroutineContext.ensureActive()
                        val read = input.read(buffer)
                        if (read < 0) break
                        output.write(buffer, 0, read)
                        received += read
                        if (total > 0 && received - lastReport > 128 * 1024) {
                            lastReport = received
                            val fraction = (received.toFloat() / total).coerceIn(0f, 1f)
                            _inFlight.update { if (key in it) it + (key to fraction) else it }
                        }
                    }
                }
            }
            if (target.exists()) target.delete()
            return partial.renameTo(target)
        } catch (e: Exception) {
            partial.delete()
            throw e
        } finally {
            connection.disconnect()
        }
    }

    fun cancel(courseId: String, language: AudioLanguage) {
        val key = AudioTrackKey(courseId, language)
        synchronized(jobs) { jobs.remove(key)?.cancel() }
        _inFlight.update { it - key }
    }

    fun delete(courseId: String, language: AudioLanguage) {
        cancel(courseId, language)
        val key = AudioTrackKey(courseId, language)
        file(key)?.delete()
        _downloaded.update { it - key }
    }

    fun deleteAll() {
        synchronized(jobs) {
            jobs.values.forEach { it.cancel() }
            jobs.clear()
        }
        _inFlight.value = emptyMap()
        root?.deleteRecursively()
        _downloaded.value = emptySet()
    }
}
