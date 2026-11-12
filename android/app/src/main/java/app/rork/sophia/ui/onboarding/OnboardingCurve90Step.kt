package app.rork.sophia.ui.onboarding

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.State
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathMeasure
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.R
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.theme.DS
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/** The chart is drawn in the fixed 318 × 300 frame of the mock-up, then scaled to its box. */
private const val CURVE_WIDTH = 318f
private const val CURVE_HEIGHT = 300f

/** Abscissas of the four marks of the axis: today, 7, 30 and 90 days. */
private val CURVE_TICK_XS = listOf(18f, 96f, 190f, 298f)

private val CURVE_MARK_KEYS = listOf(
    "onboardingV2.curve90.today",
    "onboardingV2.curve90.day7",
    "onboardingV2.curve90.day30",
    "onboardingV2.curve90.day90",
)

/** Wait before each mark: they follow the tip of the blue curve. */
private val CURVE_MARK_WAITS = listOf(60L, 540L, 380L, 620L)

/** Le bouton « Continuer » n'apparaît qu'après ce délai : le temps de voir les courbes partir. */
private const val CURVE_CTA_DELAY_MILLIS = 1000L

/** Very slightly blue background of the chart card. */
private val CurveCardFill = Color(0xFFF7F9FD)
private val CurveAxisColor = Color(0xFFC3CBD8)

/**
 * « Small efforts add up. In 90 days, you won't be the same person. »
 *
 * Two curves over 90 days: Sophia's, blue, which speeds up, and the one of the time spent
 * scrolling elsewhere, dark, which stays almost flat. The curves draw themselves when the page
 * arrives, then the marks of the axis (today, 7, 30 and 90 days) land one after the other with
 * a soft vibration. No result figure anywhere: only trends. Port of iOS's `OnboardingV2Curve90`.
 *
 * Le bouton « Continuer » n'apparaît qu'une seconde après l'arrivée sur la page, et la courbe
 * bleue est étiquetée du vrai logo Sophia, en couleurs.
 */
