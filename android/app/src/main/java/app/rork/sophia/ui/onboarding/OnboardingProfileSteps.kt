package app.rork.sophia.ui.onboarding

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.HowToReg
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.legal.LegalDocKind
import app.rork.sophia.ui.legal.LegalDocumentScreen
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.Locale
import kotlin.math.abs
import kotlin.math.min

/** Tinder-style deck: drag a card left or right, or use the two buttons. */
@Composable
internal fun SwipeCoursesStep(
    language: AppLanguage,
    courses: List<CourseSummary>,
    ready: Boolean,
    onFinished: (likedIds: List<String>) -> Unit,
) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    val scope = rememberCoroutineScope()
    val density = LocalDensity.current
    var index by remember { mutableIntStateOf(0) }
    var liked by remember { mutableStateOf(listOf<String>()) }
    var done by remember { mutableStateOf(false) }
    var finishing by remember { mutableStateOf(false) }
    var crossedThreshold by remember { mutableStateOf(false) }
    val dragX = remember { Animatable(0f) }
    var enter by remember { mutableStateOf(false) }

    LaunchedEffect(ready) {
        if (ready) {
            delay(150)
            enter = true
        }
    }
    val enterProgress by animateFloatAsState(
        targetValue = if (enter) 1f else 0f,
        animationSpec = spring(dampingRatio = 0.74f, stiffness = Spring.StiffnessMediumLow),
        label = "deckEnter",
    )

    if (courses.isEmpty() && ready) {
        LaunchedEffect(Unit) { onFinished(emptyList()) }
    }

    fun commit(like: Boolean) {
        if (finishing || done || index >= courses.size) return
        val course = courses[index]
        val isLast = index == courses.lastIndex
        if (isLast) finishing = true
        haptics.commit()
        scope.launch {
            val target = with(density) { if (like) 600.dp.toPx() else (-600).dp.toPx() }
            dragX.animateTo(target, tween(240))
            if (like) liked = liked + course.id
            index += 1
            dragX.snapTo(0f)
            if (isLast) {
                done = true
                delay(1400)
                onFinished(liked)
            }
        }
    }

    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.height(72.dp))
        Column(modifier = Modifier.padding(horizontal = 28.dp).ov2Reveal(100)) {
            Text(
                text = StringStore.text(context, "onboardingV2.swipe.title", language),
                style = OV2.title.copy(fontSize = 24.sp),
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth(),
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = StringStore.text(context, "onboardingV2.swipe.subtitle", language),
                style = OV2.subheadline,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth(),
            )
        }
        Spacer(Modifier.weight(1f))

        if (!ready) {
            CircularProgressIndicator(color = OV2.accent)
        } else if (done) {
            SwipeCompletion(language = language)
        } else {
            BoxWithConstraints(
                modifier = Modifier.fillMaxWidth(),
                contentAlignment = Alignment.Center,
            ) {
                val cardWidth = minOf(300.dp, maxWidth - 56.dp)
                val cardHeight = cardWidth * 4 / 3
                val thresholdPx = with(density) { 100.dp.toPx() }
                Box(
                    modifier = Modifier
                        .size(cardWidth, cardHeight)
                        .graphicsLayer {
                            scaleX = 0.86f + 0.14f * enterProgress
                            scaleY = 0.86f + 0.14f * enterProgress
                            alpha = enterProgress
                            translationY = (1f - enterProgress) * 64f
                            rotationZ = (1f - enterProgress) * -4f
                        },
                ) {
                    for (depth in 2 downTo 0) {
                        val course = courses.getOrNull(index + depth) ?: continue
                        val top = depth == 0
                        Box(
                            modifier = Modifier
                                .fillMaxSize()
                                .graphicsLayer {
                                    if (top) {
                                        translationX = dragX.value
                                        rotationZ = dragX.value / 24f
                                    } else {
                                        scaleX = 1f - depth * 0.04f
                                        scaleY = 1f - depth * 0.04f
                                        translationY = depth * 12.dp.toPx()
                                    }
                                }
                                .then(
                                    if (!top) Modifier else Modifier.pointerInput(index, courses) {
                                        detectHorizontalDragGestures(
                                            onDragEnd = {
                                                crossedThreshold = false
                                                if (abs(dragX.value) > thresholdPx) {
                                                    commit(dragX.value > 0)
                                                } else {
                                                    scope.launch {
                                                        dragX.animateTo(
                                                            0f,
                                                            spring(dampingRatio = 0.7f),
                                                        )
                                                    }
                                                }
                                            },
                                            onDragCancel = {
                                                crossedThreshold = false
                                                scope.launch { dragX.animateTo(0f, spring(dampingRatio = 0.7f)) }
                                            },
                                        ) { _, amount ->
                                            scope.launch { dragX.snapTo(dragX.value + amount) }
                                            val crossed = abs(dragX.value) > thresholdPx
                                            if (crossed != crossedThreshold) {
                                                crossedThreshold = crossed
                                                if (crossed) haptics.selection()
                                            }
                                        }
                                    },
                                ),
                        ) {
                            SwipeCard(
                                course = course,
                                language = language,
                                // Read per frame inside graphicsLayer, never during
                                // composition: dragging must not recompose the card.
                                stampProgress = if (top) {
                                    { (abs(dragX.value) / thresholdPx).coerceIn(0f, 1f) }
                                } else {
                                    { 0f }
                                },
                                stampDirection = { dragX.value },
                            )
                        }
                    }
                }
            }
        }

        Spacer(Modifier.weight(1f))
        if (!done) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(40.dp),
                modifier = Modifier.padding(bottom = 40.dp).ov2Reveal(300),
            ) {
                SwipeActionButton(like = false, enabled = ready) { commit(false) }
                SwipeActionButton(like = true, enabled = ready) { commit(true) }
            }
        } else {
            Spacer(Modifier.height(104.dp))
        }
    }
}

