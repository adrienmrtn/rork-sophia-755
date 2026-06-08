import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case french = "fr"
    case english = "en"
    case spanish = "es"
    case german = "de"
    case portuguese = "pt"
    case italian = "it"

    var id: String { rawValue }

    var localeIdentifier: String {
        switch self {
        case .french: "fr_FR"
        case .english: "en_US"
        case .spanish: "es_ES"
        case .german: "de_DE"
        case .portuguese: "pt_PT"
        case .italian: "it_IT"
        }
    }

    var flag: String {
        switch self {
        case .french: "🇫🇷"
        case .english: "🇬🇧"
        case .spanish: "🇪🇸"
        case .german: "🇩🇪"
        case .portuguese: "🇵🇹"
        case .italian: "🇮🇹"
        }
    }

    var displayName: String {
        switch self {
        case .french: "Français"
        case .english: "English"
        case .spanish: "Español"
        case .german: "Deutsch"
        case .portuguese: "Português"
        case .italian: "Italiano"
        }
    }

    /// Resolves the initial language from the device locale.
    static func resolvedFromSystem() -> AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        let code = preferred.lowercased()
        if code.hasPrefix("fr") { return .french }
        if code.hasPrefix("es") { return .spanish }
        if code.hasPrefix("de") { return .german }
        if code.hasPrefix("pt") { return .portuguese }
        if code.hasPrefix("it") { return .italian }
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
