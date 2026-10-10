package app.rork.sophia.ui.paywall

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.HorizontalDivider
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
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathMeasure
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import app.rork.sophia.ui.theme.uppercaseInApp

/**
 * The pieces of the reworked iOS paywalls (#249): the PRO comparison card, the « you also
 * unlock » list shared by the feature paywalls, the « OR » divider of the course-of-the-day
 * paywall, and the retention curve of the quiz paywall.
 */

// MARK: - Comparison table

/** A comparison row, and whether the free plan has it too (the real freemium rule). */
data class ComparisonFeature(val label: String, val free: Boolean)

/**
 * The table in a card. The PRO column is a tinted band, crowned, with filled ticks, facing a
 * grey free column: the eye goes straight to PRO.
 */
@Composable
fun ComparisonTable(
    features: List<ComparisonFeature>,
    freeLabel: String,
    proLabel: String,
    modifier: Modifier = Modifier,
) {
    val columnWidth = 72.dp
    val layoutDirection = LocalLayoutDirection.current
    Box(
        modifier = modifier
            .fillMaxWidth()
            .sophiaCard(elevation = 4.dp)
            .height(IntrinsicSize.Min),
    ) {
        // The PRO band, from the top of the card to the bottom.
        Box(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .width(columnWidth)
                .fillMaxHeight()
                .background(Brush.verticalGradient(listOf(DS.accent.copy(alpha = 0.14f), DS.accentSoft.copy(alpha = 0.05f))))
                .drawBehind {
                    val x = if (layoutDirection == LayoutDirection.Rtl) size.width - 1f else 0f
                    drawRect(DS.accent.copy(alpha = 0.18f), topLeft = Offset(x, 0f), size = androidx.compose.ui.geometry.Size(1.dp.toPx(), size.height))
                },
        )
        Column(modifier = Modifier.fillMaxWidth().padding(start = 16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth().height(64.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Spacer(Modifier.weight(1f))
                Text(
                    text = freeLabel,
                    style = SophiaTypography.labelMedium.copy(fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = DS.inkTertiary),
                    textAlign = TextAlign.Center,
                    maxLines = 2,
                    modifier = Modifier.width(columnWidth),
                )
                Column(
                    modifier = Modifier.width(columnWidth),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    Text("👑", fontSize = 15.sp)
                    Text(
                        text = proLabel,
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 12.sp,
                        color = Color.White,
                        maxLines = 1,
                        textAlign = TextAlign.Center,
                        modifier = Modifier
                            .clip(CircleShape)
                            .background(DS.accent)
                            .padding(horizontal = 10.dp, vertical = 4.dp),
                    )
                }
            }
            features.forEachIndexed { index, feature ->
                if (index > 0) HorizontalDivider(color = DS.hairline)
                Row(
                    modifier = Modifier.fillMaxWidth().heightIn(min = 46.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = feature.label,
                        style = SophiaTypography.bodyMedium.copy(fontSize = 15.sp, color = DS.ink, fontWeight = FontWeight.SemiBold),
                        modifier = Modifier.weight(1f).padding(vertical = 10.dp),
                    )
                    Box(modifier = Modifier.width(columnWidth), contentAlignment = Alignment.Center) {
                        if (feature.free) {
                            Icon(Icons.Filled.Check, contentDescription = null, tint = DS.inkTertiary, modifier = Modifier.size(16.dp))
                        } else {
                            Icon(Icons.Filled.Close, contentDescription = null, tint = DS.inkTertiary.copy(alpha = 0.6f), modifier = Modifier.size(15.dp))
                        }
                    }
                    Box(modifier = Modifier.width(columnWidth), contentAlignment = Alignment.Center) {
                        FilledCheck(size = 22.dp)
                    }
                }
            }
        }
    }
}

/** White tick on an accent disc, the « included » mark of the PRO column and the unlock list. */
@Composable
fun FilledCheck(size: Dp, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier.size(size).background(DS.accent, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Icon(Icons.Filled.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(size * 0.6f))
    }
}

// MARK: - « Tu débloques aussi »

/** A PRO strength: an emoji and a label. */
enum class PaywallUnlockItem(val emoji: String, val key: String) {
    AUDIO("🎧", "paywall.unlock.audio"),
    UNLIMITED("📚", "paywall.unlock.unlimited"),
    QUIZ("🧠", "paywall.unlock.quiz"),
}

/**
 * The « you also unlock » card of the feature paywalls: a title, then one line per strength
 * with its emoji and a tick, on a tinted background. The same block everywhere, so every
 * paywall says PRO is all of Sophia and not one option.
 */
@Composable
fun PaywallUnlockList(
    language: AppLanguage,
    titleKey: String,
    items: List<PaywallUnlockItem>,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val shape = DS.cardShape
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(shape)
            .background(Brush.linearGradient(listOf(DS.accentTint, DS.accentTint.copy(alpha = 0.55f))))
            .border(1.dp, DS.accentSoft.copy(alpha = 0.18f), shape)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            text = StringStore.text(context, titleKey, language).uppercaseInApp(),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 12.sp,
            letterSpacing = 0.8.sp,
            color = DS.accentSoft,
        )
        Column {
            items.forEachIndexed { index, item ->
                if (index > 0) {
                    HorizontalDivider(color = DS.accentSoft.copy(alpha = 0.14f), modifier = Modifier.padding(start = 44.dp))
                }
                Row(
                    modifier = Modifier.fillMaxWidth().padding(vertical = 9.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Box(
                        modifier = Modifier.size(32.dp).background(DS.surface, RoundedCornerShape(9.dp)),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(item.emoji, fontSize = 18.sp)
                    }
                    Text(
                        text = StringStore.text(context, item.key, language),
                        style = SophiaTypography.bodyMedium.copy(fontSize = 15.sp, color = DS.ink, fontWeight = FontWeight.SemiBold),
                        modifier = Modifier.weight(1f),
                    )
                    FilledCheck(size = 20.dp)
                }
            }
        }
    }
}

