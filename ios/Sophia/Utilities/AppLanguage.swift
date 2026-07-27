import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case french = "fr"
    case english = "en"
    case spanish = "es"
    case german = "de"
    case portuguese = "pt"
    case italian = "it"
    case turkish = "tr"
    case polish = "pl"
    case romanian = "ro"
    case dutch = "nl"
    case greek = "el"
    case swedish = "sv"
    case hungarian = "hu"
    case bulgarian = "bg"
    case czech = "cs"

    var id: String { rawValue }

    var localeIdentifier: String {
        switch self {
        case .french: "fr_FR"
        case .english: "en_US"
        case .spanish: "es_ES"
        case .german: "de_DE"
        case .portuguese: "pt_PT"
        case .italian: "it_IT"
        case .turkish: "tr_TR"
        case .polish: "pl_PL"
        case .romanian: "ro_RO"
        case .dutch: "nl_NL"
        case .greek: "el_GR"
        case .swedish: "sv_SE"
        case .hungarian: "hu_HU"
        case .bulgarian: "bg_BG"
        case .czech: "cs_CZ"
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
        case .turkish: "🇹🇷"
        case .polish: "🇵🇱"
        case .romanian: "🇷🇴"
        case .dutch: "🇳🇱"
        case .greek: "🇬🇷"
        case .swedish: "🇸🇪"
        case .hungarian: "🇭🇺"
        case .bulgarian: "🇧🇬"
        case .czech: "🇨🇿"
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
        case .turkish: "Türkçe"
        case .polish: "Polski"
        case .romanian: "Română"
        case .dutch: "Nederlands"
        case .greek: "Ελληνικά"
        case .swedish: "Svenska"
        case .hungarian: "Magyar"
        case .bulgarian: "Български"
        case .czech: "Čeština"
        }
    }

    /// Fallback when the device language is not one of the supported app languages.
    static let defaultLanguage: AppLanguage = .english

    static let userDefaultsKey = "sophia_app_language"

    /// Best matching app language for the phone's preferred languages (e.g. `fr-FR` → `.french`).
    static func preferredFromDevice() -> AppLanguage {
        for identifier in Locale.preferredLanguages {
            let normalized = identifier
                .replacingOccurrences(of: "_", with: "-")
                .lowercased()
            let primary = String(normalized.split(separator: "-").first ?? Substring(normalized))
            if let match = AppLanguage(rawValue: primary) {
                return match
            }
        }
        return defaultLanguage
    }

    /// Reads the persisted language, or the phone language on first launch (then persists it).
    static func currentPersisted() -> AppLanguage {
        if let stored = UserDefaults.standard.string(forKey: userDefaultsKey),
           let language = AppLanguage(rawValue: stored) {
            return language
        }
        let detected = preferredFromDevice()
        UserDefaults.standard.set(detected.rawValue, forKey: userDefaultsKey)
        return detected
    }
}
