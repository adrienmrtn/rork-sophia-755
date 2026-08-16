package app.rork.sophia.ui.home

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectVerticalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.CourseImagePrefetch
import app.rork.sophia.data.DeviceCapabilities
import app.rork.sophia.data.ShareHelper
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.TutorialFlags
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.ui.components.CircleIconButton
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.components.Pill
import app.rork.sophia.ui.components.SophiaPrimaryButton
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.components.FirstOpenExplanation
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import kotlin.math.roundToInt
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun HomeTikTokScreen(
    modifier: Modifier = Modifier,
    language: AppLanguage,
    favoriteIds: Set<String>,
    autoSwipeCourseId: String?,
    onAutoSwipeConsumed: () -> Unit,
    onToggleFavorite: (String) -> Unit,
    onStartCourse: (String) -> Unit,
    onUserSwipe: () -> Unit = {},
    streak: Int = 0,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val cached = remember(language) {
        ContentCatalog.cachedSummaries(language).orEmpty()
    }
    var cards by remember(language) { mutableStateOf(cached) }
    var catalogReady by remember(language) { mutableStateOf(cached.isNotEmpty()) }
    var showExplain by remember { mutableStateOf(false) }
    var index by remember(language) { mutableIntStateOf(0) }

    LaunchedEffect(language) {
        if (cards.isEmpty()) {
            cards = ContentCatalog.summariesAsync(context.applicationContext, language).shuffled()
        } else if (cards === cached && cached.isNotEmpty()) {
            cards = cached.shuffled()
        }
        catalogReady = true
        if (!DeviceCapabilities.isEmulator() && !app.tutorialFlags.seen(TutorialFlags.Id.HOME_SWIPE)) {
            delay(900)
            showExplain = true
        }
    }

    // Covers are the first thing the feed shows, so they are warmed with no debounce:
    // the current card plus the next two, which is what a swipe can reach immediately.
    LaunchedEffect(cards, index) {
        if (cards.isEmpty()) return@LaunchedEffect
        val window = (index..index + COVER_PREFETCH_AHEAD).mapNotNull { cards.getOrNull(it)?.id }
        CourseImagePrefetch.warmCovers(context.applicationContext, window)
    }

    // Give the reader a head start on the card being read. The delay is the debounce:
    // it is cancelled on every swipe, so flicking through the feed costs nothing.
    LaunchedEffect(cards, index) {
        val courseId = cards.getOrNull(index)?.id ?: return@LaunchedEffect
        delay(400)
        CourseImagePrefetch.warmCourse(context.applicationContext, language, courseId)
    }

    LaunchedEffect(autoSwipeCourseId, cards) {
        val id = autoSwipeCourseId ?: return@LaunchedEffect
        val found = cards.indexOfFirst { it.id == id }
        if (found >= 0 && found + 1 < cards.size) {
            index = found + 1
            onUserSwipe()
        }
        onAutoSwipeConsumed()
    }

    Box(modifier = modifier.fillMaxSize()) {
        Column(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = DS.Space.l, vertical = DS.Space.s),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = "Sophia",
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 22.sp,
                    color = DS.ink,
                )
                Row(
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(DS.surface)
                        .padding(horizontal = 14.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    Icon(
                        Icons.Filled.LocalFireDepartment,
                        contentDescription = null,
                        tint = DS.warm,
                        modifier = Modifier.size(18.dp),
                    )
                    Text(
                        text = "$streak",
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 15.sp,
                        color = DS.ink,
                    )
                    Text(
                        text = StringStore.text(
                            context,
                            if (streak <= 1) "common.streak.day" else "common.streak.days",
                            language,
                        ),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Medium,
                        fontSize = 12.sp,
                        color = DS.inkSecondary,
                        maxLines = 1,
                    )
                }
            }

            if (!catalogReady) {
                Box(modifier = Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = DS.accent)
                }
            } else if (cards.isEmpty()) {
                Box(modifier = Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
                    Text(
                        text = StringStore.text(context, "home.allCaughtUp", language)
                            .takeIf { it != "home.allCaughtUp" }
                            ?: "Tous les cours sont faits — bravo !",
                        fontFamily = PlusJakartaSans,
                        color = DS.ink,
                    )
                }
            } else {
                VerticalSnapFeed(
                    itemCount = cards.size,
                    index = index,
                    onIndexChange = { next ->
                        if (next != index) {
                            index = next
                            onUserSwipe()
                        }
                    },
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .padding(bottom = 8.dp)
                        // The incoming card is drawn at a vertical offset; without this it
                        // slides over the "Sophia" header and the streak badge.
                        .clipToBounds(),
                ) { page ->
                    val course = cards[page]
                    TikTokCourseCard(
                        course = course,
                        language = language,
                        isFavorite = course.id in favoriteIds,
                        onToggleFavorite = { onToggleFavorite(course.id) },
                        onShare = { ShareHelper.shareCourse(context, course.id, course.title) },
                        onStart = { onStartCourse(course.id) },
                    )
                }
            }
        }
        if (showExplain && catalogReady && cards.isNotEmpty()) {
            FirstOpenExplanation(
                language = language,
                icon = "👆",
                titleKey = "explain.home.title",
                bodyKey = "explain.home.body",
                onDismiss = {
                    app.tutorialFlags.markSeen(TutorialFlags.Id.HOME_SWIPE)
                    showExplain = false
                },
            )
        }
    }
}

