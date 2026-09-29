package app.rork.sophia.ui.audio

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.QueueMusic
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.ArrowDownward
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.DownloadDone
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.Language
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Replay
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.SkipNext
import androidx.compose.material.icons.filled.Speed
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.audio.AudioQueueItem
import app.rork.sophia.audio.CourseAudioCatalog
import app.rork.sophia.audio.CourseAudioDownloads
import app.rork.sophia.audio.CourseAudioPlayer
import app.rork.sophia.data.AuthorStore
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.Subject
import app.rork.sophia.domain.locale
import app.rork.sophia.ui.components.CircleIconButton
import app.rork.sophia.ui.components.SectionLabel
import app.rork.sophia.ui.components.SophiaSecondaryButton
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import kotlin.math.abs

private enum class PlayerPage { Player, Queue, Browse }

/**
 * Full-screen player, opened from the mini-player or the headphones of a course: cover,
 * position, ±15 s, speed (0.5× to 2×), narration language, download, queue, and courses
 * to queue next.
 */
@Composable
fun AudioPlayerScreen(language: AppLanguage, onClose: () -> Unit) {
    val state by CourseAudioPlayer.state.collectAsState()
    var page by remember { mutableStateOf(PlayerPage.Player) }
    val current = state.current

    LaunchedEffect(current == null) {
        // End of the queue, or stopped from the notification: nothing left to show.
        if (current == null) onClose()
    }
    BackHandler(enabled = page != PlayerPage.Player) { page = PlayerPage.Player }
    if (current == null) return

    when (page) {
        PlayerPage.Player -> PlayerPageContent(
            item = current,
            language = language,
            onClose = onClose,
            onOpenQueue = { page = PlayerPage.Queue },
            onBrowse = { page = PlayerPage.Browse },
        )
        PlayerPage.Queue -> AudioQueuePage(language = language, onBack = { page = PlayerPage.Player })
        PlayerPage.Browse -> AudioBrowsePage(language = language, onBack = { page = PlayerPage.Player })
    }
}

@Composable
private fun PlayerPageContent(
    item: AudioQueueItem,
    language: AppLanguage,
    onClose: () -> Unit,
    onOpenQueue: () -> Unit,
    onBrowse: () -> Unit,
) {
    val context = LocalContext.current
    val state by CourseAudioPlayer.state.collectAsState()
    val summary = rememberCourseSummary(item.courseId, language)
    val author = remember(item.courseId) { AuthorStore.authorForCourse(context.applicationContext, item.courseId) }
    fun t(key: String) = StringStore.text(context, key, language)

    Column(
        modifier = Modifier.fillMaxSize().background(DS.canvas),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = DS.Space.l, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            CircleIconButton(icon = Icons.Filled.KeyboardArrowDown, onClick = onClose)
            Text(
                text = t("audio.nowPlaying").uppercase(language.locale),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 11.sp,
                letterSpacing = 1.2.sp,
                color = DS.inkTertiary,
                textAlign = TextAlign.Center,
                modifier = Modifier.weight(1f),
            )
            Spacer(Modifier.size(40.dp))
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .widthIn(max = 520.dp)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.height(8.dp))
            AudioCover(
                courseId = item.courseId,
                corner = DS.Radius.card,
                modifier = Modifier
                    .fillMaxWidth(0.82f)
                    .aspectRatio(1f)
                    .scale(if (state.isPlaying) 1f else 0.9f),
            )
            Spacer(Modifier.height(22.dp))
            Text(
                text = summary?.title ?: "Sophia",
                style = SophiaTypography.titleLarge.copy(fontSize = 21.sp, lineHeight = 27.sp),
                textAlign = TextAlign.Center,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
            )
            Spacer(Modifier.height(6.dp))
            Text(
                text = listOfNotNull(
                    author?.name,
                    summary?.let { StringStore.text(context, "subject.${it.subjectEnum.storageKey}.short", language) },
                    "${item.language.flag} ${item.language.shortCode}",
                ).joinToString(" · "),
                style = SophiaTypography.bodyMedium,
                textAlign = TextAlign.Center,
            )

            Spacer(Modifier.height(18.dp))
            Scrubber()

            if (state.failed) {
                Spacer(Modifier.height(10.dp))
                Row(
                    modifier = Modifier.fillMaxWidth().clip(DS.controlShape).background(DS.dangerTint).padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Text(t("audio.error"), style = SophiaTypography.bodyMedium, color = DS.ink, modifier = Modifier.weight(1f))
                    Text(
                        t("audio.retry"),
                        color = DS.accentSoft,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.softPress(onClick = { CourseAudioPlayer.resume() }),
                    )
                }
            }

            Spacer(Modifier.height(14.dp))
            Transport(language)
            Spacer(Modifier.height(20.dp))
            SpeedCard(language)
            Spacer(Modifier.height(14.dp))
            ActionRow(item = item, language = language, onOpenQueue = onOpenQueue)
            Spacer(Modifier.height(24.dp))
            SuggestionsSection(courseId = item.courseId, language = language, onBrowse = onBrowse)
            Spacer(Modifier.height(32.dp))
        }
    }
}

