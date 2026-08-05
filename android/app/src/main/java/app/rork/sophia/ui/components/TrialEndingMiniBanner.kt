package app.rork.sophia.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans

/** Tiny top strip shown once when the user opens the app the day before trial end. */
@Composable
fun TrialEndingMiniBanner(
    language: AppLanguage,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    Text(
        text = StringStore.text(context, "trial.endingSoon.banner", language),
        modifier = modifier
            .fillMaxWidth()
            .background(DS.accent.copy(alpha = 0.94f))
            .padding(horizontal = 14.dp, vertical = 7.dp),
        color = Color.White,
        fontFamily = PlusJakartaSans,
        fontSize = 11.sp,
        fontWeight = FontWeight.Medium,
        textAlign = TextAlign.Center,
        maxLines = 2,
    )
}
