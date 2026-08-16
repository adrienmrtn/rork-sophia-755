package app.rork.sophia.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.FeedbackService
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.components.CircleIconButton
import app.rork.sophia.ui.components.ScreenTitle
import app.rork.sophia.ui.components.SectionLabel
import app.rork.sophia.ui.components.SophiaPrimaryButton
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.launch

private val CATEGORIES = listOf("bug", "idea", "content", "other")

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun FeedbackScreen(
    language: AppLanguage,
    isPremium: Boolean,
    onBack: () -> Unit,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val scope = rememberCoroutineScope()
    var category by remember { mutableStateOf("idea") }
    var message by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var sending by remember { mutableStateOf(false) }
    var sent by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }

    if (sent) {
        Column(
            modifier = Modifier.fillMaxSize().background(DS.canvas).padding(DS.Space.l),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(
                modifier = Modifier.height(112.dp).fillMaxWidth(),
                contentAlignment = Alignment.Center,
            ) {
                androidx.compose.material3.Icon(
                    Icons.Filled.CheckCircle,
                    contentDescription = null,
                    tint = DS.success,
                    modifier = Modifier.height(88.dp),
                )
            }
            Spacer(Modifier.height(20.dp))
            Text(
                text = StringStore.text(context, "feedback.success.title", language),
                style = SophiaTypography.titleLarge,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(10.dp))
            Text(
                text = StringStore.text(context, "feedback.success.body", language),
                style = SophiaTypography.bodyMedium,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(28.dp))
            SophiaPrimaryButton(
                text = StringStore.text(context, "feedback.success.close", language),
                onClick = onBack,
            )
        }
        return
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = DS.Space.l)
            .padding(bottom = 32.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(vertical = DS.Space.s),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            CircleIconButton(icon = Icons.AutoMirrored.Filled.ArrowBack, onClick = onBack)
            ScreenTitle(
                text = StringStore.text(context, "feedback.title", language),
                modifier = Modifier.weight(1f),
            )
        }
        Text(
            text = StringStore.text(context, "feedback.subtitle", language),
            style = SophiaTypography.bodyMedium,
        )

        Spacer(Modifier.height(22.dp))
        SectionLabel(StringStore.text(context, "feedback.category.label", language))
        Spacer(Modifier.height(10.dp))
        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            CATEGORIES.forEach { key ->
                val selected = category == key
                Text(
                    text = StringStore.text(context, "feedback.category.$key", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 13.sp,
                    color = if (selected) Color.White else DS.inkSecondary,
                    modifier = Modifier
                        .softPress(onClick = { category = key })
                        .clip(CircleShape)
                        .background(if (selected) DS.accent else DS.surface)
                        .border(1.dp, if (selected) DS.accent else DS.hairline, CircleShape)
                        .padding(horizontal = 14.dp, vertical = 9.dp),
                )
            }
        }

        Spacer(Modifier.height(22.dp))
        SectionLabel(StringStore.text(context, "feedback.message.label", language))
        Spacer(Modifier.height(10.dp))
        FeedbackField(
            value = message,
            onValueChange = { message = it },
            placeholder = StringStore.text(context, "feedback.message.placeholder", language),
            singleLine = false,
            minHeight = 150.dp,
        )

        Spacer(Modifier.height(18.dp))
        SectionLabel(StringStore.text(context, "feedback.email.label", language))
        Spacer(Modifier.height(10.dp))
        FeedbackField(
            value = email,
            onValueChange = { email = it },
            placeholder = StringStore.text(context, "feedback.email.placeholder", language),
            singleLine = true,
            minHeight = 52.dp,
        )

        Spacer(Modifier.height(14.dp))
        Text(
            text = StringStore.text(context, "feedback.technicalNote", language),
            style = SophiaTypography.labelMedium.copy(fontSize = 11.sp, color = DS.inkTertiary),
        )

        error?.let {
            Spacer(Modifier.height(14.dp))
            Text(
                text = it,
                style = SophiaTypography.bodyMedium.copy(color = DS.danger),
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(DS.controlShape)
                    .background(DS.dangerTint)
                    .padding(14.dp),
            )
        }

        Spacer(Modifier.height(24.dp))
        SophiaPrimaryButton(
            text = StringStore.text(context, "feedback.submit", language),
            enabled = message.isNotBlank() && !sending,
            onClick = {
                app.analytics.trackFeedbackOpened()
                sending = true
                error = null
                scope.launch {
                    val result = FeedbackService.submitFeedback(
                        message = message,
                        category = category,
                        language = language.code,
                        isPremium = isPremium,
                        email = email.ifBlank { null },
                    )
                    sending = false
                    if (result.isSuccess) {
                        app.analytics.trackFeedbackSubmitted(category)
                        message = ""
                        sent = true
                    } else {
                        app.analytics.trackFeedbackFailed(category)
                        error = StringStore.text(context, "feedback.error.generic", language)
                    }
                }
            },
        )
    }
}

@Composable
private fun FeedbackField(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    singleLine: Boolean,
    minHeight: androidx.compose.ui.unit.Dp,
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = minHeight)
            .sophiaCard(shape = DS.controlShape, elevation = 2.dp)
            .padding(horizontal = 14.dp, vertical = 13.dp),
    ) {
        if (value.isEmpty()) {
            Text(text = placeholder, style = SophiaTypography.bodyMedium, color = DS.inkTertiary)
        }
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            singleLine = singleLine,
            textStyle = SophiaTypography.bodyLarge.copy(fontSize = 16.sp, color = DS.ink),
            cursorBrush = SolidColor(DS.accentSoft),
            modifier = Modifier.fillMaxWidth(),
        )
    }
}
