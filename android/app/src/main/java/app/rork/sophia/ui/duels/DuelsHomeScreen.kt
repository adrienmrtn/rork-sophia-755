package app.rork.sophia.ui.duels

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import app.rork.sophia.domain.AppLanguage

/**
 * L'onglet Duels : ma ligue et mes trophées, le bouton pour chercher un adversaire, le
 * classement des amis, mes statistiques et mes dernières parties. Sans compte, il propose de
 * se connecter.
 *
 * [isActive] : l'onglet est à l'écran (il reste monté quand on en sort) ; [flowShown] : une
 * partie est en cours par-dessus, l'accueil ne se recharge pas pendant ce temps ; [onPlay]
 * ouvre la partie ([DuelFlow]).
 */
@Composable
fun DuelsHomeScreen(
    language: AppLanguage,
    isActive: Boolean,
    flowShown: Boolean,
    onPlay: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Box(modifier = modifier.fillMaxSize())
}
