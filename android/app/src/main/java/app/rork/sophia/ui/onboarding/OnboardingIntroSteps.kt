package app.rork.sophia.ui.onboarding

import androidx.annotation.DrawableRes
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.MutableTransitionState
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.shrinkVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
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
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.R
import app.rork.sophia.data.CourseCoverUrls
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.components.DSCheckBadge
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.DSOptionState
import app.rork.sophia.ui.components.dsHighlighted
import app.rork.sophia.ui.components.dsOptionCard
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import coil.compose.rememberAsyncImagePainter
import coil.request.ImageRequest
import kotlinx.coroutines.delay

internal val OBJECTIVE_KEYS = listOf("cultivate", "reduceScreen", "exams", "impress", "curiosity")
internal val OBJECTIVE_EMOJI = mapOf(
    "cultivate" to "🧠",
    "reduceScreen" to "📵",
    "exams" to "🎓",
    "impress" to "✨",
    "curiosity" to "🔭",
)

// region Shared pieces of these pages

/** Centred title of a question page (medium weight) and its grey subtitle. */
@Composable
private fun IntroQuestionTitle(title: String, subtitle: String?, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier.fillMaxWidth().padding(horizontal = ONBOARDING_SIDE_INSET),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            text = title,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Medium,
            fontSize = 22.sp,
            lineHeight = 29.sp,
            letterSpacing = 0.2.sp,
            color = DS.ink,
            textAlign = TextAlign.Center,
            modifier = Modifier.semantics { heading() },
        )
        if (subtitle != null) {
            Text(
                text = subtitle,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Normal,
                fontSize = 15.sp,
                lineHeight = 21.sp,
                color = DS.inkSecondary,
                textAlign = TextAlign.Center,
            )
        }
    }
}

/** A round illustration on the pale blue disc of the style. */
@Composable
private fun IntroRoundArt(@DrawableRes art: Int, size: Dp, modifier: Modifier = Modifier) {
    Image(
        painter = painterResource(art),
        contentDescription = null,
        contentScale = ContentScale.Crop,
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(DS.accentTint),
    )
}

/**
 * Size of the round illustration for the room really left: full size when everything fits,
 * smaller on a short screen, absent (0) when only a thumbnail would remain. [reserved] is
 * the height of the rest of the page.
 */
private fun introArtSize(base: Dp, available: Dp, reserved: Dp): Dp {
    val room = available - reserved
    return when {
        room >= base -> base
        room >= 64.dp -> room
        else -> 0.dp
    }
}

// endregion

// region 1. Welcome

/**
 * Courses whose cover fills the wall: the most read and the most telling in picture, three
 * per column (same list as iOS).
 */
/**
 * Langue de tout le texte de la page d'accueil. L'accroche de marque (« Replace scrolling
 * with… ») est volontairement en anglais dans toutes les tables ; le sous-titre et les deux
 * boutons étaient, eux, lus dans la langue de l'app, d'où une page en deux langues. Tout se
 * résout maintenant depuis cette seule langue : celle de l'accroche.
 */
private val WELCOME_LANGUAGE = AppLanguage.ENGLISH

private val WELCOME_COVER_COURSE_IDS = listOf(
    "course_67_qu_est_ce_qu_un_trou_noir",
    "course_241_pourquoi_voulait_on_demolir_la_tour_eiffel",
    "course_42_pourquoi_reve_t_on",
    "course_150_la_nuit_etoilee_van_gogh",
    "course_149_la_joconde",
    "course_281_comment_meurt_une_etoile",
    "course_264_qui_a_vraiment_construit_les_pyramides",
    "course_101_1984_george_orwell",
    "course_290_comment_les_etats_unis_ont_ils_gagne_la",
    "course_161_la_naissance_des_dieux_grecs_cronos_zeus",
    "course_247_pourquoi_les_momies_font_elles_peur",
    "course_11_la_prise_de_la_bastille_1789",
)

/**
 * Page 1 — Welcome. A wall of real course covers drifting slowly, the Sophia logo, the
 * tagline, the « Get started » button and the « I already have an account » door.
 */
