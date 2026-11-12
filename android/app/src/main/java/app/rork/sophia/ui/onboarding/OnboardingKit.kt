package app.rork.sophia.ui.onboarding

import android.content.Context
import android.os.Build
import android.os.SystemClock
import android.provider.Settings
import android.view.HapticFeedbackConstants
import android.view.View
import android.view.accessibility.AccessibilityManager
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.ScrollState
import androidx.compose.foundation.background
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.Stable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawOutline
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.isSpecified
import app.rork.sophia.data.CourseCoverUrls
import app.rork.sophia.ui.components.pressable
import coil.compose.AsyncImage
import coil.request.ImageRequest
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.DSPalette
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlinx.coroutines.delay

/**
 * Shared look and motion of the onboarding, ported from the iOS `OV2` kit: calm canvas,
 * navy ink, one blue accent, and reveals that land after the page transition instead of
 * fighting it.
 */
object OV2 {
    // The light tokens, pinned: the onboarding is light-only (see `ForceLightAppearance`),
    // and these are read once, whenever the object first loads.
    val bg = DSPalette.Light.canvas
    val ink = DSPalette.Light.ink
    val inkSecondary = DSPalette.Light.inkSecondary
    val inkTertiary = DSPalette.Light.inkTertiary
    val accent = DSPalette.Light.accent
    val accentSoft = DSPalette.Light.accentSoft
    val surface = DSPalette.Light.surface
    val hairline = DSPalette.Light.hairline
    val warm = Color(0xFFE6B233)
    val danger = Color(0xFFDB5A5C)
    val success = DSPalette.Light.success

    // Composable getters: the family is resolved from the composition, so a Russian, Greek
    // or Hebrew reader gets one consistent typeface rather than Jakarta punctuation around
    // system-fallback letters.
    val title: TextStyle
        @Composable @ReadOnlyComposable
        get() = ov2Style(FontWeight.SemiBold, 27.sp, 34.sp, DS.ink)

    val titleLarge: TextStyle
        @Composable @ReadOnlyComposable
        get() = ov2Style(FontWeight.SemiBold, 34.sp, 40.sp, DS.ink)

    val headline: TextStyle
        @Composable @ReadOnlyComposable
        get() = ov2Style(FontWeight.Bold, 17.sp, 23.sp, DS.ink)

    val body: TextStyle
        @Composable @ReadOnlyComposable
        get() = ov2Style(FontWeight.Medium, 16.sp, 23.sp, DS.inkSecondary)

    val subheadline: TextStyle
        @Composable @ReadOnlyComposable
        get() = ov2Style(FontWeight.Medium, 15.sp, 21.sp, DS.inkSecondary)

    val caption: TextStyle
        @Composable @ReadOnlyComposable
        get() = ov2Style(FontWeight.SemiBold, 13.sp, TextUnit.Unspecified, DS.inkSecondary)
}

@Composable
@ReadOnlyComposable
private fun ov2Style(
    weight: FontWeight,
    size: TextUnit,
    lineHeight: TextUnit,
    color: Color,
) = TextStyle(
    fontFamily = PlusJakartaSans,
    fontWeight = weight,
    fontSize = size,
    lineHeight = lineHeight,
    color = color,
)

object OV2Shapes {
    val card = androidx.compose.foundation.shape.RoundedCornerShape(DS.Radius.card)
    val control = androidx.compose.foundation.shape.RoundedCornerShape(DS.Radius.control)
}

/**
 * The onboarding leans on haptics the way iOS does: a tick per revealed item, a firmer
 * bump on a primary tap. [View.performHapticFeedback] already honours the system setting.
 */
@Stable
class OnboardingHaptics(private val view: View?) {
    fun selection() = perform(HapticFeedbackConstants.CLOCK_TICK)

    fun primary() {
        // The page change that follows must not vibrate a second time.
        OnboardingHapticGate.markConfirm()
        perform(
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                HapticFeedbackConstants.CONFIRM
            } else {
                HapticFeedbackConstants.VIRTUAL_KEY
            },
        )
    }

    fun commit() = perform(HapticFeedbackConstants.LONG_PRESS)

    private fun perform(constant: Int) {
        runCatching { view?.performHapticFeedback(constant) }
    }
}

/**
 * Keeps the page change from doubling the vibration of the button that caused it: the
 * coordinator asks [justConfirmed] before vibrating in its turn (iOS `OV2HapticGate`).
 */
