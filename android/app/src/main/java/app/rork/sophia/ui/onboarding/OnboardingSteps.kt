package app.rork.sophia.ui.onboarding

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
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
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Course
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.legal.LegalDocKind
import app.rork.sophia.ui.legal.LegalDocumentScreen
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.delay
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

private val OBJECTIVE_KEYS = listOf("cultivate", "reduceScreen", "exams", "impress", "curiosity")
private val OBJECTIVE_EMOJI = mapOf(
    "cultivate" to "🧠",
    "reduceScreen" to "📵",
    "exams" to "🎓",
    "impress" to "✨",
    "curiosity" to "🔭",
)

@Composable
internal fun WelcomeStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    var appear by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { appear = true }
    val scale by animateFloatAsState(if (appear) 1f else 0.92f, tween(500), label = "welcome")

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(DS.Space.l)
            .scale(scale),
        verticalArrangement = Arrangement.SpaceBetween,
    ) {
        Spacer(Modifier.height(48.dp))
        Column {
            Text("Sophia", style = SophiaTypography.displayLarge, fontSize = 52.sp)
            Spacer(Modifier.height(16.dp))
            Text(
                StringStore.text(context, "onboardingV2.welcome.title", language),
                style = SophiaTypography.titleLarge,
            )
            Spacer(Modifier.height(10.dp))
            Text(
                StringStore.text(context, "onboardingV2.welcome.subtitle", language),
                style = SophiaTypography.bodyMedium,
            )
        }
        PrimaryCta(StringStore.text(context, "onboardingV2.welcome.cta", language), onContinue)
    }
}

@Composable
internal fun LanguageStep(
    language: AppLanguage,
    onSelect: (AppLanguage) -> Unit,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
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
        AppLanguage.entries.forEachIndexed { index, _ ->
            delay(150L + index * 60L)
            revealed = index + 1
        }
    }
    LaunchedEffect(scrollState.value) {
        if (scrollState.value > 24 && showScrollHint) {
            showScrollHint = false
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = DS.Space.l),
    ) {
        Spacer(Modifier.height(48.dp))
        Text(
            StringStore.text(context, "onboardingV2.language.title", language),
            style = SophiaTypography.titleLarge,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth(),
        )
        Text(
            StringStore.text(context, "onboardingV2.language.subtitle", language),
            style = SophiaTypography.bodyMedium,
            textAlign = TextAlign.Center,
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 8.dp, bottom = 20.dp),
        )

        Box(modifier = Modifier.weight(1f).fillMaxWidth()) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(scrollState),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                AppLanguage.entries.forEachIndexed { index, lang ->
                    val visible = index < revealed
                    LanguageRow(
                        language = lang,
                        selected = lang == language,
                        visible = visible,
                        onClick = { onSelect(lang) },
                    )
                }
                Spacer(Modifier.height(36.dp))
            }

            // Extracted: ColumnScope.AnimatedVisibility would be picked inside Column→Box
            // and fails to compile; use a child composable without ColumnScope receiver.
            LanguageScrollHint(
                visible = showScrollHint,
                bounce = bounce,
                language = language,
                modifier = Modifier.align(Alignment.BottomCenter),
            )
        }

        PrimaryCta(StringStore.text(context, "common.continue", language), onContinue)
        Spacer(Modifier.height(12.dp))
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
                    .background(
                        Brush.verticalGradient(
                            listOf(DS.canvas.copy(alpha = 0f), DS.canvas),
                        ),
                    ),
            )
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(DS.canvas)
                    .padding(bottom = 8.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    "▼",
                    color = DS.inkSecondary,
                    fontSize = 11.sp,
                    modifier = Modifier.offset(y = bounce.dp),
                )
                Text(
                    StringStore.text(context, "onboardingV2.language.scrollHint", language),
                    style = SophiaTypography.labelMedium,
                    color = DS.inkSecondary,
                    modifier = Modifier.padding(horizontal = 8.dp),
                )
                Text(
                    "▼",
                    color = DS.inkSecondary,
                    fontSize = 11.sp,
                    modifier = Modifier.offset(y = bounce.dp),
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
    val offsetY by animateFloatAsState(if (visible) 0f else 18f, tween(320), label = "langY")
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .offset(y = offsetY.dp)
            .alpha(alpha)
            .clip(DS.controlShape)
            .background(DS.surface)
            .border(if (selected) 2.dp else 1.dp, if (selected) DS.accent else DS.hairline, DS.controlShape)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(language.flag, fontSize = 26.sp)
        Spacer(Modifier.size(12.dp))
        Text(
            language.displayName,
            style = SophiaTypography.bodyLarge.copy(fontWeight = FontWeight.SemiBold),
            modifier = Modifier.weight(1f),
        )
        Box(
            modifier = Modifier
                .size(22.dp)
                .border(2.dp, if (selected) DS.accent else DS.hairline, CircleShape)
                .background(if (selected) DS.accent else Color.Transparent, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            if (selected) {
                Text("✓", color = Color.White, fontSize = 11.sp, fontWeight = FontWeight.Bold)
            }
        }
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
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(DS.Space.l),
        verticalArrangement = Arrangement.SpaceBetween,
    ) {
        Column(modifier = Modifier.weight(1f).verticalScroll(rememberScrollState())) {
            Spacer(Modifier.height(40.dp))
            Text(StringStore.text(context, "onboardingV2.objective.title", language), style = SophiaTypography.titleLarge)
            Text(
                StringStore.text(context, "onboardingV2.objective.subtitle", language),
                style = SophiaTypography.bodyMedium,
                modifier = Modifier.padding(top = 8.dp, bottom = 20.dp),
            )
            OBJECTIVE_KEYS.forEach { key ->
                SelectRow(
                    label = "${OBJECTIVE_EMOJI[key].orEmpty()}  " +
                        StringStore.text(context, "onboardingV2.objective.$key", language),
                    selected = key in selected,
                    onClick = { onToggle(key) },
                )
                Spacer(Modifier.height(8.dp))
            }
        }
        PrimaryCta(
            text = StringStore.text(context, "common.continue", language),
            onClick = onContinue,
            enabled = selected.isNotEmpty(),
        )
    }
}

