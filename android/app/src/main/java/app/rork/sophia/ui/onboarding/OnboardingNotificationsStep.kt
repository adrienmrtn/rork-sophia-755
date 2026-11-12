package app.rork.sophia.ui.onboarding

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.Notifications
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.NotificationPermission
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.components.DSHighlightTitle
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.dsHighlighted
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.theme.DS
import kotlinx.coroutines.delay

private val NOTIFICATION_BULLETS = listOf(
    "📚" to "onboardingV2.notifications.bullet1",
    "⏰" to "onboardingV2.notifications.bullet2",
    "🔕" to "onboardingV2.notifications.bullet3",
)

/** Greys of the system dialog preview. */
private val DialogFill = Color(0xFFF4F5F7)
private val DialogEdge = Color(0xFFE1E4E9)

/**
 * Asks for POST_NOTIFICATIONS while the user is still being told what Sophia will do for
 * them. Sophia says why in a speech bubble, a preview of the system dialog shows where to
 * tap, and the preview card shows the real reminder copy, so the permission prompt arrives
 * with its reason already on screen.
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
        delay(450)
        NOTIFICATION_BULLETS.indices.forEach {
            revealed = it + 1
            delay(120)
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
                .verticalScroll(rememberScrollState())
                .padding(horizontal = OV2End.side),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.height(14.dp))
            NotificationBubbleRow(language = language, modifier = Modifier.dsStagger(0))
            Spacer(Modifier.height(10.dp))
            // The figure, the number in bold blue, under the bubble like a second line of speech.
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(start = 52.dp)
                    .dsStagger(1)
                    .background(DS.accentTint, RoundedCornerShape(DS.Radius.small))
                    .padding(horizontal = 14.dp, vertical = 10.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Icon(
                    Icons.AutoMirrored.Filled.TrendingUp,
                    contentDescription = null,
                    tint = DS.accent,
                    modifier = Modifier.padding(top = 2.dp).size(15.dp),
                )
                Text(
                    text = dsHighlighted(
                        StringStore.text(context, "onboardingV2.notifications.boost", language),
                        highlight = DS.accent,
                    ),
                    style = OV2.caption.copy(color = DS.ink, lineHeight = 18.sp),
                )
            }
            Spacer(Modifier.height(26.dp))
            NotificationDialogPreview(language = language, modifier = Modifier.dsStagger(2))
            Spacer(Modifier.height(22.dp))
            NotificationPreviewCard(
                title = StringStore.text(context, "notification.courseNudge.title", language),
                body = previewCourseTitle?.let {
                    StringStore.text(context, "notification.courseNudge.body", language, it)
                } ?: StringStore.text(context, "notification.courseNudge.bodyFallback", language),
                modifier = Modifier.dsStagger(3),
            )
            Spacer(Modifier.height(18.dp))
            Column(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                NOTIFICATION_BULLETS.forEachIndexed { index, (emoji, key) ->
                    NotificationBulletRow(
                        emoji = emoji,
                        label = StringStore.text(context, key, language),
                        visible = index < revealed,
                    )
                }
            }
            Spacer(Modifier.height(16.dp))
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
            style = OV2.caption,
            modifier = Modifier
                .padding(bottom = 10.dp)
                .pressable(
                    onClick = {
                        asked = true
                        onContinue()
                    },
                    enabled = !asked,
                )
                .padding(horizontal = 20.dp, vertical = 10.dp),
        )
    }
}

/** Sophia's mark and its bubble: the reason for the request, said in the first person. */
@Composable
private fun NotificationBubbleRow(language: AppLanguage, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val bubbleShape = RoundedCornerShape(
        topStart = 4.dp,
        topEnd = DS.Radius.card,
        bottomEnd = DS.Radius.card,
        bottomStart = DS.Radius.card,
    )
    Row(modifier = modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        AssetPicture(
            url = SOPHIA_LOGO,
            contentScale = ContentScale.Fit,
            modifier = Modifier.padding(top = 6.dp).size(40.dp),
        )
        Column(
            modifier = Modifier
                .weight(1f)
                .ov2EndCard(shape = bubbleShape)
                .padding(horizontal = 16.dp, vertical = 14.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            // Until the tables carry the bubble, the page keeps its former title and subtitle.
            DSHighlightTitle(
                text = ov2EndText(context, "onboardingV2.notifications.bubble", language) {
                    StringStore.text(context, "onboardingV2.notifications.title", language)
                },
                modifier = Modifier.semantics { heading() },
                fontSize = 20.sp,
                lineHeight = 26.sp,
                textAlign = TextAlign.Start,
            )
            Text(
                text = ov2EndText(context, "onboardingV2.notifications.bubbleNote", language) {
                    StringStore.text(context, "onboardingV2.notifications.subtitle", language)
                },
                style = OV2.caption.copy(fontWeight = FontWeight.Normal, lineHeight = 18.sp),
            )
        }
    }
}

/**
 * A picture of the system request, with an arrow under « Allow »: what to tap once the
 * button at the bottom is pressed. Purely illustrative, nothing in it can be clicked.
 */
@Composable
private fun NotificationDialogPreview(language: AppLanguage, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val bob = rememberInfiniteTransition(label = "dialogArrow")
    val lift by bob.animateFloat(
        initialValue = 3f,
        targetValue = -5f,
        animationSpec = infiniteRepeatable(tween(750, easing = FastOutSlowInEasing), RepeatMode.Reverse),
        label = "dialogArrowLift",
    )
    Column(
        modifier = modifier.widthIn(max = 286.dp).clearAndSetSemantics { },
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(DialogFill, RoundedCornerShape(20.dp))
                .border(1.5.dp, DialogEdge, RoundedCornerShape(20.dp))
                .padding(start = 18.dp, top = 20.dp, end = 18.dp, bottom = 16.dp),
        ) {
            Text(
                text = StringStore.text(context, "onboardingV2.notifications.dialog.title", language),
                style = OV2.headline.copy(fontSize = 16.sp, lineHeight = 21.sp),
            )
            Spacer(Modifier.height(16.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                DialogButton(
                    text = StringStore.text(context, "onboardingV2.notifications.dialog.deny", language),
                    fill = DialogEdge,
                    foreground = DS.ink,
                    modifier = Modifier.weight(1f),
                )
                DialogButton(
                    text = StringStore.text(context, "onboardingV2.notifications.dialog.allow", language),
                    fill = DS.accent,
                    foreground = Color.White,
                    modifier = Modifier.weight(1f),
                )
            }
        }
        // Under « Allow »: the same two columns as the buttons, so it follows them in
        // right-to-left languages.
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 18.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Spacer(Modifier.weight(1f))
            Box(modifier = Modifier.weight(1f), contentAlignment = Alignment.Center) {
                Icon(
                    Icons.Filled.ArrowUpward,
                    contentDescription = null,
                    tint = DS.accent,
                    modifier = Modifier
                        .size(28.dp)
                        .graphicsLayer { translationY = lift.dp.toPx() },
                )
            }
        }
    }
}

