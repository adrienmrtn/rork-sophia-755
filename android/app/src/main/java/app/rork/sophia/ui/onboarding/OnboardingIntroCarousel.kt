package app.rork.sophia.ui.onboarding

import android.content.Context
import androidx.annotation.DrawableRes
import androidx.compose.animation.core.AnimationSpec
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.animateIntAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.Public
import androidx.compose.material.icons.filled.Replay
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.EmojiEvents
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.listSaver
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import app.rork.sophia.R
import app.rork.sophia.data.AuthorStore
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.stripInlineMarkup
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.QuizQuestion
import app.rork.sophia.domain.QuizQuestionType
import app.rork.sophia.domain.Subject
import app.rork.sophia.domain.formatted
import app.rork.sophia.ui.components.DSCheckBadge
import app.rork.sophia.ui.components.DSEyebrow
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.DSOptionState
import app.rork.sophia.ui.components.dsHighlighted
import app.rork.sophia.ui.components.dsOptionCard
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.uppercaseInApp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import java.util.Locale

// region Courses shown as examples

/**
 * The courses of the catalogue the presentation screens borrow (lesson card, audio player,
 * quiz question). A course withheld from a language is replaced by another one.
 */
internal object OnboardingIntroCatalog {
    /**
     * The most-read courses of the app, also picked for a catchy title and varied subjects
     * (same list as iOS).
     */
    val featuredCourseIds = listOf(
        "course_42_pourquoi_reve_t_on",
        "course_67_qu_est_ce_qu_un_trou_noir",
        "course_201_la_naissance_du_conflit_israelo_palestin",
        "course_150_la_nuit_etoilee_van_gogh",
    )

    /** The course of the « quiz » and « audio » illustrations. */
    const val BLACK_HOLE_COURSE_ID = "course_67_qu_est_ce_qu_un_trou_noir"

    /** The course of the « a Sophia lesson » card. */
    const val DREAM_COURSE_ID = "course_42_pourquoi_reve_t_on"

    /** The course asked for, else the first featured course the language carries, else any. */
    fun pick(courses: List<CourseSummary>, preferring: String): CourseSummary? {
        val byId = courses.associateBy { it.id }
        return byId[preferring]
            ?: featuredCourseIds.firstNotNullOfOrNull { byId[it] }
            ?: courses.firstOrNull()
    }

    /** From the catalogue already in memory; null until it is loaded. Never reads a file. */
    fun cachedCourse(language: AppLanguage, preferring: String): CourseSummary? =
        ContentCatalog.cachedSummaries(language)?.let { pick(it, preferring) }

    suspend fun course(context: Context, language: AppLanguage, preferring: String): CourseSummary? =
        runCatching { pick(ContentCatalog.summariesAsync(context.applicationContext, language), preferring) }
            .getOrNull()
}

// endregion

// region Carousel state

/**
 * Current page and clock of the presentation carousel. The coordinator owns it: it feeds
 * the segments of the header, and its back arrow walks the pages back first.
 */
@Stable
internal class OnboardingCarouselState(initialPage: Int = 0, initialHold: Boolean = false) {
    var page by mutableIntStateOf(initialPage.coerceIn(0, PAGE_COUNT - 1))
        private set

    /** Bumped each time the page starts its five seconds again. */
    var clock by mutableIntStateOf(0)
        private set

    /**
     * The current page waits for the user (they came back to it): letting it move on by
     * itself would send them back where they came from.
     */
    var holdsCurrentPage by mutableStateOf(initialHold)
        private set

    /**
     * Auto-advance cut for the whole carousel (animations removed, screen reader): content
     * that changes on its own gets in the way of those readers.
     */
    var autoAdvanceDisabled by mutableStateOf(false)

    /** How far the current page is through its time, 0 to 1: the fill of its header segment. */
    var progress by mutableFloatStateOf(0f)

    /** Does the current page advance by itself? */
    val isRunning: Boolean get() = !holdsCurrentPage && !autoAdvanceDisabled

    fun go(to: Int, hold: Boolean = false) {
        page = to.coerceIn(0, PAGE_COUNT - 1)
        holdsCurrentPage = hold
        restartClock()
    }

    /** Sets the page's clock back to zero (the carousel appears, the app comes back). */
    fun restartClock() {
        progress = 0f
        clock += 1
    }

    companion object {
        const val PAGE_COUNT = 4

        /** Time a page stays before moving on by itself, in milliseconds. */
        const val PAGE_MILLIS = 5000

        /** Keeps the page across a rotation; the clock starts again. */
        val StateSaver: Saver<OnboardingCarouselState, Any> = listSaver<OnboardingCarouselState, Int>(
            save = { listOf(it.page, if (it.holdsCurrentPage) 1 else 0) },
            restore = { OnboardingCarouselState(initialPage = it[0], initialHold = it[1] == 1) },
        )
    }
}

// endregion

// region Carousel

