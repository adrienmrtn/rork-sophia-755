package app.rork.sophia.ui.onboarding

import androidx.compose.animation.AnimatedVisibility
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
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.TrackChanges
import androidx.compose.material.icons.filled.TravelExplore
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
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

internal val OBJECTIVE_KEYS = listOf("cultivate", "reduceScreen", "exams", "impress", "curiosity")
internal val OBJECTIVE_EMOJI = mapOf(
    "cultivate" to "🧠",
    "reduceScreen" to "📵",
    "exams" to "🎓",
    "impress" to "✨",
    "curiosity" to "🔭",
)

@Composable
internal fun WelcomeStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    var logoIn by remember { mutableStateOf(false) }
    var titleIn by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        logoIn = true
        delay(350)
        titleIn = true
    }
    val logoScale by animateFloatAsState(
        targetValue = if (logoIn) 1f else 0.7f,
        animationSpec = spring(dampingRatio = 0.7f, stiffness = Spring.StiffnessLow),
        label = "logo",
    )
    val logoAlpha by animateFloatAsState(if (logoIn) 1f else 0f, tween(500), label = "logoAlpha")
    val titleAlpha by animateFloatAsState(if (titleIn) 1f else 0f, tween(450), label = "titleAlpha")
    val titleShift by animateFloatAsState(if (titleIn) 0f else 16f, tween(450), label = "titleShift")
    val halo by rememberInfiniteTransition(label = "halo").animateFloat(
        initialValue = 0.92f,
        targetValue = 1.05f,
        animationSpec = infiniteRepeatable(tween(1600), RepeatMode.Reverse),
        label = "haloScale",
    )

    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.weight(1f))
        Box(contentAlignment = Alignment.Center) {
            Box(
                modifier = Modifier
                    .size(220.dp)
                    .graphicsLayer { scaleX = halo; scaleY = halo; alpha = logoAlpha }
                    .background(OV2.accentSoft.copy(alpha = 0.10f), CircleShape),
            )
            Box(
                modifier = Modifier
                    .size(140.dp)
                    .graphicsLayer { scaleX = halo; scaleY = halo; alpha = logoAlpha }
                    .background(OV2.accentSoft.copy(alpha = 0.12f), CircleShape),
            )
            Box(
                modifier = Modifier
                    .size(104.dp)
                    .graphicsLayer { scaleX = logoScale; scaleY = logoScale; alpha = logoAlpha }
                    .background(OV2.accent, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    Icons.Filled.AutoAwesome,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(44.dp),
                )
            }
        }
        Spacer(Modifier.height(40.dp))
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .graphicsLayer { alpha = titleAlpha; translationY = titleShift },
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = StringStore.text(context, "onboardingV2.welcome.title", language),
                style = OV2.titleLarge,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 28.dp),
            )
            Spacer(Modifier.height(12.dp))
            Text(
                text = StringStore.text(context, "onboardingV2.welcome.subtitle", language),
                style = OV2.body,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 32.dp),
            )
        }
        Spacer(Modifier.weight(1f))
        OnboardingCta(StringStore.text(context, "onboardingV2.welcome.cta", language), onContinue)
    }
}

