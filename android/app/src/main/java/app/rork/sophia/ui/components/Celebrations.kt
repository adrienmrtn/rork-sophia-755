package app.rork.sophia.ui.components

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Icon
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.TextStyle
import app.rork.sophia.domain.Subject
import app.rork.sophia.domain.displayNameIn
import app.rork.sophia.ui.onboarding.ConfettiBurst
import java.time.LocalDate
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CollectionProgressEvent
import app.rork.sophia.domain.PostCompletionRewardStep
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography

/**
 * The streak, as on iOS: a pink-orange flame that beats in a breathing halo, the counter that
 * jumps one notch with a burst of confetti, the week in pink dots. Warmth, no grey.
 */
@Composable
fun StreakCelebration(
    streak: Int,
    language: AppLanguage,
    onContinue: () -> Unit,
    subject: Subject? = null,
    lastActiveDate: String? = null,
) {
    val context = LocalContext.current
    val flameScale = remember { Animatable(0.5f) }
    val numberIn = remember { Animatable(0f) }
    val numberBounce = remember { Animatable(1f) }
    val appeared = remember { Animatable(0f) }
    var displayed by remember { mutableIntStateOf(maxOf(0, streak - 1)) }
    var confetti by remember { mutableStateOf(false) }
    val halo by rememberInfiniteTransition(label = "streakHalo").animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(1100, easing = FastOutSlowInEasing), RepeatMode.Reverse),
        label = "halo",
    )

    LaunchedEffect(Unit) {
        launch {
            delay(50)
            flameScale.animateTo(1f, spring(dampingRatio = 0.6f, stiffness = 160f))
        }
        launch {
            delay(300)
            numberIn.animateTo(1f, spring(dampingRatio = 0.65f, stiffness = 200f))
        }
        launch {
            delay(600)
            appeared.animateTo(1f, tween(450))
        }
        delay(550)
        // The counter jumps a notch: a small bounce and confetti.
        displayed = streak
        confetti = true
        numberBounce.animateTo(1.18f, spring(dampingRatio = 0.45f, stiffness = 440f))
        numberBounce.animateTo(1f, spring(dampingRatio = 0.7f, stiffness = 250f))
    }

    val dayLabel = StringStore.text(
        context,
        if (streak <= 1) "course.streak.day" else "course.streak.days",
        language,
    )

    Box(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
        Column(modifier = Modifier.fillMaxSize()) {
            Column(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(vertical = 16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                Box(
                    modifier = Modifier.size(164.dp).graphicsLayer {
                        scaleX = flameScale.value
                        scaleY = flameScale.value
                    },
                    contentAlignment = Alignment.Center,
                ) {
                    Box(
                        modifier = Modifier
                            .size(164.dp)
                            .graphicsLayer {
                                val scale = 0.94f + 0.14f * halo
                                scaleX = scale
                                scaleY = scale
                                alpha = 1f - 0.3f * halo
                            }
                            .background(StreakColors.pink.copy(alpha = 0.14f), CircleShape),
                    )
                    Box(
                        modifier = Modifier
                            .size(128.dp)
                            .background(
                                Brush.linearGradient(
                                    listOf(StreakColors.pink.copy(alpha = 0.22f), StreakColors.orange.copy(alpha = 0.18f)),
                                ),
                                CircleShape,
                            ),
                    )
                    AnimatedFlameBadge(size = 60.dp, showGlow = false)
                }
                Spacer(Modifier.height(8.dp))
                Text(
                    text = "$displayed",
                    style = TextStyle(
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 76.sp,
                        brush = Brush.verticalGradient(listOf(StreakColors.pink, StreakColors.orange)),
                    ),
                    modifier = Modifier.graphicsLayer {
                        val scale = (0.6f + 0.4f * numberIn.value) * numberBounce.value
                        scaleX = scale
                        scaleY = scale
                        alpha = numberIn.value.coerceIn(0f, 1f)
                    },
                )
                Text(
                    text = dayLabel,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 20.sp,
                    color = DS.ink,
                    modifier = Modifier.alpha(numberIn.value.coerceIn(0f, 1f)),
                )
                if (subject != null) {
                    Text(
                        text = StringStore.text(
                            context,
                            "course.streak.message",
                            language,
                            StringStore.text(context, "subject.${subject.storageKey}.short", language),
                        ),
                        style = SophiaTypography.bodyMedium,
                        textAlign = TextAlign.Center,
                        modifier = Modifier
                            .padding(horizontal = 32.dp)
                            .padding(top = 12.dp)
                            .alpha(appeared.value),
                    )
                }
                Spacer(Modifier.height(22.dp))
                StreakWeekStrip(
                    streak = streak,
                    lastActiveDate = lastActiveDate,
                    language = language,
                    modifier = Modifier
                        .padding(horizontal = 22.dp)
                        .graphicsLayer {
                            alpha = appeared.value
                            translationY = (1f - appeared.value) * 10.dp.toPx()
                        },
                )
                Spacer(Modifier.height(18.dp))
                Text(
                    text = StringStore.text(context, "course.streak.onTrack", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 17.sp,
                    color = StreakColors.pink,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(horizontal = 24.dp).alpha(appeared.value),
                )
            }
            Box(
                modifier = Modifier
                    .padding(horizontal = 24.dp)
                    .padding(bottom = 24.dp)
                    .graphicsLayer {
                        alpha = appeared.value
                        translationY = (1f - appeared.value) * 10.dp.toPx()
                    },
            ) {
                ContinueButton(language = language, onContinue = onContinue)
            }
        }
        if (confetti) {
            ConfettiBurst(
                colors = listOf(StreakColors.pink, StreakColors.orange, StreakColors.yellow, DS.accentSoft),
                modifier = Modifier.fillMaxSize(),
                pieceCount = 60,
                durationMillis = 2600,
                origin = Offset(0.5f, 0.3f),
            )
        }
    }
}

/**
 * Monday to Sunday of this week: the days the streak covers in pink, today ringed in pink,
 * the days to come faded.
 */
@Composable
private fun StreakWeekStrip(
    streak: Int,
    lastActiveDate: String?,
    language: AppLanguage,
    modifier: Modifier = Modifier,
) {
    val today = remember { LocalDate.now() }
    val monday = today.with(java.time.DayOfWeek.MONDAY)
    val last = remember(lastActiveDate) { lastActiveDate?.let { runCatching { LocalDate.parse(it) }.getOrNull() } }
    Row(modifier = modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        repeat(7) { i ->
            val date = monday.plusDays(i.toLong())
            val isToday = date == today
            val isFuture = date.isAfter(today)
            val isDone = !isFuture && last != null && !date.isAfter(last) &&
                java.time.temporal.ChronoUnit.DAYS.between(date, last) < streak
            Column(
                modifier = Modifier.weight(1f).alpha(if (isFuture) 0.5f else 1f),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Text(
                    text = date.dayOfWeek.displayNameIn(language, java.time.format.TextStyle.NARROW),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Medium,
                    fontSize = 11.sp,
                    color = DS.inkTertiary,
                )
                Box(
                    modifier = Modifier
                        .size(32.dp)
                        .clip(CircleShape)
                        .then(
                            when {
                                isDone -> Modifier.background(
                                    Brush.linearGradient(listOf(StreakColors.pink, StreakColors.orange)),
                                )
                                isToday -> Modifier
                                    .background(DS.surface)
                                    .border(2.dp, StreakColors.pink, CircleShape)
                                else -> Modifier.background(DS.surfaceMuted)
                            },
                        ),
                    contentAlignment = Alignment.Center,
                ) {
                    if (isDone) {
                        Icon(Icons.Filled.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(15.dp))
                    }
                }
            }
        }
    }
}

@Composable
fun RankUpCelebration(
    rankKey: String,
    level: Int,
    language: AppLanguage,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    var target by remember { mutableFloatStateOf(0.9f) }
    LaunchedEffect(Unit) { target = 1f }
    val scale by animateFloatAsState(target, animationSpec = tween(450), label = "rank")

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas)
            .padding(DS.Space.l),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.scale(scale),
        ) {
            Text(
                text = StringStore.text(context, "globalRank.newRank", language),
                style = SophiaTypography.labelLarge,
                color = DS.accentSoft,
            )
            Spacer(Modifier.height(8.dp))
            // `rankKey` is the storage key ("erudit"), not a label: title-casing it printed
            // the raw value in every language. The translations live under `globalRank.*`.
            Text(
                text = StringStore.text(context, "globalRank.$rankKey", language),
                style = SophiaTypography.displayLarge,
            )
            Text(
                text = StringStore.text(context, "common.levelShort", language, level),
                style = SophiaTypography.titleMedium,
            )
            Spacer(Modifier.height(24.dp))
            ContinueButton(language = language, onContinue = onContinue)
        }
    }
}