/**
 * Screens 5 to 8 — four presentation pages (quiz, path, duels, audio) that advance by
 * themselves every five seconds. A tap or a swipe advances too; « Continue » goes to the
 * next page, then to the next screen; the end of the fourth page moves on by itself.
 *
 * Same layout on the four: illustration (flexible), title of fixed height, button. Seule la
 * dernière page (« Écoute tes cours ») garde un sous-titre ; sur les trois premières, sa
 * place revient à l'illustration. The segments and the back arrow live in the coordinator's
 * header, fed by [state].
 */
@Composable
internal fun IntroCarouselStep(
    language: AppLanguage,
    state: OnboardingCarouselState,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val reduceMotion = rememberOnboardingReduceMotion()
    val screenReader = rememberOnboardingScreenReader()
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    val lastPage = OnboardingCarouselState.PAGE_COUNT - 1
    val leave by rememberUpdatedState(onContinue)

    // Back in the foreground, the page takes its five whole seconds again.
    var resumed by remember { mutableStateOf(true) }
    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_RESUME -> {
                    resumed = true
                    state.restartClock()
                }
                Lifecycle.Event.ON_PAUSE -> resumed = false
                else -> Unit
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }
    LaunchedEffect(reduceMotion, screenReader) {
        state.autoAdvanceDisabled = reduceMotion || screenReader
    }

    // Next page, or next screen after the last one.
    fun goNext(auto: Boolean) {
        if (state.page < lastPage) {
            if (auto) haptics.tick()
            state.go(state.page + 1)
        } else {
            leave()
        }
    }

    // A touch on the page: like « Continue », with a light tick (leaving the carousel
    // already has the one of the screen change).
    fun userAdvance() {
        if (state.page < lastPage) haptics.tap()
        goNext(auto = false)
    }

    fun goPrevious() {
        if (state.page <= 0) return
        haptics.tap()
        state.go(state.page - 1, hold = true)
    }

    // The clock of the page: it fills the header segment, then moves on. Restarted on each
    // new page, each reset, and when auto-advance stops or resumes.
    LaunchedEffect(state.page, state.clock, state.isRunning, resumed) {
        if (!state.isRunning || !resumed) return@LaunchedEffect
        val start = withFrameNanos { it }
        var fraction = 0f
        while (fraction < 1f) {
            fraction = withFrameNanos { now ->
                ((now - start) / 1_000_000f / OnboardingCarouselState.PAGE_MILLIS).coerceIn(0f, 1f)
            }
            state.progress = fraction
        }
        goNext(auto = true)
    }

    Column(modifier = Modifier.fillMaxSize()) {
        // The four pages stay mounted, stacked: the current one is opaque, the others wait
        // shifted on each side. The slide thus always follows the navigation, forwards and back.
        Box(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .pointerInput(Unit) { detectTapGestures { userAdvance() } }
                .pointerInput(rtl) {
                    val threshold = 40.dp.toPx()
                    var travelled = 0f
                    detectHorizontalDragGestures(
                        onDragStart = { travelled = 0f },
                        onDragEnd = {
                            // Swiping towards the start of the line advances, towards the end goes back.
                            val towardNext = if (rtl) travelled else -travelled
                            if (towardNext > threshold) {
                                userAdvance()
                            } else if (towardNext < -threshold) {
                                goPrevious()
                            }
                        },
                        onHorizontalDrag = { _, amount -> travelled += amount },
                    )
                },
        ) {
            CarouselSlot(0, state.page, reduceMotion, rtl) { IntroQuizPage(language, active = state.page == 0) }
            CarouselSlot(1, state.page, reduceMotion, rtl) { IntroRoutePage(language, active = state.page == 1) }
            CarouselSlot(2, state.page, reduceMotion, rtl) { IntroDuelsPage(language, active = state.page == 2) }
            CarouselSlot(3, state.page, reduceMotion, rtl) { IntroAudioPage(language, active = state.page == 3) }
        }
        OnboardingCta(
            text = StringStore.text(context, "common.continue", language),
            onClick = { goNext(auto = false) },
            modifier = Modifier.padding(top = 20.dp),
        )
    }
}

/** One page of the stack: opaque when current; upcoming pages wait on the reading side, past ones on the other. */
@Composable
private fun CarouselSlot(
    index: Int,
    page: Int,
    reduceMotion: Boolean,
    rtl: Boolean,
    content: @Composable () -> Unit,
) {
    val isCurrent = index == page
    val spec: AnimationSpec<Float> = if (reduceMotion) tween(200) else DSMotion.reveal()
    val alpha by animateFloatAsState(if (isCurrent) 1f else 0f, spec, label = "carouselAlpha")
    val side = when {
        reduceMotion || isCurrent -> 0f
        index > page -> 1f
        else -> -1f
    } * (if (rtl) -1f else 1f)
    val shift by animateFloatAsState(side, spec, label = "carouselShift")
    Box(
        modifier = Modifier
            .fillMaxSize()
            .graphicsLayer {
                this.alpha = alpha.coerceIn(0f, 1f)
                translationX = shift * 26.dp.toPx()
            }
            .then(if (isCurrent) Modifier else Modifier.clearAndSetSemantics { }),
    ) {
        content()
    }
}

