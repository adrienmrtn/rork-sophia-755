package app.rork.sophia.ui.onboarding

import android.content.Context
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
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
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.formatted
import coil.compose.AsyncImage
import kotlin.math.cos
import kotlin.math.sin
import kotlin.random.Random

/**
 * The social-proof pieces the iOS 1.1.8 onboarding repeats from page to page: words marked
 * in pink, the rating between two laurels, rows of real user photos, and a confetti burst.
 */

/** Pink of the words a translation marks between `**`, as on iOS (`OV2.pink`). */
internal val OV2Pink = Color(0xFFF2548F)

/**
 * « Get **smarter** with… »: the odd pieces between `**` markers turn pink. The markers
 * travel with each translation, so every language picks its own words without code.
 */
internal fun highlighted(source: String, color: Color = OV2Pink): AnnotatedString = buildAnnotatedString {
    source.split("**").forEachIndexed { index, part ->
        if (part.isEmpty()) return@forEachIndexed
        if (index % 2 == 0) append(part) else withStyle(SpanStyle(color = color)) { append(part) }
    }
}

// MARK: - Bundled pictures

/** Files under `assets/onboarding` (copied from the iOS bundle), by prefix, in natural order. */
internal fun onboardingAssets(context: Context, prefix: String): List<String> =
    runCatching { context.assets.list("onboarding")?.toList().orEmpty() }
        .getOrDefault(emptyList())
        .filter { it.startsWith(prefix) }
        .sortedWith(compareBy({ it.length }, { it }))
        .map { "file:///android_asset/onboarding/$it" }

/**
 * The real people of the social-proof pages: the students first, then the portraits of the
 * reviews. Only real photos — an empty slot shows nothing rather than a placeholder ring.
 */
internal fun studentPhotos(context: Context): List<String> =
    onboardingAssets(context, "student_") + onboardingAssets(context, "review_avatar_")

internal const val SOPHIA_LOGO = "file:///android_asset/onboarding/sophia_logo.png"

@Composable
internal fun AssetPicture(
    url: String,
    modifier: Modifier = Modifier,
    contentScale: ContentScale = ContentScale.Crop,
) {
    AsyncImage(
        model = url,
        contentDescription = null,
        modifier = modifier,
        contentScale = contentScale,
    )
}

/** A round portrait with a white ring and a soft shadow. */
@Composable
internal fun RoundPortrait(url: String, size: Dp, modifier: Modifier = Modifier, ring: Dp = 3.dp) {
    Box(
        modifier = modifier
            .size(size)
            .shadow(6.dp, CircleShape, clip = false, ambientColor = Color.Black.copy(alpha = 0.14f))
            .clip(CircleShape)
            .background(Color.White)
            .border(ring, Color.White, CircleShape),
    ) {
        AssetPicture(url = url, modifier = Modifier.fillMaxSize().clip(CircleShape))
    }
}

/** Overlapping portraits, for the pages that cite users without giving them the whole page. */
@Composable
internal fun PhotoRow(photos: List<String>, modifier: Modifier = Modifier, size: Dp = 36.dp) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(-(size * 0.28f)),
    ) {
        photos.forEachIndexed { i, url ->
            RoundPortrait(
                url = url,
                size = size,
                ring = 2.dp,
                modifier = Modifier.zIndex((photos.size - i).toFloat()),
            )
        }
    }
}

// MARK: - Laurels and rating

/**
 * One laurel branch, drawn rather than shipped: an arc for the stem and pairs of leaves
 * along it. [mirrored] gives the right-hand branch.
 */
@Composable
internal fun LaurelBranch(height: Dp, tint: Color, mirrored: Boolean, modifier: Modifier = Modifier) {
    // A right-to-left row swaps the two branches; flip the drawing so each still opens outwards.
    val flip = mirrored != (LocalLayoutDirection.current == LayoutDirection.Rtl)
    Canvas(modifier = modifier.width(height * 0.5f).height(height)) {
        val h = size.height
        val w = size.width
        // A circle through the bottom tip, the outer bulge and the top tip of the branch.
        val radius = (0.49f * w * w + 0.2025f * h * h) / (1.4f * w)
        val center = Offset(0.15f * w + radius, h / 2f)
        scale(scaleX = if (flip) -1f else 1f, scaleY = 1f, pivot = Offset(w / 2f, h / 2f)) {
            drawArc(
                color = tint,
                startAngle = 104f,
                sweepAngle = 150f,
                useCenter = false,
                topLeft = Offset(center.x - radius, center.y - radius),
                size = Size(radius * 2f, radius * 2f),
                style = Stroke(width = h * 0.035f, cap = StrokeCap.Round),
            )
            val leafLength = h * 0.2f
            val leafWidth = h * 0.085f
            for (i in 0 until 7) {
                val angle = 116f + i * 21f
                val rad = Math.toRadians(angle.toDouble())
                val base = Offset(
                    center.x + radius * cos(rad).toFloat(),
                    center.y + radius * sin(rad).toFloat(),
                )
                val tangent = angle + 90f
                val scaleDown = 1f - i * 0.04f
                leaf(base, tangent - 38f, leafLength * scaleDown, leafWidth * scaleDown, tint)
                leaf(base, tangent + 34f, leafLength * 0.82f * scaleDown, leafWidth * 0.9f * scaleDown, tint)
            }
            val tipRad = Math.toRadians(254.0)
            val tip = Offset(
                center.x + radius * cos(tipRad).toFloat(),
                center.y + radius * sin(tipRad).toFloat(),
            )
            leaf(tip, 254f + 90f, leafLength * 0.75f, leafWidth * 0.8f, tint)
        }
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.leaf(
    base: Offset,
    degrees: Float,
    length: Float,
    width: Float,
    tint: Color,
) {
    rotate(degrees = degrees, pivot = base) {
        drawOval(
            color = tint,
            topLeft = Offset(base.x, base.y - width / 2f),
            size = Size(length, width),
        )
    }
}

/** Two laurels around a block (rating, user count): the social-proof motif of the flow. */
@Composable
internal fun LaurelBadge(
    modifier: Modifier = Modifier,
    size: Dp = 54.dp,
    tint: Color = OV2.warm,
    content: @Composable () -> Unit,
) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        LaurelBranch(height = size * 1.2f, tint = tint, mirrored = false)
        content()
        LaurelBranch(height = size * 1.2f, tint = tint, mirrored = true)
    }
}

