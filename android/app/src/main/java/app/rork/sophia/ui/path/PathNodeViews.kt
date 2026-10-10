package app.rork.sophia.ui.path

import android.os.Build
import android.view.HapticFeedbackConstants
import android.view.View
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.Crossfade
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.EmojiEvents
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
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathMeasure
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
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
import app.rork.sophia.ui.collections.CollectionCover
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.domain.uppercaseIn
import kotlin.math.PI
import kotlin.math.sin

// MARK: - Layout

/**
 * Geometry of the trail: pods stacked in rows, each row shifted along a sine wave so the
 * trail winds down the screen. Everything is derived from the row index, so the connectors
 * can be drawn without measuring the pods. Same numbers as iOS.
 */
internal object PathLayout {
    val podSize = 74.dp
    val quizPodSize = 92.dp
    val plateDepth = 7.dp
    /** Height reserved for a pod and its plate, whatever its size, so centres line up. */
    val podAreaHeight = 100.dp
    /** Pod area plus the caption underneath. */
    val rowHeight = 138.dp
    val waveAmplitude = 84.dp
    val bannerHeight = 176.dp
    /** Between a level's banner and its trail. */
    val bannerSpacing = 18.dp
    /** Room above the first pod for its "start" bubble. */
    val trailTopPadding = 30.dp

    fun xOffset(step: Int): Dp = waveAmplitude * sin(step * PI / 4).toFloat()

    /** Centre of the pod face in row [step], from the top-left corner of the trail. */
    fun DrawScope.center(step: Int, phase: Int): Offset = Offset(
        x = size.width / 2f + xOffset(step + phase).toPx(),
        y = (rowHeight * step).toPx() + ((podAreaHeight - plateDepth) / 2).toPx(),
    )

