package app.rork.sophia.ui.duels

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import app.rork.sophia.domain.AppLanguage

/**
 * Une partie classée de bout en bout, en plein écran par-dessus les onglets : recherche
 * d'adversaire, partie en quatre manches, résultat (trophées, ligue), puis « rejouer » ou
 * retour à l'accueil des duels par [onClose].
 */
@Composable
fun DuelFlow(language: AppLanguage, onClose: () -> Unit, modifier: Modifier = Modifier) {
    Box(modifier = modifier.fillMaxSize())
}