/**
 * Runs [action] once, when the page becomes the current one of the carousel (or if it is
 * already). The four pages are mounted from the start: a plain `LaunchedEffect(Unit)` would
 * play the animations of the pages still hidden.
 */
@Composable
internal fun OnIntroPageActivated(active: Boolean, action: suspend () -> Unit) {
    var fired by remember { mutableStateOf(false) }
    LaunchedEffect(active) {
        if (active && !fired) {
            fired = true
            action()
        }
    }
}

/**
 * Shared frame of the four pages: the illustration in what is left (scaled down as one
 * block when it does not fit), then a title block of fixed height and, quand la page en a
 * un ([subtitle] non nul), un bloc de sous-titre de hauteur fixe lui aussi.
 */
@Composable
private fun IntroPageFrame(
    title: String,
    subtitle: String? = null,
    visual: @Composable () -> Unit,
) {
    Column(modifier = Modifier.fillMaxSize().padding(horizontal = ONBOARDING_SIDE_INSET)) {
        OnboardingFitHeight(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .padding(top = 10.dp)
                .clearAndSetSemantics { },
        ) {
            visual()
        }
        // Three lines of title (four by tightening) and, when there is one, two of subtitle.
        OnboardingShrinkText(
            text = dsHighlighted(title, DS.accent),
            style = TextStyle(
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Medium,
                fontSize = 22.sp,
                lineHeight = 30.sp,
                color = DS.ink,
            ),
            maxLines = 4,
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 16.dp)
                .height(96.dp)
                .semantics { heading() },
        )
        if (subtitle != null) {
            OnboardingShrinkText(
                text = AnnotatedString(subtitle),
                style = TextStyle(
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Normal,
                    fontSize = 15.sp,
                    lineHeight = 21.sp,
                    color = DS.inkSecondary,
                ),
                maxLines = 3,
                minScale = 0.75f,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 8.dp)
                    .height(44.dp),
            )
        }
    }
}

// endregion

// region 5. Quiz

/** What the card shows: a multiple-choice question, its right answer and two others. */
private data class QuizSample(
    /** La matière du cours, au-dessus de la question. */
    val eyebrow: String,
    val question: String,
    /** The answers in display order. */
    val options: List<String>,
    val correctIndex: Int,
)

/**
 * A multiple-choice question of the black-hole course (the second of the quiz for
 * preference, la même que sur iOS), else the example of the string table.
 */
private suspend fun loadQuizSample(context: Context, language: AppLanguage): QuizSample =
    withContext(Dispatchers.IO) {
        val app = context.applicationContext
        val fromCatalogue = runCatching {
            val course = ContentCatalog.summaries(app, language)
                .firstOrNull { it.id == OnboardingIntroCatalog.BLACK_HOLE_COURSE_ID }
            course?.let { catalogueQuizSample(app, language, it, ContentCatalog.quizQuestions(app, language, it.id)) }
        }.getOrNull()
        fromCatalogue ?: QuizSample(
            eyebrow = StringStore.text(app, "subject.${Subject.SCIENCES.storageKey}.short", language),
            question = StringStore.text(app, "onboardingV2.elevate.quiz.sample.question", language),
            options = listOf(
                StringStore.text(app, "onboardingV2.elevate.quiz.sample.correct", language),
                StringStore.text(app, "onboardingV2.elevate.quiz.sample.wrong1", language),
                StringStore.text(app, "onboardingV2.elevate.quiz.sample.wrong2", language),
            ),
            correctIndex = 0,
        )
    }

private fun catalogueQuizSample(
    context: Context,
    language: AppLanguage,
    course: CourseSummary,
    quiz: List<QuizQuestion>,
): QuizSample? {
    // The second question and the following ones first, the first as a last resort.
    val order = quiz.indices.drop(1) + quiz.indices.take(1)
    for (index in order) {
        val question = quiz[index]
        val options = question.options ?: continue
        val correct = question.correctIndex ?: continue
        if (question.type != QuizQuestionType.MCQ || options.size < 3 || correct !in options.indices) continue

        // The right answer and the first two others, in their original order.
        val kept = (listOf(correct) + options.indices.filter { it != correct }.take(2)).sorted()
        val texts = kept.map { stripInlineMarkup(options[it]) }
        val prompt = stripInlineMarkup(question.question)
        // A question or an answer too long does not fit in the card.
        if (prompt.length > 110 || texts.any { it.length > 100 }) continue

        return QuizSample(
            eyebrow = StringStore.text(context, "subject.${course.subjectEnum.storageKey}.short", language),
            question = prompt,
            options = texts,
            correctIndex = kept.indexOf(correct).coerceAtLeast(0),
        )
    }
    return null
}

