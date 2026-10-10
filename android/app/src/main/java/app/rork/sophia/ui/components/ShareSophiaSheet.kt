package app.rork.sophia.ui.components

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Chat
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Link
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Sms
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlinx.coroutines.delay

/**
 * Sharing Sophia: the short link, which sends each phone to its own store page (Play Store
 * for Android), and the sentence that goes with it. Same link and texts as iOS.
 */
object SophiaShare {
    const val URL = "https://taap.it/sophia.culture"
    const val DISPLAY_URL = "taap.it/sophia.culture"

    fun message(context: Context, language: AppLanguage): String =
        StringStore.text(context, "share.message", language) + "\n" + URL

    /** The system share sheet: every app installed, Nearby Share, Gmail… */
    fun openChooser(context: Context, message: String) {
        val send = Intent(Intent.ACTION_SEND)
            .setType("text/plain")
            .putExtra(Intent.EXTRA_TEXT, message)
        runCatching { context.startActivity(Intent.createChooser(send, null)) }
    }

    /** WhatsApp (or WhatsApp Business) on its contact picker, the message ready. */
    fun openWhatsApp(context: Context, message: String) {
        for (pkg in listOf("com.whatsapp", "com.whatsapp.w4b")) {
            val intent = Intent(Intent.ACTION_SEND)
                .setType("text/plain")
                .setPackage(pkg)
                .putExtra(Intent.EXTRA_TEXT, message)
            try {
                context.startActivity(intent)
                return
            } catch (_: ActivityNotFoundException) {
                // Not installed: try the next one, then the system sheet.
            }
        }
        openChooser(context, message)
    }

    /** The SMS app, the text already typed. */
    fun openMessages(context: Context, message: String) {
        val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:")).putExtra("sms_body", message)
        try {
            context.startActivity(intent)
        } catch (_: ActivityNotFoundException) {
            openChooser(context, message)
        }
    }
}

