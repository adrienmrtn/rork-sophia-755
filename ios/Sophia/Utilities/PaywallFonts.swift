import CoreText
import SwiftUI

/// Embedded paywall fonts.
/// - Quicksand / Nunito: OFL (Google Fonts)
/// - Product Sans: proprietary — Plus Jakarta Sans Bold is used as the licensed substitute (same role in Figma).
enum PaywallFonts {
    private static var didRegister = false

    static let quicksandFamily = "Quicksand"
    static let nunitoFamily = "Nunito"
    /// Figma « Product Sans » → Plus Jakarta Sans Bold (redistributable substitute).
    static let productSansFamily = "Plus Jakarta Sans"

    static func registerIfNeeded() {
        guard !didRegister else { return }
        didRegister = true

        let names = ["Quicksand", "Nunito", "PlusJakartaSans"]
        for name in names {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf")
                ?? Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
                ?? Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Resources/Fonts") else {
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    static func productSans(_ size: CGFloat, width: CGFloat) -> Font {
        .custom(productSansFamily, size: PaywallDesign.s(size, width: width)).weight(.bold)
    }

    static func quicksandBold(_ size: CGFloat, width: CGFloat) -> Font {
        .custom(quicksandFamily, size: PaywallDesign.s(size, width: width)).weight(.bold)
    }

    static func quicksandSemiBold(_ size: CGFloat, width: CGFloat) -> Font {
        .custom(quicksandFamily, size: PaywallDesign.s(size, width: width)).weight(.semibold)
    }

    static func nunitoExtraBold(_ size: CGFloat, width: CGFloat) -> Font {
        .custom(nunitoFamily, size: PaywallDesign.s(size, width: width)).weight(.heavy)
    }
}
