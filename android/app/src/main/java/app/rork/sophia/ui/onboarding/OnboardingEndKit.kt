package app.rork.sophia.ui.onboarding

import android.content.Context
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.drawOutline
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import app.rork.sophia.R
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Subject
import app.rork.sophia.ui.components.DSHighlightTitle
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.dsPopIn
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.legal.LegalDocKind
import app.rork.sophia.ui.theme.DS
import kotlinx.coroutines.delay

/**
 * Pieces shared by the last screens of the onboarding in the « Elevate arrondi » design
 * (course picks, 90-day curve, notifications, preparation, profile, account, teachers to
 * follow). The Android twin of the iOS `OnboardingV2EndKit.swift`.
 */
internal object OV2End {
    /** Side margin of the content, the one of the mock-ups. */
    val side = 24.dp

    /** Margin above the first block, under the header (back + progress) the coordinator lays over the screen. */
    val top = 22.dp

    /** Top margin of the screens after « Profile », which have no such header. */
    val topWithoutHeader = 36.dp

    /** Border of the pale blue cards (course pick, goal): the accent blue, much lightened. */
    val tintBorder = Color(0xFFC5D5F1)
}

/**
 * The text of [key], or [fallback] while the tables do not have the key yet: the new strings
 * of this design arrive in the tables separately, and a page must never show a raw key.
 */
internal fun ov2EndText(
    context: Context,
    key: String,
    language: AppLanguage,
    fallback: () -> String,
): String {
    val text = StringStore.text(context, key, language)
    return if (text == key) fallback() else text
}

// MARK: - Titles

/** Left-aligned title with its `**marked**` passage in bold blue (« Les cours qui **t'attendent** »). */
@Composable
internal fun OV2EndHighlightTitle(
    text: String,
    modifier: Modifier = Modifier,
    fontSize: TextUnit = 26.sp,
    lineHeight: TextUnit = 33.sp,
) {
    DSHighlightTitle(
        text = text,
        modifier = modifier.fillMaxWidth().semantics { heading() },
        fontSize = fontSize,
        lineHeight = lineHeight,
        textAlign = TextAlign.Start,
    )
}

/** Centred title of the announcement screens (medium weight, 23 on the mock-up). */
@Composable
internal fun OV2EndTitle(text: String, modifier: Modifier = Modifier) {
    Text(
        text = text,
        style = OV2.title.copy(
            fontWeight = FontWeight.Medium,
            fontSize = 23.sp,
            lineHeight = 30.sp,
            letterSpacing = 0.2.sp,
        ),
        textAlign = TextAlign.Center,
        modifier = modifier.fillMaxWidth().semantics { heading() },
    )
}

/** Centred secondary text under an [OV2EndTitle]. */
@Composable
internal fun OV2EndSubtitle(text: String, modifier: Modifier = Modifier) {
    Text(
        text = text,
        style = OV2.subheadline.copy(fontWeight = FontWeight.Normal, lineHeight = 22.sp),
        textAlign = TextAlign.Center,
        modifier = modifier.fillMaxWidth(),
    )
}

// MARK: - Stars

/** Five amber stars that land one after the other. */
@Composable
internal fun OV2EndStars(
    modifier: Modifier = Modifier,
    size: Dp = 17.dp,
    spacing: Dp = 2.dp,
    baseDelayMillis: Int = 100,
) {
    Row(
        modifier = modifier.clearAndSetSemantics { },
        horizontalArrangement = Arrangement.spacedBy(spacing),
    ) {
        repeat(5) { index ->
            Icon(
                Icons.Filled.Star,
                contentDescription = null,
                tint = DS.warm,
                modifier = Modifier.size(size).dsPopIn(delayMillis = baseDelayMillis + index * 70),
            )
        }
    }
}

// MARK: - Card

/**
 * The card of the style (white, 1.5 dp border, small bottom edge, no shadow) with no padding
 * of its own, and a [fill] / [border] pair for the tinted variants.
 */
internal fun Modifier.ov2EndCard(
    shape: Shape = DS.cardShape,
    fill: Color = DS.surface,
    border: Color = DS.hairline,
): Modifier = this
    .drawBehind {
        val outline = shape.createOutline(size, layoutDirection, this)
        translate(top = 1.5.dp.toPx()) { drawOutline(outline, border) }
    }
    .clip(shape)
    .background(fill)
    .border(1.5.dp, border, shape)