/**
 * « Fais découvrir Sophia »: the link to copy, WhatsApp, Messages, and the system share sheet
 * for everything else. A sheet pulled down to close, like iOS's `ShareSophiaSheet`.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShareSophiaSheet(language: AppLanguage, onDismiss: () -> Unit) {
    val context = LocalContext.current
    val view = LocalView.current
    val clipboard = LocalClipboardManager.current
    val message = remember(language) { SophiaShare.message(context, language) }
    fun text(key: String) = StringStore.text(context, key, language)

    val appeared = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        delay(100)
        appeared.animateTo(1f, spring(dampingRatio = 0.65f, stiffness = 130f))
    }
    // A counter rather than a flag, so a second tap restarts the « Copied! » timer.
    var copiedTaps by remember { mutableIntStateOf(0) }
    var copied by remember { androidx.compose.runtime.mutableStateOf(false) }
    LaunchedEffect(copiedTaps) {
        if (copiedTaps == 0) return@LaunchedEffect
        copied = true
        delay(1800)
        copied = false
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = DS.canvas,
        shape = RoundedCornerShape(topStart = 30.dp, topEnd = 30.dp),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(bottom = 22.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Column(
                modifier = Modifier.widthIn(max = 520.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Spacer(Modifier.height(8.dp))
                Box(
                    modifier = Modifier
                        .size(76.dp)
                        .graphicsLayer {
                            val scale = 0.7f + 0.3f * appeared.value
                            scaleX = scale
                            scaleY = scale
                        }
                        .clip(CircleShape)
                        .background(DS.accentTint),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        Icons.AutoMirrored.Filled.Send,
                        contentDescription = null,
                        tint = DS.accent,
                        modifier = Modifier
                            .size(30.dp)
                            .graphicsLayer { rotationZ = -25f * (1f - appeared.value) },
                    )
                }
                Spacer(Modifier.height(16.dp))
                Text(
                    text = text("share.title"),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 22.sp,
                    lineHeight = 28.sp,
                    color = DS.ink,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(horizontal = 28.dp),
                )
                Spacer(Modifier.height(8.dp))
                Text(
                    text = text("share.subtitle"),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Medium,
                    fontSize = 15.sp,
                    lineHeight = 21.sp,
                    color = DS.inkSecondary,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(horizontal = 32.dp),
                )
                Spacer(Modifier.height(22.dp))

                // The link in clear, and a button to copy it.
                Row(
                    modifier = Modifier
                        .padding(horizontal = 24.dp)
                        .fillMaxWidth()
                        .clip(DS.controlShape)
                        .background(DS.surface)
                        .border(1.dp, DS.hairline, DS.controlShape)
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Icon(Icons.Filled.Link, contentDescription = null, tint = DS.accentSoft, modifier = Modifier.size(18.dp))
                    Text(
                        text = SophiaShare.DISPLAY_URL,
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 15.sp,
                        color = DS.ink,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f),
                    )
                    Row(
                        modifier = Modifier
                            .clip(CircleShape)
                            .background(if (copied) DS.success else DS.accentTint)
                            .softPress(onClick = {
                                clipboard.setText(AnnotatedString(SophiaShare.URL))
                                view.performHapticFeedback(android.view.HapticFeedbackConstants.KEYBOARD_TAP)
                                copiedTaps += 1
                            })
                            .padding(horizontal = 12.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(5.dp),
                    ) {
                        val tint = if (copied) Color.White else DS.accent
                        Icon(
                            if (copied) Icons.Filled.Check else Icons.Filled.ContentCopy,
                            contentDescription = null,
                            tint = tint,
                            modifier = Modifier.size(14.dp),
                        )
                        Text(
                            text = text(if (copied) "share.copied" else "share.copy"),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 12.sp,
                            color = tint,
                            maxLines = 1,
                        )
                    }
                }
                Spacer(Modifier.height(14.dp))
                Row(
                    modifier = Modifier.padding(horizontal = 24.dp).fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    ChannelButton(
                        title = text("share.whatsapp"),
                        icon = Icons.AutoMirrored.Filled.Chat,
                        tint = WHATSAPP_GREEN,
                        modifier = Modifier.weight(1f),
                        onClick = { SophiaShare.openWhatsApp(context, message) },
                    )
                    ChannelButton(
                        title = text("share.messages"),
                        icon = Icons.Filled.Sms,
                        tint = MESSAGES_GREEN,
                        modifier = Modifier.weight(1f),
                        onClick = { SophiaShare.openMessages(context, message) },
                    )
                }
                Spacer(Modifier.height(12.dp))
                SophiaPrimaryButton(
                    text = text("share.more"),
                    onClick = { SophiaShare.openChooser(context, message) },
                    leadingIcon = Icons.Filled.Share,
                    modifier = Modifier.padding(horizontal = 24.dp),
                )
            }
        }
    }
}

private val WHATSAPP_GREEN = Color(red = 0.14f, green = 0.83f, blue = 0.40f)
private val MESSAGES_GREEN = Color(red = 0.20f, green = 0.78f, blue = 0.35f)

@Composable
private fun ChannelButton(
    title: String,
    icon: ImageVector,
    tint: Color,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .softPress(onClick = onClick)
            .clip(CircleShape)
            .background(tint)
            .padding(vertical = 15.dp, horizontal = 10.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, contentDescription = null, tint = Color.White, modifier = Modifier.size(17.dp))
        Spacer(Modifier.size(8.dp))
        Text(
            text = title,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 15.sp,
            color = Color.White,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

/**
 * « Partage Sophia · Offre 10 minutes de culture à un ami », the card that opens the sheet
 * from the profile, with the pink paper plane of iOS.
 */
@Composable
fun ShareSophiaCard(language: AppLanguage, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    Row(
        modifier = modifier
            .fillMaxWidth()
            .softPress(onClick = onClick)
            .sophiaCard()
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(SHARE_PINK.copy(alpha = 0.12f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.AutoMirrored.Filled.Send, contentDescription = null, tint = SHARE_PINK, modifier = Modifier.size(18.dp))
        }
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                text = StringStore.text(context, "share.card.title", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 16.sp,
                color = DS.ink,
            )
            Text(
                text = StringStore.text(context, "share.card.subtitle", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Medium,
                fontSize = 12.sp,
                lineHeight = 16.sp,
                color = DS.inkSecondary,
            )
        }
        Icon(Icons.Filled.Share, contentDescription = null, tint = DS.inkTertiary, modifier = Modifier.size(18.dp))
    }
}

/** The onboarding pink of iOS (`OV2.pink`). */
private val SHARE_PINK = Color(red = 0.95f, green = 0.33f, blue = 0.56f)