@Composable
internal fun WelcomeStep(
    /** La langue de l'app. Le texte de la page, lui, est lu dans [WELCOME_LANGUAGE]. */
    @Suppress("UNUSED_PARAMETER") language: AppLanguage,
    onContinue: () -> Unit,
    /** Someone reinstalling or switching phone. Null hides the link (no Google to sign in with). */
    onExistingAccount: (() -> Unit)? = null,
    /** Wait before the page comes in: the time the animated logo takes to play. */
    entranceDelayMillis: Int = 0,
    /** False on constrained phones: the wall stays still. */
    animateWall: Boolean = true,
) {
    val context = LocalContext.current
    val reduceMotion = rememberOnboardingReduceMotion()
    var wallIn by remember { mutableStateOf(false) }
    var textIn by remember { mutableStateOf(false) }
    var actionsIn by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(entranceDelayMillis.toLong())
        wallIn = true
        delay(150)
        textIn = true
        delay(150)
        actionsIn = true
    }
    val wallProgress by animateFloatAsState(
        targetValue = if (wallIn) 1f else 0f,
        animationSpec = tween(700, easing = LinearOutSlowInEasing),
        label = "welcomeWall",
    )
    val textProgress by animateFloatAsState(if (textIn) 1f else 0f, DSMotion.reveal(), label = "welcomeText")
    val actionsProgress by animateFloatAsState(if (actionsIn) 1f else 0f, DSMotion.reveal(), label = "welcomeActions")

    BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
        // The wall takes the top half of the screen, bounded so the text and the buttons can
        // breathe on a small phone.
        val wallHeight = (maxHeight * 0.5f).coerceIn(200.dp, 410.dp)
        WelcomeCoverWall(
            animate = animateWall && !reduceMotion,
            modifier = Modifier
                .fillMaxWidth()
                .height(wallHeight)
                .graphicsLayer {
                    alpha = wallProgress.coerceIn(0f, 1f)
                    transformOrigin = TransformOrigin(0.5f, 0f)
                    val scale = 1.05f - 0.05f * wallProgress
                    scaleX = scale
                    scaleY = scale
                },
        )
        Column(modifier = Modifier.fillMaxSize()) {
            // The text scrolls under the wall on a small phone at a large font size; when it
            // fits it sits in the middle of what the wall leaves.
            BoxWithConstraints(modifier = Modifier.weight(1f).fillMaxWidth()) {
                val textRoom = (maxHeight - wallHeight).coerceAtLeast(0.dp)
                Column(modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
                    Spacer(Modifier.height(wallHeight))
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .heightIn(min = textRoom)
                            .padding(horizontal = ONBOARDING_SIDE_INSET, vertical = 8.dp)
                            .graphicsLayer {
                                alpha = textProgress.coerceIn(0f, 1f)
                                translationY = (1f - textProgress) * 16.dp.toPx()
                            },
                        contentAlignment = Alignment.CenterStart,
                    ) {
                        WelcomeTextBlock()
                    }
                }
            }
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .graphicsLayer {
                        alpha = actionsProgress.coerceIn(0f, 1f)
                        translationY = (1f - actionsProgress) * 14.dp.toPx()
                    },
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                OnboardingCta(
                    text = StringStore.text(context, "onboardingV2.welcome.cta", WELCOME_LANGUAGE),
                    onClick = onContinue,
                    bottomInset = if (onExistingAccount == null) 20.dp else 6.dp,
                )
                // Quiet on purpose: this is the door for people who already know the app, and it
                // must not compete with « Get started » for a new one.
                if (onExistingAccount != null) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = ONBOARDING_SIDE_INSET)
                            .padding(bottom = 8.dp)
                            .heightIn(min = 48.dp)
                            .pressable(onClick = onExistingAccount)
                            .semantics { role = Role.Button },
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(
                            text = StringStore.text(context, "onboardingV2.welcome.existingAccount", WELCOME_LANGUAGE),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 15.sp,
                            letterSpacing = 0.3.sp,
                            color = DS.accent,
                            textAlign = TextAlign.Center,
                        )
                    }
                }
            }
        }
    }
}

/**
 * The whole logo (symbol + « Sophia »), the brand tagline and the promise. L'accroche et la
 * promesse sont lues dans la même langue ([WELCOME_LANGUAGE]) et posées de gauche à droite,
 * y compris sur un téléphone en arabe ou en hébreu.
 */
