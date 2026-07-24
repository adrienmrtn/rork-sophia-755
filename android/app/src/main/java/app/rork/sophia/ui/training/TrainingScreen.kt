package app.rork.sophia.ui.training

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.data.ContentCatalog
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
import app.rork.sophia.ui.components.FirstOpenExplanation
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
    val due = remember(progress, language) {
        progressManager.resolveDueQuestions(ContentCatalog.courses(context, language))
    }
    var inSession by remember { mutableStateOf(false) }
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

    if (inSession && due.isNotEmpty() && isPremium) {
        TrainingSession(
            language = language,
            items = due,
            progressManager = progressManager,
            onDone = { inSession = false },
        )
        return
    }

    Box(modifier = modifier.fillMaxSize()) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas)
            .padding(DS.Space.l),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = StringStore.text(context, "training.title", language),
            style = SophiaTypography.titleLarge,
        )
        Spacer(Modifier.height(12.dp))
        if (!isPremium) {
            Text(
                text = StringStore.text(context, "training.locked.title", language),
                style = SophiaTypography.titleMedium,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = StringStore.text(context, "training.locked.message", language),
                style = SophiaTypography.bodyMedium,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(20.dp))
            Button(
                onClick = { showTrainingOb = true },
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = DS.controlShape,
                colors = ButtonDefaults.buttonColors(containerColor = DS.accent, contentColor = Color.White),
            ) {
                Text(
                    text = StringStore.text(
                        context,
                        if (app.tutorialFlags.seen(TutorialFlags.Id.TRAINING_ONBOARDING)) {
                            "training.unlock"
                        } else {
                            "training.discover"
                        },
                        language,
                    ),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 16.sp,
                )
            }
        } else if (due.isEmpty()) {
            Text(
                text = StringStore.text(context, "training.emptyTitle", language),
                style = SophiaTypography.titleMedium,
                textAlign = TextAlign.Center,
            )
            Text(
                text = StringStore.text(context, "training.emptyMessage", language),
                style = SophiaTypography.bodyMedium,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 8.dp),
            )
        } else {
            Text(
                text = StringStore.text(context, "training.readyTitle", language),
                style = SophiaTypography.titleMedium,
                textAlign = TextAlign.Center,
            )
            Text(
                text = StringStore.text(context, "training.dueCount", language, due.size),
                style = SophiaTypography.bodyMedium,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 8.dp),
            )
            Spacer(Modifier.height(20.dp))
            Button(
                onClick = { inSession = true },
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = DS.controlShape,
                colors = ButtonDefaults.buttonColors(containerColor = DS.accent, contentColor = Color.White),
            ) {
                Text(
                    text = StringStore.text(context, "training.start", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                )
            }
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
    var correctCount by remember { mutableIntStateOf(0) }
    var finished by remember { mutableStateOf(false) }

    if (finished) {
        Column(
            modifier = Modifier.fillMaxSize().background(DS.canvas).padding(DS.Space.l),
            verticalArrangement = Arrangement.Center,
        ) {
            Text(StringStore.text(context, "training.sessionComplete.title", language), style = SophiaTypography.titleLarge)
            Spacer(Modifier.height(8.dp))
            Text(
                StringStore.text(context, "training.sessionComplete.summary", language, correctCount, shuffled.size),
                style = SophiaTypography.bodyLarge,
            )
            Spacer(Modifier.height(20.dp))
            Button(
                onClick = onDone,
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = DS.controlShape,
                colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
            ) {
                Text(StringStore.text(context, "training.backToTraining", language), color = Color.White)
            }
        }
        return
    }

    val (course, q) = shuffled[index]
    Column(
        modifier = Modifier.fillMaxSize().background(DS.canvas).padding(DS.Space.l),
    ) {
        Text("${index + 1}/${shuffled.size} · ${course.title}", style = SophiaTypography.labelMedium)
        Spacer(Modifier.height(12.dp))
        Text(q.question, style = SophiaTypography.titleMedium)
        Spacer(Modifier.height(16.dp))
        when (q.type) {
            QuizQuestionType.MCQ, QuizQuestionType.TRUE_FALSE -> {
                q.options.forEachIndexed { i, option ->
                    val bg = when {
                        answered && i == q.correctIndex -> DS.successTint
                        answered && selected == i && i != q.correctIndex -> DS.dangerTint
                        selected == i -> DS.accentTint
                        else -> DS.surface
                    }
                    Text(
                        text = option,
                        style = SophiaTypography.bodyLarge,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 6.dp)
                            .background(bg, DS.controlShape)
                            .clickable(enabled = !answered) { selected = i }
                            .padding(16.dp),
                    )
                }
            }
            else -> Text("Type non interactif en session rapide — valide pour passer.", style = SophiaTypography.bodyMedium)
        }
        Spacer(Modifier.height(20.dp))
        val canValidate = answered ||
            selected != null ||
            (q.type != QuizQuestionType.MCQ && q.type != QuizQuestionType.TRUE_FALSE)
        Button(
            onClick = {
                if (!answered) {
                    val answer = when (q.type) {
                        QuizQuestionType.MCQ, QuizQuestionType.TRUE_FALSE ->
                            QuizAnswer.SingleChoice(selected ?: return@Button)
                        QuizQuestionType.NUMERIC_SLIDER, QuizQuestionType.PERCENTAGE_SLIDER ->
                            QuizAnswer.Value((q.sliderMin + q.sliderMax) / 2)
                        QuizQuestionType.CHRONOLOGICAL ->
                            QuizAnswer.Order(q.items.indices.toList())
                    }
                    val ok = QuizScoring.isFullyCorrect(q, answer)
                    if (ok) correctCount += 1
                    progressManager.recordTrainingAnswer(q.id, course.id, ok)
                    answered = true
                } else if (index + 1 >= shuffled.size) {
                    finished = true
                } else {
                    index += 1
                    selected = null
                    answered = false
                }
            },
            enabled = canValidate,
            modifier = Modifier.fillMaxWidth().height(52.dp),
            shape = DS.controlShape,
            colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
        ) {
            Text(
                if (!answered) "Valider" else if (index + 1 >= shuffled.size) {
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