/**
 * « Sophia tests you with fun quizzes »: a real question of the catalogue, the right answer
 * that validates itself, then « Excellent! ».
 */
@Composable
private fun IntroQuizPage(language: AppLanguage, active: Boolean) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val reduceMotion = rememberOnboardingReduceMotion()
    var sample by remember(language) { mutableStateOf<QuizSample?>(null) }
    LaunchedEffect(language) { sample = loadQuizSample(context, language) }
    var answered by remember { mutableStateOf(false) }
    // The answers are laid out; a moment later the right one validates itself, as if the
    // reader had just touched it.
    OnIntroPageActivated(active) {
        if (!reduceMotion) delay(900)
        answered = true
        if (!reduceMotion) haptics.success()
    }

    IntroPageFrame(title = StringStore.text(context, "onboardingV2.intro.quizzes.title", language)) {
        sample?.let { QuizCard(sample = it, answered = answered, language = language) }
    }
}

/**
 * La carte de la question, volontairement dépouillée : la matière, la question, trois
 * réponses bien espacées, puis « Excellent ! » quand la bonne se valide. Ni barre de
 * progression, ni combo, ni compteur : une seule chose à lire à la fois.
 */
@Composable
private fun QuizCard(sample: QuizSample, answered: Boolean, language: AppLanguage) {
    val context = LocalContext.current
    val verdict by animateFloatAsState(if (answered) 1f else 0f, OV2Calm.settle(), label = "quizVerdict")
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 2.dp)
            .ov2Card()
            .padding(horizontal = 20.dp, vertical = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        DSEyebrow(text = sample.eyebrow)
        Text(
            text = sample.question,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Normal,
            fontSize = 20.sp,
            lineHeight = 27.sp,
            color = DS.ink,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(top = 10.dp),
        )
        Column(
            modifier = Modifier.fillMaxWidth().padding(top = 22.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            sample.options.forEachIndexed { index, option ->
                QuizOptionRow(text = option, answered = answered, isCorrect = index == sample.correctIndex)
            }
        }
        // Le verdict, sous les réponses : sa place est gardée, il arrive en fondu.
        Row(
            modifier = Modifier
                .padding(top = 20.dp)
                .graphicsLayer {
                    alpha = verdict.coerceIn(0f, 1f)
                    translationY = (1f - verdict) * 8.dp.toPx()
                },
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Box(
                modifier = Modifier.size(24.dp).background(DS.successTint, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Filled.Check, contentDescription = null, tint = DS.success, modifier = Modifier.size(14.dp))
            }
            Text(
                text = StringStore.text(context, "quiz.feedback.excellent", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 15.sp,
                color = DS.success,
            )
        }
    }
}

@Composable
private fun QuizOptionRow(text: String, answered: Boolean, isCorrect: Boolean) {
    val state = when {
        !answered -> DSOptionState.Idle
        isCorrect -> DSOptionState.Correct
        else -> DSOptionState.Dimmed
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 50.dp)
            .dsOptionCard(state, RoundedCornerShape(14.dp))
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = if (answered && isCorrect) FontWeight.Bold else FontWeight.Medium,
            fontSize = 14.sp,
            lineHeight = 19.sp,
            color = when {
                !answered -> DS.ink
                isCorrect -> DS.success
                else -> DS.inkTertiary
            },
            modifier = Modifier.weight(1f),
        )
        if (answered && isCorrect) {
            DSCheckBadge(size = 22.dp)
        }
    }
}

// endregion

// region 6. Personalized path

/**
 * « Sophia builds you a personalized path »: the first level of the Parcours, two courses
 * done, the next one to read, a fourth still closed.
 */
@Composable
private fun IntroRoutePage(language: AppLanguage, active: Boolean) {
    val context = LocalContext.current
    IntroPageFrame(title = StringStore.text(context, "onboardingV2.intro.route.title", language)) {
        OnboardingPathPreview(language = language, active = active)
    }
}

// endregion

// region 7. Duels

// Sample leaderboard: handles from the string table, avatars from the app's avatar set,
// trophies purely illustrative (same example as iOS).
private val DUEL_RIVAL_AVATARS = listOf(
    R.drawable.avatar_09,
    R.drawable.avatar_03,
    R.drawable.avatar_36,
    R.drawable.avatar_48,
)
private val DUEL_RIVAL_TROPHIES = listOf(412, 341, 298, 275)
private val DUEL_YOU_AVATAR = R.drawable.avatar_22
private const val DUEL_START_RANK = 3
private const val DUEL_END_RANK = 1
private const val DUEL_START_TROPHIES = 286
private const val DUEL_END_TROPHIES = 386

private val TROPHY_GOLD = Color(0xFFB17F10)
private val TROPHY_TINT = Color(0xFFFBEFC9)
private val MEDAL_COLORS = listOf(Color(0xFFE6B233), Color(0xFFC9D0DB), Color(0xFFE3B58E))

private val DUEL_ROW_HEIGHT = 50.dp
private val DUEL_ROW_GAP = 2.dp

