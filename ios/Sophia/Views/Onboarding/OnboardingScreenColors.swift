import SwiftUI

enum OnboardingScreenColors {
    static let blush = Color(red: 0.996, green: 0.588, blue: 0.737)
    static let projectionPink = Color(red: 254.0 / 255.0, green: 150.0 / 255.0, blue: 188.0 / 255.0)

    static func background(for screen: Int) -> Color {
        switch screen {
        case 3: return blush
        case 8: return projectionPink
        default: return BrutalPalette.cream
        }
    }
}