/**
 * A fade to the page background, laid just above a pinned call to action so the list that
 * scrolls under it dissolves instead of being cut off.
 */
@Composable
internal fun OV2EndBottomFade(modifier: Modifier = Modifier, height: Dp = 44.dp) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(height)
            .offset(y = -height)
            .background(Brush.verticalGradient(listOf(DS.canvas.copy(alpha = 0f), DS.canvas)))
            .clearAndSetSemantics { },
    )
}

// MARK: - People

/** Overlapping round portraits ringed in white: the readers quoted by the preparation page. */
@Composable
internal fun OV2EndPhotoRow(photos: List<String>, modifier: Modifier = Modifier, size: Dp = 36.dp) {
    Row(
        modifier = modifier.clearAndSetSemantics { },
        horizontalArrangement = Arrangement.spacedBy(-(size * 0.28f)),
    ) {
        photos.forEachIndexed { index, url ->
            Box(
                modifier = Modifier
                    .zIndex((photos.size - index).toFloat())
                    .size(size)
                    .clip(CircleShape)
                    .background(DS.accentTint)
                    .border(2.dp, DS.canvas, CircleShape),
            ) {
                AssetPicture(url = url, modifier = Modifier.fillMaxSize().padding(2.dp).clip(CircleShape))
            }
        }
    }
}

/** The round badge of a subject: its illustration on a disc of its colour. */
@Composable
internal fun OV2EndSubjectBadge(subject: Subject, modifier: Modifier = Modifier, size: Dp = 24.dp) {
    Image(
        painter = painterResource(subjectBadgeRes(subject)),
        contentDescription = null,
        contentScale = ContentScale.Crop,
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(subject.color.copy(alpha = 0.18f)),
    )
}

private fun subjectBadgeRes(subject: Subject): Int = when (subject) {
    Subject.HISTOIRE -> R.drawable.badge_subject_histoire
    Subject.SCIENCES -> R.drawable.badge_subject_sciences
    Subject.LITTERATURE -> R.drawable.badge_subject_litterature
    Subject.ART -> R.drawable.badge_subject_art
    Subject.MYTHOLOGIE -> R.drawable.badge_subject_mythologie
    Subject.COMPRENDRE_LE_MONDE -> R.drawable.badge_subject_comprendrelemonde
}

/**
 * The round illustration of the sign-in screens: a reader among their books, from the app's
 * avatar series. It lands with a bounce.
 */
@Composable
internal fun OV2EndAccountIllustration(size: Dp, modifier: Modifier = Modifier) {
    var shown by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(150)
        shown = true
    }
    val progress by animateFloatAsState(if (shown) 1f else 0f, DSMotion.pop(), label = "accountIllustration")
    Image(
        painter = painterResource(R.drawable.avatar_04),
        contentDescription = null,
        contentScale = ContentScale.Crop,
        modifier = modifier
            .size(size)
            .graphicsLayer {
                val scale = 0.7f + 0.3f * progress
                scaleX = scale
                scaleY = scale
                alpha = progress.coerceIn(0f, 1f)
            }
            .clip(CircleShape),
    )
}

// MARK: - Legal

/**
 * « By continuing, you agree to our Terms · Privacy »: signing in creates the account when
 * there is none, so the terms belong on the page. The two links open the host's documents.
 */
@Composable
internal fun OV2EndLegalNote(
    language: AppLanguage,
    onOpen: (LegalDocKind) -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    Column(modifier = modifier, horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = StringStore.text(context, "auth.legal.prefix", language),
            style = OV2.caption.copy(fontSize = 12.sp, fontWeight = FontWeight.Normal),
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 32.dp),
        )
        Row(verticalAlignment = Alignment.CenterVertically) {
            LegalLink(StringStore.text(context, "legal.terms.title", language)) { onOpen(LegalDocKind.Terms) }
            Text("·", style = OV2.caption.copy(fontSize = 12.sp, fontWeight = FontWeight.Normal))
            LegalLink(StringStore.text(context, "legal.privacy.title", language)) { onOpen(LegalDocKind.Privacy) }
        }
    }
}

@Composable
private fun LegalLink(text: String, onClick: () -> Unit) {
    Text(
        text = text,
        style = OV2.caption.copy(fontSize = 12.sp, color = DS.ink),
        modifier = Modifier
            .pressable(onClick = onClick, haptic = false)
            .padding(horizontal = 6.dp, vertical = 6.dp),
    )
}
