import Foundation

/// Drapeaux de fonctionnalités de l'app.
///
/// Un seul pour l'instant : la navigation « nouvelle génération » (4 onglets Accueil /
/// Explorer / Apprendre / Profil, fil unique, nouveau profil, page créateur), tirée au sort
/// une fois par installation pour un A/B contre les 5 onglets actuels. La variante est lue
/// une fois au lancement de `ContentView` ; un changement (réglage de debug) prend effet au
/// prochain lancement, pour ne pas changer la navigation sous les doigts de l'utilisateur.
enum FeatureFlags {
    enum NavigationVariant: String, CaseIterable {
        /// Les 5 onglets historiques et le fil TikTok.
        case classic
        /// Les écrans de la maquette « Sophia nouvelle génération ».
        case newGen = "newgen"
    }

    static let navigationKey = "sophia_nav_variant"

    /// Part des installations qui reçoivent la nouvelle navigation au tirage.
    static let newGenShare: Double = 0.5

    /// Variante de navigation : tirée au sort à la première lecture, stable ensuite.
    static var navigationVariant: NavigationVariant {
        get {
            let defaults = UserDefaults.standard
            if let raw = defaults.string(forKey: navigationKey), let variant = NavigationVariant(rawValue: raw) {
                return variant
            }
            let drawn: NavigationVariant = Double.random(in: 0..<1) < newGenShare ? .newGen : .classic
            defaults.set(drawn.rawValue, forKey: navigationKey)
            return drawn
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: navigationKey) }
    }

    static var newNavigation: Bool { navigationVariant == .newGen }
}
