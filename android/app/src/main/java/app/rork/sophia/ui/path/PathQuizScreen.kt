package app.rork.sophia.ui.path

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.Crossfade
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Canvas
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
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Contrast
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
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.LearningPathRules
import app.rork.sophia.domain.PathLevel
import app.rork.sophia.domain.PathQuizBuilder
import app.rork.sophia.domain.QuizAnswer
import app.rork.sophia.domain.QuizQuestion
import app.rork.sophia.domain.QuizQuestionType
import app.rork.sophia.domain.QuizScoring
import app.rork.sophia.domain.QuizShuffler
import app.rork.sophia.domain.ShuffledQuestion
import app.rork.sophia.ui.components.AnswerOptionRow
import app.rork.sophia.ui.components.AnswerState
import app.rork.sophia.ui.components.CalmProgressBar
import app.rork.sophia.ui.components.CircleIconButton
import app.rork.sophia.ui.components.ConfirmDialog
import app.rork.sophia.ui.components.OrderingAnswerControl
import app.rork.sophia.ui.components.RankUpCelebration
import app.rork.sophia.ui.components.SliderAnswerCard
import app.rork.sophia.ui.components.SophiaPrimaryButton
import app.rork.sophia.ui.components.SophiaSecondaryButton
import app.rork.sophia.ui.components.optionLetter
import app.rork.sophia.ui.components.softPress
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

