package app.rork.sophia.ui.path

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Contrast
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
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
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.analytics.Analytics
import app.rork.sophia.data.stripInlineMarkup
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.QuizAnswer
import app.rork.sophia.domain.QuizQuestionType
import app.rork.sophia.domain.QuizScoring
import app.rork.sophia.domain.ShuffledQuestion
import app.rork.sophia.domain.uppercaseIn
import app.rork.sophia.ui.components.DSCheckBadge
import app.rork.sophia.ui.components.DSChip
import app.rork.sophia.ui.components.DSHighlightTitle
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.DSOptionState
import app.rork.sophia.ui.components.OrderingAnswerControl
import app.rork.sophia.ui.components.SliderAnswerCard
import app.rork.sophia.ui.components.SophiaPrimaryButton
import app.rork.sophia.ui.components.dsOptionCard
import app.rork.sophia.ui.components.dsPopIn
import app.rork.sophia.ui.components.dsShake
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans

/** Past this width a question and its answers stop stretching. */
private val PANE_MAX_WIDTH = 560.dp

/**
 * One question of the level quiz with its answer controls and the verdict panel, the same
 * interaction as the course quiz. Scoring is left to [QuizScoring]; the pane only reports
 * whether the answer was fully correct, which is all the level quiz counts.
 *
 * Dressed like the course quiz: the source as a small-caps eyebrow, the question centred in
 * a light weight, the answers as option cards that turn green (with a check drawing itself)
 * or shake in red, and a rounded verdict panel sliding up from the bottom.
 */
