import UserNotifications

/// Thin wrapper around the system notification authorization, used by the onboarding page
/// that asks for it.
///
/// The app schedules **nothing** today: this only collects the authorization so notifications
/// can be sent later without having to catch the user again. iOS shows its prompt once and
/// once only — a refusal is final, `requestAuthorization` never prompts again — so the ask is
/// deliberately made from a page that explains the reason first.
enum NotificationPermission {
    static func status() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Whether iOS has already settled the authorization, which makes the onboarding page
    /// pointless: asking again is a no-op that shows no prompt, so the page would only cost
    /// the user a tap.
    static func isSettled() async -> Bool {
        await status() != .notDetermined
    }

    /// Shows the system prompt. Granted or refused, the caller moves on either way.
    @discardableResult
    static func request() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
}
