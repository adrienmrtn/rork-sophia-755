package app.rork.sophia.ui.onboarding

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.locale
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlin.math.roundToInt
import kotlinx.coroutines.delay

/** « 3h30 » / « 3h » / « 45 min », like the iOS screen-time label. */
internal fun screenTimeLabel(context: android.content.Context, minutes: Int, language: AppLanguage): String {
    if (minutes < 60) return StringStore.text(context, "onboardingV2.screenTime.minutes", language, minutes)
    val hours = minutes / 60
    val rest = minutes % 60
    return if (rest == 0) "${hours}h" else String.format("%dh%02d", hours, rest)
}

@Composable
internal fun PhoneTimeStep(
    language: AppLanguage,
    minutes: Int,
    onMinutesChange: (Int) -> Unit,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    var slider by remember { mutableFloatStateOf(minutes.toFloat()) }
    var lastStep by remember { mutableIntStateOf(minutes / 30) }

    OnboardingPage(
        contentArrangement = Arrangement.Top,
        footer = {
            OnboardingCta(
                text = StringStore.text(context, "common.continue", language),
                onClick = {
                    onMinutesChange(slider.toInt())
                    onContinue()
                },
            )
        },
    ) {
        Spacer(Modifier.height(84.dp))
        Text(
            text = StringStore.text(context, "onboardingV2.phoneTime.title", language),
            style = OV2.title,
            textAlign = TextAlign.Center,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 28.dp)
                .ov2Reveal(100),
        )
        AnimatedContent(
            targetState = slider.toInt(),
            transitionSpec = {
                if (targetState > initialState) {
                    (slideInVertically { it / 2 } + fadeIn()) togetherWith
                        (slideOutVertically { -it / 2 } + fadeOut())
                } else {
                    (slideInVertically { -it / 2 } + fadeIn()) togetherWith
                        (slideOutVertically { it / 2 } + fadeOut())
                }
            },
            label = "minutes",
        ) { value ->
            Text(
                text = screenTimeLabel(context, value, language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 62.sp,
                color = OV2.accent,
            )
        }
        Spacer(Modifier.height(32.dp))
        Column(modifier = Modifier.padding(horizontal = 36.dp).ov2Reveal(300)) {
            Slider(
                value = slider,
                onValueChange = { raw ->
                    val snapped = (raw / 30f).toInt().coerceIn(1, 20) * 30
                    slider = snapped.toFloat()
                    if (snapped / 30 != lastStep) {
                        lastStep = snapped / 30
                        haptics.selection()
                        onMinutesChange(snapped)
                    }
                },
                valueRange = 30f..600f,
                steps = 18,
                colors = SliderDefaults.colors(
                    thumbColor = OV2.accent,
                    activeTrackColor = OV2.accent,
                    inactiveTrackColor = OV2.hairline,
                ),
            )
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text(screenTimeLabel(context, 30, language), style = OV2.caption.copy(color = OV2.inkTertiary))
                Text(screenTimeLabel(context, 600, language), style = OV2.caption.copy(color = OV2.inkTertiary))
            }
        }
    }
}

/** « 27 ans », « 1 an », « 3 года »: the word for years agreed with the number. */
internal fun yearsText(context: android.content.Context, years: Int, language: AppLanguage): String =
    StringStore.text(context, "onboardingV2.yearsGrid.years", language, years)

private const val TOTAL_YEARS = 80
private const val GRID_COLUMNS = 10

/** A third of a life asleep, a third at work; the rest is free time. */
private const val SLEEP_YEARS = 27
private const val WORK_YEARS = 27
private const val FREE_YEARS = TOTAL_YEARS - SLEEP_YEARS - WORK_YEARS

private val SleepColor = Color(0xFF4D9E6B)
private val WorkColor = Color(0xFF8C613D)
private val FreeColor = Color(0xFFB8D1F2)

