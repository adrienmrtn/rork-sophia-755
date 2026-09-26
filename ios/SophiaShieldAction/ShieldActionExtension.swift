import ManagedSettings
import UserNotifications

/// Handles the two buttons on the shield.
///
/// An extension cannot open another app, so "Open Sophia" cannot launch us directly. It
/// stamps a request in the App Group and posts a local notification whose tap opens
/// Sophia; the app then reads the stamp and opens a course. The shield closes TikTok
/// (`.close`) so the user lands on the home screen with the notification in view. Opening
/// Sophia by hand within ten minutes works just as well: the stamp is what counts, and
/// the shield itself says so while a request is pending.
///
/// The shield never waits on the notification. An extension gets a few hundred
/// milliseconds; a notification request whose callback never comes back would leave
/// the shield frozen under the user's finger, which is exactly what happened before
/// this was decoupled.
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
            TikTokBlockerShared.defaults.synchronize()
            let finish = OnceHandler { completionHandler(.close) }
            postOpenSophiaNotification { finish.run() }
            // Whatever the notification daemon does, TikTok closes within the second.
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) { finish.run() }
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

        // A short interval rather than `nil`: an immediate trigger is not reliably
        // honoured from an app extension, a one-second one is.
        let request = UNNotificationRequest(
            identifier: TikTokBlockerShared.unlockNotificationId,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request) { _ in
            done()
        }
    }
}

/// Runs its block at most once, from whichever caller gets there first.
private final class OnceHandler: @unchecked Sendable {
    private let lock = NSLock()
    private var block: (() -> Void)?

    init(_ block: @escaping () -> Void) {
        self.block = block
    }

    func run() {
        lock.lock()
        let pending = block
        block = nil
        lock.unlock()
        pending?()
    }
}
