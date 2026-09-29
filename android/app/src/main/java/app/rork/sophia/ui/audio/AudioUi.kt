package app.rork.sophia.ui.audio

import android.text.format.Formatter
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.PlaylistAdd
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.Headphones
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.RemoveCircleOutline
import androidx.compose.material.icons.filled.SkipNext
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.audio.AudioLanguage
import app.rork.sophia.audio.CourseAudioCatalog
import app.rork.sophia.audio.CourseAudioDownloads
import app.rork.sophia.audio.CourseAudioPlayer
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.locale
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import java.text.NumberFormat

// MARK: - Formatting

internal object AudioFormat {
    fun time(ms: Long): String {
        val total = (ms.coerceAtLeast(0) / 1000).toInt()
        val h = total / 3600
        val m = (total % 3600) / 60
        val s = total % 60
        return if (h > 0) "%d:%02d:%02d".format(h, m, s) else "%d:%02d".format(m, s)
    }

    /** "1×", "1,25×" in the app language's decimal separator. */
    fun speed(rate: Float, language: AppLanguage): String {
        val format = NumberFormat.getNumberInstance(language.locale).apply {
            minimumFractionDigits = 0
            maximumFractionDigits = 2
        }
        return format.format(rate.toDouble()) + "×"
    }

    fun bytes(context: android.content.Context, bytes: Long): String =
        Formatter.formatShortFileSize(context, bytes)
}

/** A course's title and subject, read from the bundled index of the app language. */
@Composable
internal fun rememberCourseSummary(courseId: String, language: AppLanguage): CourseSummary? {
    val context = LocalContext.current
    return remember(courseId, language) {
        ContentCatalog.summaries(context.applicationContext, language).firstOrNull { it.id == courseId }
    }
}

/** Recomposes when the manifest or the downloads change, so audio buttons appear on their own. */
@Composable
internal fun ObserveAudioCatalog() {
    CourseAudioCatalog.manifest.collectAsState().value
    CourseAudioDownloads.downloaded.collectAsState().value
}

// MARK: - Cover

@Composable
internal fun AudioCover(courseId: String, modifier: Modifier = Modifier, corner: Dp = 12.dp) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(corner))
            .background(DS.surfaceMuted)
            .border(1.dp, DS.hairline, RoundedCornerShape(corner)),
    ) {
        CourseImage(courseId = courseId, modifier = Modifier.matchParentSize(), contentScale = ContentScale.Crop)
    }
}

// MARK: - Menu

/**
 * The audio actions of a course: listen, play next, add to the queue, download. Every one
 * goes through the player's premium gate, so a free user sees the same menu with a lock and
 * lands on the audio paywall.
 */
@Composable
internal fun AudioMenuItems(courseId: String, language: AppLanguage, onDone: () -> Unit) {
    val context = LocalContext.current
    val player by CourseAudioPlayer.state.collectAsState()
    CourseAudioDownloads.inFlight.collectAsState().value
    val downloadLanguage = CourseAudioCatalog.defaultLanguage(context, courseId, language) ?: return
    val premium = CourseAudioPlayer.isPremium
    fun t(key: String) = StringStore.text(context, key, language)

    DropdownMenuItem(
        text = { Text(t(if (CourseAudioPlayer.isPlayingCourse(courseId)) "audio.nowPlaying" else "audio.listen")) },
        leadingIcon = { Icon(if (premium) Icons.Filled.Headphones else Icons.Filled.Lock, null) },
        onClick = {
            onDone()
            CourseAudioPlayer.requestPlay(courseId)
        },
    )
    if (player.current != null && !CourseAudioPlayer.isCurrent(courseId)) {
        if (CourseAudioPlayer.isQueued(courseId)) {
            DropdownMenuItem(
                text = { Text(t("audio.removeFromQueue")) },
                leadingIcon = { Icon(Icons.Filled.RemoveCircleOutline, null) },
                onClick = {
                    onDone()
                    CourseAudioPlayer.removeFromQueue(courseId)
                },
            )
        } else {
            DropdownMenuItem(
                text = { Text(t("audio.playNext")) },
                leadingIcon = { Icon(Icons.Filled.SkipNext, null) },
                onClick = {
                    onDone()
                    CourseAudioPlayer.requestEnqueue(courseId, next = true)
                },
            )
            DropdownMenuItem(
                text = { Text(t("audio.addToQueue")) },
                leadingIcon = { Icon(Icons.AutoMirrored.Filled.PlaylistAdd, null) },
                onClick = {
                    onDone()
                    CourseAudioPlayer.requestEnqueue(courseId, next = false)
                },
            )
        }
    }
    when (CourseAudioDownloads.state(courseId, downloadLanguage)) {
        CourseAudioDownloads.State.None -> DropdownMenuItem(
            text = { Text("${t("audio.download")} · ${downloadLanguage.shortCode}") },
            leadingIcon = { Icon(if (premium) Icons.Filled.Download else Icons.Filled.Lock, null) },
            onClick = {
                onDone()
                CourseAudioPlayer.requestDownload(courseId, downloadLanguage)
            },
        )
        is CourseAudioDownloads.State.Downloading -> DropdownMenuItem(
            text = { Text(t("audio.downloading")) },
            leadingIcon = { Icon(Icons.Filled.Close, null) },
            onClick = {
                onDone()
                CourseAudioDownloads.cancel(courseId, downloadLanguage)
            },
        )
        CourseAudioDownloads.State.Downloaded -> DropdownMenuItem(
            text = { Text(t("audio.deleteDownload")) },
            leadingIcon = { Icon(Icons.Filled.Delete, null) },
            onClick = {
                onDone()
                CourseAudioDownloads.delete(courseId, downloadLanguage)
            },
        )
    }
}

