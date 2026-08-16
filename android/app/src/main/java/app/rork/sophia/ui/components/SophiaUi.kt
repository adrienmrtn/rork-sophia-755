package app.rork.sophia.ui.components

import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography

/**
 * The pieces the iOS app gets from `dsCard()`, `DSPrimaryButtonStyle` and
 * `SoftPressButtonStyle`. Android had none of them, so screens ended up as bare text on
 * the canvas; this is the shared chrome every tab now draws from.
 */

/** Surface, rounded corners, hairline border and the gentle diffuse elevation. */
fun Modifier.sophiaCard(
    shape: Shape = DS.cardShape,
    fill: Color = DS.surface,
    elevation: Dp = 6.dp,
    border: Boolean = true,
): Modifier = this
    .shadow(
        elevation = elevation,
        shape = shape,
        ambientColor = Color.Black.copy(alpha = 0.28f),
        spotColor = Color.Black.copy(alpha = 0.24f),
    )
    .clip(shape)
    .background(fill)
    .then(if (border) Modifier.border(1.dp, DS.hairline, shape) else Modifier)

/** Press feedback of the iOS `SoftPressButtonStyle`: a touch of scale and opacity. */
@Composable
fun Modifier.softPress(
    onClick: () -> Unit,
    enabled: Boolean = true,
    scaleDown: Float = 0.98f,
): Modifier {
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = if (pressed) scaleDown else 1f,
        animationSpec = spring(dampingRatio = 0.8f, stiffness = Spring.StiffnessMedium),
        label = "press",
    )
    return this
        .graphicsLayer {
            scaleX = scale
            scaleY = scale
            alpha = if (pressed) 0.94f else 1f
        }
        .clickable(
            interactionSource = interaction,
            indication = null,
            enabled = enabled,
            onClick = onClick,
        )
}

@Composable
fun SophiaPrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    leadingIcon: ImageVector? = null,
    fill: Color = DS.accent,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .softPress(onClick = onClick, enabled = enabled)
            .clip(CircleShape)
            .background(if (enabled) fill else fill.copy(alpha = 0.35f))
            .padding(vertical = 17.dp, horizontal = 14.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (leadingIcon != null) {
            Icon(leadingIcon, contentDescription = null, tint = Color.White, modifier = Modifier.size(18.dp))
            Spacer(Modifier.size(8.dp))
        }
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 17.sp,
            color = Color.White,
            maxLines = 2,
            textAlign = TextAlign.Center,
        )
    }
}

@Composable
fun SophiaSecondaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    contentColor: Color = DS.ink,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .softPress(onClick = onClick, enabled = enabled)
            .clip(CircleShape)
            .background(DS.surface)
            .border(1.dp, DS.hairline, CircleShape)
            .padding(vertical = 16.dp, horizontal = 14.dp),
        horizontalArrangement = Arrangement.Center,
    ) {
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Medium,
            fontSize = 17.sp,
            color = contentColor,
            maxLines = 2,
            textAlign = TextAlign.Center,
        )
    }
}

/** Uppercase eyebrow above a section, tracked out like the iOS section labels. */
@Composable
fun SectionLabel(text: String, modifier: Modifier = Modifier, color: Color = DS.inkTertiary) {
    Text(
        text = text.uppercase(),
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.SemiBold,
        fontSize = 11.sp,
        letterSpacing = 1.2.sp,
        color = color,
        modifier = modifier,
    )
}

@Composable
fun ScreenTitle(text: String, modifier: Modifier = Modifier) {
    Text(
        text = text,
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 32.sp,
        color = DS.ink,
        modifier = modifier,
    )
}

/** Rounded track + fill, the shape used by every progress indicator on iOS. */
@Composable
fun CalmProgressBar(
    fraction: Float,
    modifier: Modifier = Modifier,
    height: Dp = 6.dp,
    color: Color = DS.accent,
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(height)
            .clip(CircleShape)
            .background(DS.hairline),
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth(fraction.coerceIn(0f, 1f))
                .height(height)
                .clip(CircleShape)
                .background(color),
        )
    }
}

@Composable
fun CircleIconButton(
    icon: ImageVector,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    size: Dp = 40.dp,
    tint: Color = DS.inkSecondary,
    background: Color = DS.surface,
) {
    Box(
        modifier = modifier
            .size(size)
            .softPress(onClick = onClick)
            .clip(CircleShape)
            .background(background)
            .border(1.dp, DS.hairline, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(size * 0.4f))
    }
}

/** Icon in a tinted round-rect, the leading element of most iOS list rows. */
@Composable
fun TintedIconBox(
    icon: ImageVector,
    modifier: Modifier = Modifier,
    size: Dp = 40.dp,
    shape: Shape = DS.controlShape,
    tint: Color = DS.accentSoft,
    background: Color = DS.accentTint,
) {
    Box(
        modifier = modifier.size(size).clip(shape).background(background),
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(size * 0.44f))
    }
}

@Composable
fun Pill(
    text: String,
    modifier: Modifier = Modifier,
    background: Color = DS.accentTint,
    contentColor: Color = DS.accentSoft,
    borderColor: Color? = null,
    uppercase: Boolean = false,
) {
    Text(
        text = if (uppercase) text.uppercase() else text,
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.SemiBold,
        fontSize = 11.sp,
        letterSpacing = if (uppercase) 1.sp else 0.sp,
        color = contentColor,
        modifier = modifier
            .clip(CircleShape)
            .background(background)
            .then(if (borderColor != null) Modifier.border(1.dp, borderColor, CircleShape) else Modifier)
            .padding(horizontal = 10.dp, vertical = 5.dp),
    )
}

/** Centred icon + title + subtitle, used wherever a list can come back empty. */
@Composable
fun SophiaEmptyState(
    icon: ImageVector,
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    action: (@Composable () -> Unit)? = null,
) {
    Column(
        modifier = modifier.fillMaxWidth().padding(horizontal = 32.dp, vertical = 40.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier.size(96.dp).clip(CircleShape).background(DS.accentTint),
            contentAlignment = Alignment.Center,
        ) {
            Icon(icon, contentDescription = null, tint = DS.accentSoft, modifier = Modifier.size(40.dp))
        }
        Spacer(Modifier.height(20.dp))
        Text(
            text = title,
            style = SophiaTypography.titleMedium,
            textAlign = TextAlign.Center,
        )
        if (subtitle != null) {
            Spacer(Modifier.height(8.dp))
            Text(
                text = subtitle,
                style = SophiaTypography.bodyMedium,
                textAlign = TextAlign.Center,
            )
        }
        if (action != null) {
            Spacer(Modifier.height(20.dp))
            action()
        }
    }
}

/** Square metric card: icon, big number, caption. */
@Composable
fun StatTile(
    icon: ImageVector,
    value: String,
    label: String,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier.sophiaCard().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        TintedIconBox(icon = icon, size = 38.dp, shape = CircleShape)
        Text(
            text = value,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 26.sp,
            color = DS.ink,
        )
        Text(
            text = label,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Medium,
            fontSize = 12.sp,
            color = DS.inkSecondary,
        )
    }
}