@Composable
fun CollectionCelebration(
    event: CollectionProgressEvent,
    language: AppLanguage,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    var target by remember { mutableFloatStateOf(0.92f) }
    LaunchedEffect(Unit) { target = 1f }
    val scale by animateFloatAsState(target, animationSpec = tween(450), label = "collection")
    val titleKey = if (event.isComplete) "celebration.collectionComplete" else "celebration.collectionAdvanced"
    val progress = if (event.totalCount == 0) 0f
    else event.newCompletedCount.toFloat() / event.totalCount

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas)
            .padding(DS.Space.l),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.scale(scale),
        ) {
            if (event.isComplete) {
                AnimatedRewardBadge(kind = RewardBadgeKind.Seal, size = 44.dp)
                Spacer(Modifier.height(14.dp))
            }
            Text(
                text = StringStore.text(context, titleKey, language),
                style = SophiaTypography.labelLarge,
                color = DS.accentSoft,
            )
            Spacer(Modifier.height(10.dp))
            Text(
                text = event.collection.title,
                style = SophiaTypography.displayLarge,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = "${event.newCompletedCount} / ${event.totalCount}",
                style = SophiaTypography.titleMedium,
            )
            Spacer(Modifier.height(16.dp))
            LinearProgressIndicator(
                progress = { progress },
                modifier = Modifier.fillMaxWidth().height(8.dp),
                color = DS.accent,
                trackColor = DS.hairline,
                strokeCap = StrokeCap.Round,
            )
            Spacer(Modifier.height(24.dp))
            ContinueButton(language = language, onContinue = onContinue)
        }
    }
}