@Composable
private fun WelcomeTextBlock() {
    val context = LocalContext.current
    val language = WELCOME_LANGUAGE
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Image(
            painter = painterResource(R.drawable.sophia_mark),
            contentDescription = null,
            contentScale = ContentScale.Fit,
            modifier = Modifier
                .width(136.dp)
                .aspectRatio(1192f / 334f)
                .semantics { contentDescription = "Sophia" },
        )
        OnboardingShrinkText(
            text = dsHighlighted(
                StringStore.text(context, "onboardingV2.elevate.welcome.tagline", language),
                DS.accent,
            ),
            style = TextStyle(
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Normal,
                fontSize = 28.sp,
                lineHeight = 35.sp,
                color = DS.ink,
            ),
            maxLines = 3,
            minScale = 0.75f,
            textAlign = TextAlign.Start,
            modifier = Modifier.fillMaxWidth().semantics { heading() },
        )
        Text(
            text = StringStore.text(context, "onboardingV2.welcome.subtitle", language),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Normal,
            fontSize = 15.sp,
            lineHeight = 22.sp,
            color = DS.inkSecondary,
            textAlign = TextAlign.Start,
            modifier = Modifier.fillMaxWidth(),
        )
    }
    }
}

private const val WALL_COLUMNS = 4
private const val WALL_COVERS_PER_COLUMN = 3
private val WALL_COVER_HEIGHT = 136.dp
private val WALL_GAP = 10.dp

/** Overhang of the wall on each side of the screen, as on the mock-up. */
private val WALL_BLEED = 28.dp

/** Starting shift of each column, in dp. */
private val WALL_PHASES = listOf(34f, 96f, 52f, 12f)

/** Speed of each column in dp per second; the sign gives the direction. */
private val WALL_SPEEDS = listOf(7f, -5.5f, 6.5f, -7.5f)

/**
 * Four columns of course covers, staggered in height, drifting slowly in alternate
 * directions and fading into the white at the bottom. Still when [animate] is false; tinted
 * tiles hold the place while the covers arrive.
 */
@Composable
private fun WelcomeCoverWall(animate: Boolean, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val density = LocalDensity.current
    // One request per cover, drawn in each copy of its column: twelve downloads, not thirty-six.
    val painters = WELCOME_COVER_COURSE_IDS.map { courseId ->
        val url = remember(courseId) { CourseCoverUrls.url(context, courseId) }
        rememberAsyncImagePainter(
            model = remember(url) {
                ImageRequest.Builder(context)
                    .data(url)
                    .size(420)
                    .memoryCacheKey("onboarding:$courseId:420")
                    .diskCacheKey(courseId)
                    .crossfade(true)
                    .build()
            },
            contentScale = ContentScale.Crop,
        )
    }
    // Height of a full turn of a column: after it the next copy sits exactly where the
    // previous one was.
    val periodPx = with(density) { ((WALL_COVER_HEIGHT + WALL_GAP) * WALL_COVERS_PER_COLUMN).toPx() }
    var elapsedSeconds by remember { mutableFloatStateOf(0f) }
    LaunchedEffect(animate) {
        if (!animate) return@LaunchedEffect
        val start = withFrameNanos { it }
        while (true) {
            withFrameNanos { now -> elapsedSeconds = (now - start) / 1_000_000_000f }
        }
    }
    val tileShape = RoundedCornerShape(14.dp)
    val canvas = DS.canvas
    // A picture, not text: the wall runs the same way in every language.
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
        BoxWithConstraints(modifier = modifier.clipToBounds().clearAndSetSemantics { }) {
            val columnWidth = ((maxWidth + WALL_BLEED * 2 - WALL_GAP * (WALL_COLUMNS - 1)) / WALL_COLUMNS)
                .coerceAtLeast(60.dp)
            Row(
                modifier = Modifier
                    .wrapContentWidth(align = Alignment.CenterHorizontally, unbounded = true)
                    .wrapContentHeight(align = Alignment.Top, unbounded = true),
                horizontalArrangement = Arrangement.spacedBy(WALL_GAP),
            ) {
                repeat(WALL_COLUMNS) { column ->
                    Column(
                        modifier = Modifier
                            .width(columnWidth)
                            .graphicsLayer {
                                val travel = (WALL_PHASES[column] + elapsedSeconds * WALL_SPEEDS[column]).dp.toPx()
                                val wrapped = travel % periodPx
                                translationY = -(if (wrapped < 0f) wrapped + periodPx else wrapped)
                            },
                        verticalArrangement = Arrangement.spacedBy(WALL_GAP),
                    ) {
                        // Two turns: one fills the wall, the other takes over as the first leaves.
                        repeat(WALL_COVERS_PER_COLUMN * 2) { index ->
                            val slot = index % WALL_COVERS_PER_COLUMN
                            val painter = painters.getOrNull(column + slot * WALL_COLUMNS)
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(WALL_COVER_HEIGHT)
                                    .clip(tileShape)
                                    .background(DS.accentTint)
                                    .border(1.5.dp, DS.hairline, tileShape),
                            ) {
                                if (painter != null) {
                                    Image(
                                        painter = painter,
                                        contentDescription = null,
                                        contentScale = ContentScale.Crop,
                                        modifier = Modifier.fillMaxSize(),
                                    )
                                }
                            }
                        }
                    }
                }
            }
            Box(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
                    .height(130.dp)
                    .background(Brush.verticalGradient(listOf(canvas.copy(alpha = 0f), canvas))),
            )
        }
    }
}

