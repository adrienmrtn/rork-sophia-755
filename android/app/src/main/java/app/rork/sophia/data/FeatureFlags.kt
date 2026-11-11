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
     * Les duels (onglet, trophées et ligue d'un ami) : visibles quand l'app est en anglais, la
     * seule langue des questions pour l'instant. Comme sur iOS, à lire une fois au lancement :
     * un changement de langue prend effet au lancement suivant, pour ne pas faire apparaître
     * ou disparaître un onglet sous les doigts.
     */
    fun duelsVisible(language: app.rork.sophia.domain.AppLanguage): Boolean =
        language == app.rork.sophia.domain.AppLanguage.ENGLISH
}