/**
 * 80 squares, one per year of a life. They colour in by thirds: sleep in green, work in
 * brown, then the free time that is left. Sleep and work then fade out, and inside the free
 * time, square after square, in red, the years spent on the phone (from the daily screen
 * time given before); the number lands big, then the sentence.
 *
 * Every counter is saved, so a rotation or a trip to the background resumes the sequence
 * where it was instead of replaying it, and the button always ends up on screen.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun YearsGridStep(language: AppLanguage, phoneMinutes: Int, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    // Free-time years spent on the phone: the daily screen time over 80 years, capped at
    // the free time (beyond it, all the free time goes there).
    val screenYears = remember(phoneMinutes) {
        (TOTAL_YEARS * phoneMinutes / (24.0 * 60.0)).roundToInt().coerceIn(1, FREE_YEARS)
    }
    var revealed by rememberSaveable { mutableIntStateOf(0) }
    var sleepFilled by rememberSaveable { mutableIntStateOf(0) }
    var workFilled by rememberSaveable { mutableIntStateOf(0) }
    var freeFilled by rememberSaveable { mutableIntStateOf(0) }
    var screenFilled by rememberSaveable { mutableIntStateOf(0) }
    var focusPhone by rememberSaveable { mutableStateOf(false) }
    var showTitle by rememberSaveable { mutableStateOf(false) }
    var showNumber by rememberSaveable { mutableStateOf(false) }
    var showCaption by rememberSaveable { mutableStateOf(false) }
    var showButton by rememberSaveable { mutableStateOf(false) }

    LaunchedEffect(screenYears) {
        try {
            // 1 — the grey squares open.
            if (revealed < TOTAL_YEARS) {
                delay(300)
                for (i in revealed + 1..TOTAL_YEARS) {
                    revealed = i
                    if (i % 10 == 0) haptics.selection()
                    delay(10)
                }
            }
            // 2 — « Here is your life in years ».
            if (!showTitle) {
                delay(400)
                showTitle = true
                delay(700)
            }
            // 3 — the three thirds, each given time to be read.
            suspend fun fill(target: Int, current: Int, apply: (Int) -> Unit) {
                for (i in current + 1..target) {
                    apply(i)
                    if (i % 9 == 0) haptics.selection()
                    delay(30)
                }
            }
            if (sleepFilled < SLEEP_YEARS) {
                fill(SLEEP_YEARS, sleepFilled) { sleepFilled = it }
                delay(550)
            }
            if (workFilled < WORK_YEARS) {
                fill(WORK_YEARS, workFilled) { workFilled = it }
                delay(550)
            }
            if (freeFilled < FREE_YEARS) {
                fill(FREE_YEARS, freeFilled) { freeFilled = it }
                delay(700)
            }
            // 4 — sleep and work fade: only the free time is left.
            if (!focusPhone) {
                focusPhone = true
                delay(700)
            }
            // 5 — the free-time years spent on the phone, one by one.
            if (screenFilled < screenYears) {
                for (i in screenFilled + 1..screenYears) {
                    screenFilled = i
                    haptics.selection()
                    delay(140)
                }
                haptics.commit()
            }
            // 6 — the number, big, then the sentence, then the button.
            if (!showNumber) {
                delay(250)
                showNumber = true
                delay(450)
            }
            showCaption = true
            delay(600)
        } finally {
            // Finished or interrupted, the page always offers a way out.
            showButton = true
        }
    }

    val titleAlpha by animateFloatAsState(if (showTitle) 1f else 0f, tween(700), label = "gridTitle")
    val numberProgress by animateFloatAsState(
        targetValue = if (showNumber) 1f else 0f,
        animationSpec = spring(dampingRatio = 0.6f, stiffness = Spring.StiffnessMediumLow),
        label = "gridNumber",
    )
    val captionAlpha by animateFloatAsState(if (showCaption) 1f else 0f, tween(600), label = "gridCaption")
    val buttonAlpha by animateFloatAsState(if (showButton) 1f else 0f, tween(500), label = "gridCta")

    fun squareColor(i: Int): Color {
        if (i < SLEEP_YEARS) return if (i < sleepFilled) SleepColor else OV2.hairline.copy(alpha = 0.7f)
        val work = i - SLEEP_YEARS
        if (work < WORK_YEARS) return if (work < workFilled) WorkColor else OV2.hairline.copy(alpha = 0.7f)
        val free = i - SLEEP_YEARS - WORK_YEARS
        if (free < screenFilled) return OV2.danger
        return if (free < freeFilled) FreeColor else OV2.hairline.copy(alpha = 0.7f)
    }

    fun isFilled(i: Int): Boolean {
        if (i < SLEEP_YEARS) return i < sleepFilled
        val work = i - SLEEP_YEARS
        if (work < WORK_YEARS) return work < workFilled
        val free = i - SLEEP_YEARS - WORK_YEARS
        return free < freeFilled || free < screenFilled
    }

    Column(modifier = Modifier.fillMaxSize()) {
        // The CTA is pinned outside the scroll, and the grid is capped: on a tablet each
        // square used to grow to ~100dp and push the button off the screen for good.
        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.height(64.dp))
            Text(
                text = StringStore.text(context, "onboardingV2.yearsGrid.title", language),
                style = OV2.title,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 28.dp)
                    .graphicsLayer { alpha = titleAlpha; translationY = (1f - titleAlpha) * 14f * density },
            )
            Spacer(Modifier.height(26.dp))
            Column(
                modifier = Modifier
                    .widthIn(max = GRID_MAX_WIDTH)
                    .fillMaxWidth()
                    .padding(horizontal = 36.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                repeat(TOTAL_YEARS / GRID_COLUMNS) { row ->
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        repeat(GRID_COLUMNS) { column ->
                            val index = row * GRID_COLUMNS + column
                            YearCell(
                                revealed = index < revealed,
                                filled = isFilled(index),
                                color = squareColor(index),
                                dimmed = focusPhone && index < SLEEP_YEARS + WORK_YEARS,
                                modifier = Modifier.weight(1f),
                            )
                        }
                    }
                }
            }
            Spacer(Modifier.height(20.dp))
            FlowRow(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 28.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                LegendChip(SleepColor, SleepColor, "onboardingV2.yearsGrid.sleep", SLEEP_YEARS, sleepFilled > 0, focusPhone, language)
                LegendChip(WorkColor, WorkColor, "onboardingV2.yearsGrid.work", WORK_YEARS, workFilled > 0, focusPhone, language)
                LegendChip(FreeColor, OV2.accentSoft, "onboardingV2.yearsGrid.free", FREE_YEARS, freeFilled > 0, false, language)
                LegendChip(OV2.danger, OV2.danger, "onboardingV2.yearsGrid.screen", screenYears, screenFilled > 0, false, language)
            }
            Spacer(Modifier.height(18.dp))
            // The number, big, then the sentence: what the page wants remembered.
            Text(
                text = yearsText(context, screenYears, language),
                style = OV2.titleLarge.copy(fontSize = 44.sp, lineHeight = 50.sp, color = OV2.danger),
                modifier = Modifier.graphicsLayer {
                    val s = 0.6f + 0.4f * numberProgress
                    scaleX = s
                    scaleY = s
                    alpha = numberProgress.coerceIn(0f, 1f)
                },
            )
            Text(
                text = StringStore.text(context, "onboardingV2.yearsGrid.captionFree", language, FREE_YEARS, screenYears),
                style = OV2.body.copy(color = OV2.danger, fontWeight = FontWeight.Bold),
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 32.dp)
                    .padding(top = 8.dp)
                    .graphicsLayer { alpha = captionAlpha; translationY = (1f - captionAlpha) * 12f * density },
            )
            Spacer(Modifier.height(48.dp))
        }
        Box(modifier = Modifier.alpha(buttonAlpha)) {
            OnboardingCta(
                text = StringStore.text(context, "common.continue", language),
                onClick = { if (showButton) onContinue() },
                enabled = showButton,
            )
        }
    }
}

/** Ten square cells per row stay phone-sized instead of ballooning on a tablet. */
private val GRID_MAX_WIDTH = 460.dp