// endregion

// region 2. Language

/** Beyond this the rows are off screen: no point in stretching the entrance cascade. */
private const val LANGUAGE_MAX_STAGGERED_ROWS = 9

/**
 * Page 2 — the language. The current one is preselected; the list scrolls, with a hint for
 * the languages below the fold.
 */
@Composable
internal fun LanguageStep(
    language: AppLanguage,
    onSelect: (AppLanguage) -> Unit,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val scrollState = rememberScrollState()
    var showScrollHint by remember { mutableStateOf(true) }
    // Bumped on each choice: the flag of the header pulses, without bouncing.
    var flagPulse by remember { mutableIntStateOf(0) }
    val bounce by rememberInfiniteTransition(label = "langHint").animateFloat(
        initialValue = 0f,
        targetValue = 3f,
        animationSpec = infiniteRepeatable(tween(900), RepeatMode.Reverse),
        label = "bounce",
    )
    LaunchedEffect(scrollState.value) {
        if (scrollState.value > 24) showScrollHint = false
    }

    Column(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 20.dp)
                .dsStagger(0),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            IntroQuestionTitle(
                title = StringStore.text(context, "onboardingV2.language.title", language),
                subtitle = null,
            )
            LanguageFlagBadge(language = language, pulse = flagPulse, modifier = Modifier.padding(top = 14.dp))
        }

        Box(modifier = Modifier.weight(1f).fillMaxWidth().padding(top = 16.dp)) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(scrollState)
                    .padding(horizontal = ONBOARDING_SIDE_INSET)
                    .padding(top = 2.dp, bottom = 40.dp),
                verticalArrangement = Arrangement.spacedBy(9.dp),
            ) {
                AppLanguage.entries.forEachIndexed { index, lang ->
                    LanguageRow(
                        language = lang,
                        selected = lang == language,
                        modifier = Modifier.dsStagger(minOf(index, LANGUAGE_MAX_STAGGERED_ROWS) + 1, stepMillis = 45),
                        onClick = {
                            haptics.select()
                            flagPulse += 1
                            onSelect(lang)
                        },
                    )
                }
            }
            LanguageScrollHint(
                visible = showScrollHint,
                bounce = bounce,
                language = language,
                modifier = Modifier.align(Alignment.BottomCenter),
            )
        }

        OnboardingCta(
            text = StringStore.text(context, "common.continue", language),
            onClick = onContinue,
            modifier = Modifier.padding(top = 14.dp),
        )
    }
}

/** The flag of the chosen language, in a disc that pulses on each change. */
@Composable
private fun LanguageFlagBadge(language: AppLanguage, pulse: Int, modifier: Modifier = Modifier) {
    val scale = remember { Animatable(1f) }
    LaunchedEffect(pulse) {
        if (pulse == 0) return@LaunchedEffect
        // Un léger creux qui se referme, sans rebond.
        scale.snapTo(0.92f)
        scale.animateTo(1f, OV2Calm.settle())
    }
    Box(
        modifier = modifier
            .size(72.dp)
            .graphicsLayer {
                scaleX = scale.value
                scaleY = scale.value
            }
            .background(DS.accentTint, CircleShape)
            .clearAndSetSemantics { },
        contentAlignment = Alignment.Center,
    ) {
        AnimatedContent(
            targetState = language,
            transitionSpec = {
                (scaleIn(OV2Calm.settle(), initialScale = 0.7f) + fadeIn(tween(160))) togetherWith fadeOut(tween(110))
            },
            label = "languageFlag",
        ) { shown ->
            Text(shown.flag, fontSize = 36.sp)
        }
    }
}

