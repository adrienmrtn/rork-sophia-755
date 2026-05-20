import SwiftUI

/// GenK-inspired palette: cream paper backgrounds, pastel blue/pink cards,
/// pitch black CTAs and tags, warm yellow accents, rounded playful type.
enum SophiaTheme {
    // Surfaces
    static let background = Color(red: 0.96, green: 0.93, blue: 0.86)        // warm cream paper
    static let cardBackground = Color(red: 0.99, green: 0.97, blue: 0.92)    // off-white card
    static let pastelBlue = Color(red: 0.82, green: 0.91, blue: 0.94)        // GenK pastel blue
    static let pastelPink = Color(red: 0.97, green: 0.78, blue: 0.82)        // GenK pastel pink
    static let pastelMint = Color(red: 0.80, green: 0.92, blue: 0.85)
    static let pastelLavender = Color(red: 0.88, green: 0.84, blue: 0.97)

    // Brand
    /// Primary CTA color — pure black, GenK-style.
    static let emerald = Color.black
    /// Secondary accent — pastel pink for chips & tags.
    static let accent = Color(red: 0.97, green: 0.78, blue: 0.82)
    /// Streak / energy color — warm yellow.
    static let streakOrange = Color(red: 1.0, green: 0.82, blue: 0.14)
    static let errorRed = Color(red: 0.93, green: 0.30, blue: 0.32)
    static let successGreen = Color(red: 0.30, green: 0.72, blue: 0.40)

    // Text
    static let textPrimary = Color(red: 0.08, green: 0.08, blue: 0.10)
    static let textSecondary = Color(red: 0.08, green: 0.08, blue: 0.10).opacity(0.6)
    static let textTertiary = Color(red: 0.08, green: 0.08, blue: 0.10).opacity(0.4)

    static let cardGradient = LinearGradient(
        colors: [Color.black.opacity(0), Color.black.opacity(0.55)],
        startPoint: .center,
        endPoint: .bottom
    )
}
