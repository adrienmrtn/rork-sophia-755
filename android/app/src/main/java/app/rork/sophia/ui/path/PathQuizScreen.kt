package app.rork.sophia.ui.path

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Replay
import androidx.compose.material.icons.filled.Shuffle
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.TrackChanges
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.analytics.Analytics
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.LearningPathRules
import app.rork.sophia.domain.PathLevel
import app.rork.sophia.domain.PathLevelResult
import app.rork.sophia.domain.PathQuizBuilder
import app.rork.sophia.domain.QuizQuestion
import app.rork.sophia.domain.QuizShuffler
import app.rork.sophia.domain.ShuffledQuestion
import app.rork.sophia.ui.components.CircleIconButton
import app.rork.sophia.ui.components.ConfirmDialog
import app.rork.sophia.ui.components.DSCountUp
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.DSSegmentedProgress
import app.rork.sophia.ui.components.RankUpCelebration
import app.rork.sophia.ui.components.SophiaPrimaryButton
import app.rork.sophia.ui.components.SophiaSecondaryButton
import app.rork.sophia.ui.components.dsPopIn
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.onboarding.ConfettiBurst
import app.rork.sophia.ui.onboarding.readableWidth
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlin.math.cos
import kotlin.math.sin
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private enum class PathQuizPhase { Intro, Questions, Result }

internal data class PathQuizEntry(val course: CourseSummary, val question: ShuffledQuestion)

/**
 * End-of-level quiz of the learning path: a fresh draw of questions mixed from the level's
 * courses, passed with strictly more than half of them fully right. Attempts are unlimited
 * and free; passing for the first time opens the next level and grants global XP once.
 */
