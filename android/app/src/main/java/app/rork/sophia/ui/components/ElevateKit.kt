package app.rork.sophia.ui.components

import android.os.Build
import android.view.HapticFeedbackConstants
import android.view.View
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FiniteAnimationSpec
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathMeasure
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawOutline
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.uppercaseInApp
import kotlinx.coroutines.delay
import kotlin.math.PI
import kotlin.math.roundToInt
import kotlin.math.sin

/**
 * Shared pieces of the « Elevate arrondi » design, the Android twin of the iOS
 * `ElevateKit.swift`: haptics, presses, option cards, progress bars, highlighted titles and
 * the small reward animations. Every redesigned screen draws from here, so the app has one
 * family of springs ([DSMotion]) and one haptic vocabulary ([Haptics]).
 */

// region Motion

/** The springs of the app: presses, state changes, reveals and rewards share one feel. */
object DSMotion {
    /** A button or a card going down under the finger: quick, barely bouncy. */
    fun <T> press(): FiniteAnimationSpec<T> = spring(dampingRatio = 0.72f, stiffness = 600f)

    /** A state change (selection, tab, toggle): brisk with a slight bounce. */
    fun <T> snappy(): FiniteAnimationSpec<T> = spring(dampingRatio = 0.74f, stiffness = 380f)

    /** A block of content arriving: wide and settled. */
    fun <T> reveal(): FiniteAnimationSpec<T> = spring(dampingRatio = 0.84f, stiffness = 140f)

    /** A reward (check, badge, score): a clear bounce. */
    fun <T> pop(): FiniteAnimationSpec<T> = spring(dampingRatio = 0.5f, stiffness = 260f)
}

// endregion

// region Haptics

/**
 * The haptic vocabulary of the app. One gesture, one sensation, always the same: [tap] for a
 * button, [select] for a choice, [success] / [error] for a verdict, [celebrate] for a reward.
 * [View.performHapticFeedback] already honours the system setting.
 */
@Stable
class Haptics(private val view: View?) {
    /** A press on a button or a card. */
    fun tap() = perform(HapticFeedbackConstants.VIRTUAL_KEY)

    /** A choice in a list, a tab, a toggle. */
    fun select() = perform(HapticFeedbackConstants.CLOCK_TICK)

    /** The main action went through (call to action). */
    fun confirm() = perform(
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) HapticFeedbackConstants.CONFIRM else HapticFeedbackConstants.VIRTUAL_KEY,
    )

    /** Something settles (a card, a chip, a step reached). */
    fun soft() = perform(HapticFeedbackConstants.KEYBOARD_TAP)

    /** A clear stop (threshold crossed, lock). */
    fun rigid() = perform(HapticFeedbackConstants.LONG_PRESS)

    /** Right answer, step passed. */
    fun success() = confirm()

    /** Wrong answer. */
    fun error() = perform(
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) HapticFeedbackConstants.REJECT else HapticFeedbackConstants.LONG_PRESS,
    )

    /** A warning (time almost up, blocked action). */
    fun warning() = perform(HapticFeedbackConstants.LONG_PRESS)

    /** A reward: success, then two firmer bumps, for course ends, badges and wins. */
    fun celebrate() {
        success()
        view?.postDelayed({ perform(HapticFeedbackConstants.LONG_PRESS) }, 120L)
        view?.postDelayed({ perform(HapticFeedbackConstants.VIRTUAL_KEY) }, 240L)
    }

    /** A small notch repeated while a counter rolls. */
    fun tick() = perform(HapticFeedbackConstants.CLOCK_TICK)

    private fun perform(constant: Int) {
        runCatching { view?.performHapticFeedback(constant) }
    }
}

@Composable
fun rememberHaptics(): Haptics {
    val view = LocalView.current
    return remember(view) { Haptics(view) }
}

// endregion

// region Press

/**
 * The elastic press of the design: the content sinks slightly on a spring and the phone ticks
 * when the finger goes down. For any clickable card or row that draws its own background.
 */
@Composable
fun Modifier.pressable(
    onClick: () -> Unit,
    enabled: Boolean = true,
    scaleDown: Float = 0.97f,
    haptic: Boolean = true,
): Modifier {
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val haptics = rememberHaptics()
    val scale by animateFloatAsState(
        targetValue = if (pressed) scaleDown else 1f,
        animationSpec = DSMotion.press(),
        label = "pressable",
    )
    LaunchedEffect(pressed) {
        if (pressed && haptic && enabled) haptics.tap()
    }
    return this
        .graphicsLayer {
            scaleX = scale
            scaleY = scale
            alpha = if (pressed) 0.94f else 1f
        }
        .clickable(
            interactionSource = interaction,
            indication = null,
            enabled = enabled,
            onClick = onClick,
        )
}