internal object OnboardingHapticGate {
    @Volatile
    private var lastConfirmAt = 0L

    fun markConfirm() {
        lastConfirmAt = SystemClock.uptimeMillis()
    }

    /** True during the quarter of a second after a primary action vibrated. */
    val justConfirmed: Boolean
        get() = SystemClock.uptimeMillis() - lastConfirmAt < 250L
}

@Composable
fun rememberOnboardingHaptics(): OnboardingHaptics {
    val view = LocalView.current
    return remember(view) { OnboardingHaptics(view) }
}

/** Fade + lift that starts after [delayMillis], so it reads as a reveal, not a jump. */
@Composable
fun Modifier.ov2Reveal(delayMillis: Int = 120, yOffset: Dp = 16.dp): Modifier {
    var shown by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(delayMillis.toLong())
        shown = true
    }
    val progress by animateFloatAsState(
        targetValue = if (shown) 1f else 0f,
        animationSpec = spring(dampingRatio = 0.82f, stiffness = Spring.StiffnessMediumLow),
        label = "ov2Reveal",
    )
    val offsetPx = with(LocalDensity.current) { yOffset.toPx() }
    return this.graphicsLayer {
        alpha = progress
        translationY = (1f - progress) * offsetPx
    }
}

/**
 * The shape every full-page step should have: a scrolling body with the call to action
 * pinned below it, inside a column whose width is capped on a tablet.
 *
 * Two failures this replaces. A body laid out with `Spacer(weight(1f))` and no scroll simply
 * pushed the button off the bottom on a small phone at a large font scale — the user could
 * see the copy and had no way to continue, which ends the onboarding for them. And on a
 * tablet in landscape the same body stretched the full width, pushing the button hundreds of
 * points below the fold.
 *
 * [contentArrangement] is `Center` by default because most steps are a short block of copy
 * that should sit in the middle when there is room; a long step passes `Top`.
 */
@Composable
fun OnboardingPage(
    modifier: Modifier = Modifier,
    scrollState: ScrollState = rememberScrollState(),
    contentArrangement: Arrangement.Vertical = Arrangement.Center,
    footer: @Composable ColumnScope.() -> Unit,
    content: @Composable ColumnScope.() -> Unit,
) {
    Column(
        modifier = modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .readableWidth()
                .verticalScroll(scrollState),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = contentArrangement,
            content = content,
        )
        Column(
            modifier = Modifier.fillMaxWidth().readableWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            content = footer,
        )
    }
}

/**
 * Caps a column at a comfortable reading width and centres it.
 *
 * Sophia is published for iPad and for Android tablets, and its screens are one column of
 * text: stretched across a 1280pt landscape tablet the onboarding grid grew until its button
 * sat roughly 450pt below the fold, which is an onboarding nobody can finish — and Apple
 * tests on iPad during review. 440dp is the width the phone layouts were designed at.
 */
fun Modifier.readableWidth(max: Dp = READABLE_WIDTH): Modifier = this.widthIn(max = max)

val READABLE_WIDTH: Dp = 440.dp

/** Full-width rounded-rectangle CTA (« Elevate arrondi ») with the soft press feedback used across the iOS flow. */
@Composable
fun OnboardingCta(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    horizontalInset: Dp = 24.dp,
    bottomInset: Dp = 20.dp,
) {
    val haptics = rememberOnboardingHaptics()
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = if (pressed) 0.96f else 1f,
        animationSpec = spring(dampingRatio = 0.8f, stiffness = Spring.StiffnessMedium),
        label = "ctaScale",
    )
    androidx.compose.material3.Button(
        onClick = {
            haptics.primary()
            onClick()
        },
        enabled = enabled,
        interactionSource = interaction,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = horizontalInset)
            .padding(bottom = bottomInset)
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            }
            .height(56.dp),
        shape = OV2Shapes.control,
        colors = androidx.compose.material3.ButtonDefaults.buttonColors(
            containerColor = OV2.accent,
            contentColor = Color.White,
            disabledContainerColor = OV2.accent.copy(alpha = 0.35f),
            disabledContentColor = Color.White.copy(alpha = 0.9f),
        ),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 12.dp),
    ) {
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 16.sp,
            maxLines = 2,
            textAlign = TextAlign.Center,
        )
    }
}

/**
 * A word whose slot is as wide as its bold rendering, so turning it bold does not reflow
 * the sentence around it — the iOS screens rely on that stillness.
 */