@Composable
private fun YearCell(
    revealed: Boolean,
    filled: Boolean,
    color: Color,
    dimmed: Boolean,
    modifier: Modifier = Modifier,
) {
    val scale by animateFloatAsState(
        targetValue = if (!revealed) 0.3f else if (filled) 1f else 0.9f,
        animationSpec = spring(dampingRatio = 0.72f, stiffness = Spring.StiffnessMedium),
        label = "yearScale",
    )
    val animatedColor by androidx.compose.animation.animateColorAsState(
        targetValue = color,
        animationSpec = tween(250),
        label = "yearColor",
    )
    val alpha by animateFloatAsState(
        targetValue = if (!revealed) 0f else if (dimmed) 0.3f else 1f,
        animationSpec = tween(if (dimmed) 600 else 200),
        label = "yearAlpha",
    )
    Box(
        modifier = modifier
            .aspectRatio(1f)
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
                this.alpha = alpha
            }
            .clip(RoundedCornerShape(4.dp))
            .background(animatedColor),
    )
}

/** One chip per third, shown when its third starts to colour in. */
@Composable
private fun LegendChip(
    dot: Color,
    textColor: Color,
    key: String,
    years: Int,
    shown: Boolean,
    dimmed: Boolean,
    language: AppLanguage,
) {
    val context = LocalContext.current
    val progress by animateFloatAsState(
        targetValue = if (shown) 1f else 0f,
        animationSpec = spring(dampingRatio = 0.75f, stiffness = Spring.StiffnessMediumLow),
        label = "legendIn",
    )
    val dim by animateFloatAsState(if (dimmed) 0.45f else 1f, tween(500), label = "legendDim")
    Row(
        modifier = Modifier
            .graphicsLayer {
                alpha = progress.coerceIn(0f, 1f) * dim
                val s = 0.85f + 0.15f * progress
                scaleX = s
                scaleY = s
            }
            .clip(CircleShape)
            .background(OV2.surface)
            .border(1.dp, OV2.hairline, CircleShape)
            .padding(horizontal = 10.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(7.dp),
    ) {
        Box(modifier = Modifier.size(10.dp).background(dot, CircleShape))
        Text(
            text = StringStore.text(context, key, language),
            style = OV2.caption.copy(fontSize = 12.sp, color = OV2.ink),
        )
        Text(
            text = yearsText(context, years, language),
            style = OV2.caption.copy(fontSize = 12.sp, fontWeight = FontWeight.Bold, color = textColor),
        )
    }
}

/**
 * « Avec Sophia, transforme ce temps en culture » — the sentence turns bold word by word,
 * then the last word keeps swapping (culture, art, philosophie…) in a new colour.
 */
@Composable
internal fun TransformStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    val words = remember(language) {
        StringStore.text(context, "onboardingV2.transform.text", language)
            .split(' ')
            .filter { it.isNotBlank() }
    }
    val swapWords = remember(language) {
        StringStore.text(context, "onboardingV2.transform.words", language)
            .split(',')
            .map { it.trim() }
            .filter { it.isNotEmpty() }
    }
    val swapColors = listOf(OV2.accent, OV2.danger, OV2.warm, OV2.success, Color(0xFF7B5CD1))
    var boldCount by remember { mutableIntStateOf(0) }
    var showHint by remember { mutableStateOf(false) }
    var swapping by remember { mutableStateOf(false) }
    var swapIndex by remember { mutableIntStateOf(0) }

    LaunchedEffect(words) {
        delay(500)
        words.indices.forEach {
            boldCount = it + 1
            haptics.selection()
            delay(320)
        }
        showHint = true
        if (swapWords.size <= 1) return@LaunchedEffect
        delay(750)
        swapping = true
        while (true) {
            delay(1150)
            swapIndex += 1
            haptics.selection()
        }
    }

    TapToContinueScaffold(
        hint = StringStore.text(context, "onboardingV2.transform.tapHint", language),
        hintVisible = showHint,
        onContinue = onContinue,
    ) {
        ProgressiveWords(
            words = words,
            boldCount = boldCount,
            modifier = Modifier.padding(horizontal = 28.dp),
            lastCell = { bold ->
                SwapWordCell(
                    words = swapWords.ifEmpty { listOf(words.lastOrNull().orEmpty()) },
                    index = swapIndex,
                    swapping = swapping,
                    bold = bold,
                    color = if (swapping) {
                        swapColors[swapIndex % swapColors.size]
                    } else if (bold) {
                        OV2.accent
                    } else {
                        OV2.inkTertiary
                    },
                )
            },
        )
    }
}

