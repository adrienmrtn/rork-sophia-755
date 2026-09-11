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
    case danish = "da"
    case norwegian = "nb"
    case russian = "ru"
    case croatian = "hr"
    case slovenian = "sl"
    case slovak = "sk"
    case serbian = "sr"

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
        case .danish: "da_DK"
        case .norwegian: "nb_NO"
        case .russian: "ru_RU"
        case .croatian: "hr_HR"
        case .slovenian: "sl_SI"
        case .slovak: "sk_SK"
        case .serbian: "sr_RS"
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
        case .danish: "🇩🇰"
        case .norwegian: "🇳🇴"
        case .russian: "🇷🇺"
        case .croatian: "🇭🇷"
        case .slovenian: "🇸🇮"
        case .slovak: "🇸🇰"
        case .serbian: "🇷🇸"
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
        case .danish: "Dansk"
        case .norwegian: "Norsk"
        case .russian: "Русский"
        case .croatian: "Hrvatski"
        case .slovenian: "Slovenščina"
        case .slovak: "Slovenčina"
        case .serbian: "Српски"
        }
    }

    /// Device language codes that are not our raw values but map onto one.
    /// iOS reports Norwegian as `nb`, `nn` or the `no` macrolanguage depending
    /// on the device. Bosnian and Montenegrin have no table of their own; their
    /// speakers read the Croatian one, which is Latin script like their own
    /// keyboards (Serbian ships in Cyrillic). `sh` is the retired Serbo-Croatian
    /// code and lands there too.
    private static let deviceCodeAliases: [String: String] = [
        "no": "nb",
        "nn": "nb",
        "bs": "hr",
        "sh": "hr",
        "cnr": "hr",
    ]

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
            if let match = AppLanguage(rawValue: deviceCodeAliases[primary] ?? primary) {
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

    /// Very-short weekday letters Monday→Sunday for streak calendars (never hardcode French LMMJVSD).
    var mondayFirstWeekdayLetters: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        let symbols = formatter.veryShortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        guard symbols.count == 7 else { return symbols }
        // Foundation orders Sunday-first; our week strip is Monday-first.
        return Array(symbols[1...]) + [symbols[0]]
    }
}
