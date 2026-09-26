import Foundation
import FamilyControls
import ManagedSettings

// Compiled into the main app AND the three Screen Time extensions (shield UI, shield
// action, device-activity monitor). Everything the extensions need to know about the
// blocker lives here and travels through the App Group container: an extension runs in
// its own process with its own `UserDefaults.standard`, so the group suite is the only
// memory the four of them share.
//
// Nothing here may depend on the app's design system, localisation tables or services:
// none of that exists inside an extension.

enum TikTokBlockerShared {
    /// App Group shared by the app and its extensions. Must match every `.entitlements`.
    static let appGroupId = "group.app.rork.sophia"

    /// The one `ManagedSettingsStore` the blocker writes to. Named, so that an extension
    /// and the app clear exactly the same shield and never touch another store's settings.
    static let storeName = ManagedSettingsStore.Name("sophia.tiktokBlocker")

    /// The device-activity schedule whose end closes an unlock window.
    static let unlockActivityName = "sophia.tiktokBlocker.unlock"

    /// Deep link the "come and unlock" notification carries.
    static let unlockDeepLink = "sophia://unlock"

    /// Notification identifier for the prompt, so a second tap replaces the first
    /// instead of stacking.
    static let unlockNotificationId = "sophia.tiktokBlocker.unlock-request"

    /// TikTok's URL scheme, used by the "Back to TikTok" button. Declared in the app's
    /// `LSApplicationQueriesSchemes` so `canOpenURL` can answer.
    static let tiktokURL = URL(string: "tiktok://")!

    /// Unlock lengths offered in settings, in minutes. DeviceActivity refuses schedules
    /// shorter than 15 minutes, which is where the floor comes from.
    static let unlockOptions = [15, 30, 60]
    static let defaultUnlockMinutes = 30

    /// A shield tap older than this is stale: the user tapped, got distracted, and should
    /// not be ambushed with a course hours later.
    static let pendingRequestLifetime: TimeInterval = 10 * 60

