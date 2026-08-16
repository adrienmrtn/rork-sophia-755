package app.rork.sophia.ui.paywall

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.delay

/**
 * Shared paywall chrome, ported from the iOS native paywalls: one entry reveal, one close
 * button, one price line, one CTA, and the pieces each context adds on top.
 */

/** `HH:MM:SS` past an hour, `MM:SS` below — same as the iOS countdown. */
fun formatCountdown(totalSeconds: Long): String {
    val safe = totalSeconds.coerceAtLeast(0)
    val hours = safe / 3600
    val minutes = (safe % 3600) / 60
    val seconds = safe % 60
    return if (hours > 0) {
        String.format("%02d:%02d:%02d", hours, minutes, seconds)
    } else {
        String.format("%02d:%02d", minutes, seconds)
    }
}

/** Content fades and lifts in once, so a paywall never appears mid-animation. */
@Composable
fun PaywallEntry(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    var shown by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(50)
        shown = true
    }
    val progress by animateFloatAsState(
        targetValue = if (shown) 1f else 0f,
        animationSpec = spring(dampingRatio = 0.85f, stiffness = Spring.StiffnessMediumLow),
        label = "paywallEntry",
    )
    Box(
        modifier = modifier.graphicsLayer {
            alpha = progress
            translationY = (1f - progress) * 16.dp.toPx()
        },
    ) {
        content()
    }
}

/**
 * Close button. [delayMillis] holds it back the way iOS does on the quiz (4s) and course
 * unlock (2s) paywalls, so the offer is read before it can be dismissed.
 */
@Composable
fun PaywallCloseButton(
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
    delayMillis: Int = 0,
    light: Boolean = false,
) {
    var visible by remember { mutableStateOf(delayMillis == 0) }
    LaunchedEffect(delayMillis) {
        if (delayMillis > 0) {
            delay(delayMillis.toLong())
            visible = true
        }
    }
    AnimatedVisibility(visible = visible, enter = fadeIn(tween(400)), exit = fadeOut(), modifier = modifier) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .softPress(onClick = onClose)
                .clip(CircleShape)
                .background(if (light) Color.White.copy(alpha = 0.15f) else DS.surface)
                .then(if (light) Modifier else Modifier.border(1.dp, DS.hairline, CircleShape)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                Icons.Filled.Close,
                contentDescription = null,
                tint = if (light) Color.White else DS.inkSecondary,
                modifier = Modifier.size(17.dp),
            )
        }
    }
}

@Composable
fun PaywallHero(icon: ImageVector, modifier: Modifier = Modifier, size: androidx.compose.ui.unit.Dp = 92.dp) {
    Box(
        modifier = modifier.size(size).clip(CircleShape).background(DS.accentTint),
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, contentDescription = null, tint = DS.accent, modifier = Modifier.size(size * 0.47f))
    }
}

/** Course cover with the padlock badge, the hero of the "unlock this course" paywall. */
@Composable
fun PaywallCourseHero(courseId: String, modifier: Modifier = Modifier) {
    Box(modifier = modifier.size(104.dp), contentAlignment = Alignment.Center) {
        Box(
            modifier = Modifier
                .size(92.dp)
                .clip(DS.controlShape)
                .background(DS.surfaceMuted)
                .border(1.dp, DS.hairline, DS.controlShape),
        ) {
            CourseImage(
                courseId = courseId,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop,
                maxEdgePx = 360,
            )
        }
        Box(
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .size(32.dp)
                .clip(CircleShape)
                .background(Color.White)
                .padding(2.dp)
                .clip(CircleShape)
                .background(DS.accent),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.Lock, contentDescription = null, tint = Color.White, modifier = Modifier.size(15.dp))
        }
    }
}

@Composable
fun BenefitRow(text: String) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Icon(
            Icons.Filled.CheckCircle,
            contentDescription = null,
            tint = DS.success,
            modifier = Modifier.size(18.dp),
        )
        Text(
            text = text,
            style = SophiaTypography.bodyMedium.copy(color = DS.ink, fontWeight = FontWeight.Medium),
        )
    }
}