@Composable
private fun LanguageScrollHint(
    visible: Boolean,
    bounce: Float,
    language: AppLanguage,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    AnimatedVisibility(
        visible = visible,
        modifier = modifier,
        enter = fadeIn(),
        exit = fadeOut(tween(250)),
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp)
                    .background(Brush.verticalGradient(listOf(DS.canvas.copy(alpha = 0f), DS.canvas))),
            )
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(DS.canvas)
                    .padding(bottom = 8.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    Icons.Filled.KeyboardArrowDown,
                    contentDescription = null,
                    tint = DS.inkSecondary,
                    modifier = Modifier.size(18.dp).graphicsLayer { translationY = bounce },
                )
                Text(
                    text = StringStore.text(context, "onboardingV2.language.scrollHint", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 12.sp,
                    color = DS.inkSecondary,
                    modifier = Modifier.padding(horizontal = 8.dp),
                )
                Icon(
                    Icons.Filled.KeyboardArrowDown,
                    contentDescription = null,
                    tint = DS.inkSecondary,
                    modifier = Modifier.size(18.dp).graphicsLayer { translationY = bounce },
                )
            }
        }
    }
}

@Composable
private fun LanguageRow(
    language: AppLanguage,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = 52.dp)
            // The card sinks without vibrating: the vibration of the choice goes on release.
            .pressable(onClick = onClick, scaleDown = 0.98f, haptic = false)
            .dsOptionCard(if (selected) DSOptionState.Selected else DSOptionState.Idle)
            .semantics {
                this.selected = selected
                role = Role.RadioButton
            }
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(language.flag, fontSize = 24.sp)
        Text(
            text = language.displayName,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 16.sp,
            color = DS.ink,
            modifier = Modifier.weight(1f),
        )
        if (selected) {
            DSCheckBadge(size = 22.dp, fill = DS.accent)
        }
    }
}

// endregion

// region 14. Objectives

/**
 * Objectives — multiple choice, then « Continue ». Centred title, grey subtitle, the round
 * trophy illustration when the height allows it, then one option card per objective. A
 * chosen card turns blue; the subtitle says several may be picked.
 */
@Composable
internal fun ObjectivesStep(
    language: AppLanguage,
    selected: Set<String>,
    onToggle: (String) -> Unit,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val haptics = rememberHaptics()

    Column(modifier = Modifier.fillMaxSize()) {
        BoxWithConstraints(modifier = Modifier.weight(1f).fillMaxWidth()) {
            val art = introArtSize(base = 116.dp, available = maxHeight, reserved = 464.dp)
            Column(
                modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                IntroQuestionTitle(
                    title = StringStore.text(context, "onboardingV2.objective.title", language),
                    subtitle = StringStore.text(context, "onboardingV2.objective.subtitle", language),
                    modifier = Modifier.padding(top = 20.dp).dsStagger(0),
                )
                if (art > 0.dp) {
                    IntroRoundArt(
                        art = R.drawable.duel_trophy,
                        size = art,
                        modifier = Modifier.padding(top = 22.dp).ov2CalmIn(delayMillis = 120),
                    )
                }
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = ONBOARDING_SIDE_INSET)
                        .padding(top = 24.dp, bottom = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(9.dp),
                ) {
                    OBJECTIVE_KEYS.forEachIndexed { index, key ->
                        ObjectiveRow(
                            label = StringStore.text(context, "onboardingV2.objective.$key", language),
                            selected = key in selected,
                            modifier = Modifier.dsStagger(index, baseMillis = 180),
                            onClick = {
                                haptics.select()
                                onToggle(key)
                            },
                        )
                    }
                }
            }
        }
        OnboardingCta(
            text = StringStore.text(context, "common.continue", language),
            onClick = onContinue,
            enabled = selected.isNotEmpty(),
        )
    }
}

