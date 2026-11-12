import SwiftUI
import UIKit

/// Barre d'onglets « Elevate arrondi » : fond blanc opaque, filet en haut, icône et libellé
/// bleus pour l'onglet actif, gris sinon, libellés en Plus Jakarta Sans.
enum SophiaTabBarStyle {
    static func apply() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = DS.uiCanvas
        appearance.shadowColor = DS.uiHairline

        let item = UITabBarItemAppearance()
        style(item.normal, color: DS.uiInkSecondary)
        style(item.selected, color: DS.uiAccent)
        appearance.stackedLayoutAppearance = item
        appearance.inlineLayoutAppearance = item
        appearance.compactInlineLayoutAppearance = item

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = DS.uiAccent
        UITabBar.appearance().unselectedItemTintColor = DS.uiInkSecondary
    }

    /// À appeler avant la création de la barre (valeur initiale d'un `@State` de la vue qui porte
    /// la `TabView`) : l'apparence posée plus tard, dans `onAppear`, n'atteint pas toujours une
    /// barre déjà construite. Sans effet après le premier appel.
    @discardableResult
    static func applyOnce() -> Bool {
        if !applied {
            applied = true
            apply()
        }
        return true
    }

    private static var applied = false

    private static func style(_ state: UITabBarItemStateAppearance, color: UIColor) {
        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: "Plus Jakarta Sans",
            .traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.medium],
        ])
        state.iconColor = color
        state.titleTextAttributes = [
            .foregroundColor: color,
            .font: UIFont(descriptor: descriptor, size: 11),
        ]
    }
}

enum SophiaTheme {
    static let background = Color(red: 0.04, green: 0.086, blue: 0.157)
    static let cardBackground = Color(red: 0.07, green: 0.12, blue: 0.2)
    static let emerald = Color(red: 0.20, green: 0.83, blue: 0.60)
    static let accent = Color(red: 0.56, green: 0.40, blue: 0.92)
    static let streakOrange = Color(red: 0.96, green: 0.62, blue: 0.04)
    static let errorRed = Color(red: 0.95, green: 0.30, blue: 0.35)
    static let successGreen = Color(red: 0.20, green: 0.83, blue: 0.60)

    static let cardGradient = LinearGradient(
        colors: [Color.black.opacity(0), Color.black.opacity(0.85)],
        startPoint: .center,
        endPoint: .bottom
    )
}
