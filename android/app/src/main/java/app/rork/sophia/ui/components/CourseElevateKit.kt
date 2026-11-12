package app.rork.sophia.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.R
import app.rork.sophia.domain.Subject
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.uppercaseInApp

/**
 * Pieces of the « Elevate arrondi » design that belong to the « course » zone: reader, course
 * quiz, end of course, streak, training and audio player. The Android twin of the iOS
 * `CourseElevateKit.swift`. What the whole app shares lives in `ElevateKit.kt`; here, only
 * what these screens share between themselves.
 */

// region Colours

/**
 * The « gold » tones of the rewards (XP, combo, trophy) and the dark green of a verdict:
 * colours that carry a meaning, common to the quiz, its result, the end of course and the
 * streak.
 */
object CoursePalette {
    /** Saffron of the XP bars and of the flame (#E6B233). */
    val gold: Color get() = DS.warm

    /** Deep gold of the pictograms (#B17F10). */
    val goldDeep = Color(0xFFB17F10)

    /** Pale background of the XP and combo pills (#FBEFC9). */
    val goldTint = Color(0xFFFBEFC9)

    /** Text of the XP and combo pills (#6B4E00). */
    val goldInk = Color(0xFF6B4E00)

    /** Text of a right answer and title of a passed verdict (#1F4D36). */
    val successInk = Color(0xFF1F4D36)

    /** Neutral track of the progress bars. */
    val track: Color get() = DS.ink.copy(alpha = 0.12f)
}

// endregion

// region Buttons

/** A round white bordered button (close, options, listen): the header buttons of the zone. */
@Composable
fun CourseRoundIconButton(
    icon: ImageVector,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    contentDescription: String? = null,
    size: Dp = 44.dp,
    tint: Color = DS.ink,
    /** Tinted and ringed in blue (the narration of this course is loaded). */
    active: Boolean = false,
    haptic: Boolean = true,
) {
    val fill by animateColorAsState(if (active) DS.accentTint else DS.surface, DSMotion.snappy(), label = "roundFill")
    val edge by animateColorAsState(if (active) DS.accent else DS.hairline, DSMotion.snappy(), label = "roundEdge")
    Box(
        modifier = modifier
            .size(size)
            .pressable(onClick = onClick, scaleDown = 0.92f, haptic = haptic)
            .clip(CircleShape)
            .background(fill)
            .border(1.5.dp, edge, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector = icon,
            contentDescription = contentDescription,
            tint = if (active) DS.accent else tint,
            modifier = Modifier.size(size * 0.42f),
        )
    }
}

/**
 * The blue call to action of the style, with an optional icon on either side
 * (« Continuer → », « ✓ Terminer le cours »). [haptic] false is for the buttons whose action
 * picks its own vibration (a verdict, a change of section).
 */
@Composable
fun CoursePrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    leadingIcon: ImageVector? = null,
    trailingIcon: ImageVector? = null,
    haptic: Boolean = true,
    fill: Color = DS.accent,
) {
    val background by animateColorAsState(
        if (enabled) fill else fill.copy(alpha = 0.35f),
        DSMotion.snappy(),
        label = "courseCta",
    )
    Row(
        modifier = modifier
            .fillMaxWidth()
            .pressable(onClick = onClick, enabled = enabled, scaleDown = 0.96f, haptic = haptic)
            .clip(DS.controlShape)
            .background(background)
            .heightIn(min = 56.dp)
            .padding(vertical = 14.dp, horizontal = 14.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (leadingIcon != null) {
            Icon(leadingIcon, contentDescription = null, tint = Color.White, modifier = Modifier.size(18.dp))
        }
        Text(
            text = text,
            modifier = Modifier.weight(1f, fill = false),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 17.sp,
            color = Color.White,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center,
        )
        if (trailingIcon != null) {
            Icon(trailingIcon, contentDescription = null, tint = Color.White, modifier = Modifier.size(18.dp))
        }
    }
}

// endregion

// region Pills

/** A golden pill: « +50 XP gagnés ». */
@Composable
fun CourseGoldPill(
    text: String,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    fontSize: TextUnit = 13.sp,
) {
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(CoursePalette.goldTint)
            .padding(horizontal = 12.dp, vertical = 5.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (icon != null) {
            Icon(icon, contentDescription = null, tint = CoursePalette.goldDeep, modifier = Modifier.size(13.dp))
        }
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = fontSize,
            color = CoursePalette.goldInk,
            maxLines = 1,
        )
    }
}

/**
 * The combo pill of the quiz: a small flame and « x3 ». The flame bounces at each right
 * answer more.
 */
@Composable
fun CourseQuizComboPill(count: Int, modifier: Modifier = Modifier) {
    val bounce = remember { Animatable(1f) }
    LaunchedEffect(count) {
        bounce.snapTo(1.4f)
        bounce.animateTo(1f, DSMotion.pop())
    }
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(CoursePalette.goldTint)
            .padding(horizontal = 10.dp, vertical = 5.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = Icons.Filled.LocalFireDepartment,
            contentDescription = null,
            tint = CoursePalette.goldDeep,
            modifier = Modifier
                .size(14.dp)
                .graphicsLayer {
                    scaleX = bounce.value
                    scaleY = bounce.value
                },
        )
        Text(
            text = "x$count",
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 13.sp,
            color = CoursePalette.goldInk,
        )
    }
}

