package app.rork.sophia.ui.onboarding

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.outlined.ThumbDown
import androidx.compose.material.icons.outlined.ThumbUp
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.coerceIn
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.AuthorStore
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.DeviceCapabilities
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.formatted
import app.rork.sophia.domain.locale
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.components.DSCheckBadge
import app.rork.sophia.ui.components.DSEyebrow
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.DSOptionState
import app.rork.sophia.ui.components.dsOptionCard
import app.rork.sophia.ui.components.dsShake
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.legal.LegalDocKind
import app.rork.sophia.ui.legal.LegalDocumentScreen
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.uppercaseInApp
import java.text.NumberFormat
import kotlin.math.abs
import kotlin.math.max
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

// MARK: - Course picks

/** The next two cards stick out by this much above the top one. */
private val SWIPE_PLATE_RISE = 22.dp

/** Tallest a card gets: a 196 dp cover and its block of text. */
private val SWIPE_CARD_MAX_HEIGHT = 430.dp
private val SWIPE_COVER_MAX = 196.dp
private val SWIPE_BUTTON_SIZE = 64.dp

/** Border and rule of a course card: the accent blue, much diluted over the pale blue. */
private val SwipeCardBorder = Color(0xFFB1C5EB)

/**
 * Tinder-style deck: drag a card left or right, or use the two buttons.
 *
 * « Elevate arrondi »: the title on the left (its heart in bold blue), a stack of pale blue
 * cards — cover, title, author, subject — two of which stick out at the top, and two round
 * buttons (thumb down, thumb up). The gesture, its thresholds and its vibrations are unchanged.
 */
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
    // Compose mirrors the button Row in Arabic and Hebrew, so 👍 ends up on the left — while
    // the drag still read "right means like", and the LIKE / NOPE stamps still pointed the
    // old way. Swiping towards the thumb up is the whole affordance, so the gesture follows
    // the buttons rather than the other way round.
    val likeSign = if (LocalLayoutDirection.current == LayoutDirection.Rtl) -1f else 1f

    // Author of each course of the deck (course id → name), when the catalogue knows it.
    var authorNames by remember { mutableStateOf<Map<String, String>>(emptyMap()) }
    LaunchedEffect(courses) {
        val appContext = context.applicationContext
        authorNames = withContext(Dispatchers.Default) {
            courses.mapNotNull { course ->
                AuthorStore.authorForCourse(appContext, course.id)?.let { course.id to it.name }
            }.toMap()
        }
    }

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
            val target = with(density) {
                (if (like) 600.dp.toPx() else (-600).dp.toPx()) * likeSign
            }
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

    val pullPx = with(density) { 110.dp.toPx() }

    // The deck is sized against the height actually available, not a fixed card: at a large
    // font scale on a short phone the card used to grow past the bottom of the screen and
    // take the two buttons with it, which ends the onboarding for that user.
    Column(
        modifier = Modifier.fillMaxSize().readableWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.height(OV2End.top))
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = OV2End.side).dsStagger(0),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            OV2EndHighlightTitle(text = swipeTitle(context, language))
            Text(
                text = StringStore.text(context, "onboardingV2.swipe.subtitle", language),
                style = OV2.subheadline.copy(fontWeight = FontWeight.Normal),
                modifier = Modifier.fillMaxWidth(),
            )
        }
        Spacer(Modifier.height(12.dp))

        if (!ready) {
            Box(modifier = Modifier.weight(1f), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = DS.accent)
            }
        } else if (done) {
            Box(modifier = Modifier.weight(1f), contentAlignment = Alignment.Center) {
                SwipeCompletion(language = language)
            }
        } else {
            BoxWithConstraints(
                modifier = Modifier.fillMaxWidth().weight(1f),
                contentAlignment = Alignment.Center,
            ) {
                // The card is as wide as the page; its cover is what shrinks on a short screen.
                val cardWidth = (maxWidth - OV2End.side * 2).coerceAtLeast(200.dp)
                val deckHeight = minOf(maxHeight, SWIPE_PLATE_RISE + SWIPE_CARD_MAX_HEIGHT)
                val thresholdPx = with(density) { 100.dp.toPx() }
                val remaining = courses.size - index
                val farPlate by animateFloatAsState(if (remaining > 2) 1f else 0f, DSMotion.snappy(), label = "farPlate")
                val nearPlate by animateFloatAsState(if (remaining > 1) 1f else 0f, DSMotion.snappy(), label = "nearPlate")
                Box(
                    modifier = Modifier
                        .size(cardWidth, deckHeight)
                        .graphicsLayer {
                            scaleX = 0.86f + 0.14f * enterProgress
                            scaleY = 0.86f + 0.14f * enterProgress
                            alpha = enterProgress.coerceIn(0f, 1f)
                            translationY = (1f - enterProgress) * 64f
                            rotationZ = (1f - enterProgress) * -4f
                        },
                    contentAlignment = Alignment.TopCenter,
                ) {
                    // Two bluish plates stick out at the top while cards remain underneath.
                    SwipePlate(width = cardWidth - 68.dp, color = DS.accent.copy(alpha = 0.08f), alpha = { farPlate })
                    SwipePlate(
                        width = cardWidth - 34.dp,
                        color = DS.accent.copy(alpha = 0.2f),
                        alpha = { nearPlate },
                        modifier = Modifier.padding(top = 11.dp),
                    )
                    // The next card waits right under the top one, which follows the finger.
                    for (depth in 1 downTo 0) {
                        val course = courses.getOrNull(index + depth)
                        if (course != null) {
                            key(course.id) {
                                val top = depth == 0
                                Box(
                                    modifier = Modifier
                                        .fillMaxSize()
                                        .padding(top = SWIPE_PLATE_RISE)
                                        .graphicsLayer {
                                            if (top) {
                                                translationX = dragX.value
                                                rotationZ = dragX.value / 24f
                                            }
                                        }
                                        .then(
                                            if (!top) {
                                                // TalkBack reads the top card only.
                                                Modifier.clearAndSetSemantics { }
                                            } else {
                                                Modifier.pointerInput(index, courses) {
                                                    detectHorizontalDragGestures(
                                                        onDragEnd = {
                                                            crossedThreshold = false
                                                            if (abs(dragX.value) > thresholdPx) {
                                                                commit(dragX.value * likeSign > 0)
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
                                                }
                                            },
                                        ),
                                ) {
                                    SwipeCard(
                                        course = course,
                                        language = language,
                                        authorName = authorNames[course.id],
                                        // Read per frame inside graphicsLayer, never during
                                        // composition: dragging must not recompose the card.
                                        stampProgress = if (top) {
                                            { (abs(dragX.value) / thresholdPx).coerceIn(0f, 1f) }
                                        } else {
                                            { 0f }
                                        },
                                        stampDirection = { dragX.value * likeSign },
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        if (!done) {
            // The button the card is pulled towards grows slightly.
            Row(
                horizontalArrangement = Arrangement.spacedBy(22.dp),
                modifier = Modifier.padding(top = 12.dp, bottom = 28.dp).ov2Reveal(300),
            ) {
                SwipeActionButton(
                    like = false,
                    label = StringStore.text(context, "onboardingV2.swipe.nope", language),
                    enabled = ready,
                    pull = { if (dragX.value * likeSign < 0f) (abs(dragX.value) / pullPx).coerceIn(0f, 1f) else 0f },
                ) { commit(false) }
                SwipeActionButton(
                    like = true,
                    label = StringStore.text(context, "onboardingV2.swipe.like", language),
                    enabled = ready,
                    pull = { if (dragX.value * likeSign > 0f) (abs(dragX.value) / pullPx).coerceIn(0f, 1f) else 0f },
                ) { commit(true) }
            }
        } else {
            Spacer(Modifier.height(SWIPE_BUTTON_SIZE + 40.dp))
        }
    }
}

/**
 * « Choisis les **premiers cours** que tu vas lire »: the existing title with its strong
 * passage marked. The passage comes from the tables, language by language; when it is
 * missing or no longer part of the title, the title comes back as it is.
 */
private fun swipeTitle(context: android.content.Context, language: AppLanguage): String {
    val title = StringStore.text(context, "onboardingV2.swipe.title", language)
    val passage = StringStore.text(context, "elevateOnboardingCore.swipe.titleHighlight", language)
    return if (title.contains("**") || passage.isEmpty() || !title.contains(passage)) {
        title
    } else {
        title.replaceFirst(passage, "**$passage**")
    }
}

@Composable
private fun SwipePlate(width: Dp, color: Color, alpha: () -> Float, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .size(width = width.coerceAtLeast(0.dp), height = 60.dp)
            .graphicsLayer { this.alpha = alpha().coerceIn(0f, 1f) }
            .background(color, DS.cardShape),
    )
}

/** A course card: cover, title, author when known, rule, subject. */
@Composable
private fun SwipeCard(
    course: CourseSummary,
    language: AppLanguage,
    authorName: String?,
    stampProgress: () -> Float,
    stampDirection: () -> Float,
) {
    val context = LocalContext.current
    Box(
        modifier = Modifier
            .fillMaxSize()
            .ov2EndCard(fill = DS.accentTint, border = SwipeCardBorder)
            .semantics(mergeDescendants = true) { },
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(start = 20.dp, top = 26.dp, end = 20.dp, bottom = 20.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            // The cover takes what the texts leave: it is the part that gives way.
            BoxWithConstraints(
                modifier = Modifier.weight(1f).fillMaxWidth(),
                contentAlignment = Alignment.Center,
            ) {
                val side = minOf(maxWidth, maxHeight, SWIPE_COVER_MAX)
                CourseImage(
                    courseId = course.id,
                    modifier = Modifier.size(side).clip(RoundedCornerShape(14.dp)),
                    contentScale = ContentScale.Crop,
                    maxEdgePx = 720,
                )
            }
            Spacer(Modifier.height(18.dp))
            Text(
                text = course.title,
                style = OV2.headline.copy(fontSize = 20.sp, lineHeight = 25.sp),
                textAlign = TextAlign.Center,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            if (authorName != null) {
                Spacer(Modifier.height(6.dp))
                Text(
                    text = authorName,
                    style = OV2.subheadline.copy(fontWeight = FontWeight.Normal),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            Spacer(Modifier.height(14.dp))
            Box(modifier = Modifier.fillMaxWidth().height(1.5.dp).background(SwipeCardBorder))
            Spacer(Modifier.height(14.dp))
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                OV2EndSubjectBadge(subject = course.subjectEnum, size = 24.dp)
                Text(
                    text = StringStore.text(
                        context,
                        "subject.${course.subjectEnum.storageKey}.short",
                        language,
                    ),
                    style = OV2.subheadline.copy(color = DS.ink, fontWeight = FontWeight.SemiBold),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        SwipeStamp(
            text = StringStore.text(context, "onboardingV2.swipe.like", language),
            color = DS.success,
            rotation = -12f,
            alignment = Alignment.TopStart,
            alpha = { if (stampDirection() > 0f) stampProgress() else 0f },
        )
        SwipeStamp(
            text = StringStore.text(context, "onboardingV2.swipe.nope", language),
            color = DS.danger,
            rotation = 12f,
            alignment = Alignment.TopEnd,
            alpha = { if (stampDirection() < 0f) stampProgress() else 0f },
        )
    }
}

@Composable
private fun BoxScope.SwipeStamp(
    text: String,
    color: Color,
    rotation: Float,
    alignment: Alignment,
    alpha: () -> Float,
) {
    val shape = RoundedCornerShape(10.dp)
    Text(
        text = text.uppercaseInApp(),
        style = OV2.title.copy(fontSize = 20.sp, fontWeight = FontWeight.ExtraBold, color = color),
        modifier = Modifier
            .align(alignment)
            .padding(14.dp)
            .graphicsLayer {
                this.alpha = alpha()
                rotationZ = rotation
            }
            .clearAndSetSemantics { }
            .background(DS.surface, shape)
            .border(2.5.dp, color, shape)
            .padding(horizontal = 12.dp, vertical = 6.dp),
    )
}

/** « Not for me » in grey, « I'm interested » in blue. */
@Composable
private fun SwipeActionButton(
    like: Boolean,
    label: String,
    enabled: Boolean,
    pull: () -> Float,
    onClick: () -> Unit,
) {
    Box(
        modifier = Modifier
            .graphicsLayer {
                val scale = 1f + 0.12f * pull()
                scaleX = scale
                scaleY = scale
            }
            .size(SWIPE_BUTTON_SIZE)
            // No press vibration: `commit` already triggers the one of the validation.
            .pressable(onClick = onClick, enabled = enabled, scaleDown = 0.9f, haptic = false)
            .semantics {
                contentDescription = label
                role = Role.Button
            }
            .background(if (like) DS.accent else DS.hairline, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector = if (like) Icons.Outlined.ThumbUp else Icons.Outlined.ThumbDown,
            contentDescription = null,
            tint = if (like) Color.White else DS.ink,
            modifier = Modifier.size(26.dp),
        )
    }
}

@Composable
private fun SwipeCompletion(language: AppLanguage) {
    val context = LocalContext.current
    val feedback = rememberHaptics()
    var checkIn by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(150)
        checkIn = true
        feedback.success()
    }
    val reveal by animateFloatAsState(if (checkIn) 1f else 0f, DSMotion.reveal(), label = "noted")
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        OnboardingCircleBadge(size = 120.dp, background = DS.success.copy(alpha = 0.12f)) {
            // The check draws itself as it lands.
            DSCheckBadge(size = 76.dp, delayMillis = 150)
        }
        Text(
            text = StringStore.text(context, "onboardingV2.swipe.noted", language),
            style = OV2.title.copy(fontSize = 22.sp, lineHeight = 28.sp),
            textAlign = TextAlign.Center,
            modifier = Modifier
                .padding(horizontal = OV2End.side)
                .graphicsLayer {
                    alpha = reveal.coerceIn(0f, 1f)
                    translationY = (1f - reveal) * 10.dp.toPx()
                },
        )
    }
}

// MARK: - Preparation

/** Length of each bar: three different loads, like three real steps. */
private val LOADING_DURATIONS = listOf(1300, 2200, 1600)

/** Fast at first, slower and slower towards the end, like a real load. */
private val LoadingEasing = CubicBezierEasing(0.05f, 0.75f, 0.3f, 1f)

/**
 * « We are preparing your knowledge journey »: three steps loading one after the other like
 * a real load (each at its own pace, the next starting when the previous is ticked), a card
 * asking a question while waiting, then the social proof — users' photos, the stars and the
 * rating, « 500,000 users read courses on Sophia every month » — and the « see my profile » CTA.
 */
@Composable
internal fun LoadingProfileStep(language: AppLanguage, firstName: String, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    val photos = remember { studentPhotos(context).take(5) }
    val progress = remember { List(3) { Animatable(0f) } }
    var completed by remember { mutableStateOf(listOf(false, false, false)) }
    var allDone by remember { mutableStateOf(false) }
    // Answer to the « do you like learning by listening? » card; null while nothing is picked.
    // It neither stops nor speeds up the load.
    var listens by remember { mutableStateOf<Boolean?>(null) }

    LaunchedEffect(Unit) {
        // Staged, with no network behind it: the CTA must always end up enabled.
        try {
            repeat(3) { i ->
                progress[i].animateTo(1f, tween(LOADING_DURATIONS[i], easing = LoadingEasing))
                delay(80)
                completed = completed.toMutableList().also { it[i] = true }
                haptics.selection()
                delay(180)
            }
            haptics.commit()
        } finally {
            allDone = true
        }
    }
    val proofAlpha by animateFloatAsState(if (allDone) 1f else 0.45f, tween(500), label = "loadingProof")
    // The step in progress: the first one that is not ticked.
    val activeStep = completed.indexOf(false)
    val doneLabel = ov2EndText(context, "onboardingV2.loading.stepDone", language) { "" }
    val questionTitle = ov2EndText(context, "onboardingV2.loading.question.title", language) { "" }

    OnboardingPage(
        contentArrangement = Arrangement.Top,
        footer = {
            OnboardingCta(
                text = StringStore.text(context, "onboardingV2.loading.cta", language),
                onClick = onContinue,
                enabled = allDone,
            )
        },
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = OV2End.side),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.height(OV2End.top))
            OV2EndHighlightTitle(
                text = loadingTitle(context, firstName, language),
                modifier = Modifier.dsStagger(0),
            )
            Spacer(Modifier.height(10.dp))
            Column(modifier = Modifier.fillMaxWidth().dsStagger(1)) {
                repeat(3) { i ->
                    LoadingStepRow(
                        label = StringStore.text(context, "onboardingV2.loading.step${i + 1}", language),
                        progress = { progress[i].value },
                        done = completed[i],
                        active = activeStep == i,
                        doneLabel = doneLabel,
                        language = language,
                        divider = i < 2,
                    )
                }
            }
            if (questionTitle.isNotEmpty()) {
                // A dotted thread from the steps to the question.
                val dotColor = DS.inkTertiary.copy(alpha = 0.7f)
                Box(
                    modifier = Modifier
                        .padding(vertical = 10.dp)
                        .size(width = 2.dp, height = 30.dp)
                        .dsStagger(2)
                        .drawBehind {
                            drawLine(
                                color = dotColor,
                                start = Offset(size.width / 2f, 0f),
                                end = Offset(size.width / 2f, size.height),
                                strokeWidth = 2.dp.toPx(),
                                cap = StrokeCap.Round,
                                pathEffect = PathEffect.dashPathEffect(floatArrayOf(0.5.dp.toPx(), 6.dp.toPx())),
                            )
                        },
                )
                LoadingQuestionCard(
                    language = language,
                    title = questionTitle,
                    listens = listens,
                    onAnswer = { listens = it },
                    modifier = Modifier.dsStagger(3),
                )
            }
            Spacer(Modifier.height(26.dp))
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(6.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .alpha(proofAlpha)
                    .semantics(mergeDescendants = true) { },
            ) {
                if (photos.isNotEmpty()) {
                    OV2EndPhotoRow(photos = photos, size = 36.dp, modifier = Modifier.padding(bottom = 6.dp))
                }
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    OV2EndStars(size = 17.dp, baseDelayMillis = 400)
                    Text(
                        text = 4.8.formatted(language, 1),
                        style = OV2.caption.copy(color = DS.ink, fontWeight = FontWeight.Bold),
                    )
                }
                Text(
                    text = StringStore.text(context, "onboardingV2.loading.social.count", language),
                    style = OV2.title.copy(fontSize = 20.sp, lineHeight = 26.sp, fontWeight = FontWeight.ExtraBold),
                    textAlign = TextAlign.Center,
                )
                Text(
                    text = StringStore.text(context, "onboardingV2.loading.social.body", language),
                    style = OV2.subheadline.copy(fontWeight = FontWeight.Normal),
                    textAlign = TextAlign.Center,
                )
                Text(
                    text = StringStore.text(context, "onboardingV2.loading.social.join", language),
                    style = OV2.subheadline.copy(color = DS.ink, fontWeight = FontWeight.Bold),
                    textAlign = TextAlign.Center,
                )
            }
            Spacer(Modifier.height(20.dp))
        }
    }
}

/**
 * The title, with « learning path » in bold blue once the tables carry the marked version;
 * the existing title, first name included, until then.
 */
private fun loadingTitle(context: android.content.Context, firstName: String, language: AppLanguage): String {
    // A name must not be able to open or close a highlighted passage.
    val name = firstName.trim().replace("*", "")
    val plain = personalizedText(context, "onboardingV2.loading.title", name, language)
    if (name.isEmpty()) {
        return ov2EndText(context, "onboardingV2.loading.titleMarked", language) { plain }
    }
    val namedKey = "onboardingV2.loading.titleMarkedNamed"
    val named = StringStore.text(context, namedKey, language)
    return if (named == namedKey) plain else named.replace("{name}", name)
}

/**
 * One step: its name and, on the right, a blue check (finished), the percentage (in
 * progress, with the bar underneath) or an empty ring (to come).
 */
@Composable
private fun LoadingStepRow(
    label: String,
    progress: () -> Float,
    done: Boolean,
    active: Boolean,
    doneLabel: String,
    language: AppLanguage,
    divider: Boolean,
) {
    val labelColor by animateColorAsState(
        if (done || active) DS.ink else DS.inkSecondary,
        DSMotion.snappy(),
        label = "stepLabel",
    )
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .semantics(mergeDescendants = true) {
                if (done && doneLabel.isNotEmpty()) stateDescription = doneLabel
            },
    ) {
        Column(modifier = Modifier.fillMaxWidth().padding(vertical = 16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth().heightIn(min = 24.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = label,
                    style = OV2.body.copy(color = labelColor, fontWeight = FontWeight.SemiBold, lineHeight = 22.sp),
                    modifier = Modifier.weight(1f),
                )
                when {
                    done -> DSCheckBadge(size = 24.dp, fill = DS.accent)
                    active -> LoadingPercent(progress = progress, language = language)
                    else -> Box(modifier = Modifier.size(24.dp).border(1.5.dp, DS.hairline, CircleShape))
                }
            }
            AnimatedVisibility(
                visible = active,
                enter = fadeIn() + expandVertically(),
                exit = fadeOut() + shrinkVertically(),
            ) {
                LoadingBar(progress = progress, modifier = Modifier.padding(top = 10.dp))
            }
        }
        if (divider) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.5.dp)
                    .background(DS.hairline.copy(alpha = 0.75f)),
            )
        }
    }
}

/**
 * Bar of the step in progress. It carries no animation of its own: the curve of the load
 * fills it, and the value is read while drawing.
 */
@Composable
private fun LoadingBar(progress: () -> Float, modifier: Modifier = Modifier) {
    val tint = DS.accent
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(8.dp)
            .clip(CircleShape)
            .background(DS.accentTint)
            .drawBehind {
                val filled = max(8.dp.toPx(), size.width * progress().coerceIn(0f, 1f))
                val left = if (layoutDirection == LayoutDirection.Rtl) size.width - filled else 0f
                drawRoundRect(
                    color = tint,
                    topLeft = Offset(left, 0f),
                    size = Size(filled, size.height),
                    cornerRadius = CornerRadius(size.height / 2f),
                )
            }
            .clearAndSetSemantics { },
    )
}

/** Percentage of the step in progress: it rolls with the bar instead of jumping from 0 to 100. */
@Composable
private fun LoadingPercent(progress: () -> Float, language: AppLanguage) {
    val format = remember(language) { NumberFormat.getPercentInstance(language.locale) }
    val percent by remember { derivedStateOf { (progress().coerceIn(0f, 1f) * 100f).toInt() } }
    Text(
        text = format.format(percent / 100.0),
        style = OV2.caption.copy(fontWeight = FontWeight.Medium, fontFeatureSettings = "tnum"),
        maxLines = 1,
        modifier = Modifier.clearAndSetSemantics { },
    )
}

/**
 * A question asked during the load. Answering is optional: the steps go on either way and
 * the button at the bottom turns on at the end.
 */
@Composable
private fun LoadingQuestionCard(
    language: AppLanguage,
    title: String,
    listens: Boolean?,
    onAnswer: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    Column(
        modifier = modifier
            .fillMaxWidth()
            .ov2EndCard()
            .padding(start = 16.dp, top = 18.dp, end = 16.dp, bottom = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = StringStore.text(context, "onboardingV2.loading.question.eyebrow", language),
            style = OV2.caption.copy(fontWeight = FontWeight.Normal),
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(6.dp))
        Text(
            text = title,
            style = OV2.headline.copy(lineHeight = 22.sp),
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(16.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            LoadingAnswerButton(
                text = StringStore.text(context, "onboardingV2.loading.question.no", language),
                selected = listens == false,
                onSelect = { onAnswer(false) },
                modifier = Modifier.weight(1f),
            )
            LoadingAnswerButton(
                text = StringStore.text(context, "onboardingV2.loading.question.yes", language),
                selected = listens == true,
                onSelect = { onAnswer(true) },
                modifier = Modifier.weight(1f),
            )
        }
    }
}

@Composable
private fun LoadingAnswerButton(
    text: String,
    selected: Boolean,
    onSelect: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val feedback = rememberHaptics()
    val color by animateColorAsState(if (selected) DS.accent else DS.ink, DSMotion.snappy(), label = "answerText")
    Box(
        modifier = modifier
            .height(50.dp)
            .pressable(
                onClick = {
                    if (!selected) {
                        feedback.select()
                        onSelect()
                    }
                },
                haptic = false,
            )
            .semantics {
                role = Role.RadioButton
                this.selected = selected
            }
            .dsOptionCard(
                state = if (selected) DSOptionState.Selected else DSOptionState.Idle,
                shape = RoundedCornerShape(14.dp),
            )
            .padding(horizontal = 8.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = text,
            style = OV2.subheadline.copy(color = color, fontWeight = FontWeight.SemiBold),
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

// MARK: - Profile

/**
 * « Here's your profile »: the reward just before the account. A nickname drawn from the
 * answers, the goal the user picked (the pale blue « Your goal » card) and the courses
 * waiting for them, numbered along a thread.
 */
@Composable
internal fun ProfileRewardStep(
    language: AppLanguage,
    firstName: String,
    objectiveKeys: List<String>,
    likedCourseIds: List<String>,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val feedback = rememberHaptics()
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
        delay(100)
        badgeIn = true
        feedback.select()
        delay(120)
        nameRevealed = true
        delay(280)
        reveal = 1
        feedback.soft()
        delay(300)
        reveal = 2
        delay(100)
        ctaVisible = true
    }
    val badgeScale by animateFloatAsState(if (badgeIn) 1f else 0.4f, DSMotion.pop(), label = "badge")
    val nameProgress by animateFloatAsState(if (nameRevealed) 1f else 0f, DSMotion.reveal(), label = "name")
    val objectiveProgress by animateFloatAsState(if (reveal >= 1) 1f else 0f, DSMotion.reveal(), label = "obj")
    val coursesProgress by animateFloatAsState(if (reveal >= 2) 1f else 0f, DSMotion.reveal(), label = "courses")
    val ctaAlpha by animateFloatAsState(if (ctaVisible) 1f else 0f, tween(400), label = "cta")

    OnboardingPage(
        contentArrangement = Arrangement.Top,
        footer = {
            // Always tappable, even while the fade is still running.
            Box(modifier = Modifier.alpha(ctaAlpha.coerceAtLeast(0.35f))) {
                OnboardingCta(
                    text = StringStore.text(context, "onboardingV2.profile.cta", language),
                    onClick = onContinue,
                )
            }
        },
    ) {
        Column(modifier = Modifier.fillMaxWidth().padding(horizontal = OV2End.side)) {
            Spacer(Modifier.height(18.dp))
            // Badge and nickname.
            Row(
                modifier = Modifier.fillMaxWidth().semantics(mergeDescendants = true) { },
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(
                    modifier = Modifier
                        .size(56.dp)
                        .graphicsLayer {
                            scaleX = badgeScale
                            scaleY = badgeScale
                            alpha = ((badgeScale - 0.4f) / 0.6f).coerceIn(0f, 1f)
                        }
                        .background(DS.accentTint, CircleShape)
                        .clearAndSetSemantics { },
                    contentAlignment = Alignment.Center,
                ) {
                    Text(OBJECTIVE_EMOJI[archetype] ?: "📚", fontSize = 28.sp)
                }
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .graphicsLayer {
                            alpha = nameProgress.coerceIn(0f, 1f)
                            translationX = (1f - nameProgress) * -10.dp.toPx()
                        },
                    verticalArrangement = Arrangement.spacedBy(2.dp),
                ) {
                    Text(
                        text = personalizedText(context, "onboardingV2.profile.eyebrow", firstName, language),
                        style = OV2.caption.copy(fontWeight = FontWeight.Normal),
                    )
                    Text(
                        text = StringStore.text(context, "onboardingV2.profile.nickname.$archetype", language),
                        style = OV2.headline.copy(fontSize = 20.sp, lineHeight = 25.sp),
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
            Spacer(Modifier.height(16.dp))
            // « Your goal »: the sentence of the profile, then the goals picked.
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .graphicsLayer {
                        alpha = objectiveProgress.coerceIn(0f, 1f)
                        translationY = (1f - objectiveProgress) * 14.dp.toPx()
                    }
                    .ov2EndCard(fill = DS.accentTint, border = OV2End.tintBorder)
                    .padding(horizontal = 16.dp, vertical = 14.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                DSEyebrow(text = StringStore.text(context, "onboardingV2.profile.objectiveTitle", language))
                Text(
                    text = StringStore.text(context, "onboardingV2.profile.tagline.$archetype", language),
                    style = OV2.body.copy(color = DS.ink, fontWeight = FontWeight.SemiBold, lineHeight = 22.sp),
                )
                Column(
                    modifier = Modifier.padding(top = 4.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    objectives.forEach { key ->
                        Row(
                            modifier = Modifier
                                .background(DS.surface, RoundedCornerShape(DS.Radius.small))
                                .padding(horizontal = 12.dp, vertical = 7.dp),
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(OBJECTIVE_EMOJI[key] ?: "📚", fontSize = 14.sp)
                            Text(
                                text = StringStore.text(context, "onboardingV2.objective.$key", language),
                                style = OV2.caption.copy(color = DS.ink, lineHeight = 18.sp),
                            )
                        }
                    }
                }
            }
            if (awaitingCourses.isNotEmpty()) {
                Spacer(Modifier.height(22.dp))
                OV2EndHighlightTitle(
                    text = ov2EndText(context, "onboardingV2.profile.coursesTitleMarked", language) {
                        StringStore.text(context, "onboardingV2.profile.coursesTitle", language)
                    },
                    fontSize = 22.sp,
                    lineHeight = 28.sp,
                    modifier = Modifier.graphicsLayer {
                        alpha = coursesProgress.coerceIn(0f, 1f)
                        translationY = (1f - coursesProgress) * 14.dp.toPx()
                    },
                )
                Spacer(Modifier.height(18.dp))
                // The courses numbered along a vertical thread, the first one put forward.
                val threadColor = OV2End.tintBorder
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .drawBehind {
                            val inset = 20.dp.toPx()
                            val length = (size.height - inset * 2).coerceAtLeast(0f) * coursesProgress.coerceIn(0f, 1f)
                            val x = if (layoutDirection == LayoutDirection.Rtl) size.width - 14.dp.toPx() else 14.dp.toPx()
                            drawLine(
                                color = threadColor,
                                start = Offset(x, inset),
                                end = Offset(x, inset + length),
                                strokeWidth = 2.dp.toPx(),
                                alpha = coursesProgress.coerceIn(0f, 1f),
                            )
                        },
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    awaitingCourses.forEachIndexed { index, course ->
                        key(course.id) {
                            ProfileTimelineRow(
                                course = course,
                                index = index,
                                language = language,
                                visible = reveal >= 2,
                            )
                        }
                    }
                }
            }
            Spacer(Modifier.height(20.dp))
        }
    }
}

@Composable
private fun ProfileTimelineRow(
    course: CourseSummary,
    index: Int,
    language: AppLanguage,
    visible: Boolean,
) {
    val context = LocalContext.current
    // Each row lands a little after the one above it.
    var shown by remember { mutableStateOf(false) }
    LaunchedEffect(visible) {
        if (visible) {
            delay(60L + index * 80L)
            shown = true
        }
    }
    val progress by animateFloatAsState(if (shown) 1f else 0f, DSMotion.reveal(), label = "timelineRow")
    val first = index == 0
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .graphicsLayer {
                alpha = progress.coerceIn(0f, 1f)
                translationY = (1f - progress) * 16.dp.toPx()
            },
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(28.dp)
                .background(if (first) DS.accent else DS.accentTint, CircleShape)
                .clearAndSetSemantics { },
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = (index + 1).formatted(language),
                style = OV2.caption.copy(color = if (first) Color.White else DS.accent, fontWeight = FontWeight.Bold),
            )
        }
        Row(
            modifier = Modifier
                .weight(1f)
                .ov2EndCard()
                .semantics(mergeDescendants = true) { }
                .padding(start = 8.dp, top = 8.dp, end = 12.dp, bottom = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            CourseImage(
                courseId = course.id,
                modifier = Modifier.size(56.dp).clip(RoundedCornerShape(DS.Radius.small)),
                contentScale = ContentScale.Crop,
                maxEdgePx = 240,
                letterSize = 20.sp,
            )
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                DSEyebrow(
                    text = StringStore.text(
                        context,
                        "subject.${course.subjectEnum.storageKey}.short",
                        language,
                    ),
                )
                Text(
                    text = course.title,
                    style = OV2.caption.copy(color = DS.ink, lineHeight = 18.sp),
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
    }
}

// MARK: - Account

@Composable
internal fun LoginStep(
    language: AppLanguage,
    signingIn: Boolean,
    errorMessage: String?,
    googleAvailable: Boolean,
    onGoogle: () -> Unit,
    onContinueWithoutAccount: () -> Unit,
    onSkip: () -> Unit,
) {
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
        AccountPageBody(
            title = StringStore.text(context, "onboardingV2.login.title", language),
            subtitle = StringStore.text(
                context,
                // Without Play services there is no Google to sign in with, so the page
                // must not promise one.
                if (googleAvailable) "onboardingV2.login.subtitle" else "auth.withoutAccount.note",
                language,
            ),
            errorMessage = errorMessage,
            topSpacing = OV2End.topWithoutHeader,
            staggered = true,
        )
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.fillMaxWidth().dsStagger(2),
        ) {
            if (googleAvailable) {
                OnboardingCta(
                    // Was hardcoded English on every language. The translation already exists.
                    text = StringStore.text(
                        context,
                        if (errorMessage == null) "auth.continueWithGoogle" else "paywall.error.retry",
                        language,
                    ),
                    // A second tap while the account picker is opening starts a second
                    // Credential Manager request, which cancels the first one.
                    enabled = !signingIn,
                    onClick = onGoogle,
                    bottomInset = 8.dp,
                )
            }
            // The only way out when Google fails, is unavailable, or is refused by a child
            // account. Progress stays local and the app offers an account again later.
            Text(
                text = StringStore.text(context, "auth.continueWithoutAccount", language),
                style = OV2.caption.copy(
                    fontSize = 15.sp,
                    color = if (googleAvailable) DS.inkSecondary else DS.accent,
                ),
                modifier = Modifier
                    .pressable(onClick = onContinueWithoutAccount, enabled = !signingIn)
                    .padding(horizontal = 20.dp, vertical = 10.dp),
            )
            if (DeviceCapabilities.allowsLoginBypass()) {
                Text(
                    text = "Skip login · emulator only",
                    style = OV2.caption.copy(fontSize = 13.sp, color = DS.inkTertiary),
                    modifier = Modifier.clickable(onClick = onSkip).padding(8.dp),
                )
            }
            Spacer(Modifier.height(8.dp))
            OV2EndLegalNote(language = language, onOpen = { legalDoc = it })
            Spacer(Modifier.height(20.dp))
        }
    }
}

/**
 * « I already have an account », from the welcome page: sign in and go straight into the
 * app. Deliberately not the login page of the flow, which sits after the questions: a
 * returning reader answered them once already, and their history comes back from the cloud
 * the moment they sign in. Port of iOS's `OnboardingV2ExistingAccountSheet`.
 */
@Composable
internal fun ExistingAccountStep(
    language: AppLanguage,
    signingIn: Boolean,
    errorMessage: String?,
    onGoogle: () -> Unit,
    onClose: () -> Unit,
) {
    val context = LocalContext.current
    var legalDoc by remember { mutableStateOf<LegalDocKind?>(null) }
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas)
            // Nothing behind the page may be tapped through it.
            .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) {},
    ) {
        Column(modifier = Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 12.dp).padding(top = 8.dp),
                horizontalArrangement = Arrangement.End,
            ) {
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .pressable(onClick = onClose, enabled = !signingIn),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(Icons.Filled.Close, contentDescription = null, tint = DS.inkSecondary, modifier = Modifier.size(20.dp))
                }
            }
            AccountPageBody(
                title = StringStore.text(context, "onboardingV2.existingAccount.title", language),
                subtitle = StringStore.text(context, "onboardingV2.existingAccount.subtitle", language),
                errorMessage = errorMessage,
                topSpacing = 8.dp,
                staggered = false,
            )
            OnboardingCta(
                text = StringStore.text(
                    context,
                    if (errorMessage == null) "auth.continueWithGoogle" else "paywall.error.retry",
                    language,
                ),
                enabled = !signingIn,
                onClick = onGoogle,
                bottomInset = 12.dp,
            )
            OV2EndLegalNote(language = language, onOpen = { legalDoc = it })
            Spacer(Modifier.height(28.dp))
        }
        legalDoc?.let { doc ->
            Box(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
                LegalDocumentScreen(kind = doc, language = language, onBack = { legalDoc = null })
            }
        }
    }
}