// endregion

// region Option cards

/** The look of a choice card (quiz answer, onboarding option…). */
enum class DSOptionState {
    Idle,
    Selected,
    Correct,
    Wrong,

    /** A choice set aside once the verdict is in. */
    Dimmed,
}

/**
 * Background of an option card: white and bordered at rest, tinted and bordered in the
 * colour of its state otherwise, with the small bottom edge of the style. Adds no padding.
 */
@Composable
fun Modifier.dsOptionCard(
    state: DSOptionState = DSOptionState.Idle,
    shape: Shape = DS.cardShape,
): Modifier {
    val fillTarget = when (state) {
        DSOptionState.Idle, DSOptionState.Dimmed -> DS.surface
        DSOptionState.Selected -> DS.accentTint
        DSOptionState.Correct -> DS.successTint
        DSOptionState.Wrong -> DS.dangerTint
    }
    val borderTarget = when (state) {
        DSOptionState.Idle -> DS.hairline
        DSOptionState.Dimmed -> DS.hairline.copy(alpha = 0.7f)
        DSOptionState.Selected -> DS.accent
        DSOptionState.Correct -> DS.success
        DSOptionState.Wrong -> DS.danger
    }
    val fill by animateColorAsState(fillTarget, DSMotion.snappy(), label = "optionFill")
    val edge by animateColorAsState(borderTarget, DSMotion.snappy(), label = "optionBorder")
    val dim by animateFloatAsState(if (state == DSOptionState.Dimmed) 0.6f else 1f, DSMotion.snappy(), label = "optionDim")
    val lip = 1.5.dp
    return this
        .graphicsLayer { alpha = dim }
        .drawBehind {
            val outline = shape.createOutline(size, layoutDirection, this)
            translate(top = lip.toPx()) { drawOutline(outline, edge) }
        }
        .clip(shape)
        .background(fill)
        .border(1.5.dp, edge, shape)
}

// endregion

// region Progress

/** A thin rounded progress bar, animated when its value changes. */
@Composable
fun DSProgressBar(
    value: Float,
    modifier: Modifier = Modifier,
    height: Dp = 5.dp,
    tint: Color = DS.accent,
    track: Color = DS.accentTint,
) {
    val fraction by animateFloatAsState(value.coerceIn(0f, 1f), DSMotion.reveal(), label = "progress")
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(height)
            .clip(CircleShape)
            .background(track),
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth(fraction.coerceIn(0f, 1f))
                .fillMaxHeight()
                .clip(CircleShape)
                .background(tint),
        )
    }
}

/** Progress in segments (question 2 of 8, course 2 of 5…). */
@Composable
fun DSSegmentedProgress(
    total: Int,
    filled: Int,
    modifier: Modifier = Modifier,
    height: Dp = 6.dp,
    spacing: Dp = 4.dp,
    tint: Color = DS.accent,
    track: Color = DS.hairline.copy(alpha = 0.75f),
) {
    Row(modifier = modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(spacing)) {
        repeat(total.coerceAtLeast(1)) { index ->
            val color by animateColorAsState(if (index < filled) tint else track, DSMotion.snappy(), label = "segment")
            Box(
                modifier = Modifier
                    .weight(1f)
                    .height(height)
                    .clip(CircleShape)
                    .background(color),
            )
        }
    }
}

// endregion

// region Titles

/** [text] with its `**marked**` passages in bold accent blue, the title style of the design. */
fun dsHighlighted(
    text: String,
    highlight: Color,
    highlightWeight: FontWeight = FontWeight.Bold,
): AnnotatedString = buildAnnotatedString {
    text.split("**").forEachIndexed { index, part ->
        if (part.isEmpty()) return@forEachIndexed
        if (index % 2 == 1) {
            withStyle(SpanStyle(color = highlight, fontWeight = highlightWeight)) { append(part) }
        } else {
            append(part)
        }
    }
}

/**
 * A title of the design: light weight, with the passages between `**` in bold blue
 * (« Comment définit-on un **trou noir** ? »).
 */