@Composable
internal fun TapContinueStep(
    titleKey: String,
    language: AppLanguage,
    hintKey: String = "onboardingV2.tapToContinue",
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    var appear by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { appear = true }
    val alpha by animateFloatAsState(if (appear) 1f else 0f, tween(450), label = "tap")

    Box(
        modifier = Modifier
            .fillMaxSize()
            .clickable(onClick = onContinue)
            .padding(DS.Space.l)
            .alpha(alpha),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                StringStore.text(context, titleKey, language),
                style = SophiaTypography.titleLarge,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(20.dp))
            Text(
                StringStore.text(context, hintKey, language),
                style = SophiaTypography.labelMedium,
                color = DS.inkTertiary,
            )
        }
    }
}

@Composable
internal fun QuestionsStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val questions = remember {
        (1..10).map { "onboardingV2.questions.q$it" }
    }
    var index by remember { mutableIntStateOf(0) }
    LaunchedEffect(Unit) {
        while (index < questions.lastIndex) {
            delay(1600)
            index += 1
        }
    }
    Column(
        modifier = Modifier.fillMaxSize().padding(DS.Space.l),
        verticalArrangement = Arrangement.SpaceBetween,
    ) {
        Column {
            Spacer(Modifier.height(48.dp))
            Text(
                StringStore.text(context, "onboardingV2.questions.title", language),
                style = SophiaTypography.titleLarge,
            )
            Spacer(Modifier.height(32.dp))
            AnimatedContent(
                targetState = index,
                transitionSpec = { fadeIn(tween(300)) togetherWith fadeOut(tween(300)) },
                label = "q",
            ) { i ->
                Text(
                    StringStore.text(context, questions[i], language),
                    style = SophiaTypography.titleMedium,
                    color = DS.accentSoft,
                )
            }
        }
        PrimaryCta(StringStore.text(context, "common.continue", language), onContinue)
    }
}