@Composable
private fun SwapWordCell(
    words: List<String>,
    index: Int,
    swapping: Boolean,
    bold: Boolean,
    color: Color,
) {
    Box(contentAlignment = Alignment.Center) {
        // Invisible stack of every candidate: keeps the slot as wide as the longest word,
        // so the sentence never reflows while the last word cycles.
        words.forEach { candidate ->
            Text(
                text = candidate,
                style = OV2.title.copy(fontWeight = FontWeight.ExtraBold),
                modifier = Modifier.alpha(0f),
            )
        }
        AnimatedContent(
            targetState = if (swapping) index % words.size else 0,
            transitionSpec = {
                (slideInVertically { -it } + fadeIn()) togetherWith
                    (slideOutVertically { it } + fadeOut())
            },
            label = "swapWord",
        ) { i ->
            Text(
                text = words[i],
                style = OV2.title.copy(
                    fontWeight = if (bold || swapping) FontWeight.ExtraBold else FontWeight.Normal,
                    color = color,
                ),
            )
        }
    }
}

@Composable
internal fun PersonalizeStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    val words = remember(language) {
        StringStore.text(context, "onboardingV2.personalize.text", language)
            .split(' ')
            .filter { it.isNotBlank() }
    }
    var boldCount by remember { mutableIntStateOf(0) }
    var showHint by remember { mutableStateOf(false) }
    LaunchedEffect(words) {
        delay(500)
        words.indices.forEach {
            boldCount = it + 1
            haptics.selection()
            delay(320)
        }
        showHint = true
    }

    TapToContinueScaffold(
        hint = StringStore.text(context, "onboardingV2.personalize.tapHint", language),
        hintVisible = showHint,
        onContinue = onContinue,
    ) {
        ProgressiveWords(
            words = words,
            boldCount = boldCount,
            modifier = Modifier.padding(horizontal = 28.dp),
        )
    }
}