    /** Top of row [index]'s pod face centre, measured from the top of the level section. */
    fun nodeCenterInSection(index: Int): Dp =
        bannerHeight + bannerSpacing + trailTopPadding + rowHeight * index + (podAreaHeight - plateDepth) / 2
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

// MARK: - Haptics

internal enum class PathHaptic { Tick, Tap, Confirm, Reject, Heavy }

/** The closest Android has to the iOS feedback generators the path plays. */
internal fun View.pathHaptic(kind: PathHaptic) {
    val constant = when (kind) {
        PathHaptic.Tick -> HapticFeedbackConstants.CLOCK_TICK
        PathHaptic.Tap -> HapticFeedbackConstants.KEYBOARD_TAP
        PathHaptic.Confirm ->
            if (Build.VERSION.SDK_INT >= 30) HapticFeedbackConstants.CONFIRM else HapticFeedbackConstants.VIRTUAL_KEY
        PathHaptic.Reject ->
            if (Build.VERSION.SDK_INT >= 30) HapticFeedbackConstants.REJECT else HapticFeedbackConstants.LONG_PRESS
        PathHaptic.Heavy -> HapticFeedbackConstants.LONG_PRESS
    }
    performHapticFeedback(constant)
}

/** Horizontal rattle: [shakes] goes up by one per rattle, the offset is a sine of it. */
internal fun shakeOffset(shakes: Float, amplitudePx: Float): Float =
    amplitudePx * sin(shakes * PI.toFloat() * 4f)

// MARK: - Pod

/**
 * A round button on a thick rim; pressing it sinks the face onto the rim. Course pods take
 * their subject colour once completed, are ringed while they are the one to play and greyed
 * while locked; the quiz pod is a golden trophy.
 */
@Composable
internal fun PathPod(
    node: PathNode,
    state: PathNodeState,
    isCurrent: Boolean,
    isPopping: Boolean,
    shakes: () -> Float,
    startLabel: String,
    onTap: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val diameter = if (node.isQuiz) PathLayout.quizPodSize else PathLayout.podSize
    val tint = node.tint()
    val plateTarget = when (state) {
        PathNodeState.LOCKED -> PathPalette.lockedPlate
        PathNodeState.AVAILABLE -> if (node.isQuiz) PathPalette.plate(PathPalette.gold) else PathPalette.availablePlate
        PathNodeState.COMPLETED -> PathPalette.plate(tint)
    }
    val plateColor by animateColorAsState(plateTarget, tween(350), label = "plate")
    val pop by animateFloatAsState(
        targetValue = if (isPopping) 1.16f else 1f,
        animationSpec = spring(dampingRatio = 0.55f, stiffness = 200f),
        label = "pop",
    )
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val sink by animateFloatAsState(
        targetValue = if (pressed) 1f else 0f,
        animationSpec = spring(dampingRatio = 0.75f, stiffness = 1200f),
        label = "sink",
    )
    val buttonTop = (PathLayout.podAreaHeight - diameter - PathLayout.plateDepth) / 2

    Box(modifier = modifier.height(PathLayout.podAreaHeight).width(132.dp)) {
        if (isCurrent) {
            PathPulseHalo(
                tint = tint,
                diameter = diameter,
                modifier = Modifier.align(Alignment.TopCenter).offset(y = buttonTop - diameter * 0.2f),
            )
        }
        Box(
            modifier = Modifier
                .align(Alignment.TopCenter)
                .offset(y = buttonTop)
                .graphicsLayer {
                    translationX = shakeOffset(shakes(), 7.dp.toPx())
                    scaleX = pop
                    scaleY = pop
                }
                .size(width = diameter, height = diameter + PathLayout.plateDepth)
                .clickable(interactionSource = interaction, indication = null, onClick = onTap),
        ) {
            Box(
                modifier = Modifier
                    .offset(y = PathLayout.plateDepth)
                    .size(diameter)
                    .clip(CircleShape)
                    .background(plateColor),
            )
            Box(modifier = Modifier.graphicsLayer { translationY = PathLayout.plateDepth.toPx() * sink }) {
                if (node.isQuiz) {
                    PathQuizPodFace(state = state, diameter = diameter)
                } else {
                    PathPodFace(
                        state = state,
                        tint = tint,
                        icon = node.course!!.subjectEnum.pathIcon,
                        diameter = diameter,
                    )
                }
            }
        }
        AnimatedVisibility(
            visible = isCurrent,
            modifier = Modifier
                .align(Alignment.TopCenter)
                .offset(y = buttonTop - 50.dp)
                .wrapContentSize(unbounded = true),
            enter = scaleIn(initialScale = 0.7f, transformOrigin = TransformOrigin(0.5f, 1f)) + fadeIn(),
            exit = fadeOut(),
        ) {
            PathStartBubble(text = startLabel, tint = tint)
        }
    }
}

@Composable
private fun PathPodFace(state: PathNodeState, tint: Color, icon: ImageVector, diameter: Dp) {
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
                    PathNodeState.LOCKED -> Modifier.border(1.dp, DS.hairline, CircleShape)
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

@Composable
private fun PathQuizPodFace(state: PathNodeState, diameter: Dp) {
    Box(modifier = Modifier.size(diameter)) {
        Crossfade(targetState = state == PathNodeState.LOCKED, animationSpec = tween(350), label = "quizFace") { locked ->
            Box(
                modifier = Modifier
                    .size(diameter)
                    .clip(CircleShape)
                    .then(
                        if (locked) {
                            Modifier.background(DS.surfaceMuted).border(1.dp, DS.hairline, CircleShape)
                        } else {
                            Modifier.background(PathPalette.goldGradient)
                        },
                    ),
                contentAlignment = Alignment.Center,
            ) {
                if (!locked) {
                    Box(
                        modifier = Modifier
                            .matchParentSize()
                            .padding(5.dp)
                            .border(2.dp, Color.White.copy(alpha = 0.45f), CircleShape),
                    )
                }
                Icon(
                    Icons.Filled.EmojiEvents,
                    contentDescription = null,
                    tint = if (locked) DS.inkTertiary else Color.White,
                    modifier = Modifier.size(diameter * 0.44f),
                )
            }
        }
        AnimatedVisibility(
            visible = state == PathNodeState.COMPLETED,
            modifier = Modifier.align(Alignment.BottomEnd).offset(x = 2.dp, y = 2.dp),
            enter = scaleIn() + fadeIn(),
            exit = scaleOut() + fadeOut(),
        ) {
            Box(
                modifier = Modifier.size(diameter * 0.32f).clip(CircleShape).background(Color.White),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    Icons.Filled.CheckCircle,
                    contentDescription = null,
                    tint = DS.success,
                    modifier = Modifier.size(diameter * 0.3f),
                )
            }
        }
    }
}

// MARK: - Start bubble and halo

/** The bobbing "start" call-out above the pod to play next. */
@Composable
private fun PathStartBubble(text: String, tint: Color) {
    val bob = rememberInfiniteTransition(label = "bubble")
    val lift by bob.animateFloat(
        initialValue = 3f,
        targetValue = -4f,
        animationSpec = infiniteRepeatable(tween(750, easing = FastOutSlowInEasing), RepeatMode.Reverse),
        label = "lift",
    )
    Column(
        modifier = Modifier.graphicsLayer { translationY = lift.dp.toPx() },
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 12.sp,
            letterSpacing = 1.2.sp,
            color = tint,
            maxLines = 1,
            softWrap = false,
            modifier = Modifier
                .shadow(
                    elevation = 8.dp,
                    shape = RoundedCornerShape(12.dp),
                    ambientColor = Color.Black.copy(alpha = 0.2f),
                    spotColor = Color.Black.copy(alpha = 0.2f),
                )
                .background(DS.surface, RoundedCornerShape(12.dp))
                .padding(horizontal = 14.dp, vertical = 9.dp),
        )
        Canvas(modifier = Modifier.offset(y = (-1).dp).size(width = 16.dp, height = 8.dp)) {
            val pointer = Path().apply {
                moveTo(0f, 0f)
                lineTo(size.width, 0f)
                lineTo(size.width / 2f, size.height)
                close()
            }
            drawPath(pointer, DS.surface)
        }
    }
}