@Composable
fun PathQuizScreen(
    level: PathLevel,
    isLastLevel: Boolean,
    language: AppLanguage,
    progressManager: ProgressManager,
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    fun text(key: String, vararg args: Any): String = StringStore.text(context, key, language, *args)

    // The level's quizzes, read once in a single pass over the catalogue.
    var quizzes by remember(level.id) { mutableStateOf<List<Pair<CourseSummary, List<QuizQuestion>>>?>(null) }
    LaunchedEffect(level.id, language) {
        val byCourse = ContentCatalog.quizQuestionsForCoursesAsync(
            context.applicationContext,
            language,
            level.courses.map { it.id },
        )
        quizzes = level.courses.map { it to byCourse[it.id].orEmpty() }
    }
    val plannedCount = quizzes?.let { all -> PathQuizBuilder.plannedCount(all.sumOf { it.second.size }) }
        ?: LearningPathRules.QUIZ_QUESTION_COUNT

    var phase by remember { mutableStateOf(PathQuizPhase.Intro) }
    var attempt by remember { mutableIntStateOf(0) }
    var entries by remember { mutableStateOf<List<PathQuizEntry>>(emptyList()) }
    var index by remember { mutableIntStateOf(0) }
    var correctCount by remember { mutableIntStateOf(0) }
    var answeredCurrent by remember { mutableStateOf(false) }
    var counterBump by remember { mutableStateOf(false) }
    var didPass by remember { mutableStateOf(false) }
    var newlyPassed by remember { mutableStateOf(false) }
    var awardedXp by remember { mutableIntStateOf(0) }
    var showLeaveConfirm by remember { mutableStateOf(false) }
    var showRankUp by remember { mutableStateOf(false) }
    val total = entries.size

    // Called from primary buttons only, which already vibrate on the press.
    fun startQuiz() {
        val drawn = PathQuizBuilder.questions(quizzes.orEmpty())
        if (drawn.isEmpty()) {
            onDismiss()
            return
        }
        entries = drawn.map { PathQuizEntry(it.course, QuizShuffler.shuffle(it.question)) }
        Analytics.log("quiz_start", props = mapOf("context" to "path", "level" to level.collection.id, "total" to entries.size))
        index = 0
        correctCount = 0
        answeredCurrent = false
        didPass = false
        newlyPassed = false
        awardedXp = 0
        attempt += 1
        phase = PathQuizPhase.Questions
    }

    fun finishQuiz() {
        val passed = LearningPathRules.isPassing(correctCount, total)
        Analytics.log(
            "quiz_complete",
            props = mapOf("context" to "path", "level" to level.collection.id, "correct" to correctCount, "total" to total, "passed" to passed),
        )
        didPass = passed
        newlyPassed = progressManager.recordPathQuizAttempt(level.collection.id, correctCount, total, passed)
        awardedXp = if (newlyPassed) progressManager.awardPathLevelPassedXpIfNeeded(level.collection.id) else 0
        phase = PathQuizPhase.Result
    }

    fun finishAfterPass() {
        if (progressManager.progress.value.pendingGlobalRankUp != null) {
            showRankUp = true
        } else {
            onDismiss()
        }
    }

    BackHandler {
        when {
            showRankUp -> Unit
            phase == PathQuizPhase.Questions -> showLeaveConfirm = true
            phase == PathQuizPhase.Result && didPass -> finishAfterPass()
            else -> onDismiss()
        }
    }

    Box(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
        Crossfade(targetState = phase, animationSpec = tween(300), label = "pathQuizPhase") { shown ->
            when (shown) {
                PathQuizPhase.Intro -> PathQuizIntro(
                    level = level,
                    language = language,
                    plannedCount = plannedCount,
                    best = progressManager.pathLevelResult(level.collection.id),
                    ready = quizzes != null,
                    onStart = { startQuiz() },
                    onClose = onDismiss,
                )
                PathQuizPhase.Questions -> Column(modifier = Modifier.fillMaxSize()) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 24.dp)
                            .padding(top = 10.dp, bottom = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        CircleIconButton(
                            icon = Icons.Filled.Close,
                            onClick = { showLeaveConfirm = true },
                            size = 44.dp,
                            tint = DS.ink,
                        )
                        DSSegmentedProgress(
                            total = total,
                            filled = index + if (answeredCurrent) 1 else 0,
                            modifier = Modifier.weight(1f),
                            height = 6.dp,
                            spacing = 3.dp,
                        )
                        Text(
                            text = "${index + 1}/$total",
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 12.sp,
                            color = DS.inkSecondary,
                            maxLines = 1,
                        )
                        CorrectPill(
                            count = correctCount,
                            bump = counterBump,
                            label = text("path.quiz.correctSoFar", correctCount),
                        )
                    }
                    AnimatedContent(
                        targetState = index,
                        modifier = Modifier.weight(1f),
                        transitionSpec = {
                            (slideInHorizontally(DSMotion.reveal()) { it } + fadeIn()) togetherWith
                                (slideOutHorizontally(DSMotion.reveal()) { -it } + fadeOut())
                        },
                        label = "pathQuizQuestion",
                    ) { shownIndex ->
                        val entry = entries.getOrNull(shownIndex) ?: return@AnimatedContent
                        key(attempt, entry.question.id) {
                            PathQuestionPane(
                                entry = entry,
                                language = language,
                                isLast = shownIndex == total - 1,
                                onAnswered = { fullyCorrect ->
                                    answeredCurrent = true
                                    if (fullyCorrect) {
                                        correctCount += 1
                                        counterBump = !counterBump
                                    }
                                },
                                // The panel's primary button vibrates on the press.
                                onContinue = {
                                    if (index < total - 1) {
                                        index += 1
                                        answeredCurrent = false
                                    } else {
                                        finishQuiz()
                                    }
                                },
                            )
                        }
                    }
                }
                PathQuizPhase.Result -> key(attempt) {
                    PathQuizResult(
                        level = level,
                        language = language,
                        correct = correctCount,
                        total = total,
                        didPass = didPass,
                        newlyPassed = newlyPassed,
                        isLastLevel = isLastLevel,
                        awardedXp = awardedXp,
                        // The buttons vibrate on the press: no vibration is added here.
                        onContinue = { finishAfterPass() },
                        onRetry = { startQuiz() },
                        onReview = onDismiss,
                    )
                }
            }
        }

        if (showRankUp) {
            val pending = progressManager.progress.value.pendingGlobalRankUp
            if (pending == null) {
                LaunchedEffect(Unit) { onDismiss() }
            } else {
                RankUpCelebration(
                    rankKey = pending.newRankRawValue,
                    level = pending.newLevel,
                    language = language,
                    onContinue = {
                        progressManager.clearPendingRankUp()
                        showRankUp = false
                        onDismiss()
                    },
                )
            }
        }

        if (showLeaveConfirm) {
            ConfirmDialog(
                title = text("path.quiz.leave.title"),
                message = text("path.quiz.leave.body"),
                confirm = text("path.quiz.leave.confirm"),
                cancel = text("path.quiz.leave.cancel"),
                onConfirm = {
                    showLeaveConfirm = false
                    onDismiss()
                },
                onDismiss = { showLeaveConfirm = false },
            )
        }
    }
}