private data class DuelRow(
    val id: String,
    val name: String,
    @DrawableRes val avatar: Int,
    val trophies: Int,
    val isYou: Boolean,
)

/**
 * « Challenge your friends to a duel »: a sample leaderboard where « You » wins trophies
 * and climbs two places.
 */
@Composable
private fun IntroDuelsPage(language: AppLanguage, active: Boolean) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val reduceMotion = rememberOnboardingReduceMotion()
    // Place of « You » in the leaderboard (0 for the first).
    var youRank by remember { mutableIntStateOf(DUEL_START_RANK) }
    var youTrophies by remember { mutableIntStateOf(DUEL_START_TROPHIES) }
    var rowsShown by remember { mutableStateOf(false) }
    // The leaderboard lands, then « You » wins a hundred trophies and moves up to second.
    OnIntroPageActivated(active) {
        if (reduceMotion) {
            rowsShown = true
            youRank = DUEL_END_RANK
            youTrophies = DUEL_END_TROPHIES
            return@OnIntroPageActivated
        }
        delay(150)
        rowsShown = true
        delay(950)
        youTrophies = DUEL_END_TROPHIES
        haptics.tick()
        delay(350)
        youRank = DUEL_END_RANK
        haptics.success()
    }

    val rivals = remember(language) {
        DUEL_RIVAL_AVATARS.indices.map { index ->
            val handle = StringStore.text(context, "onboardingV2.elevate.duels.sample.handle${index + 1}", language)
            DuelRow(
                id = "rival$index",
                name = "@$handle",
                avatar = DUEL_RIVAL_AVATARS[index],
                trophies = DUEL_RIVAL_TROPHIES[index],
                isYou = false,
            )
        }
    }
    val shownTrophies by animateIntAsState(youTrophies, tween(700), label = "duelTrophies")
    val you = DuelRow(
        id = "you",
        name = StringStore.text(context, "duel.you", language),
        avatar = DUEL_YOU_AVATAR,
        trophies = shownTrophies,
        isYou = true,
    )
    val rows = rivals.toMutableList().apply { add(youRank.coerceIn(0, rivals.size), you) }
    val rowsProgress by animateFloatAsState(if (rowsShown) 1f else 0f, DSMotion.reveal(), label = "duelRows")

    IntroPageFrame(title = StringStore.text(context, "onboardingV2.elevate.duels.title", language)) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 2.dp)
                .ov2Card()
                .padding(vertical = 16.dp),
        ) {
            DuelsHeader(language, modifier = Modifier.padding(horizontal = 16.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 12.dp)
                    .padding(horizontal = 8.dp)
                    .height(DUEL_ROW_HEIGHT * rows.size + DUEL_ROW_GAP * (rows.size - 1))
                    .graphicsLayer {
                        alpha = rowsProgress.coerceIn(0f, 1f)
                        translationY = (1f - rowsProgress) * 10.dp.toPx()
                    },
            ) {
                // Composed in a stable order (rivals, then « You ») and moved by offset, so a
                // change of rank slides the rows instead of redrawing them.
                (rivals + you).forEach { row ->
                    val rank = rows.indexOfFirst { it.id == row.id }
                    // Le rang glisse à sa nouvelle place et s'y arrête, sans rebond.
                    val slot by animateFloatAsState(rank.toFloat(), tween(420, easing = FastOutSlowInEasing), label = "duelSlot")
                    DuelRowView(
                        row = row,
                        rank = rank + 1,
                        modifier = Modifier
                            .zIndex(if (row.isYou) 1f else 0f)
                            .offset { IntOffset(0, ((DUEL_ROW_HEIGHT + DUEL_ROW_GAP).toPx() * slot).toInt()) },
                    )
                }
            }
            DuelsFooter(language, modifier = Modifier.padding(top = 10.dp).padding(horizontal = 16.dp))
        }
    }
}

