package app.rork.sophia.ui.course

import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.WorkspacePremium
import androidx.compose.material.icons.outlined.EmojiEvents
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.analytics.Analytics
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Course
import app.rork.sophia.domain.QuizAnswer
import app.rork.sophia.domain.QuizQuestionType
import app.rork.sophia.domain.QuizScoring
import app.rork.sophia.domain.QuizShuffler
import app.rork.sophia.domain.ShuffledQuestion
import app.rork.sophia.ui.components.AnswerOptionRow
import app.rork.sophia.ui.components.AnswerState
import app.rork.sophia.ui.components.CoursePalette
import app.rork.sophia.ui.components.CoursePrimaryButton
import app.rork.sophia.ui.components.CourseQuizQuestionHeader
import app.rork.sophia.ui.components.CourseQuizTopBar
import app.rork.sophia.ui.components.CourseRoundIconButton
import app.rork.sophia.ui.components.DSCountUp
import app.rork.sophia.ui.components.OrderingAnswerControl
import app.rork.sophia.ui.components.QuizVerdictPanel
import app.rork.sophia.ui.components.QuizVerdictTone
import app.rork.sophia.ui.components.SliderAnswerCard
import app.rork.sophia.ui.components.SophiaPrimaryButton
import app.rork.sophia.ui.components.SophiaSecondaryButton
import app.rork.sophia.ui.components.TrueFalseAnswerCard
import app.rork.sophia.ui.components.dsPopIn
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.optionLetter
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.onboarding.readableWidth
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

