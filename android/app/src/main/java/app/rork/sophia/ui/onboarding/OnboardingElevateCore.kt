package app.rork.sophia.ui.onboarding

import android.content.Context
import android.provider.Settings
import androidx.annotation.DrawableRes
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathMeasure
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawOutline
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.toggleableState
import androidx.compose.ui.state.ToggleableState
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.R
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Subject
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.DSOptionState
import app.rork.sophia.ui.components.dsOptionCard
import app.rork.sophia.ui.components.dsPopIn
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.theme.DS

/**
 * Pieces shared by the middle of the onboarding (first name → reviews, mission, welcome
 * aboard) in the « Elevate arrondi » style, the Android twin of the iOS
 * `OnboardingV2ElevateCore.swift`: page container, titles, round illustration, option row and
 * its check square. What the whole app shares stays in `ElevateKit`; only what makes sense for
 * these screens lives here.
 */
internal object OV2Core {
    /**
     * Gap between the header of the flow (back arrow + progress bar, laid out by the
     * coordinator above the page) and the title of the page.
     */
    val topInset: Dp = 20.dp

    /** Side margin of the pages. */
    val sideInset: Dp = 24.dp

    /**
     * Size of the round illustration for the room really left: full size when everything
     * fits, smaller on a short screen or with the keyboard up, absent (0) when only a
     * thumbnail would remain. [reserved] is the height of the rest of the page.
     */
    fun artSize(base: Dp, available: Dp, reserved: Dp): Dp {
        val room = available - reserved
        if (room >= base) return base
        return if (room >= 64.dp) room else 0.dp
    }

    /**
     * The existing title [titleKey] with its strong passage wrapped in `**` (drawn in bold
     * blue by `DSHighlightTitle`). The passage comes from the table, language by language;
     * when it is missing or no longer part of the title, the title comes back as it is.
     */
    fun marked(context: Context, titleKey: String, highlightKey: String, language: AppLanguage): String {
        val title = StringStore.text(context, titleKey, language)
        if (title.contains("**")) return title
        val passage = StringStore.text(context, highlightKey, language)
        if (passage == highlightKey || passage.isBlank()) return title
        val start = title.indexOf(passage)
        if (start < 0) return title
        return title.substring(0, start) + "**" + passage + "**" + title.substring(start + passage.length)
    }

    /** [text] without the given trailing punctuation (the full stop of a sentence set in a chip). */
    fun trimmingTrailing(text: String, characters: String): String =
        text.trim().trimEnd { it in characters || it.isWhitespace() }
}

/** `true` when the system has animations turned off (« Remove animations »). */
@Composable
internal fun rememberOV2CoreReducedMotion(): Boolean {
    val context = LocalContext.current
    return remember(context) {
        runCatching {
            Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f
        }.getOrDefault(false)
    }
}

// region Page

/**
 * Scrolling content with a pinned footer, like `OnboardingPage`, but handing the content the
 * height really available: pages use it to shrink their illustration on a short screen (or
 * with the keyboard up) rather than scroll, and `Spacer(Modifier.weight(1f))` shares what is
 * left, so a block can sit in the middle when there is room.
 */
@Composable
internal fun OV2CorePage(
    modifier: Modifier = Modifier,
    footer: @Composable ColumnScope.() -> Unit,
    content: @Composable ColumnScope.(availableHeight: Dp) -> Unit,
) {
    Column(
        modifier = modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        BoxWithConstraints(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .readableWidth(),
        ) {
            val available = maxHeight
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .heightIn(min = available),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                content(available)
            }
        }
        Column(
            modifier = Modifier.fillMaxWidth().readableWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            content = footer,
        )
    }
}

// endregion

// region Titles

/** Style of the centred title of a question page: medium weight, 23 sp. */
internal val ov2CoreTitleStyle: TextStyle
    @Composable @ReadOnlyComposable
    get() = OV2.title.copy(
        fontWeight = FontWeight.Medium,
        fontSize = 23.sp,
        lineHeight = 31.sp,
        letterSpacing = 0.2.sp,
        color = DS.ink,
    )