@Composable
internal fun PathQuestionPane(
    entry: PathQuizEntry,
    language: AppLanguage,
    isLast: Boolean,
    onAnswered: (fullyCorrect: Boolean) -> Unit,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    fun text(key: String): String = StringStore.text(context, key, language)
    val question = entry.question

    var selected by remember { mutableStateOf<Int?>(null) }
    var sliderValue by remember { mutableDoubleStateOf(question.snapToStep((question.sliderMin + question.sliderMax) / 2.0)) }
    val chronoSlots = remember { mutableStateListOf<Int?>().apply { addAll(List(question.items.size) { null }) } }
    val chronoPool = remember { mutableStateListOf<Int>().apply { addAll(question.items.indices) } }
    var hasAnswered by remember { mutableStateOf(false) }
    var earned by remember { mutableIntStateOf(0) }
    // Bumped once when the answer earns nothing: what was answered shakes.
    var wrongShakes by remember { mutableIntStateOf(0) }
    val fullyCorrect = hasAnswered && earned == question.maxPoints

    fun submit(answer: QuizAnswer) {
        if (hasAnswered) return
        earned = QuizScoring.points(question, answer)
        hasAnswered = true
        val correct = earned == question.maxPoints
        Analytics.log(
            "quiz_answer",
            courseId = entry.course.id,
            props = mapOf(
                "question_id" to question.id,
                "context" to "path",
                "correct" to correct,
                "points" to earned,
                "max_points" to question.maxPoints,
                "option_index" to (answer as? QuizAnswer.SingleChoice)?.index,
            ),
        )
        when {
            correct -> haptics.success()
            earned > 0 -> haptics.warning()
            else -> {
                haptics.error()
                wrongShakes += 1
            }
        }
        onAnswered(correct)
    }

    /** Idle until the reader answers; then the right answer turns green, the one picked by mistake red, and the others step back. */
    fun optionState(index: Int): DSOptionState = when {
        !hasAnswered -> DSOptionState.Idle
        index == question.correctIndex -> DSOptionState.Correct
        index == selected -> DSOptionState.Wrong
        else -> DSOptionState.Dimmed
    }

    Column(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp)
                .padding(top = 22.dp, bottom = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(26.dp),
        ) {
            QuestionHeader(
                entry = entry,
                language = language,
                modifier = Modifier.widthIn(max = PANE_MAX_WIDTH).fillMaxWidth().dsStagger(0),
            )

            val answerModifier = Modifier.widthIn(max = PANE_MAX_WIDTH).fillMaxWidth()
            when (question.type) {
                QuizQuestionType.MCQ -> Column(
                    modifier = answerModifier,
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    question.options.forEachIndexed { i, option ->
                        OptionRow(
                            text = option,
                            state = optionState(i),
                            // Only the option picked by mistake shakes.
                            shakeTrigger = if (i == selected) wrongShakes else 0,
                            enabled = !hasAnswered,
                            modifier = Modifier.dsStagger(i + 1),
                            onClick = {
                                selected = i
                                submit(QuizAnswer.SingleChoice(i))
                            },
                        )
                    }
                }
                QuizQuestionType.TRUE_FALSE -> Row(
                    modifier = answerModifier,
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    question.options.forEachIndexed { i, option ->
                        TrueFalseButton(
                            index = i,
                            text = option,
                            state = optionState(i),
                            shakeTrigger = if (i == selected) wrongShakes else 0,
                            enabled = !hasAnswered,
                            modifier = Modifier.weight(1f).dsStagger(i + 1),
                            onClick = {
                                selected = i
                                submit(QuizAnswer.SingleChoice(i))
                            },
                        )
                    }
                }
                QuizQuestionType.CHRONOLOGICAL -> Column(
                    modifier = answerModifier.dsStagger(1).dsShake(wrongShakes),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
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
                        // The primary button vibrates on the press.
                        SophiaPrimaryButton(
                            text = text("quiz.chronological.validate"),
                            onClick = { submit(QuizAnswer.Order(chronoSlots.filterNotNull())) },
                        )
                    }
                }
                QuizQuestionType.NUMERIC_SLIDER, QuizQuestionType.PERCENTAGE_SLIDER -> Column(
                    modifier = answerModifier.dsStagger(1).dsShake(wrongShakes),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
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

        AnimatedVisibility(
            visible = hasAnswered,
            enter = slideInVertically(DSMotion.snappy()) { it } + fadeIn(),
        ) {
            VerdictPanel(
                question = question,
                earned = earned,
                fullyCorrect = fullyCorrect,
                title = feedbackTitle(question, earned, fullyCorrect, ::text),
                pointsLabel = text("quiz.pointsEarned"),
                continueLabel = if (isLast) text("path.quiz.seeResult") else text("common.continue"),
                onContinue = onContinue,
            )
        }
    }
}

// MARK: - Question

/** The course the question comes from, as an eyebrow, then the question itself. */
@Composable
private fun QuestionHeader(entry: PathQuizEntry, language: AppLanguage, modifier: Modifier = Modifier) {
    val question = entry.question.question
    val source = remember(entry.course.title, language) {
        stripInlineMarkup(entry.course.title).uppercaseIn(language)
    }
    // The longer the question, the smaller its title, so the answers stay on screen.
    val length = question.length
    val fontSize = when {
        length <= 70 -> 26.sp
        length <= 140 -> 22.sp
        else -> 20.sp
    }
    val lineHeight = when {
        length <= 70 -> 33.sp
        length <= 140 -> 29.sp
        else -> 26.sp
    }
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Icon(
                entry.course.subjectEnum.pathIcon,
                contentDescription = null,
                tint = DS.accent,
                modifier = Modifier.size(13.dp),
            )
            Text(
                text = source,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 11.sp,
                lineHeight = 15.sp,
                letterSpacing = 0.8.sp,
                color = DS.accent,
                textAlign = TextAlign.Center,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f, fill = false),
            )
        }
        DSHighlightTitle(
            text = question,
            modifier = Modifier.fillMaxWidth(),
            fontSize = fontSize,
            lineHeight = lineHeight,
            weight = FontWeight.Normal,
        )
    }
}

// MARK: - Choice answers

@Composable
private fun OptionRow(
    text: String,
    state: DSOptionState,
    shakeTrigger: Int,
    enabled: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .dsShake(shakeTrigger)
            // No vibration on the press itself: the verdict's follows at once.
            .pressable(onClick = onClick, enabled = enabled, haptic = false)
            .dsOptionCard(state)
            .heightIn(min = 56.dp)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = if (state == DSOptionState.Correct) FontWeight.Bold else FontWeight.Medium,
            fontSize = 15.sp,
            lineHeight = 21.sp,
            color = optionTextColor(state),
            modifier = Modifier.weight(1f),
        )
        when (state) {
            DSOptionState.Correct -> DSCheckBadge(size = 26.dp)
            DSOptionState.Wrong -> WrongBadge(size = 26.dp)
            else -> Unit
        }
    }
}

