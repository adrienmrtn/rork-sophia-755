package app.rork.sophia.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography

/** Visual state of an answer row, shared by the quiz and the training session. */
enum class AnswerState { Idle, Selected, Correct, Wrong, Dimmed }

/**
 * The iOS answer row: letter badge, option text, and a result icon once answered.
 * Colours follow the same semantics everywhere (sage for correct, terracotta for wrong).
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
    val background by animateColorAsState(
        targetValue = when (state) {
            AnswerState.Correct -> DS.successTint
            AnswerState.Wrong -> DS.dangerTint
            AnswerState.Selected -> DS.accentTint
            else -> DS.surface
        },
        animationSpec = tween(220),
        label = "answerBg",
    )
    val borderColor by animateColorAsState(
        targetValue = when (state) {
            AnswerState.Correct -> DS.success
            AnswerState.Wrong -> DS.danger
            AnswerState.Selected -> DS.accent
            else -> DS.hairline
        },
        animationSpec = tween(220),
        label = "answerBorder",
    )
    val badgeColor = when (state) {
        AnswerState.Correct -> DS.success
        AnswerState.Wrong -> DS.danger
        else -> DS.accentTint
    }
    val badgeContent = when (state) {
        AnswerState.Correct, AnswerState.Wrong -> Color.White
        else -> DS.accentSoft
    }
    Row(
        modifier = modifier
            .fillMaxWidth()
            .alpha(if (state == AnswerState.Dimmed) 0.55f else 1f)
            .softPress(onClick = onClick, enabled = enabled)
            .heightIn(min = 62.dp)
            .background(background, DS.controlShape)
            .border(
                width = if (state == AnswerState.Idle || state == AnswerState.Dimmed) 1.dp else 1.5.dp,
                color = borderColor,
                shape = DS.controlShape,
            )
            .padding(horizontal = 14.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Box(
            modifier = Modifier.size(34.dp).background(badgeColor, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = letter,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 15.sp,
                color = badgeContent,
            )
        }
        Text(
            text = text,
            style = SophiaTypography.bodyLarge.copy(fontWeight = FontWeight.Medium, fontSize = 16.sp),
            modifier = Modifier.weight(1f),
        )
        when (state) {
            AnswerState.Correct -> Icon(
                Icons.Filled.CheckCircle,
                contentDescription = null,
                tint = DS.success,
                modifier = Modifier.size(22.dp),
            )
            AnswerState.Wrong -> Icon(
                Icons.Filled.Cancel,
                contentDescription = null,
                tint = DS.danger,
                modifier = Modifier.size(22.dp),
            )
            else -> Spacer(Modifier.size(22.dp))
        }
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
    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(DS.surface)
            .padding(horizontal = DS.Space.l, vertical = 16.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Icon(
                if (correct) Icons.Filled.CheckCircle else Icons.Filled.Cancel,
                contentDescription = null,
                tint = if (correct) DS.success else DS.danger,
                modifier = Modifier.size(26.dp),
            )
            Text(
                text = title,
                style = SophiaTypography.titleMedium.copy(fontSize = 17.sp),
            )
        }
        if (!explanation.isNullOrBlank()) {
            Spacer(Modifier.size(6.dp))
            Text(text = explanation, style = SophiaTypography.bodyMedium)
        }
        Spacer(Modifier.size(14.dp))
        SophiaPrimaryButton(text = ctaText, onClick = onContinue)
    }
}

/** A/B/C/D for the option at [index]. */
fun optionLetter(index: Int): String = ('A' + index).toString()
