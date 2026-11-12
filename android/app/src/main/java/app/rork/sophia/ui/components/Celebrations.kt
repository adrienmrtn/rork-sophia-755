package app.rork.sophia.ui.components

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CollectionProgressEvent
import app.rork.sophia.domain.PostCompletionRewardStep
import app.rork.sophia.domain.Subject
import app.rork.sophia.domain.displayNameIn
import app.rork.sophia.ui.onboarding.ConfettiBurst
import app.rork.sophia.ui.onboarding.readableWidth
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import java.time.LocalDate
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/** The confetti of a reward: the gold of the XP and the blue of the app. */
private val rewardConfetti
    get() = listOf(CoursePalette.gold, CoursePalette.goldTint, DS.accent, DS.accentTint)

/**
 * The frame of a reward screen: its content centred in the room above the button, and
 * « Continuer » anchored at the bottom (it vibrates by its style).
 */
@Composable
private fun CelebrationScaffold(
    language: AppLanguage,
    onContinue: () -> Unit,
    /** Position of the button in the cascade of the screen. */
    ctaStaggerIndex: Int = 6,
    overlay: @Composable () -> Unit = {},
    content: @Composable () -> Unit,
) {
    val context = LocalContext.current
    Box(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
        Column(modifier = Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
            Column(
                modifier = Modifier
                    .weight(1f)
                    .readableWidth()
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 24.dp, vertical = 20.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                content()
            }
            SophiaPrimaryButton(
                text = StringStore.text(context, "common.continue", language),
                onClick = onContinue,
                modifier = Modifier
                    .readableWidth()
                    .padding(start = 24.dp, end = 24.dp, bottom = 24.dp)
                    .dsStagger(ctaStaggerIndex, stepMillis = 110),
            )
        }
        overlay()
    }
}

/**
 * The streak, as on iOS: the saffron flame that sways, the number of days that arrives with a
 * counter, then the week in pills that appear in cascade.
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
    val haptics = rememberHaptics()
    val flameScale = remember { Animatable(0.5f) }
    val numberIn = remember { Animatable(0f) }
    val appeared = remember { Animatable(0f) }
    // The value the counter rolls up to: 0, then the streak.
    var countTarget by remember { mutableIntStateOf(0) }
    var confetti by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        launch {
            delay(50)
            flameScale.animateTo(1f, DSMotion.pop())
        }
        launch {
            delay(250)
            numberIn.animateTo(1f, DSMotion.pop())
        }
        launch {
            delay(600)
            appeared.animateTo(1f, tween(450))
        }
        // The counter starts once the number is visible; it vibrates in small notches (`DSCountUp`).
        delay(450)
        countTarget = streak
        // The counter has arrived: the reward, and a rain of confetti.
        delay(1100)
        haptics.celebrate()
        confetti = true
    }

    val dayLabel = StringStore.text(
        context,
        if (streak <= 1) "course.streak.day" else "course.streak.days",
        language,
    )

    CelebrationScaffold(
        language = language,
        onContinue = onContinue,
        ctaStaggerIndex = 8,
        overlay = {
            if (confetti) {
                ConfettiBurst(
                    colors = rewardConfetti,
                    modifier = Modifier.fillMaxSize(),
                    pieceCount = 60,
                    durationMillis = 2600,
                    origin = Offset(0.5f, 0.3f),
                )
            }
        },
    ) {
        DSFlame(
            size = 84.dp,
            modifier = Modifier.graphicsLayer {
                scaleX = flameScale.value
                scaleY = flameScale.value
            },
        )
        Spacer(Modifier.height(6.dp))
        DSCountUp(
            value = countTarget,
            durationMillis = 900,
            style = TextStyle(fontFamily = PlusJakartaSans, fontWeight = FontWeight.ExtraBold, fontSize = 92.sp),
            color = DS.ink,
            modifier = Modifier
                .graphicsLayer {
                    val scale = 0.6f + 0.4f * numberIn.value
                    scaleX = scale
                    scaleY = scale
                    alpha = numberIn.value.coerceIn(0f, 1f)
                }
                .clearAndSetSemantics { contentDescription = "$streak" },
        )
        Text(
            text = dayLabel,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 22.sp,
            color = DS.ink,
            textAlign = TextAlign.Center,
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
                style = SophiaTypography.bodyMedium.copy(fontSize = 16.sp, lineHeight = 24.sp),
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .padding(horizontal = 8.dp)
                    .padding(top = 12.dp)
                    .alpha(appeared.value),
            )
        }
        Spacer(Modifier.height(24.dp))
        // The pills arrive in cascade; the check of each day done draws itself in turn.
        StreakWeekStrip(
            streak = streak,
            lastActiveDate = lastActiveDate,
            language = language,
            cascadeBaseMillis = 750,
        )
        Spacer(Modifier.height(20.dp))
        Text(
            text = StringStore.text(context, "course.streak.onTrack", language),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 16.sp,
            color = DS.ink,
            textAlign = TextAlign.Center,
            modifier = Modifier.alpha(appeared.value),
        )
    }
}

/**
 * Seven days starting on the first day of the streak (not on Monday): the days the streak
 * covers in gold, today ringed in gold, the days to come faded. On the eighth day a new row
 * starts; it does not slide one day at a time.
 */