@Composable
private fun TapToContinueScaffold(
    hint: String,
    hintVisible: Boolean,
    onContinue: () -> Unit,
    content: @Composable () -> Unit,
) {
    val haptics = rememberOnboardingHaptics()
    var advanced by remember { mutableStateOf(false) }
    val hintAlpha by animateFloatAsState(if (hintVisible) 1f else 0f, tween(500), label = "hint")
    Box(
        modifier = Modifier
            .fillMaxSize()
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
            ) {
                if (!advanced) {
                    advanced = true
                    haptics.primary()
                    onContinue()
                }
            },
        contentAlignment = Alignment.Center,
    ) {
        content()
        Text(
            text = hint,
            style = OV2.caption.copy(color = OV2.inkTertiary),
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 40.dp)
                .alpha(hintAlpha),
        )
    }
}

/**
 * Social proof: a title that fades in, the laurels « 4.8 · 500,000 users », then reviews on
 * the same blurred wheel as the questions screen, each with the reviewer's photo.
 */
@Composable
internal fun ReviewStep(
    language: AppLanguage,
    richMotion: Boolean,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val avatars = remember { onboardingAssets(context, "review_avatar_") }
    val testimonials = remember(language) {
        (1..6).map { i ->
            Testimonial(
                index = i,
                quote = StringStore.text(context, "onboardingV2.review.t$i.quote", language),
                author = StringStore.text(context, "onboardingV2.review.t$i.author", language),
                avatar = avatars.firstOrNull { it.endsWith("review_avatar_$i.jpg") || it.endsWith("review_avatar_$i.png") },
            )
        }
    }
    var listIn by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(700)
        listIn = true
    }
    val listAlpha by animateFloatAsState(if (listIn) 1f else 0f, tween(900), label = "reviewIn")

    OnboardingPage(
        contentArrangement = Arrangement.Top,
        footer = {
            OnboardingCta(StringStore.text(context, "common.continue", language), onContinue)
        },
    ) {
        Spacer(Modifier.height(84.dp))
        Text(
            text = StringStore.text(context, "onboardingV2.review.title", language),
            style = OV2.title,
            textAlign = TextAlign.Center,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 28.dp)
                .ov2Reveal(50),
        )
        Spacer(Modifier.height(18.dp))
        LaurelBadge(size = 46.dp, modifier = Modifier.ov2Reveal(150)) {
            RatingStack(
                caption = StringStore.text(context, "onboardingV2.loading.social.count", language),
                language = language,
                compact = true,
            )
        }
        Spacer(Modifier.height(24.dp))
        OnboardingRoulette(
            items = testimonials,
            slotSpacing = 188.dp,
            tickMillis = 3000,
            running = listIn,
            blurEnabled = richMotion,
            modifier = Modifier
                .fillMaxWidth()
                .height(400.dp)
                .padding(horizontal = 24.dp)
                .alpha(listAlpha),
        ) { testimonial, focused ->
            ReviewCard(testimonial = testimonial, focused = focused)
        }
    }
}