// MARK: - « OU »

/** The hinge between the two ways out: wait for tomorrow, or unlock now. */
@Composable
fun PaywallOrDivider(text: String, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(Modifier.weight(1f).height(1.dp).background(DS.hairline))
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 12.sp,
            letterSpacing = 1.2.sp,
            color = DS.inkTertiary,
        )
        Box(Modifier.weight(1f).height(1.dp).background(DS.hairline))
    }
}

// MARK: - Retention curve (quiz paywall)

/**
 * Points (x 0…1, y 0…1 where 1 = everything remembered) of the « with quizzes » curve:
 * reminders at D3, D7, D15 and D30 that bring it back up each time.
 */
private val WITH_QUIZ = listOf(
    0.00f to 1.00f, 0.07f to 0.78f, 0.13f to 0.96f, 0.24f to 0.76f, 0.30f to 0.97f,
    0.47f to 0.80f, 0.55f to 0.98f, 0.78f to 0.86f, 0.86f to 1.00f, 1.00f to 0.97f,
)

/** Without quizzes: the fall, then almost nothing. */
private val WITHOUT_QUIZ = listOf(
    0.00f to 1.00f, 0.07f to 0.50f, 0.18f to 0.28f, 0.38f to 0.16f, 0.65f to 0.10f, 1.00f to 0.06f,
)

/** Axis marks (D1, D3, D7, D15, D30); for the four reminders, also where the blue curve peaks. */
private val DAY_MARKS = listOf(1 to 0.0f, 3 to 0.13f, 7 to 0.30f, 15 to 0.55f, 30 to 0.86f)

private val PLOT_HEIGHT = 150.dp
private val PLOT_INSET = 8.dp

/**
 * Two hand-drawn curves: in blue, what is remembered with the quizzes and the training (high,
 * dipping a little then climbing back at D3, D7, D15, D30); in grey, without quizzes (it falls
 * and never recovers). A drawing, not a measurement: it shows the forgetting curve and what
 * reminders do to it.
 */