@Composable
private fun ObjectiveRow(
    label: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = 56.dp)
            .pressable(onClick = onClick, haptic = false)
            .dsOptionCard(if (selected) DSOptionState.Selected else DSOptionState.Idle)
            .semantics {
                this.selected = selected
                role = Role.Checkbox
            }
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = label,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 16.sp,
            lineHeight = 22.sp,
            color = DS.ink,
            modifier = Modifier.weight(1f),
        )
    }
}

// endregion

// region 16. « Sophia will help you »

/**
 * « Sophia va t'aider… », with the first name in front when one was given: the round path
 * illustration, the sentence in very large type that bold walks through, then a tap
 * anywhere continues.
 */
@Composable
internal fun ObjectiveIntroStep(language: AppLanguage, firstName: String, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    val words = remember(language, firstName) {
        personalizedText(context, "onboardingV2.objectiveIntro.title", firstName, language)
            .split(' ')
            .filter { it.isNotBlank() }
    }
    var boldCount by remember { mutableIntStateOf(0) }
    var canTap by remember { mutableStateOf(false) }
    LaunchedEffect(words) {
        delay(350)
        words.indices.forEach {
            boldCount = it + 1
            haptics.selection()
            delay(130)
        }
        delay(200)
        canTap = true
    }
    val pulse by rememberInfiniteTransition(label = "hint").animateFloat(
        initialValue = 0.45f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(1000), RepeatMode.Reverse),
        label = "pulse",
    )
    val hintIn by animateFloatAsState(if (canTap) 1f else 0f, tween(400), label = "hintIn")
    val ink = DS.ink
    val dim = DS.inkTertiary.copy(alpha = 0.6f)

    BoxWithConstraints(
        modifier = Modifier
            .fillMaxSize()
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
            ) {
                if (canTap) {
                    haptics.primary()
                    onContinue()
                }
            },
    ) {
        // The largest size that keeps the longest word on one line, font scale included.
        val fontScale = LocalDensity.current.fontScale
        val lineWidth = (maxWidth - ONBOARDING_SIDE_INSET * 2).value
        val longest = words.maxOfOrNull { it.length } ?: 0
        val size = listOf(34, 28, 22).firstOrNull { longest * 0.64f * it * fontScale <= lineWidth } ?: 20
        val art = if (maxHeight < 520.dp) 112.dp else 160.dp
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.weight(1f))
            IntroRoundArt(art = R.drawable.path_poster, size = art, modifier = Modifier.ov2CalmIn(delayMillis = 100))
            Spacer(Modifier.height(26.dp))
            Text(
                text = buildAnnotatedString {
                    words.forEachIndexed { index, word ->
                        val reached = index < boldCount
                        withStyle(
                            SpanStyle(
                                fontWeight = if (reached) FontWeight.ExtraBold else FontWeight.SemiBold,
                                color = if (reached) ink else dim,
                            ),
                        ) {
                            append(word)
                        }
                        if (index < words.lastIndex) append(" ")
                    }
                },
                fontFamily = PlusJakartaSans,
                fontSize = size.sp,
                lineHeight = (size * 1.2f).sp,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = ONBOARDING_SIDE_INSET)
                    .semantics { heading() },
            )
            Spacer(Modifier.weight(1f))
            Text(
                text = StringStore.text(context, "onboardingV2.tapToContinue", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 15.sp,
                color = DS.inkSecondary,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .padding(horizontal = ONBOARDING_SIDE_INSET)
                    .padding(bottom = 28.dp)
                    .alpha(hintIn * pulse),
            )
        }
    }
}

// endregion

// region 20. Questions

/**
 * La personne qui pose chaque question (dans l'ordre des clés `q1`…`q10`) : un avatar de
 * l'app à côté de la bulle, comme dans une conversation. Un jeu fixe et varié (âges,
 * origines, genres), le même à chaque passage.
 */
private val QUESTION_AVATARS: List<Int> = listOf(
    R.drawable.avatar_05,
    R.drawable.avatar_20,
    R.drawable.avatar_17,
    R.drawable.avatar_28,
    R.drawable.avatar_10,
    R.drawable.avatar_15,
    R.drawable.avatar_30,
    R.drawable.avatar_02,
    R.drawable.avatar_55,
    R.drawable.avatar_14,
)

