package app.rork.sophia.ui.course

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Course
import app.rork.sophia.domain.QuizAnswer
import app.rork.sophia.domain.QuizQuestionType
import app.rork.sophia.domain.QuizScoring
import app.rork.sophia.domain.QuizShuffler
import app.rork.sophia.domain.ShuffledQuestion
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
    val app = context.applicationContext as SophiaApplication
    if (!isPremium) {
        LaunchedEffect(Unit) {
            app.analytics.trackFreemiumGateHit("quizz", subject = course.subjectEnum.storageKey, courseId = course.id)
        }
        Box(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(DS.Space.l),
                verticalArrangement = Arrangement.Center,
            ) {
                Text(
                    text = StringStore.text(context, "training.locked.title", language)
                        .takeIf { it != "training.locked.title" } ?: "Quiz Premium",
                    style = SophiaTypography.titleLarge,
                )
                Spacer(Modifier.height(12.dp))
                Text(
                    text = "Les quiz sont réservés aux membres Premium.",
                    style = SophiaTypography.bodyMedium,
                )
                Spacer(Modifier.height(20.dp))
                Button(
                    onClick = onRequestPaywall,
                    modifier = Modifier.fillMaxWidth().height(52.dp),
                    shape = DS.controlShape,
                    colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
                ) {
                    Text("Premium", color = Color.White, fontFamily = PlusJakartaSans, fontWeight = FontWeight.SemiBold)
                }
                Spacer(Modifier.height(12.dp))
                Text(
                    text = StringStore.text(context, "home.skip", language),
                    style = SophiaTypography.labelLarge,
                    color = DS.inkSecondary,
                    modifier = Modifier.clickable(onClick = onFinished).padding(8.dp),
                )
            }
            Box(modifier = Modifier.padding(DS.Space.s)) { QuizCloseButton(onDismiss) }
        }
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
        app.analytics.trackQuizStarted(
            courseId = course.id,
            subject = course.subjectEnum.storageKey,
            questionCount = questions.size,
        )
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
    val chronoSlots = remember { mutableStateListOf<Int?>() }
    val chronoPool = remember { mutableStateListOf<Int>() }

    fun resetForQuestion(i: Int) {
        val q = questions[i]
        selected = null
        hasAnswered = false
        lastPoints = 0
        sliderValue = (q.sliderMin + q.sliderMax) / 2.0
        chronoSlots.clear()
        chronoPool.clear()
        if (q.type == QuizQuestionType.CHRONOLOGICAL) {
            chronoSlots.addAll(List(q.items.size) { null })
            chronoPool.addAll(q.items.indices)
        }
    }

    if (questions.isEmpty()) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(DS.canvas)
                .padding(DS.Space.l),
        ) {
            Text("No quiz", style = SophiaTypography.titleMedium)
            Button(onClick = onFinished) { Text("OK") }
        }
        return
    }

    if (finished) {
        val max = questions.sumOf { it.maxPoints }
        Column(
            modifier = Modifier.fillMaxSize().background(DS.canvas).padding(DS.Space.l),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = StringStore.text(context, "training.sessionComplete.title", language),
                style = SophiaTypography.titleLarge,
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = "$totalPoints / $max",
                style = SophiaTypography.displayLarge,
            )
            Spacer(Modifier.height(20.dp))
            Button(
                onClick = {
                    val maxPts = questions.sumOf { it.maxPoints }
                    progressManager.completeQuiz(
                        courseId = course.id,
                        score = totalPoints,
                        questionIds = questions.map { it.id },
                        subjectKey = course.subjectEnum.storageKey,
                    )
                    app.analytics.trackQuizCompleted(
                        courseId = course.id,
                        score = totalPoints,
                        total = maxPts,
                        passed = totalPoints >= (maxPts * 0.5).toInt(),
                    )
                    onFinished()
                },
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = DS.controlShape,
                colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
            ) {
                Text(
                    text = StringStore.text(context, "training.finish", language),
                    color = Color.White,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                )
            }
        }
        return
    }

    val q = questions[index]
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState())
            .padding(DS.Space.l),
    ) {
        QuizCloseButton(onDismiss)
        Spacer(Modifier.height(8.dp))
        LinearProgressIndicator(
            progress = { (index + 1).toFloat() / questions.size },
            modifier = Modifier.fillMaxWidth(),
            color = DS.accent,
            trackColor = DS.hairline,
            strokeCap = StrokeCap.Round,
        )
        Spacer(Modifier.height(16.dp))
        Text(
            text = "${index + 1}/${questions.size}",
            style = SophiaTypography.labelMedium,
        )
        Spacer(Modifier.height(8.dp))
        Text(text = q.question, style = SophiaTypography.titleMedium)
        Spacer(Modifier.height(20.dp))

        when (q.type) {
            QuizQuestionType.MCQ, QuizQuestionType.TRUE_FALSE -> {
                q.options.forEachIndexed { i, option ->
                    val selectedHere = selected == i
                    val showResult = hasAnswered
                    val bg = when {
                        showResult && i == q.correctIndex -> DS.successTint
                        showResult && selectedHere && i != q.correctIndex -> DS.dangerTint
                        selectedHere -> DS.accentTint
                        else -> DS.surface
                    }
                    Text(
                        text = option,
                        style = SophiaTypography.bodyLarge,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 6.dp)
                            .clip(DS.controlShape)
                            .background(bg)
                            .border(1.dp, DS.hairline, DS.controlShape)
                            .clickable(enabled = !hasAnswered) { selected = i }
                            .padding(16.dp),
                    )
                }
            }
            QuizQuestionType.CHRONOLOGICAL -> {
                Text("Ordre correct :", style = SophiaTypography.labelMedium)
                chronoSlots.forEachIndexed { slot, displayIdx ->
                    val label = displayIdx?.let { q.items.getOrNull(it) } ?: "—"
                    Text(
                        text = "${slot + 1}. $label",
                        style = SophiaTypography.bodyLarge,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp)
                            .clip(DS.controlShape)
                            .background(DS.surface)
                            .clickable(enabled = !hasAnswered && displayIdx != null) {
                                chronoPool.add(displayIdx!!)
                                chronoSlots[slot] = null
                            }
                            .padding(14.dp),
                    )
                }
                Spacer(Modifier.height(8.dp))
                Text("À placer :", style = SophiaTypography.labelMedium)
                chronoPool.toList().forEach { displayIdx ->
                    Text(
                        text = q.items[displayIdx],
                        style = SophiaTypography.bodyLarge,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp)
                            .clip(DS.controlShape)
                            .background(DS.accentTint)
                            .clickable(enabled = !hasAnswered) {
                                val empty = chronoSlots.indexOfFirst { it == null }
                                if (empty >= 0) {
                                    chronoSlots[empty] = displayIdx
                                    chronoPool.remove(displayIdx)
                                }
                            }
                            .padding(14.dp),
                    )
                }
            }
            QuizQuestionType.NUMERIC_SLIDER, QuizQuestionType.PERCENTAGE_SLIDER -> {
                Text(
                    text = "${sliderValue.toInt()}${q.unit}",
                    style = SophiaTypography.titleLarge,
                )
                Slider(
                    value = sliderValue.toFloat(),
                    onValueChange = { if (!hasAnswered) sliderValue = it.toDouble() },
                    valueRange = q.sliderMin.toFloat()..q.sliderMax.toFloat(),
                    colors = SliderDefaults.colors(thumbColor = DS.accent, activeTrackColor = DS.accent),
                )
            }
        }

        if (hasAnswered) {
            Spacer(Modifier.height(12.dp))
            Text(
                text = if (lastPoints == q.maxPoints) "✓ +$lastPoints" else "+$lastPoints / ${q.maxPoints}",
                color = if (lastPoints == q.maxPoints) DS.success else DS.danger,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 18.sp,
            )
            if (q.explanation.isNotBlank()) {
                Spacer(Modifier.height(8.dp))
                Text(text = q.explanation, style = SophiaTypography.bodyMedium)
            }
        }

        Spacer(Modifier.height(24.dp))
        Button(
            onClick = {
                if (!hasAnswered) {
                    val answer = when (q.type) {
                        QuizQuestionType.MCQ, QuizQuestionType.TRUE_FALSE ->
                            QuizAnswer.SingleChoice(selected ?: return@Button)
                        QuizQuestionType.CHRONOLOGICAL -> {
                            if (chronoSlots.any { it == null }) return@Button
                            QuizAnswer.Order(chronoSlots.filterNotNull())
                        }
                        QuizQuestionType.NUMERIC_SLIDER, QuizQuestionType.PERCENTAGE_SLIDER ->
                            QuizAnswer.Value(sliderValue)
                    }
                    lastPoints = QuizScoring.points(q, answer)
                    totalPoints += lastPoints
                    hasAnswered = true
                } else if (index + 1 >= questions.size) {
                    finished = true
                } else {
                    index += 1
                    resetForQuestion(index)
                }
            },
            modifier = Modifier.fillMaxWidth().height(52.dp),
            shape = DS.controlShape,
            colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
            enabled = hasAnswered || when (q.type) {
                QuizQuestionType.MCQ, QuizQuestionType.TRUE_FALSE -> selected != null
                QuizQuestionType.CHRONOLOGICAL -> chronoSlots.none { it == null }
                else -> true
            },
        ) {
            Text(
                text = if (!hasAnswered) {
                    StringStore.text(context, "quiz.validate", language)
                        .takeIf { it != "quiz.validate" } ?: "Valider"
                } else if (index + 1 >= questions.size) {
                    StringStore.text(context, "training.finish", language)
                } else {
                    StringStore.text(context, "course.continue", language)
                        .takeIf { it != "course.continue" } ?: "Continuer"
                },
                color = Color.White,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
            )
        }
    }
}

@Composable
private fun QuizCloseButton(onDismiss: () -> Unit) {
    IconButton(
        onClick = onDismiss,
        modifier = Modifier
            .size(40.dp)
            .clip(CircleShape)
            .background(DS.surface)
            .border(1.dp, DS.hairline, CircleShape),
    ) {
        Icon(Icons.Filled.Close, contentDescription = null, tint = DS.inkSecondary)
    }
}
