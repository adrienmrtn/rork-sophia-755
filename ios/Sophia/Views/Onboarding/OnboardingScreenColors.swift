import SwiftUI

enum OnboardingScreenColors {
    static let blush = Color(red: 0.996, green: 0.588, blue: 0.737)
    static let projectionPink = Color(red: 254.0 / 255.0, green: 150.0 / 255.0, blue: 188.0 / 255.0)
    static let goldXP = Color(red: 1.0, green: 0.88, blue: 0.56)

    static func background(for screen: Int) -> Color {
        switch screen {
        case 4: return blush
        case 8: return OnboardingPastels.at(0)   // Showcase Cours — peach
        case 10: return projectionPink           // Projection — animation
        case 11: return OnboardingPastels.at(1)  // Showcase Quiz — mint
        case 12: return goldXP                   // Showcase Cartes + XP — gold
        case 13: return OnboardingPastels.at(5)  // Showcase Collections — sky
        case 15: return OnboardingPastels.at(1)  // Programme personnalisé — mint
        default: return BrutalPalette.cream
        }
    }
}