// MARK: - Intro

@Composable
private fun PathQuizIntro(
    level: PathLevel,
    language: AppLanguage,
    plannedCount: Int,
    best: PathLevelResult?,
    ready: Boolean,
    onStart: () -> Unit,
    onClose: () -> Unit,
) {
    val context = LocalContext.current
    fun text(key: String, vararg args: Any): String = StringStore.text(context, key, language, *args)

    Column(modifier = Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
        Box(modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp).padding(top = 10.dp)) {
            CircleIconButton(icon = Icons.Filled.Close, onClick = onClose, size = 44.dp, tint = DS.ink)
        }
        Column(
            modifier = Modifier
                .weight(1f)
                .readableWidth()
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp, vertical = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp, Alignment.CenterVertically),
        ) {
            Box(
                modifier = Modifier.dsPopIn(delayMillis = 50).size(132.dp).clearAndSetSemantics { },
                contentAlignment = Alignment.Center,
            ) {
                Box(Modifier.size(132.dp).clip(CircleShape).background(PathCardPalette.goldTint))
                Box(
                    modifier = Modifier.size(100.dp).clip(CircleShape).background(PathPalette.gold),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(Icons.Filled.EmojiEvents, contentDescription = null, tint = Color.White, modifier = Modifier.size(46.dp))
                }
            }
            Column(
                modifier = Modifier.padding(top = 4.dp).dsStagger(0),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Text(
                    text = text("path.quiz.title", level.number),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 28.sp,
                    lineHeight = 34.sp,
                    color = DS.ink,
                    textAlign = TextAlign.Center,
                )
                Text(
                    text = level.collection.title,
                    fontFamily = PlusJakartaSans,
                    fontSize = 15.sp,
                    lineHeight = 22.sp,
                    color = DS.inkSecondary,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(horizontal = 16.dp),
                )
            }
            Column(
                modifier = Modifier
                    .dsStagger(1)
                    .fillMaxWidth()
                    .sophiaCard()
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                RuleRow(Icons.Filled.Shuffle, text("path.quiz.rule.questions", plannedCount, level.courseCount))
                RuleRow(Icons.Filled.TrackChanges, text("path.quiz.rule.pass", LearningPathRules.passMark(plannedCount)))
                RuleRow(Icons.Filled.Replay, text("path.quiz.rule.retries"))
            }
            if (best != null && best.attempts > 0) {
                Row(
                    modifier = Modifier
                        .dsStagger(2)
                        .clip(RoundedCornerShape(14.dp))
                        .background(if (best.isPassed) DS.successTint else DS.accentTint)
                        .padding(horizontal = 14.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    Icon(
                        if (best.isPassed) Icons.Filled.Verified else Icons.Filled.BarChart,
                        contentDescription = null,
                        tint = if (best.isPassed) DS.success else DS.accent,
                        modifier = Modifier.size(14.dp),
                    )
                    Text(
                        text = text("path.quiz.bestScore", best.bestCorrect, best.bestTotal),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 13.sp,
                        color = if (best.isPassed) DS.success else DS.ink,
                    )
                }
            }
        }
        // Both buttons vibrate on the press: no vibration is added here.
        Column(
            modifier = Modifier
                .readableWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 24.dp)
                .dsStagger(3),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            SophiaPrimaryButton(text = text("path.quiz.go"), onClick = onStart, enabled = ready)
            SophiaSecondaryButton(text = text("path.quiz.later"), onClick = onClose)
        }
    }
}

@Composable
private fun RuleRow(icon: ImageVector, label: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Box(
            modifier = Modifier.size(30.dp).clip(CircleShape).background(DS.accentTint),
            contentAlignment = Alignment.Center,
        ) {
            Icon(icon, contentDescription = null, tint = DS.accent, modifier = Modifier.size(15.dp))
        }
        Text(
            text = label,
            fontFamily = PlusJakartaSans,
            fontSize = 15.sp,
            lineHeight = 21.sp,
            color = DS.ink,
            modifier = Modifier.weight(1f).padding(top = 4.dp),
        )
    }
}

/** Fades in and rises by [distance] dp as [progress] goes from 0 to 1. */
private fun Modifier.slideUp(progress: Float, distance: Float): Modifier = graphicsLayer {
    alpha = progress.coerceIn(0f, 1f)
    translationY = (1f - progress) * distance * density
}