    enum Keys {
        static let enabled = "tiktokBlocker.enabled"
        static let selection = "tiktokBlocker.selection"
        static let unlockMinutes = "tiktokBlocker.unlockMinutes"
        static let unlockedUntil = "tiktokBlocker.unlockedUntil"
        static let pendingRequestAt = "tiktokBlocker.pendingRequestAt"
        static let language = "tiktokBlocker.language"
        static let unlockCount = "tiktokBlocker.unlockCount"
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupId) ?? .standard
    }

    // MARK: - State

    static var isEnabled: Bool {
        get { defaults.bool(forKey: Keys.enabled) }
        set { defaults.set(newValue, forKey: Keys.enabled) }
    }

    /// What the user ticked in the `FamilyActivityPicker`: TikTok, if they followed the
    /// instructions. Tokens are opaque and only meaningful on this device; Apple never
    /// tells us which app a token is, it only shields it.
    static var selection: FamilyActivitySelection {
        get {
            guard let data = defaults.data(forKey: Keys.selection),
                  let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            else { return FamilyActivitySelection() }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.selection)
            } else {
                defaults.removeObject(forKey: Keys.selection)
            }
        }
    }

    static var hasSelection: Bool {
        let s = selection
        return !(s.applicationTokens.isEmpty && s.categoryTokens.isEmpty && s.webDomainTokens.isEmpty)
    }

    /// Length of the window a finished course + quiz buys.
    static var unlockMinutes: Int {
        get {
            let stored = defaults.integer(forKey: Keys.unlockMinutes)
            return stored == 0 ? defaultUnlockMinutes : max(15, stored)
        }
        set { defaults.set(max(15, newValue), forKey: Keys.unlockMinutes) }
    }

    static var unlockedUntil: Date? {
        get { defaults.object(forKey: Keys.unlockedUntil) as? Date }
        set {
            if let newValue {
                defaults.set(newValue, forKey: Keys.unlockedUntil)
            } else {
                defaults.removeObject(forKey: Keys.unlockedUntil)
            }
        }
    }

    static var isUnlockWindowOpen: Bool {
        guard let until = unlockedUntil else { return false }
        return until > Date()
    }

    /// Written by the shield-action extension when the user taps "Open Sophia". The app
    /// reads it on activation and opens a course straight away.
    static var pendingRequestAt: Date? {
        get { defaults.object(forKey: Keys.pendingRequestAt) as? Date }
        set {
            if let newValue {
                defaults.set(newValue, forKey: Keys.pendingRequestAt)
            } else {
                defaults.removeObject(forKey: Keys.pendingRequestAt)
            }
        }
    }

    /// A tap on "Open Sophia" that the app has not consumed yet.
    static var isRequestPending: Bool {
        guard let at = pendingRequestAt else { return false }
        return Date().timeIntervalSince(at) < pendingRequestLifetime
    }

    /// Two-letter app language, mirrored from the app so the shield speaks the same one.
    /// Before the app has written it once, the device language is the best guess.
    static var language: String {
        get {
            if let stored = defaults.string(forKey: Keys.language) { return stored }
            let device = Locale.preferredLanguages.first ?? "en"
            return String(device.prefix(2)).lowercased()
        }
        set { defaults.set(newValue, forKey: Keys.language) }
    }

    /// Lifetime number of unlocks earned. Shown in settings.
    static var unlockCount: Int {
        get { defaults.integer(forKey: Keys.unlockCount) }
        set { defaults.set(newValue, forKey: Keys.unlockCount) }
    }

    // MARK: - Shield

    /// Puts the shield on everything selected. Safe to call repeatedly.
    static func applyShield() {
        let store = ManagedSettingsStore(named: storeName)
        let selection = selection
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    /// Lifts the shield entirely: unlock window open, or feature switched off.
    static func clearShield() {
        let store = ManagedSettingsStore(named: storeName)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    /// What the shield should be right now, from the stored state alone. Both the app
    /// (on foreground) and the monitor extension (at the end of a window) call this, so a
    /// window that ends while Sophia is closed still ends.
    static func reconcileShield() {
        guard isEnabled, hasSelection else {
            clearShield()
            return
        }
        if isUnlockWindowOpen {
            clearShield()
        } else {
            if unlockedUntil != nil { unlockedUntil = nil }
            applyShield()
        }
    }

    // MARK: - Shield copy

    /// Copy shown on the system shield and in the notification. The extension cannot
    /// reach the app's localisation tables, so the handful of strings it needs live here,
    /// keyed by the mirrored language. Anything else falls back to English.
    struct ShieldCopy {
        let title: String
        let subtitle: String
        /// Shown instead of [subtitle] while a tap on the primary button is pending.
        let pendingSubtitle: String
        let primaryButton: String
        let secondaryButton: String
        let notificationTitle: String
        let notificationBody: String
    }

    static func shieldCopy(language: String = language) -> ShieldCopy {
        switch language {
        case "fr":
            return ShieldCopy(
                title: "Cultive-toi avant de scroller",
                subtitle: "Un cours Sophia de 3 minutes et son quiz débloquent TikTok pendant \(unlockMinutes) min.",
                pendingSubtitle: "C\u{2019}est noté ! Ouvre Sophia maintenant : ton cours t\u{2019}attend.",
                primaryButton: "Ouvrir Sophia",
                secondaryButton: "Fermer",
                notificationTitle: "Un cours, puis tu scrolles",
                notificationBody: "Appuie ici : un cours de 3 minutes et son quiz débloquent TikTok."
            )
        case "es":
            return ShieldCopy(
                title: "Cultívate antes de scrollear",
                subtitle: "Un curso de Sophia de 3 minutos y su quiz desbloquean TikTok durante \(unlockMinutes) min.",
                pendingSubtitle: "¡Anotado! Abre Sophia ahora: tu curso te espera.",
                primaryButton: "Abrir Sophia",
                secondaryButton: "Cerrar",
                notificationTitle: "Un curso y luego a scrollear",
                notificationBody: "Toca aquí: un curso de 3 minutos y su quiz desbloquean TikTok."
            )
        case "de":
            return ShieldCopy(
                title: "Erst lernen, dann scrollen",
                subtitle: "Ein 3-Minuten-Kurs von Sophia und sein Quiz schalten TikTok für \(unlockMinutes) Min. frei.",
                pendingSubtitle: "Notiert! Öffne jetzt Sophia: dein Kurs wartet.",
                primaryButton: "Sophia öffnen",
                secondaryButton: "Schließen",
                notificationTitle: "Ein Kurs, dann darfst du scrollen",
                notificationBody: "Tippe hier: ein 3-Minuten-Kurs und sein Quiz schalten TikTok frei."
            )
        case "it":
            return ShieldCopy(
                title: "Coltivati prima di scrollare",
                subtitle: "Un corso Sophia di 3 minuti e il suo quiz sbloccano TikTok per \(unlockMinutes) min.",
                pendingSubtitle: "Segnato! Apri Sophia adesso: il tuo corso ti aspetta.",
                primaryButton: "Apri Sophia",
                secondaryButton: "Chiudi",
                notificationTitle: "Un corso, poi scrolli",
                notificationBody: "Tocca qui: un corso di 3 minuti e il suo quiz sbloccano TikTok."
            )
        case "pt":
            return ShieldCopy(
                title: "Cultiva-te antes de fazer scroll",
                subtitle: "Um curso Sophia de 3 minutos e o seu quiz desbloqueiam o TikTok durante \(unlockMinutes) min.",
                pendingSubtitle: "Anotado! Abre a Sophia agora: o teu curso está à espera.",
                primaryButton: "Abrir Sophia",
                secondaryButton: "Fechar",
                notificationTitle: "Um curso, depois fazes scroll",
                notificationBody: "Toca aqui: um curso de 3 minutos e o seu quiz desbloqueiam o TikTok."
            )
        default:
            return ShieldCopy(
                title: "Learn something before you scroll",
                subtitle: "A 3-minute Sophia course and its quiz unlock TikTok for \(unlockMinutes) min.",
                pendingSubtitle: "Got it! Open Sophia now: your course is waiting.",
                primaryButton: "Open Sophia",
                secondaryButton: "Close",
                notificationTitle: "One course, then you scroll",
                notificationBody: "Tap here: a 3-minute course and its quiz unlock TikTok."
            )
        }
    }
}
