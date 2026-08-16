package app.rork.sophia.ui.training

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.LockOpen
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.RestartAlt
import androidx.compose.material.icons.filled.VerifiedUser
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
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
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.TutorialFlags
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Course
import app.rork.sophia.domain.QuizAnswer
import app.rork.sophia.domain.QuizQuestion
import app.rork.sophia.domain.QuizQuestionType
import app.rork.sophia.domain.QuizScoring
import app.rork.sophia.domain.QuizShuffler
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.components.AnswerOptionRow
import app.rork.sophia.ui.components.AnswerState
import app.rork.sophia.ui.components.CalmProgressBar
import app.rork.sophia.ui.components.CircleIconButton
import app.rork.sophia.ui.components.FirstOpenExplanation
import app.rork.sophia.ui.components.QuizFeedbackPanel
import app.rork.sophia.ui.components.SophiaPrimaryButton
import app.rork.sophia.ui.components.optionLetter
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography

@Composable
fun TrainingScreen(
    modifier: Modifier = Modifier,
    language: AppLanguage,
    isPremium: Boolean,
    progress: UserProgress,
    progressManager: ProgressManager,
    storeViewModel: StoreViewModel,
    onPremiumUnlocked: () -> Unit = {},
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    // Questions live in the quiz catalog, not in the lightweight course stubs, so the
    // due set is resolved off the main thread from the training states themselves.
    val due by produceState(
        initialValue = emptyList<Pair<Course, QuizQuestion>>(),
        progress.trainingQuestionStates,
        language,
    ) {
        value = progressManager.resolveDueQuestions(context.applicationContext, language)
    }
    // Frozen at start: answering updates the due set, which would otherwise restart
    // or truncate the running session.
    var sessionItems by remember { mutableStateOf<List<Pair<Course, QuizQuestion>>>(emptyList()) }
    var showTrainingOb by remember { mutableStateOf(false) }
    var showExplain by remember {
        mutableStateOf(!app.tutorialFlags.seen(TutorialFlags.Id.TRAINING) && isPremium)
    }

    if (showTrainingOb) {
        TrainingOnboardingScreen(
            language = language,
            storeViewModel = storeViewModel,
            startAtPaywall = app.tutorialFlags.seen(TutorialFlags.Id.TRAINING_ONBOARDING),
            onCompletedOnboarding = {
                app.tutorialFlags.markSeen(TutorialFlags.Id.TRAINING_ONBOARDING)
            },
            onPurchased = {
                showTrainingOb = false
                onPremiumUnlocked()
            },
            onClose = { showTrainingOb = false },
        )
        return
    }

    if (sessionItems.isNotEmpty() && isPremium) {
        TrainingSession(
            language = language,
            items = sessionItems,
            progressManager = progressManager,
            onDone = { sessionItems = emptyList() },
        )
        return
    }

    Box(modifier = modifier.fillMaxSize().background(DS.canvas)) {
        Column(modifier = Modifier.fillMaxSize()) {
            Text(
                text = StringStore.text(context, "training.title", language),
                style = SophiaTypography.titleLarge,
                modifier = Modifier.padding(start = DS.Space.l, end = DS.Space.l, top = DS.Space.m, bottom = 4.dp),
            )
            Column(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = DS.Space.l),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Spacer(Modifier.height(40.dp))
                TrainingHero(
                    icon = when {
                        !isPremium -> Icons.Filled.Psychology
                        due.isEmpty() -> Icons.Filled.VerifiedUser
                        else -> Icons.Filled.RestartAlt
                    },
                )
                Spacer(Modifier.height(24.dp))
                when {
                    !isPremium -> {
                        TrainingCopy(
                            title = StringStore.text(context, "training.locked.title", language),
                            body = StringStore.text(context, "training.locked.message", language),
                        )
                        Spacer(Modifier.height(24.dp))
                        SophiaPrimaryButton(
                            text = StringStore.text(
                                context,
                                if (app.tutorialFlags.seen(TutorialFlags.Id.TRAINING_ONBOARDING)) {
                                    "training.unlock"
                                } else {
                                    "training.discover"
                                },
                                language,
                            ),
                            onClick = { showTrainingOb = true },
                            leadingIcon = Icons.Filled.LockOpen,
                            modifier = Modifier.padding(horizontal = 20.dp),
                        )
                    }
                    due.isEmpty() -> {
                        TrainingCopy(
                            title = StringStore.text(context, "training.emptyTitle", language),
                            body = StringStore.text(context, "training.emptyMessage", language),
                        )
                    }
                    else -> {
                        TrainingCopy(
                            title = StringStore.text(context, "training.readyTitle", language),
                            body = StringStore.text(context, "training.dueCount", language, due.size),
                        )
                        Spacer(Modifier.height(24.dp))
                        SophiaPrimaryButton(
                            text = StringStore.text(context, "training.start", language),
                            onClick = { sessionItems = due },
                            modifier = Modifier.padding(horizontal = 20.dp),
                        )
                    }
                }
                Spacer(Modifier.height(40.dp))
            }
        }
        if (showExplain) {
            FirstOpenExplanation(
                language = language,
                icon = "🎯",
                titleKey = "explain.training.title",
                bodyKey = "explain.training.body",
                onDismiss = {
                    app.tutorialFlags.markSeen(TutorialFlags.Id.TRAINING)
                    showExplain = false
                },
            )
        }
    }
}