@Composable
private fun CorrectPill(count: Int, bump: Boolean, label: String) {
    // Flips on every right answer: the pill swells for a beat, then settles.
    val scale = remember { Animatable(1f) }
    var first by remember { mutableStateOf(true) }
    LaunchedEffect(bump) {
        if (first) {
            first = false
            return@LaunchedEffect
        }
        scale.animateTo(1.18f, spring(dampingRatio = 0.5f, stiffness = 900f))
        scale.animateTo(1f, DSMotion.pop())
    }
    Row(
        modifier = Modifier
            .graphicsLayer {
                scaleX = scale.value
                scaleY = scale.value
            }
            .clip(RoundedCornerShape(12.dp))
            .background(DS.successTint)
            .padding(horizontal = 10.dp, vertical = 4.dp)
            .clearAndSetSemantics { contentDescription = label },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Icon(Icons.Filled.Check, contentDescription = null, tint = DS.success, modifier = Modifier.size(12.dp))
        Text(
            text = "$count",
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 13.sp,
            color = DS.success,
        )
    }
}

// MARK: - Result

@Composable
private fun PathQuizResult(
    level: PathLevel,
    language: AppLanguage,
    correct: Int,
    total: Int,
    didPass: Boolean,
    newlyPassed: Boolean,
    isLastLevel: Boolean,
    awardedXp: Int,
    onContinue: () -> Unit,
    onRetry: () -> Unit,
    onReview: () -> Unit,
) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val scope = rememberCoroutineScope()
    fun text(key: String, vararg args: Any): String = StringStore.text(context, key, language, *args)
    val passMark = LearningPathRules.passMark(total)

    val appeared = remember { Animatable(0f) }
    val ring = remember { Animatable(0f) }
    val badge = remember { Animatable(0.6f) }
    val failShake = remember { Animatable(0f) }
    // The score counts up with the ring: `DSCountUp` runs (and ticks) when its value changes.
    var displayedCorrect by remember { mutableIntStateOf(0) }
    var showConfetti by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        launch { appeared.animateTo(1f, spring(dampingRatio = 0.75f, stiffness = 110f)) }
        launch { badge.animateTo(1f, spring(dampingRatio = 0.75f, stiffness = 110f)) }
        launch {
            delay(300)
            ring.animateTo(correct.toFloat() / maxOf(total, 1), tween(1000, easing = LinearOutSlowInEasing))
        }
        launch {
            delay(300)
            displayedCorrect = correct
        }
        delay(1250)
        if (didPass) {
            haptics.celebrate()
            showConfetti = true
            badge.animateTo(1.12f, DSMotion.pop())
            delay(100)
            badge.animateTo(1f, spring(dampingRatio = 0.7f, stiffness = 250f))
            scope.launch {
                delay(3400)
                showConfetti = false
            }
        } else {
            haptics.error()
            failShake.animateTo(1f, tween(450, easing = LinearEasing))
        }
    }

    val subtitle = when {
        didPass && !newlyPassed -> text("path.quiz.passed.again")
        didPass && isLastLevel -> text("path.quiz.passed.last")
        didPass -> text("path.quiz.passed.next")
        else -> text("path.quiz.failed.body", passMark, total)
    }
    val scoreStyle = TextStyle(fontFamily = PlusJakartaSans, fontWeight = FontWeight.ExtraBold, fontSize = 44.sp)

    Box(modifier = Modifier.fillMaxSize()) {
        Column(modifier = Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
            Column(
                modifier = Modifier
                    .weight(1f)
                    .readableWidth()
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(vertical = 20.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterVertically),
            ) {
                ScoreBadge(
                    didPass = didPass,
                    ring = ring.value,
                    passFraction = passMark.toFloat() / maxOf(total, 1),
                    badgeScale = badge.value,
                    shake = failShake.value,
                    modifier = Modifier.alpha(appeared.value.coerceIn(0f, 1f)),
                )
                Column(
                    modifier = Modifier.slideUp(appeared.value, 14f),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Text(
                        text = if (didPass) text("path.quiz.passed.title", level.number) else text("path.quiz.failed.title"),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 24.sp,
                        lineHeight = 30.sp,
                        color = DS.ink,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 24.dp).padding(top = 8.dp),
                    )
                    // « 14 / 20 »: the first number counts up (and ticks) once the screen is in.
                    Row(
                        modifier = Modifier.clearAndSetSemantics { contentDescription = "$correct / $total" },
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        DSCountUp(
                            value = displayedCorrect,
                            modifier = Modifier.alignByBaseline(),
                            durationMillis = 800,
                            style = scoreStyle,
                            color = DS.ink,
                        )
                        Text(
                            text = "/ $total",
                            style = scoreStyle,
                            color = DS.ink,
                            modifier = Modifier.alignByBaseline(),
                        )
                    }
                    Text(
                        text = subtitle,
                        fontFamily = PlusJakartaSans,
                        fontSize = 15.sp,
                        lineHeight = 22.sp,
                        color = DS.inkSecondary,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 28.dp),
                    )
                    if (didPass && awardedXp > 0) {
                        Row(
                            modifier = Modifier
                                .dsPopIn(delayMillis = 1300)
                                .clip(RoundedCornerShape(14.dp))
                                .background(PathCardPalette.goldTint)
                                .padding(horizontal = 14.dp, vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp),
                        ) {
                            Icon(
                                Icons.Filled.Star,
                                contentDescription = null,
                                tint = PathCardPalette.goldInk,
                                modifier = Modifier.size(14.dp),
                            )
                            Text(
                                text = text("cards.globalXP", awardedXp),
                                fontFamily = PlusJakartaSans,
                                fontWeight = FontWeight.ExtraBold,
                                fontSize = 15.sp,
                                color = PathCardPalette.goldInk,
                            )
                        }
                    }
                }
            }
            Column(
                modifier = Modifier
                    .readableWidth()
                    .padding(horizontal = 24.dp)
                    .padding(bottom = 24.dp)
                    .slideUp(appeared.value, 12f),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                if (didPass) {
                    SophiaPrimaryButton(text = text("common.continue"), onClick = onContinue)
                } else {
                    SophiaPrimaryButton(
                        text = text("path.quiz.retry"),
                        onClick = onRetry,
                        leadingIcon = Icons.Filled.Replay,
                    )
                    SophiaSecondaryButton(text = text("path.quiz.review"), onClick = onReview)
                }
            }
        }
        if (showConfetti) {
            val colors = remember(level.id) {
                buildList {
                    add(PathPalette.gold)
                    add(lerp(PathPalette.gold, Color.White, 0.3f))
                    add(DS.accentSoft)
                    level.courses.map { it.subjectEnum }.distinct().forEach { add(PathPalette.tint(it)) }
                }
            }
            ConfettiBurst(
                colors = colors,
                modifier = Modifier.fillMaxSize(),
                pieceCount = 130,
                durationMillis = 3200,
                origin = Offset(0.5f, 0.3f),
            )
        }
    }
}

