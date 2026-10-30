import RevenueCat
import SwiftUI

@Observable
final class LanguageManager {
    static let shared = LanguageManager()

    private(set) var current: AppLanguage

    init() {
        current = AppLanguage.currentPersisted()
    }

    var locale: Locale {
        current.foundationLocale
    }

    /// Writing direction of the chosen language. `\.locale` does not imply it:
    /// SwiftUI resolves `\.layoutDirection` from the device, so an Arabic reader
    /// on an English phone would otherwise get a left-to-right screen.
    var layoutDirection: LayoutDirection {
        current.layoutDirection
    }

    func setLanguage(_ language: AppLanguage) {
        guard current != language else { return }
        current = language
        UserDefaults.standard.set(language.rawValue, forKey: AppLanguage.userDefaultsKey)
        UserDefaults.standard.set(true, forKey: AppLanguage.portugueseSplitKey)
        LocalizedContentLoader.resetCache()
        Self.reportToRevenueCat(language)
    }

    /// Tells RevenueCat which language this customer reads the app in, so trial starts and
    /// conversions can be compared language by language (customer attribute `app_language`).
    /// Sent at every launch and on every change; RevenueCat ignores unchanged values.
    static func reportToRevenueCat(_ language: AppLanguage = AppLanguage.currentPersisted()) {
        guard Purchases.isConfigured else { return }
        Purchases.shared.attribution.setAttributes(["app_language": language.rawValue])
    }

    func text(_ key: String) -> String {
        AppLocalizable.string(key, language: current)
    }

    /// A trial string with its day count filled in (see `AppLocalizable.trialString`).
    func trialText(_ key: String, days: Int) -> String {
        AppLocalizable.trialString(key, days: days, language: current)
    }
}
