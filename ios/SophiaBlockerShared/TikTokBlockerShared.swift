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
        case "tr":
            return ShieldCopy(
                title: "Kaydırmadan önce bir şey öğren",
                subtitle: "TikTok’un kilidini yarına kadar açmak için Sophia’da günün dersini bitir.",
                pendingSubtitle: "Tamamdır! Şimdi Sophia’yı aç: dersin seni bekliyor.",
                primaryButton: "Sophia’yı aç",
                secondaryButton: "Kapat",
                notificationTitle: "Önce bir ders, sonra kaydır",
                notificationBody: "Buraya dokun: günün dersi TikTok’un kilidini açar."
            )
        case "pl":
            return ShieldCopy(
                title: "Najpierw nauka, potem scroll",
                subtitle: "Ukończ kurs dnia w Sophii, aby odblokować TikToka do jutra.",
                pendingSubtitle: "Jasne! Otwórz teraz Sophię: twój kurs czeka.",
                primaryButton: "Otwórz Sophię",
                secondaryButton: "Zamknij",
                notificationTitle: "Jeden kurs i możesz scrollować",
                notificationBody: "Dotknij tutaj: twój kurs dnia odblokuje TikToka."
            )
        case "ro":
            return ShieldCopy(
                title: "Învață ceva înainte să derulezi",
                subtitle: "Termină cursul de azi în Sophia ca să deblochezi TikTok până mâine.",
                pendingSubtitle: "Perfect! Deschide Sophia acum: cursul tău te așteaptă.",
                primaryButton: "Deschide Sophia",
                secondaryButton: "Închide",
                notificationTitle: "Un curs, apoi derulezi",
                notificationBody: "Atinge aici: cursul de azi deblochează TikTok."
            )
        case "nl":
            return ShieldCopy(
                title: "Leer iets voordat je scrolt",
                subtitle: "Rond je cursus van de dag af in Sophia om TikTok tot morgen te ontgrendelen.",
                pendingSubtitle: "Genoteerd! Open Sophia nu: je cursus wacht op je.",
                primaryButton: "Open Sophia",
                secondaryButton: "Sluiten",
                notificationTitle: "Eerst een cursus, dan scrollen",
                notificationBody: "Tik hier: je cursus van de dag ontgrendelt TikTok."
            )
        case "el":
            return ShieldCopy(
                title: "Μάθε κάτι πριν σκρολάρεις",
                subtitle: "Τελείωσε το μάθημα της ημέρας σου στη Sophia για να ξεκλειδώσεις το TikTok μέχρι αύριο.",
                pendingSubtitle: "Έγινε! Άνοιξε τη Sophia τώρα: το μάθημά σου σε περιμένει.",
                primaryButton: "Άνοιξε τη Sophia",
                secondaryButton: "Κλείσιμο",
                notificationTitle: "Ένα μάθημα, και μετά σκρολάρεις",
                notificationBody: "Πάτα εδώ: το μάθημα της ημέρας σου ξεκλειδώνει το TikTok."
            )
        case "sv":
            return ShieldCopy(
                title: "Lär dig något innan du scrollar",
                subtitle: "Gör klart dagens kurs i Sophia för att låsa upp TikTok till imorgon.",
                pendingSubtitle: "Uppfattat! Öppna Sophia nu: din kurs väntar.",
                primaryButton: "Öppna Sophia",
                secondaryButton: "Stäng",
                notificationTitle: "En kurs, sen scrollar du",
                notificationBody: "Tryck här: dagens kurs låser upp TikTok."
            )
        case "hu":
            return ShieldCopy(
                title: "Előbb tanulj, aztán görgess",
                subtitle: "Fejezd be a mai kurzusodat a Sophiában, hogy holnapig feloldd a TikTokot.",
                pendingSubtitle: "Megvan! Nyisd meg most a Sophiát: vár a kurzusod.",
                primaryButton: "Sophia megnyitása",
                secondaryButton: "Bezárás",
                notificationTitle: "Egy kurzus, aztán görgethetsz",
                notificationBody: "Koppints ide: a mai kurzusod feloldja a TikTokot."
            )
        case "bg":
            return ShieldCopy(
                title: "Научи нещо, преди да скролваш",
                subtitle: "Завърши курса си за деня в Sophia, за да отключиш TikTok до утре.",
                pendingSubtitle: "Готово! Отвори Sophia сега: курсът ти те чака.",
                primaryButton: "Отвори Sophia",
                secondaryButton: "Затвори",
                notificationTitle: "Един курс, после скролваш",
                notificationBody: "Докосни тук: курсът ти за деня отключва TikTok."
            )
        case "cs":
            return ShieldCopy(
                title: "Nejdřív se něco nauč, pak scrolluj",
                subtitle: "Dokonči kurz dne v Sophii a TikTok se ti odblokuje do zítřka.",
                pendingSubtitle: "Jasně! Teď otevři Sophii: kurz na tebe čeká.",
                primaryButton: "Otevřít Sophii",
                secondaryButton: "Zavřít",
                notificationTitle: "Jeden kurz a pak scrolluj",
                notificationBody: "Klepni sem: kurz dne ti odblokuje TikTok."
            )
        case "da":
            return ShieldCopy(
                title: "Lær noget, før du scroller",
                subtitle: "Gennemfør dagens kursus på Sophia for at låse TikTok op indtil i morgen.",
                pendingSubtitle: "Forstået! Åbn Sophia nu: dit kursus venter.",
                primaryButton: "Åbn Sophia",
                secondaryButton: "Luk",
                notificationTitle: "Ét kursus, så kan du scrolle",
                notificationBody: "Tryk her: dagens kursus låser TikTok op."
            )
        case "nb", "no":
            return ShieldCopy(
                title: "Lær noe før du scroller",
                subtitle: "Fullfør dagens kurs på Sophia for å låse opp TikTok til i morgen.",
                pendingSubtitle: "Notert! Åpne Sophia nå: kurset ditt venter.",
                primaryButton: "Åpne Sophia",
                secondaryButton: "Lukk",
                notificationTitle: "Ett kurs, så kan du scrolle",
                notificationBody: "Trykk her: dagens kurs låser opp TikTok."
            )
        case "ru":
            return ShieldCopy(
                title: "Сначала узнай новое, потом листай",
                subtitle: "Пройди курс дня в Sophia, чтобы разблокировать TikTok до завтра.",
                pendingSubtitle: "Принято! Открой Sophia прямо сейчас: курс уже ждёт.",
                primaryButton: "Открыть Sophia",
                secondaryButton: "Закрыть",
                notificationTitle: "Один курс — и листай дальше",
                notificationBody: "Нажми сюда: курс дня разблокирует TikTok."
            )
        case "hr":
            return ShieldCopy(
                title: "Nauči nešto prije skrolanja",
                subtitle: "Završi tečaj dana u Sophiji i otključaj TikTok do sutra.",
                pendingSubtitle: "Zabilježeno! Sad otvori Sophiju: tečaj te čeka.",
                primaryButton: "Otvori Sophiju",
                secondaryButton: "Zatvori",
                notificationTitle: "Jedan tečaj, pa skrolaj",
                notificationBody: "Dodirni ovdje: tvoj tečaj dana otključava TikTok."
            )
        case "sl":
            return ShieldCopy(
                title: "Nauči se kaj, preden drsaš",
                subtitle: "Dokončaj tečaj dneva v Sophii in odkleni TikTok do jutri.",
                pendingSubtitle: "Zabeleženo! Zdaj odpri Sophio: tečaj te čaka.",
                primaryButton: "Odpri Sophio",
                secondaryButton: "Zapri",
                notificationTitle: "En tečaj, potem drsaj",
                notificationBody: "Tapni tukaj: tvoj tečaj dneva odklene TikTok."
            )
        case "sk":
            return ShieldCopy(
                title: "Nauč sa niečo pred scrollovaním",
                subtitle: "Dokonči kurz dňa v Sophii a odomkni si TikTok do zajtra.",
                pendingSubtitle: "Mám to! Teraz otvor Sophiu: kurz na teba čaká.",
                primaryButton: "Otvoriť Sophiu",
                secondaryButton: "Zavrieť",
                notificationTitle: "Jeden kurz, potom scrolluj",
                notificationBody: "Ťukni sem: tvoj kurz dňa odomkne TikTok."
            )
        case "sr":
            return ShieldCopy(
                title: "Nauči nešto pre skrolovanja",
                subtitle: "Završi kurs dana u aplikaciji Sophia i otključaj TikTok do sutra.",
                pendingSubtitle: "Zabeleženo! Sad otvori Sophia: kurs te čeka.",
                primaryButton: "Otvori Sophia",
                secondaryButton: "Zatvori",
                notificationTitle: "Jedan kurs, pa skroluj",
                notificationBody: "Dodirni ovde: tvoj kurs dana otključava TikTok."
            )
        case "ar":
            return ShieldCopy(
                title: "تثقّف قبل أن تتصفّح",
                subtitle: "أنهِ درسك اليومي على Sophia لرفع الحظر عن TikTok حتى الغد.",
                pendingSubtitle: "حسنًا! افتح Sophia الآن: درسك بانتظارك.",
                primaryButton: "افتح Sophia",
                secondaryButton: "إغلاق",
                notificationTitle: "درس أولًا، ثم تصفّح",
                notificationBody: "اضغط هنا: درسك اليومي يرفع الحظر عن TikTok."
            )
        case "he":
            return ShieldCopy(
                title: "קצת תרבות לפני הגלילה",
                subtitle: "סיים את השיעור היומי שלך ב־Sophia כדי לשחרר את TikTok עד מחר.",
                pendingSubtitle: "קיבלנו! פתח את Sophia עכשיו: השיעור שלך מחכה.",
                primaryButton: "פתח את Sophia",
                secondaryButton: "סגור",
                notificationTitle: "שיעור אחד, ואז גוללים",
                notificationBody: "הקש כאן: השיעור היומי שלך משחרר את TikTok."
            )
        case "fi":
            return ShieldCopy(
                title: "Sivisty ennen kuin skrollaat",
                subtitle: "Suorita päivän kurssisi Sophiassa, niin TikTok aukeaa huomiseen asti.",
                pendingSubtitle: "Selvä! Avaa nyt Sophia: kurssisi odottaa.",
                primaryButton: "Avaa Sophia",
                secondaryButton: "Sulje",
                notificationTitle: "Kurssi ensin, sitten skrollaamaan",
                notificationBody: "Napauta tästä: päivän kurssisi avaa TikTokin."
            )
        case "et":
            return ShieldCopy(
                title: "Hari end enne kerimist",
                subtitle: "Lõpeta Sophias oma päeva kursus, et TikTok homseni avada.",
                pendingSubtitle: "Selge! Ava nüüd Sophia: sinu kursus ootab.",
                primaryButton: "Ava Sophia",
                secondaryButton: "Sulge",
                notificationTitle: "Enne kursus, siis kerimine",
                notificationBody: "Puuduta siin: sinu päeva kursus avab TikToki."
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
