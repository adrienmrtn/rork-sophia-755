package app.rork.sophia.data

/**
 * Drapeaux de fonctionnalités de l'app.
 *
 * La navigation « nouvelle génération » (Accueil / Explorer / Profil, fil unique, nouveau
 * profil, page créateur) a d'abord été tirée au sort une fois par installation, en A/B contre
 * les 5 onglets historiques. Le tirage est terminé, comme sur iOS (`FeatureFlags.swift`) : tout
 * le monde la reçoit, y compris les installations qui avaient tiré `classic`.
 */
object FeatureFlags {
    enum class NavigationVariant(val raw: String) {
        /** Les 5 onglets historiques et le fil TikTok. Plus servie. */
        CLASSIC("classic"),

        /** Les écrans de la maquette « Sophia nouvelle génération ». */
        NEWGEN("newgen"),
    }

    /** Variante de navigation, gardée pour la propriété `nav` des événements d'analyse. */
    val navigationVariant: NavigationVariant get() = NavigationVariant.NEWGEN

    val newNavigation: Boolean get() = navigationVariant == NavigationVariant.NEWGEN

    /**
     * Les duels (onglet, trophées et ligue d'un ami) : ouverts dans toutes les langues de l'app.
     * Le serveur rend chaque question dans la langue du joueur (`duel_set_language`), et deux
     * joueurs de langues différentes jouent la même partie. Le paramètre reste pour les
     * appelants ; comme sur iOS, la valeur est lue une fois au lancement.
     */
    @Suppress("UNUSED_PARAMETER")
    fun duelsVisible(language: app.rork.sophia.domain.AppLanguage): Boolean = true
}
