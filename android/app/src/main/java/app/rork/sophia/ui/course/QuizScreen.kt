package app.rork.sophia.ui.course

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.WorkspacePremium
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
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
import app.rork.sophia.ui.components.AnswerOptionRow
import app.rork.sophia.ui.components.AnswerState
import app.rork.sophia.ui.components.CalmProgressBar
import app.rork.sophia.ui.components.CircleIconButton
import app.rork.sophia.ui.components.QuizFeedbackPanel
import app.rork.sophia.ui.components.SectionLabel
import app.rork.sophia.ui.components.SophiaPrimaryButton
import app.rork.sophia.ui.components.SophiaSecondaryButton
import app.rork.sophia.ui.components.optionLetter
import app.rork.sophia.ui.components.sophiaCard
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
            modifier = Modifier.fillMaxSize().background(DS.canvas).padding(DS.Space.l),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            QuizHero(icon = Icons.Filled.EmojiEvents)
            Spacer(Modifier.height(20.dp))
            Text(
                text = StringStore.text(context, "training.emptyTitle", language),
                style = SophiaTypography.titleMedium,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(24.dp))
            SophiaPrimaryButton(
                text = StringStore.text(context, "course.finish", language)
                    .takeIf { it != "course.finish" } ?: "Terminer",
                onClick = onFinished,
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
                progressManager.completeQuiz(
                    courseId = course.id,
                    score = totalPoints,
                    questionIds = questions.map { it.id },
                    subjectKey = course.subjectEnum.storageKey,
                )
                app.analytics.trackQuizCompleted(
                    courseId = course.id,
                    score = totalPoints,
                    total = max,
                    passed = totalPoints >= (max * 0.5).toInt(),
                )
                onFinished()
            },
        )
        return
    }

    val q = questions[index]
    val canValidate = when (q.type) {
        QuizQuestionType.MCQ, QuizQuestionType.TRUE_FALSE -> selected != null
        QuizQuestionType.CHRONOLOGICAL -> chronoSlots.none { it == null }
        else -> true
    }

    Column(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = DS.Space.l, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            CircleIconButton(icon = Icons.Filled.Close, onClick = onDismiss)
            CalmProgressBar(
                fraction = (index + 1).toFloat() / questions.size,
                modifier = Modifier.weight(1f),
            )
            Text(text = "${index + 1}/${questions.size}", style = SophiaTypography.labelMedium)
        }

        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = DS.Space.l),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            Spacer(Modifier.height(6.dp))
            Column(
                modifier = Modifier.fillMaxWidth().sophiaCard().padding(DS.Space.l),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Text(
                    text = course.title,
                    style = SophiaTypography.labelMedium.copy(
                        color = DS.accentSoft,
                        fontWeight = FontWeight.SemiBold,
                    ),
                    maxLines = 2,
                )
                Text(text = q.question, style = SophiaTypography.titleMedium.copy(fontSize = 20.sp))
            }

            when (q.type) {
                QuizQuestionType.MCQ, QuizQuestionType.TRUE_FALSE -> {
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        q.options.forEachIndexed { i, option ->
                            AnswerOptionRow(
                                letter = optionLetter(i),
                                text = option,
                                state = when {
                                    hasAnswered && i == q.correctIndex -> AnswerState.Correct
                                    hasAnswered && selected == i -> AnswerState.Wrong
                                    hasAnswered -> AnswerState.Dimmed
                                    selected == i -> AnswerState.Selected
                                    else -> AnswerState.Idle
                                },
                                enabled = !hasAnswered,
                                onClick = { selected = i },
                            )
                        }
                    }
                }
                QuizQuestionType.CHRONOLOGICAL -> {
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Text(
                            text = StringStore.text(context, "quiz.chronological.instruction", language),
                            style = SophiaTypography.bodyMedium,
                        )
                        chronoSlots.forEachIndexed { slot, displayIdx ->
                            ChronoSlot(
                                position = slot + 1,
                                label = displayIdx?.let { q.items.getOrNull(it) },
                                placeholder = StringStore.text(context, "quiz.chronological.emptySlot", language),
                                enabled = !hasAnswered && displayIdx != null,
                                onClick = {
                                    displayIdx?.let {
                                        chronoPool.add(it)
                                        chronoSlots[slot] = null
                                    }
                                },
                            )
                        }
                        if (chronoPool.isNotEmpty()) {
                            Spacer(Modifier.height(2.dp))
                            SectionLabel(StringStore.text(context, "quiz.chronological.remaining", language))
                            chronoPool.toList().forEach { displayIdx ->
                                AnswerOptionRow(
                                    letter = "•",
                                    text = q.items[displayIdx],
                                    state = AnswerState.Idle,
                                    enabled = !hasAnswered,
                                    onClick = {
                                        val empty = chronoSlots.indexOfFirst { it == null }
                                        if (empty >= 0) {
                                            chronoSlots[empty] = displayIdx
                                            chronoPool.remove(displayIdx)
                                        }
                                    },
                                )
                            }
                        }
                    }
                }
                QuizQuestionType.NUMERIC_SLIDER, QuizQuestionType.PERCENTAGE_SLIDER -> {
                    Column(
                        modifier = Modifier.fillMaxWidth().sophiaCard().padding(DS.Space.l),
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        Text(
                            text = "${sliderValue.toInt()}${q.unit}",
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 40.sp,
                            color = DS.ink,
                        )
                        Slider(
                            value = sliderValue.toFloat(),
                            onValueChange = { if (!hasAnswered) sliderValue = it.toDouble() },
                            valueRange = q.sliderMin.toFloat()..q.sliderMax.toFloat(),
                            colors = SliderDefaults.colors(
                                thumbColor = DS.accent,
                                activeTrackColor = DS.accent,
                                inactiveTrackColor = DS.hairline,
                            ),
                        )
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                        ) {
                            Text("${q.sliderMin.toInt()}${q.unit}", style = SophiaTypography.labelMedium)
                            Text("${q.sliderMax.toInt()}${q.unit}", style = SophiaTypography.labelMedium)
                        }
                        if (hasAnswered) {
                            Spacer(Modifier.height(12.dp))
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(10.dp),
                            ) {
                                ResultPill(
                                    label = StringStore.text(context, "quiz.slider.yourGuess", language),
                                    value = "${sliderValue.toInt()}${q.unit}",
                                    tint = DS.inkSecondary,
                                    modifier = Modifier.weight(1f),
                                )
                                ResultPill(
                                    label = StringStore.text(context, "quiz.slider.correctAnswer", language),
                                    value = "${q.correctValue.toInt()}${q.unit}",
                                    tint = DS.success,
                                    modifier = Modifier.weight(1f),
                                )
                            }
                        }
                    }
                }
            }
            Spacer(Modifier.height(8.dp))
        }

        if (hasAnswered) {
            QuizFeedbackPanel(
                correct = lastPoints == q.maxPoints,
                title = if (lastPoints == q.maxPoints) {
                    StringStore.text(context, "quiz.feedback.correct", language)
                } else {
                    StringStore.text(context, "quiz.feedback.wrong", language)
                } + "  +$lastPoints/${q.maxPoints}",
                explanation = q.explanation.takeIf { it.isNotBlank() },
                ctaText = if (index + 1 >= questions.size) {
                    StringStore.text(context, "training.finish", language)
                } else {
                    StringStore.text(context, "course.continue", language)
                        .takeIf { it != "course.continue" } ?: "Continuer"
                },
                onContinue = {
                    if (index + 1 >= questions.size) {
                        finished = true
                    } else {
                        index += 1
                        resetForQuestion(index)
                    }
                },
            )
        } else {
            Box(modifier = Modifier.padding(horizontal = DS.Space.l, vertical = 16.dp)) {
                SophiaPrimaryButton(
                    text = StringStore.text(context, "quiz.validate", language)
                        .takeIf { it != "quiz.validate" } ?: "Valider",
                    enabled = canValidate,
                    onClick = {
                        val answer = when (q.type) {
                            QuizQuestionType.MCQ, QuizQuestionType.TRUE_FALSE ->
                                QuizAnswer.SingleChoice(selected ?: return@SophiaPrimaryButton)
                            QuizQuestionType.CHRONOLOGICAL -> {
                                if (chronoSlots.any { it == null }) return@SophiaPrimaryButton
                                QuizAnswer.Order(chronoSlots.filterNotNull())
                            }
                            QuizQuestionType.NUMERIC_SLIDER, QuizQuestionType.PERCENTAGE_SLIDER ->
                                QuizAnswer.Value(sliderValue)
                        }
                        lastPoints = QuizScoring.points(q, answer)
                        totalPoints += lastPoints
                        hasAnswered = true
                    },
                )
            }
        }
    }
}