/** A level gained: the violet-pink bolt, the level in its gradient, and confetti (iOS). */
@Composable
fun LevelUpCelebration(
    level: Int,
    language: AppLanguage,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    var target by remember { mutableFloatStateOf(0.9f) }
    LaunchedEffect(Unit) { target = 1f }
    val scale by animateFloatAsState(target, animationSpec = tween(450), label = "level")
    val bolt = remember { Animatable(0.3f) }
    LaunchedEffect(Unit) {
        delay(150)
        bolt.animateTo(1f, spring(dampingRatio = 0.55f, stiffness = 220f))
    }
    val levelColors = RewardBadgeKind.LevelUp.colors

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas),
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier
                .align(Alignment.Center)
                .padding(DS.Space.l)
                .scale(scale),
        ) {
            AnimatedRewardBadge(
                kind = RewardBadgeKind.LevelUp,
                size = 56.dp,
                modifier = Modifier.graphicsLayer {
                    scaleX = bolt.value
                    scaleY = bolt.value
                    alpha = ((bolt.value - 0.3f) / 0.7f).coerceIn(0f, 1f)
                },
            )
            Spacer(Modifier.height(16.dp))
            Text(
                text = StringStore.text(context, "globalRank.reachedLevel", language, level),
                style = SophiaTypography.labelLarge,
                color = DS.accentSoft,
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = StringStore.text(context, "common.levelShort", language, level),
                style = SophiaTypography.displayLarge.copy(
                    fontSize = 44.sp,
                    brush = Brush.verticalGradient(levelColors.reversed()),
                ),
            )
            Spacer(Modifier.height(24.dp))
            ContinueButton(language = language, onContinue = onContinue)
        }
        ConfettiBurst(
            colors = levelColors + DS.accentSoft,
            modifier = Modifier.fillMaxSize(),
            pieceCount = 50,
            durationMillis = 2400,
            origin = Offset(0.5f, 0.28f),
        )
    }
}

@Composable
fun PostCompletionRewardFlow(
    steps: List<PostCompletionRewardStep>,
    language: AppLanguage,
    onFinished: () -> Unit,
) {
    if (steps.isEmpty()) {
        LaunchedEffect(Unit) { onFinished() }
        return
    }
    var index by remember { mutableIntStateOf(0) }
    if (index !in steps.indices) {
        LaunchedEffect(Unit) { onFinished() }
        return
    }
    val step = steps[index]

    fun next() {
        if (index + 1 >= steps.size) onFinished() else index += 1
    }

    when (step) {
        is PostCompletionRewardStep.Streak ->
            StreakCelebration(
                streak = step.days,
                language = language,
                onContinue = ::next,
                subject = step.subject,
                lastActiveDate = step.lastActiveDate,
            )
        is PostCompletionRewardStep.RankUp ->
            RankUpCelebration(
                rankKey = step.rankKey,
                level = step.level,
                language = language,
                onContinue = ::next,
            )
        is PostCompletionRewardStep.Collection ->
            CollectionCelebration(event = step.event, language = language, onContinue = ::next)
        is PostCompletionRewardStep.LevelUp ->
            LevelUpCelebration(level = step.level, language = language, onContinue = ::next)
    }
}

@Composable
private fun ContinueButton(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    Button(
        onClick = onContinue,
        modifier = Modifier.fillMaxWidth().height(52.dp),
        shape = DS.controlShape,
        colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
    ) {
        Text(
            text = StringStore.text(context, "common.continue", language),
            color = Color.White,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
        )
    }
}