/** The day in the first cell of the streak row. A broken streak starts again from today. */
internal fun streakWeekFirstDay(streak: Int, last: LocalDate?, today: LocalDate): LocalDate {
    if (streak <= 0 || last == null) return today
    val gap = java.time.temporal.ChronoUnit.DAYS.between(last, today)
    if (gap < 0 || gap > 1) return today
    val start = last.minusDays((streak - 1).toLong())
    val elapsed = java.time.temporal.ChronoUnit.DAYS.between(start, today)
    return start.plusDays((elapsed / 7) * 7)
}

/**
 * The week of the streak: a golden checked pill for a day done, a golden ring for today, a
 * plain ring otherwise; the initial of the day underneath. With [cascadeBaseMillis] the pills
 * arrive one after the other from that delay (the streak screen); without it they are simply
 * there (the progress page).
 */
@Composable
internal fun StreakWeekStrip(
    streak: Int,
    lastActiveDate: String?,
    language: AppLanguage,
    modifier: Modifier = Modifier,
    cascadeBaseMillis: Int? = null,
) {
    val today = remember { LocalDate.now() }
    val last = remember(lastActiveDate) { lastActiveDate?.let { runCatching { LocalDate.parse(it) }.getOrNull() } }
    val firstDay = streakWeekFirstDay(streak, last, today)
    Row(modifier = modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        repeat(7) { i ->
            val date = firstDay.plusDays(i.toLong())
            val isToday = date == today
            val isFuture = date.isAfter(today)
            val isDone = !isFuture && last != null && !date.isAfter(last) &&
                java.time.temporal.ChronoUnit.DAYS.between(date, last) < streak
            Column(
                modifier = Modifier
                    .weight(1f)
                    .then(
                        if (cascadeBaseMillis != null) {
                            Modifier.dsStagger(i, stepMillis = 70, baseMillis = cascadeBaseMillis, offset = 10.dp)
                        } else {
                            Modifier
                        },
                    ),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Box(
                    modifier = Modifier.size(36.dp).alpha(if (isFuture) 0.6f else 1f),
                    contentAlignment = Alignment.Center,
                ) {
                    if (isDone) {
                        DSCheckBadge(
                            size = 36.dp,
                            fill = CoursePalette.gold,
                            delayMillis = if (cascadeBaseMillis != null) cascadeBaseMillis + 200 + i * 70 else 0,
                        )
                    } else {
                        Box(
                            modifier = Modifier
                                .fillMaxSize()
                                .background(DS.surface, CircleShape)
                                .border(
                                    width = if (isToday) 2.5.dp else 1.5.dp,
                                    color = if (isToday) CoursePalette.gold else DS.ink.copy(alpha = 0.2f),
                                    shape = CircleShape,
                                ),
                        )
                    }
                }
                Text(
                    text = date.dayOfWeek.displayNameIn(language, java.time.format.TextStyle.NARROW),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 12.sp,
                    color = DS.ink,
                )
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
    val haptics = rememberHaptics()
    LaunchedEffect(Unit) {
        // The new rank lands: the reward vibration.
        delay(350)
        haptics.celebrate()
    }

    CelebrationScaffold(language = language, onContinue = onContinue, ctaStaggerIndex = 5) {
        Box(
            modifier = Modifier.size(132.dp).dsPopIn().background(CoursePalette.goldTint, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            AnimatedRewardBadge(kind = RewardBadgeKind.Trophy, size = 56.dp, showGlow = false)
        }
        Spacer(Modifier.height(22.dp))
        DSEyebrow(
            text = StringStore.text(context, "globalRank.newRank", language),
            modifier = Modifier.dsStagger(1, stepMillis = 110),
        )
        Spacer(Modifier.height(8.dp))
        // `rankKey` is the storage key ("erudit"), not a label: title-casing it printed
        // the raw value in every language. The translations live under `globalRank.*`.
        Text(
            text = StringStore.text(context, "globalRank.$rankKey", language),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 34.sp,
            lineHeight = 41.sp,
            color = DS.accent,
            textAlign = TextAlign.Center,
            modifier = Modifier.dsStagger(2, stepMillis = 110),
        )
        Spacer(Modifier.height(10.dp))
        Text(
            text = StringStore.text(context, "common.levelShort", language, level),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 13.sp,
            color = DS.ink,
            modifier = Modifier
                .dsStagger(3, stepMillis = 110)
                .background(DS.accentTint, CircleShape)
                .padding(horizontal = 12.dp, vertical = 5.dp),
        )
    }
}

@Composable
fun CollectionCelebration(
    event: CollectionProgressEvent,
    language: AppLanguage,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val titleKey = if (event.isComplete) "celebration.collectionComplete" else "celebration.collectionAdvanced"
    val progress = if (event.totalCount == 0) 0f
    else event.newCompletedCount.toFloat() / event.totalCount
    // The bar starts empty and fills up to the collection's progress.
    var shownProgress by remember { mutableStateOf(0f) }
    LaunchedEffect(Unit) {
        delay(450)
        shownProgress = progress
        // A collection completed is a reward; a step forward simply settles.
        if (event.isComplete) haptics.celebrate() else haptics.success()
    }

    CelebrationScaffold(
        language = language,
        onContinue = onContinue,
        ctaStaggerIndex = 5,
        overlay = {
            if (event.isComplete) {
                ConfettiBurst(
                    colors = rewardConfetti,
                    modifier = Modifier.fillMaxSize(),
                    pieceCount = 50,
                    durationMillis = 2400,
                    origin = Offset(0.5f, 0.28f),
                )
            }
        },
    ) {
        if (event.isComplete) {
            Box(
                modifier = Modifier.size(112.dp).dsPopIn().background(DS.successTint, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                AnimatedRewardBadge(kind = RewardBadgeKind.Seal, size = 48.dp, showGlow = false)
            }
            Spacer(Modifier.height(20.dp))
        }
        DSEyebrow(
            text = StringStore.text(context, titleKey, language),
            modifier = Modifier.dsStagger(1, stepMillis = 110),
        )
        Spacer(Modifier.height(10.dp))
        Text(
            text = event.collection.title,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 28.sp,
            lineHeight = 35.sp,
            color = DS.ink,
            textAlign = TextAlign.Center,
            modifier = Modifier.dsStagger(2, stepMillis = 110),
        )
        Spacer(Modifier.height(22.dp))
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .dsStagger(3, stepMillis = 110)
                .sophiaCard()
                .padding(DS.Space.m),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(
                text = "${event.newCompletedCount} / ${event.totalCount}",
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 17.sp,
                color = DS.ink,
            )
            DSProgressBar(value = shownProgress, height = 8.dp, track = CoursePalette.track)
        }
    }
}

/** A level gained: the bolt, the level in bold blue, the reward vibration and confetti. */
@Composable
fun LevelUpCelebration(
    level: Int,
    language: AppLanguage,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val levelScale = remember { Animatable(0.5f) }
    var showLevel by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(500)
        // The new level lands: the reward vibration.
        haptics.celebrate()
        showLevel = true
        levelScale.animateTo(1f, DSMotion.pop())
    }

    CelebrationScaffold(
        language = language,
        onContinue = onContinue,
        ctaStaggerIndex = 6,
        overlay = {
            if (showLevel) {
                ConfettiBurst(
                    colors = rewardConfetti,
                    modifier = Modifier.fillMaxSize(),
                    pieceCount = 50,
                    durationMillis = 2400,
                    origin = Offset(0.5f, 0.28f),
                )
            }
        },
    ) {
        Box(
            modifier = Modifier.size(132.dp).dsPopIn().background(DS.accentTint, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            AnimatedRewardBadge(kind = RewardBadgeKind.LevelUp, size = 56.dp, showGlow = false)
        }
        Spacer(Modifier.height(22.dp))
        Text(
            text = StringStore.text(context, "globalRank.reachedLevel", language, level),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 24.sp,
            lineHeight = 31.sp,
            color = DS.ink,
            textAlign = TextAlign.Center,
            modifier = Modifier.dsStagger(1, stepMillis = 110),
        )
        Spacer(Modifier.height(14.dp))
        Text(
            text = StringStore.text(context, "common.levelShort", language, level),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 44.sp,
            color = DS.accent,
            textAlign = TextAlign.Center,
            modifier = Modifier.graphicsLayer {
                scaleX = levelScale.value
                scaleY = levelScale.value
                alpha = if (showLevel) 1f else 0f
            },
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

    // Keyed by its position: two rewards of the same kind in a row (two collections) each
    // play their own entrance.
    key(index) {
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
}
