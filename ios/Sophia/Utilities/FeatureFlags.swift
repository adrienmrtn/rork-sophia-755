import Foundation

/// Drapeaux de fonctionnalités de l'app.
///
/// La navigation « nouvelle génération » (Accueil / Explorer / Profil, fil unique, nouveau
/// profil, page créateur) a d'abord été tirée au sort une fois par installation, en A/B contre
/// les 5 onglets historiques. Le tirage est terminé : tout le monde la reçoit, y compris les
/// installations qui avaient tiré `classic`.
enum FeatureFlags {
    enum NavigationVariant: String, CaseIterable {
        /// Les 5 onglets historiques et le fil TikTok. Plus servie.
        case classic
        /// Les écrans de la maquette « Sophia nouvelle génération ».
        case newGen = "newgen"
    }

    /// Variante de navigation, gardée pour la propriété `nav` des événements d'analyse.
    static var navigationVariant: NavigationVariant { .newGen }

    static var newNavigation: Bool { navigationVariant == .newGen }

    // MARK: - Duels

    /// Valeur de sélection de l'onglet Duels, à la suite des cinq onglets existants (0 à 4)
    /// pour ne pas décaler les leurs ; dans la barre, il se place entre Explorer et Profil.
    static let duelsTab = 5

    /// L'onglet Duels est ouvert dans toutes les langues de l'app : le serveur rend chaque
    /// question dans la langue du joueur (`duel_set_language`, `duel_ping`), et deux joueurs de
    /// langues différentes jouent la même partie. Le paramètre reste pour les appelants.
    static func duelsVisible(language: AppLanguage) -> Bool {
        true
    }
}