@Composable
private fun Scrubber() {
    val state by CourseAudioPlayer.state.collectAsState()
    var dragging by remember { mutableStateOf(false) }
    var dragValue by remember { mutableFloatStateOf(0f) }
    val duration = state.durationMs
    val shown = if (dragging) (dragValue * duration).toLong() else state.positionMs
    Column(modifier = Modifier.fillMaxWidth()) {
        Slider(
            value = if (dragging) dragValue else state.progress,
            onValueChange = {
                dragging = true
                dragValue = it
            },
            onValueChangeFinished = {
                CourseAudioPlayer.seekTo((dragValue * duration).toLong())
                dragging = false
            },
            enabled = duration > 0,
            colors = SliderDefaults.colors(
                thumbColor = DS.accent,
                activeTrackColor = DS.accent,
                inactiveTrackColor = DS.hairline,
            ),
        )
        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text(AudioFormat.time(shown), style = SophiaTypography.labelMedium)
            Box(modifier = Modifier.weight(1f), contentAlignment = Alignment.Center) {
                if (state.isBuffering) {
                    CircularProgressIndicator(color = DS.accent, strokeWidth = 2.dp, modifier = Modifier.size(14.dp))
                }
            }
            Text(
                if (duration > 0) "-" + AudioFormat.time(duration - shown) else "--:--",
                style = SophiaTypography.labelMedium,
            )
        }
    }
}

@Composable
private fun Transport(language: AppLanguage) {
    val context = LocalContext.current
    val state by CourseAudioPlayer.state.collectAsState()
    val haptics = LocalHapticFeedback.current
    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(30.dp)) {
            SkipButton(forward = false, label = StringStore.text(context, "audio.skipBack", language)) {
                CourseAudioPlayer.skip(-CourseAudioPlayer.SKIP_MS)
            }
            Box(
                modifier = Modifier
                    .size(78.dp)
                    .clip(CircleShape)
                    .background(DS.accent)
                    .softPress(onClick = {
                        haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                        CourseAudioPlayer.togglePlayPause()
                    }),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    if (state.isPlaying) Icons.Filled.Pause else Icons.Filled.PlayArrow,
                    contentDescription = StringStore.text(context, if (state.isPlaying) "audio.pause" else "audio.play", language),
                    tint = DS.surface,
                    modifier = Modifier.size(38.dp),
                )
            }
            SkipButton(forward = true, label = StringStore.text(context, "audio.skipForward", language)) {
                CourseAudioPlayer.skip(CourseAudioPlayer.SKIP_MS)
            }
        }
        if (state.queue.isNotEmpty()) {
            Box(
                modifier = Modifier
                    .align(Alignment.CenterEnd)
                    .size(44.dp)
                    .clip(CircleShape)
                    .softPress(onClick = { CourseAudioPlayer.skipToNext() }),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Filled.SkipNext, contentDescription = StringStore.text(context, "audio.next", language), tint = DS.ink)
            }
        }
    }
}