@Composable
internal fun PhoneTimeStep(
    language: AppLanguage,
    minutes: Int,
    onMinutesChange: (Int) -> Unit,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    Column(
        modifier = Modifier.fillMaxSize().padding(DS.Space.l),
        verticalArrangement = Arrangement.SpaceBetween,
    ) {
        Column {
            Spacer(Modifier.height(48.dp))
            Text(
                StringStore.text(context, "onboardingV2.phoneTime.title", language),
                style = SophiaTypography.titleLarge,
            )
            Spacer(Modifier.height(36.dp))
            Text(
                StringStore.text(context, "onboardingV2.screenTime.minutes", language, minutes),
                style = SophiaTypography.displayLarge,
                fontSize = 48.sp,
                color = DS.accentSoft,
            )
            Spacer(Modifier.height(8.dp))
            Text(
                StringStore.text(context, "onboardingV2.phone.perDay", language),
                style = SophiaTypography.bodyMedium,
            )
            Spacer(Modifier.height(24.dp))
            Slider(
                value = minutes.toFloat(),
                onValueChange = { onMinutesChange((it / 30f).toInt().coerceIn(1, 20) * 30) },
                valueRange = 30f..600f,
                steps = 18,
                colors = SliderDefaults.colors(thumbColor = DS.accent, activeTrackColor = DS.accent),
            )
        }
        PrimaryCta(StringStore.text(context, "common.continue", language), onContinue)
    }
}

@Composable
internal fun YearsGridStep(language: AppLanguage, phoneMinutes: Int, onContinue: () -> Unit) {
    val context = LocalContext.current
    val redYears = remember(phoneMinutes) {
        (80.0 * phoneMinutes / (24.0 * 60.0)).toInt().coerceIn(1, 80)
    }
    var revealed by remember { mutableIntStateOf(0) }
    var filled by remember { mutableIntStateOf(0) }
    var showCaption by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        while (revealed < 80) {
            delay(12)
            revealed += 1
        }
        delay(200)
        while (filled < redYears) {
            delay(40)
            filled += 1
        }
        showCaption = true
    }

    Column(
        modifier = Modifier.fillMaxSize().padding(DS.Space.l),
        verticalArrangement = Arrangement.SpaceBetween,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Spacer(Modifier.height(36.dp))
            Text(
                StringStore.text(context, "onboardingV2.yearsGrid.title", language),
                style = SophiaTypography.titleLarge,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth(),
            )
            Spacer(Modifier.height(24.dp))
            LazyVerticalGrid(
                columns = GridCells.Fixed(10),
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp),
                userScrollEnabled = false,
                modifier = Modifier.fillMaxWidth(),
            ) {
                items(80, key = { it }) { i ->
                    val color = when {
                        i < filled -> DS.danger
                        i < revealed -> DS.hairline
                        else -> Color.Transparent
                    }
                    Box(
                        modifier = Modifier
                            .aspectRatio(1f)
                            .clip(RoundedCornerShape(4.dp))
                            .background(color),
                    )
                }
            }
            if (showCaption) {
                Spacer(Modifier.height(16.dp))
                Text(
                    StringStore.text(context, "onboardingV2.yearsGrid.caption", language, redYears),
                    style = SophiaTypography.bodyMedium,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }
        PrimaryCta(StringStore.text(context, "common.continue", language), onContinue)
    }
}

@Composable
internal fun TransformStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val words = remember {
        StringStore.text(context, "onboardingV2.transform.words", language)
            .split(',')
            .map { it.trim() }
            .filter { it.isNotEmpty() }
    }
    var wordIndex by remember { mutableIntStateOf(0) }
    var appear by remember { mutableFloatStateOf(0f) }
    LaunchedEffect(Unit) {
        appear = 1f
        while (wordIndex < words.lastIndex) {
            delay(700)
            wordIndex += 1
        }
    }
    Box(
        modifier = Modifier
            .fillMaxSize()
            .clickable(onClick = onContinue)
            .padding(DS.Space.l)
            .alpha(appear),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                StringStore.text(context, "onboardingV2.transform.text", language),
                style = SophiaTypography.titleLarge,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(20.dp))
            if (words.isNotEmpty()) {
                Text(
                    words[wordIndex],
                    style = SophiaTypography.displayLarge,
                    color = DS.accentSoft,
                    textAlign = TextAlign.Center,
                )
            }
            Spacer(Modifier.height(24.dp))
            Text(
                StringStore.text(context, "onboardingV2.transform.tapHint", language),
                style = SophiaTypography.labelMedium,
                color = DS.inkTertiary,
            )
        }
    }
}