private data class PathQuizEntry(val course: CourseSummary, val question: ShuffledQuestion)

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
    val view = LocalView.current
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

    fun startQuiz() {
        view.pathHaptic(PathHaptic.Tap)
        val drawn = PathQuizBuilder.questions(quizzes.orEmpty())
        if (drawn.isEmpty()) {
            onDismiss()
            return
        }
        entries = drawn.map { PathQuizEntry(it.course, QuizShuffler.shuffle(it.question)) }
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
                            .padding(horizontal = 20.dp)
                            .padding(top = 10.dp, bottom = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        CircleIconButton(icon = Icons.Filled.Close, onClick = { showLeaveConfirm = true })
                        val fraction by animateFloatAsState(
                            targetValue = (index + if (answeredCurrent) 1 else 0).toFloat() / maxOf(total, 1),
                            animationSpec = spring(dampingRatio = 0.85f, stiffness = 250f),
                            label = "pathQuizProgress",
                        )
                        CalmProgressBar(fraction = fraction, modifier = Modifier.weight(1f))
                        Text(
                            text = "${index + 1}/$total",
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Medium,
                            fontSize = 12.sp,
                            color = DS.inkSecondary,
                            maxLines = 1,
                        )
                        CorrectPill(count = correctCount, bump = counterBump)
                    }
                    AnimatedContent(
                        targetState = index,
                        modifier = Modifier.weight(1f),
                        transitionSpec = {
                            (slideInHorizontally { it } + fadeIn()) togetherWith (slideOutHorizontally { -it } + fadeOut())
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
                                onContinue = {
                                    view.pathHaptic(PathHaptic.Tap)
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
                        onContinue = {
                            view.pathHaptic(PathHaptic.Tap)
                            finishAfterPass()
                        },
                        onRetry = { startQuiz() },
                        onReview = {
                            view.pathHaptic(PathHaptic.Tap)
                            onDismiss()
                        },
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
    best: app.rork.sophia.domain.PathLevelResult?,
    ready: Boolean,
    onStart: () -> Unit,
    onClose: () -> Unit,
) {
    val context = LocalContext.current
    fun text(key: String, vararg args: Any): String = StringStore.text(context, key, language, *args)
    val appeared = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        delay(50)
        appeared.animateTo(1f, spring(dampingRatio = 0.85f, stiffness = 160f))
    }

    Column(modifier = Modifier.fillMaxSize()) {
        Box(modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(top = 10.dp)) {
            CircleIconButton(icon = Icons.Filled.Close, onClick = onClose)
        }
        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .readableWidth()
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(22.dp),
        ) {
            Spacer(Modifier.height(12.dp))
            Box(
                modifier = Modifier.size(148.dp).graphicsLayer {
                    val scale = 0.7f + 0.3f * appeared.value
                    scaleX = scale
                    scaleY = scale
                    alpha = appeared.value.coerceIn(0f, 1f)
                },
                contentAlignment = Alignment.Center,
            ) {
                Box(Modifier.size(148.dp).clip(CircleShape).background(PathPalette.gold.copy(alpha = 0.16f)))
                Box(
                    modifier = Modifier.size(112.dp).clip(CircleShape).background(PathPalette.goldGradient),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(Icons.Filled.EmojiEvents, contentDescription = null, tint = Color.White, modifier = Modifier.size(54.dp))
                }
            }
            Column(
                modifier = Modifier.slideUp(appeared.value, 12f),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Text(
                    text = text("path.quiz.title", level.number),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 28.sp,
                    lineHeight = 33.sp,
                    color = DS.ink,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(horizontal = 20.dp),
                )
                Text(
                    text = level.collection.title,
                    fontFamily = PlusJakartaSans,
                    fontSize = 15.sp,
                    lineHeight = 21.sp,
                    color = DS.inkSecondary,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(horizontal = 28.dp),
                )
            }
            Column(
                modifier = Modifier
                    .padding(horizontal = 20.dp)
                    .slideUp(appeared.value, 16f)
                    .fillMaxWidth()
                    .sophiaCard()
                    .padding(DS.Space.l),
                verticalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                RuleRow(Icons.Filled.Shuffle, text("path.quiz.rule.questions", plannedCount, level.courseCount))
                RuleRow(Icons.Filled.TrackChanges, text("path.quiz.rule.pass", LearningPathRules.passMark(plannedCount)))
                RuleRow(Icons.Filled.Replay, text("path.quiz.rule.retries"))
            }
            if (best != null && best.attempts > 0) {
                Row(
                    modifier = Modifier
                        .alpha(appeared.value.coerceIn(0f, 1f))
                        .clip(CircleShape)
                        .background(if (best.isPassed) DS.successTint else DS.accentTint)
                        .padding(horizontal = 14.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    val tint = if (best.isPassed) DS.success else DS.accentSoft
                    Icon(
                        if (best.isPassed) Icons.Filled.Verified else Icons.Filled.BarChart,
                        contentDescription = null,
                        tint = tint,
                        modifier = Modifier.size(14.dp),
                    )
                    Text(
                        text = text("path.quiz.bestScore", best.bestCorrect, best.bestTotal),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 12.sp,
                        color = tint,
                    )
                }
            }
            Spacer(Modifier.height(20.dp))
        }
        Column(
            modifier = Modifier
                .readableWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 24.dp)
                .slideUp(appeared.value, 12f),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            SophiaPrimaryButton(text = text("path.quiz.go"), onClick = onStart, enabled = ready)
            SophiaSecondaryButton(text = text("path.quiz.later"), onClick = onClose)
        }
    }
}

@Composable
private fun RuleRow(icon: androidx.compose.ui.graphics.vector.ImageVector, label: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Box(
            modifier = Modifier.size(32.dp).clip(CircleShape).background(DS.accentTint),
            contentAlignment = Alignment.Center,
        ) {
            Icon(icon, contentDescription = null, tint = DS.accentSoft, modifier = Modifier.size(16.dp))
        }
        Text(
            text = label,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Medium,
            fontSize = 15.sp,
            lineHeight = 21.sp,
            color = DS.ink,
            modifier = Modifier.weight(1f).padding(top = 5.dp),
        )
    }
}

/** Fades in and rises by [distance] dp as [progress] goes from 0 to 1. */
private fun Modifier.slideUp(progress: Float, distance: Float): Modifier = graphicsLayer {
    alpha = progress.coerceIn(0f, 1f)
    translationY = (1f - progress) * distance * density
}