@Composable
fun WordCell(
    word: String,
    bold: Boolean,
    modifier: Modifier = Modifier,
    style: TextStyle = OV2.title,
    boldColor: Color = OV2.ink,
    dimColor: Color = OV2.inkTertiary,
) {
    val color by androidx.compose.animation.animateColorAsState(
        targetValue = if (bold) boldColor else dimColor,
        animationSpec = tween(300),
        label = "wordColor",
    )
    Box(modifier = modifier, contentAlignment = Alignment.Center) {
        Text(text = word, style = style.copy(fontWeight = FontWeight.ExtraBold), modifier = Modifier.alpha(0f))
        Text(
            text = word,
            style = style.copy(
                fontWeight = if (bold) FontWeight.ExtraBold else FontWeight.Normal,
                color = color,
            ),
        )
    }
}

/** Sentence that turns bold one word at a time, centred and wrapping like the iOS flow layout. */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun ProgressiveWords(
    words: List<String>,
    boldCount: Int,
    modifier: Modifier = Modifier,
    style: TextStyle = OV2.title,
    lastCell: (@Composable (bold: Boolean) -> Unit)? = null,
) {
    FlowRow(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(7.dp, Alignment.CenterHorizontally),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        words.forEachIndexed { index, word ->
            if (lastCell != null && index == words.lastIndex) {
                lastCell(boldCount > index)
            } else {
                WordCell(word = word, bold = index < boldCount, style = style)
            }
        }
    }
}

/**
 * Vertical carousel: the centred item is sharp, its neighbours shrink, fade and blur.
 * [blurEnabled] is off on constrained phones, where the scale and fade carry the effect
 * on their own (and `Modifier.blur` is a no-op below Android 12 anyway).
 */
@Composable
fun <T> OnboardingRoulette(
    items: List<T>,
    slotSpacing: Dp,
    tickMillis: Long,
    modifier: Modifier = Modifier,
    running: Boolean = true,
    blurEnabled: Boolean = true,
    content: @Composable (item: T, focused: Boolean) -> Unit,
) {
    if (items.isEmpty()) return
    val position = remember { Animatable(0f) }
    LaunchedEffect(running, items.size) {
        if (!running) return@LaunchedEffect
        while (true) {
            delay(tickMillis)
            position.animateTo(position.value + 1f, tween(950, easing = FastOutSlowInEasing))
        }
    }
    val spacingPx = with(LocalDensity.current) { slotSpacing.toPx() }
    // Only the slot window is read during composition; the per-frame offset, scale and
    // fade are read inside graphicsLayer, so a turn does not recompose the cards.
    val base by remember { derivedStateOf { kotlin.math.floor(position.value).toInt() } }
    Box(
        modifier = modifier
            .graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
            .drawWithContent {
                drawContent()
                drawRect(
                    brush = Brush.verticalGradient(
                        0f to Color.Transparent,
                        0.27f to Color.Black,
                        0.73f to Color.Black,
                        1f to Color.Transparent,
                    ),
                    blendMode = BlendMode.DstIn,
                )
            },
        contentAlignment = Alignment.Center,
    ) {
        for (slot in (base - 1)..(base + 2)) {
            val item = items[((slot % items.size) + items.size) % items.size]
            val settledDistance = kotlin.math.abs(slot - base)
            val focused = settledDistance == 0
            // Blur cannot be animated per frame the way a layer transform can, so it is
            // stepped once per turn on the settled distance.
            val blurRadius = if (focused) 0.dp else minOf(7, settledDistance * 5).dp
            Box(
                modifier = Modifier
                    .graphicsLayer {
                        val distance = slot - position.value
                        val magnitude = kotlin.math.abs(distance)
                        translationY = distance * spacingPx
                        val s = 1f - 0.16f * minOf(magnitude, 1f)
                        scaleX = s
                        scaleY = s
                        alpha = if (magnitude < 0.5f) {
                            1f
                        } else {
                            (0.42f - (magnitude - 0.5f) * 0.42f).coerceAtLeast(0f)
                        }
                    }
                    .let { if (blurEnabled && blurRadius > 0.dp) it.blur(blurRadius) else it },
            ) {
                content(item, focused)
            }
        }
    }
}