@Composable
fun PriceLine(text: String, modifier: Modifier = Modifier, light: Boolean = false) {
    Text(
        text = text,
        style = SophiaTypography.labelMedium.copy(fontSize = 12.sp),
        color = if (light) Color.White.copy(alpha = 0.85f) else DS.inkTertiary,
        textAlign = TextAlign.Center,
        modifier = modifier.fillMaxWidth(),
    )
}

@Composable
fun PurchaseButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    purchasing: Boolean = false,
    enabled: Boolean = true,
    leadingIcon: ImageVector? = null,
    fill: Color = DS.accent,
    contentColor: Color = Color.White,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .softPress(onClick = onClick, enabled = enabled && !purchasing)
            .clip(CircleShape)
            .background(if (enabled) fill else fill.copy(alpha = 0.4f))
            .padding(vertical = 17.dp, horizontal = 14.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (purchasing) {
            CircularProgressIndicator(
                color = contentColor,
                strokeWidth = 2.dp,
                modifier = Modifier.size(20.dp),
            )
        } else {
            if (leadingIcon != null) {
                Icon(leadingIcon, contentDescription = null, tint = contentColor, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(8.dp))
            }
            Text(
                text = text,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 17.sp,
                color = contentColor,
                maxLines = 2,
                textAlign = TextAlign.Center,
            )
        }
    }
}

/** Plan row of the comparison paywall: name and cadence left, price and trial right. */
@Composable
fun PlanSelectorCard(
    name: String,
    subtitle: String,
    price: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    trialBadge: String? = null,
    saveBadge: String? = null,
) {
    Box(modifier = modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .softPress(onClick = onClick)
                .clip(DS.controlShape)
                .background(if (selected) DS.accentSoft.copy(alpha = 0.08f) else DS.surface)
                .border(
                    width = if (selected) 2.dp else 1.dp,
                    color = if (selected) DS.accent else DS.hairline,
                    shape = DS.controlShape,
                )
                .padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(text = name, style = SophiaTypography.bodyLarge.copy(fontWeight = FontWeight.Bold))
                Text(text = subtitle, style = SophiaTypography.labelMedium)
            }
            Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(text = price, style = SophiaTypography.bodyLarge.copy(fontWeight = FontWeight.Bold))
                if (trialBadge != null) {
                    Text(
                        text = trialBadge,
                        style = SophiaTypography.labelMedium.copy(
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = DS.success,
                        ),
                    )
                }
            }
        }
        if (saveBadge != null) {
            Text(
                text = saveBadge,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 11.sp,
                color = Color.White,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(end = 12.dp)
                    .offset(y = (-9).dp)
                    .clip(CircleShape)
                    .background(DS.accent)
                    .padding(horizontal = 8.dp, vertical = 4.dp),
            )
        }
    }
}

/** Free vs Pro feature table. */
@Composable
fun ComparisonTable(
    features: List<String>,
    freeLabel: String,
    proLabel: String,
    modifier: Modifier = Modifier,
) {
    Column(modifier = modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Spacer(Modifier.weight(1f))
            Text(
                text = freeLabel,
                style = SophiaTypography.labelMedium.copy(fontSize = 12.sp, fontWeight = FontWeight.SemiBold),
                textAlign = TextAlign.Center,
                modifier = Modifier.width(72.dp),
            )
            Text(
                text = proLabel,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 12.sp,
                color = Color.White,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .width(72.dp)
                    .clip(CircleShape)
                    .background(DS.accent)
                    .padding(vertical = 4.dp),
            )
        }
        features.forEach { feature ->
            Row(
                modifier = Modifier.fillMaxWidth().padding(vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = feature,
                    style = SophiaTypography.bodyMedium.copy(color = DS.ink, fontWeight = FontWeight.Medium),
                    modifier = Modifier.weight(1f),
                )
                Box(modifier = Modifier.width(72.dp), contentAlignment = Alignment.Center) {
                    Icon(
                        Icons.Filled.Remove,
                        contentDescription = null,
                        tint = DS.inkTertiary,
                        modifier = Modifier.size(14.dp),
                    )
                }
                Box(modifier = Modifier.width(72.dp), contentAlignment = Alignment.Center) {
                    Icon(
                        Icons.Filled.CheckCircle,
                        contentDescription = null,
                        tint = DS.accent,
                        modifier = Modifier.size(18.dp),
                    )
                }
            }
            androidx.compose.material3.HorizontalDivider(color = DS.hairline)
        }
    }
}

