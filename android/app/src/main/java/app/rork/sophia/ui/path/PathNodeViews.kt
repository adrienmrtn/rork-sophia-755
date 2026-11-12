package app.rork.sophia.ui.path

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.Crossfade
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Palette
import androidx.compose.material.icons.filled.Public
import androidx.compose.material.icons.filled.Science
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.PathLevel
import app.rork.sophia.domain.PathNode
import app.rork.sophia.domain.PathNodeState
import app.rork.sophia.domain.Subject
import app.rork.sophia.domain.uppercaseIn
import app.rork.sophia.ui.collections.CollectionCover
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlin.math.PI
import kotlin.math.sin

// The Parcours tab draws its levels as a zigzag of cards (`PathCardViews.kt`). This file
// keeps what the cards share with the round pods of the previous trail, which live on for
// the onboarding preview: the palette, the subject icons, the pod face, the halo, and the
// banner of a level.

// MARK: - Layout

/** Sizes of the round pods. Same numbers as iOS. */
internal object PathLayout {
    val podSize = 74.dp
    val quizPodSize = 92.dp
    val plateDepth = 7.dp

    /** Height reserved for a pod and its plate, whatever its size, so centres line up. */
    val podAreaHeight = 100.dp
    val waveAmplitude = 84.dp

    fun xOffset(step: Int): Dp = waveAmplitude * sin(step * PI / 4).toFloat()
}

// MARK: - Palette

/** The app's calm palette, tinted by subject on the pods; gold is kept for the quiz. */
internal object PathPalette {
    val gold = Color(red = 0.93f, green = 0.70f, blue = 0.18f)

    val goldGradient: Brush
        get() = Brush.linearGradient(listOf(lerp(gold, Color.White, 0.22f), gold))

    fun tint(subject: Subject): Color = lerp(subject.color, Color.Black, 0.08f)

    /** The darker rim drawn under a pod, giving it its thickness. */
    fun plate(fill: Color): Color = lerp(fill, Color.Black, 0.3f)

    val availablePlate: Color get() = lerp(DS.hairline, DS.inkTertiary, 0.45f)

    val lockedPlate: Color get() = DS.hairline
}

/** Material twins of the iOS subject symbols. */
internal val Subject.pathIcon: ImageVector
    get() = when (this) {
        Subject.HISTOIRE -> Icons.Filled.AccountBalance
        Subject.SCIENCES -> Icons.Filled.Science
        Subject.LITTERATURE -> Icons.AutoMirrored.Filled.MenuBook
        Subject.ART -> Icons.Filled.Palette
        Subject.MYTHOLOGIE -> Icons.Filled.Bolt
        Subject.COMPRENDRE_LE_MONDE -> Icons.Filled.Public
    }

internal fun PathNode.tint(): Color = course?.let { PathPalette.tint(it.subjectEnum) } ?: PathPalette.gold

// MARK: - Shake

/** Horizontal rattle: [shakes] goes up by one per rattle, the offset is a sine of it. */
internal fun shakeOffset(shakes: Float, amplitudePx: Float): Float =
    amplitudePx * sin(shakes * PI.toFloat() * 4f)

// MARK: - Pod face

/**
 * Face of a course pod: filled with the subject colour once completed, ringed while it is
 * the one to play, greyed while locked.
 */
@Composable
internal fun PathPodFace(state: PathNodeState, tint: Color, icon: ImageVector, diameter: Dp) {
    val fill by animateColorAsState(
        targetValue = when (state) {
            PathNodeState.COMPLETED -> tint
            PathNodeState.AVAILABLE -> DS.surface
            PathNodeState.LOCKED -> DS.surfaceMuted
        },
        animationSpec = tween(350),
        label = "podFill",
    )
    Box(
        modifier = Modifier
            .size(diameter)
            .clip(CircleShape)
            .background(fill)
            .then(
                when (state) {
                    PathNodeState.AVAILABLE -> Modifier.border(4.dp, tint, CircleShape)
                    PathNodeState.LOCKED -> Modifier.border(1.5.dp, DS.hairline, CircleShape)
                    PathNodeState.COMPLETED -> Modifier
                },
            ),
        contentAlignment = Alignment.Center,
    ) {
        Crossfade(targetState = state, animationSpec = tween(250), label = "podIcon") { shown ->
            Icon(
                imageVector = when (shown) {
                    PathNodeState.COMPLETED -> Icons.Filled.Check
                    PathNodeState.AVAILABLE -> icon
                    PathNodeState.LOCKED -> Icons.Filled.Lock
                },
                contentDescription = null,
                tint = when (shown) {
                    PathNodeState.COMPLETED -> Color.White
                    PathNodeState.AVAILABLE -> tint
                    PathNodeState.LOCKED -> DS.inkTertiary
                },
                modifier = Modifier.size(diameter * 0.4f),
            )
        }
    }
}

