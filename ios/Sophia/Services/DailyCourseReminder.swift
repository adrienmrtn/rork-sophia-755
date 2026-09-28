import Foundation
import UserNotifications

/// The daily "come read your course" notification, at the hour chosen in the onboarding.
///
/// Scheduled once notifications are allowed (end of onboarding, or later from anywhere
/// that re-checks the authorization). A calendar trigger repeats every day at that hour;
/// re-scheduling replaces the previous request, so changing the hour never stacks two.
enum DailyCourseReminder {
    static let requestId = "sophia.dailyCourse"
    private static let hourKey = "sophia_daily_reminder_hour"
    static let defaultHour = 8

    static var storedHour: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: hourKey)
            return stored == 0 ? defaultHour : stored
        }
        set { UserDefaults.standard.set(newValue, forKey: hourKey) }
    }

    /// Schedules the reminder when the authorization allows it; a no-op otherwise.
    static func scheduleIfAllowed() {
        Task {
            let status = await NotificationPermission.status()
            guard status == .authorized || status == .provisional || status == .ephemeral else { return }
            await schedule(hour: storedHour)
        }
    }

    static func schedule(hour: Int) async {
        let language = AppLanguage.currentPersisted()
        let content = UNMutableNotificationContent()
        content.title = AppLocalizable.string("notification.courseNudge.title", language: language)
        content.body = AppLocalizable.string("notification.courseNudge.bodyFallback", language: language)
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [requestId])
        try? await center.add(request)
    }
}
