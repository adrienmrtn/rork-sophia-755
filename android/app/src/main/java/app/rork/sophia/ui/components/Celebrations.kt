package app.rork.sophia.ui.components

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

@Composable
fun StreakCelebration(
    streak: Int,
    language: AppLanguage,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    var target by remember { mutableFloatStateOf(0.85f) }
    LaunchedEffect(Unit) { target = 1f }
    val scale by animateFloatAsState(target, animationSpec = tween(500), label = "streak")
    val dayLabel = StringStore.text(
        context,
        if (streak <= 1) "course.streak.day" else "course.streak.days",
        language,
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas)
            .padding(DS.Space.l),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.scale(scale),
        ) {
            Text("🔥", fontSize = 64.sp)
            Text(
                text = "$streak $dayLabel",
                style = SophiaTypography.displayLarge,
                textAlign = TextAlign.Center,
            )
            Text(
                text = StringStore.text(context, "course.streak.onTrack", language),
                style = SophiaTypography.bodyMedium,
                textAlign = TextAlign.Center,
            )
            Spacer(modifier.height(16.dp))
            ContinueButton(language = language, onContinue = onContinue)
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
            Text(rankKey.replaceFirstChar { it.titlecase() }, style = SophiaTypography.displayLarge)
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
                text = StringStore.text(context, "globalRank.reachedLevel", language, level),
                style = SophiaTypography.labelLarge,
                color = DS.accentSoft,
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = StringStore.text(context, "common.levelShort", language, level),
                style = SophiaTypography.displayLarge,
            )
            Spacer(Modifier.height(24.dp))
            ContinueButton(language = language, onContinue = onContinue)
        }
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
            StreakCelebration(streak = step.days, language = language, onContinue = ::next)
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