/**
 * The ring fills to the score, with a dot at the pass mark so it reads as "this far to go".
 * A golden trophy pops in its middle once the level is passed.
 */
@Composable
private fun ScoreBadge(
    didPass: Boolean,
    ring: Float,
    passFraction: Float,
    badgeScale: Float,
    shake: Float,
    modifier: Modifier = Modifier,
) {
    val hairline = DS.hairline
    val markColor = DS.inkTertiary
    val ringColor = if (didPass) PathPalette.gold else DS.accent
    Box(
        modifier = modifier
            .size(150.dp)
            .graphicsLayer { translationX = shakeOffset(shake, 9.dp.toPx()) }
            .clearAndSetSemantics { },
        contentAlignment = Alignment.Center,
    ) {
        Canvas(modifier = Modifier.size(140.dp)) {
            val stroke = 10.dp.toPx()
            val radius = size.minDimension / 2f
            drawCircle(hairline, radius = radius, style = Stroke(stroke))
            drawArc(
                color = ringColor,
                startAngle = -90f,
                sweepAngle = 360f * ring.coerceIn(0f, 1f),
                useCenter = false,
                topLeft = Offset(center.x - radius, center.y - radius),
                size = Size(radius * 2, radius * 2),
                style = Stroke(stroke, cap = StrokeCap.Round),
            )
            val angle = Math.toRadians(360.0 * passFraction)
            drawCircle(
                markColor,
                radius = 4.dp.toPx(),
                center = Offset(
                    center.x + (sin(angle) * radius).toFloat(),
                    center.y - (cos(angle) * radius).toFloat(),
                ),
            )
        }
        Icon(
            if (didPass) Icons.Filled.EmojiEvents else Icons.Filled.Replay,
            contentDescription = null,
            tint = if (didPass) PathPalette.gold else DS.inkSecondary,
            modifier = Modifier
                .size(if (didPass) 64.dp else 52.dp)
                .graphicsLayer {
                    scaleX = badgeScale
                    scaleY = badgeScale
                },
        )
    }
}