@Composable
fun QuizScreen(
    course: Course,
    language: AppLanguage,
    isPremium: Boolean,
    progressManager: ProgressManager,
    onRequestPaywall: () -> Unit,
    onFinished: () -> Unit,
    onDismiss: () -> Unit = onFinished,
) {
    val context = LocalContext.current

    if (!isPremium) {
        QuizPremiumGate(
            language = language,
            onRequestPaywall = onRequestPaywall,
            onSkip = onFinished,
            onDismiss = onDismiss,
        )
        return
    }

    val questions = remember(course.id) { mutableStateListOf<ShuffledQuestion>() }
    var quizReady by remember(course.id) { mutableStateOf(false) }
    LaunchedEffect(course.id) {
        val raw = if (course.quiz.isNotEmpty()) {
            course.quiz
        } else {
            withContext(Dispatchers.IO) {
                ContentCatalog.quizQuestions(
                    context.applicationContext,
                    language,
                    course.id,
                )
            }
        }
        questions.clear()
        questions.addAll(raw.map { QuizShuffler.shuffle(it) })
        quizReady = true
    }
    if (!quizReady) {
        Box(
            modifier = Modifier.fillMaxSize().background(DS.canvas),
            contentAlignment = Alignment.Center,
        ) {
            CircularProgressIndicator(color = DS.accent)
        }
        return
    }
    var index by remember { mutableIntStateOf(0) }
    var totalPoints by remember { mutableIntStateOf(0) }
    var finished by remember { mutableStateOf(false) }
    var selected by remember { mutableStateOf<Int?>(null) }
    var sliderValue by remember { mutableDoubleStateOf(0.0) }
    var hasAnswered by remember { mutableStateOf(false) }
    var lastPoints by remember { mutableIntStateOf(0) }
    var questionShownAt by remember { mutableLongStateOf(System.currentTimeMillis()) }
    val chronoSlots = remember { mutableStateListOf<Int?>() }
    val chronoPool = remember { mutableStateListOf<Int>() }
    // Right answers in a row, for the combo pill of the header. Display only: nothing is
    // scored on it.
    var combo by remember { mutableIntStateOf(0) }
    val haptics = rememberHaptics()

    fun resetForQuestion(i: Int) {
        val q = questions[i]
        selected = null
        hasAnswered = false
        lastPoints = 0
        questionShownAt = System.currentTimeMillis()
        sliderValue = q.snapToStep((q.sliderMin + q.sliderMax) / 2.0)
        chronoSlots.clear()
        chronoPool.clear()
        if (q.type == QuizQuestionType.CHRONOLOGICAL) {
            chronoSlots.addAll(List(q.items.size) { null })
            chronoPool.addAll(q.items.indices)
        }
    }

    // Question 1 only ever got the defaults of the `remember` blocks: a slider pinned at 0
    // even when the range started elsewhere, and — worse — an ordering question with no
    // slots and no items to place, which could not be answered at all. Only questions 2
    // onwards went through resetForQuestion.
    LaunchedEffect(questions.size) {
        if (questions.isNotEmpty()) {
            resetForQuestion(index)
            Analytics.log("quiz_start", courseId = course.id, props = mapOf("context" to "course", "total" to questions.size))
        }
    }

    if (questions.isEmpty()) {
        Column(
            modifier = Modifier.fillMaxSize().background(DS.canvas).padding(24.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            QuizHero(icon = Icons.Outlined.EmojiEvents)
            Spacer(Modifier.height(20.dp))
            Text(
                text = StringStore.text(context, "training.emptyTitle", language),
                style = SophiaTypography.titleLarge.copy(fontSize = 24.sp, lineHeight = 31.sp),
                textAlign = TextAlign.Center,
                modifier = Modifier.dsStagger(1),
            )
            Spacer(Modifier.height(24.dp))
            SophiaPrimaryButton(
                text = StringStore.text(context, "course.finish", language),
                onClick = onFinished,
                modifier = Modifier.readableWidth().dsStagger(2),
            )
        }
        return
    }

    if (finished) {
        val max = questions.sumOf { it.maxPoints }
        QuizResults(
            language = language,
            score = totalPoints,
            max = max,
            onFinish = {
                Analytics.log(
                    "quiz_complete",
                    courseId = course.id,
                    props = mapOf("context" to "course", "score" to totalPoints, "max_score" to max, "total" to questions.size),
                )
                progressManager.completeQuiz(
                    courseId = course.id,
                    score = totalPoints,
                    maxPoints = max,
                    questionIds = questions.map { it.id },
                    subjectKey = course.subjectEnum.storageKey,
                )
                onFinished()
            },
        )
        return
    }

    // Back leaves the quiz rather than the app. Mid-quiz it is the same exit the close
    // button offers: answers are scored as they are validated, so nothing is lost that
    // was not already lost.
    BackHandler { onDismiss() }

    val q = questions[index]
    val canValidate = when (q.type) {
        QuizQuestionType.MCQ, QuizQuestionType.TRUE_FALSE -> selected != null
        QuizQuestionType.CHRONOLOGICAL -> chronoSlots.none { it == null }
        else -> true
    }

    val subjectName = StringStore.text(context, "subject.${course.subjectEnum.storageKey}.short", language)
    // « Question 2 sur 8 »: the eyebrow, and what TalkBack reads on the progress.
    val questionCount = StringStore.text(context, "elevateCourse.quiz.questionOf", language, index + 1, questions.size)
    val fullyCorrect = lastPoints == q.maxPoints

    fun optionState(i: Int): AnswerState = when {
        hasAnswered && i == q.correctIndex -> AnswerState.Correct
        hasAnswered && selected == i -> AnswerState.Wrong
        hasAnswered -> AnswerState.Dimmed
        selected == i -> AnswerState.Selected
        else -> AnswerState.Idle
    }

    fun select(i: Int) {
        if (selected != i) haptics.select()
        selected = i
    }

    Column(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
        CourseQuizTopBar(
            total = questions.size,
            filled = index + 1,
            closeLabel = StringStore.text(context, "common.close", language),
            progressLabel = questionCount,
            onClose = onDismiss,
            combo = combo,
        )

        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            // Each question arrives on its own: the statement, then its answers in cascade.
            key(index) {
                Column(
                    modifier = Modifier.readableWidth().fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(26.dp),
                ) {
                    CourseQuizQuestionHeader(
                        subject = course.subjectEnum,
                        eyebrow = "$subjectName · $questionCount",
                        question = q.question,
                        caption = course.title,
                        modifier = Modifier.padding(top = 26.dp).dsStagger(0),
                    )

                    when (q.type) {
                        QuizQuestionType.MCQ, QuizQuestionType.TRUE_FALSE -> {
                            if (q.type == QuizQuestionType.TRUE_FALSE && q.options.size == 2) {
                                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                                    q.options.forEachIndexed { i, option ->
                                        TrueFalseAnswerCard(
                                            text = option,
                                            isTrue = i == 0,
                                            state = optionState(i),
                                            enabled = !hasAnswered,
                                            onClick = { select(i) },
                                            modifier = Modifier.weight(1f).dsStagger(i + 1),
                                        )
                                    }
                                }
                            } else {
                                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                    q.options.forEachIndexed { i, option ->
                                        AnswerOptionRow(
                                            letter = optionLetter(i),
                                            text = option,
                                            state = optionState(i),
                                            enabled = !hasAnswered,
                                            onClick = { select(i) },
                                            modifier = Modifier.dsStagger(i + 1),
                                        )
                                    }
                                }
                            }
                        }
                        QuizQuestionType.CHRONOLOGICAL -> OrderingAnswerControl(
                            question = q,
                            language = language,
                            slots = chronoSlots,
                            pool = chronoPool,
                            answered = hasAnswered,
                        )
                        QuizQuestionType.NUMERIC_SLIDER, QuizQuestionType.PERCENTAGE_SLIDER ->
                            SliderAnswerCard(
                                question = q,
                                language = language,
                                value = sliderValue,
                                onValueChange = { sliderValue = it },
                                answered = hasAnswered,
                                modifier = Modifier.dsStagger(1),
                            )
                    }
                    Spacer(Modifier.height(6.dp))
                }
            }
        }

        if (hasAnswered) {
            // The verdict panel rises from the bottom; its « Continuer » vibrates by itself.
            QuizVerdictPanel(
                tone = when {
                    fullyCorrect -> QuizVerdictTone.Success
                    lastPoints > 0 -> QuizVerdictTone.Partial
                    else -> QuizVerdictTone.Failure
                },
                title = when {
                    !fullyCorrect -> StringStore.text(context, "quiz.feedback.wrong", language)
                    combo >= 3 -> StringStore.text(context, "quiz.feedback.amazing", language)
                    combo >= 2 -> StringStore.text(context, "quiz.feedback.excellent", language)
                    else -> StringStore.text(context, "quiz.feedback.correct", language)
                },
                badgeText = "+$lastPoints/${q.maxPoints}",
                explanation = q.explanation.takeIf { it.isNotBlank() },
                ctaText = if (index + 1 >= questions.size) {
                    StringStore.text(context, "training.finish", language)
                } else {
                    StringStore.text(context, "course.continue", language)
                },
                onContinue = {
                    if (index + 1 >= questions.size) {
                        finished = true
                    } else {
                        index += 1
                        resetForQuestion(index)
                    }
                },
                detail = {
                    if (fullyCorrect && combo >= 2) {
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(4.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Icon(
                                imageVector = Icons.Filled.LocalFireDepartment,
                                contentDescription = null,
                                tint = CoursePalette.goldDeep,
                                modifier = Modifier.size(13.dp),
                            )
                            Text(
                                text = StringStore.text(context, "quiz.combo", language, combo),
                                fontFamily = PlusJakartaSans,
                                fontWeight = FontWeight.Bold,
                                fontSize = 12.sp,
                                color = CoursePalette.goldInk,
                            )
                        }
                    }
                },
            )
        } else {
            Box(modifier = Modifier.padding(start = 24.dp, end = 24.dp, top = 8.dp, bottom = 16.dp)) {
                // No vibration on the press: the verdict vibrates at once.
                CoursePrimaryButton(
                    text = StringStore.text(context, "quiz.validate", language),
                    enabled = canValidate,
                    haptic = false,
                    onClick = {
                        val answer = when (q.type) {
                            QuizQuestionType.MCQ, QuizQuestionType.TRUE_FALSE ->
                                QuizAnswer.SingleChoice(selected ?: return@CoursePrimaryButton)
                            QuizQuestionType.CHRONOLOGICAL -> {
                                if (chronoSlots.any { it == null }) return@CoursePrimaryButton
                                QuizAnswer.Order(chronoSlots.filterNotNull())
                            }
                            QuizQuestionType.NUMERIC_SLIDER, QuizQuestionType.PERCENTAGE_SLIDER ->
                                QuizAnswer.Value(sliderValue)
                        }
                        lastPoints = QuizScoring.points(q, answer)
                        totalPoints += lastPoints
                        hasAnswered = true
                        // The verdict: the combo of the header, and its vibration.
                        when {
                            lastPoints == q.maxPoints -> {
                                combo += 1
                                haptics.success()
                            }
                            lastPoints > 0 -> {
                                combo = 0
                                haptics.warning()
                            }
                            else -> {
                                combo = 0
                                haptics.error()
                            }
                        }
                        Analytics.log(
                            "quiz_answer",
                            courseId = course.id,
                            props = mapOf(
                                "question_id" to q.id,
                                "context" to "course",
                                "correct" to (lastPoints == q.maxPoints),
                                "points" to lastPoints,
                                "max_points" to q.maxPoints,
                                "option_index" to (answer as? QuizAnswer.SingleChoice)?.index,
                                "seconds" to ((System.currentTimeMillis() - questionShownAt) / 1000).toInt(),
                            ),
                        )
                    },
                )
            }
        }
    }
}

