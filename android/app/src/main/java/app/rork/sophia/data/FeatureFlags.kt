package app.rork.sophia.data

import android.content.Context
import kotlin.random.Random

/**
 * Drapeaux de fonctionnalités de l'app.
 *
 * Un seul pour l'instant : la navigation « nouvelle génération » (4 onglets Accueil /
 * Explorer / Apprendre / Profil, fil unique, nouveau profil, page créateur), tirée au sort
 * une fois par installation pour un A/B contre les 5 onglets actuels. La variante est lue
 * une fois à la composition de `MainTabs` ; un changement (réglage de debug) prend effet au
 * prochain lancement, pour ne pas changer la navigation sous les doigts de l'utilisateur.
 *
 * Même clé et mêmes valeurs qu'iOS (`FeatureFlags.swift`), dans les préférences partagées
 * `sophia_prefs` du reste de l'app.
 */
object FeatureFlags {
    enum class NavigationVariant(val raw: String) {
        /** Les 5 onglets historiques et le fil TikTok. */
        CLASSIC("classic"),

        /** Les écrans de la maquette « Sophia nouvelle génération ». */
        NEWGEN("newgen");

        companion object {
            fun fromRaw(raw: String?): NavigationVariant? = entries.firstOrNull { it.raw == raw }
        }
    }

    private const val PREFS = "sophia_prefs"
    const val NAVIGATION_KEY = "sophia_nav_variant"

    /** Part des installations qui reçoivent la nouvelle navigation au tirage. */
    const val NEW_GEN_SHARE = 0.5

    /** Variante de navigation : tirée au sort à la première lecture, stable ensuite. */
    fun navigationVariant(context: Context): NavigationVariant {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        NavigationVariant.fromRaw(prefs.getString(NAVIGATION_KEY, null))?.let { return it }
        val drawn = if (Random.Default.nextDouble() < NEW_GEN_SHARE) NavigationVariant.NEWGEN else NavigationVariant.CLASSIC
        prefs.edit().putString(NAVIGATION_KEY, drawn.raw).apply()
        return drawn
    }

    fun setNavigationVariant(context: Context, variant: NavigationVariant) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(NAVIGATION_KEY, variant.raw)
            .apply()
    }

    fun newNavigation(context: Context): Boolean = navigationVariant(context) == NavigationVariant.NEWGEN

    /**
     * Les duels (onglet, trophées et ligue d'un ami) : ouverts dans toutes les langues de l'app.
     * Le serveur rend chaque question dans la langue du joueur (`duel_set_language`), et deux
     * joueurs de langues différentes jouent la même partie. Le paramètre reste pour les
     * appelants ; comme sur iOS, la valeur est lue une fois au lancement.
     */
    @Suppress("UNUSED_PARAMETER")
    fun duelsVisible(language: app.rork.sophia.domain.AppLanguage): Boolean = true
}
