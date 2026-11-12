package app.rork.sophia.ui.path

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.Crossfade
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.outlined.EmojiEvents
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.LockOpen
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.PathMeasure
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawOutline
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.stripInlineMarkup
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.PathLevel
import app.rork.sophia.domain.PathNodeState
import app.rork.sophia.domain.uppercaseIn
import app.rork.sophia.ui.collections.CollectionCover
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.components.DSCheckBadge
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlinx.coroutines.delay

// The « zigzag of cards » trail of the Parcours tab: every course of a level is a card with
// its cover, alternately at the start and at the end of the row, joined to the next one by a
// dotted curve. The level closes on a quiz pill, and the levels still locked fold into a
// compact card. Twin of the iOS `PathCardViews.swift`. The pods of the previous trail live
// on in `PathNodeViews.kt` for the onboarding preview.

// MARK: - Layout

/**
 * Geometry of the card trail, same numbers as iOS. The connector is anchored on the bottom
 * of its own row, so the cards can be as tall as their title needs.
 */
internal object PathCardLayout {
    val cardWidth = 186.dp

    /** The course to read now is drawn wider. */
    val currentCardWidth = 214.dp
    val coverHeight = 78.dp
    val currentCoverHeight = 110.dp
    val rowSpacing = 14.dp
    val sideInset = 24.dp

    /** Past this width the cards would drift apart and the connector no longer reach. */
    val maxTrailWidth = 420.dp
    val maxSectionWidth = 520.dp
    val quizPillWidth = 230.dp
    val bannerHeight = 120.dp

    /** Between a level's header and its first card. */
    val headerSpacing = 16.dp

    /** Box of the dotted curve, hung under the card it starts from. */
    val connectorWidth = 120.dp

    /** The last course only has to reach the quiz pill, in the middle. */
    val quizConnectorWidth = 56.dp
    val connectorHeight = 60.dp

    /** How far the box hangs below the bottom edge of its row. */
    val connectorDrop = 34.dp

    /** Distance from the card's outer edge to where the curve starts. */
    val connectorStartX = 150.dp

    /** Courses alternate sides, the first one at the start of the row. */
    fun isLeading(index: Int): Boolean = index % 2 == 0
}

// MARK: - Palette

/** Colours of the trail that carry a meaning of their own (done, not reached yet, reward). */
internal object PathCardPalette {
    /** Bright green of what is behind the reader: check badge, travelled dots. */
    val done = Color(0xFF3FBF8F)

    /** Dots not travelled yet, dashed outline of the quiz to come. */
    val trailIdle = Color(0xFFC3CBD8)

    /** Cover of a course still locked. */
    val lockedCover = Color(0xFFEEF0F3)

    /** Night-blue veil over a level's cover, so its title reads on any artwork. */
    val bannerVeil = Color(0xFF0D182D)

    /** Pale gold behind a trophy or a reward chip. */
    val goldTint = Color(0xFFFBEFC9)

    /** Text on pale gold. */
    val goldInk = Color(0xFF6B4E00)
}

// MARK: - Surfaces

/**
 * The card of the style with a border of its own colour (blue around the course to read):
 * white, 16 dp corners, a 1.5 dp border and the slightly thicker bottom edge. The colour
 * change is animated.
 */
@Composable
internal fun Modifier.pathCardSurface(border: Color, shape: Shape = DS.cardShape): Modifier {
    val edge by animateColorAsState(border, DSMotion.snappy(), label = "pathCardBorder")
    return this
        .drawBehind {
            val outline = shape.createOutline(size, layoutDirection, this)
            translate(top = 1.5.dp.toPx()) { drawOutline(outline, edge) }
        }
        .clip(shape)
        .background(DS.surface)
        .border(1.5.dp, edge, shape)
}

