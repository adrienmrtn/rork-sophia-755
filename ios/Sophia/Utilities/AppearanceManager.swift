import SwiftUI

/// User-chosen appearance. Factory default is always light — never follow the system
/// until the user explicitly picks Automatic in Settings.
enum AppearancePreference: String, CaseIterable, Identifiable, Codable, Sendable {
    case light
    case dark
    case system

    var id: String { rawValue }

    /// `nil` lets the system decide (Automatic). Light / Night pin the scheme.
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
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