@Composable
private fun TrainingHero(icon: androidx.compose.ui.graphics.vector.ImageVector) {
    Box(
        modifier = Modifier.size(128.dp).clip(CircleShape).background(DS.accentTint),
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, contentDescription = null, tint = DS.accent, modifier = Modifier.size(52.dp))
    }
}

@Composable
private fun TrainingCopy(title: String, body: String) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
        modifier = Modifier.padding(horizontal = 12.dp),
    ) {
        Text(text = title, style = SophiaTypography.titleLarge.copy(fontSize = 22.sp), textAlign = TextAlign.Center)
        Text(text = body, style = SophiaTypography.bodyMedium, textAlign = TextAlign.Center)
    }
}

@Composable
private fun TrainingSession(
    language: AppLanguage,
    items: List<Pair<Course, QuizQuestion>>,
    progressManager: ProgressManager,
    onDone: () -> Unit,
) {
    val context = LocalContext.current
    val shuffled = remember(items) { items.map { it.first to QuizShuffler.shuffle(it.second) } }
    var index by remember { mutableIntStateOf(0) }
    var selected by remember { mutableStateOf<Int?>(null) }
    var answered by remember { mutableStateOf(false) }
    var lastCorrect by remember { mutableStateOf(false) }
    var correctCount by remember { mutableIntStateOf(0) }
    var finished by remember { mutableStateOf(false) }

    if (finished) {
        Column(
            modifier = Modifier.fillMaxSize().background(DS.canvas).padding(DS.Space.l),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            TrainingHero(icon = Icons.Filled.VerifiedUser)
            Spacer(Modifier.height(24.dp))
            TrainingCopy(
                title = StringStore.text(context, "training.sessionComplete.title", language),
                body = StringStore.text(
                    context,
                    "training.sessionComplete.summary",
                    language,
                    correctCount,
                    shuffled.size,
                ),
            )
            Spacer(Modifier.height(28.dp))
            SophiaPrimaryButton(
                text = StringStore.text(context, "training.backToTraining", language),
                onClick = onDone,
                modifier = Modifier.padding(horizontal = 20.dp),
            )
        }
        return
    }

    val (course, q) = shuffled[index]
    val interactive = q.type == QuizQuestionType.MCQ || q.type == QuizQuestionType.TRUE_FALSE

    Column(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = DS.Space.l, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            CircleIconButton(icon = Icons.Filled.Close, onClick = onDone)
            CalmProgressBar(
                fraction = (index + 1).toFloat() / shuffled.size,
                modifier = Modifier.weight(1f),
            )
            Text(
                text = "${index + 1}/${shuffled.size}",
                style = SophiaTypography.labelMedium,
            )
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
                    style = SophiaTypography.labelMedium.copy(color = DS.accentSoft, fontWeight = FontWeight.SemiBold),
                    maxLines = 2,
                )
                Text(text = q.question, style = SophiaTypography.titleMedium.copy(fontSize = 20.sp))
            }

            if (interactive) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    q.options.forEachIndexed { i, option ->
                        AnswerOptionRow(
                            letter = optionLetter(i),
                            text = option,
                            state = when {
                                answered && i == q.correctIndex -> AnswerState.Correct
                                answered && selected == i -> AnswerState.Wrong
                                answered -> AnswerState.Dimmed
                                selected == i -> AnswerState.Selected
                                else -> AnswerState.Idle
                            },
                            enabled = !answered,
                            onClick = { selected = i },
                        )
                    }
                }
            } else {
                Text(
                    text = StringStore.text(context, "quiz.slider.validate", language),
                    style = SophiaTypography.bodyMedium,
                )
            }
            Spacer(Modifier.height(8.dp))
        }

        if (answered) {
            QuizFeedbackPanel(
                correct = lastCorrect,
                title = StringStore.text(
                    context,
                    if (lastCorrect) "quiz.feedback.correct" else "quiz.feedback.wrong",
                    language,
                ),
                explanation = q.explanation.takeIf { it.isNotBlank() },
                ctaText = if (index + 1 >= shuffled.size) {
                    StringStore.text(context, "training.finish", language)
                } else {
                    StringStore.text(context, "course.continue", language)
                        .takeIf { it != "course.continue" } ?: "Continuer"
                },
                onContinue = {
                    if (index + 1 >= shuffled.size) {
                        finished = true
                    } else {
                        index += 1
                        selected = null
                        answered = false
                    }
                },
            )
        } else {
            Box(modifier = Modifier.padding(horizontal = DS.Space.l, vertical = 16.dp)) {
                SophiaPrimaryButton(
                    text = StringStore.text(context, "quiz.validate", language)
                        .takeIf { it != "quiz.validate" } ?: "Valider",
                    enabled = !interactive || selected != null,
                    onClick = {
                        val answer = when (q.type) {
                            QuizQuestionType.MCQ, QuizQuestionType.TRUE_FALSE ->
                                QuizAnswer.SingleChoice(selected ?: return@SophiaPrimaryButton)
                            QuizQuestionType.NUMERIC_SLIDER, QuizQuestionType.PERCENTAGE_SLIDER ->
                                QuizAnswer.Value((q.sliderMin + q.sliderMax) / 2)
                            QuizQuestionType.CHRONOLOGICAL ->
                                QuizAnswer.Order(q.items.indices.toList())
                        }
                        val ok = QuizScoring.isFullyCorrect(q, answer)
                        lastCorrect = ok
                        if (ok) correctCount += 1
                        progressManager.recordTrainingAnswer(q.id, course.id, ok)
                        answered = true
                    },
                )
            }
        }
    }
}