/** Délai avant que « Continuer » n'apparaisse sur la page des questions, en millisecondes. */
private const val QUESTIONS_CTA_DELAY_MILLIS = 1000L

private const val QUESTIONS_HIGHLIGHT_KEY = "elevateOnboardingCore.questions.titleHighlight"

/**
 * « Avec Sophia, tu sauras **répondre à ces questions** »: the existing title without its
 * final colon (the bubbles are no longer a list), its core between `**`. The passage comes
 * from the string table, language by language; when it is missing or no longer part of the
 * title, the title comes back plain.
 */
private fun questionsTitle(context: android.content.Context, language: AppLanguage): String {
    val base = StringStore.text(context, "onboardingV2.questions.title", language)
        .trim()
        .trimEnd(':', '：', ' ', ' ', ' ')
    val passage = StringStore.text(context, QUESTIONS_HIGHLIGHT_KEY, language)
    if (passage == QUESTIONS_HIGHLIGHT_KEY || passage.isBlank() || base.contains("**") || !base.contains(passage)) {
        return base
    }
    return base.replaceFirst(passage, "**$passage**")
}

/**
 * « With Sophia, you'll be able to answer these questions » — the questions arrive one by
 * one as chat bubbles: one at the start (pale blue), the next at the end (solid blue), each
 * beside the avatar of the person asking it. Once the screen is full the oldest leaves by
 * the top and a new one lands at the bottom, so the ten questions loop for as long as the
 * page is shown.
 *
 * « Continuer » n'apparaît qu'après une seconde : le temps de voir arriver les premières
 * questions.
 */
@Composable
internal fun QuestionsStep(
    language: AppLanguage,
    richMotion: Boolean,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val reduceMotion = rememberOnboardingReduceMotion()
    val questions = remember(language) {
        (1..10).map { StringStore.text(context, "onboardingV2.questions.q$it", language) }
    }
    val title = remember(language) { questionsTitle(context, language) }
    // Bubbles sent so far. Never wraps: each bubble keeps a stable identity (its rank) and
    // the content loops by a modulo on the list.
    var sent by remember { mutableIntStateOf(0) }
    // « Continuer » attend une seconde, puis arrive en fondu ; sa place est gardée dès le
    // départ, donc rien ne bouge quand il apparaît.
    var ctaShown by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(QUESTIONS_CTA_DELAY_MILLIS)
        ctaShown = true
    }
    val ctaAlpha by animateFloatAsState(if (ctaShown) 1f else 0f, tween(300), label = "questionsCta")
    LaunchedEffect(Unit) {
        if (sent == 0) delay(350)
        while (true) {
            sent += 1
            // One vibration per bubble for a full turn, then the feed goes quiet.
            if (sent <= questions.size) haptics.soft()
            // The first bubbles follow quickly to fill the screen, then the talk settles.
            delay(
                when {
                    sent < 4 -> 480L
                    sent < 6 -> 800L
                    else -> 2400L
                },
            )
        }
    }

    Column(modifier = Modifier.fillMaxSize()) {
        Text(
            text = dsHighlighted(title, DS.accent),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Normal,
            fontSize = 25.sp,
            lineHeight = 32.sp,
            color = DS.ink,
            textAlign = TextAlign.Start,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = ONBOARDING_SIDE_INSET)
                .padding(top = 20.dp)
                .dsStagger(0)
                .semantics { heading() },
        )
        BoxWithConstraints(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .padding(top = 10.dp)
                .clipToBounds(),
        ) {
            // Bubbles shown at once, from the free height and the font size: the average
            // height of a bubble (one to two lines) and of the gap after it.
            val slot = if (LocalDensity.current.fontScale >= 1.3f) 98.dp else 72.dp
            val capacity = (maxHeight / slot).toInt().coerceIn(2, 6)
            val first = (sent - capacity).coerceAtLeast(0)
            QuestionFeed(modifier = Modifier.fillMaxSize().padding(horizontal = ONBOARDING_SIDE_INSET)) {
                // The bubble that just left stays one more beat, the time to fade out.
                for (rank in (first - 1).coerceAtLeast(0) until sent) {
                    key(rank) {
                        val visibility = remember { MutableTransitionState(false) }
                        visibility.targetState = rank >= first
                        val leading = rank % 2 == 0
                        val origin = TransformOrigin(
                            pivotFractionX = if (leading == (LocalLayoutDirection.current == LayoutDirection.Ltr)) 0f else 1f,
                            pivotFractionY = 1f,
                        )
                        // Named in full: inside the page's Column the bare name would resolve to
                        // the ColumnScope variant, which a nested scope may not call.
                        androidx.compose.animation.AnimatedVisibility(
                            visibleState = visibility,
                            enter = if (reduceMotion || !richMotion) {
                                fadeIn() + expandVertically()
                            } else {
                                scaleIn(DSMotion.reveal(), initialScale = 0.6f, transformOrigin = origin) +
                                    fadeIn(tween(220)) + expandVertically(DSMotion.reveal())
                            },
                            exit = if (reduceMotion || !richMotion) {
                                fadeOut() + shrinkVertically()
                            } else {
                                slideOutVertically(tween(320)) { -it / 2 } + fadeOut(tween(240)) +
                                    shrinkVertically(DSMotion.reveal(), shrinkTowards = Alignment.Top)
                            },
                        ) {
                            QuestionBubble(
                                text = questions[rank % questions.size],
                                leading = leading,
                                avatar = QUESTION_AVATARS[rank % QUESTION_AVATARS.size],
                                modifier = Modifier.padding(bottom = 12.dp),
                            )
                        }
                    }
                }
            }
        }
        OnboardingCta(
            text = StringStore.text(context, "common.continue", language),
            // Invisible, le bouton ne répond pas (ni au doigt, ni au lecteur d'écran).
            onClick = { if (ctaShown) onContinue() },
            modifier = Modifier
                .padding(top = 14.dp)
                .alpha(ctaAlpha)
                .then(if (ctaShown) Modifier else Modifier.clearAndSetSemantics { }),
        )
    }
}