private data class Testimonial(val index: Int, val quote: String, val author: String, val avatar: String?)

@Composable
private fun ReviewCard(testimonial: Testimonial, focused: Boolean) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .height(164.dp)
            .shadow(
                if (focused) 10.dp else 4.dp,
                OV2Shapes.card,
                ambientColor = Color.Black.copy(alpha = 0.06f),
                spotColor = Color.Black.copy(alpha = 0.06f),
            )
            .clip(OV2Shapes.card)
            .background(OV2.surface)
            .border(1.dp, OV2.hairline, OV2Shapes.card)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            ReviewAvatar(testimonial)
            Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(text = testimonial.author, style = OV2.caption.copy(color = OV2.ink))
                StarRow(starSize = 11.dp, spacing = 2.dp)
            }
        }
        Text(
            text = testimonial.quote,
            style = OV2.body.copy(color = OV2.ink, fontSize = 15.sp, lineHeight = 21.sp),
            maxLines = 4,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

/** Gradients of the generated portraits, always the same for the same reviewer. */
private val AvatarPalettes = listOf(
    Color(0xFFFA9E73) to Color(0xFFED5973),
    Color(0xFF73B8FA) to Color(0xFF4073D9),
    Color(0xFF8CD9A6) to Color(0xFF389973),
    Color(0xFFD9A6FA) to Color(0xFF8F66EB),
    Color(0xFFFCCC66) to Color(0xFFEB8C26),
    Color(0xFF8CD9EB) to Color(0xFF4099BF),
)

/** The bundled `review_avatar_<n>` when there is one, otherwise the initial on a gradient. */
@Composable
private fun ReviewAvatar(testimonial: Testimonial) {
    val modifier = Modifier
        .size(36.dp)
        .clip(CircleShape)
        .border(1.dp, Color.White.copy(alpha = 0.6f), CircleShape)
    if (testimonial.avatar != null) {
        AssetPicture(url = testimonial.avatar, modifier = modifier)
    } else {
        val palette = AvatarPalettes[(testimonial.index - 1).mod(AvatarPalettes.size)]
        Box(
            modifier = modifier.background(Brush.linearGradient(listOf(palette.first, palette.second))),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = testimonial.author.trim().take(1).uppercase(),
                color = Color.White,
                fontWeight = FontWeight.Bold,
                fontSize = 15.sp,
            )
        }
    }
}

@Composable
internal fun ReminderStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    val words = remember(language) {
        StringStore.text(context, "onboardingV2.reminder.title", language)
            .split(' ')
            .filter { it.isNotBlank() }
    }
    var boldCount by remember { mutableIntStateOf(0) }
    var bellIn by remember { mutableStateOf(false) }
    LaunchedEffect(words) {
        bellIn = true
        delay(300)
        words.indices.forEach {
            boldCount = it + 1
            haptics.selection()
            delay(120)
        }
    }
    val bellScale by animateFloatAsState(
        targetValue = if (bellIn) 1f else 0.5f,
        animationSpec = spring(dampingRatio = 0.6f, stiffness = Spring.StiffnessLow),
        label = "bellScale",
    )
    val wobble by rememberInfiniteTransition(label = "bell").animateFloat(
        initialValue = -12f,
        targetValue = 12f,
        animationSpec = infiniteRepeatable(tween(400), RepeatMode.Reverse),
        label = "bellWobble",
    )

    OnboardingPage(
        footer = {
            OnboardingCta(StringStore.text(context, "onboardingV2.reminder.cta", language), onContinue)
        },
    ) {
        ProgressiveWords(
            words = words,
            boldCount = boldCount,
            modifier = Modifier.padding(horizontal = 32.dp),
        )
        Spacer(Modifier.height(48.dp))
        Text(
            text = "🔔",
            fontSize = 86.sp,
            modifier = Modifier.graphicsLayer {
                scaleX = bellScale
                scaleY = bellScale
                alpha = bellScale
                rotationZ = if (bellIn) wobble else 0f
                transformOrigin = androidx.compose.ui.graphics.TransformOrigin(0.5f, 0f)
            },
        )
    }
}