@Composable
private fun SwipeCard(
    course: CourseSummary,
    language: AppLanguage,
    stampProgress: () -> Float,
    stampDirection: () -> Float,
) {
    val context = LocalContext.current
    Box(
        modifier = Modifier
            .fillMaxSize()
            .clip(RoundedCornerShape(24.dp))
            .background(OV2.surface)
            .border(1.dp, OV2.hairline, RoundedCornerShape(24.dp)),
    ) {
        CourseImage(
            courseId = course.id,
            modifier = Modifier.fillMaxSize(),
            contentScale = ContentScale.Crop,
            maxEdgePx = 720,
        )
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        0.35f to Color.Transparent,
                        0.7f to Color.Black.copy(alpha = 0.28f),
                        1f to Color.Black.copy(alpha = 0.78f),
                    ),
                ),
        )
        Column(
            modifier = Modifier
                .align(Alignment.BottomStart)
                .padding(18.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Text(
                text = StringStore.text(
                    context,
                    "subject.${course.subjectEnum.storageKey}.short",
                    language,
                ).uppercase(Locale.getDefault()),
                style = OV2.caption.copy(fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color.White),
                modifier = Modifier
                    .clip(CircleShape)
                    .background(Color.White.copy(alpha = 0.22f))
                    .padding(horizontal = 10.dp, vertical = 5.dp),
            )
            Text(
                text = course.title,
                style = OV2.headline.copy(fontSize = 20.sp, lineHeight = 26.sp, color = Color.White),
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
            )
        }
        SwipeStamp(
            text = StringStore.text(context, "onboardingV2.swipe.like", language),
            color = OV2.success,
            rotation = -12f,
            alignment = Alignment.TopStart,
            alpha = { if (stampDirection() > 0f) stampProgress() else 0f },
        )
        SwipeStamp(
            text = StringStore.text(context, "onboardingV2.swipe.nope", language),
            color = OV2.danger,
            rotation = 12f,
            alignment = Alignment.TopEnd,
            alpha = { if (stampDirection() < 0f) stampProgress() else 0f },
        )
    }
}