@Composable
internal fun Curve90Step(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberHaptics()

    /** Drawn share of both curves, from 0 to 1. */
    val trim = remember { Animatable(0f) }
    var axisIn by remember { mutableStateOf(false) }
    /** Number of marks of the axis already down (0 to 4). */
    var marks by remember { mutableIntStateOf(0) }
    var endsIn by remember { mutableStateOf(false) }
    var labelsIn by remember { mutableStateOf(false) }
    var ctaIn by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        delay(CURVE_CTA_DELAY_MILLIS)
        ctaIn = true
    }
    LaunchedEffect(Unit) {
        delay(280)
        axisIn = true
        launch { trim.animateTo(1f, tween(durationMillis = 1600, easing = FastOutSlowInEasing)) }
        CURVE_MARK_WAITS.forEachIndexed { index, wait ->
            delay(wait)
            marks = index + 1
            haptics.soft()
        }
        endsIn = true
        delay(200)
        labelsIn = true
    }

    val axisAlpha = animateFloatAsState(if (axisIn) 1f else 0f, tween(350), label = "curveAxis")
    val markProgress = List(CURVE_MARK_KEYS.size) { index ->
        animateFloatAsState(if (marks > index) 1f else 0f, OnboardingMotion.settle(), label = "curveMark$index")
    }
    val endsProgress = animateFloatAsState(if (endsIn) 1f else 0f, OnboardingMotion.settle(), label = "curveEnds")
    val labelsProgress = animateFloatAsState(if (labelsIn) 1f else 0f, OnboardingMotion.settle(), label = "curveLabels")
    val ctaProgress = animateFloatAsState(if (ctaIn) 1f else 0f, OnboardingMotion.settle(320), label = "curveCta")
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl

    OnboardingPage(
        contentArrangement = Arrangement.Top,
        footer = {
            // Sa place est gardée dès le départ : le bouton apparaît sans déplacer la page, et
            // ne répond qu'une fois visible.
            Box(
                modifier = Modifier.graphicsLayer {
                    val progress = ctaProgress.value.coerceIn(0f, 1f)
                    alpha = progress
                    translationY = (1f - progress) * 10.dp.toPx()
                },
            ) {
                OnboardingCta(
                    text = StringStore.text(context, "common.continue", language),
                    onClick = onContinue,
                    enabled = ctaIn,
                )
            }
        },
    ) {
        Column(modifier = Modifier.fillMaxWidth().padding(horizontal = OV2End.side)) {
            Spacer(Modifier.height(OV2End.top))
            OV2EndHighlightTitle(
                text = StringStore.text(context, "onboardingV2.curve90.title", language),
                modifier = Modifier.dsStagger(0),
            )
            Spacer(Modifier.height(28.dp))
            val description = StringStore.text(context, "onboardingV2.curve90.a11y", language)
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .dsStagger(1)
                    .ov2EndCard(fill = CurveCardFill)
                    .clearAndSetSemantics { contentDescription = description },
            ) {
                Column(
                    modifier = Modifier.padding(start = 12.dp, top = 18.dp, end = 12.dp, bottom = 12.dp),
                    verticalArrangement = Arrangement.spacedBy(2.dp),
                ) {
                    BoxWithConstraints(
                        modifier = Modifier.fillMaxWidth().aspectRatio(CURVE_WIDTH / CURVE_HEIGHT),
                    ) {
                        Curve90Chart(
                            trim = { trim.value },
                            axisAlpha = axisAlpha,
                            markProgress = markProgress,
                            endsProgress = endsProgress,
                            modifier = Modifier.fillMaxSize(),
                        )
                        // Label of the dark curve, just above where it ends.
                        Text(
                            text = StringStore.text(context, "onboardingV2.curve90.others", language),
                            style = OV2.caption.copy(fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color.White),
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                            modifier = Modifier
                                .align(Alignment.TopEnd)
                                .padding(end = 4.dp)
                                .offset(y = maxHeight * 0.645f)
                                .widthIn(max = maxWidth * 0.86f)
                                .graphicsLayer {
                                    val progress = labelsProgress.value
                                    val scale = 0.5f + 0.5f * progress
                                    scaleX = scale
                                    scaleY = scale
                                    alpha = progress.coerceIn(0f, 1f)
                                    transformOrigin = TransformOrigin(if (rtl) 0f else 1f, 0.5f)
                                }
                                .background(DS.ink, RoundedCornerShape(12.dp))
                                .padding(horizontal = 12.dp, vertical = 5.dp),
                        )
                    }
                    Curve90MarkLabels(language = language, markProgress = markProgress)
                }
                // Étiquette de la courbe bleue : le vrai logo Sophia, en couleurs et jamais teinté,
                // sur une pastille blanche cerclée du bleu de la courbe.
                Box(
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .padding(top = 12.dp, end = 16.dp)
                        .graphicsLayer {
                            val progress = labelsProgress.value
                            val scale = 0.5f + 0.5f * progress
                            scaleX = scale
                            scaleY = scale
                            alpha = progress.coerceIn(0f, 1f)
                            transformOrigin = TransformOrigin(if (rtl) 0f else 1f, 0f)
                        }
                        .background(DS.surface, RoundedCornerShape(12.dp))
                        .border(1.5.dp, DS.accent, RoundedCornerShape(12.dp))
                        .padding(horizontal = 11.dp, vertical = 7.dp),
                ) {
                    Image(
                        painter = painterResource(R.drawable.sophia_mark),
                        contentDescription = null,
                        contentScale = ContentScale.Fit,
                        modifier = Modifier.height(18.dp).aspectRatio(LOGO_RATIO),
                    )
                }
            }
            Spacer(Modifier.height(16.dp))
        }
    }
}

/** Largeur sur hauteur de l'image `sophia_mark` (1192 × 334) : le symbole rose et le mot « Sophia ». */
private const val LOGO_RATIO = 1192f / 334f

/** The four marks of the axis, under the chart: each rises into place with its tick. */
@Composable
private fun Curve90MarkLabels(language: AppLanguage, markProgress: List<State<Float>>) {
    val context = LocalContext.current
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 6.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        CURVE_MARK_KEYS.forEachIndexed { index, key ->
            Text(
                text = StringStore.text(context, key, language),
                style = OV2.caption.copy(fontSize = 12.sp),
                maxLines = 1,
                softWrap = false,
                modifier = Modifier.graphicsLayer {
                    val progress = markProgress[index].value
                    alpha = progress.coerceIn(0f, 1f)
                    translationY = (1f - progress) * 5.dp.toPx()
                },
            )
        }
    }
}

