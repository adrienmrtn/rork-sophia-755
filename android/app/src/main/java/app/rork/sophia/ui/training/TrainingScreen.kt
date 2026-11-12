package app.rork.sophia.ui.training

import androidx.compose.foundation.Image
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
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.LockOpen
import androidx.compose.material.icons.outlined.StarOutline
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
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.R
import app.rork.sophia.SophiaApplication
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.analytics.Analytics
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
import app.rork.sophia.ui.components.AnimatedRewardBadge
import app.rork.sophia.ui.components.AnswerOptionRow
import app.rork.sophia.ui.components.AnswerState
import app.rork.sophia.ui.components.CoursePrimaryButton
import app.rork.sophia.ui.components.CourseQuizQuestionHeader
import app.rork.sophia.ui.components.CourseQuizTopBar
import app.rork.sophia.ui.components.DSCheckBadge
import app.rork.sophia.ui.components.FirstOpenExplanation
import app.rork.sophia.ui.components.OrderingAnswerControl
import app.rork.sophia.ui.components.QuizFeedbackPanel
import app.rork.sophia.ui.components.RewardBadgeKind
import app.rork.sophia.ui.components.SliderAnswerCard
import app.rork.sophia.ui.components.SophiaPrimaryButton
import app.rork.sophia.ui.components.TrueFalseAnswerCard
import app.rork.sophia.ui.components.dsPopIn
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.optionLetter
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.onboarding.readableWidth
import app.rork.sophia.ui.theme.DS
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
        Column(modifier = Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = StringStore.text(context, "training.title", language),
                style = SophiaTypography.titleLarge,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(start = 24.dp, end = 24.dp, top = DS.Space.m, bottom = 4.dp),
            )
            // The illustration and its message, centred in the room above the button.
            Column(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 24.dp, vertical = 24.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                // One state at a time: each arrives with its own cascade.
                val state = when {
                    !isPremium -> TrainingEntry.Locked
                    due.isEmpty() -> TrainingEntry.Done
                    else -> TrainingEntry.Ready
                }
                key(state) {
                    TrainingIllustration(badge = state)
                    Spacer(Modifier.height(20.dp))
                    when (state) {
                        TrainingEntry.Locked -> TrainingCopy(
                            title = StringStore.text(context, "training.locked.title", language),
                            body = StringStore.text(context, "training.locked.message", language),
                        )
                        TrainingEntry.Done -> TrainingCopy(
                            title = StringStore.text(context, "training.emptyTitle", language),
                            body = StringStore.text(context, "training.emptyMessage", language),
                        )
                        TrainingEntry.Ready -> TrainingCopy(
                            title = StringStore.text(context, "training.readyTitle", language),
                            body = StringStore.text(context, "training.dueCount", language, due.size),
                        )
                    }
                }
            }
            // The action, anchored at the bottom of the screen.
            when {
                !isPremium -> {
                    val seenOnboarding = app.tutorialFlags.seen(TutorialFlags.Id.TRAINING_ONBOARDING)
                    CoursePrimaryButton(
                        text = StringStore.text(
                            context,
                            if (seenOnboarding) "training.unlock" else "training.discover",
                            language,
                        ),
                        onClick = { showTrainingOb = true },
                        leadingIcon = if (seenOnboarding) Icons.Filled.LockOpen else Icons.Outlined.StarOutline,
                        modifier = Modifier
                            .readableWidth()
                            .padding(start = 24.dp, end = 24.dp, bottom = 24.dp)
                            .dsStagger(3),
                    )
                }
                due.isEmpty() -> Unit
                else -> CoursePrimaryButton(
                    text = StringStore.text(context, "training.start", language),
                    onClick = { sessionItems = due },
                    modifier = Modifier
                        .readableWidth()
                        .padding(start = 24.dp, end = 24.dp, bottom = 24.dp)
                        .dsStagger(3),
                )
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

/** What the entry of the training shows: questions to review, nothing left, or locked. */
private enum class TrainingEntry { Ready, Done, Locked }

/**
 * The round illustration of the training, with a badge when everything is reviewed (a check
 * that draws itself) or while it is locked (a padlock).
 */
@Composable
private fun TrainingIllustration(badge: TrainingEntry) {
    Box(modifier = Modifier.size(190.dp).dsPopIn().clearAndSetSemantics { }) {
        Image(
            painter = painterResource(R.drawable.training_poster),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxSize().clip(CircleShape).background(DS.accentTint),
        )
        when (badge) {
            TrainingEntry.Ready -> Unit
            TrainingEntry.Done -> Box(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(end = 6.dp, bottom = 6.dp)
                    .background(DS.surface, CircleShape)
                    .padding(3.dp),
            ) {
                DSCheckBadge(size = 38.dp, delayMillis = 250)
            }
            TrainingEntry.Locked -> Box(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(end = 6.dp, bottom = 6.dp)
                    .background(DS.surface, CircleShape)
                    .padding(3.dp)
                    .size(38.dp)
                    .background(DS.accentTint, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Filled.Lock, contentDescription = null, tint = DS.accent, modifier = Modifier.size(17.dp))
            }
        }
    }
}

@Composable
private fun TrainingCopy(title: String, body: String) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
        modifier = Modifier.readableWidth().padding(horizontal = 8.dp),
    ) {
        Text(
            text = title,
            style = SophiaTypography.titleLarge.copy(fontSize = 24.sp, lineHeight = 31.sp),
            textAlign = TextAlign.Center,
            modifier = Modifier.dsStagger(1),
        )
        Text(
            text = body,
            style = SophiaTypography.bodyMedium.copy(fontSize = 16.sp, lineHeight = 24.sp),
            textAlign = TextAlign.Center,
            modifier = Modifier.dsStagger(2),
        )
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
    val haptics = rememberHaptics()
    val shuffled = remember(items) { items.map { it.first to QuizShuffler.shuffle(it.second) } }
    var index by remember { mutableIntStateOf(0) }
    var selected by remember { mutableStateOf<Int?>(null) }
    var answered by remember { mutableStateOf(false) }
    var lastCorrect by remember { mutableStateOf(false) }
    var correctCount by remember { mutableIntStateOf(0) }
    var finished by remember { mutableStateOf(false) }
    var sliderValue by remember { mutableDoubleStateOf(0.0) }
    val orderSlots = remember { mutableStateListOf<Int?>() }
    val orderPool = remember { mutableStateListOf<Int>() }

    fun resetForQuestion(i: Int) {
        val q = shuffled[i].second
        selected = null
        answered = false
        sliderValue = q.snapToStep((q.sliderMin + q.sliderMax) / 2.0)
        orderSlots.clear()
        orderPool.clear()
        if (q.type == QuizQuestionType.CHRONOLOGICAL) {
            orderSlots.addAll(List(q.items.size) { null })
            orderPool.addAll(q.items.indices)
        }
    }

    LaunchedEffect(shuffled) {
        if (shuffled.isNotEmpty()) resetForQuestion(index)
    }

    if (finished) {
        // The session is over: the reward vibration, once.
        LaunchedEffect(Unit) { haptics.celebrate() }
        Column(
            modifier = Modifier.fillMaxSize().background(DS.canvas),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Column(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(24.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Box(
                    modifier = Modifier.size(128.dp).dsPopIn().clip(CircleShape).background(DS.successTint),
                    contentAlignment = Alignment.Center,
                ) {
                    AnimatedRewardBadge(kind = RewardBadgeKind.Seal, size = 54.dp)
                }
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
            }
            SophiaPrimaryButton(
                text = StringStore.text(context, "training.backToTraining", language),
                onClick = onDone,
                modifier = Modifier
                    .readableWidth()
                    .padding(start = 24.dp, end = 24.dp, bottom = 24.dp)
                    .dsStagger(3),
            )
        }
        return
    }

    val (course, q) = shuffled[index]
    // Every question type is answerable here now, so "can we score yet?" replaces the old
    // "is this one of the two types we render?".
    val canValidate = when (q.type) {
        QuizQuestionType.MCQ, QuizQuestionType.TRUE_FALSE -> selected != null
        QuizQuestionType.CHRONOLOGICAL -> orderSlots.isNotEmpty() && orderSlots.none { it == null }
        QuizQuestionType.NUMERIC_SLIDER, QuizQuestionType.PERCENTAGE_SLIDER -> true
    }

    val subjectName = StringStore.text(context, "subject.${course.subjectEnum.storageKey}.short", language)
    // « Question 2 sur 8 »: the eyebrow, and what TalkBack reads on the progress.
    val questionCount = StringStore.text(context, "elevateCourse.quiz.questionOf", language, index + 1, shuffled.size)

    fun optionState(i: Int): AnswerState = when {
        answered && i == q.correctIndex -> AnswerState.Correct
        answered && selected == i -> AnswerState.Wrong
        answered -> AnswerState.Dimmed
        selected == i -> AnswerState.Selected
        else -> AnswerState.Idle
    }

    fun select(i: Int) {
        if (selected != i) haptics.select()
        selected = i
    }

    Column(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
        CourseQuizTopBar(
            total = shuffled.size,
            filled = index + 1,
            closeLabel = StringStore.text(context, "common.close", language),
            progressLabel = questionCount,
            onClose = onDone,
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
                        // The course the question comes from.
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
                                            enabled = !answered,
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
                                            enabled = !answered,
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
                            slots = orderSlots,
                            pool = orderPool,
                            answered = answered,
                        )
                        QuizQuestionType.NUMERIC_SLIDER, QuizQuestionType.PERCENTAGE_SLIDER ->
                            SliderAnswerCard(
                                question = q,
                                language = language,
                                value = sliderValue,
                                onValueChange = { sliderValue = it },
                                answered = answered,
                                modifier = Modifier.dsStagger(1),
                            )
                    }
                    Spacer(Modifier.height(6.dp))
                }
            }
        }

        if (answered) {
            // The verdict panel rises from the bottom; its « Continuer » vibrates by itself.
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
                },
                onContinue = {
                    if (index + 1 >= shuffled.size) {
                        finished = true
                    } else {
                        index += 1
                        resetForQuestion(index)
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
                            QuizQuestionType.NUMERIC_SLIDER, QuizQuestionType.PERCENTAGE_SLIDER ->
                                QuizAnswer.Value(sliderValue)
                            QuizQuestionType.CHRONOLOGICAL -> {
                                if (orderSlots.any { it == null }) return@CoursePrimaryButton
                                QuizAnswer.Order(orderSlots.filterNotNull())
                            }
                        }
                        val ok = QuizScoring.isFullyCorrect(q, answer)
                        Analytics.log(
                            "quiz_answer",
                            courseId = course.id,
                            props = mapOf(
                                "question_id" to q.id,
                                "context" to "training",
                                "correct" to ok,
                                "points" to (if (ok) q.maxPoints else 0),
                                "max_points" to q.maxPoints,
                                "option_index" to (answer as? QuizAnswer.SingleChoice)?.index,
                            ),
                        )
                        lastCorrect = ok
                        if (ok) correctCount += 1
                        progressManager.recordTrainingAnswer(q.id, course.id, ok)
                        answered = true
                        if (ok) haptics.success() else haptics.error()
                    },
                )
            }
        }
    }
}