@Composable
private fun androidx.compose.foundation.layout.BoxScope.SwipeStamp(
    text: String,
    color: Color,
    rotation: Float,
    alignment: Alignment,
    alpha: () -> Float,
) {
    Text(
        text = text.uppercase(Locale.getDefault()),
        style = OV2.title.copy(fontSize = 22.sp, color = color),
        modifier = Modifier
            .align(alignment)
            .padding(18.dp)
            .graphicsLayer {
                this.alpha = alpha()
                rotationZ = rotation
            }
            .border(3.dp, color, RoundedCornerShape(10.dp))
            .padding(horizontal = 12.dp, vertical = 6.dp),
    )
}

@Composable
private fun SwipeActionButton(like: Boolean, enabled: Boolean, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .size(64.dp)
            .clip(CircleShape)
            .background(OV2.surface)
            .border(1.dp, OV2.hairline, CircleShape)
            .clickable(enabled = enabled, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector = if (like) Icons.Filled.Favorite else Icons.Filled.Close,
            contentDescription = null,
            tint = if (like) OV2.success else OV2.danger,
            modifier = Modifier.size(26.dp),
        )
    }
}

@Composable
private fun SwipeCompletion(language: AppLanguage) {
    val context = LocalContext.current
    var checkIn by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(150)
        checkIn = true
    }
    val scale by animateFloatAsState(
        targetValue = if (checkIn) 1f else 0.4f,
        animationSpec = spring(dampingRatio = 0.6f, stiffness = Spring.StiffnessMediumLow),
        label = "check",
    )
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        OnboardingCircleBadge(size = 120.dp, background = OV2.success.copy(alpha = 0.12f)) {
            Icon(
                Icons.Filled.Check,
                contentDescription = null,
                tint = OV2.success,
                modifier = Modifier
                    .size(56.dp)
                    .graphicsLayer { scaleX = scale; scaleY = scale; alpha = scale },
            )
        }
        Text(
            text = StringStore.text(context, "onboardingV2.swipe.noted", language),
            style = OV2.title.copy(fontSize = 24.sp),
            modifier = Modifier.alpha(scale),
        )
    }
}

/** Three staged steps with real progress bars, then the App Store style rating. */
@Composable
internal fun LoadingProfileStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    val progress = remember { List(3) { Animatable(0f) } }
    var completed by remember { mutableStateOf(listOf(false, false, false)) }
    var allDone by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        repeat(3) { i ->
            progress[i].animateTo(1f, tween(1000))
            completed = completed.toMutableList().also { it[i] = true }
            haptics.selection()
            delay(100)
        }
        haptics.commit()
        allDone = true
    }
    val ratingAlpha by animateFloatAsState(if (allDone) 1f else 0.4f, tween(300), label = "rating")

    Column(modifier = Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(Modifier.height(84.dp))
        Text(
            text = StringStore.text(context, "onboardingV2.loading.title", language),
            style = OV2.title,
            textAlign = TextAlign.Center,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 28.dp)
                .ov2Reveal(50),
        )
        Spacer(Modifier.height(40.dp))
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 32.dp),
            verticalArrangement = Arrangement.spacedBy(22.dp),
        ) {
            repeat(3) { i ->
                LoadingStepRow(
                    label = StringStore.text(context, "onboardingV2.loading.step${i + 1}", language),
                    progress = progress[i].value,
                    done = completed[i],
                )
            }
        }
        Spacer(Modifier.height(32.dp))
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.alpha(ratingAlpha),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("4.8/5", style = OV2.headline)
                Text("★★★★★", color = OV2.warm, fontSize = 13.sp)
            }
            Spacer(Modifier.height(4.dp))
            Text(
                text = StringStore.text(context, "onboardingV2.loading.reviews", language),
                style = OV2.caption,
            )
        }
        Spacer(Modifier.weight(1f))
        OnboardingCta(
            text = StringStore.text(context, "onboardingV2.loading.cta", language),
            onClick = onContinue,
            enabled = allDone,
        )
    }
}

