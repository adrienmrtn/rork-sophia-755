import SwiftUI

enum OnboardingScreenColors {
    static let blush = Color(red: 0.996, green: 0.588, blue: 0.737)
    static let projectionPink = Color(red: 254.0 / 255.0, green: 150.0 / 255.0, blue: 188.0 / 255.0)
    static let goldXP = Color(red: 1.0, green: 0.88, blue: 0.56)

    static func background(for screen: Int) -> Color {
        switch screen {
        case 3: return blush
        case 7: return OnboardingPastels.at(0)   // Showcase Cours — peach
        case 9: return projectionPink            // Projection — animation
        case 10: return OnboardingPastels.at(1)  // Showcase Quiz — mint
        case 11: return OnboardingPastels.at(4)  // Showcase Cartes — lavande
        case 12: return OnboardingPastels.at(5)  // Showcase Collections — sky
        case 13: return goldXP                   // Showcase XP — gold
        default: return BrutalPalette.cream
        }
    }
}
