import ManagedSettings
import UserNotifications

/// Handles the two buttons on the shield.
///
/// An extension cannot open another app, so "Open Sophia" cannot launch us directly. It
/// stamps a request in the App Group and posts a local notification whose tap opens
/// Sophia; the app then reads the stamp and opens a course. The shield closes TikTok
/// (`.close`) so the user lands on the home screen with the notification in view. Opening
/// Sophia by hand within ten minutes works just as well: the stamp is what counts.
final class ShieldActionExtension: ShieldActionDelegate {
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler: completionHandler)
    }

    private func respond(to action: ShieldAction, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            TikTokBlockerShared.pendingRequestAt = Date()
            postOpenSophiaNotification {
                completionHandler(.close)
            }
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    private func postOpenSophiaNotification(then done: @escaping () -> Void) {
        let copy = TikTokBlockerShared.shieldCopy()
        let content = UNMutableNotificationContent()
        content.title = copy.notificationTitle
        content.body = copy.notificationBody
        content.sound = .default
        content.interruptionLevel = .active
        content.userInfo = ["deepLink": TikTokBlockerShared.unlockDeepLink]

        let request = UNNotificationRequest(
            identifier: TikTokBlockerShared.unlockNotificationId,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { _ in
            done()
        }
    }
}
