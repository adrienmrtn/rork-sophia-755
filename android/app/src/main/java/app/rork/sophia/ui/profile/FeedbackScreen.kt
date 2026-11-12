package app.rork.sophia.ui.profile

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.FeedbackService
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.components.DSCheckBadge
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.SophiaPrimaryButton
import app.rork.sophia.ui.components.dsShake
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlinx.coroutines.launch

private val CATEGORIES = listOf("bug", "idea", "feature", "content", "translation", "other")

/**
 * Le formulaire de retour dans le design « Elevate arrondi » : l'en-tête calme (titre, croix),
 * les catégories en pastilles, les deux champs bordés, puis l'envoi. Une fois parti, la coche
 * se dessine avec rebond.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun FeedbackScreen(
    language: AppLanguage,
    isPremium: Boolean,
    onBack: () -> Unit,
    /** La catégorie présélectionnée : « Demander une fonctionnalité » ouvre le formulaire sur la sienne. */
    initialCategory: String = "idea",
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val haptics = rememberHaptics()
    var category by remember { mutableStateOf(initialCategory) }
    var message by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var sending by remember { mutableStateOf(false) }
    var sent by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    // Secousse du message d'erreur à chaque envoi refusé.
    var errorShake by remember { mutableIntStateOf(0) }
    val closeLabel = StringStore.text(context, "common.close", language)

    if (sent) {
        Column(
            modifier = Modifier.fillMaxSize().background(DS.canvas).padding(horizontal = 20.dp).padding(bottom = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.weight(1f))
            // Retour envoyé : la coche se dessine, avec rebond (la vibration part à l'envoi).
            DSCheckBadge(size = 88.dp, delayMillis = 100)
            Spacer(Modifier.height(20.dp))
            Text(
                text = StringStore.text(context, "feedback.success.title", language),
                modifier = Modifier.dsStagger(1),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 22.sp,
                lineHeight = 28.sp,
                color = DS.ink,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(10.dp))
            Text(
                text = StringStore.text(context, "feedback.success.body", language),
                modifier = Modifier.padding(horizontal = 24.dp).dsStagger(2),
                fontFamily = PlusJakartaSans,
                fontSize = 15.sp,
                lineHeight = 21.sp,
                color = DS.inkSecondary,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.weight(1f))
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
            .imePadding()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp)
            .padding(bottom = 32.dp),
    ) {
        ProfileSheetHeader(
            title = StringStore.text(context, if (category == "feature") "feedback.feature.title" else "feedback.title", language),
            closeIcon = Icons.Filled.Close,
            closeLabel = closeLabel,
            onClose = onBack,
            modifier = Modifier.padding(top = 16.dp, bottom = 12.dp),
        )
        Text(
            text = StringStore.text(context, "feedback.subtitle", language),
            fontFamily = PlusJakartaSans,
            fontSize = 15.sp,
            lineHeight = 21.sp,
            color = DS.inkSecondary,
        )

        Spacer(Modifier.height(20.dp))
        ProfileGroupLabel(StringStore.text(context, "feedback.category.label", language))
        Spacer(Modifier.height(10.dp))
        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            CATEGORIES.forEach { key ->
                val isSelected = category == key
                val fill by animateColorAsState(if (isSelected) DS.accent else DS.accentTint, DSMotion.snappy(), label = "categoryFill")
                val ink by animateColorAsState(if (isSelected) Color.White else DS.ink, DSMotion.snappy(), label = "categoryInk")
                Box(
                    modifier = Modifier
                        .height(40.dp)
                        .pressable(
                            onClick = {
                                if (!isSelected) {
                                    haptics.select()
                                    category = key
                                }
                            },
                            haptic = false,
                        )
                        .clip(RoundedCornerShape(14.dp))
                        .background(fill)
                        .semantics {
                            selected = isSelected
                            role = Role.RadioButton
                        }
                        .padding(horizontal = 14.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = StringStore.text(context, "feedback.category.$key", language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.sp,
                        color = ink,
                        maxLines = 1,
                    )
                }
            }
        }

        Spacer(Modifier.height(20.dp))
        ProfileGroupLabel(StringStore.text(context, "feedback.message.label", language))
        Spacer(Modifier.height(10.dp))
        ProfileTextField(
            value = message,
            onValueChange = { message = it },
            placeholder = StringStore.text(context, if (category == "feature") "feedback.feature.placeholder" else "feedback.message.placeholder", language),
            singleLine = false,
            minHeight = 150.dp,
        )

        Spacer(Modifier.height(20.dp))
        ProfileGroupLabel(StringStore.text(context, "feedback.email.label", language))
        Spacer(Modifier.height(10.dp))
        ProfileTextField(
            value = email,
            onValueChange = { email = it },
            placeholder = StringStore.text(context, "feedback.email.placeholder", language),
            singleLine = true,
            minHeight = 52.dp,
        )

        Spacer(Modifier.height(14.dp))
        Text(
            text = StringStore.text(context, "feedback.technicalNote", language),
            fontFamily = PlusJakartaSans,
            fontSize = 12.sp,
            lineHeight = 17.sp,
            color = DS.inkSecondary,
        )

        error?.let {
            Spacer(Modifier.height(14.dp))
            Text(
                text = it,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 14.sp,
                lineHeight = 20.sp,
                color = DS.danger,
                modifier = Modifier
                    .fillMaxWidth()
                    .dsShake(trigger = errorShake)
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
                        message = ""
                        haptics.success()
                        sent = true
                    } else {
                        // The message stays in the field either way: a rejected email is a
                        // reason to fix one line, not to retype the whole report.
                        val badEmail = (result.exceptionOrNull() as? IllegalArgumentException)
                            ?.message == "email"
                        error = StringStore.text(
                            context,
                            if (badEmail) "feedback.error.email" else "feedback.error.generic",
                            language,
                        )
                        haptics.error()
                        errorShake += 1
                    }
                }
            },
        )
    }
}
