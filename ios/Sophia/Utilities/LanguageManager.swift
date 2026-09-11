import SwiftUI

@Observable
final class LanguageManager {
    static let shared = LanguageManager()

    private(set) var current: AppLanguage

    init() {
        current = AppLanguage.currentPersisted()
    }

    var locale: Locale {
        Locale(identifier: current.localeIdentifier)
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
        LocalizedContentLoader.resetCache()
    }

    func text(_ key: String) -> String {
        AppLocalizable.string(key, language: current)
    }
}