/** A red badge with a cross: the wrong answer. */
@Composable
fun CourseCrossBadge(modifier: Modifier = Modifier, size: Dp = 26.dp) {
    Box(
        modifier = modifier
            .size(size)
            .dsPopIn()
            .background(DS.danger, CircleShape)
            .clearAndSetSemantics { },
        contentAlignment = Alignment.Center,
    ) {
        Icon(Icons.Filled.Close, contentDescription = null, tint = Color.White, modifier = Modifier.size(size * 0.58f))
    }
}

// endregion

// region Subject

/** The round thumbnail of a subject: its illustration (`badge_subject_…`). */
@Composable
fun CourseSubjectAvatar(subject: Subject, modifier: Modifier = Modifier, size: Dp = 36.dp) {
    val image = when (subject) {
        Subject.HISTOIRE -> R.drawable.badge_subject_histoire
        Subject.SCIENCES -> R.drawable.badge_subject_sciences
        Subject.LITTERATURE -> R.drawable.badge_subject_litterature
        Subject.ART -> R.drawable.badge_subject_art
        Subject.MYTHOLOGIE -> R.drawable.badge_subject_mythologie
        Subject.COMPRENDRE_LE_MONDE -> R.drawable.badge_subject_comprendrelemonde
    }
    Image(
        painter = painterResource(image),
        contentDescription = null,
        contentScale = ContentScale.Crop,
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(DS.accentTint),
    )
}

// endregion

// region Quiz header

/** Top of a quiz: close, progress in segments, combo pill. */
@Composable
fun CourseQuizTopBar(
    total: Int,
    /** Number of filled segments (the current question included). */
    filled: Int,
    closeLabel: String,
    /** « Question 2 sur 8 », read by TalkBack on the bar. */
    progressLabel: String,
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
    /** Current combo; the pill only shows from 2. */
    combo: Int = 0,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(start = 24.dp, end = 24.dp, top = 10.dp, bottom = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        CourseRoundIconButton(icon = Icons.Filled.Close, onClick = onClose, contentDescription = closeLabel)
        Box(
            modifier = Modifier
                .weight(1f)
                .clearAndSetSemantics { contentDescription = progressLabel },
        ) {
            // One segment per question; beyond sixteen, a continuous bar (a long training
            // session would turn the segments into dots).
            if (total <= 16) {
                DSSegmentedProgress(total = total, filled = filled)
            } else {
                DSProgressBar(
                    value = filled.toFloat() / total.coerceAtLeast(1),
                    height = 6.dp,
                    track = DS.hairline.copy(alpha = 0.75f),
                )
            }
        }
        if (combo >= 2) {
            CourseQuizComboPill(count = combo, modifier = Modifier.dsPopIn())
        }
    }
}

/**
 * The statement: eyebrow « MATIÈRE · QUESTION n SUR N » with the subject thumbnail, then the
 * question centred in a light weight (the passages between `**` in bold blue).
 */
@Composable
fun CourseQuizQuestionHeader(
    subject: Subject?,
    eyebrow: String,
    question: String,
    modifier: Modifier = Modifier,
    /** A discreet line under the eyebrow (the course the question comes from). */
    caption: String? = null,
) {
    val size = when {
        question.length > 120 -> 20
        question.length > 70 -> 23
        else -> 26
    }
    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                if (subject != null) CourseSubjectAvatar(subject = subject, size = 20.dp)
                Text(
                    text = eyebrow.uppercaseInApp(),
                    modifier = Modifier.weight(1f, fill = false),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 12.sp,
                    letterSpacing = 0.8.sp,
                    color = DS.accent,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    textAlign = TextAlign.Center,
                )
            }
            if (!caption.isNullOrBlank()) {
                Text(
                    text = caption,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Medium,
                    fontSize = 13.sp,
                    lineHeight = 18.sp,
                    color = DS.inkSecondary,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    textAlign = TextAlign.Center,
                )
            }
        }
        DSHighlightTitle(
            text = question,
            modifier = Modifier.semantics { heading() },
            fontSize = size.sp,
            lineHeight = (size * 1.3f).sp,
        )
    }
}

// endregion

// region XP bar

/**
 * The golden XP bar. No animation of its own: the screen that shows it paces the filling.
 */
@Composable
fun CourseXPBar(fraction: Float, modifier: Modifier = Modifier, height: Dp = 8.dp) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(height)
            .clip(CircleShape)
            .background(CoursePalette.track)
            .clearAndSetSemantics { },
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth(fraction.coerceIn(0f, 1f))
                .fillMaxHeight()
                .clip(CircleShape)
                .background(CoursePalette.gold),
        )
    }
}

// endregion