@Composable
internal fun TrialStepsStep(language: AppLanguage, trialDays: Int = 3, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    val endDate = remember(language, trialDays) {
        java.time.LocalDate.now().plusDays(trialDays.toLong()).format(
            // `Locale("sr")` resolves to Cyrillic, which put a Cyrillic month next to the
            // Latin text of Sophia's own Serbian table. `language.locale` pins the script.
            // The pattern is the language's own day-month order ("3. Oktober", "3 de
            // octubre", "October 3"); a fixed "d MMMM" read wrong in half of them.
            java.time.format.DateTimeFormatter.ofPattern(
                android.text.format.DateFormat.getBestDateTimePattern(language.locale, "dMMMM"),
                language.locale,
            ),
        )
    }
    val steps = remember(language, endDate, trialDays) {
        (0..3).map { i ->
            // Steps 2 and 3 name the reminder day and the last day of the trial.
            val dayNumber = when (i) {
                2 -> (trialDays - 1).coerceAtLeast(1)
                3 -> trialDays
                else -> 0
            }
            Triple(
                if (i >= 2) {
                    StringStore.trialText(context, "onboardingV2.trial.step$i.title", language, dayNumber)
                } else {
                    StringStore.text(context, "onboardingV2.trial.step$i.title", language)
                },
                StringStore.text(context, "onboardingV2.trial.step$i.detail", language, endDate),
                i,
            )
        }
    }
    var revealed by remember { mutableIntStateOf(0) }
    LaunchedEffect(Unit) {
        delay(200)
        steps.indices.forEach {
            revealed = it + 1
            haptics.selection()
            delay(180)
        }
    }

    OnboardingPage(
        contentArrangement = Arrangement.Top,
        footer = {
            OnboardingCta(StringStore.text(context, "onboardingV2.trial.cta", language), onContinue)
        },
    ) {
        Spacer(Modifier.height(72.dp))
        Text(
            text = StringStore.text(context, "onboardingV2.trial.title", language),
            style = OV2.titleLarge,
            modifier = Modifier.padding(horizontal = 28.dp).ov2Reveal(50),
        )
        Spacer(Modifier.height(36.dp))
        Column(modifier = Modifier.padding(horizontal = 28.dp)) {
            steps.forEach { (title, detail, index) ->
                TrialTimelineRow(
                    title = title,
                    detail = detail,
                    emoji = TRIAL_EMOJI[index],
                    active = index == 1,
                    done = index == 0,
                    last = index == steps.lastIndex,
                    visible = index < revealed,
                )
            }
        }
    }
}

private val TRIAL_EMOJI = listOf("✓", "🔓", "🔔", "★")

@Composable
private fun TrialTimelineRow(
    title: String,
    detail: String,
    emoji: String,
    active: Boolean,
    done: Boolean,
    last: Boolean,
    visible: Boolean,
) {
    val alpha by animateFloatAsState(if (visible) 1f else 0f, tween(400), label = "trialAlpha")
    val shift by animateFloatAsState(
        targetValue = if (visible) 0f else -12f,
        animationSpec = spring(dampingRatio = 0.82f, stiffness = Spring.StiffnessMediumLow),
        label = "trialShift",
    )
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .graphicsLayer { this.alpha = alpha; translationX = shift },
        horizontalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            OnboardingCircleBadge(
                size = 40.dp,
                background = if (done || active) OV2.accent else OV2.inkTertiary.copy(alpha = 0.35f),
            ) {
                Text(emoji, fontSize = 16.sp, color = Color.White)
            }
            if (!last) {
                Box(
                    modifier = Modifier
                        .size(width = 3.dp, height = 46.dp)
                        .background(OV2.accent.copy(alpha = 0.18f)),
                )
            }
        }
        Column(modifier = Modifier.padding(bottom = if (last) 0.dp else 14.dp)) {
            Text(
                text = title,
                style = OV2.headline.copy(color = if (active) OV2.accent else OV2.ink),
            )
            Text(text = detail, style = OV2.subheadline)
        }
    }
}