/**
 * The upper part of a sign-in page: title, subtitle, the round illustration centred in the
 * room that is left, and the error when there is one. It scrolls, so the buttons under it
 * stay reachable at large font scales on a short phone, where the illustration also shrinks.
 */
@Composable
private fun ColumnScope.AccountPageBody(
    title: String,
    subtitle: String,
    errorMessage: String?,
    topSpacing: Dp,
    staggered: Boolean,
) {
    BoxWithConstraints(modifier = Modifier.weight(1f).fillMaxWidth()) {
        val viewport = maxHeight
        val illustration = (viewport - 190.dp).coerceIn(88.dp, 190.dp)
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .heightIn(min = viewport),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween,
        ) {
            Column(
                modifier = Modifier.fillMaxWidth().padding(horizontal = OV2End.side),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Spacer(Modifier.height(topSpacing))
                OV2EndTitle(text = title, modifier = if (staggered) Modifier.dsStagger(0) else Modifier)
                Spacer(Modifier.height(10.dp))
                OV2EndSubtitle(text = subtitle, modifier = if (staggered) Modifier.dsStagger(1) else Modifier)
            }
            Column(
                modifier = Modifier.fillMaxWidth().padding(vertical = 16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                OV2EndAccountIllustration(size = illustration)
                if (errorMessage != null) {
                    Spacer(Modifier.height(18.dp))
                    LoginErrorNote(errorMessage)
                }
            }
            // Third item of the spread: keeps the illustration in the middle of the room left.
            Spacer(Modifier.height(0.dp))
        }
    }
}

/** Sign-in failures used to be a Toast thrown from the service; they belong on the page. */
@Composable
private fun LoginErrorNote(message: String) {
    val feedback = rememberHaptics()
    var shakes by remember { mutableIntStateOf(0) }
    LaunchedEffect(message) {
        shakes += 1
        feedback.error()
    }
    Text(
        text = message,
        style = OV2.caption.copy(fontSize = 13.sp, color = DS.danger, lineHeight = 18.sp),
        textAlign = TextAlign.Center,
        modifier = Modifier
            .padding(horizontal = 28.dp)
            .fillMaxWidth()
            .dsShake(shakes)
            .background(DS.dangerTint, RoundedCornerShape(DS.Radius.small))
            .padding(horizontal = 14.dp, vertical = 12.dp),
    )
}