/**
 * The chart itself: the axis and its ticks, the two curves cut at [trim], and the three dots
 * (start, and the end of each curve). Mirrored in right-to-left languages, where time runs
 * from the right like the labels under it. Every animated value is read while drawing, so a
 * frame of the animation never recomposes the page.
 */
@Composable
private fun Curve90Chart(
    trim: () -> Float,
    axisAlpha: State<Float>,
    markProgress: List<State<Float>>,
    endsProgress: State<Float>,
    modifier: Modifier = Modifier,
) {
    val ink = DS.ink
    val accent = DS.accent
    Spacer(
        modifier = modifier.drawWithCache {
            val rtl = layoutDirection == LayoutDirection.Rtl
            fun point(x: Float, y: Float): Offset {
                val mirrored = if (rtl) CURVE_WIDTH - x else x
                return Offset(mirrored / CURVE_WIDTH * size.width, y / CURVE_HEIGHT * size.height)
            }
            fun Path.start(x: Float, y: Float) = point(x, y).let { moveTo(it.x, it.y) }
            fun Path.curve(x1: Float, y1: Float, x2: Float, y2: Float, x: Float, y: Float) {
                val first = point(x1, y1)
                val second = point(x2, y2)
                val end = point(x, y)
                cubicTo(first.x, first.y, second.x, second.y, end.x, end.y)
            }

            // Sophia: starts flat and speeds up to the top corner.
            val sophia = Path().apply {
                start(18f, 256f)
                curve(120f, 252f, 200f, 190f, 298f, 40f)
            }
            // « Scrolling on other apps »: it ripples near the axis and barely climbs.
            val others = Path().apply {
                start(18f, 256f)
                curve(44f, 244f, 58f, 244f, 76f, 252f)
                curve(94f, 260f, 112f, 262f, 132f, 246f)
                curve(152f, 230f, 170f, 236f, 190f, 250f)
                curve(210f, 264f, 240f, 244f, 298f, 232f)
            }
            val sophiaMeasure = PathMeasure().apply { setPath(sophia, false) }
            val othersMeasure = PathMeasure().apply { setPath(others, false) }
            val segment = Path()
            val thin = 1.5.dp.toPx()

            onDrawBehind {
                val shown = trim().coerceIn(0f, 1f)
                drawLine(
                    color = CurveAxisColor,
                    start = point(18f, 258f),
                    end = point(300f, 258f),
                    strokeWidth = thin,
                    cap = StrokeCap.Round,
                    alpha = axisAlpha.value.coerceIn(0f, 1f),
                )
                CURVE_TICK_XS.forEachIndexed { index, x ->
                    drawLine(
                        color = CurveAxisColor,
                        start = point(x, 252f),
                        end = point(x, 264f),
                        strokeWidth = thin,
                        cap = StrokeCap.Round,
                        alpha = markProgress[index].value.coerceIn(0f, 1f),
                    )
                }
                drawTrimmed(othersMeasure, segment, shown, ink, 3.5.dp.toPx())
                drawTrimmed(sophiaMeasure, segment, shown, accent, 4.5.dp.toPx())
                drawDot(accent, 6.dp.toPx(), point(18f, 256f), markProgress[0].value)
                drawDot(ink, 6.dp.toPx(), point(298f, 232f), endsProgress.value)
                drawDot(accent, 7.dp.toPx(), point(298f, 40f), endsProgress.value)
            }
        },
    )
}

private fun DrawScope.drawTrimmed(measure: PathMeasure, segment: Path, shown: Float, color: Color, width: Float) {
    if (shown <= 0f) return
    segment.rewind()
    measure.getSegment(0f, measure.length * shown, segment, true)
    drawPath(
        path = segment,
        color = color,
        style = Stroke(width = width, cap = StrokeCap.Round, join = StrokeJoin.Round),
    )
}

/** A dot that pops in: [progress] overshoots 1 on its spring, which is the bounce. */
private fun DrawScope.drawDot(color: Color, radius: Float, center: Offset, progress: Float) {
    if (progress <= 0.01f) return
    drawCircle(
        color = color,
        radius = radius * progress.coerceAtLeast(0f),
        center = center,
        alpha = progress.coerceIn(0f, 1f),
    )
}