/** A circular arrow with "15" inside; mirrored for forward. */
@Composable
private fun SkipButton(forward: Boolean, label: String, onClick: () -> Unit) {
    Box(
        modifier = Modifier.size(52.dp).clip(CircleShape).softPress(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            Icons.Filled.Replay,
            contentDescription = label,
            tint = DS.ink,
            modifier = Modifier.size(34.dp).graphicsLayer { scaleX = if (forward) -1f else 1f },
        )
        Text("15", fontSize = 9.sp, fontWeight = FontWeight.Bold, color = DS.ink, modifier = Modifier.padding(top = 3.dp))
    }
}

@Composable
private fun SpeedCard(language: AppLanguage) {
    val context = LocalContext.current
    val state by CourseAudioPlayer.state.collectAsState()
    var value by remember { mutableFloatStateOf(state.rate) }
    LaunchedEffect(state.rate) {
        // Changed elsewhere (a Bluetooth control, another screen).
        if (abs(state.rate - value) > 0.001f) value = state.rate
    }
    Column(modifier = Modifier.fillMaxWidth().sophiaCard(shape = DS.controlShape, elevation = 2.dp).padding(16.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Icon(Icons.Filled.Speed, contentDescription = null, tint = DS.accentSoft, modifier = Modifier.size(18.dp))
            Text(
                StringStore.text(context, "audio.speed", language),
                style = SophiaTypography.bodyLarge.copy(fontWeight = FontWeight.SemiBold),
                modifier = Modifier.weight(1f),
            )
            Text(
                AudioFormat.speed(value, language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                color = DS.accentSoft,
            )
            if (abs(value - 1f) > 0.001f) {
                Text(
                    "1×",
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 12.sp,
                    color = DS.inkSecondary,
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(DS.accentTint)
                        .softPress(onClick = {
                            value = 1f
                            CourseAudioPlayer.setRate(1f)
                        })
                        .padding(horizontal = 10.dp, vertical = 4.dp),
                )
            }
        }
        Slider(
            value = value,
            onValueChange = {
                value = CourseAudioPlayer.snap(it)
                // Live, so the listener hears the speed while dragging.
                CourseAudioPlayer.setRate(value)
            },
            onValueChangeFinished = {
                (context.applicationContext as app.rork.sophia.SophiaApplication).analytics.track(
                    "audio_speed_changed",
                    mapOf("rate" to value.toDouble()),
                )
            },
            valueRange = CourseAudioPlayer.SPEED_MIN..CourseAudioPlayer.SPEED_MAX,
            steps = ((CourseAudioPlayer.SPEED_MAX - CourseAudioPlayer.SPEED_MIN) / CourseAudioPlayer.SPEED_STEP).toInt() - 1,
            colors = SliderDefaults.colors(
                thumbColor = DS.accent,
                activeTrackColor = DS.accent,
                inactiveTrackColor = DS.hairline,
                activeTickColor = DS.accent.copy(alpha = 0f),
                inactiveTickColor = DS.hairline.copy(alpha = 0f),
            ),
        )
        Row(modifier = Modifier.fillMaxWidth()) {
            Text(AudioFormat.speed(CourseAudioPlayer.SPEED_MIN, language), style = SophiaTypography.labelMedium)
            Spacer(Modifier.weight(1f))
            Text(AudioFormat.speed(CourseAudioPlayer.SPEED_MAX, language), style = SophiaTypography.labelMedium)
        }
    }
}

@Composable
private fun ActionRow(item: AudioQueueItem, language: AppLanguage, onOpenQueue: () -> Unit) {
    val context = LocalContext.current
    val state by CourseAudioPlayer.state.collectAsState()
    CourseAudioDownloads.downloaded.collectAsState().value
    CourseAudioDownloads.inFlight.collectAsState().value
    fun t(key: String) = StringStore.text(context, key, language)
    var languageMenu by remember { mutableStateOf(false) }
    var deleteMenu by remember { mutableStateOf(false) }

    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Box(modifier = Modifier.weight(1f)) {
            ActionTile(Icons.Filled.Language, "${item.language.flag} ${item.language.shortCode}", t("audio.language")) {
                languageMenu = true
            }
            DropdownMenu(expanded = languageMenu, onDismissRequest = { languageMenu = false }) {
                CourseAudioCatalog.languages(item.courseId).forEach { lang ->
                    DropdownMenuItem(
                        text = { Text(lang.label()) },
                        trailingIcon = if (lang == item.language) {
                            { Icon(Icons.Filled.CheckCircle, null, tint = DS.accent) }
                        } else {
                            null
                        },
                        onClick = {
                            languageMenu = false
                            CourseAudioPlayer.switchLanguage(lang)
                        },
                    )
                }
            }
        }
        Box(modifier = Modifier.weight(1f)) {
            when (val download = CourseAudioDownloads.state(item.courseId, item.language)) {
                CourseAudioDownloads.State.None ->
                    ActionTile(Icons.Filled.Download, item.language.shortCode, t("audio.download")) {
                        CourseAudioPlayer.requestDownload(item.courseId, item.language, "player")
                    }
                is CourseAudioDownloads.State.Downloading ->
                    ActionTile(Icons.Filled.Close, "${(download.fraction * 100).toInt()} %", t("audio.downloading")) {
                        CourseAudioDownloads.cancel(item.courseId, item.language)
                    }
                CourseAudioDownloads.State.Downloaded -> {
                    ActionTile(Icons.Filled.DownloadDone, item.language.shortCode, t("audio.downloaded"), tint = DS.success) {
                        deleteMenu = true
                    }
                    DropdownMenu(expanded = deleteMenu, onDismissRequest = { deleteMenu = false }) {
                        DropdownMenuItem(
                            text = { Text(t("audio.deleteDownload"), color = DS.danger) },
                            leadingIcon = { Icon(Icons.Filled.Delete, null, tint = DS.danger) },
                            onClick = {
                                deleteMenu = false
                                CourseAudioDownloads.delete(item.courseId, item.language)
                            },
                        )
                    }
                }
            }
        }
        Box(modifier = Modifier.weight(1f)) {
            ActionTile(Icons.AutoMirrored.Filled.QueueMusic, "${state.queue.size}", t("audio.upNext"), onClick = onOpenQueue)
        }
    }
}

