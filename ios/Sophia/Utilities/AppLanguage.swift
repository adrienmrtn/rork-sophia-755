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

    /// The default language used when the user has not chosen one yet.
    static let defaultLanguage: AppLanguage = .english

    static let userDefaultsKey = "sophia_app_language"

    /// Reads the persisted language, or falls back to the default language (English).
    static func currentPersisted() -> AppLanguage {
        if let stored = UserDefaults.standard.string(forKey: userDefaultsKey),
           let language = AppLanguage(rawValue: stored) {
            return language
        }
        return defaultLanguage
    }
}
