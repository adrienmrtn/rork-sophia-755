import SwiftUI
import UIKit

/// User-chosen appearance. Factory default is always light — never follow the system
/// until the user explicitly picks Automatic in Settings.
enum AppearancePreference: String, CaseIterable, Identifiable, Codable, Sendable {
    case light
    case dark
    case system

    var id: String { rawValue }

    /// `nil` lets the system decide (Automatic). Light / Night pin the scheme.
    /// Used on the app window. Modal presentations must not pass `nil` — they do
    /// not inherit the window scheme and would stay light (see `resolvedPresentedColorScheme`).
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }

    /// Concrete scheme for `sheet` / `fullScreenCover`, which open a new presentation
    /// that does **not** inherit the window's `preferredColorScheme`.
    ///
    /// Automatic reads the **screen** traits (the device appearance), not the current
    /// view's traits — otherwise a light sheet would snapshot itself as light forever.
    func resolvedPresentedColorScheme() -> ColorScheme {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system:
            return UIScreen.main.traitCollection.userInterfaceStyle == .dark ? .dark : .light
        }
    }

    var presentedUserInterfaceStyle: UIUserInterfaceStyle {
        resolvedPresentedColorScheme() == .dark ? .dark : .light
    }

    var localizationKey: String {
        switch self {
        case .light: "settings.appearance.light"
        case .dark: "settings.appearance.dark"
        case .system: "settings.appearance.automatic"
        }
    }

    var systemImage: String {
        switch self {
        case .light: "sun.max"
        case .dark: "moon"
        case .system: "circle.lefthalf.filled"
        }
    }
}

@Observable
final class AppearanceManager {
    static let shared = AppearanceManager()
    static let userDefaultsKey = "sophia_appearance_preference"

    private let defaults: UserDefaults
    private(set) var preference: AppearancePreference

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let stored = defaults.string(forKey: Self.userDefaultsKey),
           let value = AppearancePreference(rawValue: stored) {
            preference = value
        } else {
            preference = .light
        }
    }

    func setPreference(_ preference: AppearancePreference) {
        guard self.preference != preference else { return }
        self.preference = preference
        defaults.set(preference.rawValue, forKey: Self.userDefaultsKey)
    }
}

/// Sheets and `fullScreenCover` open a new presentation that does **not** inherit
/// the window's `preferredColorScheme`. Apply this on every post-onboarding modal
/// so Night / Automatic actually reach Settings, Course, Account, legal, etc.
///
/// Paywalls and onboarding stay forced light — do not attach this there.
struct SophiaColorSchemeModifier: ViewModifier {
    @Environment(AppearanceManager.self) private var appearance

    func body(content: Content) -> some View {
        let scheme = appearance.preference.resolvedPresentedColorScheme()
        content
            .preferredColorScheme(scheme)
            .presentationBackground(DS.resolvedCanvas(for: scheme))
            .background {
                SophiaInterfaceStyleBridge(style: appearance.preference.presentedUserInterfaceStyle)
                    .frame(width: 0, height: 0)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
    }
}

/// SwiftUI's `preferredColorScheme` is ignored by many modal hosting controllers.
/// Walking to the nearest `UIViewController` and setting `overrideUserInterfaceStyle`
/// is what actually flips `DS.*` adaptive tokens on Settings and other covers.
private struct SophiaInterfaceStyleBridge: UIViewRepresentable {
    var style: UIUserInterfaceStyle

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isHidden = true
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        apply(style, from: uiView)
        DispatchQueue.main.async {
            apply(style, from: uiView)
        }
    }

    private func apply(_ style: UIUserInterfaceStyle, from view: UIView) {
        var node: UIResponder? = view.next
        while let current = node {
            if let controller = current as? UIViewController {
                if controller.overrideUserInterfaceStyle != style {
                    controller.overrideUserInterfaceStyle = style
                }
                if let presented = controller.presentedViewController,
                   presented.overrideUserInterfaceStyle != style {
                    presented.overrideUserInterfaceStyle = style
                }
                return
            }
            node = current.next
        }
    }
}

extension View {
    func sophiaColorScheme() -> some View {
        modifier(SophiaColorSchemeModifier())
    }

    /// Sheet chrome (grabber, unused area) follows the design-system canvas.
    func sophiaSheetChrome() -> some View {
        sophiaColorScheme()
    }
}
