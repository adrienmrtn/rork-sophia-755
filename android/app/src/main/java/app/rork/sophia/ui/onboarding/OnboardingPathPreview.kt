package app.rork.sophia.ui.onboarding

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.absoluteOffset
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.LearningCollection
import app.rork.sophia.ui.components.DSCheckBadge
import app.rork.sophia.ui.components.DSEyebrow
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.uppercaseInApp
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private enum class PreviewStep { Done, Current, Locked }

// Geometry of the mock-up, in a 310 × 322 frame.
private val PREVIEW_CANVAS_HEIGHT = 322.dp
private const val PREVIEW_REFERENCE_WIDTH = 310f
private val PREVIEW_CENTERS_Y = listOf(30.dp, 92.dp, 162.dp, 236.dp)
private val PREVIEW_LABEL_TOPS = listOf(65.dp, 127.dp, 205.dp, 271.dp)
private val PREVIEW_STEPS = listOf(PreviewStep.Done, PreviewStep.Done, PreviewStep.Current, PreviewStep.Locked)

/** Courses already done in the preview. */
private const val PREVIEW_DONE_COUNT = 2

/** Milliseconds between two courses landing. */
private const val PREVIEW_STAGGER = 280

// Colours of the illustration: green of the finished courses, grey of the closed ones.
private val PREVIEW_DONE_GREEN = Color(0xFF3FBF8F)
private val PREVIEW_DONE_INK = Color(0xFF2C8A66)
private val PREVIEW_LOCKED_LINE = Color(0xFFC3CBD8)
private val PREVIEW_LOCKED_BADGE = Color(0xFFEEF0F3)

/** What the card shows: the level, its size and its first courses. */
private class PreviewLevel(val title: String?, val courseCount: Int, val courses: List<CourseSummary>)

/**
 * The first level of the Parcours and its first four courses (the first collection with
 * four courses the language carries, else the first with any); the featured courses fill in
 * when the level has fewer. Null until both lists are in.
 */
private fun previewLevel(
    collections: List<LearningCollection>?,
    summaries: List<CourseSummary>?,
): PreviewLevel? {
    if (collections == null || summaries == null) return null
    val byId = summaries.associateBy { it.id }
    val collection = collections.firstOrNull { it.courseIds.size >= PREVIEW_STEPS.size }
        ?: collections.firstOrNull { it.courseIds.isNotEmpty() }
    val courses = collection?.courseIds.orEmpty().mapNotNull { byId[it] }.take(PREVIEW_STEPS.size).toMutableList()
    if (courses.size < PREVIEW_STEPS.size) {
        val known = courses.map { it.id }.toSet()
        val fill = OnboardingIntroCatalog.featuredCourseIds.mapNotNull { byId[it] }.filter { it.id !in known }
        courses += fill.take(PREVIEW_STEPS.size - courses.size)
    }
    if (courses.isEmpty()) return null
    return PreviewLevel(
        title = collection?.title,
        courseCount = maxOf(collection?.courseIds?.size ?: 0, courses.size),
        courses = courses,
    )
}

/**
 * Preview of the Parcours for the « personalized path » page of the carousel, as on iOS
 * (`OnboardingV2PathPreview`): the card of the first level, with its first four courses in
 * a zigzag joined by a dotted line — two courses done (green tick), the course to read
 * (blue border, « Start »), one still closed (greyed, padlock). The courses, their covers
 * and the name of the level come from the catalogue of the language.
 */