/**
 * Headphones laid over a course cover. Tap: listen (or pause it). Long press: the whole
 * audio menu. With another narration loaded, a tap asks rather than cutting it off.
 * Absent when the course has no narration.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun CourseAudioButton(
    courseId: String,
    language: AppLanguage,
    modifier: Modifier = Modifier,
    size: Dp = 38.dp,
) {
    ObserveAudioCatalog()
    if (!CourseAudioCatalog.hasAudio(courseId)) return
    val context = LocalContext.current
    val haptics = LocalHapticFeedback.current
    val player by CourseAudioPlayer.state.collectAsState()
    var menu by remember { mutableStateOf(false) }
    var choice by remember { mutableStateOf(false) }
    val playing = player.current?.courseId == courseId && player.isPlaying

    Box(modifier = modifier) {
        Box(
            modifier = Modifier
                .size(size)
                .clip(CircleShape)
                .background(DS.surface.copy(alpha = 0.92f))
                .border(1.dp, DS.hairline, CircleShape)
                .combinedClickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null,
                    onClickLabel = StringStore.text(context, "audio.listen", language),
                    onLongClick = {
                        haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                        menu = true
                    },
                    onClick = {
                        when {
                            playing -> CourseAudioPlayer.pause()
                            CourseAudioPlayer.isPremium && player.current != null &&
                                player.current?.courseId != courseId -> choice = true
                            else -> CourseAudioPlayer.requestPlay(courseId)
                        }
                    },
                ),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = if (playing) Icons.Filled.GraphicEq else Icons.Filled.Headphones,
                contentDescription = StringStore.text(context, "audio.listen", language),
                tint = if (player.current?.courseId == courseId) DS.accent else DS.inkSecondary,
                modifier = Modifier.size(size * 0.46f),
            )
        }
        DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
            AudioMenuItems(courseId, language) { menu = false }
        }
    }
    if (choice) {
        AudioPlayChoiceDialog(
            courseId = courseId,
            language = language,
            onPlayNow = { CourseAudioPlayer.requestPlay(courseId) },
            onDismiss = { choice = false },
        )
    }
}

// MARK: - Choice when another course is playing

/** "Écouter maintenant / Lire ensuite / Ajouter à la file" instead of cutting off what plays. */
@Composable
fun AudioPlayChoiceDialog(
    courseId: String,
    language: AppLanguage,
    onPlayNow: () -> Unit,
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    val haptics = LocalHapticFeedback.current
    fun t(key: String) = StringStore.text(context, key, language)

    @Composable
    fun Choice(text: String, icon: ImageVector, action: () -> Unit) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(DS.controlShape)
                .softPress(onClick = {
                    onDismiss()
                    action()
                })
                .padding(vertical = 12.dp, horizontal = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Icon(icon, contentDescription = null, tint = DS.accentSoft)
            Text(text, style = SophiaTypography.bodyLarge.copy(fontSize = 16.sp), color = DS.ink)
        }
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = DS.surface,
        title = { Text(t("audio.choice.title"), style = SophiaTypography.titleMedium) },
        text = {
            Column {
                Choice(t("audio.playNow"), Icons.Filled.PlayArrow, onPlayNow)
                Choice(t("audio.playNext"), Icons.Filled.SkipNext) {
                    if (CourseAudioPlayer.requestEnqueue(courseId, next = true)) {
                        haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                    }
                }
                Choice(t("audio.addToQueue"), Icons.AutoMirrored.Filled.PlaylistAdd) {
                    if (CourseAudioPlayer.requestEnqueue(courseId, next = false)) {
                        haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) { Text(t("audio.cancel"), color = DS.inkSecondary) }
        },
    )
}

// MARK: - Mini player

/** The bar above the tabs while a narration is loaded. Tap: full player. */
@Composable
fun AudioMiniPlayer(language: AppLanguage, onOpen: () -> Unit) {
    val context = LocalContext.current
    val state by CourseAudioPlayer.state.collectAsState()
    val current = state.current
    AnimatedVisibility(
        visible = current != null,
        enter = fadeIn() + slideInVertically { it },
        exit = fadeOut() + slideOutVertically { it },
    ) {
        val item = current ?: return@AnimatedVisibility
        val summary = rememberCourseSummary(item.courseId, language)
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 10.dp, vertical = 6.dp)
                .clip(DS.controlShape)
                .background(DS.surface)
                .border(1.dp, DS.hairline, DS.controlShape)
                .softPress(onClick = onOpen, scaleDown = 0.99f),
        ) {
            Row(
                modifier = Modifier.padding(start = 8.dp, end = 4.dp, top = 7.dp, bottom = 7.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                AudioCover(item.courseId, modifier = Modifier.size(42.dp), corner = 8.dp)
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = summary?.title ?: "Sophia",
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 14.sp,
                        color = DS.ink,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                    val lang = "${item.language.flag} ${item.language.shortCode}"
                    Text(
                        text = if (state.durationMs > 0) {
                            "$lang · -${AudioFormat.time(state.durationMs - state.positionMs)}"
                        } else {
                            lang
                        },
                        style = SophiaTypography.labelMedium,
                        maxLines = 1,
                    )
                }
                Box(
                    modifier = Modifier.size(40.dp).clip(CircleShape).softPress(onClick = { CourseAudioPlayer.togglePlayPause() }),
                    contentAlignment = Alignment.Center,
                ) {
                    if (state.isBuffering) {
                        CircularProgressIndicator(color = DS.accent, strokeWidth = 2.dp, modifier = Modifier.size(20.dp))
                    } else {
                        Icon(
                            if (state.isPlaying) Icons.Filled.Pause else Icons.Filled.PlayArrow,
                            contentDescription = StringStore.text(context, if (state.isPlaying) "audio.pause" else "audio.play", language),
                            tint = DS.ink,
                        )
                    }
                }
                Box(
                    modifier = Modifier.size(36.dp).clip(CircleShape).softPress(onClick = { CourseAudioPlayer.stop() }),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        Icons.Filled.Close,
                        contentDescription = StringStore.text(context, "audio.close", language),
                        tint = DS.inkSecondary,
                        modifier = Modifier.size(18.dp),
                    )
                }
            }
            Box(
                modifier = Modifier
                    .padding(horizontal = 14.dp)
                    .fillMaxWidth(state.progress)
                    .height(2.dp)
                    .background(DS.accent),
            )
        }
    }
}