@Composable
private fun ActionTile(
    icon: ImageVector,
    value: String,
    title: String,
    tint: androidx.compose.ui.graphics.Color = DS.accentSoft,
    onClick: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .sophiaCard(shape = DS.controlShape, elevation = 2.dp)
            .softPress(onClick = onClick)
            .padding(vertical = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(20.dp))
        Text(value, fontFamily = PlusJakartaSans, fontWeight = FontWeight.Bold, fontSize = 14.sp, color = DS.ink, maxLines = 1)
        Text(title, style = SophiaTypography.labelMedium.copy(fontSize = 11.sp), maxLines = 1, overflow = TextOverflow.Ellipsis)
    }
}

// MARK: - Suggestions

/**
 * The rest of the current course's collection first (reading order, starting after it),
 * then the same subject, then everything else. Only narrated courses, never the one playing
 * or one already queued; unread courses before finished ones.
 */
@Composable
private fun rememberSuggestions(courseId: String, language: AppLanguage, limit: Int = 6): List<CourseSummary> {
    val context = LocalContext.current
    val state by CourseAudioPlayer.state.collectAsState()
    val manifest by CourseAudioCatalog.manifest.collectAsState()
    return remember(courseId, language, state.queue, manifest) {
        val app = context.applicationContext
        val excluded = state.queue.map { it.courseId }.toSet() + courseId
        val narrated = ContentCatalog.summaries(app, language)
            .filter { it.id !in excluded && CourseAudioCatalog.hasAudio(it.id) }
        if (narrated.isEmpty()) return@remember emptyList()
        val byId = narrated.associateBy { it.id }
        val ordered = LinkedHashMap<String, CourseSummary>()
        ContentCatalog.collections(app, language).forEach { collection ->
            val index = collection.courseIds.indexOf(courseId)
            if (index < 0) return@forEach
            (collection.courseIds.drop(index + 1) + collection.courseIds.take(index))
                .mapNotNull { byId[it] }
                .forEach { ordered.putIfAbsent(it.id, it) }
        }
        val subject = ContentCatalog.summaries(app, language).firstOrNull { it.id == courseId }?.subject
        narrated.filter { it.subject == subject }.forEach { ordered.putIfAbsent(it.id, it) }
        narrated.forEach { ordered.putIfAbsent(it.id, it) }
        val done = CourseAudioPlayer.isCourseCompleted ?: { false }
        val (finished, fresh) = ordered.values.partition { done(it.id) }
        (fresh + finished).take(limit)
    }
}