@Composable
fun QuizRetentionChart(language: AppLanguage, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val drawn = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        drawn.animateTo(1f, tween(durationMillis = 1800, delayMillis = 350, easing = FastOutSlowInEasing))
    }
    Column(
        modifier = modifier
            .fillMaxWidth()
            .sophiaCard(elevation = 4.dp)
            .padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically) {
            ChartLegend(DS.accentSoft, StringStore.text(context, "paywall.quiz.chart.with", language), strong = true)
            ChartLegend(DS.inkTertiary, StringStore.text(context, "paywall.quiz.chart.without", language), strong = false)
        }
        // A chart reads left to right in every language.
        androidx.compose.runtime.CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                // The vertical axis label, lying along the plot.
                Box(modifier = Modifier.width(14.dp).height(PLOT_HEIGHT), contentAlignment = Alignment.Center) {
                    Text(
                        text = StringStore.text(context, "paywall.quiz.chart.axis", language),
                        style = SophiaTypography.labelMedium.copy(fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = DS.inkTertiary),
                        maxLines = 1,
                        softWrap = false,
                        modifier = Modifier
                            .wrapContentSize(unbounded = true)
                            .rotate(-90f),
                    )
                }
                Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    RetentionPlot(progress = drawn.value)
                    DayLabels(language)
                }
            }
        }
    }
}

@Composable
private fun ChartLegend(color: Color, label: String, strong: Boolean) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Box(Modifier.size(width = 16.dp, height = 4.dp).background(color, CircleShape))
        Text(
            text = label,
            style = SophiaTypography.labelMedium.copy(
                fontSize = 12.sp,
                fontWeight = if (strong) FontWeight.Bold else FontWeight.Medium,
                color = if (strong) DS.ink else DS.inkSecondary,
            ),
            maxLines = 1,
        )
    }
}

@Composable
private fun RetentionPlot(progress: Float) {
    Box(modifier = Modifier.fillMaxWidth().height(PLOT_HEIGHT)) {
        Canvas(modifier = Modifier.fillMaxWidth().height(PLOT_HEIGHT)) {
            val inset = PLOT_INSET.toPx()
            fun point(p: Pair<Float, Float>) = Offset(
                inset + p.first * (size.width - 2 * inset),
                inset + (1 - p.second) * (size.height - 2 * inset),
            )
            // Three very light grid lines.
            for (i in 1..3) {
                val y = size.height * i / 4f
                drawLine(DS.hairline.copy(alpha = 0.8f), Offset(0f, y), Offset(size.width, y), strokeWidth = 1.dp.toPx())
            }
            val without = smoothPath(WITHOUT_QUIZ.map(::point))
            val with = smoothPath(WITH_QUIZ.map(::point))
            // Without quizzes: the fall, in grey.
            drawPath(
                trimmed(without, progress),
                color = DS.inkTertiary.copy(alpha = 0.75f),
                style = Stroke(width = 3.dp.toPx(), cap = StrokeCap.Round, join = StrokeJoin.Round),
            )
            // With quizzes: the tinted area, then the blue line.
            val area = Path().apply {
                addPath(with)
                val last = point(WITH_QUIZ.last())
                val first = point(WITH_QUIZ.first())
                lineTo(last.x, size.height)
                lineTo(first.x, size.height)
                close()
            }
            drawPath(
                area,
                brush = Brush.verticalGradient(listOf(DS.accentSoft.copy(alpha = 0.22f), DS.accentSoft.copy(alpha = 0f))),
                alpha = progress,
            )
            drawPath(
                trimmed(with, progress),
                color = DS.accentSoft,
                style = Stroke(width = 3.5.dp.toPx(), cap = StrokeCap.Round, join = StrokeJoin.Round),
            )
        }
        // A dot at each reminder: the curve climbs back.
        DAY_MARKS.drop(1).forEach { (_, x) ->
            val peak = WITH_QUIZ.firstOrNull { kotlin.math.abs(it.first - x) < 0.001f } ?: (x to 1f)
            ReminderDot(fractionX = peak.first, fractionY = peak.second, shown = progress >= x)
        }
    }
}