/** Circle badge used for icons and emoji throughout the flow. */
@Composable
fun OnboardingCircleBadge(
    size: Dp,
    background: Color,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    Box(
        modifier = modifier.size(size).background(background, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        content()
    }
}

// region « Elevate arrondi » : header, cards, fitted illustrations

/** Height the coordinator reserves above a step that carries the header (row of 44 + 6 on top). */
internal val ONBOARDING_HEADER_HEIGHT: Dp = 50.dp

/** Width of the bar (progress or carousel segments) centred in the header. */
internal val ONBOARDING_HEADER_BAR_WIDTH: Dp = 200.dp

/** Side margin of the redesigned pages. */
internal val ONBOARDING_SIDE_INSET: Dp = 24.dp

/** « Remove animations » is on (animator scale 0): the flow shows its end states instead of moving. */
@Composable
internal fun rememberOnboardingReduceMotion(): Boolean {
    val context = LocalContext.current
    return remember(context) {
        runCatching {
            Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f
        }.getOrDefault(false)
    }
}

/** A screen reader explores the screen by touch: content must not change on its own. */
@Composable
internal fun rememberOnboardingScreenReader(): Boolean {
    val context = LocalContext.current
    return remember(context) {
        runCatching {
            (context.getSystemService(Context.ACCESSIBILITY_SERVICE) as? AccessibilityManager)
                ?.isTouchExplorationEnabled == true
        }.getOrDefault(false)
    }
}

/**
 * Card background of the style (1.5 dp border, small bottom edge, no shadow) with a free
 * border colour and no padding, for the cards of the illustrations (iOS `ov2Card`).
 */
internal fun Modifier.ov2Card(
    border: Color = DS.hairline,
    fill: Color = DS.surface,
    shape: Shape = DS.cardShape,
    lip: Dp = 1.dp,
): Modifier = this
    .drawBehind {
        val outline = shape.createOutline(size, layoutDirection, this)
        translate(top = lip.toPx()) { drawOutline(outline, border) }
    }
    .clip(shape)
    .background(fill)
    .border(1.5.dp, border, shape)

/** The header's back chevron: 44 dp touch target and elastic press. */
@Composable
internal fun OnboardingBackButton(label: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val ink = DS.ink
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    Box(
        modifier = modifier
            .size(44.dp)
            // No tick of its own: going back vibrates once, from the arrow as from the system gesture.
            .pressable(onClick = onClick, scaleDown = 0.88f, haptic = false)
            .semantics {
                contentDescription = label
                role = Role.Button
            },
        contentAlignment = Alignment.Center,
    ) {
        Canvas(modifier = Modifier.size(width = 10.dp, height = 17.dp)) {
            // The point of the chevron sits on the side the reading comes from.
            val tip = if (rtl) size.width else 0f
            val tail = if (rtl) 0f else size.width
            val chevron = Path().apply {
                moveTo(tail, 0f)
                lineTo(tip, size.height / 2f)
                lineTo(tail, size.height)
            }
            drawPath(
                path = chevron,
                color = ink,
                style = Stroke(width = 2.4.dp.toPx(), cap = StrokeCap.Round, join = StrokeJoin.Round),
            )
        }
    }
}

/**
 * The header shared by the flow: the back chevron at the start and, centred, what the step
 * shows of its progress (nothing, a 200 dp bar, the carousel segments). Laid over the pages
 * by the coordinator, which reserves [ONBOARDING_HEADER_HEIGHT] above them.
 */
@Composable
internal fun OnboardingHeader(
    backLabel: String,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    center: @Composable () -> Unit,
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .readableWidth()
            .padding(horizontal = 14.dp)
            .padding(top = 6.dp)
            .height(44.dp),
    ) {
        Box(
            modifier = Modifier.align(Alignment.Center).width(ONBOARDING_HEADER_BAR_WIDTH),
            contentAlignment = Alignment.Center,
        ) {
            center()
        }
        OnboardingBackButton(
            label = backLabel,
            onClick = onBack,
            modifier = Modifier.align(Alignment.CenterStart),
        )
    }
}

/**
 * Segmented bar of the presentation carousel: past pages are full, the current segment
 * fills while its page is on screen. [progress] is read while drawing, so the bar follows
 * the clock without recomposing.
 */
