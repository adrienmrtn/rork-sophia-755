package app.rork.sophia.ui.onboarding

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
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
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.NotificationPermission
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import kotlinx.coroutines.delay

private val NOTIFICATION_BULLETS = listOf(
    "📚" to "onboardingV2.notifications.bullet1",
    "⏰" to "onboardingV2.notifications.bullet2",
    "🔕" to "onboardingV2.notifications.bullet3",
)

/**
 * Asks for POST_NOTIFICATIONS right after the profile reveal, while the user is still being
 * told what Sophia will do for them. The preview card shows the real reminder copy, so the
 * permission prompt arrives with its reason already on screen.
 *
 * A refusal changes nothing else: the flow continues to the same next step, and the reminder
 * scheduler simply finds notifications disabled later on and no-ops.
 */
@Composable
internal fun NotificationsStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    var asked by remember { mutableStateOf(false) }
    // Preview the exact notification the user would get, featuring a real course.
    var previewCourseTitle by remember(language) { mutableStateOf<String?>(null) }
    LaunchedEffect(language) {
        previewCourseTitle = ContentCatalog
            .summariesAsync(context.applicationContext, language)
            .randomOrNull()
            ?.title
    }
    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission(),
    ) {
        // Granted or refused, the onboarding moves on either way.
        onContinue()
    }

    var revealed by remember { mutableIntStateOf(0) }
    LaunchedEffect(Unit) {
        delay(200)
        NOTIFICATION_BULLETS.indices.forEach {
            revealed = it + 1
            delay(160)
        }
    }

    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        // Short phones have to reach the CTA, which stays pinned below the scroll area.
        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.height(76.dp))
            Text(
                text = StringStore.text(context, "onboardingV2.notifications.title", language),
                style = OV2.titleLarge,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 28.dp).ov2Reveal(60),
            )
            Spacer(Modifier.height(10.dp))
            Text(
                text = StringStore.text(context, "onboardingV2.notifications.subtitle", language),
                style = OV2.body,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 30.dp).ov2Reveal(140),
            )
            Spacer(Modifier.height(30.dp))
            NotificationPreviewCard(
                title = StringStore.text(context, "notification.courseNudge.title", language),
                body = previewCourseTitle?.let {
                    StringStore.text(context, "notification.courseNudge.body", language, it)
                } ?: StringStore.text(context, "notification.courseNudge.bodyFallback", language),
                modifier = Modifier.padding(horizontal = 24.dp).ov2Reveal(260, yOffset = 24.dp),
            )
            Spacer(Modifier.height(30.dp))
            Column(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 30.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                NOTIFICATION_BULLETS.forEachIndexed { index, (emoji, key) ->
                    NotificationBulletRow(
                        emoji = emoji,
                        label = StringStore.text(context, key, language),
                        visible = index < revealed,
                    )
                }
            }
            Spacer(Modifier.height(20.dp))
        }
        OnboardingCta(
            text = StringStore.text(context, "onboardingV2.notifications.cta", language),
            onClick = {
                if (!asked) {
                    asked = true
                    if (NotificationPermission.shouldAsk(context)) {
                        permissionLauncher.launch(NotificationPermission.PERMISSION)
                    } else {
                        onContinue()
                    }
                }
            },
            bottomInset = 6.dp,
        )
        Text(
            text = StringStore.text(context, "onboardingV2.notifications.skip", language),
            style = OV2.caption.copy(color = OV2.inkTertiary),
            modifier = Modifier
                .padding(bottom = 22.dp)
                .clickable(enabled = !asked) {
                    asked = true
                    onContinue()
                }
                .padding(horizontal = 20.dp, vertical = 8.dp),
        )
    }
}

/** Mock of the system notification, so the value of saying yes is visible before the prompt. */
@Composable
private fun NotificationPreviewCard(title: String, body: String, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(OV2.surface, RoundedCornerShape(20.dp))
            .border(1.dp, OV2.hairline, RoundedCornerShape(20.dp))
            .padding(14.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(
            modifier = Modifier
                .size(38.dp)
                .background(OV2.accent.copy(alpha = 0.12f), RoundedCornerShape(11.dp)),
            contentAlignment = Alignment.Center,
        ) {
            Text("🔔", fontSize = 19.sp)
        }
        Column {
            Text(
                text = "Sophia",
                style = OV2.caption.copy(color = OV2.inkTertiary, fontWeight = FontWeight.SemiBold),
            )
            Spacer(Modifier.height(3.dp))
            Text(text = title, style = OV2.caption.copy(color = OV2.ink, fontSize = 14.sp))
            Spacer(Modifier.height(2.dp))
            Text(text = body, style = OV2.caption.copy(color = OV2.inkSecondary), maxLines = 3)
        }
    }
}

@Composable
private fun NotificationBulletRow(emoji: String, label: String, visible: Boolean) {
    val alpha by animateFloatAsState(if (visible) 1f else 0f, tween(360), label = "bulletAlpha")
    val shift by animateFloatAsState(
        targetValue = if (visible) 0f else -10f,
        animationSpec = spring(dampingRatio = 0.82f, stiffness = Spring.StiffnessMediumLow),
        label = "bulletShift",
    )
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .graphicsLayer { this.alpha = alpha; translationX = shift },
        horizontalArrangement = Arrangement.spacedBy(13.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(emoji, fontSize = 19.sp)
        Text(text = label, style = OV2.subheadline.copy(color = OV2.ink))
    }
}
