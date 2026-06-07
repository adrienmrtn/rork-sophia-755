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