@Composable
internal fun OnboardingStorySegments(
    count: Int,
    current: Int,
    progress: () -> Float,
    modifier: Modifier = Modifier,
    height: Dp = 5.dp,
) {
    val tint = DS.accent
    val track = DS.accentTint
    val total = count.coerceAtLeast(1)
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(height)
            .clearAndSetSemantics { stateDescription = "${minOf(current + 1, total)} / $total" },
        horizontalArrangement = Arrangement.spacedBy(5.dp),
    ) {
        repeat(total) { index ->
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .clip(CircleShape)
                    .background(track)
                    .drawBehind {
                        val fill = when {
                            index < current -> 1f
                            index == current -> progress().coerceIn(0f, 1f)
                            else -> 0f
                        }
                        if (fill <= 0f) return@drawBehind
                        val width = size.width * fill
                        drawRoundRect(
                            color = tint,
                            topLeft = Offset(if (layoutDirection == LayoutDirection.Rtl) size.width - width else 0f, 0f),
                            size = Size(width, size.height),
                            cornerRadius = CornerRadius(size.height / 2f),
                        )
                    },
            )
        }
    }
}

/**
 * Shows [content] at its natural height when it fits in the height received, and scales it
 * down as one block otherwise (small phone, large font). The illustrations of the
 * presentation pages are interface mock-ups with fixed sizes: scaling keeps their
 * proportions where squeezing would distort them (iOS `OnboardingV2FitHeight`).
 */
@Composable
internal fun OnboardingFitHeight(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Layout(content = { Box { content() } }, modifier = modifier) { measurables, constraints ->
        val width = constraints.maxWidth
        val placeable = measurables.first().measure(
            Constraints(minWidth = width, maxWidth = width, minHeight = 0, maxHeight = Constraints.Infinity),
        )
        val height = if (constraints.hasBoundedHeight) constraints.maxHeight else placeable.height
        val scale = if (placeable.height > height && placeable.height > 0) {
            (height.toFloat() / placeable.height).coerceIn(0.5f, 1f)
        } else {
            1f
        }
        layout(width, height) {
            placeable.placeWithLayer(0, (height - placeable.height) / 2) {
                scaleX = scale
                scaleY = scale
            }
        }
    }
}

/**
 * A text that shrinks, down to [minScale], until it fits its [maxLines] and the height its
 * modifier gives it — iOS's `minimumScaleFactor`. Hidden until the size has settled, so the
 * reader never sees it jump.
 */
@Composable
internal fun OnboardingShrinkText(
    text: AnnotatedString,
    style: TextStyle,
    maxLines: Int,
    modifier: Modifier = Modifier,
    minScale: Float = 0.7f,
    textAlign: TextAlign = TextAlign.Center,
) {
    var scale by remember(text.text, style.fontSize) { mutableFloatStateOf(1f) }
    var settled by remember(text.text, style.fontSize) { mutableStateOf(false) }
    Text(
        text = text,
        style = style.copy(
            fontSize = style.fontSize * scale,
            lineHeight = if (style.lineHeight.isSpecified) style.lineHeight * scale else style.lineHeight,
        ),
        textAlign = textAlign,
        maxLines = maxLines,
        overflow = TextOverflow.Ellipsis,
        onTextLayout = { layout ->
            if (layout.hasVisualOverflow && scale > minScale) {
                scale = (scale - 0.06f).coerceAtLeast(minScale)
            } else {
                settled = true
            }
        },
        modifier = modifier.drawWithContent { if (settled) drawContent() },
    )
}

/**
 * A course cover for the illustrations of the flow, small and cached on its own key. Covers
 * are fetched (Android ships none): until one arrives, or without network, the tile keeps
 * its [placeholder] tint rather than a letter.
 */
@Composable
internal fun OnboardingCover(
    courseId: String?,
    modifier: Modifier = Modifier,
    placeholder: Color = DS.accentTint,
    edgePx: Int = 360,
    colorFilter: ColorFilter? = null,
    imageAlpha: Float = 1f,
) {
    val context = LocalContext.current
    val url = remember(courseId) { courseId?.let { CourseCoverUrls.url(context, it) } }
    Box(modifier = modifier.background(placeholder)) {
        if (url != null) {
            AsyncImage(
                model = ImageRequest.Builder(context)
                    .data(url)
                    .size(edgePx)
                    .memoryCacheKey("onboarding:$courseId:$edgePx")
                    .diskCacheKey(courseId)
                    .crossfade(true)
                    .build(),
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop,
                colorFilter = colorFilter,
                alpha = imageAlpha,
            )
        }
    }
}

// endregion
