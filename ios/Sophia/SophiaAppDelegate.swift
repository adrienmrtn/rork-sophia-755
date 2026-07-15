import UIKit

/// AppDelegate UIKit requis par FacebookCore (init SDK + App Events au retour au premier plan).
/// Sophia reste une SwiftUI App ; ce pont respecte le cycle de vie attendu par Meta App Manager.
final class SophiaAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        MetaAdsService.configure(launchOptions: launchOptions)
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        MetaAdsService.handleBecomeActive()
    }
}
