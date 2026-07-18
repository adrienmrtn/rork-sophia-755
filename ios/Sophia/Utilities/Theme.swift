import SwiftUI
import UIKit

/// Calm tab bar chrome — matches the `DS` design system (soft canvas, navy accent,
/// muted slate for unselected items), replacing the previous cream/black neo-brutalist look.
enum SophiaTabBarStyle {
    static func apply() {
        let canvas = UIColor(red: 0.969, green: 0.973, blue: 0.980, alpha: 1)
        let accent = UIColor(red: 0.102, green: 0.227, blue: 0.420, alpha: 1)
        let inkTertiary = UIColor(red: 0.604, green: 0.643, blue: 0.698, alpha: 1)
        let hairline = UIColor(red: 0.894, green: 0.906, blue: 0.925, alpha: 1)

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = canvas
        appearance.shadowColor = hairline
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = accent
        UITabBar.appearance().unselectedItemTintColor = inkTertiary
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