@Composable
fun DSHighlightTitle(
    text: String,
    modifier: Modifier = Modifier,
    fontSize: TextUnit = 24.sp,
    lineHeight: TextUnit = 31.sp,
    weight: FontWeight = FontWeight.Normal,
    highlightWeight: FontWeight = FontWeight.Bold,
    highlight: Color = DS.accent,
    textAlign: TextAlign = TextAlign.Center,
) {
    Text(
        text = dsHighlighted(text, highlight, highlightWeight),
        modifier = modifier,
        fontFamily = PlusJakartaSans,
        fontWeight = weight,
        fontSize = fontSize,
        lineHeight = lineHeight,
        color = DS.ink,
        textAlign = textAlign,
    )
}

/** A small rounded label (subject, « À lire maintenant », combo…). */
@Composable
fun DSChip(
    text: String,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    foreground: Color = DS.accent,
    background: Color = DS.accentTint,
) {
    Row(
        modifier = modifier
            .clip(CircleShape)
            .background(background)
            .padding(horizontal = 10.dp, vertical = 5.dp),
        horizontalArrangement = Arrangement.spacedBy(5.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (icon != null) {
            Icon(icon, contentDescription = null, tint = foreground, modifier = Modifier.size(13.dp))
        }
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 12.sp,
            color = foreground,
        )
    }
}

/** An eyebrow in tracked capitals (« SCIENCES · QUESTION 2 SUR 8 »). */
@Composable
fun DSEyebrow(text: String, modifier: Modifier = Modifier, color: Color = DS.accent) {
    Text(
        text = text.uppercaseInApp(),
        modifier = modifier,
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 11.sp,
        letterSpacing = 0.9.sp,
        color = color,
    )
}

// endregion

// region Reveals

/**
 * A cascade: item number [index] of a list rises and fades in after its predecessors.
 * Plays once per composition of the item.
 */
@Composable
fun Modifier.dsStagger(
    index: Int,
    stepMillis: Int = 60,
    baseMillis: Int = 50,
    offset: Dp = 14.dp,
): Modifier {
    var shown by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay((baseMillis + index.coerceAtLeast(0) * stepMillis).toLong())
        shown = true
    }
    val progress by animateFloatAsState(if (shown) 1f else 0f, DSMotion.reveal(), label = "stagger")
    val offsetPx = with(LocalDensity.current) { offset.toPx() }
    return this.graphicsLayer {
        alpha = progress.coerceIn(0f, 1f)
        translationY = (1f - progress) * offsetPx
        val scale = 0.97f + 0.03f * progress
        scaleX = scale
        scaleY = scale
    }
}

/** A bouncy « pop » entrance (check, badge, score chip). */
@Composable
fun Modifier.dsPopIn(delayMillis: Int = 0): Modifier {
    var shown by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(delayMillis.toLong())
        shown = true
    }
    val progress by animateFloatAsState(if (shown) 1f else 0f, DSMotion.pop(), label = "popIn")
    return this.graphicsLayer {
        alpha = progress.coerceIn(0f, 1f)
        val scale = 0.4f + 0.6f * progress
        scaleX = scale
        scaleY = scale
    }
}

/** A horizontal shake each time [trigger] changes (wrong answer, refused field). */
@Composable
fun Modifier.dsShake(trigger: Int, travel: Dp = 7.dp): Modifier {
    val phase = remember { Animatable(0f) }
    LaunchedEffect(trigger) {
        if (trigger == 0) return@LaunchedEffect
        phase.snapTo(0f)
        phase.animateTo(1f, tween(durationMillis = 380, easing = LinearEasing))
    }
    val travelPx = with(LocalDensity.current) { travel.toPx() }
    return this.graphicsLayer {
        translationX = travelPx * sin(phase.value * PI.toFloat() * 6f) * (1f - phase.value)
    }
}

// endregion

// region Check badge