@Composable
internal fun ReviewStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    var index by remember { mutableIntStateOf(0) }
    LaunchedEffect(Unit) {
        while (index < 5) {
            delay(2200)
            index += 1
        }
    }
    val quote = StringStore.text(context, "onboardingV2.review.t${index + 1}.quote", language)
    val author = StringStore.text(context, "onboardingV2.review.t${index + 1}.author", language)
    Column(
        modifier = Modifier.fillMaxSize().padding(DS.Space.l),
        verticalArrangement = Arrangement.SpaceBetween,
    ) {
        Column {
            Spacer(Modifier.height(48.dp))
            Text(
                StringStore.text(context, "onboardingV2.review.title", language),
                style = SophiaTypography.titleLarge,
            )
            Spacer(Modifier.height(28.dp))
            AnimatedContent(
                targetState = index,
                transitionSpec = { fadeIn() togetherWith fadeOut() },
                label = "review",
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(DS.cardShape)
                        .background(DS.surface)
                        .padding(DS.Space.m),
                ) {
                    Text("★★★★★", color = DS.warm, fontSize = 18.sp)
                    Spacer(Modifier.height(12.dp))
                    Text("« $quote »", style = SophiaTypography.bodyLarge)
                    Spacer(Modifier.height(12.dp))
                    Text(author, style = SophiaTypography.labelLarge, color = DS.accentSoft)
                }
            }
        }
        PrimaryCta(StringStore.text(context, "common.continue", language), onContinue)
    }
}

@Composable
internal fun SwipeCoursesStep(
    language: AppLanguage,
    courses: List<Course>,
    onFinished: (likedIds: List<String>) -> Unit,
) {
    val context = LocalContext.current
    var index by remember { mutableIntStateOf(0) }
    var liked by remember { mutableStateOf(listOf<String>()) }

    fun advance(like: Boolean) {
        val course = courses.getOrNull(index) ?: return
        if (like) liked = liked + course.id
        if (index + 1 >= courses.size) onFinished(liked)
        else index += 1
    }

    if (courses.isEmpty()) {
        LaunchedEffect(Unit) { onFinished(emptyList()) }
        return
    }

    val course = courses[index]
    Column(
        modifier = Modifier.fillMaxSize().padding(DS.Space.l),
        verticalArrangement = Arrangement.SpaceBetween,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Spacer(Modifier.height(36.dp))
            Text(StringStore.text(context, "onboardingV2.swipe.title", language), style = SophiaTypography.titleLarge)
            Text(
                StringStore.text(context, "onboardingV2.swipe.subtitle", language),
                style = SophiaTypography.bodyMedium,
                modifier = Modifier.padding(top = 8.dp, bottom = 20.dp),
            )
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f)
                    .clip(DS.cardShape)
                    .background(DS.surface)
                    .border(1.dp, DS.hairline, DS.cardShape)
                    .padding(DS.Space.m),
                verticalArrangement = Arrangement.SpaceBetween,
            ) {
                Column {
                    Text(course.subjectEnum.storageKey, style = SophiaTypography.labelMedium, color = DS.accentSoft)
                    Spacer(Modifier.height(10.dp))
                    Text(course.title, style = SophiaTypography.titleLarge)
                    Spacer(Modifier.height(12.dp))
                    Text(course.description, style = SophiaTypography.bodyMedium, maxLines = 8)
                }
                Text("${index + 1}/${courses.size}", style = SophiaTypography.labelMedium)
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
            Button(
                onClick = { advance(false) },
                modifier = Modifier.weight(1f).height(52.dp),
                shape = DS.controlShape,
                colors = ButtonDefaults.buttonColors(containerColor = DS.surfaceMuted, contentColor = DS.ink),
            ) {
                Text(StringStore.text(context, "onboardingV2.swipe.nope", language))
            }
            Button(
                onClick = { advance(true) },
                modifier = Modifier.weight(1f).height(52.dp),
                shape = DS.controlShape,
                colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
            ) {
                Text(
                    StringStore.text(context, "onboardingV2.swipe.like", language),
                    color = Color.White,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                )
            }
        }
    }
}