@Composable
internal fun OnboardingPathPreview(
    language: AppLanguage,
    /** Is the page showing the preview the current page of the carousel? */
    active: Boolean,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val reduceMotion = rememberOnboardingReduceMotion()
    var level by remember(language) {
        mutableStateOf(previewLevel(ContentCatalog.cachedCollections(language), ContentCatalog.cachedSummaries(language)))
    }
    LaunchedEffect(language) {
        if (level != null) return@LaunchedEffect
        level = runCatching {
            previewLevel(
                ContentCatalog.collectionsAsync(context.applicationContext, language),
                ContentCatalog.summariesAsync(context.applicationContext, language),
            )
        }.getOrNull()
    }

    // 0 → 1 per course, each with its own delay: the tile, its label and the line leaving it.
    val tiles = remember { List(PREVIEW_STEPS.size) { Animatable(if (reduceMotion) 1f else 0f) } }
    val links = remember { List(PREVIEW_STEPS.size - 1) { Animatable(if (reduceMotion) 1f else 0f) } }
    var badgesShown by remember { mutableStateOf(reduceMotion) }
    var pulsing by remember { mutableStateOf(false) }
    OnIntroPageActivated(active) {
        if (reduceMotion) return@OnIntroPageActivated
        badgesShown = true
        coroutineScope {
            tiles.forEachIndexed { index, tile ->
                launch {
                    delay(150L + index * PREVIEW_STAGGER)
                    haptics.tick()
                    // Une tuile se pose sans rebond.
                    tile.animateTo(1f, OV2Calm.settle())
                }
            }
            links.forEachIndexed { index, link ->
                launch {
                    delay(300L + index * PREVIEW_STAGGER)
                    link.animateTo(1f, tween(400))
                }
            }
            delay(400L + PREVIEW_STEPS.size * PREVIEW_STAGGER)
            pulsing = true
        }
    }

    val shown = level
    val courses = shown?.courses.orEmpty()
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(bottom = 2.dp)
            .ov2Card()
            .padding(16.dp)
            .clearAndSetSemantics { },
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        // Header of the card.
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            DSEyebrow(text = StringStore.text(context, "subject.level", language, 1))
            Text(
                text = shown?.title ?: StringStore.text(context, "path.title", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 13.sp,
                color = DS.ink,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f),
            )
            // No count until the level is known: « 2 / 0 courses » would be a false figure.
            if (shown != null) {
                Text(
                    text = StringStore.text(
                        context,
                        "path.courses.count",
                        language,
                        minOf(PREVIEW_DONE_COUNT, courses.size),
                        maxOf(shown.courseCount, courses.size),
                    ),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 12.sp,
                    color = DS.inkSecondary,
                    maxLines = 1,
                )
            }
        }

        // The zigzag. A drawing: even courses on the left, odd ones on the right, in every language.
        CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
            BoxWithConstraints(modifier = Modifier.fillMaxWidth().height(PREVIEW_CANVAS_HEIGHT)) {
                val width = maxWidth
                val labelWidth = minOf(140.dp, width * 0.46f)
                fun centerX(index: Int): Dp = width * ((if (index % 2 == 0) 72f else 238f) / PREVIEW_REFERENCE_WIDTH)
                fun centerY(index: Int): Dp = PREVIEW_CENTERS_Y[index % PREVIEW_CENTERS_Y.size]

                // The dotted line between a course and the next: green while the next is
                // reached, grey towards a closed course.
                Canvas(modifier = Modifier.fillMaxSize()) {
                    for (index in 0 until courses.size - 1) {
                        val drawn = links.getOrNull(index)?.value ?: 1f
                        if (drawn <= 0f) continue
                        val start = Offset(centerX(index).toPx(), centerY(index).toPx())
                        val end = Offset(centerX(index + 1).toPx(), centerY(index + 1).toPx())
                        val reachesLocked = PREVIEW_STEPS[minOf(index + 1, PREVIEW_STEPS.lastIndex)] == PreviewStep.Locked
                        drawLine(
                            color = if (reachesLocked) PREVIEW_LOCKED_LINE else PREVIEW_DONE_GREEN,
                            start = start,
                            end = start + (end - start) * drawn,
                            strokeWidth = 3.dp.toPx(),
                            cap = StrokeCap.Round,
                            pathEffect = PathEffect.dashPathEffect(floatArrayOf(0.5.dp.toPx(), 8.dp.toPx())),
                        )
                    }
                }

                courses.forEachIndexed { index, course ->
                    val step = PREVIEW_STEPS[minOf(index, PREVIEW_STEPS.lastIndex)]
                    val size = if (step == PreviewStep.Current) 76.dp else 60.dp
                    val reveal = tiles.getOrNull(index)
                    PreviewTile(
                        course = course,
                        step = step,
                        size = size,
                        pulsing = pulsing && step == PreviewStep.Current,
                        badgeShown = badgesShown,
                        badgeDelayMillis = if (reduceMotion) 0 else 350 + index * PREVIEW_STAGGER,
                        modifier = Modifier
                            .absoluteOffset(x = centerX(index) - size / 2, y = centerY(index) - size / 2)
                            .zIndex(1f)
                            .graphicsLayer {
                                // No offscreen buffer: the badge and the pulse overflow the tile.
                                compositingStrategy = CompositingStrategy.ModulateAlpha
                                val progress = reveal?.value ?: 1f
                                alpha = progress.coerceIn(0f, 1f)
                                val scale = 0.4f + 0.6f * progress
                                scaleX = scale
                                scaleY = scale
                            },
                    )
                    PreviewLabel(
                        index = index,
                        course = course,
                        step = step,
                        language = language,
                        modifier = Modifier
                            .absoluteOffset(
                                x = centerX(index) - labelWidth / 2,
                                y = PREVIEW_LABEL_TOPS[index % PREVIEW_LABEL_TOPS.size],
                            )
                            .width(labelWidth)
                            .graphicsLayer { alpha = (reveal?.value ?: 1f).coerceIn(0f, 1f) },
                    )
                }
            }
        }
    }
}

