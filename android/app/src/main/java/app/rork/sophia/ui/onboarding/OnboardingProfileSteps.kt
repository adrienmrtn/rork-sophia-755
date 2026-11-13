package app.rork.sophia.ui.onboarding

import androidx.annotation.DrawableRes
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.Image
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
import androidx.compose.foundation.layout.navigationBarsPadding
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
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.outlined.ThumbDown
import androidx.compose.material.icons.outlined.ThumbUp
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
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
import app.rork.sophia.R
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
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

// MARK: - Course picks

/** Au plus cinq cartes dépassent derrière celle du dessus : toute la pile d'un paquet de six. */
private const val SWIPE_STACK_MAX = 5

/** Chaque carte de la pile dépasse de cette hauteur au-dessus de celle qui la précède… */
private val SWIPE_STACK_STEP = 8.dp

/** …et est plus étroite d'autant de chaque côté. */
private val SWIPE_STACK_INSET = 10.dp

/** Place gardée au-dessus de la carte du dessus pour la pile entière. */
private val SWIPE_STACK_RISE = SWIPE_STACK_STEP * SWIPE_STACK_MAX

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
 * cards — cover, title, author, subject — and two round buttons (thumb down, thumb up). The
 * gesture, its thresholds and its vibrations are unchanged.
 *
 * La pile est visible en entier : une tranche par cours restant dépasse derrière la carte du
 * dessus. Chaque réponse, oui ou non, fait partir la carte du dessus et retire une tranche ;
 * la pile fond ainsi jusqu'à être vide.
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
        animationSpec = OnboardingMotion.settle(420),
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
        // Le titre seul : le sous-titre a été retiré, la pile et les deux boutons se lisent sans lui.
        OV2EndHighlightTitle(
            text = swipeTitle(context, language),
            modifier = Modifier.padding(horizontal = OV2End.side).dsStagger(0),
        )
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
                val deckHeight = minOf(maxHeight, SWIPE_STACK_RISE + SWIPE_CARD_MAX_HEIGHT)
                val thresholdPx = with(density) { 100.dp.toPx() }
                // Cartes encore sous celle du dessus : une tranche visible pour chacune.
                val behind = (courses.size - index - 1).coerceIn(0, SWIPE_STACK_MAX)
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
                    // La pile : de la carte la plus profonde à la plus proche, chacune un peu plus
                    // haute et plus étroite que la suivante. La plus profonde s'efface à chaque réponse.
                    for (depth in SWIPE_STACK_MAX downTo 1) {
                        key(depth) {
                            val shown by animateFloatAsState(
                                targetValue = if (depth <= behind) 1f else 0f,
                                animationSpec = OnboardingMotion.settle(280),
                                label = "stackPlate",
                            )
                            SwipePlate(
                                width = cardWidth - SWIPE_STACK_INSET * (2 * depth),
                                depth = depth,
                                shown = { shown },
                                modifier = Modifier.padding(top = SWIPE_STACK_RISE - SWIPE_STACK_STEP * depth),
                            )
                        }
                    }
                    // The next card waits right under the top one, which follows the finger.
                    for (depth in 1 downTo 0) {
                        val course = courses.getOrNull(index + depth)
                        if (course != null) {
                            key(course.id) {
                                val top = depth == 0
                                Box(
                                    modifier = Modifier
                                        .fillMaxSize()
                                        .padding(top = SWIPE_STACK_RISE)
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
                                                                    // Retour au centre sans rebond.
                                                                    dragX.animateTo(0f, OnboardingMotion.settle(260))
                                                                }
                                                            }
                                                        },
                                                        onDragCancel = {
                                                            crossedThreshold = false
                                                            scope.launch { dragX.animateTo(0f, OnboardingMotion.settle(260)) }
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

/**
 * La tranche d'une carte de la pile, à [depth] cartes sous celle du dessus : même fond et même
 * bordure qu'une carte, un peu plus soutenus en profondeur. Quand [shown] retombe à zéro la
 * tranche s'efface en descendant derrière les autres : la pile a perdu une carte.
 */
@Composable
private fun SwipePlate(width: Dp, depth: Int, shown: () -> Float, modifier: Modifier = Modifier) {
    val fill = lerp(DS.accentTint, SwipeCardBorder, (0.14f * depth).coerceIn(0f, 1f))
    val drop = with(LocalDensity.current) { SWIPE_STACK_STEP.toPx() }
    Box(
        modifier = modifier
            .size(width = width.coerceAtLeast(0.dp), height = 60.dp)
            .graphicsLayer {
                val progress = shown().coerceIn(0f, 1f)
                alpha = progress
                translationY = (1f - progress) * drop
            }
            .ov2EndCard(fill = fill, border = SwipeCardBorder)
            .clearAndSetSemantics { },
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

/**
 * Les quatre arrêts du chargement, fixés d'avance (part de la progression globale) : la barre
 * s'y immobilise et ne repart qu'une fois la question du même rang répondue.
 */
private val LOADING_CHECKPOINTS = listOf(0.18f, 0.41f, 0.63f, 0.86f)

/** Durée d'un chargement complet, hors attente des réponses. */
private const val LOADING_TOTAL_MILLIS = 5200

/** Le temps de voir sa réponse cochée avant que la barre reparte. */
private const val LOADING_ANSWER_HOLD_MILLIS = 450L

/** Chaque tronçon part vite et ralentit en arrivant sur son arrêt, comme un vrai chargement. */
private val LoadingEasing = CubicBezierEasing(0.2f, 0.6f, 0.3f, 1f)

/** La barre en pause : un ambre net, loin du bleu de la barre qui avance. */
private val LoadingPausedTint = Color(0xFFE39A1C)

/**
 * « We are preparing your knowledge journey »: one progress bar for the whole preparation, the
 * three steps ticking as it passes them, then the social proof — users' photos, the stars and
 * the rating, « 500,000 users read courses on Sophia every month » — and the « see my profile » CTA.
 *
 * Le chargement est **bloquant** : à quatre moments fixés d'avance ([LOADING_CHECKPOINTS]) la
 * barre s'arrête pile sur son arrêt, passe en pause (couleur, pictogramme) et une carte pose
 * une question oui / non. Rien n'avance tant qu'elle n'a pas de réponse ; après la quatrième,
 * la barre file jusqu'à 100 % et le bouton du bas s'allume.
 */
@Composable
internal fun LoadingProfileStep(language: AppLanguage, firstName: String, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    val photos = remember { studentPhotos(context).take(5) }
    // Nombre de questions déjà répondues ; gardé à la rotation, pour ne pas les reposer.
    var answered by rememberSaveable { mutableIntStateOf(0) }
    // Progression globale, de 0 à 1. Elle reprend à l'arrêt de la dernière question répondue.
    val overall = remember {
        Animatable(if (answered > 0) LOADING_CHECKPOINTS[(answered - 1).coerceAtMost(LOADING_CHECKPOINTS.lastIndex)] else 0f)
    }
    // Rang de la question en attente ; null tant que la barre avance.
    var pending by remember { mutableStateOf<Int?>(null) }
    // Dernière question montrée : la carte la garde pendant qu'elle se referme.
    var shownQuestion by remember { mutableIntStateOf(answered.coerceAtMost(LOADING_CHECKPOINTS.lastIndex)) }
    // Réponse choisie à la question en cours ; null tant que rien n'est choisi.
    var picked by remember { mutableStateOf<Boolean?>(null) }
    var allDone by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        // Mise en scène, sans réseau derrière : seules les réponses peuvent la retenir.
        for (index in answered.coerceAtMost(LOADING_CHECKPOINTS.size) until LOADING_CHECKPOINTS.size) {
            val stop = LOADING_CHECKPOINTS[index]
            overall.animateTo(stop, tween(loadingMillis(stop - overall.value), easing = LoadingEasing))
            // Arrêt : la question s'affiche, la barre ne bouge plus.
            picked = null
            shownQuestion = index
            pending = index
            haptics.commit()
            snapshotFlow { answered }.first { it > index }
            delay(LOADING_ANSWER_HOLD_MILLIS)
            pending = null
        }
        overall.animateTo(1f, tween(loadingMillis(1f - overall.value), easing = LoadingEasing))
        haptics.commit()
        allDone = true
    }

    // Étapes terminées : la barre globale les coche en passant au tiers, aux deux tiers, au bout.
    val stepsDone by remember {
        derivedStateOf {
            val value = overall.value
            when {
                value >= 0.999f -> 3
                value >= 2f / 3f -> 2
                value >= 1f / 3f -> 1
                else -> 0
            }
        }
    }
    LaunchedEffect(stepsDone) {
        if (stepsDone > 0) haptics.selection()
    }

    val blocked = pending != null
    val proofAlpha by animateFloatAsState(if (allDone) 1f else 0.45f, tween(500), label = "loadingProof")
    val barTint by animateColorAsState(
        if (blocked) LoadingPausedTint else DS.accent,
        OnboardingMotion.quick(),
        label = "loadingBarTint",
    )
    val doneLabel = ov2EndText(context, "onboardingV2.loading.stepDone", language) { "" }

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
            Spacer(Modifier.height(18.dp))
            // La progression globale : le pourcentage en grand, le signe de pause, la barre.
            Column(modifier = Modifier.fillMaxWidth().dsStagger(1)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    LoadingPercent(progress = { overall.value }, language = language)
                    AnimatedVisibility(
                        visible = blocked,
                        enter = fadeIn(tween(180)),
                        exit = fadeOut(tween(180)),
                    ) {
                        LoadingPauseBadge()
                    }
                }
                LoadingBar(
                    progress = { overall.value },
                    tint = { barTint },
                    marks = LOADING_CHECKPOINTS,
                    modifier = Modifier.padding(top = 10.dp),
                )
            }
            // La question en attente, entre la barre arrêtée et les étapes.
            AnimatedVisibility(
                visible = blocked,
                enter = fadeIn(tween(220)) + expandVertically(OnboardingMotion.settle(320)),
                exit = fadeOut(tween(180)) + shrinkVertically(OnboardingMotion.settle(280)),
            ) {
                LoadingQuestionCard(
                    language = language,
                    index = shownQuestion,
                    count = LOADING_CHECKPOINTS.size,
                    picked = picked,
                    onAnswer = { yes ->
                        // Une seule réponse par question : la suivante attend son propre arrêt.
                        if (picked == null && pending == shownQuestion) {
                            picked = yes
                            answered = shownQuestion + 1
                        }
                    },
                    modifier = Modifier.padding(top = 16.dp),
                )
            }
            Spacer(Modifier.height(8.dp))
            Column(modifier = Modifier.fillMaxWidth().dsStagger(2)) {
                repeat(3) { i ->
                    LoadingStepRow(
                        label = StringStore.text(context, "onboardingV2.loading.step${i + 1}", language),
                        done = stepsDone > i,
                        active = stepsDone == i,
                        doneLabel = doneLabel,
                        divider = i < 2,
                    )
                }
            }
            Spacer(Modifier.height(22.dp))
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

/** Durée d'un tronçon de la barre, proportionnelle à ce qu'il parcourt. */
private fun loadingMillis(span: Float): Int =
    (span.coerceIn(0f, 1f) * LOADING_TOTAL_MILLIS).toInt().coerceAtLeast(450)

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
 * One step: its name and, on the right, a blue check (finished), a blue ring (in progress)
 * or a grey ring (to come). The percentage lives on the global bar above.
 */
@Composable
private fun LoadingStepRow(
    label: String,
    done: Boolean,
    active: Boolean,
    doneLabel: String,
    divider: Boolean,
) {
    val labelColor by animateColorAsState(
        if (done || active) DS.ink else DS.inkSecondary,
        OnboardingMotion.quick(),
        label = "stepLabel",
    )
    val ringColor by animateColorAsState(
        if (active) DS.accent else DS.hairline,
        OnboardingMotion.quick(),
        label = "stepRing",
    )
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .semantics(mergeDescendants = true) {
                if (done && doneLabel.isNotEmpty()) stateDescription = doneLabel
            },
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(vertical = 14.dp).heightIn(min = 24.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = label,
                style = OV2.body.copy(color = labelColor, fontWeight = FontWeight.SemiBold, lineHeight = 22.sp),
                modifier = Modifier.weight(1f),
            )
            if (done) {
                DSCheckBadge(size = 24.dp, fill = DS.accent)
            } else {
                Box(modifier = Modifier.size(24.dp).border(if (active) 2.dp else 1.5.dp, ringColor, CircleShape))
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
 * La barre du chargement. Elle ne porte aucune animation propre : la valeur et la couleur sont
 * lues au moment du dessin. Les [marks] sont les arrêts, de petites encoches sur la piste.
 */
@Composable
private fun LoadingBar(
    progress: () -> Float,
    tint: () -> Color,
    marks: List<Float>,
    modifier: Modifier = Modifier,
) {
    val track = DS.accentTint
    val notch = DS.surface
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(12.dp)
            .clip(CircleShape)
            .background(track)
            .drawBehind {
                val rtl = layoutDirection == LayoutDirection.Rtl
                val filled = max(size.height, size.width * progress().coerceIn(0f, 1f))
                drawRoundRect(
                    color = tint(),
                    topLeft = Offset(if (rtl) size.width - filled else 0f, 0f),
                    size = Size(filled, size.height),
                    cornerRadius = CornerRadius(size.height / 2f),
                )
                val notchWidth = 2.dp.toPx()
                marks.forEach { mark ->
                    val x = size.width * mark.coerceIn(0f, 1f)
                    drawRect(
                        color = notch,
                        topLeft = Offset((if (rtl) size.width - x else x) - notchWidth / 2f, 0f),
                        size = Size(notchWidth, size.height),
                        alpha = 0.85f,
                    )
                }
            }
            .clearAndSetSemantics { },
    )
}

/** Pourcentage de la progression globale : il roule avec la barre et se fige avec elle. */
@Composable
private fun LoadingPercent(progress: () -> Float, language: AppLanguage) {
    val format = remember(language) { NumberFormat.getPercentInstance(language.locale) }
    val percent by remember { derivedStateOf { (progress().coerceIn(0f, 1f) * 100f).toInt() } }
    Text(
        text = format.format(percent / 100.0),
        style = OV2.title.copy(fontSize = 30.sp, lineHeight = 36.sp, fontWeight = FontWeight.ExtraBold, fontFeatureSettings = "tnum"),
        maxLines = 1,
        modifier = Modifier.clearAndSetSemantics { },
    )
}

/** Le signe « pause » à côté du pourcentage, tant qu'une question attend sa réponse. */
@Composable
private fun LoadingPauseBadge() {
    Box(
        modifier = Modifier
            .size(28.dp)
            .background(LoadingPausedTint, CircleShape)
            .clearAndSetSemantics { },
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector = Icons.Filled.Pause,
            contentDescription = null,
            tint = Color.White,
            modifier = Modifier.size(18.dp),
        )
    }
}

/**
 * La question qui retient le chargement : une carte bleutée bien visible, son rang (« 2/4 »),
 * la question et les deux réponses. Y répondre est le seul moyen de faire repartir la barre.
 * TalkBack l'annonce quand elle apparaît (région vivante) ; les deux réponses sont des boutons.
 */
@Composable
private fun LoadingQuestionCard(
    language: AppLanguage,
    index: Int,
    count: Int,
    picked: Boolean?,
    onAnswer: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    Column(
        modifier = modifier
            .fillMaxWidth()
            .ov2EndCard(fill = DS.accentTint, border = DS.accent)
            .padding(start = 16.dp, top = 16.dp, end = 16.dp, bottom = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                // Lue d'un bloc, et dès qu'elle arrive.
                .semantics(mergeDescendants = true) { liveRegion = LiveRegionMode.Polite },
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = "${(index + 1).formatted(language)}/${count.formatted(language)}",
                    style = OV2.caption.copy(color = Color.White, fontWeight = FontWeight.Bold, fontFeatureSettings = "tnum"),
                    maxLines = 1,
                    modifier = Modifier
                        .background(DS.accent, CircleShape)
                        .padding(horizontal = 9.dp, vertical = 3.dp),
                )
                Text(
                    text = StringStore.text(context, "onboardingV2.loading.question.eyebrow", language),
                    style = OV2.caption.copy(color = DS.accent, fontWeight = FontWeight.SemiBold),
                )
            }
            Spacer(Modifier.height(10.dp))
            Text(
                text = StringStore.text(context, "onboardingV2.loading.question${index + 1}.title", language),
                style = OV2.headline.copy(fontSize = 19.sp, lineHeight = 25.sp),
                textAlign = TextAlign.Center,
            )
        }
        Spacer(Modifier.height(16.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            LoadingAnswerButton(
                text = StringStore.text(context, "onboardingV2.loading.question.no", language),
                selected = picked == false,
                enabled = picked == null,
                onSelect = { onAnswer(false) },
                modifier = Modifier.weight(1f),
            )
            LoadingAnswerButton(
                text = StringStore.text(context, "onboardingV2.loading.question.yes", language),
                selected = picked == true,
                enabled = picked == null,
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
    enabled: Boolean,
    onSelect: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val feedback = rememberHaptics()
    val color by animateColorAsState(if (selected) DS.accent else DS.ink, OnboardingMotion.quick(), label = "answerText")
    Box(
        modifier = modifier
            .heightIn(min = 52.dp)
            .pressable(
                onClick = {
                    feedback.select()
                    onSelect()
                },
                enabled = enabled,
                haptic = false,
            )
            .semantics {
                role = Role.Button
                this.selected = selected
            }
            .dsOptionCard(
                state = if (selected) DSOptionState.Selected else DSOptionState.Idle,
                shape = RoundedCornerShape(14.dp),
            )
            .padding(horizontal = 8.dp, vertical = 6.dp),
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
 *
 * Le badge rond porte l'illustration du profil ([profileIllustration]), plus un emoji.
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
    // Le badge grandit et se pose, sans rebond.
    val badgeScale by animateFloatAsState(if (badgeIn) 1f else 0.7f, OnboardingMotion.settle(420), label = "badge")
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
                Image(
                    painter = painterResource(profileIllustration(archetype)),
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier
                        .size(PROFILE_BADGE_SIZE)
                        .graphicsLayer {
                            scaleX = badgeScale
                            scaleY = badgeScale
                            alpha = ((badgeScale - 0.7f) / 0.3f).coerceIn(0f, 1f)
                        }
                        .clip(CircleShape)
                        .background(DS.accentTint)
                        .border(1.5.dp, OV2End.tintBorder, CircleShape)
                        .clearAndSetSemantics { },
                )
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
                            // Une coche bleue à la place de l'emoji : la page n'en porte plus.
                            Icon(
                                imageVector = Icons.Filled.Check,
                                contentDescription = null,
                                tint = DS.accent,
                                modifier = Modifier.size(15.dp),
                            )
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

/** Diamètre du badge rond du profil. */
private val PROFILE_BADGE_SIZE = 72.dp

/**
 * L'illustration d'un profil (`res/drawable-nodpi`, carrée, fond crème, dans le style papier
 * découpé des avatars), d'après la clé de l'objectif principal. Une clé inconnue retombe sur
 * « se cultiver », comme le surnom et la phrase du profil.
 */
@DrawableRes
private fun profileIllustration(archetype: String): Int = when (archetype) {
    "reduceScreen" -> R.drawable.onboarding_profile_reduce_screen
    "exams" -> R.drawable.onboarding_profile_exams
    "impress" -> R.drawable.onboarding_profile_impress
    "curiosity" -> R.drawable.onboarding_profile_curiosity
    else -> R.drawable.onboarding_profile_cultivate
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

/**
 * « Crée ton compte » : la page ne porte qu'un bouton, « Me connecter ». Il ouvre une languette
 * (feuille du bas, [LoginSheet]) qui porte les boutons de connexion — sur Android, Google seul.
 * La connexion elle-même, ses erreurs et la mention légale sont celles d'avant ; « Continuer
 * sans compte » reste sur la page, seule issue quand Google manque ou échoue.
 */
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
    // La languette des boutons de connexion, ouverte par « Me connecter ».
    var showSheet by rememberSaveable { mutableStateOf(false) }
    // Sans Google il n'y a plus rien à y proposer : la page reprend la main, avec son erreur.
    LaunchedEffect(googleAvailable) {
        if (!googleAvailable) showSheet = false
    }
    val doc = legalDoc
    if (doc != null) {
        LegalDocumentScreen(kind = doc, language = language, onBack = { legalDoc = null })
        return
    }
    val sheetOpen = showSheet && googleAvailable
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
            // Tant que la languette est ouverte, c'est elle qui montre l'erreur (une seule
            // note à l'écran, une seule vibration).
            errorMessage = if (sheetOpen) null else errorMessage,
            topSpacing = OV2End.topWithoutHeader,
            staggered = true,
        )
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.fillMaxWidth().dsStagger(2),
        ) {
            if (googleAvailable) {
                OnboardingCta(
                    text = StringStore.text(context, "onboardingV2.login.signIn", language),
                    enabled = !signingIn,
                    onClick = { showSheet = true },
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
    if (sheetOpen) {
        LoginSheet(
            language = language,
            signingIn = signingIn,
            errorMessage = errorMessage,
            onGoogle = onGoogle,
            onDismiss = { showSheet = false },
        )
    }
}

/**
 * La languette de connexion : son titre, l'erreur s'il y en a une, puis les boutons — Google
 * seul sur Android. Elle a exactement la hauteur de son contenu (pas d'état à moitié ouvert,
 * rien de vide dessous) et laisse la barre de navigation du système dégagée.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun LoginSheet(
    language: AppLanguage,
    signingIn: Boolean,
    errorMessage: String?,
    onGoogle: () -> Unit,
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = DS.canvas,
        shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(start = OV2End.side, end = OV2End.side, bottom = 20.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = StringStore.text(context, "onboardingV2.login.signIn", language),
                style = OV2.headline.copy(fontSize = 19.sp, lineHeight = 25.sp),
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().semantics { heading() },
            )
            Spacer(Modifier.height(16.dp))
            if (errorMessage != null) {
                LoginErrorNote(errorMessage, horizontalInset = 0.dp)
                Spacer(Modifier.height(14.dp))
            }
            OV2EndGoogleButton(
                // Après un échec, le même bouton propose de réessayer.
                text = StringStore.text(
                    context,
                    if (errorMessage == null) "auth.continueWithGoogle" else "paywall.error.retry",
                    language,
                ),
                // A second tap while the account picker is opening starts a second
                // Credential Manager request, which cancels the first one.
                enabled = !signingIn,
                busy = signingIn,
                onClick = onGoogle,
            )
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
private fun LoginErrorNote(message: String, horizontalInset: Dp = 28.dp) {
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
            .padding(horizontal = horizontalInset)
            .fillMaxWidth()
            .dsShake(shakes)
            .background(DS.dangerTint, RoundedCornerShape(DS.Radius.small))
            .padding(horizontal = 14.dp, vertical = 12.dp),
    )
}