/** « Prochain cours gratuit dans 07:12:44 », ticking every second. */
@Composable
fun CountdownCard(
    label: String,
    secondsRemaining: Long,
    modifier: Modifier = Modifier,
) {
    var remaining by remember(secondsRemaining) { mutableStateOf(secondsRemaining) }
    LaunchedEffect(secondsRemaining) {
        while (remaining > 0) {
            delay(1000)
            remaining -= 1
        }
    }
    Column(
        modifier = modifier.fillMaxWidth().sophiaCard().padding(vertical = 14.dp, horizontal = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Icon(
                Icons.Filled.Schedule,
                contentDescription = null,
                tint = DS.inkSecondary,
                modifier = Modifier.size(13.dp),
            )
            Text(
                text = label,
                style = SophiaTypography.labelMedium.copy(fontSize = 12.sp, fontWeight = FontWeight.SemiBold),
            )
        }
        Text(
            text = formatCountdown(remaining),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 22.sp,
            color = DS.ink,
        )
    }
}

/** Expandable question card. */
@Composable
fun FaqItem(
    question: String,
    answer: String,
    expanded: Boolean,
    onToggle: () -> Unit,
) {
    val rotation by animateFloatAsState(
        targetValue = if (expanded) 180f else 0f,
        animationSpec = spring(dampingRatio = 0.86f, stiffness = Spring.StiffnessMediumLow),
        label = "faqChevron",
    )
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .softPress(onClick = onToggle)
            .clip(DS.cardShape)
            .background(DS.surface)
            .border(
                1.dp,
                if (expanded) DS.accentSoft.copy(alpha = 0.35f) else DS.hairline,
                DS.cardShape,
            )
            .padding(16.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = question,
                style = SophiaTypography.bodyMedium.copy(color = DS.ink, fontWeight = FontWeight.SemiBold),
                modifier = Modifier.weight(1f),
            )
            Icon(
                Icons.Filled.ExpandMore,
                contentDescription = null,
                tint = DS.inkTertiary,
                modifier = Modifier.size(18.dp).graphicsLayer { rotationZ = rotation },
            )
        }
        AnimatedVisibility(visible = expanded) {
            Text(
                text = answer,
                style = SophiaTypography.labelMedium,
                modifier = Modifier.padding(top = 10.dp),
            )
        }
    }
}

/** Auto-advancing testimonials with page dots. */
@Composable
fun ReviewsCarousel(
    reviews: List<Pair<String, String>>,
    modifier: Modifier = Modifier,
) {
    if (reviews.isEmpty()) return
    var index by remember { mutableIntStateOf(0) }
    LaunchedEffect(reviews.size) {
        while (true) {
            delay(3200)
            index = (index + 1) % reviews.size
        }
    }
    Column(modifier = modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
        AnimatedContent(
            targetState = index,
            transitionSpec = { fadeIn(tween(320)) togetherWith fadeOut(tween(220)) },
            label = "review",
        ) { i ->
            val (quote, author) = reviews[i]
            Column(
                modifier = Modifier.fillMaxWidth().sophiaCard().padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Text("★★★★★", color = DS.warm, fontSize = 12.sp)
                Text(
                    text = quote,
                    style = SophiaTypography.bodyMedium.copy(color = DS.ink, fontWeight = FontWeight.Medium),
                )
                Text(text = author, style = SophiaTypography.labelMedium)
            }
        }
        Spacer(Modifier.height(10.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            reviews.indices.forEach { i ->
                Box(
                    modifier = Modifier
                        .size(if (i == index) 8.dp else 6.dp)
                        .clip(CircleShape)
                        .background(if (i == index) DS.accent else DS.hairline),
                )
            }
        }
    }
}

/** Big number + caption, used by the training and course-unlock paywalls. */
@Composable
fun PaywallStatCard(
    value: String,
    label: String,
    modifier: Modifier = Modifier,
    valueColor: Color = DS.accent,
) {
    Column(
        modifier = modifier.sophiaCard().padding(vertical = 18.dp, horizontal = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            text = value,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 28.sp,
            color = valueColor,
        )
        Text(text = label, style = SophiaTypography.labelMedium, textAlign = TextAlign.Center)
    }
}

@Composable
fun NumberedStepRow(number: Int, text: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(
            modifier = Modifier.size(26.dp).clip(CircleShape).background(DS.accent),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = "$number",
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 13.sp,
                color = Color.White,
            )
        }
        Text(
            text = text,
            style = SophiaTypography.bodyMedium.copy(color = DS.ink, fontWeight = FontWeight.Medium),
        )
    }
}

