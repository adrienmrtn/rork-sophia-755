import SwiftUI

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