@Composable
private fun QuizHero(icon: androidx.compose.ui.graphics.vector.ImageVector) {
    Box(
        modifier = Modifier.size(120.dp).dsPopIn().clip(CircleShape).background(DS.accentTint),
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, contentDescription = null, tint = DS.accent, modifier = Modifier.size(50.dp))
    }
}

@Composable
private fun QuizPremiumGate(
    language: AppLanguage,
    onRequestPaywall: () -> Unit,
    onSkip: () -> Unit,
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    Box(modifier = Modifier.fillMaxSize().background(DS.canvas), contentAlignment = Alignment.Center) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .readableWidth()
                .verticalScroll(rememberScrollState())
                .padding(24.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            QuizHero(icon = Icons.Filled.WorkspacePremium)
            Spacer(Modifier.height(24.dp))
            Text(
                text = StringStore.text(context, "training.locked.title", language),
                style = SophiaTypography.titleLarge.copy(fontSize = 24.sp, lineHeight = 31.sp),
                textAlign = TextAlign.Center,
                modifier = Modifier.dsStagger(1),
            )
            Spacer(Modifier.height(10.dp))
            Text(
                text = StringStore.text(context, "settings.premium.subtitle", language),
                style = SophiaTypography.bodyMedium.copy(fontSize = 16.sp, lineHeight = 23.sp),
                textAlign = TextAlign.Center,
                modifier = Modifier.dsStagger(2),
            )
            Spacer(Modifier.height(28.dp))
            SophiaPrimaryButton(
                text = StringStore.text(context, "settings.premium.title", language),
                onClick = onRequestPaywall,
                modifier = Modifier.dsStagger(3),
            )
            Spacer(Modifier.height(10.dp))
            SophiaSecondaryButton(
                text = StringStore.text(context, "home.skip", language),
                onClick = onSkip,
                contentColor = DS.inkSecondary,
                modifier = Modifier.dsStagger(4),
            )
        }
        CourseRoundIconButton(
            icon = Icons.Filled.Close,
            onClick = onDismiss,
            contentDescription = StringStore.text(context, "common.close", language),
            modifier = Modifier.align(Alignment.TopStart).padding(start = 24.dp, top = 10.dp),
        )
    }
}