@Composable
private fun SuggestionsSection(courseId: String, language: AppLanguage, onBrowse: () -> Unit) {
    val context = LocalContext.current
    val suggestions = rememberSuggestions(courseId, language)
    Column(modifier = Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(
            StringStore.text(context, "audio.suggestions.title", language),
            style = SophiaTypography.titleMedium.copy(fontSize = 17.sp),
        )
        if (suggestions.isNotEmpty()) {
            Column(modifier = Modifier.fillMaxWidth().sophiaCard(shape = DS.controlShape, elevation = 2.dp).padding(horizontal = 12.dp)) {
                suggestions.forEachIndexed { index, course ->
                    if (index > 0) HorizontalDivider(color = DS.hairline, modifier = Modifier.padding(start = 58.dp))
                    AudioAddRow(course = course, language = language, source = "player_suggestions")
                }
            }
        }
        SophiaSecondaryButton(
            text = StringStore.text(context, "audio.browse", language),
            onClick = onBrowse,
        )
    }
}

/**
 * A narrated course with its queue button: ＋ adds it at the end, ✓ once queued (a tap takes
 * it out again), the waveform while it plays. Long press on the row: the full audio menu.
 */
@Composable
private fun AudioAddRow(course: CourseSummary, language: AppLanguage, source: String) {
    val context = LocalContext.current
    val haptics = LocalHapticFeedback.current
    val state by CourseAudioPlayer.state.collectAsState()
    val isCurrent = state.current?.courseId == course.id
    val queued = state.queue.any { it.courseId == course.id }
    var menu by remember { mutableStateOf(false) }
    val flags = CourseAudioCatalog.languages(course.id).joinToString(" ") { it.flag }

    Box {
        Row(
            modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            AudioCover(course.id, modifier = Modifier.size(46.dp), corner = 8.dp)
            Column(modifier = Modifier.weight(1f).softPress(onClick = { menu = true })) {
                Text(
                    course.title,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 14.sp,
                    color = DS.ink,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
                Text(
                    StringStore.text(context, "subject.${course.subjectEnum.storageKey}.short", language) + " · " + flags,
                    style = SophiaTypography.labelMedium,
                    maxLines = 1,
                )
            }
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .softPress(enabled = !isCurrent, onClick = {
                        if (queued) {
                            CourseAudioPlayer.removeFromQueue(course.id)
                        } else if (CourseAudioPlayer.requestEnqueue(course.id, next = false, source = source)) {
                            haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                        }
                    }),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = when {
                        isCurrent -> Icons.Filled.GraphicEq
                        queued -> Icons.Filled.CheckCircle
                        else -> Icons.Filled.AddCircle
                    },
                    contentDescription = StringStore.text(
                        context,
                        if (queued) "audio.removeFromQueue" else "audio.addToQueue",
                        language,
                    ),
                    tint = when {
                        queued -> DS.success
                        else -> DS.accent
                    },
                    modifier = Modifier.size(28.dp),
                )
            }
        }
        DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
            AudioMenuItems(course.id, language, source) { menu = false }
        }
    }
}