@Composable
private fun VerticalSnapFeed(
    itemCount: Int,
    index: Int,
    onIndexChange: (Int) -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable (Int) -> Unit,
) {
    val scope = rememberCoroutineScope()
    val indexState = rememberUpdatedState(index)
    val countState = rememberUpdatedState(itemCount)
    val changeState = rememberUpdatedState(onIndexChange)
    var drag by remember { mutableFloatStateOf(0f) }
    val anim = remember { Animatable(0f) }
    var settling by remember { mutableStateOf(false) }
    var heightPx by remember { mutableFloatStateOf(0f) }
    val y = if (settling) anim.value else drag

    Box(
        modifier = modifier
            .onSizeChanged { heightPx = it.height.toFloat() }
            .pointerInput(heightPx) {
                if (heightPx <= 0f) return@pointerInput
                detectVerticalDragGestures(
                    onDragStart = {
                        if (settling) {
                            settling = false
                            drag = anim.value
                            scope.launch { anim.stop() }
                        }
                    },
                    onVerticalDrag = { _, dy ->
                        val i = indexState.value
                        val count = countState.value
                        if (count <= 1) return@detectVerticalDragGestures
                        val min = if (i < count - 1) -heightPx else 0f
                        val max = if (i > 0) heightPx else 0f
                        drag = (drag + dy).coerceIn(min, max)
                    },
                    onDragCancel = {
                        scope.launch {
                            settling = true
                            anim.snapTo(drag)
                            anim.animateTo(0f, spring())
                            drag = 0f
                            settling = false
                        }
                    },
                    onDragEnd = {
                        val i = indexState.value
                        val count = countState.value
                        val threshold = heightPx * 0.18f
                        val value = drag
                        scope.launch {
                            settling = true
                            anim.snapTo(value)
                            when {
                                value < -threshold && i < count - 1 -> {
                                    changeState.value(i + 1)
                                    anim.snapTo(value + heightPx)
                                    drag = 0f
                                    anim.animateTo(0f, spring())
                                }
                                value > threshold && i > 0 -> {
                                    changeState.value(i - 1)
                                    anim.snapTo(value - heightPx)
                                    drag = 0f
                                    anim.animateTo(0f, spring())
                                }
                                else -> {
                                    anim.animateTo(0f, spring())
                                }
                            }
                            drag = 0f
                            settling = false
                        }
                    },
                )
            },
    ) {
        val incoming = when {
            y < 0f && index < itemCount - 1 -> index + 1
            y > 0f && index > 0 -> index - 1
            else -> null
        }
        if (incoming != null && heightPx > 0f) {
            val incomingY = if (y < 0f) heightPx + y else -heightPx + y
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .offset { IntOffset(0, incomingY.roundToInt()) },
            ) {
                content(incoming)
            }
        }
        Box(
            modifier = Modifier
                .fillMaxSize()
                .offset { IntOffset(0, y.roundToInt()) },
        ) {
            content(index)
        }
    }
}

@Composable
private fun TikTokCourseCard(
    course: CourseSummary,
    language: AppLanguage,
    isFavorite: Boolean,
    onToggleFavorite: () -> Unit,
    onShare: () -> Unit,
    onStart: () -> Unit,
) {
    val context = LocalContext.current
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = DS.Space.m, vertical = DS.Space.s)
            .sophiaCard(elevation = 10.dp)
            .padding(DS.Space.l),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f)
                .clip(DS.controlShape)
                .background(DS.surfaceMuted)
                .border(1.dp, DS.hairline, DS.controlShape),
        ) {
            CourseImage(
                courseId = course.id,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop,
            )
            Row(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(12.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                CircleIconButton(
                    icon = Icons.Filled.Share,
                    onClick = onShare,
                    size = 38.dp,
                )
                CircleIconButton(
                    icon = if (isFavorite) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder,
                    onClick = onToggleFavorite,
                    size = 38.dp,
                    tint = if (isFavorite) DS.accent else DS.inkSecondary,
                )
            }
        }

        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Pill(
                text = StringStore.text(
                    context,
                    "subject.${course.subjectEnum.storageKey}.short",
                    language,
                ),
                uppercase = true,
                borderColor = DS.accentSoft.copy(alpha = 0.2f),
            )
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(5.dp),
            ) {
                Icon(
                    Icons.Filled.Visibility,
                    contentDescription = null,
                    tint = DS.inkTertiary,
                    modifier = Modifier.size(13.dp),
                )
                Text(
                    text = readsCountShort(course.id),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 11.sp,
                    color = DS.inkTertiary,
                )
            }
        }

        Text(
            text = course.title,
            style = SophiaTypography.titleMedium.copy(fontSize = 21.sp, lineHeight = 27.sp),
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            text = course.description,
            style = SophiaTypography.bodyMedium.copy(lineHeight = 21.sp),
            maxLines = 4,
            overflow = TextOverflow.Ellipsis,
        )
        SophiaPrimaryButton(
            text = StringStore.text(context, "home.start", language)
                .takeIf { it != "home.start" } ?: "Commencer",
            onClick = onStart,
            leadingIcon = Icons.Filled.PlayArrow,
        )
    }
}

private const val COVER_PREFETCH_AHEAD = 2

private fun readsCountShort(id: String): String {
    var hash = 0xcbf29ce484222325UL
    for (byte in id.encodeToByteArray()) {
        hash = hash xor byte.toULong()
        hash *= 0x100000001b3UL
    }
    val count = 7_000 + (hash % 243_000UL).toInt()
    val rounded = (count / 100) * 100
    return if (rounded < 10_000) {
        String.format("%.1f k", rounded / 1000.0).replace('.', ',')
    } else {
        "${rounded / 1000} k"
    }
}
