package app.rork.sophia.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.FeedbackService
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.launch

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
    var status by remember { mutableStateOf<String?>(null) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas)
            .padding(DS.Space.l),
    ) {
        TextButton(onClick = onBack) { Text("← Retour") }
        Text("Feedback", style = SophiaTypography.titleLarge)
        Spacer(Modifier.height(12.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            listOf("bug", "idea", "content", "other").forEach { cat ->
                Text(
                    text = cat,
                    modifier = Modifier
                        .clip(DS.controlShape)
                        .background(if (category == cat) DS.accentTint else DS.surface)
                        .clickable { category = cat }
                        .padding(horizontal = 12.dp, vertical = 8.dp),
                    style = SophiaTypography.labelMedium,
                )
            }
        }
        Spacer(Modifier.height(12.dp))
        OutlinedTextField(
            value = message,
            onValueChange = { message = it },
            modifier = Modifier.fillMaxWidth().height(160.dp),
            placeholder = { Text("Ton message…") },
        )
        Spacer(Modifier.height(8.dp))
        OutlinedTextField(
            value = email,
            onValueChange = { email = it },
            modifier = Modifier.fillMaxWidth(),
            placeholder = { Text("Email (optionnel)") },
            singleLine = true,
        )
        Spacer(Modifier.height(16.dp))
        Button(
            onClick = {
                app.analytics.trackFeedbackOpened()
                scope.launch {
                    val result = FeedbackService.submitFeedback(
                        message = message,
                        category = category,
                        language = language.code,
                        isPremium = isPremium,
                        email = email.ifBlank { null },
                    )
                    if (result.isSuccess) {
                        app.analytics.trackFeedbackSubmitted(category)
                        status = "Merci !"
                        message = ""
                    } else {
                        app.analytics.trackFeedbackFailed(category)
                        status = "Échec d'envoi"
                    }
                }
            },
            modifier = Modifier.fillMaxWidth().height(52.dp),
            shape = DS.controlShape,
            colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
        ) {
            Text("Envoyer", color = Color.White)
        }
        status?.let {
            Spacer(Modifier.height(12.dp))
            Text(it, style = SophiaTypography.bodyMedium)
        }
    }
}
