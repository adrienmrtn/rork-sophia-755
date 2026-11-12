package app.rork.sophia.ui.components

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Tonality
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathMeasure
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans

/** Visual state of an answer row, shared by the quiz and the training session. */
enum class AnswerState { Idle, Selected, Correct, Wrong, Dimmed }

private fun AnswerState.optionState(): DSOptionState = when (this) {
    AnswerState.Idle -> DSOptionState.Idle
    AnswerState.Selected -> DSOptionState.Selected
    AnswerState.Correct -> DSOptionState.Correct
    AnswerState.Wrong -> DSOptionState.Wrong
    AnswerState.Dimmed -> DSOptionState.Dimmed
}

/** Text colour of an answer card according to its state. */
private fun AnswerState.textColor(): Color = when (this) {
    AnswerState.Idle, AnswerState.Selected -> DS.ink
    AnswerState.Correct -> CoursePalette.successInk
    AnswerState.Wrong -> DS.danger
    AnswerState.Dimmed -> DS.inkSecondary
}

/**
 * An answer of the « Elevate arrondi » quiz: a card without a letter. The right one turns
 * green with a check that draws itself, the wrong one chosen turns red, shakes and gets a
 * cross, the others fade. [letter] is kept for the call sites; the design no longer shows it.
 *
 * The card does not vibrate by itself: the screen decides (a selection tick, or the verdict).
 */
@Composable
fun AnswerOptionRow(
    letter: String,
    text: String,
    state: AnswerState,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .dsShake(trigger = if (state == AnswerState.Wrong) 1 else 0)
            .pressable(onClick = onClick, enabled = enabled, scaleDown = 0.98f, haptic = false)
            .dsOptionCard(state.optionState())
            .heightIn(min = 54.dp)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            text = text,
            modifier = Modifier.weight(1f),
            fontFamily = PlusJakartaSans,
            fontWeight = if (state == AnswerState.Correct) FontWeight.Bold else FontWeight.SemiBold,
            fontSize = 15.sp,
            lineHeight = 21.sp,
            color = state.textColor(),
        )
        when (state) {
            AnswerState.Correct -> DSCheckBadge(size = 26.dp)
            AnswerState.Wrong -> CourseCrossBadge(size = 26.dp)
            else -> Unit
        }
    }
}

/**
 * A « True » or « False » answer: two cards side by side, in the same style. The « True » card
 * (first option) carries a check, the other a cross.
 */