/** Style of the grey text under a title. */
internal val ov2CoreSubtitleStyle: TextStyle
    @Composable @ReadOnlyComposable
    get() = OV2.body.copy(
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp,
        lineHeight = 21.sp,
        color = DS.inkSecondary,
    )

/** Centred title of a question page and its grey subtitle. */
@Composable
internal fun OV2CoreQuestionTitle(
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    horizontalInset: Dp = OV2Core.sideInset,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = horizontalInset),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            text = title,
            style = ov2CoreTitleStyle,
            textAlign = TextAlign.Center,
            modifier = Modifier.semantics { heading() },
        )
        if (subtitle != null) {
            Text(text = subtitle, style = ov2CoreSubtitleStyle, textAlign = TextAlign.Center)
        }
    }
}

/** « Tap to continue », on the pages without a button. */
@Composable
internal fun OV2CoreTapHint(text: String, modifier: Modifier = Modifier) {
    Text(
        text = text,
        style = OV2.subheadline.copy(fontWeight = FontWeight.SemiBold, color = DS.inkSecondary),
        textAlign = TextAlign.Center,
        modifier = modifier.padding(horizontal = OV2Core.sideInset),
    )
}

/**
 * Text style of the sentences set very large (« Let's personalize your content », « turn that
 * time into… »): the largest that keeps the longest word on one line of [width], the user's
 * font scale included. The words are laid one by one at a fixed width, so a word wider than
 * the screen would be cut.
 */
@Composable
internal fun ov2CoreSentenceStyle(words: List<String>, width: Dp): TextStyle {
    val fontScale = LocalDensity.current.fontScale
    val longest = words.maxOfOrNull { it.length } ?: 0
    // Average width of a character in a heavy weight: about 0.64 em.
    val size = listOf(32, 28, 24).firstOrNull { longest * 0.64f * it * fontScale <= width.value } ?: 21
    return OV2.titleLarge.copy(fontSize = size.sp, lineHeight = (size * 1.24f).sp, color = DS.ink)
}

// endregion

// region Illustrations

/** Round illustration of a page, on the pale blue of the style while it decodes. */
@Composable
internal fun OV2CoreIllustration(@DrawableRes art: Int, size: Dp, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(DS.accentTint)
            .clearAndSetSemantics { },
    ) {
        Image(
            painter = painterResource(art),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxSize(),
        )
    }
}

@DrawableRes
private fun subjectBadgeRes(subject: Subject): Int = when (subject) {
    Subject.HISTOIRE -> R.drawable.badge_subject_histoire
    Subject.SCIENCES -> R.drawable.badge_subject_sciences
    Subject.LITTERATURE -> R.drawable.badge_subject_litterature
    Subject.ART -> R.drawable.badge_subject_art
    Subject.MYTHOLOGIE -> R.drawable.badge_subject_mythologie
    Subject.COMPRENDRE_LE_MONDE -> R.drawable.badge_subject_comprendrelemonde
}

/** Round thumbnail of a subject: the picture of its badge on a tint of its colour. */
@Composable
internal fun OV2CoreSubjectBadge(subject: Subject, modifier: Modifier = Modifier, size: Dp = 30.dp) {
    Box(
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(subject.color.copy(alpha = 0.18f))
            .clearAndSetSemantics { },
    ) {
        Image(
            painter = painterResource(subjectBadgeRes(subject)),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxSize(),
        )
    }
}

/** Five amber stars landing one after the other. */
@Composable
internal fun OV2CoreStars(
    modifier: Modifier = Modifier,
    size: Dp = 17.dp,
    spacing: Dp = 2.dp,
    baseDelayMillis: Int = 100,
    animated: Boolean = true,
) {
    Row(
        modifier = modifier.clearAndSetSemantics { },
        horizontalArrangement = Arrangement.spacedBy(spacing),
    ) {
        repeat(5) { index ->
            Icon(
                imageVector = Icons.Filled.Star,
                contentDescription = null,
                tint = DS.warm,
                modifier = Modifier
                    .then(if (animated) Modifier.dsPopIn(baseDelayMillis + index * 70) else Modifier)
                    .size(size),
            )
        }
    }
}

// endregion

// region Surfaces

/**
 * The outlined surface of the style for a field or a secondary button: fill, 1.5 dp border in
 * [edge] and the small bottom lip in the same colour. Adds no padding.
 */