@Composable
private fun QuizHero(icon: androidx.compose.ui.graphics.vector.ImageVector) {
    Box(
        modifier = Modifier.size(120.dp).clip(CircleShape).background(DS.accentTint),
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
    Box(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
        Column(
            modifier = Modifier.fillMaxSize().padding(DS.Space.l),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            QuizHero(icon = Icons.Filled.WorkspacePremium)
            Spacer(Modifier.height(24.dp))
            Text(
                text = StringStore.text(context, "training.locked.title", language),
                style = SophiaTypography.titleLarge.copy(fontSize = 22.sp),
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(10.dp))
            Text(
                text = StringStore.text(context, "settings.premium.subtitle", language),
                style = SophiaTypography.bodyMedium,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(28.dp))
            SophiaPrimaryButton(
                text = StringStore.text(context, "settings.premium.title", language),
                onClick = onRequestPaywall,
                modifier = Modifier.padding(horizontal = 12.dp),
            )
            Spacer(Modifier.height(12.dp))
            SophiaSecondaryButton(
                text = StringStore.text(context, "home.skip", language),
                onClick = onSkip,
                contentColor = DS.inkSecondary,
                modifier = Modifier.padding(horizontal = 12.dp),
            )
        }
        CircleIconButton(
            icon = Icons.Filled.Close,
            onClick = onDismiss,
            modifier = Modifier.padding(DS.Space.s),
        )
    }
}

@Composable
private fun QuizResults(
    language: AppLanguage,
    score: Int,
    max: Int,
    onFinish: () -> Unit,
) {
    val context = LocalContext.current
    Column(
        modifier = Modifier.fillMaxSize().background(DS.canvas).padding(DS.Space.l),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        QuizHero(icon = Icons.Filled.EmojiEvents)
        Spacer(Modifier.height(24.dp))
        Text(
            text = StringStore.text(context, "quiz.completed", language),
            style = SophiaTypography.titleLarge.copy(fontSize = 22.sp),
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(20.dp))
        Column(
            modifier = Modifier.fillMaxWidth().sophiaCard().padding(DS.Space.l),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = "$score / $max",
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 40.sp,
                color = DS.ink,
            )
            Spacer(Modifier.height(6.dp))
            Text(
                text = StringStore.text(context, "quiz.pointsEarned", language),
                style = SophiaTypography.labelMedium,
            )
            Spacer(Modifier.height(14.dp))
            CalmProgressBar(fraction = if (max == 0) 0f else score.toFloat() / max)
        }
        Spacer(Modifier.height(28.dp))
        SophiaPrimaryButton(
            text = StringStore.text(context, "training.finish", language),
            onClick = onFinish,
        )
    }
}

@Composable
private fun ChronoSlot(
    position: Int,
    label: String?,
    placeholder: String,
    enabled: Boolean,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 56.dp)
            .clip(DS.controlShape)
            .background(if (label == null) DS.surfaceMuted else DS.surface)
            .border(1.dp, DS.hairline, DS.controlShape)
            .then(if (enabled) Modifier.clickable(onClick = onClick) else Modifier)
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(
            modifier = Modifier.size(28.dp).clip(CircleShape).background(DS.accentTint),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = "$position",
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 13.sp,
                color = DS.accentSoft,
            )
        }
        Text(
            text = label ?: placeholder,
            style = SophiaTypography.bodyLarge.copy(
                color = if (label == null) DS.inkTertiary else DS.ink,
            ),
        )
    }
}

@Composable
private fun ResultPill(label: String, value: String, tint: Color, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .clip(DS.controlShape)
            .background(DS.surfaceMuted)
            .padding(vertical = 10.dp, horizontal = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        SectionLabel(label)
        Spacer(Modifier.height(4.dp))
        Text(
            text = value,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 15.sp,
            color = tint,
        )
    }
}
