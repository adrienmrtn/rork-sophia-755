import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case french = "fr"
    case english = "en"
    case german = "de"

    var id: String { rawValue }

    var localeIdentifier: String {
        switch self {
        case .french: "fr_FR"
        case .english: "en_US"
        case .german: "de_DE"
        }
    }

    var flag: String {
        switch self {
        case .french: "🇫🇷"
        case .english: "🇬🇧"
        case .german: "🇩🇪"
        }
    }

    var displayName: String {
        switch self {
        case .french: "Français"
        case .english: "English"
        case .german: "Deutsch"
        }
    }

    /// Resolves the initial language from the device locale.
    static func resolvedFromSystem() -> AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        let code = preferred.lowercased()
        if code.hasPrefix("fr") { return .french }
        if code.hasPrefix("de") { return .german }
        return .english
    }

    static let userDefaultsKey = "sophia_app_language"

    /// Reads the persisted language, or resolves from the system locale.
    static func currentPersisted() -> AppLanguage {
        if let stored = UserDefaults.standard.string(forKey: userDefaultsKey),
           let language = AppLanguage(rawValue: stored) {
            return language
        }
        return resolvedFromSystem()
    }
}
