#if DEBUG
import RevenueCat
import SwiftUI
import UIKit
import UserNotifications

/// Réglages › Développeur › Tester les notifications. Builds Debug uniquement.
///
/// Envoie, après un court délai, chaque notification que l'app sait envoyer, avec le même
/// contenu et le même lien que la vraie : on peut quitter l'app pour la voir arriver comme
/// un utilisateur, ou rester dedans (elle s'affiche aussi en bannière). Montre aussi ce que
/// la vraie programmation a prévu et pour qui (essai, payant, gratuit).
///
/// Les notifications de test ont leur propre préfixe : elles ne touchent jamais à la
/// programmation réelle de la question du jour.
struct DebugNotificationsView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    @State private var delay: Int = 5
    @State private var authorization: UNAuthorizationStatus?
    @State private var audience: String = "…"
    @State private var firstDay: String = "…"
    @State private var pending: [PendingNotification] = []
    @State private var message: String?

    private static let debugPrefix = "sophia.debug."
    private static let delays = [5, 10, 30, 60]

    struct PendingNotification: Identifiable {
        let id: String
        let date: Date?
        let title: String
    }

    var body: some View {
        NavigationStack {
            List {
                statusSection
                sendSection
                scheduleSection
                pendingSection
            }
            .navigationTitle("Notifications (debug)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .task { await reload() }
            .refreshable { await reload() }
        }
    }

    // MARK: - Sections

    private var statusSection: some View {
        Section {
            infoRow("Autorisation iOS", authorizationLabel)
            if authorization == .notDetermined {
                Button("Demander l'autorisation") {
                    Task {
                        await NotificationPermission.request()
                        await reload()
                    }
                }
            }
            if authorization == .denied {
                Button("Ouvrir les réglages iOS") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            infoRow("Abonnement (RevenueCat)", audience)
            infoRow("Question du jour à partir du", firstDay)
            infoRow("Heure", OnboardingV2ReadingTime.label(hour: DailyCourseReminder.storedHour))
            infoRow("Langue", languageManager.current.rawValue)
        } header: {
            Text("État")
        } footer: {
            Text("Les questions sont envoyées dans la langue de l'app : change-la dans Réglages pour tester une autre langue.")
        }
    }

    private var sendSection: some View {
        Section {
            Picker("Délai", selection: $delay) {
                ForEach(Self.delays, id: \.self) { Text("\($0) s").tag($0) }
            }
            Button("Question du jour") { sendPlanned(dayOffset: 0) }
            Button("Question de demain") { sendPlanned(dayOffset: 1) }
            Button("Question au hasard") { sendRandomQuestion() }
            Button("Les 5 prochaines questions (une toutes les 10 s)") { sendNextFive() }
            Button("Blocker TikTok : « Un cours, puis tu scrolles »") { sendBlockerPrompt() }
            if let message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Envoyer maintenant")
        } footer: {
            Text("Même contenu et même lien que la vraie notification. Quitte l'app pour la voir comme un utilisateur ; app ouverte, elle s'affiche en bannière. Toucher la question ouvre le cours.")
        }
    }

    private var scheduleSection: some View {
        Section {
            Button("Reprogrammer maintenant") {
                DailyCourseReminder.refresh(force: true)
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    await reload()
                }
            }
            Button("Tout effacer (programmées et reçues)", role: .destructive) {
                let center = UNUserNotificationCenter.current()
                center.removeAllPendingNotificationRequests()
                center.removeAllDeliveredNotifications()
                message = "Tout est effacé. « Reprogrammer maintenant » remet la programmation réelle."
                Task { await reload() }
            }
        } header: {
            Text("Programmation réelle")
        } footer: {
            Text("Rien n'est programmé pendant l'essai gratuit avant le lendemain de sa fin, ni le jour où la question est déjà lue.")
        }
    }

    private var pendingSection: some View {
        Section {
            if pending.isEmpty {
                Text("Aucune notification programmée")
                    .foregroundStyle(.secondary)
            }
            ForEach(pending) { item in
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.subheadline)
                        .lineLimit(2)
                    Text(item.date.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? "—")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.id)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        } header: {
            Text("Programmées (\(pending.count))")
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private var authorizationLabel: String {
        guard let authorization else { return "…" }
        switch authorization {
        case .authorized: return "autorisées"
        case .denied: return "refusées"
        case .notDetermined: return "pas encore demandées"
        case .provisional: return "provisoires"
        case .ephemeral: return "éphémères"
        @unknown default: return "inconnu"
        }
    }

    // MARK: - Envois

    private var language: AppLanguage { languageManager.current }

    private func sendPlanned(dayOffset: Int) {
        let plan = DailyQuestion.plan(
            days: dayOffset + 1,
            language: language,
            isCompleted: ProgressManager.persistedCompletedCourseIds().contains
        )
        guard plan.count > dayOffset,
              let content = DailyCourseReminder.content(courseId: plan[dayOffset].courseId, language: language) else {
            message = "Aucune question disponible dans cette langue."
            return
        }
        schedule(content, after: delay)
    }

    private func sendRandomQuestion() {
        let available = Set(ContentCatalog.courses(for: language).map(\.id))
        guard let id = DailyQuestion.order.filter({ available.contains($0) }).randomElement(),
              let content = DailyCourseReminder.content(courseId: id, language: language) else {
            message = "Aucune question disponible dans cette langue."
            return
        }
        schedule(content, after: delay)
    }

    private func sendNextFive() {
        let plan = DailyQuestion.plan(
            days: 5,
            language: language,
            isCompleted: ProgressManager.persistedCompletedCourseIds().contains
        )
        for (index, entry) in plan.enumerated() {
            guard let content = DailyCourseReminder.content(courseId: entry.courseId, language: language) else { continue }
            schedule(content, after: delay + index * 10, announce: false)
        }
        message = "\(plan.count) questions envoyées : la première dans \(delay) s, puis une toutes les 10 s."
        Task { await reload() }
    }

    /// Celle que l'extension du bouclier envoie quand on touche « Ouvrir Sophia » sur TikTok.
    private func sendBlockerPrompt() {
        let copy = TikTokBlockerShared.shieldCopy()
        let content = UNMutableNotificationContent()
        content.title = copy.notificationTitle
        content.body = copy.notificationBody
        content.sound = .default
        content.interruptionLevel = .active
        content.userInfo = ["deepLink": TikTokBlockerShared.unlockDeepLink]
        schedule(content, after: delay)
    }

    private func schedule(_ content: UNMutableNotificationContent, after seconds: Int, announce: Bool = true) {
        let request = UNNotificationRequest(
            identifier: Self.debugPrefix + UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(1, seconds)), repeats: false)
        )
        let title = content.title
        Task {
            do {
                try await UNUserNotificationCenter.current().add(request)
                if announce { message = "« \(title) » arrive dans \(seconds) s." }
            } catch {
                message = "Échec : \(error.localizedDescription)"
            }
            await reload()
        }
    }

    // MARK: - État

    private func reload() async {
        let center = UNUserNotificationCenter.current()
        authorization = await center.notificationSettings().authorizationStatus

        if let info = try? await Purchases.shared.customerInfo() {
            let entitlement = info.entitlements["premium"]
            if entitlement?.isActive == true {
                if entitlement?.periodType == .trial {
                    let end = entitlement?.expirationDate?.formatted(date: .abbreviated, time: .shortened) ?? "?"
                    audience = "Premium en essai (fin : \(end))"
                } else {
                    audience = "Premium payant"
                }
            } else {
                audience = entitlement == nil ? "Gratuit, jamais d'essai" : "Gratuit, ancien Premium ou essai"
            }
            firstDay = DailyCourseReminder.firstNotificationDay(for: info, now: Date())
                .formatted(date: .abbreviated, time: .omitted)
        } else {
            audience = "inconnu (RevenueCat injoignable)"
            firstDay = "?"
        }

        pending = await center.pendingNotificationRequests()
            .map { request in
                let date = (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
                    ?? (request.trigger as? UNTimeIntervalNotificationTrigger)?.nextTriggerDate()
                return PendingNotification(id: request.identifier, date: date, title: request.content.title)
            }
            .sorted { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) }
    }
}
#endif
