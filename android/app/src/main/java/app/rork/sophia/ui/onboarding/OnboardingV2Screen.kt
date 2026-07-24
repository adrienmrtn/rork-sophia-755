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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.paywall.PaywallContext
import app.rork.sophia.ui.paywall.PaywallScreen
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import app.rork.sophia.billing.StoreViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private enum class OnboardingStep {
    Welcome,
    Language,
    Objectives,
    ValueProp,
    Personalize,
    SwipeHint,
    Loading,
    Login,
    Trial,
    Reminder,
    Paywall,
}

@Composable
fun OnboardingV2Screen(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    onLanguageSelected: (AppLanguage) -> Unit,
    onComplete: () -> Unit,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    var step by remember { mutableStateOf(OnboardingStep.Welcome) }
    var selectedObjective by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    Box(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
        when (step) {
            OnboardingStep.Welcome -> WelcomeStep(language) { step = OnboardingStep.Language }
            OnboardingStep.Language -> LanguageStep(language) {
                onLanguageSelected(it)
                step = OnboardingStep.Objectives
            }
            OnboardingStep.Objectives -> ObjectivesStep(language) {
                selectedObjective = it
                step = OnboardingStep.ValueProp
            }
            OnboardingStep.ValueProp -> SimpleStep(
                title = StringStore.text(context, "training.ob.recall.title", language),
                body = StringStore.text(context, "training.ob.recall.stat.prefix", language) + " " +
                    StringStore.text(context, "training.ob.recall.stat.highlight", language),
                cta = StringStore.text(context, "training.ob.cta.last", language),
                onContinue = { step = OnboardingStep.Personalize },
            )
            OnboardingStep.Personalize -> SimpleStep(
                title = StringStore.text(context, "onboarding.intro.title", language),
                body = selectedObjective ?: "",
                cta = StringStore.text(context, "onboarding.intro.cta", language),
                onContinue = { step = OnboardingStep.SwipeHint },
            )
            OnboardingStep.SwipeHint -> SimpleStep(
                title = StringStore.text(context, "home.swipe.title", language),
                body = StringStore.text(context, "home.swipe.subtitle", language),
                cta = StringStore.text(context, "training.ob.cta.last", language),
                onContinue = { step = OnboardingStep.Loading },
            )
            OnboardingStep.Loading -> LoadingStep {
                step = OnboardingStep.Login
            }
            OnboardingStep.Login -> LoginStep(
                language = language,
                onGoogle = {
                    scope.launch {
                        runCatching { app.authService.signInWithGoogle(context) }
                        step = OnboardingStep.Trial
                    }
                },
                onSkip = { step = OnboardingStep.Trial },
            )
            OnboardingStep.Trial -> SimpleStep(
                title = "3 jours d'essai",
                body = "Puis un abonnement annuel. Annule quand tu veux.",
                cta = StringStore.text(context, "training.ob.cta.last", language),
                onContinue = { step = OnboardingStep.Reminder },
            )
            OnboardingStep.Reminder -> SimpleStep(
                title = "Un rappel doux",
                body = "10 minutes par jour suffisent pour progresser.",
                cta = StringStore.text(context, "training.ob.cta.last", language),
                onContinue = { step = OnboardingStep.Paywall },
            )
            OnboardingStep.Paywall -> PaywallScreen(
                context = PaywallContext.FIN_ONBOARDING,
                language = language,
                storeViewModel = storeViewModel,
                onDismiss = onComplete,
                onPurchased = onComplete,
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
            Text(text = "Sophia", style = SophiaTypography.displayLarge, fontSize = 48.sp)
            Spacer(Modifier.height(16.dp))
            Text(
                text = StringStore.text(context, "onboarding.intro.title", language),
                style = SophiaTypography.titleLarge,
            )
        }
        PrimaryCta(StringStore.text(context, "onboarding.intro.cta", language), onContinue)
    }
}

@Composable
private fun LanguageStep(language: AppLanguage, onSelect: (AppLanguage) -> Unit) {
    val context = LocalContext.current
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(DS.Space.l),
    ) {
        Spacer(Modifier.height(48.dp))
        Text(StringStore.text(context, "onboarding.language.title", language), style = SophiaTypography.titleLarge)
        Text(
            StringStore.text(context, "onboarding.language.subtitle", language),
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
private fun ObjectivesStep(language: AppLanguage, onSelect: (String) -> Unit) {
    val context = LocalContext.current
    val options = listOf(
        "Devenir plus cultivé",
        "Briller en société",
        "Apprendre chaque jour",
        "Préparer des examens",
    )
    Column(modifier = Modifier.fillMaxSize().padding(DS.Space.l)) {
        Spacer(Modifier.height(48.dp))
        Text(
            text = StringStore.text(context, "onboarding.language.title", language)
                .let { "Ton objectif" },
            style = SophiaTypography.titleLarge,
        )
        Spacer(Modifier.height(16.dp))
        options.forEach { opt ->
            Text(
                text = opt,
                style = SophiaTypography.bodyLarge,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 6.dp)
                    .clip(DS.controlShape)
                    .background(DS.surface)
                    .clickable { onSelect(opt) }
                    .padding(16.dp),
            )
        }
    }
}

@Composable
private fun SimpleStep(title: String, body: String = "", cta: String, onContinue: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().padding(DS.Space.l),
        verticalArrangement = Arrangement.SpaceBetween,
    ) {
        Spacer(Modifier.height(80.dp))
        Column {
            Text(text = title, style = SophiaTypography.titleLarge)
            if (body.isNotBlank()) {
                Spacer(Modifier.height(12.dp))
                Text(text = body, style = SophiaTypography.bodyMedium)
            }
        }
        PrimaryCta(cta, onContinue)
    }
}

@Composable
private fun LoadingStep(onDone: () -> Unit) {
    var progress by remember { mutableIntStateOf(0) }
    LaunchedEffect(Unit) {
        while (progress < 100) {
            delay(18)
            progress += 2
        }
        delay(200)
        onDone()
    }
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        CircularProgressIndicator(color = DS.accent)
        Spacer(Modifier.height(16.dp))
        Text("Préparation de ton parcours… $progress%", style = SophiaTypography.bodyMedium)
    }
}

@Composable
private fun LoginStep(language: AppLanguage, onGoogle: () -> Unit, onSkip: () -> Unit) {
    val context = LocalContext.current
    Column(
        modifier = Modifier.fillMaxSize().padding(DS.Space.l),
        verticalArrangement = Arrangement.SpaceBetween,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.height(80.dp))
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text("Sophia", style = SophiaTypography.displayLarge)
            Spacer(Modifier.height(12.dp))
            Text(
                text = "Connecte-toi pour sauvegarder ta progression.",
                style = SophiaTypography.bodyMedium,
                textAlign = TextAlign.Center,
            )
        }
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            PrimaryCta("Continue with Google", onGoogle)
            Text(
                text = StringStore.text(context, "home.skip", language),
                style = SophiaTypography.labelLarge,
                color = DS.inkSecondary,
                modifier = Modifier
                    .align(Alignment.CenterHorizontally)
                    .clickable(onClick = onSkip)
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