/** Struck-through regular price next to the promo price, on the discount paywall. */
@Composable
fun DiscountPriceBlock(regular: String?, promo: String, perYear: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            if (regular != null) {
                Text(
                    text = regular,
                    color = Color.White.copy(alpha = 0.7f),
                    textDecoration = TextDecoration.LineThrough,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 19.sp,
                )
            }
            Text(
                text = promo,
                color = Color.White,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 38.sp,
            )
        }
        Text(
            text = perYear,
            color = Color.White.copy(alpha = 0.85f),
            style = SophiaTypography.labelMedium.copy(fontWeight = FontWeight.SemiBold, color = Color.White),
        )
    }
}

/** Pulsing "ends in MM:SS" chip of the discount paywall. */
@Composable
fun DiscountCountdownChip(label: String, time: String) {
    val pulse by rememberInfiniteTransition(label = "discountPulse").animateFloat(
        initialValue = 1f,
        targetValue = 1.04f,
        animationSpec = infiniteRepeatable(tween(900), RepeatMode.Reverse),
        label = "chipPulse",
    )
    Row(
        modifier = Modifier
            .graphicsLayer { scaleX = pulse; scaleY = pulse }
            .clip(CircleShape)
            .background(DS.danger)
            .border(1.dp, Color.White.copy(alpha = 0.35f), CircleShape)
            .padding(horizontal = 16.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text("🔥", fontSize = 14.sp)
        Text(
            text = label.uppercase(),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 11.sp,
            letterSpacing = 0.5.sp,
            color = Color.White,
        )
        Text(
            text = time,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 16.sp,
            color = Color.White,
        )
    }
}

@Composable
fun PaywallLegalRow(
    language: AppLanguage,
    onRestore: () -> Unit,
    onTerms: () -> Unit,
    onPrivacy: () -> Unit,
    light: Boolean = false,
) {
    val context = LocalContext.current
    val color = if (light) Color.White.copy(alpha = 0.75f) else DS.inkTertiary
    Row(
        modifier = Modifier.fillMaxWidth().padding(top = 4.dp, bottom = 6.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        listOf(
            "paywall.restore" to onRestore,
            "paywall.terms" to onTerms,
            "paywall.privacy" to onPrivacy,
        ).forEachIndexed { index, (key, action) ->
            if (index > 0) Text("·", color = color, fontSize = 11.sp)
            Text(
                text = StringStore.text(context, key, language),
                style = SophiaTypography.labelMedium.copy(fontSize = 11.sp),
                color = color,
                modifier = Modifier
                    .softPress(onClick = action)
                    .padding(horizontal = 6.dp, vertical = 4.dp),
            )
        }
    }
}

/** Rating line reused by the quiz and course-unlock paywalls. */
@Composable
fun RatingLine(text: String, light: Boolean = false) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Text("★★★★★", color = DS.warm, fontSize = 11.sp)
        Text(
            text = "4,8 · $text",
            style = SophiaTypography.labelMedium.copy(fontSize = 11.sp),
            color = if (light) Color.White.copy(alpha = 0.8f) else DS.inkTertiary,
        )
    }
}

@Composable
fun CheckedFeatureRow(text: String) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Icon(Icons.Filled.Check, contentDescription = null, tint = DS.success, modifier = Modifier.size(15.dp))
        Text(text = text, style = SophiaTypography.bodyMedium)
    }
}

@Composable
fun PaywallErrorNote(message: String, light: Boolean = false) {
    Text(
        text = message,
        style = SophiaTypography.labelMedium.copy(fontSize = 12.sp),
        color = if (light) Color.White else DS.danger,
        textAlign = TextAlign.Center,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(if (light) Color.Black.copy(alpha = 0.2f) else DS.dangerTint)
            .padding(horizontal = 12.dp, vertical = 10.dp),
    )
}
