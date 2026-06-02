import SwiftUI
import UIKit

enum SophiaTabBarStyle {
    static func apply() {
        let cream = UIColor(red: 0.984, green: 0.961, blue: 0.918, alpha: 1)
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = cream
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.08)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = .black
        UITabBar.appearance().unselectedItemTintColor = UIColor.black.withAlphaComponent(0.35)
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