// MARK: - Queue

@Composable
private fun AudioQueuePage(language: AppLanguage, onBack: () -> Unit) {
    val context = LocalContext.current
    val state by CourseAudioPlayer.state.collectAsState()
    fun t(key: String) = StringStore.text(context, key, language)

    SubPage(title = t("audio.queue.title"), language = language, onBack = onBack) {
        LazyColumn(modifier = Modifier.fillMaxSize(), contentPadding = androidx.compose.foundation.layout.PaddingValues(DS.Space.l)) {
            state.current?.let { current ->
                item(key = "now") {
                    SectionLabel(t("audio.nowPlaying"), modifier = Modifier.padding(bottom = 8.dp))
                    QueueRow(item = current, language = language, isCurrent = true)
                    Spacer(Modifier.height(20.dp))
                }
            }
            item(key = "next-label") {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    SectionLabel(t("audio.upNext"), modifier = Modifier.weight(1f).padding(bottom = 8.dp))
                    if (state.queue.isNotEmpty()) {
                        Text(
                            t("audio.queue.clear"),
                            color = DS.danger,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 13.sp,
                            modifier = Modifier.softPress(onClick = { CourseAudioPlayer.clearQueue() }).padding(bottom = 8.dp),
                        )
                    }
                }
            }
            if (state.queue.isEmpty()) {
                item(key = "empty") {
                    Text(t("audio.queue.empty"), style = SophiaTypography.bodyMedium)
                }
            }
            items(state.queue, key = { it.id }) { queued ->
                val index = state.queue.indexOf(queued)
                QueueRow(
                    item = queued,
                    language = language,
                    isCurrent = false,
                    onPlay = { CourseAudioPlayer.playFromQueue(queued) },
                    onUp = if (index > 0) ({ CourseAudioPlayer.moveInQueue(index, index - 1) }) else null,
                    onDown = if (index < state.queue.lastIndex) ({ CourseAudioPlayer.moveInQueue(index, index + 1) }) else null,
                    onRemove = { CourseAudioPlayer.removeFromQueue(queued.courseId) },
                )
            }
        }
    }
}

@Composable
private fun QueueRow(
    item: AudioQueueItem,
    language: AppLanguage,
    isCurrent: Boolean,
    onPlay: (() -> Unit)? = null,
    onUp: (() -> Unit)? = null,
    onDown: (() -> Unit)? = null,
    onRemove: (() -> Unit)? = null,
) {
    val summary = rememberCourseSummary(item.courseId, language)
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        AudioCover(item.courseId, modifier = Modifier.size(46.dp), corner = 8.dp)
        Column(modifier = Modifier.weight(1f).softPress(enabled = onPlay != null, onClick = { onPlay?.invoke() })) {
            Text(
                summary?.title ?: item.courseId,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 14.sp,
                color = DS.ink,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            Text(item.language.label(), style = SophiaTypography.labelMedium)
        }
        if (isCurrent) {
            Icon(Icons.Filled.GraphicEq, contentDescription = null, tint = DS.accent)
        } else {
            SmallIcon(Icons.Filled.ArrowUpward, onUp)
            SmallIcon(Icons.Filled.ArrowDownward, onDown)
            SmallIcon(Icons.Filled.Delete, onRemove, tint = DS.danger)
        }
    }
}

@Composable
private fun SmallIcon(icon: ImageVector, onClick: (() -> Unit)?, tint: androidx.compose.ui.graphics.Color = DS.inkSecondary) {
    Box(
        modifier = Modifier.size(34.dp).clip(CircleShape).softPress(enabled = onClick != null, onClick = { onClick?.invoke() }),
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, contentDescription = null, tint = if (onClick != null) tint else DS.hairline, modifier = Modifier.size(18.dp))
    }
}