// MARK: - Halo

/** Soft breathing glow behind the pod to play next. */
@Composable
internal fun PathPulseHalo(tint: Color, diameter: Dp, modifier: Modifier = Modifier) {
    val breath = rememberInfiniteTransition(label = "halo")
    val expanded by breath.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(1300, easing = FastOutSlowInEasing), RepeatMode.Reverse),
        label = "expanded",
    )
    Box(
        modifier = modifier
            .size(diameter * 1.4f)
            .graphicsLayer {
                val scale = 0.9f + 0.22f * expanded
                scaleX = scale
                scaleY = scale
                alpha = 0.95f - 0.6f * expanded
            }
            .clip(CircleShape)
            .background(tint.copy(alpha = 0.22f)),
    )
}

// MARK: - Level banner

/**
 * Header of a level: the collection cover under a night-blue veil, with the level's number,
 * its progress and its title at the bottom. A chip tells once the level is passed. Levels
 * still locked are not drawn with it: the trail folds them into a [PathLockedLevelCard].
 */
@Composable
internal fun PathLevelBanner(
    level: PathLevel,
    isPassed: Boolean,
    language: AppLanguage,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val caption = remember(level.number, level.completedCourseCount, level.courseCount, language) {
        val levelText = StringStore.text(context, "path.levelCaption", language, level.number)
        val coursesText = StringStore.text(
            context, "path.courses.count", language, level.completedCourseCount, level.courseCount,
        )
        "$levelText · $coursesText".uppercaseIn(language)
    }
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(PathCardLayout.bannerHeight)
            .clip(DS.cardShape),
    ) {
        CollectionCover(
            collection = level.collection,
            accentIndex = level.number - 1,
            modifier = Modifier.matchParentSize(),
        )
        Box(modifier = Modifier.matchParentSize().background(PathCardPalette.bannerVeil.copy(alpha = 0.55f)))
        Column(
            modifier = Modifier
                .align(Alignment.BottomStart)
                .fillMaxWidth()
                .padding(start = 16.dp, end = 16.dp, bottom = 12.dp),
            verticalArrangement = Arrangement.spacedBy(3.dp),
        ) {
            Text(
                text = caption,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 12.sp,
                letterSpacing = 1.sp,
                color = Color.White,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                text = level.collection.title,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 19.sp,
                lineHeight = 23.sp,
                color = Color.White,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
        AnimatedVisibility(
            visible = isPassed,
            modifier = Modifier.align(Alignment.TopEnd).padding(10.dp),
            enter = fadeIn() + scaleIn(DSMotion.pop(), initialScale = 0.6f, transformOrigin = TransformOrigin(1f, 0f)),
            exit = fadeOut(tween(350)),
        ) {
            Row(
                modifier = Modifier
                    .clip(RoundedCornerShape(10.dp))
                    .background(Color.White)
                    .padding(horizontal = 10.dp, vertical = 5.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(5.dp),
            ) {
                Icon(Icons.Filled.Verified, contentDescription = null, tint = DS.success, modifier = Modifier.size(12.dp))
                Text(
                    text = StringStore.text(context, "path.status.passed", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 11.sp,
                    color = DS.success,
                    maxLines = 1,
                )
            }
        }
    }
}

/** Draws the content desaturated ([value] 0 is greyscale); no-op at full saturation. */
internal fun Modifier.pathSaturation(value: Float): Modifier =
    if (value >= 0.999f) {
        this
    } else {
        drawWithContent {
            val paint = Paint().apply {
                colorFilter = ColorFilter.colorMatrix(ColorMatrix().apply { setToSaturation(value) })
            }
            drawIntoCanvas { canvas ->
                canvas.saveLayer(Rect(Offset.Zero, size), paint)
                drawContent()
                canvas.restore()
            }
        }
    }
