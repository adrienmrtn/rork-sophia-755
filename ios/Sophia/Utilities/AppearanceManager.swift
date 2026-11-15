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
    /// Automatic reads the **device** appearance, not the current view's traits —
    /// otherwise a light sheet would snapshot itself as light forever. [systemScheme] is
    /// passed in rather than sampled from `UIScreen` here: a bare read is not observable, so
    /// a course open on Automatic stayed light for as long as it was on screen when the
    /// phone switched to dark. `AppearanceManager.systemColorScheme` is observable and
    /// updates on the trait change, which is what makes the open course follow along.
    func resolvedPresentedColorScheme(systemScheme: ColorScheme) -> ColorScheme {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return systemScheme
        }
    }

    func presentedUserInterfaceStyle(systemScheme: ColorScheme) -> UIUserInterfaceStyle {
        resolvedPresentedColorScheme(systemScheme: systemScheme) == .dark ? .dark : .light
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

    /// The device's current appearance, kept up to date so Automatic can react to it.
    ///
    /// Observed rather than sampled: a plain `UIScreen.main.traitCollection` read inside a
    /// view does not re-run when the phone switches to dark, which is why a course opened on
    /// Automatic stayed light until it was closed and reopened.
    private(set) var systemColorScheme: ColorScheme =
        UIScreen.main.traitCollection.userInterfaceStyle == .dark ? .dark : .light

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

    func updateSystemColorScheme(_ scheme: ColorScheme) {
        guard systemColorScheme != scheme else { return }
        systemColorScheme = scheme
    }

    /// What the whole app should render as right now.
    var effectiveColorScheme: ColorScheme {
        preference.resolvedPresentedColorScheme(systemScheme: systemColorScheme)
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
        // Reading the observable `effectiveColorScheme` is what re-runs this body when the
        // device appearance changes under Automatic.
        let scheme = appearance.effectiveColorScheme
        content
            .preferredColorScheme(scheme)
            .presentationBackground(DS.resolvedCanvas(for: scheme))
            .background {
                SophiaInterfaceStyleBridge(style: scheme == .dark ? .dark : .light)
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

/// Reports the device's appearance to [AppearanceManager] whenever it changes.
///
/// Observation is registered on the **window scene**, not on this view. The app pins a
/// scheme on its root, which sets `overrideUserInterfaceStyle` on the hosting controller: a
/// view inside that subtree never sees its own traits change when the device flips, so a
/// view-level registration would simply never fire. The scene's traits do follow the device.
struct SystemAppearanceObserver: UIViewRepresentable {
    let onChange: (ColorScheme) -> Void

    func makeUIView(context: Context) -> TraitObservingView {
        let view = TraitObservingView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        view.onChange = onChange
        return view
    }

    func updateUIView(_ uiView: TraitObservingView, context: Context) {
        uiView.onChange = onChange
        uiView.report()
    }

    static func dismantleUIView(_ uiView: TraitObservingView, coordinator: ()) {
        uiView.unregister()
    }

    final class TraitObservingView: UIView {
        var onChange: ((ColorScheme) -> Void)?
        private var registration: UITraitChangeRegistration?
        private var sceneObserver: NSObjectProtocol?

        func report() {
            let style = window?.windowScene?.traitCollection.userInterfaceStyle
                ?? UIScreen.main.traitCollection.userInterfaceStyle
            onChange?(style == .dark ? .dark : .light)
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            registerIfNeeded()
            report()
        }

        private func registerIfNeeded() {
            guard registration == nil, let scene = window?.windowScene else { return }
            registration = scene.registerForTraitChanges(
                [UITraitUserInterfaceStyle.self]
            ) { [weak self] (_: UITraitEnvironment, _: UITraitCollection) in
                self?.report()
            }
            // Changing the appearance while the app is backgrounded does not deliver a trait
            // change to a scene that is not on screen; re-reading on activation covers it.
            sceneObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.report() }
            }
        }

        func unregister() {
            if let registration, let scene = window?.windowScene {
                scene.unregisterForTraitChanges(registration)
            }
            registration = nil
            if let sceneObserver {
                NotificationCenter.default.removeObserver(sceneObserver)
            }
            sceneObserver = nil
        }
    }
}