@Composable
internal fun LanguageStep(
    language: AppLanguage,
    onSelect: (AppLanguage) -> Unit,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    val scrollState = rememberScrollState()
    var showScrollHint by remember { mutableStateOf(true) }
    var revealed by remember { mutableIntStateOf(0) }
    val bounce by rememberInfiniteTransition(label = "langHint").animateFloat(
        initialValue = 0f,
        targetValue = 3f,
        animationSpec = infiniteRepeatable(tween(900), RepeatMode.Reverse),
        label = "bounce",
    )

    LaunchedEffect(Unit) {
        delay(150)
        AppLanguage.entries.indices.forEach { index ->
            revealed = index + 1
            delay(60)
        }
    }
    LaunchedEffect(scrollState.value) {
        if (scrollState.value > 24) showScrollHint = false
    }

    Column(modifier = Modifier.fillMaxSize()) {
        Spacer(Modifier.height(72.dp))
        Column(modifier = Modifier.padding(horizontal = 28.dp).ov2Reveal(100)) {
            Text(
                text = StringStore.text(context, "onboardingV2.language.title", language),
                style = OV2.title,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth(),
            )
            Spacer(Modifier.height(10.dp))
            Text(
                text = StringStore.text(context, "onboardingV2.language.subtitle", language),
                style = OV2.subheadline,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth(),
            )
        }
        Spacer(Modifier.height(28.dp))

        Box(modifier = Modifier.weight(1f).fillMaxWidth()) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(scrollState)
                    .padding(horizontal = 24.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                AppLanguage.entries.forEachIndexed { index, lang ->
                    LanguageRow(
                        language = lang,
                        selected = lang == language,
                        visible = index < revealed,
                        onClick = {
                            haptics.selection()
                            onSelect(lang)
                        },
                    )
                }
                Spacer(Modifier.height(36.dp))
            }
            LanguageScrollHint(
                visible = showScrollHint,
                bounce = bounce,
                language = language,
                modifier = Modifier.align(Alignment.BottomCenter),
            )
        }

        OnboardingCta(StringStore.text(context, "common.continue", language), onContinue)
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
                    .background(Brush.verticalGradient(listOf(OV2.bg.copy(alpha = 0f), OV2.bg))),
            )
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(OV2.bg)
                    .padding(bottom = 8.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    Icons.Filled.KeyboardArrowDown,
                    contentDescription = null,
                    tint = OV2.inkSecondary,
                    modifier = Modifier.size(18.dp).graphicsLayer { translationY = bounce },
                )
                Text(
                    text = StringStore.text(context, "onboardingV2.language.scrollHint", language),
                    style = OV2.caption,
                    modifier = Modifier.padding(horizontal = 8.dp),
                )
                Icon(
                    Icons.Filled.KeyboardArrowDown,
                    contentDescription = null,
                    tint = OV2.inkSecondary,
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
    visible: Boolean,
    onClick: () -> Unit,
) {
    val alpha by animateFloatAsState(if (visible) 1f else 0f, tween(320), label = "langAlpha")
    val offsetY by animateFloatAsState(
        targetValue = if (visible) 0f else 18f,
        animationSpec = spring(dampingRatio = 0.8f, stiffness = Spring.StiffnessMediumLow),
        label = "langY",
    )
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .graphicsLayer { this.alpha = alpha; translationY = offsetY }
            .clip(OV2Shapes.control)
            .background(OV2.surface)
            .border(
                width = if (selected) 2.dp else 1.dp,
                color = if (selected) OV2.accent else OV2.hairline,
                shape = OV2Shapes.control,
            )
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(language.flag, fontSize = 26.sp)
        Spacer(Modifier.size(12.dp))
        Text(
            text = language.displayName,
            style = OV2.body.copy(color = OV2.ink, fontWeight = FontWeight.SemiBold),
            modifier = Modifier.weight(1f),
        )
        SelectionMark(selected = selected, shape = CircleShape)
    }
}

@Composable
internal fun ObjectivesStep(
    language: AppLanguage,
    selected: Set<String>,
    onToggle: (String) -> Unit,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    var revealed by remember { mutableIntStateOf(0) }
    LaunchedEffect(Unit) {
        delay(150)
        OBJECTIVE_KEYS.indices.forEach { index ->
            revealed = index + 1
            delay(70)
        }
    }

    Column(modifier = Modifier.fillMaxSize()) {
        Spacer(Modifier.height(72.dp))
        Column(modifier = Modifier.padding(horizontal = 28.dp).ov2Reveal(100)) {
            Text(
                text = StringStore.text(context, "onboardingV2.objective.title", language),
                style = OV2.title,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth(),
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = StringStore.text(context, "onboardingV2.objective.subtitle", language),
                style = OV2.subheadline,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth(),
            )
        }
        Spacer(Modifier.height(24.dp))
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            OBJECTIVE_KEYS.forEachIndexed { index, key ->
                ObjectiveRow(
                    emoji = OBJECTIVE_EMOJI[key].orEmpty(),
                    label = StringStore.text(context, "onboardingV2.objective.$key", language),
                    selected = key in selected,
                    visible = index < revealed,
                    onClick = {
                        haptics.selection()
                        onToggle(key)
                    },
                )
            }
            Spacer(Modifier.height(8.dp))
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
    emoji: String,
    label: String,
    selected: Boolean,
    visible: Boolean,
    onClick: () -> Unit,
) {
    val alpha by animateFloatAsState(if (visible) 1f else 0f, tween(320), label = "objAlpha")
    val offsetY by animateFloatAsState(
        targetValue = if (visible) 0f else 18f,
        animationSpec = spring(dampingRatio = 0.8f, stiffness = Spring.StiffnessMediumLow),
        label = "objY",
    )
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .graphicsLayer { this.alpha = alpha; translationY = offsetY }
            .clip(OV2Shapes.control)
            .background(if (selected) OV2.accentSoft.copy(alpha = 0.06f) else OV2.surface)
            .border(
                width = if (selected) 2.dp else 1.dp,
                color = if (selected) OV2.accent else OV2.hairline,
                shape = OV2Shapes.control,
            )
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        OnboardingCircleBadge(
            size = 44.dp,
            background = if (selected) OV2.accent.copy(alpha = 0.16f) else OV2.accentSoft.copy(alpha = 0.12f),
        ) {
            Text(emoji, fontSize = 22.sp)
        }
        Text(
            text = label,
            style = OV2.body.copy(color = OV2.ink, fontWeight = FontWeight.SemiBold),
            modifier = Modifier.weight(1f),
        )
        SelectionMark(selected = selected, shape = RoundedCornerShape(7.dp))
    }
}