@Composable
private fun LoadingStepRow(label: String, progress: Float, done: Boolean) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        OnboardingCircleBadge(
            size = 34.dp,
            background = if (done) OV2.success else OV2.accent.copy(alpha = 0.12f),
        ) {
            if (done) {
                Icon(
                    Icons.Filled.Check,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(18.dp),
                )
            } else {
                CircularProgressIndicator(
                    color = OV2.accent,
                    strokeWidth = 2.dp,
                    modifier = Modifier.size(18.dp),
                )
            }
        }
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(text = label, style = OV2.subheadline.copy(color = OV2.ink, fontWeight = FontWeight.SemiBold))
            LinearProgressIndicator(
                progress = { progress },
                modifier = Modifier.fillMaxWidth().clip(CircleShape),
                color = OV2.accent,
                trackColor = OV2.hairline,
                strokeCap = StrokeCap.Round,
            )
        }
    }
}

private data class ProfileMetrics(
    val topSpacing: Dp,
    val sectionSpacing: Dp,
    val badge: Dp,
    val emojiSp: Int,
    val cardWidth: Dp,
    val cardHeight: Dp,
) {
    companion object {
        val Regular = ProfileMetrics(44.dp, 22.dp, 116.dp, 52, 168.dp, 214.dp)
        val Compact = ProfileMetrics(16.dp, 16.dp, 92.dp, 42, 148.dp, 188.dp)

        fun fitting(heightDp: Dp): ProfileMetrics = if (heightDp < 740.dp) Compact else Regular
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun ProfileRewardStep(
    language: AppLanguage,
    objectiveKeys: List<String>,
    likedCourseIds: List<String>,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val archetype = objectiveKeys.firstOrNull() ?: "cultivate"
    val objectives = objectiveKeys.ifEmpty { listOf(archetype) }
    val excluded = likedCourseIds.toSet()
    var awaitingCourses by remember(language, likedCourseIds) {
        mutableStateOf<List<CourseSummary>>(emptyList())
    }
    LaunchedEffect(language, likedCourseIds) {
        awaitingCourses = ContentCatalog.summariesAsync(context.applicationContext, language)
            .filter { it.id !in excluded }
            .shuffled()
            .take(5)
    }

    var badgeIn by remember { mutableStateOf(false) }
    var nameRevealed by remember { mutableStateOf(false) }
    var reveal by remember { mutableIntStateOf(0) }
    var ctaVisible by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(200)
        badgeIn = true
        delay(350)
        nameRevealed = true
        delay(450)
        reveal = 1
        delay(450)
        reveal = 2
        delay(250)
        ctaVisible = true
    }
    val badgeScale by animateFloatAsState(
        targetValue = if (badgeIn) 1f else 0.4f,
        animationSpec = spring(dampingRatio = 0.65f, stiffness = Spring.StiffnessMediumLow),
        label = "badge",
    )
    val nameAlpha by animateFloatAsState(if (nameRevealed) 1f else 0f, tween(400), label = "name")
    val objAlpha by animateFloatAsState(if (reveal >= 1) 1f else 0f, tween(400), label = "obj")
    val coursesAlpha by animateFloatAsState(if (reveal >= 2) 1f else 0f, tween(400), label = "courses")
    val ctaAlpha by animateFloatAsState(if (ctaVisible) 1f else 0f, tween(400), label = "cta")

    BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
        val metrics = ProfileMetrics.fitting(maxHeight)
        Column(modifier = Modifier.fillMaxSize()) {
            Column(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Spacer(Modifier.height(metrics.topSpacing))
                Box(
                    modifier = Modifier
                        .size(metrics.badge)
                        .graphicsLayer { scaleX = badgeScale; scaleY = badgeScale }
                        .clip(CircleShape)
                        .background(OV2.accent.copy(alpha = 0.10f))
                        .border(1.dp, OV2.accent.copy(alpha = 0.18f), CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(OBJECTIVE_EMOJI[archetype] ?: "📚", fontSize = metrics.emojiSp.sp)
                }
                Spacer(Modifier.height(16.dp))
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.padding(horizontal = 28.dp).alpha(nameAlpha),
                ) {
                    Text(
                        text = StringStore.text(context, "onboardingV2.profile.eyebrow", language)
                            .uppercase(Locale.getDefault()),
                        style = OV2.caption.copy(color = OV2.accentSoft),
                        letterSpacing = 1.2.sp,
                    )
                    Spacer(Modifier.height(8.dp))
                    Text(
                        text = StringStore.text(context, "onboardingV2.profile.nickname.$archetype", language),
                        style = OV2.titleLarge,
                        textAlign = TextAlign.Center,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                    Spacer(Modifier.height(8.dp))
                    Text(
                        text = StringStore.text(context, "onboardingV2.profile.tagline.$archetype", language),
                        style = OV2.body,
                        textAlign = TextAlign.Center,
                    )
                }
                Spacer(Modifier.height(metrics.sectionSpacing))
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier
                        .fillMaxWidth()
                        .graphicsLayer { alpha = objAlpha; translationY = (1f - objAlpha) * 16f },
                ) {
                    Text(
                        text = StringStore.text(context, "onboardingV2.profile.objectiveTitle", language)
                            .uppercase(Locale.getDefault()),
                        style = OV2.caption.copy(color = OV2.inkTertiary),
                        letterSpacing = 1.sp,
                    )
                    Spacer(Modifier.height(10.dp))
                    FlowRow(
                        modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        objectives.forEach { key ->
                            Row(
                                modifier = Modifier
                                    .clip(CircleShape)
                                    .background(OV2.surface)
                                    .border(1.dp, OV2.accent.copy(alpha = 0.25f), CircleShape)
                                    .padding(horizontal = 14.dp, vertical = 9.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Text(OBJECTIVE_EMOJI[key] ?: "📚", fontSize = 15.sp)
                                Spacer(Modifier.size(8.dp))
                                Text(
                                    text = StringStore.text(context, "onboardingV2.objective.$key", language),
                                    style = OV2.subheadline.copy(
                                        color = OV2.ink,
                                        fontWeight = FontWeight.SemiBold,
                                    ),
                                )
                            }
                        }
                    }
                }
                if (awaitingCourses.isNotEmpty()) {
                    Spacer(Modifier.height(metrics.sectionSpacing))
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .graphicsLayer { alpha = coursesAlpha; translationY = (1f - coursesAlpha) * 20f },
                    ) {
                        Text(
                            text = StringStore.text(context, "onboardingV2.profile.coursesTitle", language),
                            style = OV2.headline,
                            modifier = Modifier.padding(horizontal = 28.dp),
                        )
                        Spacer(Modifier.height(12.dp))
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .horizontalScroll(rememberScrollState())
                                .padding(horizontal = 28.dp, vertical = 4.dp),
                            horizontalArrangement = Arrangement.spacedBy(14.dp),
                        ) {
                            awaitingCourses.forEach { course ->
                                ProfileCourseCard(
                                    course = course,
                                    language = language,
                                    width = metrics.cardWidth,
                                    height = metrics.cardHeight,
                                )
                            }
                        }
                    }
                }
                Spacer(Modifier.height(16.dp))
            }
            // Always tappable, even while the fade is still running.
            Box(modifier = Modifier.alpha(ctaAlpha.coerceAtLeast(0.35f))) {
                OnboardingCta(
                    text = StringStore.text(context, "onboardingV2.profile.cta", language),
                    onClick = onContinue,
                )
            }
        }
    }
}