// MARK: - Browse

@Composable
private fun AudioBrowsePage(language: AppLanguage, onBack: () -> Unit) {
    val context = LocalContext.current
    val manifest by CourseAudioCatalog.manifest.collectAsState()
    var query by remember { mutableStateOf("") }
    var subject by remember { mutableStateOf<Subject?>(null) }
    val all = remember(language, manifest) {
        ContentCatalog.summaries(context.applicationContext, language).filter { CourseAudioCatalog.hasAudio(it.id) }
    }
    val courses = remember(all, query, subject) {
        all.filter { course ->
            (subject == null || course.subjectEnum == subject) &&
                (query.isBlank() || course.title.contains(query, ignoreCase = true) ||
                    course.subcategory.contains(query, ignoreCase = true))
        }
    }
    fun t(key: String) = StringStore.text(context, key, language)

    SubPage(title = t("audio.browse.title"), language = language, onBack = onBack) {
        Column(modifier = Modifier.fillMaxSize()) {
            Row(
                modifier = Modifier
                    .padding(horizontal = DS.Space.l)
                    .fillMaxWidth()
                    .clip(DS.controlShape)
                    .background(DS.surface)
                    .border(1.dp, DS.hairline, DS.controlShape)
                    .padding(horizontal = 16.dp, vertical = 13.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Icon(Icons.Filled.Search, contentDescription = null, tint = DS.inkTertiary, modifier = Modifier.size(18.dp))
                Box(modifier = Modifier.weight(1f)) {
                    if (query.isEmpty()) {
                        Text(t("audio.browse.search"), style = SophiaTypography.bodyMedium, color = DS.inkTertiary)
                    }
                    BasicTextField(
                        value = query,
                        onValueChange = { query = it },
                        singleLine = true,
                        textStyle = SophiaTypography.bodyMedium.copy(color = DS.ink),
                        cursorBrush = SolidColor(DS.accentSoft),
                        modifier = Modifier.fillMaxWidth(),
                    )
                }
            }
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .padding(horizontal = DS.Space.l, vertical = 10.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Chip(t("audio.browse.all"), selected = subject == null) { subject = null }
                Subject.entries.forEach { s ->
                    Chip(StringStore.text(context, "subject.${s.storageKey}.short", language), selected = subject == s) {
                        subject = s
                    }
                }
            }
            if (courses.isEmpty()) {
                Text(t("audio.browse.empty"), style = SophiaTypography.bodyMedium, modifier = Modifier.padding(DS.Space.l))
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = DS.Space.l, vertical = 4.dp),
                ) {
                    items(courses, key = { it.id }) { course ->
                        AudioAddRow(course = course, language = language, source = "audio_browse")
                        HorizontalDivider(color = DS.hairline, modifier = Modifier.padding(start = 58.dp))
                    }
                }
            }
        }
    }
}

@Composable
private fun Chip(text: String, selected: Boolean, onClick: () -> Unit) {
    Text(
        text = text,
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.SemiBold,
        fontSize = 14.sp,
        color = if (selected) DS.surface else DS.ink,
        modifier = Modifier
            .clip(CircleShape)
            .background(if (selected) DS.accent else DS.surface)
            .border(if (selected) 0.dp else 1.dp, DS.hairline, CircleShape)
            .softPress(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 8.dp),
    )
}

@Composable
internal fun SubPage(title: String, language: AppLanguage, onBack: () -> Unit, content: @Composable () -> Unit) {
    Column(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = DS.Space.s, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            CircleIconButton(icon = Icons.AutoMirrored.Filled.ArrowBack, onClick = onBack)
            Text(
                text = title,
                style = SophiaTypography.titleMedium.copy(fontSize = 17.sp),
                modifier = Modifier.padding(horizontal = 12.dp).weight(1f),
                maxLines = 1,
            )
            Spacer(Modifier.width(40.dp))
        }
        content()
    }
}