@Composable
private fun DuelsHeader(language: AppLanguage, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Box(
            modifier = Modifier.size(28.dp).background(TROPHY_TINT, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Outlined.EmojiEvents, contentDescription = null, tint = TROPHY_GOLD, modifier = Modifier.size(16.dp))
        }
        Column(verticalArrangement = Arrangement.spacedBy(1.dp)) {
            DSEyebrow(text = StringStore.text(context, "duel.trophies.title", language))
            Text(
                text = StringStore.text(context, "duel.friends.title", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 13.sp,
                color = DS.ink,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

@Composable
private fun DuelRowView(row: DuelRow, rank: Int, modifier: Modifier = Modifier) {
    val onPodium = rank <= MEDAL_COLORS.size
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(DUEL_ROW_HEIGHT)
            .background(if (row.isYou) DS.accentTint else Color.Transparent, RoundedCornerShape(12.dp))
            .padding(horizontal = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Box(
            modifier = Modifier
                .size(24.dp)
                .background(if (onPodium) MEDAL_COLORS[rank - 1] else Color.Transparent, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = rank.toString(),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 12.sp,
                color = if (onPodium) Color.White else DS.inkTertiary,
            )
        }
        Image(
            painter = painterResource(row.avatar),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.size(34.dp).clip(CircleShape),
        )
        Text(
            text = row.name,
            fontFamily = PlusJakartaSans,
            fontWeight = if (row.isYou) FontWeight.ExtraBold else FontWeight.SemiBold,
            fontSize = 13.sp,
            color = DS.ink,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f),
        )
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(3.dp)) {
            Icon(Icons.Outlined.EmojiEvents, contentDescription = null, tint = TROPHY_GOLD, modifier = Modifier.size(13.dp))
            Text(
                text = row.trophies.toString(),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 13.sp,
                color = DS.ink,
            )
        }
    }
}

/** The gesture that starts a duel between friends, shown as on a friend's card. */
@Composable
private fun DuelsFooter(language: AppLanguage, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val rule = DS.hairline
    Column(modifier = modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
        Canvas(modifier = Modifier.fillMaxWidth().height(1.5.dp)) {
            drawLine(
                color = rule,
                start = Offset(0f, size.height / 2f),
                end = Offset(size.width, size.height / 2f),
                strokeWidth = size.height,
                pathEffect = PathEffect.dashPathEffect(floatArrayOf(4.dp.toPx(), 4.dp.toPx())),
            )
        }
        Row(
            modifier = Modifier
                .padding(top = 12.dp)
                .background(DS.accent, RoundedCornerShape(10.dp))
                .padding(horizontal = 14.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Icon(Icons.Filled.Bolt, contentDescription = null, tint = Color.White, modifier = Modifier.size(13.dp))
            Text(
                text = StringStore.text(context, "duel.friend.challenge", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 12.sp,
                color = Color.White,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

// endregion

// region 8. Audio

/** Announced length of a course, in minutes (the « 10 min » of the lessons). */
private const val AUDIO_LESSON_MINUTES = 10

/** Where playback stands when the page opens, in seconds. */
private const val AUDIO_START_SECONDS = 192

private fun audioClock(seconds: Int): String {
    val safe = seconds.coerceAtLeast(0)
    return String.format(Locale.ROOT, "%d:%02d", safe / 60, safe % 60)
}

/**
 * « Listen to your courses when you can't read them »: the subway illustration and, laid
 * over it, the audio player of a real course whose time runs.
 */
@Composable
private fun IntroAudioPage(language: AppLanguage, active: Boolean) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val reduceMotion = rememberOnboardingReduceMotion()
    val totalSeconds = AUDIO_LESSON_MINUTES * 60
    var course by remember(language) {
        mutableStateOf(OnboardingIntroCatalog.cachedCourse(language, OnboardingIntroCatalog.BLACK_HOLE_COURSE_ID))
    }
    var authorName by remember(language) { mutableStateOf<String?>(null) }
    LaunchedEffect(language) {
        val picked = course
            ?: OnboardingIntroCatalog.course(context, language, OnboardingIntroCatalog.BLACK_HOLE_COURSE_ID)
        course = picked
        authorName = picked?.let { found ->
            withContext(Dispatchers.IO) {
                runCatching { AuthorStore.authorForCourse(context.applicationContext, found.id)?.name }.getOrNull()
            }
        }
    }
    var playerIn by remember { mutableStateOf(false) }
    var elapsed by remember { mutableIntStateOf(AUDIO_START_SECONDS) }
    OnIntroPageActivated(active) {
        if (reduceMotion) {
            playerIn = true
            return@OnIntroPageActivated
        }
        delay(200)
        playerIn = true
        delay(150)
        haptics.soft()
        // The time elapsed since the page opened, one beat per second.
        while (elapsed < totalSeconds) {
            delay(1000)
            elapsed += 1
        }
    }
    val playerProgress by animateFloatAsState(if (playerIn) 1f else 0f, DSMotion.reveal(), label = "audioPlayer")
    val played by animateFloatAsState(
        targetValue = elapsed.toFloat() / totalSeconds,
        animationSpec = tween(1000, easing = LinearEasing),
        label = "audioPlayed",
    )
    // « Stacy Jankowski · 10 min »: the author of the course when the catalogue knows them.
    val duration = StringStore.text(context, "onboardingV2.screenTime.minutes", language, AUDIO_LESSON_MINUTES)
    val caption = authorName?.takeIf { it.isNotBlank() }?.let { "$it · $duration" } ?: duration

    IntroPageFrame(
        title = StringStore.text(context, "onboardingV2.elevate.audio.title", language),
        subtitle = StringStore.text(context, "onboardingV2.elevate.audio.subtitle", language),
    ) {
        Box(modifier = Modifier.fillMaxWidth().height(372.dp)) {
            Image(
                painter = painterResource(R.drawable.onb_audio_metro),
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .fillMaxWidth()
                    .height(300.dp)
                    .clip(RoundedCornerShape(24.dp)),
            )
            // The player: cover, title, author and length, the playback bar, the controls.
            Column(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(horizontal = 14.dp)
                    .padding(bottom = 2.dp)
                    .graphicsLayer {
                        alpha = playerProgress.coerceIn(0f, 1f)
                        translationY = (1f - playerProgress) * 24.dp.toPx()
                    }
                    .fillMaxWidth()
                    .ov2Card(shape = RoundedCornerShape(18.dp))
                    .padding(12.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    OnboardingCover(
                        courseId = course?.id,
                        modifier = Modifier.size(44.dp).clip(RoundedCornerShape(10.dp)),
                        edgePx = 160,
                    )
                    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
                        Text(
                            text = course?.title.orEmpty(),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 13.sp,
                            color = DS.ink,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                        Text(
                            text = caption,
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Normal,
                            fontSize = 12.sp,
                            color = DS.inkSecondary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                }
                AudioProgressBar(fraction = { played })
                Row(verticalAlignment = Alignment.CenterVertically) {
                    AudioClockText(audioClock(elapsed), TextAlign.Start)
                    Spacer(Modifier.weight(1f))
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                        AudioSkipGlyph(forward = false)
                        Box(
                            modifier = Modifier.size(42.dp).background(DS.accent, CircleShape),
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(Icons.Filled.Pause, contentDescription = null, tint = Color.White, modifier = Modifier.size(22.dp))
                        }
                        AudioSkipGlyph(forward = true)
                    }
                    Spacer(Modifier.weight(1f))
                    AudioClockText(audioClock(totalSeconds), TextAlign.End)
                }
            }
        }
    }
}

@Composable
private fun AudioClockText(text: String, align: TextAlign) {
    Text(
        text = text,
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.SemiBold,
        fontSize = 11.sp,
        color = DS.inkSecondary,
        textAlign = align,
        maxLines = 1,
        modifier = Modifier.width(44.dp),
    )
}

/** The playback bar: a thin track, the part played in blue, a round knob at its end. */
@Composable
private fun AudioProgressBar(fraction: () -> Float) {
    val track = DS.hairline
    val tint = DS.accent
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(12.dp)
            .drawBehind {
                val clamped = fraction().coerceIn(0f, 1f)
                val bar = 4.dp.toPx()
                val top = (size.height - bar) / 2f
                // A media bar reads from left to right in every language.
                drawRoundRect(track, Offset(0f, top), Size(size.width, bar), CornerRadius(bar / 2f))
                drawRoundRect(tint, Offset(0f, top), Size(size.width * clamped, bar), CornerRadius(bar / 2f))
                drawCircle(tint, radius = size.height / 2f, center = Offset(size.width * clamped, size.height / 2f))
            },
    )
}

/** « 15 seconds back / forward »: the circular arrow with its number inside. */
@Composable
private fun AudioSkipGlyph(forward: Boolean) {
    Box(modifier = Modifier.size(26.dp), contentAlignment = Alignment.Center) {
        Icon(
            Icons.Filled.Replay,
            contentDescription = null,
            tint = DS.ink,
            modifier = Modifier.fillMaxSize().graphicsLayer { scaleX = if (forward) -1f else 1f },
        )
        Text(
            text = "15",
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 7.sp,
            color = DS.ink,
            modifier = Modifier.offset(y = 1.5.dp),
        )
    }
}

// endregion

// region 9. Social proof

/**
 * The reviews shown here (keys `onboardingV2.review.t<n>`): the end of the list, so as not
 * to open on the same ones as the reviews page, later in the flow.
 */
private val SOCIAL_REVIEW_INDICES = listOf(4, 5, 6)
private const val SOCIAL_STAR_COUNT = 5

/**
 * Screen 9 — social proof, after the carousel: « Join the 500,000 users… » in a card, two
 * laurels (the five stars with the number of users, the store rating), three user reviews,
 * the availability in more than 140 countries, and the « Let's go » button.
 *
 * Every figure is one the app already showed (title, user count, rating, countries); the
 * reviews are those of the « what our users think » page.
 */
@Composable
internal fun SocialProofStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val reduceMotion = rememberOnboardingReduceMotion()
    val photos = remember { studentPhotos(context).take(4) }
    var laurelsIn by remember { mutableStateOf(reduceMotion) }
    var starsShown by remember { mutableIntStateOf(if (reduceMotion) SOCIAL_STAR_COUNT else 0) }
    // The laurels land, then the stars light up one by one.
    LaunchedEffect(Unit) {
        if (reduceMotion) return@LaunchedEffect
        delay(250)
        laurelsIn = true
        haptics.soft()
        delay(150)
        for (count in 1..SOCIAL_STAR_COUNT) {
            starsShown = count
            haptics.tick()
            delay(70)
        }
    }
    val laurelsProgress by animateFloatAsState(if (laurelsIn) 1f else 0f, OV2Calm.settle(), label = "socialLaurels")

    // Card, laurels and reviews outgrow a small phone at a large font size: the content
    // scrolls, the button stays pinned.
    OnboardingPage(
        contentArrangement = Arrangement.Top,
        footer = {
            OnboardingCta(
                text = StringStore.text(context, "onboardingV2.intro.social.cta", language),
                onClick = onContinue,
                modifier = Modifier.padding(top = 10.dp),
            )
        },
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = ONBOARDING_SIDE_INSET),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = dsHighlighted(StringStore.text(context, "onboardingV2.intro.social.title", language), DS.accent),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Normal,
                fontSize = 20.sp,
                lineHeight = 27.sp,
                color = DS.ink,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .padding(top = 12.dp)
                    .dsStagger(0)
                    .fillMaxWidth()
                    .ov2Card()
                    .padding(horizontal = 18.dp, vertical = 14.dp)
                    .semantics { heading() },
            )

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 20.dp)
                    .graphicsLayer {
                        alpha = laurelsProgress.coerceIn(0f, 1f)
                        val scale = 0.92f + 0.08f * laurelsProgress
                        scaleX = scale
                        scaleY = scale
                    },
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                PaperLaurels(modifier = Modifier.weight(1f).semantics(mergeDescendants = true) { }) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(5.dp),
                    ) {
                        Text(
                            text = StringStore.text(context, "onboardingV2.loading.social.count", language).uppercaseInApp(),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 12.sp,
                            lineHeight = 15.sp,
                            letterSpacing = 0.6.sp,
                            color = DS.ink,
                            textAlign = TextAlign.Center,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis,
                        )
                        SocialStars(starSize = 14, shown = starsShown)
                    }
                }
                PaperLaurels(modifier = Modifier.weight(1f).semantics(mergeDescendants = true) { }) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(5.dp),
                    ) {
                        Text(
                            text = 4.8.formatted(language, 1),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 22.sp,
                            color = DS.ink,
                        )
                        Text(
                            text = StringStore.text(context, "onboardingV2.review.appStore", language).uppercaseInApp(),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 11.sp,
                            lineHeight = 14.sp,
                            letterSpacing = 0.6.sp,
                            color = DS.inkSecondary,
                            textAlign = TextAlign.Center,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                }
            }

            Column(
                modifier = Modifier.fillMaxWidth().padding(top = 18.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                SOCIAL_REVIEW_INDICES.forEachIndexed { position, index ->
                    SocialReviewCard(
                        quote = StringStore.text(context, "onboardingV2.review.t$index.quote", language),
                        author = StringStore.text(context, "onboardingV2.review.t$index.author", language),
                        modifier = Modifier.dsStagger(position + 3, stepMillis = 90),
                    )
                }
            }

            // « Available in more than 140 countries », beside a few users' faces.
            Row(
                modifier = Modifier
                    .padding(top = 16.dp, bottom = 12.dp)
                    .dsStagger(SOCIAL_REVIEW_INDICES.size + 3, stepMillis = 90),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                if (photos.isNotEmpty()) {
                    PhotoRow(photos = photos, size = 26.dp, modifier = Modifier.clearAndSetSemantics { })
                } else {
                    Icon(Icons.Filled.Public, contentDescription = null, tint = DS.accent, modifier = Modifier.size(18.dp))
                }
                Text(
                    text = StringStore.text(context, "onboardingV2.intro.social.countries", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Medium,
                    fontSize = 13.sp,
                    lineHeight = 18.sp,
                    color = DS.inkSecondary,
                    modifier = Modifier.weight(1f, fill = false),
                )
            }
        }
    }
}

/** Five stars; [shown] lights the first ones (all by default). */
@Composable
private fun SocialStars(starSize: Int, shown: Int = SOCIAL_STAR_COUNT) {
    Row(
        modifier = Modifier.clearAndSetSemantics { },
        horizontalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        repeat(SOCIAL_STAR_COUNT) { index ->
            val lit by animateFloatAsState(if (index < shown) 1f else 0f, OV2Calm.quick(), label = "socialStar")
            Icon(
                Icons.Filled.Star,
                contentDescription = null,
                tint = DS.warm,
                modifier = Modifier
                    .size(starSize.dp)
                    .graphicsLayer {
                        alpha = lit.coerceIn(0f, 1f)
                        val scale = 0.6f + 0.4f * lit
                        scaleX = scale
                        scaleY = scale
                    },
            )
        }
    }
}

@Composable
private fun SocialReviewCard(quote: String, author: String, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .ov2Card()
            .padding(horizontal = 18.dp, vertical = 16.dp)
            .semantics(mergeDescendants = true) { },
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Text(
            text = quote,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Normal,
            fontSize = 15.sp,
            lineHeight = 22.sp,
            color = DS.ink,
            modifier = Modifier.fillMaxWidth(),
        )
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            SocialStars(starSize = 13)
            Spacer(Modifier.weight(1f))
            Text(
                text = author,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Normal,
                fontSize = 12.sp,
                color = DS.inkSecondary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

// endregion