/** A round badge whose check draws itself: the « right answer » verdict and finished steps. */
@Composable
fun DSCheckBadge(
    modifier: Modifier = Modifier,
    size: Dp = 26.dp,
    fill: Color = DS.success,
    delayMillis: Int = 0,
) {
    var drawn by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(delayMillis.toLong())
        drawn = true
    }
    val scale by animateFloatAsState(if (drawn) 1f else 0.5f, DSMotion.pop(), label = "checkScale")
    val stroke by animateFloatAsState(if (drawn) 1f else 0f, tween(durationMillis = 260, delayMillis = 60), label = "checkStroke")
    Canvas(
        modifier = modifier
            .size(size)
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            }
            .clearAndSetSemantics { },
    ) {
        drawCircle(fill)
        val inset = this.size.minDimension * 0.27f
        val w = this.size.width - inset * 2
        val h = this.size.height - inset * 2
        val full = Path().apply {
            moveTo(inset, inset + h * 0.55f)
            lineTo(inset + w * 0.36f, inset + h * 0.92f)
            lineTo(inset + w, inset + h * 0.12f)
        }
        val measure = PathMeasure().apply { setPath(full, false) }
        val partial = Path()
        measure.getSegment(0f, measure.length * stroke.coerceIn(0f, 1f), partial, true)
        drawPath(
            path = partial,
            color = Color.White,
            style = Stroke(
                width = (this.size.minDimension * 0.11f).coerceAtLeast(2.dp.toPx()),
                cap = StrokeCap.Round,
                join = StrokeJoin.Round,
            ),
        )
    }
}

// endregion

// region Streak flame

/**
 * The streak flame, gently swaying: a saffron body, a lighter core and a halo that breathes.
 * The system's animator scale (« Remove animations ») stills it.
 */
@Composable
fun DSFlame(
    modifier: Modifier = Modifier,
    size: Dp = 84.dp,
    color: Color = Color(0xFFE6B233),
    core: Color = Color(0xFFF7D774),
) {
    val transition = rememberInfiniteTransition(label = "flame")
    val sway by transition.animateFloat(
        initialValue = -1f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(1800), RepeatMode.Reverse),
        label = "flameSway",
    )
    val breathe by transition.animateFloat(
        initialValue = -1f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(1200), RepeatMode.Reverse),
        label = "flameBreathe",
    )
    Box(
        modifier = modifier
            .size(width = size * 1.32f, height = size * 1.2f)
            .clearAndSetSemantics { },
        contentAlignment = Alignment.BottomCenter,
    ) {
        Box(
            modifier = Modifier
                .size(size * 1.32f)
                .graphicsLayer {
                    val scale = 1f + 0.06f * breathe
                    scaleX = scale
                    scaleY = scale
                    alpha = 0.75f + 0.25f * breathe
                    translationY = size.toPx() * 0.12f
                }
                .background(
                    Brush.radialGradient(listOf(color.copy(alpha = 0.32f), color.copy(alpha = 0f))),
                    CircleShape,
                ),
        )
        Icon(
            imageVector = Icons.Filled.LocalFireDepartment,
            contentDescription = null,
            tint = color,
            modifier = Modifier
                .size(size)
                .graphicsLayer {
                    transformOrigin = TransformOrigin(0.5f, 1f)
                    scaleX = 1f - 0.02f * sway
                    scaleY = 1f + 0.035f * sway
                    rotationZ = 2f * sway
                },
        )
        Icon(
            imageVector = Icons.Filled.LocalFireDepartment,
            contentDescription = null,
            tint = core,
            modifier = Modifier
                .size(size * 0.46f)
                .graphicsLayer {
                    transformOrigin = TransformOrigin(0.5f, 1f)
                    scaleX = 1f - 0.08f * breathe
                    scaleY = 1f + 0.12f * breathe
                    alpha = 0.85f - 0.12f * breathe
                    translationY = -size.toPx() * 0.07f
                },
        )
    }
}

// endregion

// region Count up

/** A number that rolls up to its value (score, XP, trophies), with small haptic notches. */
@Composable
fun DSCountUp(
    value: Int,
    modifier: Modifier = Modifier,
    durationMillis: Int = 900,
    style: TextStyle = TextStyle(fontFamily = PlusJakartaSans, fontWeight = FontWeight.ExtraBold, fontSize = 34.sp),
    color: Color = DS.ink,
    prefix: String = "",
    suffix: String = "",
    haptics: Boolean = true,
) {
    var shown by remember { mutableIntStateOf(0) }
    val feedback = rememberHaptics()
    LaunchedEffect(value) {
        val start = shown
        val delta = value - start
        if (delta == 0) return@LaunchedEffect
        val steps = kotlin.math.abs(delta).coerceAtMost(24)
        for (step in 1..steps) {
            delay((durationMillis / steps).toLong())
            shown = start + (delta.toFloat() * step / steps).roundToInt()
            if (haptics && step % 3 == 0) feedback.tick()
        }
        shown = value
        if (haptics) feedback.soft()
    }
    Text(
        text = "$prefix$shown$suffix",
        modifier = modifier,
        style = style,
        color = color,
    )
}

// endregion