@Composable
private fun TrueFalseButton(
    index: Int,
    text: String,
    state: DSOptionState,
    shakeTrigger: Int,
    enabled: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .dsShake(shakeTrigger)
            // No vibration on the press itself: the verdict's follows at once.
            .pressable(onClick = onClick, enabled = enabled, haptic = false)
            .dsOptionCard(state)
            .padding(horizontal = 8.dp, vertical = 22.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Icon(
            if (index == 0) Icons.Filled.CheckCircle else Icons.Filled.Cancel,
            contentDescription = null,
            tint = when (state) {
                DSOptionState.Correct -> DS.success
                DSOptionState.Wrong -> DS.danger
                else -> DS.accent
            },
            modifier = Modifier.size(28.dp),
        )
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = if (state == DSOptionState.Correct) FontWeight.Bold else FontWeight.SemiBold,
            fontSize = 17.sp,
            color = optionTextColor(state),
            textAlign = TextAlign.Center,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

/** The options left aside keep their ink: the card itself fades them. */
private fun optionTextColor(state: DSOptionState): Color = when (state) {
    DSOptionState.Correct -> DS.success
    DSOptionState.Wrong -> DS.danger
    else -> DS.ink
}

/** Red counterpart of [DSCheckBadge], for the answer picked by mistake. */
@Composable
private fun WrongBadge(size: Dp) {
    Box(
        modifier = Modifier
            .dsPopIn()
            .size(size)
            .clip(CircleShape)
            .background(DS.danger)
            .clearAndSetSemantics { },
        contentAlignment = Alignment.Center,
    ) {
        Icon(Icons.Filled.Close, contentDescription = null, tint = Color.White, modifier = Modifier.size(size * 0.58f))
    }
}

// MARK: - Verdict panel

/**
 * The verdict, rising from the bottom: a rounded top edge, the badge and the title in the
 * colour of the outcome, the explanation and the button to go on.
 */
@Composable
private fun VerdictPanel(
    question: ShuffledQuestion,
    earned: Int,
    fullyCorrect: Boolean,
    title: String,
    pointsLabel: String,
    continueLabel: String,
    onContinue: () -> Unit,
) {
    val color = when {
        fullyCorrect -> DS.success
        earned > 0 -> DS.accent
        else -> DS.danger
    }
    val tint = when {
        fullyCorrect -> DS.successTint
        earned > 0 -> DS.accentTint
        else -> DS.dangerTint
    }
    val icon = when {
        fullyCorrect -> Icons.Filled.Check
        earned > 0 -> Icons.Filled.Contrast
        else -> Icons.Filled.Close
    }
    val panelShape = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp)
    val edge = DS.hairline
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(DS.surface, panelShape)
            .drawBehind {
                // Only the rounded top edge shows: the sides and the bottom are pushed out of the panel.
                val stroke = 1.5.dp.toPx()
                val overflow = 2.dp.toPx()
                drawRoundRect(
                    color = edge,
                    topLeft = Offset(-overflow, stroke / 2f),
                    size = Size(size.width + overflow * 2f, size.height + 80.dp.toPx()),
                    cornerRadius = CornerRadius(24.dp.toPx()),
                    style = Stroke(stroke),
                )
            },
        contentAlignment = Alignment.TopCenter,
    ) {
        Column(
            modifier = Modifier
                .widthIn(max = PANE_MAX_WIDTH)
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .padding(top = 18.dp, bottom = 16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Box(
                    modifier = Modifier
                        .dsPopIn(delayMillis = 50)
                        .size(32.dp)
                        .clip(CircleShape)
                        .background(tint),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(17.dp))
                }
                Text(
                    text = title,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 20.sp,
                    lineHeight = 25.sp,
                    color = color,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f),
                )
                if (question.maxPoints > 2) {
                    DSChip(
                        text = "+$earned/${question.maxPoints} $pointsLabel",
                        modifier = Modifier.dsPopIn(delayMillis = 150),
                    )
                }
            }
            if (question.explanation.isNotBlank()) {
                Text(
                    text = question.explanation,
                    fontFamily = PlusJakartaSans,
                    fontSize = 15.sp,
                    lineHeight = 22.sp,
                    color = DS.inkSecondary,
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(max = 220.dp)
                        .verticalScroll(rememberScrollState()),
                )
            }
            // The primary button vibrates on the press.
            SophiaPrimaryButton(
                text = continueLabel,
                onClick = onContinue,
                modifier = Modifier.padding(top = 8.dp),
            )
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
