import SwiftUI

/// Vertical rhythm measured from Figma node `167:93` (gaps between sections, not absolute canvas coords).
enum PaywallSpacing {
    static let horizontal: CGFloat = 27
    static let headlineMaxWidth: CGFloat = 346

    static let afterHeader: CGFloat = 50
    static let afterSubjects: CGFloat = 36
    static let afterWeapon: CGFloat = 28
    static let betweenBenefits: CGFloat = 8
    static let afterBenefits: CGFloat = 40
    static let afterPremiumHeadline: CGFloat = 24
    static let afterTable: CGFloat = 24
    static let betweenPlans: CGFloat = 27
    static let afterPlans: CGFloat = 20
}

struct PaywallBenefitItem: Identifiable {
    let textKey: String
    let color: Color
    let rotation: Double
    let leadingInset: CGFloat

    var id: String { textKey }
}

extension PaywallBenefitItem {
    static func figmaItems() -> [PaywallBenefitItem] {
        [
            PaywallBenefitItem(
                textKey: "paywall.benefit.conversations",
                color: Color(red: 1, green: 0.820, blue: 0.659),
                rotation: -2.95,
                leadingInset: 30
            ),
            PaywallBenefitItem(
                textKey: "paywall.benefit.curiosity",
                color: Color(red: 1, green: 0.839, blue: 0.945),
                rotation: 3.09,
                leadingInset: 84
            ),
            PaywallBenefitItem(
                textKey: "paywall.benefit.confidence",
                color: Color(red: 0.792, green: 0.867, blue: 0.898),
                rotation: -2.08,
                leadingInset: 27
            ),
            PaywallBenefitItem(
                textKey: "paywall.benefit.screenTime",
                color: Color(red: 0.937, green: 0.992, blue: 0.882),
                rotation: 0.79,
                leadingInset: 68
            ),
        ]
    }
}
