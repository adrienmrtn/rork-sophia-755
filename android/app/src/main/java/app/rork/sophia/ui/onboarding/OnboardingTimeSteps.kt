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
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
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
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.theme.PlusJakartaSans
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

    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
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
        Spacer(Modifier.weight(1f))
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
        Spacer(Modifier.weight(1f))
        OnboardingCta(
            text = StringStore.text(context, "common.continue", language),
            onClick = {
                onMinutesChange(slider.toInt())
                onContinue()
            },
        )
    }
}

/**
 * 80 squares, one per year of a life. They open first, the title lands, then the years
 * lost to the phone fill in red one by one.
 */
@Composable
internal fun YearsGridStep(language: AppLanguage, phoneMinutes: Int, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    val totalYears = 80
    val columns = 10
    val redYears = remember(phoneMinutes) {
        (totalYears * phoneMinutes / (24.0 * 60.0)).toInt().coerceIn(1, totalYears)
    }
    var revealed by remember { mutableIntStateOf(0) }
    var filled by remember { mutableIntStateOf(0) }
    var showTitle by remember { mutableStateOf(false) }
    var showCaption by remember { mutableStateOf(false) }
    var showButton by remember { mutableStateOf(false) }

    LaunchedEffect(redYears) {
        delay(350)
        repeat(totalYears) { i ->
            revealed = i + 1
            if ((i + 1) % 8 == 0) haptics.selection()
            delay(24)
        }
        delay(550)
        showTitle = true
        delay(1100)
        repeat(redYears) { i ->
            filled = i + 1
            haptics.selection()
            delay(150)
        }
        haptics.commit()
        delay(350)
        showCaption = true
        delay(600)
        showButton = true
    }

    val titleAlpha by animateFloatAsState(if (showTitle) 1f else 0f, tween(900), label = "gridTitle")
    val captionAlpha by animateFloatAsState(if (showCaption) 1f else 0f, tween(700), label = "gridCaption")
    val buttonAlpha by animateFloatAsState(if (showButton) 1f else 0f, tween(500), label = "gridCta")

    Column(modifier = Modifier.fillMaxSize()) {
        Spacer(Modifier.height(72.dp))
        Text(
            text = StringStore.text(context, "onboardingV2.yearsGrid.title", language),
            style = OV2.title,
            textAlign = TextAlign.Center,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 28.dp)
                .graphicsLayer { alpha = titleAlpha; translationY = (1f - titleAlpha) * 14f },
        )
        Spacer(Modifier.height(36.dp))
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 36.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            repeat(totalYears / columns) { row ->
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    repeat(columns) { column ->
                        val index = row * columns + column
                        YearCell(
                            revealed = index < revealed,
                            red = index < filled,
                            modifier = Modifier.weight(1f),
                        )
                    }
                }
            }
        }
        Spacer(Modifier.height(28.dp))
        Text(
            text = StringStore.text(context, "onboardingV2.yearsGrid.caption", language, redYears),
            style = OV2.subheadline.copy(color = OV2.danger, fontWeight = FontWeight.Bold),
            textAlign = TextAlign.Center,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 36.dp)
                .graphicsLayer { alpha = captionAlpha; translationY = (1f - captionAlpha) * 12f },
        )
        Spacer(Modifier.weight(1f))
        Box(modifier = Modifier.alpha(buttonAlpha)) {
            OnboardingCta(
                text = StringStore.text(context, "common.continue", language),
                onClick = { if (showButton) onContinue() },
                enabled = showButton,
            )
        }
    }
}

@Composable
private fun YearCell(revealed: Boolean, red: Boolean, modifier: Modifier = Modifier) {
    val scale by animateFloatAsState(
        targetValue = if (!revealed) 0.3f else if (red) 1f else 0.9f,
        animationSpec = spring(dampingRatio = 0.72f, stiffness = Spring.StiffnessMedium),
        label = "yearScale",
    )
    val color by androidx.compose.animation.animateColorAsState(
        targetValue = if (red) OV2.danger else OV2.hairline,
        animationSpec = tween(400),
        label = "yearColor",
    )
    Box(
        modifier = modifier
            .aspectRatio(1f)
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
                alpha = if (revealed) 1f else 0f
            }
            .clip(RoundedCornerShape(4.dp))
            .background(color),
    )
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

/** Social proof on the same blurred wheel as the questions screen. */
@Composable
internal fun ReviewStep(
    language: AppLanguage,
    richMotion: Boolean,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val testimonials = remember(language) {
        (1..6).map { i ->
            StringStore.text(context, "onboardingV2.review.t$i.quote", language) to
                StringStore.text(context, "onboardingV2.review.t$i.author", language)
        }
    }
    var listIn by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(700)
        listIn = true
    }
    val listAlpha by animateFloatAsState(if (listIn) 1f else 0f, tween(900), label = "reviewIn")

    Column(modifier = Modifier.fillMaxSize()) {
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
        Spacer(Modifier.weight(1f))
        OnboardingRoulette(
            items = testimonials,
            slotSpacing = 172.dp,
            tickMillis = 3000,
            running = listIn,
            blurEnabled = richMotion,
            modifier = Modifier
                .fillMaxWidth()
                .height(360.dp)
                .padding(horizontal = 24.dp)
                .alpha(listAlpha),
        ) { testimonial, _ ->
            ReviewCard(quote = testimonial.first, author = testimonial.second)
        }
        Spacer(Modifier.weight(1f))
        OnboardingCta(StringStore.text(context, "common.continue", language), onContinue)
    }
}

@Composable
private fun ReviewCard(quote: String, author: String) {
    val stars by rememberInfiniteTransition(label = "stars").animateFloat(
        initialValue = 0.85f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(1800), RepeatMode.Reverse),
        label = "starPulse",
    )
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .height(150.dp)
            .clip(OV2Shapes.card)
            .background(OV2.surface)
            .border(1.dp, OV2.hairline, OV2Shapes.card)
            .padding(18.dp),
    ) {
        Text(
            text = "★★★★★",
            color = OV2.warm,
            fontSize = 13.sp,
            modifier = Modifier.alpha(stars),
        )
        Spacer(Modifier.height(10.dp))
        Text(
            text = quote,
            style = OV2.body.copy(color = OV2.ink),
            maxLines = 4,
        )
        Spacer(Modifier.weight(1f))
        Text(text = author, style = OV2.caption)
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

    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.weight(1f))
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
        Spacer(Modifier.weight(1f))
        OnboardingCta(StringStore.text(context, "onboardingV2.reminder.cta", language), onContinue)
    }
}

@Composable
internal fun TrialStepsStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    val endDate = remember(language) {
        java.time.LocalDate.now().plusDays(3).format(
            java.time.format.DateTimeFormatter.ofPattern("d MMMM", java.util.Locale(language.code)),
        )
    }
    val steps = remember(language, endDate) {
        (0..3).map { i ->
            Triple(
                StringStore.text(context, "onboardingV2.trial.step$i.title", language),
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

    Column(modifier = Modifier.fillMaxSize()) {
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
        Spacer(Modifier.weight(1f))
        OnboardingCta(StringStore.text(context, "onboardingV2.trial.cta", language), onContinue)
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