@Composable
private fun ProfileCourseCard(
    course: CourseSummary,
    language: AppLanguage,
    width: Dp,
    height: Dp,
) {
    val context = LocalContext.current
    Box(
        modifier = Modifier
            .width(width)
            .height(height)
            .clip(RoundedCornerShape(20.dp))
            .border(1.dp, OV2.hairline, RoundedCornerShape(20.dp)),
    ) {
        CourseImage(
            courseId = course.id,
            modifier = Modifier.fillMaxSize(),
            contentScale = ContentScale.Crop,
            maxEdgePx = 360,
        )
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        listOf(Color.Transparent, Color.Black.copy(alpha = 0.15f), Color.Black.copy(alpha = 0.78f)),
                    ),
                ),
        )
        Column(
            modifier = Modifier.align(Alignment.BottomStart).padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Text(
                text = StringStore.text(
                    context,
                    "subject.${course.subjectEnum.storageKey}.short",
                    language,
                ).uppercase(Locale.getDefault()),
                style = OV2.caption.copy(fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color.White),
                modifier = Modifier
                    .clip(CircleShape)
                    .background(Color.White.copy(alpha = 0.22f))
                    .padding(horizontal = 8.dp, vertical = 4.dp),
            )
            Text(
                text = course.title,
                style = OV2.subheadline.copy(fontWeight = FontWeight.Bold, color = Color.White),
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

@Composable
internal fun LoginStep(language: AppLanguage, onGoogle: () -> Unit, onSkip: () -> Unit) {
    val context = LocalContext.current
    var legalDoc by remember { mutableStateOf<LegalDocKind?>(null) }
    val doc = legalDoc
    if (doc != null) {
        LegalDocumentScreen(kind = doc, language = language, onBack = { legalDoc = null })
        return
    }
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.weight(1f))
        OnboardingCircleBadge(
            size = 96.dp,
            background = OV2.accentSoft.copy(alpha = 0.12f),
            modifier = Modifier.ov2Reveal(50),
        ) {
            Icon(
                Icons.Filled.HowToReg,
                contentDescription = null,
                tint = OV2.accent,
                modifier = Modifier.size(44.dp),
            )
        }
        Spacer(Modifier.height(16.dp))
        Text(
            text = StringStore.text(context, "onboardingV2.login.title", language),
            style = OV2.title,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 28.dp).ov2Reveal(120),
        )
        Spacer(Modifier.height(10.dp))
        Text(
            text = StringStore.text(context, "onboardingV2.login.subtitle", language),
            style = OV2.body,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 32.dp).ov2Reveal(180),
        )
        Spacer(Modifier.weight(1f))
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.fillMaxWidth().ov2Reveal(240),
        ) {
            OnboardingCta("Continue with Google", onGoogle)
            Text(
                text = StringStore.text(context, "home.skip", language),
                style = OV2.caption.copy(fontSize = 15.sp),
                modifier = Modifier.clickable(onClick = onSkip).padding(8.dp),
            )
            Spacer(Modifier.height(12.dp))
            Text(
                text = StringStore.text(context, "auth.legal.prefix", language),
                style = OV2.caption.copy(fontSize = 12.sp, color = OV2.inkTertiary),
            )
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = StringStore.text(context, "legal.terms.title", language),
                    style = OV2.caption.copy(fontSize = 12.sp, color = OV2.accentSoft),
                    modifier = Modifier
                        .clickable { legalDoc = LegalDocKind.Terms }
                        .padding(horizontal = 6.dp, vertical = 4.dp),
                )
                Text("·", color = OV2.inkTertiary)
                Text(
                    text = StringStore.text(context, "legal.privacy.title", language),
                    style = OV2.caption.copy(fontSize = 12.sp, color = OV2.accentSoft),
                    modifier = Modifier
                        .clickable { legalDoc = LegalDocKind.Privacy }
                        .padding(horizontal = 6.dp, vertical = 4.dp),
                )
            }
            Spacer(Modifier.height(24.dp))
        }
    }
}