@Composable
private fun ReminderDot(fractionX: Float, fractionY: Float, shown: Boolean) {
    val scale by animateFloatAsState(
        targetValue = if (shown) 1f else 0f,
        animationSpec = spring(dampingRatio = 0.6f, stiffness = Spring.StiffnessMedium),
        label = "reminderDot",
    )
    Layout(
        content = {
            Box(
                modifier = Modifier
                    .size(11.dp)
                    .graphicsLayer { scaleX = scale; scaleY = scale; alpha = scale.coerceIn(0f, 1f) }
                    .background(DS.surface, CircleShape)
                    .border(2.5.dp, DS.accentSoft, CircleShape),
            )
        },
        modifier = Modifier.fillMaxWidth().height(PLOT_HEIGHT),
    ) { measurables, constraints ->
        val placeable = measurables.first().measure(Constraints())
        val inset = PLOT_INSET.roundToPx()
        layout(constraints.maxWidth, constraints.maxHeight) {
            val x = inset + fractionX * (constraints.maxWidth - 2 * inset)
            val y = inset + (1 - fractionY) * (constraints.maxHeight - 2 * inset)
            placeable.place((x - placeable.width / 2f).toInt(), (y - placeable.height / 2f).toInt())
        }
    }
}

/** « J1 », « J3 »… centred under their mark. */
@Composable
private fun DayLabels(language: AppLanguage) {
    val context = LocalContext.current
    Layout(
        content = {
            DAY_MARKS.forEach { (day, _) ->
                Text(
                    text = StringStore.text(context, "paywall.quiz.chart.day", language, day),
                    style = SophiaTypography.labelMedium.copy(
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        color = if (day == 1) DS.inkTertiary else DS.accentSoft,
                    ),
                    maxLines = 1,
                    softWrap = false,
                )
            }
        },
        modifier = Modifier.fillMaxWidth().height(16.dp),
    ) { measurables, constraints ->
        val placeables = measurables.map { it.measure(Constraints()) }
        val inset = PLOT_INSET.roundToPx()
        layout(constraints.maxWidth, constraints.maxHeight) {
            placeables.forEachIndexed { i, placeable ->
                val x = inset + DAY_MARKS[i].second * (constraints.maxWidth - 2 * inset)
                val left = (x - placeable.width / 2f).toInt().coerceIn(0, (constraints.maxWidth - placeable.width).coerceAtLeast(0))
                placeable.place(left, (constraints.maxHeight - placeable.height) / 2)
            }
        }
    }
}

/** A smooth curve (Catmull-Rom → Bézier) through the points, as on iOS. */
private fun smoothPath(points: List<Offset>): Path {
    val path = Path()
    if (points.isEmpty()) return path
    path.moveTo(points[0].x, points[0].y)
    for (i in 0 until points.size - 1) {
        val p0 = if (i > 0) points[i - 1] else points[i]
        val p1 = points[i]
        val p2 = points[i + 1]
        val p3 = if (i + 2 < points.size) points[i + 2] else p2
        path.cubicTo(
            p1.x + (p2.x - p0.x) / 6f, p1.y + (p2.y - p0.y) / 6f,
            p2.x - (p3.x - p1.x) / 6f, p2.y - (p3.y - p1.y) / 6f,
            p2.x, p2.y,
        )
    }
    return path
}

/** The first [fraction] of [path], for the curves drawing themselves in. */
private fun trimmed(path: Path, fraction: Float): Path {
    if (fraction >= 1f) return path
    val measure = PathMeasure()
    measure.setPath(path, false)
    val out = Path()
    if (fraction > 0f) measure.getSegment(0f, measure.length * fraction, out, true)
    return out
}