/** Soft breathing glow behind the pod to play next. */
@Composable
private fun PathPulseHalo(tint: Color, diameter: Dp, modifier: Modifier = Modifier) {
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

// MARK: - Connectors

/**
 * The faint line under all the pods of a level, and over it each connector filled in the
 * colour of the pod it leaves once that pod is done, or as far as [segmentFills] says
 * while the fill is being animated.
 */
@Composable
internal fun PathTrailCanvas(
    level: PathLevel,
    shownState: (PathNode) -> PathNodeState,
    segmentFills: Map<String, Float>,
    modifier: Modifier = Modifier,
) {
    val base = DS.hairline
    val accent = DS.accent
    Canvas(modifier = modifier) {
        val stroke = Stroke(width = 4.dp.toPx(), cap = StrokeCap.Round)
        val count = level.nodes.size
        if (count < 2) return@Canvas
        val phase = level.wavePhase
        val trail = Path()
        for (index in 0 until count - 1) addSegment(trail, index, phase)
        drawPath(trail, base, style = stroke)

        for (index in 0 until count - 1) {
            val node = level.nodes[index]
            val fill = segmentFills[node.id] ?: if (shownState(node) == PathNodeState.COMPLETED) 1f else 0f
            if (fill <= 0f) continue
            val segment = Path().also { addSegment(it, index, phase) }
            val color = if (node.isQuiz) accent else node.tint()
            if (fill >= 1f) {
                drawPath(segment, color, style = stroke)
            } else {
                val measure = PathMeasure()
                measure.setPath(segment, false)
                val partial = Path()
                measure.getSegment(0f, measure.length * fill, partial, true)
                drawPath(partial, color, style = stroke)
            }
        }
    }
}

private fun DrawScope.addSegment(path: Path, index: Int, phase: Int) {
    with(PathLayout) {
        val start = center(index, phase)
        val end = center(index + 1, phase)
        val midY = (start.y + end.y) / 2f
        path.moveTo(start.x, start.y)
        path.cubicTo(start.x, midY, end.x, midY, end.x, end.y)
    }
}

// MARK: - Level banner

/**
 * Header of a level: the collection cover with its number and title centred on it. Greyed
 * under a padlock while locked; a golden chip once the level is passed. [retract] (0 to 1)
 * shrinks and fades it as it slides under the top bar.
 */
@Composable
internal fun PathLevelBanner(
    level: PathLevel,
    isUnlocked: Boolean,
    isPassed: Boolean,
    language: AppLanguage,
    lockShakes: () -> Float,
    retract: () -> Float,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val saturation by animateFloatAsState(if (isUnlocked) 1f else 0f, tween(600), label = "saturation")
    val coverAlpha by animateFloatAsState(if (isUnlocked) 1f else 0.55f, tween(600), label = "coverAlpha")
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
            .height(PathLayout.bannerHeight)
            .graphicsLayer {
                val r = retract()
                val scale = 1f - 0.06f * r
                scaleX = scale
                scaleY = scale
                alpha = 1f - 0.35f * r
                transformOrigin = TransformOrigin(0.5f, 0f)
            }
            .shadow(
                elevation = 8.dp,
                shape = DS.cardShape,
                ambientColor = Color.Black.copy(alpha = 0.24f),
                spotColor = Color.Black.copy(alpha = 0.2f),
            )
            .clip(DS.cardShape),
    ) {
        CollectionCover(
            collection = level.collection,
            accentIndex = level.number - 1,
            modifier = Modifier
                .matchParentSize()
                .saturation(saturation)
                .graphicsLayer { alpha = coverAlpha },
        )
        Box(
            modifier = Modifier
                .matchParentSize()
                .background(
                    Brush.verticalGradient(
                        listOf(
                            Color.Black.copy(alpha = 0.30f),
                            Color.Black.copy(alpha = 0.46f),
                            Color.Black.copy(alpha = 0.62f),
                        ),
                    ),
                ),
        )
        val textShadow = Shadow(color = Color.Black.copy(alpha = 0.35f), offset = Offset(0f, 4f), blurRadius = 16f)
        Column(
            modifier = Modifier
                .align(Alignment.Center)
                .fillMaxWidth()
                .padding(horizontal = 24.dp, vertical = 36.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Text(
                text = caption,
                style = TextStyle(
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 11.sp,
                    letterSpacing = 1.2.sp,
                    color = Color.White.copy(alpha = 0.85f),
                    shadow = textShadow,
                ),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                text = level.collection.title,
                style = TextStyle(
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 22.sp,
                    lineHeight = 27.sp,
                    color = Color.White,
                    textAlign = TextAlign.Center,
                    shadow = textShadow,
                ),
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
        AnimatedVisibility(
            visible = isPassed,
            modifier = Modifier.align(Alignment.TopEnd).padding(12.dp),
            enter = fadeIn(tween(350)) + scaleIn(initialScale = 0.8f),
            exit = fadeOut(tween(350)),
        ) {
            Row(
                modifier = Modifier
                    .clip(CircleShape)
                    .background(Color.Black.copy(alpha = 0.4f))
                    .padding(horizontal = 10.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(5.dp),
            ) {
                Icon(Icons.Filled.Verified, contentDescription = null, tint = PathPalette.gold, modifier = Modifier.size(12.dp))
                Text(
                    text = StringStore.text(context, "path.status.passed", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 11.sp,
                    color = PathPalette.gold,
                    maxLines = 1,
                )
            }
        }
        // The padlock: rattles on demand, then flies off when the level opens.
        AnimatedVisibility(
            visible = !isUnlocked && !isPassed,
            modifier = Modifier.align(Alignment.TopEnd).padding(12.dp),
            enter = fadeIn(),
            exit = scaleOut(targetScale = 1.6f, animationSpec = tween(600)) +
                fadeOut(tween(600)) +
                slideOutVertically(tween(600)) { -it },
        ) {
            Box(
                modifier = Modifier
                    .graphicsLayer { translationX = shakeOffset(lockShakes(), 6.dp.toPx()) }
                    .size(46.dp)
                    .clip(CircleShape)
                    .background(Color.Black.copy(alpha = 0.45f))
                    .border(1.dp, Color.White.copy(alpha = 0.35f), CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Filled.Lock, contentDescription = null, tint = Color.White, modifier = Modifier.size(20.dp))
            }
        }
        Box(
            modifier = Modifier
                .matchParentSize()
                .border(1.dp, Color.White.copy(alpha = 0.14f), DS.cardShape),
        )
    }
}

/** Draws the content desaturated ([value] 0 is greyscale); no-op at full saturation. */
private fun Modifier.saturation(value: Float): Modifier =
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
