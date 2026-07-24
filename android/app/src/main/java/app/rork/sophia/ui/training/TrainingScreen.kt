package app.rork.sophia.ui.training

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography

@Composable
fun TrainingScreen(
    modifier: Modifier = Modifier,
    language: AppLanguage,
    isPremium: Boolean,
    progress: UserProgress,
) {
    val context = LocalContext.current
    val dueCount = progress.trainingQuestionStates.size

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            .padding(DS.Space.l),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = StringStore.text(context, "training.title", language),
            style = SophiaTypography.titleLarge,
        )
        Spacer(Modifier.height(12.dp))
        if (!isPremium) {
            Text(
                text = StringStore.text(context, "training.locked.title", language),
                style = SophiaTypography.titleMedium,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = StringStore.text(context, "training.locked.message", language),
                style = SophiaTypography.bodyMedium,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(20.dp))
            Button(
                onClick = { /* paywall entrainement */ },
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = DS.controlShape,
                colors = ButtonDefaults.buttonColors(containerColor = DS.accent, contentColor = Color.White),
            ) {
                Text(
                    text = StringStore.text(context, "training.unlock", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 16.sp,
                )
            }
        } else if (dueCount == 0) {
            Text(
                text = StringStore.text(context, "training.emptyTitle", language),
                style = SophiaTypography.titleMedium,
                textAlign = TextAlign.Center,
            )
            Text(
                text = StringStore.text(context, "training.emptyMessage", language),
                style = SophiaTypography.bodyMedium,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 8.dp),
            )
        } else {
            Text(
                text = StringStore.text(context, "training.readyTitle", language),
                style = SophiaTypography.titleMedium,
                textAlign = TextAlign.Center,
            )
            Text(
                text = StringStore.text(context, "training.dueCount", language, dueCount),
                style = SophiaTypography.bodyMedium,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 8.dp),
            )
            Spacer(Modifier.height(20.dp))
            Button(
                onClick = { /* session UI next */ },
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = DS.controlShape,
                colors = ButtonDefaults.buttonColors(containerColor = DS.accent, contentColor = Color.White),
            ) {
                Text(
                    text = StringStore.text(context, "training.start", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                )
            }
        }
    }
}