@Composable
internal fun LoadingProfileStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    var stepDone by remember { mutableIntStateOf(0) }
    var ready by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        repeat(3) {
            delay(700)
            stepDone += 1
        }
        ready = true
    }
    Column(
        modifier = Modifier.fillMaxSize().padding(DS.Space.l),
        verticalArrangement = Arrangement.SpaceBetween,
    ) {
        Column {
            Spacer(Modifier.height(56.dp))
            Text(StringStore.text(context, "onboardingV2.loading.title", language), style = SophiaTypography.titleLarge)
            Spacer(Modifier.height(28.dp))
            listOf(1, 2, 3).forEach { n ->
                val active = stepDone >= n
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp)
                        .clip(DS.controlShape)
                        .background(if (active) DS.accentTint else DS.surface)
                        .padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(if (active) "✓" else "…", color = if (active) DS.success else DS.inkTertiary)
                    Spacer(Modifier.size(12.dp))
                    Text(
                        StringStore.text(context, "onboardingV2.loading.step$n", language),
                        style = SophiaTypography.bodyLarge,
                    )
                }
            }
            Spacer(Modifier.height(16.dp))
            Text(
                "★★★★★  " + StringStore.text(context, "onboardingV2.loading.reviews", language),
                style = SophiaTypography.labelMedium,
                color = DS.warm,
            )
        }
        PrimaryCta(
            text = StringStore.text(context, "onboardingV2.loading.cta", language),
            onClick = onContinue,
            enabled = ready,
        )
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

        fun fitting(heightDp: Dp): ProfileMetrics =
            if (heightDp < 740.dp) Compact else Regular
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
    val awaitingCourses = remember(language, likedCourseIds) {
        val excluded = likedCourseIds.toSet()
        ContentCatalog.courses(context, language)
            .filter { it.id !in excluded }
            .shuffled()
            .take(5)
    }

    var badgeIn by remember { mutableStateOf(false) }
    var nameRevealed by remember { mutableStateOf(false) }
    var reveal by remember { mutableIntStateOf(0) }
    LaunchedEffect(Unit) {
        delay(200)
        badgeIn = true
        delay(350)
        nameRevealed = true
        delay(450)
        reveal = 1
        delay(450)
        reveal = 2
    }
    // CTA reveal is independent of content animation (parity with iOS).
    var ctaVisible by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(1500)
        ctaVisible = true
    }
    val badgeScale by animateFloatAsState(if (badgeIn) 1f else 0.4f, tween(450), label = "badge")
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
                        .scale(badgeScale)
                        .clip(CircleShape)
                        .background(DS.accent.copy(alpha = 0.10f))
                        .border(1.dp, DS.accent.copy(alpha = 0.18f), CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        OBJECTIVE_EMOJI[archetype] ?: "📚",
                        fontSize = metrics.emojiSp.sp,
                    )
                }

                Spacer(Modifier.height(16.dp))
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier
                        .padding(horizontal = 28.dp)
                        .alpha(nameAlpha),
                ) {
                    Text(
                        StringStore.text(context, "onboardingV2.profile.eyebrow", language).uppercase(Locale.getDefault()),
                        style = SophiaTypography.labelMedium,
                        color = DS.accentSoft,
                        letterSpacing = 1.2.sp,
                    )
                    Spacer(Modifier.height(8.dp))
                    Text(
                        StringStore.text(context, "onboardingV2.profile.nickname.$archetype", language),
                        style = SophiaTypography.displayLarge,
                        textAlign = TextAlign.Center,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                    Spacer(Modifier.height(8.dp))
                    Text(
                        StringStore.text(context, "onboardingV2.profile.tagline.$archetype", language),
                        style = SophiaTypography.bodyMedium,
                        textAlign = TextAlign.Center,
                    )
                }

                Spacer(Modifier.height(metrics.sectionSpacing))
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier
                        .fillMaxWidth()
                        .alpha(objAlpha)
                        .offset(y = if (reveal >= 1) 0.dp else 16.dp),
                ) {
                    Text(
                        StringStore.text(context, "onboardingV2.profile.objectiveTitle", language)
                            .uppercase(Locale.getDefault()),
                        style = SophiaTypography.labelMedium,
                        color = DS.inkTertiary,
                        letterSpacing = 1.sp,
                    )
                    Spacer(Modifier.height(10.dp))
                    FlowRow(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 24.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        objectives.forEach { key ->
                            Row(
                                modifier = Modifier
                                    .clip(CircleShape)
                                    .background(DS.surface)
                                    .border(1.dp, DS.accent.copy(alpha = 0.25f), CircleShape)
                                    .padding(horizontal = 14.dp, vertical = 9.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Text(OBJECTIVE_EMOJI[key] ?: "📚", fontSize = 15.sp)
                                Spacer(Modifier.size(8.dp))
                                Text(
                                    StringStore.text(context, "onboardingV2.objective.$key", language),
                                    style = SophiaTypography.bodyMedium.copy(fontWeight = FontWeight.SemiBold),
                                    color = DS.ink,
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
                            .alpha(coursesAlpha)
                            .offset(y = if (reveal >= 2) 0.dp else 20.dp),
                    ) {
                        Text(
                            StringStore.text(context, "onboardingV2.profile.coursesTitle", language),
                            style = SophiaTypography.titleMedium,
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

            // Pinned CTA — always tappable even before fade-in completes.
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = DS.Space.l)
                    .padding(bottom = 12.dp)
                    .alpha(ctaAlpha.coerceAtLeast(0.35f)),
            ) {
                PrimaryCta(
                    text = StringStore.text(context, "onboardingV2.profile.cta", language),
                    onClick = onContinue,
                )
            }
        }
    }
}

@Composable
private fun ProfileCourseCard(
    course: Course,
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
            .border(1.dp, DS.hairline, RoundedCornerShape(20.dp)),
    ) {
        CourseImage(
            courseId = course.id,
            modifier = Modifier.fillMaxSize(),
            contentScale = ContentScale.Crop,
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
            modifier = Modifier
                .align(Alignment.BottomStart)
                .padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Text(
                StringStore.text(
                    context,
                    "subject.${course.subjectEnum.storageKey}.short",
                    language,
                ).uppercase(Locale.getDefault()),
                style = SophiaTypography.labelMedium.copy(fontSize = 11.sp, fontWeight = FontWeight.Bold),
                color = Color.White,
                modifier = Modifier
                    .clip(CircleShape)
                    .background(Color.White.copy(alpha = 0.22f))
                    .padding(horizontal = 8.dp, vertical = 4.dp),
            )
            Text(
                course.title,
                style = SophiaTypography.bodyMedium.copy(fontWeight = FontWeight.Bold, color = Color.White),
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
    if (legalDoc != null) {
        LegalDocumentScreen(
            kind = legalDoc!!,
            language = language,
            onBack = { legalDoc = null },
        )
        return
    }
    Column(
        modifier = Modifier.fillMaxSize().padding(DS.Space.l),
        verticalArrangement = Arrangement.SpaceBetween,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.height(72.dp))
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text("Sophia", style = SophiaTypography.displayLarge)
            Spacer(Modifier.height(12.dp))
            Text(
                StringStore.text(context, "onboardingV2.login.title", language),
                style = SophiaTypography.titleLarge,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(8.dp))
            Text(
                StringStore.text(context, "onboardingV2.login.subtitle", language),
                style = SophiaTypography.bodyMedium,
                textAlign = TextAlign.Center,
            )
        }
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            PrimaryCta("Continue with Google", onGoogle)
            Text(
                text = StringStore.text(context, "home.skip", language),
                style = SophiaTypography.labelLarge,
                color = DS.inkSecondary,
                modifier = Modifier
                    .align(Alignment.CenterHorizontally)
                    .clickable(onClick = onSkip)
                    .padding(8.dp),
            )
            // auth.legal.prefix + tappable Terms / Privacy
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
            ) {
                Text(
                    StringStore.text(context, "auth.legal.prefix", language) + " ",
                    style = SophiaTypography.labelMedium,
                    color = DS.inkTertiary,
                )
            }
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    StringStore.text(context, "legal.terms.title", language),
                    style = SophiaTypography.labelMedium,
                    color = DS.accentSoft,
                    modifier = Modifier
                        .clickable { legalDoc = LegalDocKind.Terms }
                        .padding(horizontal = 6.dp, vertical = 4.dp),
                )
                Text("·", color = DS.inkTertiary)
                Text(
                    StringStore.text(context, "legal.privacy.title", language),
                    style = SophiaTypography.labelMedium,
                    color = DS.accentSoft,
                    modifier = Modifier
                        .clickable { legalDoc = LegalDocKind.Privacy }
                        .padding(horizontal = 6.dp, vertical = 4.dp),
                )
            }
        }
    }
}

