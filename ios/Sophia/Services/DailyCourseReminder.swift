import Foundation
import RevenueCat
import UserNotifications

/// La notification quotidienne, à l'heure choisie dans l'onboarding : la question du jour
/// (« Pourquoi le savon tue-t-il les bactéries ? »), qui ouvre le cours au toucher.
///
/// Qui la reçoit (décision du 29/09/2026) :
///  - **Premium en essai gratuit : rien.** Ni notification ni widget pendant l'essai ; les
///    notifications sont déjà programmées à partir du lendemain de la fin de l'essai.
///  - Premium payant (essai terminé ou sans essai), gratuit qui n'a jamais pris d'essai,
///    gratuit qui a résilié son essai : oui.
///
/// Notifications locales, sans serveur : une par jour pour les `scheduledDays` jours à
/// venir, chacune avec sa question (`DailyQuestion`). Recalculées à chaque ouverture de
/// l'app, changement d'abonnement, de langue ou d'heure, et après chaque cours lu. Pas de
/// notification le jour où la question a déjà été lue. Le même passage met le widget à jour.
enum DailyCourseReminder {
    /// L'ancienne notification répétée au texte générique, retirée au premier passage.
    private static let legacyRequestId = "sophia.dailyCourse"
    static let requestPrefix = "sophia.dailyQuestion."
    private static let hourKey = "sophia_daily_reminder_hour"
    /// Ce qui a été programmé la dernière fois, pour ne pas tout refaire à chaque retour
    /// au premier plan.
    private static let signatureKey = "sophia_daily_question_schedule_signature"
    static let defaultHour = 8
    /// iOS garde au plus 64 notifications en attente par app.
    static let scheduledDays = 30

    static var storedHour: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: hourKey)
            return stored == 0 ? defaultHour : stored
        }
        set { UserDefaults.standard.set(newValue, forKey: hourKey) }
    }

    /// Appelé par l'onboarding une fois l'autorisation demandée.
    static func scheduleIfAllowed() {
        refresh()
    }

    private static var isRefreshing = false
    private static var needsAnotherPass = false

    /// Recalcule les notifications et le widget. Les appels qui arrivent pendant un passage
    /// en déclenchent un seul de plus, à la fin. `force` reprogramme tout, même si rien
    /// n'a changé depuis la dernière fois.
    static func refresh(force: Bool = false) {
        if force {
            UserDefaults.standard.removeObject(forKey: signatureKey)
        }
        guard !isRefreshing else {
            needsAnotherPass = true
            return
        }
        isRefreshing = true
        Task {
            repeat {
                needsAnotherPass = false
                await refreshNow()
            } while needsAnotherPass
            isRefreshing = false
        }
    }

    private static func refreshNow() async {
        // Sans statut d'abonnement (hors ligne au premier lancement), on ne touche à rien :
        // mieux vaut garder ce qui est programmé que l'envoyer à un essai.
        guard let info = try? await Purchases.shared.customerInfo() else { return }
        let now = Date()
        let startDay = firstNotificationDay(for: info, now: now)
        let language = AppLanguage.currentPersisted()
        let completed = ProgressManager.persistedCompletedCourseIds()
        let plan = DailyQuestion.plan(
            from: now,
            days: scheduledDays,
            language: language,
            isCompleted: completed.contains
        )
        let upcoming = plan.filter { $0.day.start >= startDay }

        DailyQuestionWidgetWriter.update(days: upcoming, language: language)

        let status = await NotificationPermission.status()
        let allowed = status == .authorized || status == .provisional || status == .ephemeral
        let hour = storedHour
        let calendar = DailyQuestion.calendar
        var planned: [(id: String, fireDate: Date, courseId: String)] = []
        if allowed {
            for entry in upcoming {
                guard !completed.contains(entry.courseId),
                      let fire = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: entry.day.start),
                      fire > now else { continue }
                planned.append((id: requestPrefix + entry.day.key, fireDate: fire, courseId: entry.courseId))
            }
        }

        let center = UNUserNotificationCenter.current()
        let pendingIds = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(requestPrefix) || $0 == legacyRequestId }
        let signature = ([language.rawValue, String(hour)] + planned.map { "\($0.id)=\($0.courseId)" })
            .joined(separator: "|")
        if signature == UserDefaults.standard.string(forKey: signatureKey),
           Set(pendingIds) == Set(planned.map(\.id)) {
            return
        }

        center.removePendingNotificationRequests(withIdentifiers: pendingIds)
        for item in planned {
            guard let notification = content(courseId: item.courseId, language: language) else { continue }
            // Heure « flottante » : 8 h reste 8 h en voyage. Le calendrier est précisé pour
            // qu'un téléphone réglé sur un autre calendrier lise la bonne année.
            let components = calendar.dateComponents([.calendar, .year, .month, .day, .hour, .minute], from: item.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: item.id, content: notification, trigger: trigger))
        }
        UserDefaults.standard.set(signature, forKey: signatureKey)
    }

    /// La notification d'une question : titre = la question, texte = l'accroche, toucher =
    /// le cours. Nil si le cours n'existe pas dans cette langue.
    static func content(courseId: String, language: AppLanguage) -> UNMutableNotificationContent? {
        guard let course = ContentCatalog.course(withId: courseId, language: language) else { return nil }
        let content = UNMutableNotificationContent()
        content.title = course.title
        content.body = hook(for: courseId, language: language)
            ?? AppLocalizable.string("notification.courseNudge.bodyFallback", language: language)
        content.sound = .default
        content.threadIdentifier = "sophia.dailyQuestion"
        content.userInfo = ["deepLink": "sophia://course/\(courseId)?from=notification"]
        return content
    }

    /// Premier jour où la personne peut recevoir la question : aujourd'hui, ou le lendemain
    /// de la fin de l'essai gratuit.
    static func firstNotificationDay(for info: CustomerInfo, now: Date) -> Date {
        let calendar = DailyQuestion.calendar
        let today = calendar.startOfDay(for: now)
        let entitlement = info.entitlements["premium"]
        guard entitlement?.isActive == true, entitlement?.periodType == .trial else { return today }
        let trialEnd = calendar.startOfDay(for: entitlement?.expirationDate ?? now)
        return calendar.date(byAdding: .day, value: 1, to: trialEnd) ?? today
    }

    /// L'accroche du cours, sans balisage. Toutes les questions en ont une dans les 26 langues.
    private static func hook(for courseId: String, language: AppLanguage) -> String? {
        guard let hook = CourseContentStore.content(courseId: courseId, language: language)?.hero?.hook else {
            return nil
        }
        let text = hook.withoutInlineMarkup.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }
}