/** A white rounded box under a dashed outline: something that is not there yet. */
private fun Modifier.pathDashedOutline(color: Color, radius: Dp = DS.Radius.card): Modifier = this
    .background(DS.surface, RoundedCornerShape(radius))
    .drawBehind {
        val stroke = 1.5.dp.toPx()
        drawRoundRect(
            color = color,
            topLeft = Offset(stroke / 2f, stroke / 2f),
            size = Size(size.width - stroke, size.height - stroke),
            cornerRadius = CornerRadius(radius.toPx() - stroke / 2f),
            style = Stroke(
                width = stroke,
                pathEffect = PathEffect.dashPathEffect(floatArrayOf(5.dp.toPx(), 4.dp.toPx())),
            ),
        )
    }

// MARK: - Padlock

/** A padlock that swings open (and turns blue) when [isOpen] flips. */
@Composable
internal fun PathLockGlyph(
    isOpen: Boolean,
    modifier: Modifier = Modifier,
    size: Dp = 20.dp,
    color: Color = DS.inkTertiary,
) {
    val scale by animateFloatAsState(if (isOpen) 1.18f else 1f, DSMotion.pop(), label = "lockScale")
    Crossfade(
        targetState = isOpen,
        animationSpec = tween(160),
        modifier = modifier
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            }
            .clearAndSetSemantics { },
        label = "lockGlyph",
    ) { open ->
        Icon(
            imageVector = if (open) Icons.Outlined.LockOpen else Icons.Outlined.Lock,
            contentDescription = null,
            tint = if (open) DS.accent else color,
            modifier = Modifier.size(size),
        )
    }
}

// MARK: - Course card

/**
 * One course of a level: its cover, « COURS n » and its title. Checked in green once read,
 * wider and ringed in blue with its button while it is the one to read, grey under a
 * padlock while locked. [isUnlocking]: the padlock is opening, just before the card is
 * uncovered.
 */
@Composable
internal fun PathCourseCard(
    course: CourseSummary,
    /** Rank of the course in its level, from 1. */
    number: Int,
    state: PathNodeState,
    isCurrent: Boolean,
    language: AppLanguage,
    modifier: Modifier = Modifier,
    isUnlocking: Boolean = false,
) {
    val context = LocalContext.current
    val width by animateDpAsState(
        if (isCurrent) PathCardLayout.currentCardWidth else PathCardLayout.cardWidth,
        DSMotion.snappy(),
        label = "pathCardWidth",
    )
    val coverHeight by animateDpAsState(
        if (isCurrent) PathCardLayout.currentCoverHeight else PathCardLayout.coverHeight,
        DSMotion.snappy(),
        label = "pathCoverHeight",
    )
    val eyebrow = remember(number, language) {
        StringStore.text(context, "elevatePath.course.number", language, number).uppercaseIn(language)
    }
    val eyebrowColor by animateColorAsState(
        when (state) {
            PathNodeState.COMPLETED -> DS.success
            PathNodeState.AVAILABLE -> DS.accent
            PathNodeState.LOCKED -> DS.inkTertiary
        },
        tween(350),
        label = "pathEyebrow",
    )
    val title = remember(course.title) { stripInlineMarkup(course.title) }

    Column(
        modifier = modifier
            .width(width)
            .pathCardSurface(if (isCurrent) DS.accent else DS.hairline),
    ) {
        Box(modifier = Modifier.fillMaxWidth().height(coverHeight)) {
            Crossfade(
                targetState = state == PathNodeState.LOCKED,
                animationSpec = tween(350),
                label = "pathCover",
            ) { locked ->
                if (locked) {
                    Box(
                        modifier = Modifier.fillMaxSize().background(PathCardPalette.lockedCover),
                        contentAlignment = Alignment.Center,
                    ) {
                        PathLockGlyph(isOpen = isUnlocking, size = 22.dp)
                    }
                } else {
                    CourseImage(
                        courseId = course.id,
                        modifier = Modifier.fillMaxSize(),
                        maxEdgePx = 480,
                        letterSize = 26.sp,
                    )
                }
            }
            // Named in full: inside this Box, the bare call would resolve to the Column's variant.
            androidx.compose.animation.AnimatedVisibility(
                visible = state == PathNodeState.COMPLETED,
                modifier = Modifier.align(Alignment.TopEnd).padding(8.dp),
                enter = scaleIn(DSMotion.pop(), initialScale = 0.4f) + fadeIn(),
                exit = scaleOut() + fadeOut(),
            ) {
                PathDoneBadge()
            }
            androidx.compose.animation.AnimatedVisibility(
                visible = isCurrent,
                modifier = Modifier.align(Alignment.TopStart).padding(8.dp),
                enter = scaleIn(DSMotion.snappy(), initialScale = 0.8f, transformOrigin = TransformOrigin(0f, 0f)) + fadeIn(),
                exit = fadeOut(),
            ) {
                Text(
                    text = StringStore.text(context, "elevatePath.course.readNow", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 11.sp,
                    color = DS.accent,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier
                        .clip(RoundedCornerShape(10.dp))
                        .background(DS.surface)
                        .padding(horizontal = 10.dp, vertical = 4.dp),
                )
            }
        }
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(start = 11.dp, end = 11.dp, top = 9.dp, bottom = 11.dp),
            verticalArrangement = Arrangement.spacedBy(3.dp),
        ) {
            Text(
                text = eyebrow,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 11.sp,
                letterSpacing = 0.8.sp,
                color = eyebrowColor,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                text = title,
                fontFamily = PlusJakartaSans,
                fontWeight = if (isCurrent) FontWeight.Bold else FontWeight.SemiBold,
                fontSize = if (isCurrent) 15.sp else 13.sp,
                lineHeight = if (isCurrent) 19.5.sp else 17.sp,
                color = if (state == PathNodeState.LOCKED) DS.inkTertiary else DS.ink,
                maxLines = 4,
                overflow = TextOverflow.Ellipsis,
            )
            AnimatedVisibility(
                visible = isCurrent,
                enter = fadeIn() + expandVertically(),
                exit = fadeOut() + shrinkVertically(),
            ) {
                PathStartLabel(
                    text = StringStore.text(context, "home.start", language),
                    modifier = Modifier.padding(top = 6.dp),
                )
            }
        }
    }
}