@Composable
private fun SelectionMark(selected: Boolean, shape: androidx.compose.ui.graphics.Shape) {
    val scale by animateFloatAsState(
        targetValue = if (selected) 1f else 0f,
        animationSpec = spring(dampingRatio = 0.6f, stiffness = Spring.StiffnessMedium),
        label = "mark",
    )
    Box(
        modifier = Modifier
            .size(24.dp)
            .border(2.dp, if (selected) OV2.accent else OV2.hairline, shape),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer { scaleX = scale; scaleY = scale; alpha = scale }
                .background(OV2.accent, shape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                Icons.Filled.Check,
                contentDescription = null,
                tint = Color.White,
                modifier = Modifier.size(15.dp),
            )
        }
    }
}

/** « Sophia va t'aider… » — bold walks through the sentence, then a tap anywhere continues. */
@Composable
internal fun ObjectiveIntroStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    val words = remember(language) {
        StringStore.text(context, "onboardingV2.objectiveIntro.title", language)
            .split(' ')
            .filter { it.isNotBlank() }
    }
    var boldCount by remember { mutableIntStateOf(0) }
    var canTap by remember { mutableStateOf(false) }
    var glowIn by remember { mutableStateOf(false) }
    LaunchedEffect(words) {
        glowIn = true
        delay(350)
        words.indices.forEach {
            boldCount = it + 1
            haptics.selection()
            delay(130)
        }
        delay(200)
        canTap = true
    }
    val glow by animateFloatAsState(
        targetValue = if (glowIn) 1f else 0.6f,
        animationSpec = spring(dampingRatio = 0.7f, stiffness = Spring.StiffnessLow),
        label = "glow",
    )
    val pulse by rememberInfiniteTransition(label = "hint").animateFloat(
        initialValue = 0.4f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(1000), RepeatMode.Reverse),
        label = "pulse",
    )

    Box(
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
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.weight(1f))
            OnboardingCircleBadge(
                size = 108.dp,
                background = OV2.accent.copy(alpha = 0.10f),
                modifier = Modifier.graphicsLayer { scaleX = glow; scaleY = glow; alpha = glow },
            ) {
                Icon(
                    Icons.Filled.TrackChanges,
                    contentDescription = null,
                    tint = OV2.accent,
                    modifier = Modifier.size(46.dp),
                )
            }
            Spacer(Modifier.height(36.dp))
            ProgressiveWords(
                words = words,
                boldCount = boldCount,
                modifier = Modifier.padding(horizontal = 34.dp),
            )
            Spacer(Modifier.weight(1f))
            Text(
                text = StringStore.text(context, "onboardingV2.tapToContinue", language),
                style = OV2.caption.copy(color = OV2.inkTertiary),
                modifier = Modifier
                    .padding(bottom = 48.dp)
                    .alpha(if (canTap) pulse else 0f),
            )
        }
    }
}

/** « Avec Sophia, tu sauras répondre à ces questions » — questions on a slow blurred wheel. */
@Composable
internal fun QuestionsStep(
    language: AppLanguage,
    richMotion: Boolean,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val questions = remember(language) {
        (1..10).map { StringStore.text(context, "onboardingV2.questions.q$it", language) }
    }
    Column(modifier = Modifier.fillMaxSize()) {
        Spacer(Modifier.height(84.dp))
        Text(
            text = StringStore.text(context, "onboardingV2.questions.title", language),
            style = OV2.title,
            textAlign = TextAlign.Center,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 28.dp)
                .ov2Reveal(100),
        )
        Spacer(Modifier.weight(1f))
        OnboardingRoulette(
            items = questions,
            slotSpacing = 152.dp,
            tickMillis = 2400,
            blurEnabled = richMotion,
            modifier = Modifier
                .fillMaxWidth()
                .height(320.dp)
                .padding(horizontal = 28.dp),
        ) { question, focused ->
            QuestionCard(question = question, focused = focused)
        }
        Spacer(Modifier.weight(1f))
        OnboardingCta(StringStore.text(context, "common.continue", language), onContinue)
    }
}

@Composable
private fun QuestionCard(question: String, focused: Boolean) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(OV2Shapes.card)
            .background(OV2.surface)
            .border(1.dp, OV2.hairline, OV2Shapes.card)
            .padding(22.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Icon(
            Icons.Filled.TravelExplore,
            contentDescription = null,
            tint = OV2.accentSoft,
            modifier = Modifier.size(22.dp),
        )
        Text(
            text = question,
            style = OV2.title.copy(
                fontSize = 21.sp,
                lineHeight = 27.sp,
                fontWeight = if (focused) FontWeight.ExtraBold else FontWeight.Bold,
            ),
            fontFamily = PlusJakartaSans,
        )
    }
}