@Composable
private fun DialogButton(text: String, fill: Color, foreground: Color, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .height(46.dp)
            .background(fill, CircleShape)
            .padding(horizontal = 8.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = text,
            style = OV2.subheadline.copy(fontWeight = FontWeight.SemiBold, color = foreground),
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

/** Mock of the system notification, so the value of saying yes is visible before the prompt. */
@Composable
private fun NotificationPreviewCard(title: String, body: String, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .ov2EndCard()
            .padding(14.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(
            modifier = Modifier
                .size(38.dp)
                .background(DS.accentTint, RoundedCornerShape(11.dp)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                Icons.Filled.Notifications,
                contentDescription = null,
                tint = DS.accent,
                modifier = Modifier.size(20.dp),
            )
        }
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = "Sophia",
                style = OV2.caption.copy(color = DS.accent, fontSize = 12.sp, fontWeight = FontWeight.Bold),
                letterSpacing = 0.6.sp,
            )
            Spacer(Modifier.height(3.dp))
            Text(text = title, style = OV2.subheadline.copy(color = DS.ink, fontWeight = FontWeight.SemiBold))
            Spacer(Modifier.height(3.dp))
            Text(
                text = body,
                style = OV2.caption.copy(fontSize = 12.sp, fontWeight = FontWeight.Normal, lineHeight = 17.sp),
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

@Composable
private fun NotificationBulletRow(emoji: String, label: String, visible: Boolean) {
    val progress by animateFloatAsState(if (visible) 1f else 0f, DSMotion.reveal(), label = "bullet")
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .graphicsLayer {
                alpha = progress.coerceIn(0f, 1f)
                translationX = (1f - progress) * -10.dp.toPx()
            },
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(emoji, fontSize = 17.sp)
        Text(text = label, style = OV2.subheadline.copy(color = DS.ink))
    }
}
