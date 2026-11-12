package app.rork.sophia.ui.onboarding

import androidx.compose.runtime.Composable
import app.rork.sophia.domain.AppLanguage

/**
 * « Courbe 90 jours » : placeholder, the real page is drawn in the « Elevate arrondi » pass.
 */
@Composable
internal fun Curve90Step(language: AppLanguage, onContinue: () -> Unit) {
    OnboardingPage(footer = { OnboardingCta(text = "→", onClick = onContinue) }) { }
}