@Composable
private fun CorrectPill(count: Int, bump: Boolean) {
    // Flips on every right answer: the pill swells for a beat, then settles.
    val scale = remember { Animatable(1f) }
    var first by remember { mutableStateOf(true) }
    LaunchedEffect(bump) {
        if (first) {
            first = false
            return@LaunchedEffect
        }
        scale.animateTo(1.18f, spring(dampingRatio = 0.5f, stiffness = 900f))
        scale.animateTo(1f, spring(dampingRatio = 0.5f, stiffness = 600f))
    }
    Row(
        modifier = Modifier
            .graphicsLayer {
                scaleX = scale.value
                scaleY = scale.value
            }
            .clip(CircleShape)
            .background(DS.successTint)
            .padding(horizontal = 9.dp, vertical = 5.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Icon(Icons.Filled.Check, contentDescription = null, tint = DS.success, modifier = Modifier.size(12.dp))
        Text(
            text = "$count",
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 12.sp,
            color = DS.success,
        )
    }
}

// MARK: - Question

/**
 * One question with its answer controls and the feedback bar, the same interaction as the
 * course quiz. Scoring is left to [QuizScoring]; the pane only reports whether the answer
 * was fully correct, which is all the level quiz counts.
 */
@Composable
private fun PathQuestionPane(
    entry: PathQuizEntry,
    language: AppLanguage,
    isLast: Boolean,
    onAnswered: (fullyCorrect: Boolean) -> Unit,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val view = LocalView.current
    fun text(key: String): String = StringStore.text(context, key, language)
    val question = entry.question

    var selected by remember { mutableStateOf<Int?>(null) }
    var sliderValue by remember { mutableDoubleStateOf(question.snapToStep((question.sliderMin + question.sliderMax) / 2.0)) }
    val chronoSlots = remember { mutableStateListOf<Int?>().apply { addAll(List(question.items.size) { null }) } }
    val chronoPool = remember { mutableStateListOf<Int>().apply { addAll(question.items.indices) } }
    var hasAnswered by remember { mutableStateOf(false) }
    var earned by remember { mutableIntStateOf(0) }
    val fullyCorrect = hasAnswered && earned == question.maxPoints

    fun submit(answer: QuizAnswer) {
        if (hasAnswered) return
        earned = QuizScoring.points(question, answer)
        hasAnswered = true
        val correct = earned == question.maxPoints
        view.pathHaptic(if (correct) PathHaptic.Confirm else PathHaptic.Reject)
        onAnswered(correct)
    }

    Column(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp)
                .padding(top = 16.dp, bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            Column(
                modifier = Modifier.fillMaxWidth().sophiaCard().padding(DS.Space.l),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Icon(
                        entry.course.subjectEnum.pathIcon,
                        contentDescription = null,
                        tint = DS.accentSoft,
                        modifier = Modifier.size(13.dp),
                    )
                    Text(
                        text = entry.course.title,
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 12.sp,
                        lineHeight = 16.sp,
                        color = DS.accentSoft,
                        maxLines = 2,
                    )
                }
                Text(
                    text = question.question,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 20.sp,
                    lineHeight = 26.sp,
                    color = DS.ink,
                )
            }

            when (question.type) {
                QuizQuestionType.MCQ -> Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    question.options.forEachIndexed { i, option ->
                        AnswerOptionRow(
                            letter = optionLetter(i),
                            text = option,
                            state = when {
                                hasAnswered && i == question.correctIndex -> AnswerState.Correct
                                hasAnswered && selected == i -> AnswerState.Wrong
                                hasAnswered -> AnswerState.Dimmed
                                else -> AnswerState.Idle
                            },
                            enabled = !hasAnswered,
                            onClick = {
                                selected = i
                                submit(QuizAnswer.SingleChoice(i))
                            },
                        )
                    }
                }
                QuizQuestionType.TRUE_FALSE -> Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    question.options.forEachIndexed { i, option ->
                        TrueFalseButton(
                            index = i,
                            text = option,
                            answered = hasAnswered,
                            isCorrect = i == question.correctIndex,
                            isSelected = selected == i,
                            modifier = Modifier.weight(1f),
                            onClick = {
                                selected = i
                                submit(QuizAnswer.SingleChoice(i))
                            },
                        )
                    }
                }
                QuizQuestionType.CHRONOLOGICAL -> Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    OrderingAnswerControl(
                        question = question,
                        language = language,
                        slots = chronoSlots,
                        pool = chronoPool,
                        answered = hasAnswered,
                    )
                    if (hasAnswered) {
                        Text(
                            text = "${text("quiz.chronological.correctOrder")} : ${correctOrder(question)}",
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Medium,
                            fontSize = 12.sp,
                            lineHeight = 17.sp,
                            color = DS.inkSecondary,
                        )
                    } else if (chronoSlots.none { it == null }) {
                        SophiaPrimaryButton(
                            text = text("quiz.chronological.validate"),
                            onClick = { submit(QuizAnswer.Order(chronoSlots.filterNotNull())) },
                        )
                    }
                }
                QuizQuestionType.NUMERIC_SLIDER, QuizQuestionType.PERCENTAGE_SLIDER ->
                    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        SliderAnswerCard(
                            question = question,
                            language = language,
                            value = sliderValue,
                            onValueChange = { sliderValue = it },
                            answered = hasAnswered,
                        )
                        if (!hasAnswered) {
                            SophiaPrimaryButton(
                                text = text("quiz.slider.validate"),
                                onClick = { submit(QuizAnswer.Value(sliderValue)) },
                            )
                        }
                    }
            }
        }

        if (hasAnswered) {
            Box(Modifier.fillMaxWidth().height(1.dp).background(DS.hairline))
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(DS.surface)
                    .padding(horizontal = 20.dp)
                    .padding(top = 18.dp, bottom = 16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                val (icon, color) = when {
                    fullyCorrect -> Icons.Filled.CheckCircle to DS.success
                    earned > 0 -> Icons.Filled.Contrast to DS.accentSoft
                    else -> Icons.Filled.Cancel to DS.danger
                }
                Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(30.dp))
                    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(
                            text = feedbackTitle(question, earned, fullyCorrect, ::text),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 17.sp,
                            color = DS.ink,
                        )
                        if (question.maxPoints > 2) {
                            Text(
                                text = "+$earned/${question.maxPoints} ${text("quiz.pointsEarned")}",
                                fontFamily = PlusJakartaSans,
                                fontWeight = FontWeight.Medium,
                                fontSize = 12.sp,
                                color = DS.inkTertiary,
                            )
                        }
                        if (question.explanation.isNotBlank()) {
                            Text(
                                text = question.explanation,
                                fontFamily = PlusJakartaSans,
                                fontSize = 15.sp,
                                lineHeight = 21.sp,
                                color = DS.inkSecondary,
                                modifier = Modifier
                                    .padding(top = 2.dp)
                                    .heightIn(max = 220.dp)
                                    .verticalScroll(rememberScrollState()),
                            )
                        }
                    }
                }
                SophiaPrimaryButton(
                    text = if (isLast) text("path.quiz.seeResult") else text("common.continue"),
                    onClick = onContinue,
                )
            }
        }
    }
}

