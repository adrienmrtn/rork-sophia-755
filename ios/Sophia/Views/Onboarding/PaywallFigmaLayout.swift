import SwiftUI

/// Absolute layout metrics from Figma node `167:93` (402 × 1802).
/// Coordinates are in Figma points; scale with `PaywallDesign.s(_:width:)`.
enum PaywallFigmaLayout {
    static let canvasWidth: CGFloat = 402

    /// Extra top inset so canvas content clears the status bar (close button uses `safeAreaInset`).
    static let topContentInset: CGFloat = 48

    /// Scroll content height — ends after plans + legal, excluding Figma mid-CTA (y≈730) and bottom band (y≈1617).
    static let scrollHeight: CGFloat = 1_635 + topContentInset

    // MARK: - Headlines & highlights

    static let headerText = CGRect(x: 27, y: 119.54, width: 330, height: 113)
    static let headerHighlight = CGRect(x: 128, y: 182, width: 211, height: 14)

    static let weaponText = CGRect(x: 27, y: 577, width: 330, height: 76)
    static let weaponHighlight = CGRect(x: 25, y: 642, width: 125, height: 14)

    static let premiumText = CGRect(x: 27, y: 949, width: 339, height: 118)
    static let premiumHighlight = CGRect(x: 25, y: 1_051, width: 262, height: 14)

    // MARK: - Decorations

    static let lightbulb = CGRect(x: 311.77, y: 232.03, width: 72.789, height: 90.739)
    static let lightbulbRotation: Double = 15.61

    static let phi = CGRect(x: 313.42, y: 600.51, width: 74.497, height: 86.593)
    static let phiRotation: Double = -9.06

    static let pencil = CGRect(x: -32.81, y: 430, width: 141.834, height: 104.187)
    static let pencilRotation: Double = -178.83

    static let subjectsCard = CGRect(x: 24.99, y: 282.16, width: 347.016, height: 191.674)
    static let subjectsCardRotation: Double = -1.98
    static let subjectsCardInner = CGSize(width: 341, height: 180)

    // MARK: - Stars

    static let star1 = CGRect(x: 313, y: 218, width: 15, height: 14)
    static let star2 = CGRect(x: 303, y: 243, width: 9, height: 8)
    static let star3 = CGRect(x: 122.57, y: 514.01, width: 15, height: 13)
    static let star4 = CGRect(x: 111.57, y: 494.01, width: 8, height: 9)
    static let star5 = CGRect(x: 288, y: 640, width: 9, height: 9)
    static let star6 = CGRect(x: 300, y: 624, width: 6, height: 6)

    // MARK: - Benefits

    struct Benefit {
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat
        let cardWidth: CGFloat
        let cardHeight: CGFloat
        let rotation: Double
        let color: Color
        let textKey: String
    }

    static let benefits: [Benefit] = [
        Benefit(x: 57, y: 689, width: 255.185, height: 61.942, cardWidth: 253, cardHeight: 49, rotation: -2.95,
                color: Color(red: 1, green: 0.820, blue: 0.659), textKey: "paywall.benefit.conversations"),
        Benefit(x: 111.3, y: 743.72, width: 229.674, height: 61.185, cardWidth: 227.363, cardHeight: 49, rotation: 3.09,
                color: Color(red: 1, green: 0.839, blue: 0.945), textKey: "paywall.benefit.curiosity"),
        Benefit(x: 54.49, y: 797.24, width: 242.624, height: 57.709, cardWidth: 241.005, cardHeight: 49, rotation: -2.08,
                color: Color(red: 0.792, green: 0.867, blue: 0.898), textKey: "paywall.benefit.confidence"),
        Benefit(x: 95.25, y: 851.01, width: 261.767, height: 52.605, cardWidth: 261.114, cardHeight: 49, rotation: 0.79,
                color: Color(red: 0.937, green: 0.992, blue: 0.882), textKey: "paywall.benefit.screenTime"),
    ]

    // MARK: - Comparison & plans

    static let comparisonTable = CGRect(x: 29, y: 1_094, width: 339, height: 229)
    static let premiumColumn = CGRect(x: 285.97, y: 1_094, width: 82.032, height: 229)

    static let yearlyPlan = CGRect(x: 29, y: 1_347, width: 343, height: 117)
    static let monthlyPlan = CGRect(x: 29, y: 1_491, width: 343, height: 117)
    static let discountBadge = CGRect(x: 323, y: 1_442, width: 53, height: 33.83)

    static let legalRowY: CGFloat = 1_612
}

// MARK: - Canvas placement

extension View {
    /// Places a view at a Figma top-left coordinate inside a 402pt-wide canvas.
    func paywallFigmaPosition(
        x: CGFloat,
        y: CGFloat,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        layoutWidth: CGFloat
    ) -> some View {
        let scale = layoutWidth / PaywallFigmaLayout.canvasWidth
        let top = (y + PaywallFigmaLayout.topContentInset) * scale
        return frame(width: width.map { $0 * scale }, height: height.map { $0 * scale }, alignment: .topLeading)
            .offset(x: x * scale, y: top)
    }

    func paywallFigmaRect(_ rect: CGRect, layoutWidth: CGFloat) -> some View {
        paywallFigmaPosition(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height, layoutWidth: layoutWidth)
    }
}
