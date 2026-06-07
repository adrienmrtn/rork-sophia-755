import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case french = "fr"
    case english = "en"

    var id: String { rawValue }

    var localeIdentifier: String {
        switch self {
        case .french: "fr_FR"
        case .english: "en_US"
        }
    }

    var flag: String {
        switch self {
        case .french: "🇫🇷"
        case .english: "🇬🇧"
        }
    }

    var displayName: String {
        switch self {
        case .french: "Français"
        case .english: "English"
        }
    }

    /// Resolves the initial language from the device locale.
    /// French if the system language is French; otherwise English.
    static func resolvedFromSystem() -> AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.lowercased().hasPrefix("fr") { return .french }
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