internal fun Modifier.ov2CoreOutlined(
    edge: Color,
    fill: Color,
    shape: Shape = DS.controlShape,
    lip: Dp = 1.5.dp,
): Modifier = this
    .drawBehind {
        val outline = shape.createOutline(size, layoutDirection, this)
        translate(top = lip.toPx()) { drawOutline(outline, edge) }
    }
    .clip(shape)
    .background(fill)
    .border(1.5.dp, edge, shape)

// endregion

// region Options

/** Square box of a multiple choice: the check draws itself as the box fills. */
@Composable
internal fun OV2CoreCheckSquare(isOn: Boolean, modifier: Modifier = Modifier, size: Dp = 22.dp) {
    val accent = DS.accent
    val fill by animateColorAsState(if (isOn) accent else accent.copy(alpha = 0f), DSMotion.snappy(), label = "checkSquareFill")
    val edge by animateColorAsState(if (isOn) accent else DS.inkTertiary, DSMotion.snappy(), label = "checkSquareEdge")
    val stroke by animateFloatAsState(if (isOn) 1f else 0f, tween(durationMillis = 220), label = "checkSquareStroke")
    val pop by animateFloatAsState(if (isOn) 1f else 0.92f, DSMotion.pop(), label = "checkSquarePop")
    Canvas(
        modifier = modifier
            .size(size)
            .graphicsLayer {
                scaleX = pop
                scaleY = pop
            }
            .clearAndSetSemantics { },
    ) {
        val radius = 5.dp.toPx()
        val border = 1.5.dp.toPx()
        drawRoundRect(color = fill, cornerRadius = CornerRadius(radius))
        drawRoundRect(
            color = edge,
            topLeft = Offset(border / 2f, border / 2f),
            size = Size(this.size.width - border, this.size.height - border),
            cornerRadius = CornerRadius(radius - border / 2f),
            style = Stroke(width = border),
        )
        if (stroke > 0f) {
            val inset = this.size.minDimension * 0.25f
            val w = this.size.width - inset * 2
            val h = this.size.height - inset * 2
            val full = Path().apply {
                moveTo(inset, inset + h * 0.55f)
                lineTo(inset + w * 0.36f, inset + h * 0.92f)
                lineTo(inset + w, inset + h * 0.12f)
            }
            val measure = PathMeasure().apply { setPath(full, false) }
            val partial = Path()
            measure.getSegment(0f, measure.length * stroke.coerceIn(0f, 1f), partial, true)
            drawPath(
                path = partial,
                color = Color.White,
                style = Stroke(width = 2.4.dp.toPx(), cap = StrokeCap.Round, join = StrokeJoin.Round),
            )
        }
    }
}

/**
 * One answer among others: optional pictogram, label, and a box on the right for multiple
 * choices. The background is the option card of the style (`dsOptionCard`), the haptic that
 * of a choice.
 */
@Composable
internal fun OV2CoreOptionRow(
    label: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    showsCheckbox: Boolean = false,
    minHeight: Dp = 52.dp,
    leading: (@Composable () -> Unit)? = null,
) {
    val haptics = rememberHaptics()
    Row(
        modifier = modifier
            .fillMaxWidth()
            .semantics {
                if (showsCheckbox) {
                    role = Role.Checkbox
                    toggleableState = ToggleableState(selected)
                } else {
                    role = Role.RadioButton
                    this.selected = selected
                }
            }
            // The haptic of a choice replaces the one of the press.
            .pressable(
                onClick = {
                    haptics.select()
                    onClick()
                },
                haptic = false,
            )
            .dsOptionCard(if (selected) DSOptionState.Selected else DSOptionState.Idle)
            .heightIn(min = minHeight)
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        leading?.invoke()
        Text(
            text = label,
            style = OV2.body.copy(
                color = DS.ink,
                fontWeight = FontWeight.SemiBold,
                fontSize = 15.sp,
                lineHeight = 20.sp,
                letterSpacing = 0.2.sp,
            ),
            modifier = Modifier.weight(1f),
        )
        if (showsCheckbox) {
            OV2CoreCheckSquare(isOn = selected)
        }
    }
}

// endregion
