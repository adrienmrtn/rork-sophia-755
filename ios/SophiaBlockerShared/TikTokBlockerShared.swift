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

    /// DeviceActivity refuses schedules shorter than this, in minutes: a course finished
    /// just before midnight still buys a window at least this long.
    static let minimumUnlockMinutes = 15

    /// A shield tap older than this is stale: the user tapped, got distracted, and should
    /// not be ambushed with a course hours later.
    static let pendingRequestLifetime: TimeInterval = 10 * 60

    enum Keys {
        static let enabled = "tiktokBlocker.enabled"
        static let selection = "tiktokBlocker.selection"
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

    /// The daily course unlocks TikTok until the day is over: local midnight, or at least
    /// [minimumUnlockMinutes] from now when midnight is closer than that.
    static func unlockWindowEnd(from now: Date = Date()) -> Date {
        let calendar = Calendar.current
        let startOfTomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
        let floor = now.addingTimeInterval(TimeInterval(minimumUnlockMinutes * 60))
        return max(startOfTomorrow, floor)
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
                subtitle: "Finis ton cours du jour sur Sophia pour débloquer TikTok jusqu\u{2019}à demain.",
                pendingSubtitle: "C\u{2019}est noté ! Ouvre Sophia maintenant : ton cours t\u{2019}attend.",
                primaryButton: "Ouvrir Sophia",
                secondaryButton: "Fermer",
                notificationTitle: "Un cours, puis tu scrolles",
                notificationBody: "Appuie ici : ton cours du jour débloque TikTok."
            )
        case "es":
            return ShieldCopy(
                title: "Cultívate antes de scrollear",
                subtitle: "Termina tu curso del día en Sophia para desbloquear TikTok hasta mañana.",
                pendingSubtitle: "¡Anotado! Abre Sophia ahora: tu curso te espera.",
                primaryButton: "Abrir Sophia",
                secondaryButton: "Cerrar",
                notificationTitle: "Un curso y luego a scrollear",
                notificationBody: "Toca aquí: tu curso del día desbloquea TikTok."
            )
        case "de":
            return ShieldCopy(
                title: "Erst lernen, dann scrollen",
                subtitle: "Beende deinen Tageskurs in Sophia, um TikTok bis morgen freizuschalten.",
                pendingSubtitle: "Notiert! Öffne jetzt Sophia: dein Kurs wartet.",
                primaryButton: "Sophia öffnen",
                secondaryButton: "Schließen",
                notificationTitle: "Ein Kurs, dann darfst du scrollen",
                notificationBody: "Tippe hier: dein Tageskurs schaltet TikTok frei."
            )
        case "it":
            return ShieldCopy(
                title: "Coltivati prima di scrollare",
                subtitle: "Finisci il corso del giorno su Sophia per sbloccare TikTok fino a domani.",
                pendingSubtitle: "Segnato! Apri Sophia adesso: il tuo corso ti aspetta.",
                primaryButton: "Apri Sophia",
                secondaryButton: "Chiudi",
                notificationTitle: "Un corso, poi scrolli",
                notificationBody: "Tocca qui: il tuo corso del giorno sblocca TikTok."
            )
        case "pt":
            return ShieldCopy(
                title: "Cultiva-te antes de fazer scroll",
                subtitle: "Termina o teu curso do dia na Sophia para desbloquear o TikTok até amanhã.",
                pendingSubtitle: "Anotado! Abre a Sophia agora: o teu curso está à espera.",
                primaryButton: "Abrir Sophia",
                secondaryButton: "Fechar",
                notificationTitle: "Um curso, depois fazes scroll",
                notificationBody: "Toca aqui: o teu curso do dia desbloqueia o TikTok."
            )
        default:
            return ShieldCopy(
                title: "Learn something before you scroll",
                subtitle: "Finish your daily course on Sophia to unlock TikTok until tomorrow.",
                pendingSubtitle: "Got it! Open Sophia now: your course is waiting.",
                primaryButton: "Open Sophia",
                secondaryButton: "Close",
                notificationTitle: "One course, then you scroll",
                notificationBody: "Tap here: your daily course unlocks TikTok."
            )
        }
    }
}