@Composable
private fun PreviewTile(
    course: CourseSummary,
    step: PreviewStep,
    size: Dp,
    pulsing: Boolean,
    badgeShown: Boolean,
    badgeDelayMillis: Int,
    modifier: Modifier = Modifier,
) {
    val shape = RoundedCornerShape(18.dp)
    val locked = step == PreviewStep.Locked
    val border = when (step) {
        PreviewStep.Done -> PREVIEW_DONE_GREEN
        PreviewStep.Current -> DS.accent
        PreviewStep.Locked -> DS.hairline
    }
    val accent = DS.accent
    // A ring that grows and fades around the course to read.
    // Read while drawing only: the tile is not recomposed on each frame of the pulse.
    val pulse = if (pulsing) {
        rememberInfiniteTransition(label = "pathPulse").animateFloat(
            initialValue = 0f,
            targetValue = 1f,
            animationSpec = infiniteRepeatable(tween(1500, easing = LinearOutSlowInEasing), RepeatMode.Restart),
            label = "pathPulseRing",
        )
    } else {
        null
    }
    Box(modifier = modifier.size(size)) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .drawBehind {
                    val ring = pulse?.value ?: return@drawBehind
                    val grow = this.size.width * 0.11f * ring
                    drawRoundRect(
                        color = accent.copy(alpha = 0.45f * (1f - ring)),
                        topLeft = Offset(-grow, -grow),
                        size = Size(this.size.width + grow * 2, this.size.height + grow * 2),
                        cornerRadius = CornerRadius(18.dp.toPx() + grow),
                        style = Stroke(width = 3.dp.toPx()),
                    )
                }
                .clip(shape)
                .background(DS.surface)
                .border(3.dp, border, shape),
        ) {
            OnboardingCover(
                courseId = course.id,
                modifier = Modifier.fillMaxSize(),
                placeholder = course.subjectEnum.color.copy(alpha = if (locked) 0.12f else 0.35f),
                edgePx = 240,
                colorFilter = if (locked) ColorFilter.colorMatrix(ColorMatrix().apply { setToSaturation(0f) }) else null,
                imageAlpha = if (locked) 0.4f else 1f,
            )
        }
        // Green tick of the finished course, padlock of the closed one; nothing on the course to read.
        if (badgeShown && step != PreviewStep.Current) {
            Box(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .absoluteOffset(x = 6.dp, y = (-6).dp)
                    .background(DS.surface, CircleShape)
                    .padding(2.dp),
                contentAlignment = Alignment.Center,
            ) {
                if (step == PreviewStep.Done) {
                    DSCheckBadge(size = 18.dp, fill = PREVIEW_DONE_GREEN, delayMillis = badgeDelayMillis)
                } else {
                    Box(
                        modifier = Modifier.size(18.dp).background(PREVIEW_LOCKED_BADGE, CircleShape),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(Icons.Filled.Lock, contentDescription = null, tint = DS.inkTertiary, modifier = Modifier.size(10.dp))
                    }
                }
            }
        }
    }
}

@Composable
private fun PreviewLabel(
    index: Int,
    course: CourseSummary,
    step: PreviewStep,
    language: AppLanguage,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val isCurrent = step == PreviewStep.Current
    // « COURSE 3 », followed by « UP NEXT » for the course of the day.
    val number = StringStore.text(context, "onboardingV2.elevate.path.course", language, index + 1)
    val eyebrow = if (isCurrent) {
        "$number · ${StringStore.text(context, "onboardingV2.elevate.path.toRead", language)}"
    } else {
        number
    }
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(1.dp),
    ) {
        Text(
            text = eyebrow.uppercaseInApp(),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 9.5.sp,
            lineHeight = 12.sp,
            letterSpacing = 0.8.sp,
            color = when (step) {
                PreviewStep.Done -> PREVIEW_DONE_INK
                PreviewStep.Current -> DS.accent
                PreviewStep.Locked -> DS.inkTertiary
            },
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            text = course.title,
            fontFamily = PlusJakartaSans,
            fontWeight = if (isCurrent) FontWeight.Bold else FontWeight.SemiBold,
            fontSize = if (isCurrent) 12.sp else 11.5.sp,
            lineHeight = 14.5.sp,
            color = if (step == PreviewStep.Locked) DS.inkTertiary else DS.ink,
            textAlign = TextAlign.Center,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
        if (isCurrent) {
            Text(
                text = StringStore.text(context, "home.start", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 11.5.sp,
                color = Color.White,
                maxLines = 1,
                modifier = Modifier
                    .padding(top = 3.dp)
                    .background(DS.accent, RoundedCornerShape(10.dp))
                    .padding(horizontal = 14.dp, vertical = 5.dp),
            )
        }
    }
}
