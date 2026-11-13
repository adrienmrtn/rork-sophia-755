package app.rork.sophia.ui.onboarding

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.NotificationPermission
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.components.DSHighlightTitle
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.theme.DS

/** The colours of the Android 13+ permission dialog (Material 3, light). */
private val SystemDialogSurface = Color(0xFFF3F6FC)
private val SystemDialogButtonFill = Color(0xFFD3E3FD)
private val SystemDialogButtonText = Color(0xFF041E49)
private val SystemDialogIcon = Color(0xFF0B57D0)
private val SystemDialogTitle = Color(0xFF1F1F1F)

/**
 * Asks for POST_NOTIFICATIONS. The page is Sophia's title and one block: a faithful replica
 * of the Android 13+ system dialog (bell, centred title, « Allow » over « Don't allow »).
 *
 * « Allow », or a tap anywhere else on the block, opens the REAL system request, then the
 * flow moves on whatever the answer. « Don't allow » moves on without asking, so the system
 * request stays available for later. A refusal changes nothing else: the reminder scheduler
 * simply finds notifications disabled and no-ops.
 */
@Composable
internal fun NotificationsStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    var asked by remember { mutableStateOf(false) }
    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission(),
    ) {
        // Granted or refused, the onboarding moves on either way.
        onContinue()
    }
    fun askSystem() {
        if (asked) return
        asked = true
        if (NotificationPermission.shouldAsk(context)) {
            permissionLauncher.launch(NotificationPermission.PERMISSION)
        } else {
            onContinue()
        }
    }
    fun skip() {
        if (asked) return
        asked = true
        onContinue()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = OV2End.side),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.height(14.dp))
        NotificationBubbleRow(language = language, modifier = Modifier.dsStagger(0))
        Spacer(Modifier.height(44.dp))
        SystemNotificationDialog(
            language = language,
            onAllow = { askSystem() },
            onDeny = { skip() },
            modifier = Modifier.dsStagger(1),
        )
        Spacer(Modifier.height(24.dp))
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
            // Until the tables carry the bubble, the page keeps its former title. No subtitle.
            DSHighlightTitle(
                text = ov2EndText(context, "onboardingV2.notifications.bubble", language) {
                    StringStore.text(context, "onboardingV2.notifications.title", language)
                },
                modifier = Modifier.semantics { heading() },
                fontSize = 20.sp,
                lineHeight = 26.sp,
                textAlign = TextAlign.Start,
            )
        }
    }
}

/**
 * The Android 13+ notification permission dialog, redrawn: a rounded Material card, the bell,
 * the centred question, and the two stacked full-width buttons. The whole card answers like
 * « Allow »; only « Don't allow » declines.
 */
@Composable
private fun SystemNotificationDialog(
    language: AppLanguage,
    onAllow: () -> Unit,
    onDeny: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val shape = RoundedCornerShape(28.dp)
    Column(
        modifier = modifier
            .widthIn(max = 320.dp)
            .fillMaxWidth()
            .shadow(elevation = 10.dp, shape = shape)
            .clip(shape)
            .background(SystemDialogSurface)
            .pressable(onClick = onAllow, scaleDown = 1f, haptic = false)
            .padding(start = 24.dp, top = 24.dp, end = 24.dp, bottom = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(
            Icons.Outlined.Notifications,
            contentDescription = null,
            tint = SystemDialogIcon,
            modifier = Modifier.size(28.dp),
        )
        Spacer(Modifier.height(16.dp))
        Text(
            // The system's own wording ; the former preview title until the tables carry it.
            text = ov2EndText(context, "onboardingV2.notifications.alert.title.android", language) {
                StringStore.text(context, "onboardingV2.notifications.dialog.title", language)
            },
            style = OV2.headline.copy(
                color = SystemDialogTitle,
                fontSize = 22.sp,
                lineHeight = 28.sp,
                fontWeight = FontWeight.Normal,
            ),
            textAlign = TextAlign.Center,
            modifier = Modifier.semantics { heading() },
        )
        Spacer(Modifier.height(24.dp))
        SystemDialogButton(
            text = ov2EndText(context, "onboardingV2.notifications.alert.allow", language) {
                StringStore.text(context, "onboardingV2.notifications.dialog.allow", language)
            },
            shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp, bottomStart = 4.dp, bottomEnd = 4.dp),
            onClick = onAllow,
        )
        Spacer(Modifier.height(2.dp))
        SystemDialogButton(
            text = ov2EndText(context, "onboardingV2.notifications.alert.deny.android", language) {
                StringStore.text(context, "onboardingV2.notifications.dialog.deny", language)
            },
            shape = RoundedCornerShape(topStart = 4.dp, topEnd = 4.dp, bottomStart = 20.dp, bottomEnd = 20.dp),
            onClick = onDeny,
        )
    }
}

/** One of the two stacked buttons of the system dialog: tonal, full width, text centred. */
@Composable
private fun SystemDialogButton(text: String, shape: Shape, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 56.dp)
            .clip(shape)
            .background(SystemDialogButtonFill)
            .pressable(onClick = onClick, scaleDown = 1f)
            .semantics { role = Role.Button }
            .padding(horizontal = 16.dp, vertical = 12.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = text,
            style = OV2.subheadline.copy(
                color = SystemDialogButtonText,
                fontSize = 14.sp,
                lineHeight = 20.sp,
                fontWeight = FontWeight.Medium,
            ),
            textAlign = TextAlign.Center,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
    }
}
