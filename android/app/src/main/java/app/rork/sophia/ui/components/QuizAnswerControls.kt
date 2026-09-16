package app.rork.sophia.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.ShuffledQuestion
import app.rork.sophia.domain.formatted
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography

/**
 * The slider and ordering controls, shared by the course quiz and the Training session.
 *
 * Training used to render neither: it printed a hint and then submitted the midpoint of the
 * range, or the items in the order they happened to be shuffled into. Both are wrong almost
 * every time, and since the spaced-repetition scheduler brings a failed question straight
 * back, those two question types looped forever and could never leave the queue.
 */
@Composable
fun SliderAnswerCard(
    question: ShuffledQuestion,
    language: AppLanguage,
    value: Double,
    onValueChange: (Double) -> Unit,
    answered: Boolean,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    Column(
        modifier = modifier.fillMaxWidth().sophiaCard().padding(DS.Space.l),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = "${value.formatted(language, question.sliderDecimals)}${question.unit}",
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 40.sp,
            color = DS.ink,
        )
        Slider(
            value = value.toFloat(),
            // Snapping to the question's own step is what makes an answer like 2.4
            // selectable at all, and keeps the value shown equal to the value scored.
            onValueChange = { if (!answered) onValueChange(question.snapToStep(it.toDouble())) },
            valueRange = question.sliderMin.toFloat()..question.sliderMax.toFloat(),
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
            Text(
                text = "${question.sliderMin.formatted(language, question.sliderDecimals)}${question.unit}",
                style = SophiaTypography.labelMedium,
            )
            Text(
                text = "${question.sliderMax.formatted(language, question.sliderDecimals)}${question.unit}",
                style = SophiaTypography.labelMedium,
            )
        }
        if (answered) {
            Spacer(Modifier.height(12.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                QuizResultPill(
                    label = StringStore.text(context, "quiz.slider.yourGuess", language),
                    value = "${value.formatted(language, question.sliderDecimals)}${question.unit}",
                    tint = DS.inkSecondary,
                    modifier = Modifier.weight(1f),
                )
                QuizResultPill(
                    label = StringStore.text(context, "quiz.slider.correctAnswer", language),
                    value = "${question.correctValue.formatted(language, question.sliderDecimals)}${question.unit}",
                    tint = DS.success,
                    modifier = Modifier.weight(1f),
                )
            }
        }
    }
}

/**
 * Tap an item to drop it into the next free slot, tap a filled slot to take it back.
 * [slots] and [pool] are the caller's state so it can score and reset them.
 */
@Composable
fun OrderingAnswerControl(
    question: ShuffledQuestion,
    language: AppLanguage,
    slots: MutableList<Int?>,
    pool: MutableList<Int>,
    answered: Boolean,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text(
            text = StringStore.text(context, "quiz.chronological.instruction", language),
            style = SophiaTypography.bodyMedium,
        )
        slots.forEachIndexed { slot, displayIdx ->
            ChronoSlotRow(
                position = slot + 1,
                label = displayIdx?.let { question.items.getOrNull(it) },
                placeholder = StringStore.text(context, "quiz.chronological.emptySlot", language),
                enabled = !answered && displayIdx != null,
                onClick = {
                    displayIdx?.let {
                        pool.add(it)
                        slots[slot] = null
                    }
                },
            )
        }
        if (pool.isNotEmpty()) {
            Spacer(Modifier.height(2.dp))
            SectionLabel(StringStore.text(context, "quiz.chronological.remaining", language))
            pool.toList().forEach { displayIdx ->
                AnswerOptionRow(
                    letter = "•",
                    text = question.items[displayIdx],
                    state = AnswerState.Idle,
                    enabled = !answered,
                    onClick = {
                        val empty = slots.indexOfFirst { it == null }
                        if (empty >= 0) {
                            slots[empty] = displayIdx
                            pool.remove(displayIdx)
                        }
                    },
                )
            }
        }
    }
}

@Composable
private fun ChronoSlotRow(
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
fun QuizResultPill(label: String, value: String, tint: Color, modifier: Modifier = Modifier) {
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