/** The green check of a course read, ringed in white so it reads on any cover. */
@Composable
private fun PathDoneBadge() {
    Box(
        modifier = Modifier.size(26.dp).clip(CircleShape).background(Color.White),
        contentAlignment = Alignment.Center,
    ) {
        DSCheckBadge(size = 22.dp, fill = PathCardPalette.done)
    }
}

/**
 * The blue « Commencer » bar at the foot of the card to play. It is drawn, not a button of
 * its own: the whole card is the button.
 */
@Composable
internal fun PathStartLabel(text: String, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(40.dp)
            .clip(RoundedCornerShape(DS.Radius.small))
            .background(DS.accent)
            .padding(horizontal = 8.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 14.sp,
            color = Color.White,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

// MARK: - Quiz pill

/**
 * The quiz that closes a level: a dashed outline while its courses are not all read, a card
 * with its « Commencer » bar once it can be taken, checked once passed. [isUnlocking]: the
 * quiz is about to open, its dashed outline lights up before it turns into a card.
 */
@Composable
internal fun PathQuizPill(
    state: PathNodeState,
    isCurrent: Boolean,
    courseCount: Int,
    completedCourseCount: Int,
    language: AppLanguage,
    modifier: Modifier = Modifier,
    isUnlocking: Boolean = false,
) {
    val context = LocalContext.current
    val locked = state == PathNodeState.LOCKED
    val subtitle = when (state) {
        PathNodeState.LOCKED ->
            if (courseCount > 1) {
                StringStore.text(context, "elevatePath.quiz.afterCourses", language, courseCount)
            } else {
                StringStore.text(context, "path.status.locked", language)
            }
        PathNodeState.AVAILABLE ->
            StringStore.text(context, "path.courses.count", language, completedCourseCount, courseCount)
        PathNodeState.COMPLETED -> StringStore.text(context, "path.status.passed", language)
    }
    val subtitleColor = when (state) {
        PathNodeState.LOCKED -> DS.inkTertiary
        PathNodeState.AVAILABLE -> DS.inkSecondary
        PathNodeState.COMPLETED -> DS.success
    }
    val dashColor by animateColorAsState(
        if (isUnlocking) DS.accent else PathCardPalette.trailIdle,
        DSMotion.snappy(),
        label = "pathQuizDash",
    )

    Column(
        modifier = modifier
            .width(PathCardLayout.quizPillWidth)
            .then(
                if (locked) {
                    Modifier.pathDashedOutline(dashColor)
                } else {
                    Modifier.pathCardSurface(if (isCurrent) DS.accent else DS.hairline)
                },
            )
            .padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Crossfade(targetState = locked, animationSpec = tween(350), label = "pathQuizIcon") { isLocked ->
                Box(
                    modifier = Modifier
                        .size(34.dp)
                        .then(if (isLocked) Modifier else Modifier.clip(CircleShape).background(PathPalette.gold)),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        imageVector = if (isLocked) Icons.Outlined.EmojiEvents else Icons.Filled.EmojiEvents,
                        contentDescription = null,
                        tint = when {
                            !isLocked -> Color.White
                            isUnlocking -> DS.accent
                            else -> DS.inkTertiary
                        },
                        modifier = Modifier.size(if (isLocked) 22.dp else 17.dp),
                    )
                }
            }
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(
                    text = StringStore.text(context, "path.quizPod", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp,
                    color = if (locked) DS.inkSecondary else DS.ink,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Text(
                    text = subtitle,
                    fontFamily = PlusJakartaSans,
                    fontSize = 12.sp,
                    lineHeight = 16.sp,
                    color = subtitleColor,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            AnimatedVisibility(
                visible = state == PathNodeState.COMPLETED,
                enter = scaleIn(DSMotion.pop(), initialScale = 0.4f) + fadeIn(),
                exit = scaleOut() + fadeOut(),
            ) {
                DSCheckBadge(size = 24.dp, fill = PathCardPalette.done)
            }
        }
        AnimatedVisibility(
            visible = isCurrent,
            enter = fadeIn() + expandVertically(),
            exit = fadeOut() + shrinkVertically(),
        ) {
            PathStartLabel(text = StringStore.text(context, "home.start", language))
        }
    }
}

// MARK: - Locked level

/**
 * A level still locked, folded into one row: greyed cover, « NIVEAU n », its title and the
 * padlock, which rattles on a tap ([lockShakes] goes up by one per rattle) and swings open
 * when the level is won ([isOpening]).
 */
@Composable
internal fun PathLockedLevelCard(
    level: PathLevel,
    language: AppLanguage,
    lockShakes: () -> Float,
    modifier: Modifier = Modifier,
    isOpening: Boolean = false,
) {
    val context = LocalContext.current
    val caption = remember(level.number, level.completedCourseCount, level.courseCount, language) {
        val levelText = StringStore.text(context, "path.levelCaption", language, level.number)
        val coursesText = StringStore.text(
            context, "path.courses.count", language, level.completedCourseCount, level.courseCount,
        )
        "$levelText · $coursesText".uppercaseIn(language)
    }
    Row(
        modifier = modifier
            .fillMaxWidth()
            .sophiaCard()
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        CollectionCover(
            collection = level.collection,
            accentIndex = level.number - 1,
            modifier = Modifier
                .size(48.dp)
                .graphicsLayer { alpha = 0.6f }
                .clip(RoundedCornerShape(DS.Radius.small))
                .pathSaturation(0f)
                .clearAndSetSemantics { },
        )
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                text = caption,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 11.sp,
                letterSpacing = 1.sp,
                color = DS.inkTertiary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                text = level.collection.title,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 15.sp,
                lineHeight = 20.sp,
                color = DS.inkSecondary,
                textAlign = TextAlign.Start,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
        Box(
            modifier = Modifier
                .size(24.dp)
                .graphicsLayer { translationX = shakeOffset(lockShakes(), 5.dp.toPx()) },
            contentAlignment = Alignment.Center,
        ) {
            PathLockGlyph(isOpen = isOpening, size = 18.dp)
        }
    }
}

// MARK: - Breathing halo

/**
 * A soft blue glow breathing behind the card to play. Drawn behind the content, a little
 * larger than it; its transparency is painted rather than layered, so nothing clips it.
 * The system's animator scale (« Remove animations ») stills it.
 */
@Composable
internal fun Modifier.pathCardHalo(visible: Boolean, cornerRadius: Dp = DS.Radius.card + 5.dp): Modifier {
    val presence by animateFloatAsState(if (visible) 1f else 0f, tween(300), label = "haloPresence")
    if (!visible && presence <= 0f) return this
    val breath = rememberInfiniteTransition(label = "cardHalo")
    val expanded = breath.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(1500, easing = FastOutSlowInEasing), RepeatMode.Reverse),
        label = "haloExpanded",
    )
    val tint = DS.accent
    return drawBehind {
        val phase = expanded.value
        val grow = 5.dp.toPx()
        val scale = 0.99f + 0.03f * phase
        val width = (size.width + grow * 2f) * scale
        val height = (size.height + grow * 2f) * scale
        drawRoundRect(
            color = tint.copy(alpha = 0.16f * (1f - 0.7f * phase) * presence),
            topLeft = Offset((size.width - width) / 2f, (size.height - height) / 2f),
            size = Size(width, height),
            cornerRadius = CornerRadius(cornerRadius.toPx()),
        )
    }
}

// MARK: - Dotted connector

/**
 * The dotted lying-S curve from a row down to the next one, drawn behind the row in the box
 * hung under its card (only the middle stretch of the curve is kept: both ends would sit
 * under the cards anyway). The grey dots trace themselves when the row comes in, after
 * [appearDelayMillis]; the green ones follow [fill] (0 to 1), which the page animates when
 * a course has just been finished.
 *
 * [fromStart] is true when the curve leaves a card at the start of the row towards one at
 * its end; right-to-left languages mirror it.
 */
@Composable
internal fun Modifier.pathDottedConnector(
    fromStart: Boolean,
    fill: () -> Float,
    width: Dp = PathCardLayout.connectorWidth,
    appearDelayMillis: Int = 0,
    /** False draws the dots at once (a row the reader has already seen come in). */
    animated: Boolean = true,
): Modifier {
    val drawn = remember { Animatable(if (animated) 0f else 1f) }
    LaunchedEffect(Unit) {
        if (drawn.value >= 1f) return@LaunchedEffect
        delay(appearDelayMillis.toLong())
        drawn.animateTo(1f, tween(550, easing = LinearOutSlowInEasing))
    }
    val idle = PathCardPalette.trailIdle
    val done = PathCardPalette.done
    return drawBehind {
        val progress = drawn.value
        if (progress <= 0f) return@drawBehind
        val fromLeft = fromStart == (layoutDirection == LayoutDirection.Ltr)
        val boxWidth = width.toPx()
        val boxHeight = PathCardLayout.connectorHeight.toPx()
        val top = size.height + PathCardLayout.connectorDrop.toPx() - boxHeight
        val left = if (fromLeft) {
            PathCardLayout.connectorStartX.toPx()
        } else {
            size.width - PathCardLayout.connectorStartX.toPx() - boxWidth
        }
        val startX = if (fromLeft) left else left + boxWidth
        val endX = if (fromLeft) left + boxWidth else left
        val midX = left + boxWidth / 2f
        val startY = top + boxHeight / 6f
        val endY = top + boxHeight - boxHeight / 6f
        val curve = Path().apply {
            moveTo(startX, startY)
            cubicTo(midX, startY, midX, endY, endX, endY)
        }
        val measure = PathMeasure().apply { setPath(curve, false) }
        val from = measure.length * 0.2f
        val span = measure.length * 0.6f
        val dots = Stroke(
            width = 3.dp.toPx(),
            cap = StrokeCap.Round,
            pathEffect = PathEffect.dashPathEffect(floatArrayOf(1.dp.toPx(), 9.dp.toPx())),
        )
        val base = Path()
        measure.getSegment(from, from + span * progress, base, true)
        drawPath(base, idle, style = dots)
        val travelled = fill().coerceIn(0f, 1f) * progress
        if (travelled > 0f) {
            val green = Path()
            measure.getSegment(from, from + span * travelled, green, true)
            drawPath(green, done, style = dots)
        }
    }
}
