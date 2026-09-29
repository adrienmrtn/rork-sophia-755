import UIKit
import UserNotifications

/// AppDelegate UIKit requis par FacebookCore (init SDK + App Events au retour au premier plan).
/// Sophia reste une SwiftUI App ; ce pont respecte le cycle de vie attendu par Meta App Manager.
///
/// Il reçoit aussi les touchers sur les notifications : la question du jour ouvre son cours,
/// celle du blocker TikTok ouvre la demande de déblocage. Le délégué doit être posé avant la
/// fin du lancement, sinon un toucher qui lance l'app est perdu.
final class SophiaAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        MetaAdsService.configure(launchOptions: launchOptions)
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        MetaAdsService.handleBecomeActive()
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let link = response.notification.request.content.userInfo["deepLink"] as? String,
              let url = URL(string: link) else { return }
        await MainActor.run {
            _ = DeepLinkRouter.shared.open(url)
        }
    }

    /// App ouverte : la notification s'affiche quand même (bannière), comme en arrière-plan.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
