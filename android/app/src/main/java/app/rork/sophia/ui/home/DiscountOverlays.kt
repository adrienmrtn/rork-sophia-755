package app.rork.sophia.ui.home

import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.DiscountState
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.delay

private const val TAPS_TO_OPEN = 3

@Composable
fun DiscountGiftOverlay(
    language: AppLanguage,
    onOpened: () -> Unit,
) {
    val context = LocalContext.current
    var taps by remember { mutableIntStateOf(0) }
    var opened by remember { mutableStateOf(false) }
    var appeared by remember { mutableStateOf(false) }
    var bounce by remember { mutableStateOf(false) }
    var backdrop by remember { mutableFloatStateOf(0f) }

    LaunchedEffect(Unit) {
        backdrop = 0.45f
        appeared = true
    }

    LaunchedEffect(opened) {
        if (!opened) return@LaunchedEffect
        delay(420)
        onOpened()
    }

    val cardScale by animateFloatAsState(
        targetValue = if (appeared) 1f else 0.9f,
        animationSpec = spring(dampingRatio = 0.78f, stiffness = Spring.StiffnessMediumLow),
        label = "giftCard",
    )
    val iconScale by animateFloatAsState(
        targetValue = if (bounce) 1.08f else 1f,
        animationSpec = spring(dampingRatio = 0.45f, stiffness = Spring.StiffnessMedium),
        label = "giftIcon",
    )
    val progress = taps.coerceAtMost(TAPS_TO_OPEN) / TAPS_TO_OPEN.toFloat()
    val ringProgress by animateFloatAsState(
        targetValue = progress,
        animationSpec = spring(dampingRatio = 0.8f, stiffness = Spring.StiffnessMedium),
        label = "giftRing",
    )
    val dim by animateFloatAsState(
        targetValue = backdrop,
        animationSpec = tween(350),
        label = "giftDim",
    )

    fun tapGift() {
        if (opened) return
        taps += 1
        bounce = true
        if (taps >= TAPS_TO_OPEN) {
            opened = true
        }
    }

    LaunchedEffect(bounce) {
        if (bounce) {
            delay(180)
            bounce = false
        }
    }

    val prompt = when {
        opened -> ""
        taps == 0 -> StringStore.text(context, "discount.gift.tapToOpen", language)
        taps >= TAPS_TO_OPEN - 1 -> StringStore.text(context, "discount.gift.almost", language)
        else -> StringStore.text(context, "discount.gift.keepTapping", language)
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = dim))
            .clickable(
                indication = null,
                interactionSource = remember { MutableInteractionSource() },
                onClick = { tapGift() },
            ),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            modifier = Modifier
                .padding(horizontal = 32.dp)
                .scale(cardScale)
                .clip(DS.cardShape)
                .background(DS.surface)
                .padding(horizontal = 24.dp, vertical = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(22.dp),
        ) {
            if (!opened) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = StringStore.text(context, "discount.gift.title", language),
                        style = SophiaTypography.titleLarge,
                        textAlign = TextAlign.Center,
                    )
                    Spacer(Modifier.height(8.dp))
                    Text(
                        text = prompt,
                        style = SophiaTypography.bodyMedium,
                        textAlign = TextAlign.Center,
                        color = DS.inkSecondary,
                    )
                }
            }

            Box(
                modifier = Modifier
                    .size(128.dp)
                    .scale(iconScale)
                    .clickable(
                        indication = null,
                        interactionSource = remember { MutableInteractionSource() },
                        onClick = { tapGift() },
                    ),
                contentAlignment = Alignment.Center,
            ) {
                Canvas(modifier = Modifier.fillMaxSize()) {
                    val stroke = 8.dp.toPx()
                    drawCircle(
                        color = DS.hairline,
                        style = Stroke(width = stroke),
                    )
                    drawArc(
                        color = DS.accent,
                        startAngle = -90f,
                        sweepAngle = 360f * ringProgress,
                        useCenter = false,
                        style = Stroke(width = stroke, cap = StrokeCap.Round),
                    )
                }
                Box(
                    modifier = Modifier
                        .size(100.dp)
                        .clip(CircleShape)
                        .background(DS.accentTint),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(if (opened) "🎁" else "🎀", fontSize = 42.sp)
                }
            }

            if (!opened) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    repeat(TAPS_TO_OPEN) { i ->
                        Box(
                            modifier = Modifier
                                .width(28.dp)
                                .height(6.dp)
                                .clip(RoundedCornerShape(3.dp))
                                .background(if (i < taps) DS.accent else DS.hairline),
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun DiscountSideTab(
    state: DiscountState,
    onClick: () -> Unit,
) {
    Box(
        modifier = Modifier
            .fillMaxHeight()
            .padding(vertical = 120.dp),
        contentAlignment = Alignment.CenterEnd,
    ) {
        Column(
            modifier = Modifier
                .width(52.dp)
                .clip(RoundedCornerShape(topStart = 12.dp, bottomStart = 12.dp))
                .background(DS.accent)
                .clickable(onClick = onClick)
                .padding(vertical = 14.dp, horizontal = 6.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                "OFFRE",
                color = Color.White,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 11.sp,
            )
            Text(
                state.formattedRemaining,
                color = Color.White,
                fontFamily = PlusJakartaSans,
                fontSize = 11.sp,
                modifier = Modifier.padding(top = 6.dp),
            )
        }
    }
}