@Composable
fun TrueFalseAnswerCard(
    text: String,
    isTrue: Boolean,
    state: AnswerState,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    Column(
        modifier = modifier
            .dsShake(trigger = if (state == AnswerState.Wrong) 1 else 0)
            .pressable(onClick = onClick, enabled = enabled, scaleDown = 0.97f, haptic = false)
            .dsOptionCard(state.optionState())
            .padding(horizontal = 8.dp, vertical = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        when (state) {
            AnswerState.Correct -> DSCheckBadge(size = 30.dp)
            AnswerState.Wrong -> CourseCrossBadge(size = 30.dp)
            else -> Box(
                modifier = Modifier.size(30.dp).background(DS.accentTint, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = if (isTrue) Icons.Filled.Check else Icons.Filled.Close,
                    contentDescription = null,
                    tint = DS.accent,
                    modifier = Modifier.size(16.dp),
                )
            }
        }
        Text(
            text = text,
            modifier = Modifier.fillMaxWidth(),
            fontFamily = PlusJakartaSans,
            fontWeight = if (state == AnswerState.Correct) FontWeight.Bold else FontWeight.SemiBold,
            fontSize = 17.sp,
            color = state.textColor(),
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center,
        )
    }
}

/** Tone of a verdict: all right, partly right, missed. */
enum class QuizVerdictTone { Success, Partial, Failure }

private fun QuizVerdictTone.ink(): Color = when (this) {
    QuizVerdictTone.Success -> CoursePalette.successInk
    QuizVerdictTone.Partial -> DS.accent
    QuizVerdictTone.Failure -> DS.danger
}

private fun QuizVerdictTone.tint(): Color = when (this) {
    QuizVerdictTone.Success -> DS.successTint
    QuizVerdictTone.Partial -> DS.accentTint
    QuizVerdictTone.Failure -> DS.dangerTint
}

/** The round icon of a verdict: a green check that draws itself, a half disc, or a cross. */
@Composable
private fun QuizVerdictIcon(tone: QuizVerdictTone, size: Dp = 32.dp) {
    Box(
        modifier = Modifier
            .size(size)
            .dsPopIn(delayMillis = 50)
            .background(tone.tint(), CircleShape)
            .clearAndSetSemantics { },
        contentAlignment = Alignment.Center,
    ) {
        when (tone) {
            QuizVerdictTone.Success -> {
                val stroke = remember { Animatable(0f) }
                LaunchedEffect(Unit) { stroke.animateTo(1f, tween(durationMillis = 320, delayMillis = 120)) }
                val color = DS.success
                Canvas(modifier = Modifier.size(size * 0.44f)) {
                    val w = this.size.width
                    val h = this.size.height
                    val full = Path().apply {
                        moveTo(0f, h * 0.55f)
                        lineTo(w * 0.36f, h * 0.92f)
                        lineTo(w, h * 0.12f)
                    }
                    val measure = PathMeasure().apply { setPath(full, false) }
                    val partial = Path()
                    measure.getSegment(0f, measure.length * stroke.value.coerceIn(0f, 1f), partial, true)
                    drawPath(
                        path = partial,
                        color = color,
                        style = Stroke(width = 2.6.dp.toPx(), cap = StrokeCap.Round, join = StrokeJoin.Round),
                    )
                }
            }
            QuizVerdictTone.Partial -> Icon(
                imageVector = Icons.Filled.Tonality,
                contentDescription = null,
                tint = DS.accent,
                modifier = Modifier.size(size * 0.56f),
            )
            QuizVerdictTone.Failure -> Icon(
                imageVector = Icons.Filled.Close,
                contentDescription = null,
                tint = DS.danger,
                modifier = Modifier.size(size * 0.52f),
            )
        }
    }
}

/**
 * The white panel that rises from the bottom after an answer: verdict, an optional badge
 * (points earned), the explanation, then « Continuer ». [detail] takes the lines proper to a
 * screen (combo…). Compose it only once the answer is in: it plays its entrance when it
 * enters the composition.
 */
@Composable
fun QuizVerdictPanel(
    tone: QuizVerdictTone,
    title: String,
    explanation: String?,
    ctaText: String,
    onContinue: () -> Unit,
    modifier: Modifier = Modifier,
    badgeText: String? = null,
    detail: (@Composable ColumnScope.() -> Unit)? = null,
) {
    val enter = remember { Animatable(0f) }
    LaunchedEffect(Unit) { enter.animateTo(1f, DSMotion.reveal()) }
    val shape = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp)
    Column(
        modifier = modifier
            .fillMaxWidth()
            .graphicsLayer {
                alpha = enter.value.coerceIn(0f, 1f)
                translationY = (1f - enter.value) * size.height * 0.5f
            }
            .clip(shape)
            .background(DS.surface)
            .border(1.5.dp, DS.hairline, shape)
            .padding(start = 24.dp, end = 24.dp, top = 18.dp, bottom = 16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            QuizVerdictIcon(tone = tone)
            Text(
                text = title,
                modifier = Modifier.weight(1f),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 19.sp,
                lineHeight = 24.sp,
                color = tone.ink(),
            )
            if (!badgeText.isNullOrBlank()) {
                Text(
                    text = badgeText,
                    modifier = Modifier
                        .dsPopIn(delayMillis = 180)
                        .clip(RoundedCornerShape(12.dp))
                        .background(DS.accentTint)
                        .padding(horizontal = 10.dp, vertical = 4.dp),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 13.sp,
                    color = DS.accent,
                    maxLines = 1,
                )
            }
        }
        if (detail != null) detail()
        if (!explanation.isNullOrBlank()) {
            Text(
                text = explanation,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Normal,
                fontSize = 15.sp,
                lineHeight = 22.sp,
                color = DS.inkSecondary,
            )
        }
        Spacer(Modifier.height(8.dp))
        CoursePrimaryButton(
            text = ctaText,
            onClick = onContinue,
            trailingIcon = Icons.AutoMirrored.Filled.ArrowForward,
        )
    }
}

/** Result banner pinned under the question: verdict, explanation and the next CTA. */
@Composable
fun QuizFeedbackPanel(
    correct: Boolean,
    title: String,
    explanation: String?,
    ctaText: String,
    onContinue: () -> Unit,
    modifier: Modifier = Modifier,
) {
    QuizVerdictPanel(
        tone = if (correct) QuizVerdictTone.Success else QuizVerdictTone.Failure,
        title = title,
        explanation = explanation,
        ctaText = ctaText,
        onContinue = onContinue,
        modifier = modifier,
    )
}

/** A/B/C/D for the option at [index]. */
fun optionLetter(index: Int): String = ('A' + index).toString()
