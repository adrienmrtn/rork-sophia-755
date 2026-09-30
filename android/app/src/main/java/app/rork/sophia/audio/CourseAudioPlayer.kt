package app.rork.sophia.audio

import android.content.ComponentName
import android.content.Context
import android.net.Uri
import androidx.annotation.OptIn
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.AuthorStore
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.CourseCoverUrls
import app.rork.sophia.data.StringStore
import com.google.common.util.concurrent.ListenableFuture
import kotlinx.coroutines.Job
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.util.UUID
import kotlin.math.roundToInt

/** A narration in the queue, or the one playing. */
@Serializable
data class AudioQueueItem(
    val id: String = UUID.randomUUID().toString(),
    val courseId: String,
    val languageCode: String,
) {
    val language: AudioLanguage get() = AudioLanguage.fromCode(languageCode) ?: AudioLanguage.FRENCH
    val key: AudioTrackKey get() = AudioTrackKey(courseId, language)
}

@Serializable
private data class SavedAudioSession(val items: List<AudioQueueItem> = emptyList())

/**
 * The app's one audio player: course narrations, played like a podcast.
 *
 * Native on purpose: an ExoPlayer wrapped in a `MediaSession` by [CourseAudioService], so
 * the narration keeps playing with the screen off or in another app, with the media
 * notification, the lock-screen controls, Bluetooth headsets, Android Auto and Wear all
 * showing the course cover and driving playback. Audio focus pauses for a call and resumes
 * after; unplugging headphones pauses.
 *
 * The queue *is* ExoPlayer's playlist (the item playing first, then what comes next), so
 * "next" works everywhere the system shows it. Premium only: the gate lives in the
 * `request…` entry points the UI calls. Listening past [COMPLETION_THRESHOLD] completes the
 * course; every narration resumes where it was left, per course and per language.
 *
 * Main thread only.
 */
@OptIn(UnstableApi::class)
object CourseAudioPlayer {
    const val SKIP_MS = 15_000L
    const val COMPLETION_THRESHOLD = 0.9
    const val SPEED_MIN = 0.5f
    const val SPEED_MAX = 2.0f
    const val SPEED_STEP = 0.05f

    data class UiState(
        val current: AudioQueueItem? = null,
        val queue: List<AudioQueueItem> = emptyList(),
        /** What the listener asked for: true from the tap on play, loading included. */
        val isPlaying: Boolean = false,
        val isBuffering: Boolean = false,
        val positionMs: Long = 0,
        val durationMs: Long = 0,
        val rate: Float = 1f,
        val failed: Boolean = false,
    ) {
        val progress: Float
            get() = if (durationMs > 0) (positionMs.toFloat() / durationMs).coerceIn(0f, 1f) else 0f
    }

    private const val PREFS = "sophia_audio"
    private const val SESSION_KEY = "session"
    private const val POSITIONS_KEY = "positions"
    private const val RATE_KEY = "rate"
    private val json = Json { ignoreUnknownKeys = true }

    private val _state = MutableStateFlow(UiState())
    val state: StateFlow<UiState> = _state.asStateFlow()

    /** Mirrored from `StoreViewModel` by `MainTabs`. */
    @Volatile var isPremium: Boolean = false
    /** Opens the audio paywall for a course; set by `MainTabs`. */
    var onPaywallNeeded: ((courseId: String?) -> Unit)? = null
    /** A course was listened to the end; set by `SophiaApplication`, which owns the progress. */
    var onListenedToEnd: ((String) -> Unit)? = null
    /** Whether a course is done, so suggestions put unread ones first. */
    var isCourseCompleted: ((String) -> Boolean)? = null

    private lateinit var appContext: Context
    private var exo: ExoPlayer? = null
    /** The items ExoPlayer holds, in order; index 0 is the one playing. Empty until loaded. */
    private var items: MutableList<AudioQueueItem> = mutableListOf()
    private var loaded = false
    private var positions: MutableMap<String, Long> = mutableMapOf()
    private var reportedCompletionFor: String? = null
    /** Where the item playing started; checked once its duration is known. */
    private var startPositionToCheck: Long? = null
    private var controllerFuture: ListenableFuture<MediaController>? = null
    private val scope = MainScope()
    private var ticker: Job? = null
    private var lastPositionSave = 0L
    private var lastKnownPositionMs = 0L