private fun feedbackTitle(
    question: ShuffledQuestion,
    earned: Int,
    fullyCorrect: Boolean,
    text: (String) -> String,
): String = when (question.type) {
    QuizQuestionType.MCQ, QuizQuestionType.TRUE_FALSE ->
        text(if (fullyCorrect) "quiz.feedback.correct" else "quiz.feedback.wrong")
    else -> when (earned) {
        3 -> text("quiz.feedback.correct")
        2 -> text("quiz.feedback.close")
        1 -> text("quiz.feedback.far")
        else -> text("quiz.feedback.wrong")
    }
}

/** The items in their right order: `originalIndices[slot]` is where the item belongs. */
private fun correctOrder(question: ShuffledQuestion): String =
    question.items.indices
        .sortedBy { question.originalIndices.getOrElse(it) { it } }
        .joinToString(" → ") { question.items[it] }

@Composable
private fun TrueFalseButton(
    index: Int,
    text: String,
    answered: Boolean,
    isCorrect: Boolean,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val highlighted = answered && (isCorrect || isSelected)
    val background by animateColorAsState(
        when {
            answered && isCorrect -> DS.successTint
            answered && isSelected -> DS.dangerTint
            else -> DS.surface
        },
        tween(220),
        label = "tfBg",
    )
    val border = when {
        answered && isCorrect -> DS.success
        answered && isSelected -> DS.danger
        else -> DS.hairline
    }
    val content = when {
        answered && isCorrect -> DS.success
        answered && isSelected -> DS.danger
        else -> DS.ink
    }
    Column(
        modifier = modifier
            .alpha(if (answered && !highlighted) 0.55f else 1f)
            .softPress(onClick = onClick, enabled = !answered)
            .clip(DS.controlShape)
            .background(background)
            .border(if (highlighted) 1.5.dp else 1.dp, border, DS.controlShape)
            .padding(horizontal = 8.dp, vertical = 22.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Icon(
            if (index == 0) Icons.Filled.CheckCircle else Icons.Filled.Cancel,
            contentDescription = null,
            tint = if (answered && (isCorrect || isSelected)) content else DS.accentSoft,
            modifier = Modifier.size(28.dp),
        )
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 17.sp,
            color = content,
            textAlign = TextAlign.Center,
            maxLines = 2,
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
    val view = LocalView.current
    val scope = rememberCoroutineScope()
    fun text(key: String, vararg args: Any): String = StringStore.text(context, key, language, *args)
    val passMark = LearningPathRules.passMark(total)

    val appeared = remember { Animatable(0f) }
    val ring = remember { Animatable(0f) }
    val badge = remember { Animatable(0.6f) }
    val failShake = remember { Animatable(0f) }
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
            val steps = maxOf(correct, 1)
            for (step in 1..steps) {
                delay((800L / steps).coerceAtLeast(1L))
                if (step > correct) break
                displayedCorrect = step
                view.pathHaptic(PathHaptic.Tick)
            }
        }
        delay(1250)
        if (didPass) {
            view.pathHaptic(PathHaptic.Confirm)
            showConfetti = true
            badge.animateTo(1.12f, spring(dampingRatio = 0.5f, stiffness = 200f))
            delay(100)
            view.pathHaptic(PathHaptic.Heavy)
            badge.animateTo(1f, spring(dampingRatio = 0.7f, stiffness = 250f))
            scope.launch {
                delay(3400)
                showConfetti = false
            }
        } else {
            view.pathHaptic(PathHaptic.Reject)
            failShake.animateTo(1f, tween(450, easing = LinearEasing))
        }
    }

    val subtitle = when {
        didPass && !newlyPassed -> text("path.quiz.passed.again")
        didPass && isLastLevel -> text("path.quiz.passed.last")
        didPass -> text("path.quiz.passed.next")
        else -> text("path.quiz.failed.body", passMark, total)
    }

    Box(modifier = Modifier.fillMaxSize()) {
        Column(modifier = Modifier.fillMaxSize()) {
            Column(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .readableWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(vertical = 20.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(22.dp, Alignment.CenterVertically),
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
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Text(
                        text = if (didPass) text("path.quiz.passed.title", level.number) else text("path.quiz.failed.title"),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 28.sp,
                        lineHeight = 33.sp,
                        color = DS.ink,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 24.dp),
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(
                            text = "$displayedCorrect",
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 48.sp,
                            color = DS.ink,
                            modifier = Modifier.alignByBaseline(),
                        )
                        Text(
                            text = "/ $total",
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Medium,
                            fontSize = 22.sp,
                            color = DS.inkTertiary,
                            modifier = Modifier.alignByBaseline(),
                        )
                    }
                    Text(
                        text = subtitle,
                        fontFamily = PlusJakartaSans,
                        fontSize = 15.sp,
                        lineHeight = 21.sp,
                        color = DS.inkSecondary,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 28.dp),
                    )
                    if (didPass && awardedXp > 0) {
                        Row(
                            modifier = Modifier
                                .padding(top = 4.dp)
                                .clip(CircleShape)
                                .background(DS.accentTint)
                                .padding(horizontal = 16.dp, vertical = 9.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            Icon(Icons.Filled.Star, contentDescription = null, tint = DS.accentSoft, modifier = Modifier.size(14.dp))
                            Text(
                                text = text("cards.globalXP", awardedXp),
                                fontFamily = PlusJakartaSans,
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 15.sp,
                                color = DS.accentSoft,
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
                verticalArrangement = Arrangement.spacedBy(12.dp),
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

/** The ring fills to the score, with a dot at the pass mark so it reads as "this far to go". */
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
            .size(180.dp)
            .graphicsLayer { translationX = shakeOffset(shake, 9.dp.toPx()) },
        contentAlignment = Alignment.Center,
    ) {
        Canvas(modifier = Modifier.size(168.dp)) {
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
        Box(
            modifier = Modifier
                .size(132.dp)
                .graphicsLayer {
                    scaleX = badgeScale
                    scaleY = badgeScale
                }
                .clip(CircleShape)
                .then(if (didPass) Modifier.background(PathPalette.goldGradient) else Modifier.background(DS.surfaceMuted)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                if (didPass) Icons.Filled.EmojiEvents else Icons.Filled.Replay,
                contentDescription = null,
                tint = if (didPass) Color.White else DS.inkSecondary,
                modifier = Modifier.size(58.dp),
            )
        }
    }
}
