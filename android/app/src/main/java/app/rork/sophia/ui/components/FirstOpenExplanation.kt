package app.rork.sophia.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.delay

@Composable
fun FirstOpenExplanation(
    language: AppLanguage,
    icon: String,
    titleKey: String,
    bodyKey: String,
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    var dim by remember { mutableFloatStateOf(0f) }
    var showIcon by remember { mutableStateOf(false) }
    var showTitle by remember { mutableStateOf(false) }
    var showMessage by remember { mutableStateOf(false) }
    var showHint by remember { mutableStateOf(false) }
    var leaving by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        dim = 0.64f
        delay(400)
        showIcon = true
        delay(500)
        showTitle = true
        delay(550)
        showMessage = true
        delay(750)
        showHint = true
    }

    val iconScale by animateFloatAsState(if (showIcon) 1f else 0.7f, tween(450), label = "icon")
    val iconAlpha by animateFloatAsState(if (showIcon && !leaving) 1f else 0f, tween(400), label = "ia")
    val titleAlpha by animateFloatAsState(if (showTitle && !leaving) 1f else 0f, tween(400), label = "ta")
    val msgAlpha by animateFloatAsState(if (showMessage && !leaving) 1f else 0f, tween(400), label = "ma")
    val hintAlpha by animateFloatAsState(if (showHint && !leaving) 1f else 0f, tween(400), label = "ha")
    val dimAnim by animateFloatAsState(if (leaving) 0f else dim, tween(400), label = "dim")

    fun dismiss() {
        if (leaving || dim < 0.3f) return
        leaving = true
    }

    LaunchedEffect(leaving) {
        if (!leaving) return@LaunchedEffect
        delay(380)
        onDismiss()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = dimAnim))
            .clickable(
                indication = null,
                interactionSource = remember { MutableInteractionSource() },
                onClick = { dismiss() },
            ),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(horizontal = 44.dp),
        ) {
            Box(
                modifier = Modifier
                    .size(96.dp)
                    .scale(iconScale)
                    .alpha(iconAlpha)
                    .clip(CircleShape)
                    .background(Color.White.copy(alpha = 0.10f)),
                contentAlignment = Alignment.Center,
            ) {
                Text(icon, fontSize = 34.sp)
            }
            Spacer(Modifier.height(26.dp))
            Text(
                text = StringStore.text(context, titleKey, language),
                style = SophiaTypography.titleLarge,
                color = Color.White,
                textAlign = TextAlign.Center,
                modifier = Modifier.alpha(titleAlpha),
            )
            Spacer(Modifier.height(14.dp))
            Text(
                text = StringStore.text(context, bodyKey, language),
                style = SophiaTypography.bodyLarge,
                color = Color.White.copy(alpha = 0.82f),
                textAlign = TextAlign.Center,
                modifier = Modifier.alpha(msgAlpha),
            )
        }
        Text(
            text = StringStore.text(context, "explain.tapToClose", language),
            fontFamily = PlusJakartaSans,
            color = Color.White.copy(alpha = 0.6f),
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 48.dp)
                .alpha(hintAlpha),
        )
    }
}