/**
 * The column of bubbles: centred while it fits, anchored to the bottom once it is taller
 * than the room, so the newest question is always in view.
 */
@Composable
private fun QuestionFeed(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Layout(content = { Column(modifier = Modifier.fillMaxWidth()) { content() } }, modifier = modifier) { measurables, constraints ->
        val placeable = measurables.first().measure(
            constraints.copy(minHeight = 0, maxHeight = androidx.compose.ui.unit.Constraints.Infinity),
        )
        val height = if (constraints.hasBoundedHeight) constraints.maxHeight else placeable.height
        layout(constraints.maxWidth, height) {
            val y = if (placeable.height <= height) (height - placeable.height) / 2 else height - placeable.height
            placeable.place(0, y)
        }
    }
}

@Composable
private fun QuestionBubble(
    text: String,
    leading: Boolean,
    @DrawableRes avatar: Int,
    modifier: Modifier = Modifier,
) {
    val shape = RoundedCornerShape(
        topStart = if (leading) 4.dp else 18.dp,
        topEnd = if (leading) 18.dp else 4.dp,
        bottomEnd = 18.dp,
        bottomStart = 18.dp,
    )
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(10.dp, if (leading) Alignment.Start else Alignment.End),
        verticalAlignment = Alignment.Top,
    ) {
        if (leading) QuestionAvatar(avatar) else Spacer(Modifier.width(14.dp))
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 15.sp,
            lineHeight = 20.sp,
            color = if (leading) DS.ink else Color.White,
            modifier = Modifier
                .weight(1f, fill = false)
                .clip(shape)
                .background(if (leading) DS.accentTint else DS.accent)
                .padding(horizontal = 15.dp, vertical = 11.dp),
        )
        if (leading) Spacer(Modifier.width(14.dp)) else QuestionAvatar(avatar)
    }
}

/**
 * L'avatar rond à côté d'une bulle : la personne qui pose la question, cerclée de blanc puis
 * d'un filet.
 */
@Composable
private fun QuestionAvatar(@DrawableRes avatar: Int) {
    Box(
        modifier = Modifier
            .size(44.dp)
            .background(DS.surface, CircleShape)
            .border(1.5.dp, DS.hairline, CircleShape)
            .padding(2.dp)
            .clearAndSetSemantics { },
        contentAlignment = Alignment.Center,
    ) {
        Image(
            painter = painterResource(avatar),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxSize().clip(CircleShape).background(DS.accentTint),
        )
    }
}

// endregion
