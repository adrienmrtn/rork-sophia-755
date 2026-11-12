package app.rork.sophia.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.DragHandle
import androidx.compose.material3.Icon
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.QuizAnswer
import app.rork.sophia.domain.QuizScoring
import app.rork.sophia.domain.ShuffledQuestion
import app.rork.sophia.domain.formatted
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import app.rork.sophia.ui.theme.uppercaseInApp

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
    val haptics = rememberHaptics()
    Column(
        modifier = modifier.fillMaxWidth().sophiaCard().padding(DS.Space.l),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = "${value.formatted(language, question.sliderDecimals)}${question.unit}",
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 44.sp,
            color = DS.ink,
            maxLines = 1,
        )
        Spacer(Modifier.height(6.dp))
        Slider(
            value = value.toFloat(),
            // Snapping to the question's own step is what makes an answer like 2.4
            // selectable at all, and keeps the value shown equal to the value scored.
            onValueChange = {
                if (!answered) {
                    val snapped = question.snapToStep(it.toDouble())
                    // A small notch each time the value moves to another step.
                    if (snapped != value) haptics.tick()
                    onValueChange(snapped)
                }
            },
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
                style = SophiaTypography.labelMedium.copy(fontWeight = FontWeight.SemiBold),
            )
            Text(
                text = "${question.sliderMax.formatted(language, question.sliderDecimals)}${question.unit}",
                style = SophiaTypography.labelMedium.copy(fontWeight = FontWeight.SemiBold),
            )
        }
        if (answered) {
            // The colour of « Ta réponse » follows the points the guess is worth: green when
            // it is within tolerance, blue when it earns something, red otherwise.
            val points = QuizScoring.points(question, QuizAnswer.Value(value))
            val (guessTint, guessFill) = when {
                points == question.maxPoints -> CoursePalette.successInk to DS.successTint
                points > 0 -> DS.accent to DS.accentTint
                else -> DS.danger to DS.dangerTint
            }
            Spacer(Modifier.height(14.dp))
            Row(
                modifier = Modifier.fillMaxWidth().dsPopIn(),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                SliderResultPill(
                    label = StringStore.text(context, "quiz.slider.yourGuess", language),
                    value = "${value.formatted(language, question.sliderDecimals)}${question.unit}",
                    tint = guessTint,
                    fill = guessFill,
                    modifier = Modifier.weight(1f).dsShake(trigger = if (points == 0) 1 else 0),
                )
                SliderResultPill(
                    label = StringStore.text(context, "quiz.slider.correctAnswer", language),
                    value = "${question.correctValue.formatted(language, question.sliderDecimals)}${question.unit}",
                    tint = CoursePalette.successInk,
                    fill = DS.successTint,
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
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            text = StringStore.text(context, "quiz.chronological.instruction", language),
            style = SophiaTypography.bodyMedium,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp),
        )
        slots.forEachIndexed { slot, displayIdx ->
            ChronoSlotRow(
                position = slot + 1,
                label = displayIdx?.let { question.items.getOrNull(it) },
                placeholder = StringStore.text(context, "quiz.chronological.emptySlot", language),
                // Once the answer is in, each slot says whether its item sits at its place.
                verdict = when {
                    !answered || displayIdx == null -> SlotVerdict.Pending
                    question.originalIndices.getOrNull(displayIdx) == slot -> SlotVerdict.Correct
                    else -> SlotVerdict.Wrong
                },
                enabled = !answered && displayIdx != null,
                onClick = {
                    displayIdx?.let {
                        pool.add(it)
                        slots[slot] = null
                    }
                },
                modifier = Modifier.dsStagger(slot),
            )
        }
        if (pool.isNotEmpty()) {
            Text(
                text = StringStore.text(context, "quiz.chronological.remaining", language).uppercaseInApp(),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 11.sp,
                letterSpacing = 0.9.sp,
                color = DS.inkSecondary,
                modifier = Modifier.padding(top = 8.dp),
            )
            pool.toList().forEach { displayIdx ->
                ChronoPoolRow(
                    text = question.items[displayIdx],
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

private enum class SlotVerdict { Pending, Correct, Wrong }

/**
 * A numbered slot of the ordering question: empty (dashes), filled (a bordered card with its
 * handle), then green or red once the answer is in.
 */
@Composable
private fun ChronoSlotRow(
    position: Int,
    label: String?,
    placeholder: String,
    verdict: SlotVerdict,
    enabled: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val filled = label != null
    val state = when (verdict) {
        SlotVerdict.Pending -> DSOptionState.Idle
        SlotVerdict.Correct -> DSOptionState.Correct
        SlotVerdict.Wrong -> DSOptionState.Wrong
    }
    val dash = DS.hairline
    val chrome = if (filled) {
        Modifier.dsOptionCard(state)
    } else {
        Modifier
            .clip(DS.cardShape)
            .background(DS.surface)
            .drawBehind {
                val stroke = 1.5.dp.toPx()
                val radius = DS.Radius.card.toPx()
                drawRoundRect(
                    color = dash,
                    topLeft = androidx.compose.ui.geometry.Offset(stroke / 2, stroke / 2),
                    size = androidx.compose.ui.geometry.Size(size.width - stroke, size.height - stroke),
                    cornerRadius = CornerRadius(radius, radius),
                    style = Stroke(
                        width = stroke,
                        pathEffect = PathEffect.dashPathEffect(floatArrayOf(5.dp.toPx(), 4.dp.toPx())),
                    ),
                )
            }
    }
    Row(
        modifier = modifier
            .fillMaxWidth()
            .dsShake(trigger = if (verdict == SlotVerdict.Wrong) 1 else 0)
            .pressable(onClick = onClick, enabled = enabled, scaleDown = 0.98f)
            .then(chrome)
            .heightIn(min = 56.dp)
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        val badgeFill = when (verdict) {
            SlotVerdict.Correct -> DS.success
            SlotVerdict.Wrong -> DS.danger
            SlotVerdict.Pending -> if (filled) DS.accentTint else DS.surface
        }
        val badgeText = when (verdict) {
            SlotVerdict.Correct, SlotVerdict.Wrong -> Color.White
            SlotVerdict.Pending -> if (filled) DS.accent else DS.inkTertiary
        }
        Box(
            modifier = Modifier
                .size(28.dp)
                .clip(CircleShape)
                .background(badgeFill)
                .then(if (filled) Modifier else Modifier.border(1.dp, DS.hairline, CircleShape)),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = "$position",
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 13.sp,
                color = badgeText,
            )
        }
        Text(
            text = label ?: placeholder,
            modifier = Modifier.weight(1f),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 15.sp,
            lineHeight = 21.sp,
            color = when {
                !filled -> DS.inkTertiary
                verdict == SlotVerdict.Correct -> CoursePalette.successInk
                verdict == SlotVerdict.Wrong -> DS.danger
                else -> DS.ink
            },
        )
        when {
            !filled -> Unit
            verdict == SlotVerdict.Correct -> DSCheckBadge(size = 22.dp)
            verdict == SlotVerdict.Wrong -> CourseCrossBadge(size = 22.dp)
            else -> Icon(
                imageVector = Icons.Filled.DragHandle,
                contentDescription = null,
                tint = DS.inkTertiary,
                modifier = Modifier.size(18.dp),
            )
        }
    }
}

/** An answer still to be placed in the timeline. */
@Composable
private fun ChronoPoolRow(text: String, enabled: Boolean, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .pressable(onClick = onClick, enabled = enabled, scaleDown = 0.98f)
            .dsOptionCard(DSOptionState.Idle)
            .heightIn(min = 52.dp)
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(
            modifier = Modifier.size(28.dp).background(DS.accentTint, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.Add, contentDescription = null, tint = DS.accent, modifier = Modifier.size(16.dp))
        }
        Text(
            text = text,
            modifier = Modifier.weight(1f),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 15.sp,
            lineHeight = 21.sp,
            color = DS.ink,
        )
    }
}

/** « Ta réponse » / « Bonne réponse » under the slider, once the answer is in. */
@Composable
private fun SliderResultPill(label: String, value: String, tint: Color, fill: Color, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(DS.Radius.small))
            .background(fill)
            .padding(vertical = 10.dp, horizontal = 6.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Text(
            text = label.uppercaseInApp(),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 10.sp,
            letterSpacing = 0.6.sp,
            color = DS.inkSecondary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            text = value,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 15.sp,
            color = tint,
            maxLines = 1,
        )
    }
}

@Composable
fun QuizResultPill(label: String, value: String, tint: Color, modifier: Modifier = Modifier) {
    SliderResultPill(label = label, value = value, tint = tint, fill = DS.surfaceMuted, modifier = modifier)
}
