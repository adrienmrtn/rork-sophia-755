package app.rork.sophia.ui.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
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
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
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
import app.rork.sophia.ui.theme.SophiaTypography

/**
 * Onboarding V2 skeleton — full 18-step flow will be filled screen-by-screen.
 * Current path: welcome → language → value props → login placeholder → enter app.
 */
@Composable
fun OnboardingV2Screen(
    language: AppLanguage,
    onLanguageSelected: (AppLanguage) -> Unit,
    onComplete: () -> Unit,
) {
    val context = LocalContext.current
    var step by remember { mutableIntStateOf(0) }

    Box(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
        when (step) {
            0 -> WelcomeStep(
                language = language,
                onContinue = { step = 1 },
            )
            1 -> LanguageStep(
                language = language,
                onSelect = {
                    onLanguageSelected(it)
                    step = 2
                },
            )
            2 -> SimpleStep(
                title = StringStore.text(context, "onboarding.intro.title", language),
                cta = StringStore.text(context, "onboarding.intro.cta", language),
                onContinue = { step = 3 },
            )
            3 -> SimpleStep(
                title = StringStore.text(context, "training.ob.recall.title", language)
                    .takeIf { it != "training.ob.recall.title" }
                    ?: "10 minutes a day to become cultured",
                cta = StringStore.text(context, "training.ob.cta.last", language),
                onContinue = { step = 4 },
            )
            else -> LoginPlaceholderStep(
                language = language,
                onContinue = onComplete,
            )
        }
    }
}

@Composable
private fun WelcomeStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    Column(
        modifier = Modifier.fillMaxSize().padding(DS.Space.l),
        verticalArrangement = Arrangement.SpaceBetween,
    ) {
        Spacer(Modifier.height(40.dp))
        Column {
            Text(
                text = "Sophia",
                style = SophiaTypography.displayLarge,
                fontSize = 48.sp,
            )
            Spacer(Modifier.height(16.dp))
            Text(
                text = StringStore.text(context, "onboarding.intro.title", language),
                style = SophiaTypography.titleLarge,
            )
        }
        PrimaryCta(
            text = StringStore.text(context, "onboarding.intro.cta", language),
            onClick = onContinue,
        )
    }
}

@Composable
private fun LanguageStep(
    language: AppLanguage,
    onSelect: (AppLanguage) -> Unit,
) {
    val context = LocalContext.current
    Column(
        modifier = Modifier.fillMaxSize().padding(DS.Space.l),
    ) {
        Spacer(Modifier.height(48.dp))
        Text(
            text = StringStore.text(context, "onboarding.language.title", language),
            style = SophiaTypography.titleLarge,
        )
        Text(
            text = StringStore.text(context, "onboarding.language.subtitle", language),
            style = SophiaTypography.bodyMedium,
            modifier = Modifier.padding(top = 8.dp, bottom = 24.dp),
        )
        AppLanguage.entries.forEach { lang ->
            Text(
                text = "${lang.flag}  ${lang.displayName}",
                style = SophiaTypography.bodyLarge,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 6.dp)
                    .clip(DS.controlShape)
                    .background(if (lang == language) DS.accentTint else DS.surface)
                    .clickable { onSelect(lang) }
                    .padding(horizontal = 16.dp, vertical = 14.dp),
            )
        }
    }
}

@Composable
private fun SimpleStep(title: String, cta: String, onContinue: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().padding(DS.Space.l),
        verticalArrangement = Arrangement.SpaceBetween,
    ) {
        Spacer(Modifier.height(80.dp))
        Text(
            text = title,
            style = SophiaTypography.titleLarge,
            textAlign = TextAlign.Start,
        )
        PrimaryCta(text = cta, onClick = onContinue)
    }
}

@Composable
private fun LoginPlaceholderStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    Column(
        modifier = Modifier.fillMaxSize().padding(DS.Space.l),
        verticalArrangement = Arrangement.SpaceBetween,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.height(80.dp))
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(text = "Sophia", style = SophiaTypography.displayLarge)
            Spacer(Modifier.height(12.dp))
            Text(
                text = "Continue with Google (wired next) — or explore the app now.",
                style = SophiaTypography.bodyMedium,
                textAlign = TextAlign.Center,
            )
        }
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            PrimaryCta(
                text = "Continue with Google",
                onClick = onContinue,
            )
            Text(
                text = StringStore.text(context, "home.skip", language),
                style = SophiaTypography.labelLarge,
                color = DS.inkSecondary,
                modifier = Modifier
                    .align(Alignment.CenterHorizontally)
                    .clickable(onClick = onContinue)
                    .padding(8.dp),
            )
        }
    }
}

@Composable
private fun PrimaryCta(text: String, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth().height(54.dp),
        shape = DS.controlShape,
        colors = ButtonDefaults.buttonColors(containerColor = DS.accent, contentColor = Color.White),
    ) {
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 16.sp,
        )
    }
}