/**
 * The result: a golden ring that fills up to the score around the trophy, the score that
 * rolls up to its value, and the reward vibration when the quiz is passed.
 */
@Composable
private fun QuizResults(
    language: AppLanguage,
    score: Int,
    max: Int,
    onFinish: () -> Unit,
) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val fraction = if (max == 0) 0f else (score.toFloat() / max).coerceIn(0f, 1f)
    val ring = remember { Animatable(0f) }
    // 0, then the score: the counter rolls up to it.
    var shownScore by remember { mutableIntStateOf(0) }
    LaunchedEffect(Unit) {
        // Passed (at least half of the points): the reward vibration.
        if (fraction >= 0.5f) haptics.celebrate() else haptics.soft()
        shownScore = score
        ring.animateTo(fraction, tween(durationMillis = 900, delayMillis = 350))
    }
    Column(
        modifier = Modifier.fillMaxSize().background(DS.canvas),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .readableWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp, vertical = 20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterVertically),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(
                modifier = Modifier.size(150.dp).dsPopIn(delayMillis = 100).clearAndSetSemantics { },
                contentAlignment = Alignment.Center,
            ) {
                val track = CoursePalette.goldTint
                val gold = CoursePalette.gold
                Canvas(modifier = Modifier.fillMaxSize().padding(5.dp)) {
                    val stroke = 10.dp.toPx()
                    val inset = stroke / 2
                    val arcSize = Size(size.width - stroke, size.height - stroke)
                    drawArc(
                        color = track,
                        startAngle = 0f,
                        sweepAngle = 360f,
                        useCenter = false,
                        topLeft = Offset(inset, inset),
                        size = arcSize,
                        style = Stroke(width = stroke),
                    )
                    drawArc(
                        color = gold,
                        startAngle = -90f,
                        sweepAngle = 360f * ring.value.coerceIn(0f, 1f),
                        useCenter = false,
                        topLeft = Offset(inset, inset),
                        size = arcSize,
                        style = Stroke(width = stroke, cap = StrokeCap.Round),
                    )
                }
                Icon(
                    imageVector = Icons.Outlined.EmojiEvents,
                    contentDescription = null,
                    tint = CoursePalette.goldDeep,
                    modifier = Modifier.size(58.dp),
                )
            }
            Text(
                text = StringStore.text(context, "quiz.completed", language),
                style = SophiaTypography.titleLarge.copy(fontSize = 24.sp, lineHeight = 31.sp),
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 8.dp).dsStagger(1, baseMillis = 200),
            )
            DSCountUp(
                value = shownScore,
                suffix = " / $max",
                style = TextStyle(fontFamily = PlusJakartaSans, fontWeight = FontWeight.ExtraBold, fontSize = 44.sp),
                modifier = Modifier.dsStagger(2, baseMillis = 200),
            )
            Text(
                text = StringStore.text(context, "quiz.pointsEarned", language),
                style = SophiaTypography.bodyMedium,
                textAlign = TextAlign.Center,
                modifier = Modifier.dsStagger(3, baseMillis = 200),
            )
        }
        SophiaPrimaryButton(
            text = StringStore.text(context, "training.finish", language),
            onClick = onFinish,
            modifier = Modifier
                .readableWidth()
                .padding(start = 24.dp, end = 24.dp, bottom = 24.dp)
                .dsStagger(5, baseMillis = 300),
        )
    }
}