@Composable
internal fun TrialStepsStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val endDate = remember {
        LocalDate.now().plusDays(3).format(DateTimeFormatter.ofPattern("d MMMM", Locale.FRENCH))
    }
    Column(
        modifier = Modifier.fillMaxSize().padding(DS.Space.l),
        verticalArrangement = Arrangement.SpaceBetween,
    ) {
        Column {
            Spacer(Modifier.height(40.dp))
            Text(StringStore.text(context, "onboardingV2.trial.title", language), style = SophiaTypography.titleLarge)
            Spacer(Modifier.height(20.dp))
            (0..3).forEach { i ->
                val detail = StringStore.text(context, "onboardingV2.trial.step$i.detail", language, endDate)
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp)
                        .clip(DS.controlShape)
                        .background(DS.surface)
                        .padding(14.dp),
                ) {
                    Text("${i + 1}", style = SophiaTypography.titleMedium, color = DS.accentSoft)
                    Spacer(Modifier.size(12.dp))
                    Column {
                        Text(
                            StringStore.text(context, "onboardingV2.trial.step$i.title", language),
                            style = SophiaTypography.titleMedium,
                        )
                        Text(detail, style = SophiaTypography.bodyMedium)
                    }
                }
            }
        }
        PrimaryCta(StringStore.text(context, "onboardingV2.trial.cta", language), onContinue)
    }
}