/** A narration language as "🇫🇷 Français". */
internal fun AudioLanguage.label(): String = "$flag $displayName"

/**
 * Headphones in the course reader's header. Premium: listen and open the player (asking
 * first when another course is loaded). Free: [onLocked], which opens the audio paywall.
 */
@Composable
fun CourseReaderAudioButton(
    courseId: String,
    language: AppLanguage,
    isPremium: Boolean,
    onLocked: () -> Unit,
    onOpenPlayer: () -> Unit,
) {
    ObserveAudioCatalog()
    if (!CourseAudioCatalog.hasAudio(courseId)) return
    val context = LocalContext.current
    val player by CourseAudioPlayer.state.collectAsState()
    var choice by remember { mutableStateOf(false) }
    val isCurrent = player.current?.courseId == courseId
    val playing = isCurrent && player.isPlaying

    Box(
        modifier = Modifier
            .size(40.dp)
            .clip(CircleShape)
            .background(DS.surface)
            .border(1.dp, DS.hairline, CircleShape)
            .softPress(onClick = {
                when {
                    !isPremium -> onLocked()
                    player.current != null && !isCurrent -> choice = true
                    else -> {
                        CourseAudioPlayer.isPremium = true
                        if (!isCurrent) {
                            CourseAudioPlayer.play(courseId)
                        } else if (!player.isPlaying) {
                            CourseAudioPlayer.resume()
                        }
                        onOpenPlayer()
                    }
                }
            }),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector = when {
                playing -> Icons.Filled.GraphicEq
                isPremium -> Icons.Filled.Headphones
                else -> Icons.Filled.Lock
            },
            contentDescription = StringStore.text(context, "audio.listen", language),
            tint = if (isCurrent) DS.accent else DS.inkSecondary,
            modifier = Modifier.size(19.dp),
        )
    }
    if (choice) {
        AudioPlayChoiceDialog(
            courseId = courseId,
            language = language,
            onPlayNow = {
                CourseAudioPlayer.play(courseId)
                onOpenPlayer()
            },
            onDismiss = { choice = false },
        )
    }
}