@Composable
internal fun StarRow(starSize: Dp, modifier: Modifier = Modifier, spacing: Dp = 3.dp) {
    Row(modifier = modifier, horizontalArrangement = Arrangement.spacedBy(spacing)) {
        repeat(5) {
            Icon(Icons.Filled.Star, contentDescription = null, tint = OV2.warm, modifier = Modifier.size(starSize))
        }
    }
}

/** Five stars, « 4,8 » with the language's decimal separator, and a caption. */
@Composable
internal fun RatingStack(caption: String, language: AppLanguage, compact: Boolean = false) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(if (compact) 2.dp else 3.dp),
    ) {
        StarRow(starSize = if (compact) 13.dp else 15.dp)
        Text(
            text = 4.8.formatted(language, 1),
            style = OV2.title.copy(fontSize = if (compact) 22.sp else 34.sp, lineHeight = if (compact) 26.sp else 40.sp),
        )
        Text(text = caption, style = OV2.caption, maxLines = 1)
    }
}

// MARK: - Small shared pieces

/** White ring, green disc, white tick: the « done » badge of the quiz squares and the account. */
@Composable
internal fun CheckBadge(size: Dp, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .size(size)
            .shadow(4.dp, CircleShape)
            .background(Color.White, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier.size(size - 5.dp).background(OV2.success, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(size * 0.45f))
        }
    }
}

/** The page dots under the presentation pages: current one in ink, the others faded. */
@Composable
internal fun PagerDots(count: Int, current: Int, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        repeat(count) { i ->
            val scale by animateFloatAsState(
                targetValue = if (i == current) 1f else 0.85f,
                animationSpec = spring(dampingRatio = 0.8f, stiffness = Spring.StiffnessMedium),
                label = "pagerDot",
            )
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .graphicsLayer { scaleX = scale; scaleY = scale }
                    .background(if (i == current) OV2.ink else OV2.ink.copy(alpha = 0.18f), CircleShape),
            )
        }
    }
}

// MARK: - Confetti

private class ConfettiPiece(
    val angle: Float,
    val speed: Float,
    val spin: Float,
    val color: Color,
    val width: Float,
    val height: Float,
    val delay: Float,
)

/**
 * A single burst of paper from [origin] (fractions of the box), falling under gravity and
 * fading out over [durationMillis]. Plays once.
 */
@Composable
internal fun ConfettiBurst(
    colors: List<Color>,
    modifier: Modifier = Modifier,
    pieceCount: Int = 70,
    durationMillis: Int = 3000,
    origin: Offset = Offset(0.5f, 0.32f),
) {
    val pieces = remember {
        val random = Random(42)
        List(pieceCount) {
            ConfettiPiece(
                angle = (-160f + random.nextFloat() * 140f),
                speed = 0.55f + random.nextFloat() * 0.75f,
                spin = (random.nextFloat() - 0.5f) * 1440f,
                color = colors[it % colors.size],
                width = 6f + random.nextFloat() * 6f,
                height = 9f + random.nextFloat() * 8f,
                delay = random.nextFloat() * 0.12f,
            )
        }
    }
    val progress = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        progress.animateTo(1f, tween(durationMillis, easing = LinearEasing))
    }
    Canvas(modifier = modifier.fillMaxSize()) {
        val t = progress.value
        if (t >= 1f) return@Canvas
        val start = Offset(size.width * origin.x, size.height * origin.y)
        val reach = size.minDimension
        val density = density
        pieces.forEach { piece ->
            val local = ((t - piece.delay) / (1f - piece.delay)).coerceIn(0f, 1f)
            if (local <= 0f) return@forEach
            val seconds = local * durationMillis / 1000f
            val rad = Math.toRadians(piece.angle.toDouble())
            val vx = cos(rad).toFloat() * piece.speed * reach * 0.9f
            val vy = sin(rad).toFloat() * piece.speed * reach * 1.1f
            val gravity = reach * 0.75f
            val x = start.x + vx * seconds * (1f - local * 0.35f)
            val y = start.y + vy * seconds + gravity * seconds * seconds
            val alpha = if (local < 0.7f) 1f else (1f - (local - 0.7f) / 0.3f)
            rotate(degrees = piece.spin * local, pivot = Offset(x, y)) {
                drawRect(
                    color = piece.color.copy(alpha = alpha.coerceIn(0f, 1f)),
                    topLeft = Offset(x - piece.width * density / 2f, y - piece.height * density / 2f),
                    size = Size(piece.width * density, piece.height * density),
                )
            }
        }
    }
}