    // MARK: - Setup

    fun init(context: Context) {
        if (::appContext.isInitialized) return
        appContext = context.applicationContext
        val prefs = appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val rate = prefs.getFloat(RATE_KEY, 1f).let(::snap)
        positions = runCatching {
            json.decodeFromString<Map<String, Long>>(prefs.getString(POSITIONS_KEY, null) ?: "{}")
        }.getOrDefault(emptyMap()).toMutableMap()
        val saved = runCatching {
            json.decodeFromString<SavedAudioSession>(prefs.getString(SESSION_KEY, null) ?: "{}")
        }.getOrNull()
        // An item saved in a language no longer narrated (es, de, tr) is dropped, not
        // replayed in French: that course may have no French narration.
        items = saved?.items.orEmpty().filter { AudioLanguage.fromCode(it.languageCode) != null }.toMutableList()
        val first = items.firstOrNull()
        _state.value = UiState(
            current = first,
            queue = items.drop(1),
            positionMs = first?.let { positions[it.key.path] } ?: 0,
            rate = rate,
        )
    }

    /** The player the media session wraps; created on first use. */
    fun player(context: Context): Player {
        init(context)
        return exo ?: ExoPlayer.Builder(appContext)
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(C.USAGE_MEDIA)
                    .setContentType(C.AUDIO_CONTENT_TYPE_SPEECH)
                    .build(),
                /* handleAudioFocus = */ true,
            )
            .setHandleAudioBecomingNoisy(true)
            .setWakeMode(C.WAKE_MODE_NETWORK)
            .setSeekBackIncrementMs(SKIP_MS)
            .setSeekForwardIncrementMs(SKIP_MS)
            .build()
            .also { player ->
                player.setPlaybackSpeed(_state.value.rate)
                player.addListener(listener)
                exo = player
            }
    }

    /** Binding a controller is what starts [CourseAudioService] and its notification. */
    private fun ensureService() {
        if (controllerFuture != null) return
        val token = SessionToken(appContext, ComponentName(appContext, CourseAudioService::class.java))
        controllerFuture = MediaController.Builder(appContext, token).buildAsync()
    }

    // MARK: - Queries

    fun isCurrent(courseId: String) = _state.value.current?.courseId == courseId
    fun isPlayingCourse(courseId: String) = isCurrent(courseId) && _state.value.isPlaying
    fun isQueued(courseId: String) = _state.value.queue.any { it.courseId == courseId }
    val hasItem: Boolean get() = _state.value.current != null

    private fun appLanguage() = SophiaApplication.instance.languageManager.current.value

    // MARK: - Entry points (gated)

    private fun gate(courseId: String?): Boolean {
        if (isPremium) return true
        onPaywallNeeded?.invoke(courseId)
        return false
    }

    fun requestPlay(courseId: String, language: AudioLanguage? = null): Boolean {
        if (!gate(courseId)) return false
        play(courseId, language)
        return true
    }

    fun requestEnqueue(courseId: String, next: Boolean): Boolean {
        if (!gate(courseId)) return false
        enqueue(courseId, next)
        return true
    }

    fun requestDownload(courseId: String, language: AudioLanguage? = null): Boolean {
        if (!gate(courseId)) return false
        val lang = language ?: CourseAudioCatalog.defaultLanguage(appContext, courseId, appLanguage()) ?: return false
        CourseAudioDownloads.download(courseId, lang)
        return true
    }

    /** Play/pause from the app's own buttons; resuming goes through the gate. */
    fun togglePlayPause() {
        when {
            _state.value.isPlaying -> pause()
            isPremium -> resume()
            else -> onPaywallNeeded?.invoke(_state.value.current?.courseId)
        }
    }

    // MARK: - Playback

    fun play(courseId: String, language: AudioLanguage? = null) {
        val lang = language ?: CourseAudioCatalog.defaultLanguage(appContext, courseId, appLanguage()) ?: return
        val current = _state.value.current
        if (current != null && current.courseId == courseId && current.language == lang) {
            resume()
            return
        }
        savePosition(force = true)
        val item = AudioQueueItem(courseId = courseId, languageCode = lang.code)
        val rest = _state.value.queue.filter { it.courseId != courseId }
        items = (listOf(item) + rest).toMutableList()
        loadPlaylist(playWhenReady = true)
        persistSession()
    }

    fun resume() {
        if (items.isEmpty()) return
        val player = player(appContext) as ExoPlayer
        if (!loaded || player.mediaItemCount == 0 || _state.value.failed) {
            loadPlaylist(playWhenReady = true)
            return
        }
        ensureService()
        if (player.playbackState == Player.STATE_ENDED) player.seekTo(0, 0)
        player.play()
        syncState()
    }

    fun pause() {
        exo?.pause()
        savePosition(force = true)
        syncState()
    }

    /** Stops and empties the player: the mini-player goes away. */
    fun stop() {
        savePosition(force = true)
        exo?.run {
            stop()
            clearMediaItems()
        }
        loaded = false
        items.clear()
        reportedCompletionFor = null
        ticker?.cancel()
        _state.update { UiState(rate = it.rate) }
        persistSession()
    }

    fun seekTo(positionMs: Long) {
        val target = positionMs.coerceIn(0, _state.value.durationMs.takeIf { it > 0 } ?: positionMs)
        exo?.takeIf { loaded }?.seekTo(target)
        _state.update { it.copy(positionMs = target) }
        val duration = _state.value.durationMs
        if (duration > 0 && target < duration * COMPLETION_THRESHOLD) reportedCompletionFor = null
        savePosition(force = true)
    }

    fun skip(deltaMs: Long) = seekTo(_state.value.positionMs + deltaMs)

    fun setRate(value: Float) {
        val rate = snap(value)
        if (rate == _state.value.rate) return
        exo?.setPlaybackSpeed(rate)
        _state.update { it.copy(rate = rate) }
        appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putFloat(RATE_KEY, rate).apply()
    }

    /** Same course, another language; each language keeps its own resume position. */
    fun switchLanguage(language: AudioLanguage) {
        CourseAudioCatalog.setPreferredLanguage(appContext, language)
        val current = _state.value.current ?: return
        if (current.language == language) return
        val wasPlaying = _state.value.isPlaying
        savePosition(force = true)
        val item = AudioQueueItem(courseId = current.courseId, languageCode = language.code)
        items[0] = item
        val player = exo
        if (loaded && player != null && player.mediaItemCount > 0) {
            player.replaceMediaItem(0, mediaItem(item))
            player.seekTo(0, resumePosition(item))
            player.playWhenReady = wasPlaying
        }
        reportedCompletionFor = null
        startPositionToCheck = resumePosition(item)
        _state.update { it.copy(current = item, positionMs = resumePosition(item), durationMs = 0, failed = false) }
        persistSession()
    }

    fun snap(value: Float): Float {
        val clamped = value.coerceIn(SPEED_MIN, SPEED_MAX)
        return ((clamped / SPEED_STEP).roundToInt() * SPEED_STEP * 100).roundToInt() / 100f
    }

    // MARK: - Queue

    fun enqueue(courseId: String, next: Boolean) {
        if (items.isEmpty()) {
            play(courseId)
            return
        }
        if (isCurrent(courseId)) return
        val lang = CourseAudioCatalog.defaultLanguage(appContext, courseId, appLanguage()) ?: return
        removeFromQueue(courseId, persist = false)
        val item = AudioQueueItem(courseId = courseId, languageCode = lang.code)
        val index = if (next) 1 else items.size
        items.add(index, item)
        exo?.takeIf { loaded }?.addMediaItem(index, mediaItem(item))
        publishQueue()
    }

    fun removeFromQueue(courseId: String, persist: Boolean = true) {
        val index = items.indexOfFirst { it.courseId == courseId }
        if (index <= 0) return
        items.removeAt(index)
        exo?.takeIf { loaded }?.removeMediaItem(index)
        if (persist) publishQueue()
    }

    /** Moves an up-next entry; indices are in the queue (0 = right after the current one). */
    fun moveInQueue(from: Int, to: Int) {
        val size = items.size - 1
        if (from !in 0 until size || to !in 0 until size || from == to) return
        val item = items.removeAt(from + 1)
        items.add(to + 1, item)
        exo?.takeIf { loaded }?.moveMediaItem(from + 1, to + 1)
        publishQueue()
    }

    fun clearQueue() {
        if (items.size <= 1) return
        exo?.takeIf { loaded }?.removeMediaItems(1, items.size)
        items = items.take(1).toMutableList()
        publishQueue()
    }

    fun playFromQueue(item: AudioQueueItem) {
        val index = items.indexOfFirst { it.id == item.id }
        if (index <= 0) return
        savePosition(force = true)
        items.removeAt(index)
        items[0] = item
        loadPlaylist(playWhenReady = true)
        persistSession()
    }

    /** Next narration; with an empty queue, the player closes. */
    fun skipToNext() {
        savePosition(force = true)
        if (items.size <= 1) {
            stop()
            return
        }
        items.removeAt(0)
        loadPlaylist(playWhenReady = true)
        persistSession()
    }

    // MARK: - Loading

    private fun resumePosition(item: AudioQueueItem): Long = positions[item.key.path] ?: 0L

    private fun mediaItem(item: AudioQueueItem): MediaItem {
        val language = appLanguage()
        val summary = ContentCatalog.summaries(appContext, language).firstOrNull { it.id == item.courseId }
        val author = AuthorStore.authorForCourse(appContext, item.courseId)
        val subject = summary?.let {
            StringStore.text(appContext, "subject.${it.subjectEnum.storageKey}.short", language)
        }
        val uri = CourseAudioDownloads.localFile(item.courseId, item.language)?.let(Uri::fromFile)
            ?: Uri.parse(CourseAudioCatalog.remoteUrl(item.courseId, item.language))
        val metadata = MediaMetadata.Builder()
            .setTitle(summary?.title ?: "Sophia")
            .setArtist(author?.name ?: "Sophia")
            .setAlbumTitle(subject?.let { "Sophia · $it" } ?: "Sophia")
            .setArtworkUri(CourseCoverUrls.url(appContext, item.courseId)?.let(Uri::parse))
            .setMediaType(MediaMetadata.MEDIA_TYPE_PODCAST_EPISODE)
            .build()
        return MediaItem.Builder()
            .setMediaId(item.id)
            .setUri(uri)
            .setMediaMetadata(metadata)
            .build()
    }

    private fun loadPlaylist(playWhenReady: Boolean) {
        val first = items.firstOrNull() ?: return
        val player = player(appContext) as ExoPlayer
        ensureService()
        reportedCompletionFor = null
        val start = resumePosition(first)
        startPositionToCheck = start
        player.setMediaItems(items.map(::mediaItem), 0, start)
        player.setPlaybackSpeed(_state.value.rate)
        player.prepare()
        player.playWhenReady = playWhenReady
        loaded = true
        _state.update {
            it.copy(
                current = first,
                queue = items.drop(1),
                positionMs = start,
                durationMs = 0,
                failed = false,
                isPlaying = playWhenReady,
            )
        }
        startTicker()
    }

    private fun publishQueue() {
        _state.update { it.copy(current = items.firstOrNull(), queue = items.drop(1)) }
        persistSession()
    }

    private val listener = object : Player.Listener {
        override fun onEvents(player: Player, events: Player.Events) {
            syncState()
        }

        override fun onPlaybackStateChanged(playbackState: Int) {
            if (playbackState == Player.STATE_ENDED) itemEnded(lastInPlaylist = true)
        }

        override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
            val player = exo ?: return
            val index = player.currentMediaItemIndex
            if (index <= 0 || index > items.size - 1) return
            when (reason) {
                // The previous narration played to its end: count it and forget its position.
                Player.MEDIA_ITEM_TRANSITION_REASON_AUTO -> itemEnded(lastInPlaylist = false)
                // "Next" from the notification, a headset or a watch.
                Player.MEDIA_ITEM_TRANSITION_REASON_SEEK -> savePositionOf(items.first(), lastKnownPositionMs)
                else -> return
            }
            // The playlist keeps starting with the one playing.
            repeat(index) { items.removeAt(0) }
            player.removeMediaItems(0, index)
            items.firstOrNull()?.let { next ->
                val start = resumePosition(next)
                if (start > 1_000) player.seekTo(0, start)
                startPositionToCheck = start
            }
            reportedCompletionFor = null
            publishQueue()
        }

        override fun onPlayerError(error: PlaybackException) {
            _state.update { it.copy(failed = true, isPlaying = false) }
        }
    }

    private fun itemEnded(lastInPlaylist: Boolean) {
        val finished = items.firstOrNull() ?: return
        if (reportedCompletionFor != finished.id) reportCompletion(finished)
        positions.remove(finished.key.path)
        persistPositions()
        if (lastInPlaylist) stop()
    }

    private fun reportCompletion(item: AudioQueueItem) {
        reportedCompletionFor = item.id
        onListenedToEnd?.invoke(item.courseId)
    }

    private fun syncState() {
        val player = exo ?: return
        if (!loaded) return
        val duration = player.duration.takeIf { it != C.TIME_UNSET && it > 0 } ?: 0L
        val buffering = player.playbackState == Player.STATE_BUFFERING
        _state.update {
            it.copy(
                isPlaying = player.playWhenReady && player.playbackState != Player.STATE_ENDED,
                isBuffering = buffering && player.playWhenReady,
                positionMs = player.currentPosition.coerceAtLeast(0),
                durationMs = duration,
            )
        }
    }

    private fun startTicker() {
        if (ticker?.isActive == true) return
        ticker = scope.launch {
            while (isActive) {
                delay(500)
                tick()
            }
        }
    }

    private fun tick() {
        val player = exo ?: return
        if (!loaded || items.isEmpty()) return
        syncState()
        val current = items.first()
        val duration = _state.value.durationMs
        val position = _state.value.positionMs
        if (duration > 0) {
            startPositionToCheck?.let { start ->
                // Resumed past the threshold: this playthrough was already counted.
                if (start.toDouble() / duration >= COMPLETION_THRESHOLD) reportedCompletionFor = current.id
                startPositionToCheck = null
            }
        }
        if (duration > 0 && reportedCompletionFor != current.id &&
            position.toDouble() / duration >= COMPLETION_THRESHOLD
        ) {
            reportCompletion(current)
        }
        lastKnownPositionMs = position
        if (player.isPlaying) savePosition(force = false)
    }

    // MARK: - Persistence

    private fun savePosition(force: Boolean) {
        val current = items.firstOrNull() ?: return
        val now = System.currentTimeMillis()
        if (!force && now - lastPositionSave < 5_000) return
        lastPositionSave = now
        val duration = _state.value.durationMs
        val position = _state.value.positionMs
        if (duration > 0 && position >= duration - 3_000) {
            positions.remove(current.key.path)
        } else {
            positions[current.key.path] = position
        }
        persistPositions()
    }

    private fun savePositionOf(item: AudioQueueItem, positionMs: Long) {
        positions[item.key.path] = positionMs
        persistPositions()
    }

    private fun persistPositions() {
        appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(POSITIONS_KEY, json.encodeToString(positions.toMap()))
            .apply()
    }

    private fun persistSession() {
        appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(SESSION_KEY, json.encodeToString(SavedAudioSession(items.toList())))
            .apply()
    }
}