@Composable
internal fun ReminderStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    Column(
        modifier = Modifier.fillMaxSize().padding(DS.Space.l),
        verticalArrangement = Arrangement.SpaceBetween,
    ) {
        Column {
            Spacer(Modifier.height(80.dp))
            Text(
                StringStore.text(context, "onboardingV2.reminder.title", language),
                style = SophiaTypography.titleLarge,
            )
        }
        PrimaryCta(StringStore.text(context, "onboardingV2.reminder.cta", language), onContinue)
    }
}

@Composable
private fun SelectRow(label: String, selected: Boolean, onClick: () -> Unit) {
    Text(
        text = label,
        style = SophiaTypography.bodyLarge,
        modifier = Modifier
            .fillMaxWidth()
            .clip(DS.controlShape)
            .background(if (selected) DS.accentTint else DS.surface)
            .border(1.dp, if (selected) DS.accentSoft else DS.hairline, DS.controlShape)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 14.dp),
    )
}

@Composable
internal fun PrimaryCta(text: String, onClick: () -> Unit, enabled: Boolean = true) {
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = Modifier.fillMaxWidth().height(54.dp),
        shape = DS.controlShape,
        colors = ButtonDefaults.buttonColors(containerColor = DS.accent, contentColor = Color.White),
    ) {
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 16.sp,
        )
    }
}
