import AppTrackingTransparency
import FacebookCore
import Foundation
import UIKit

/// Intégration Meta Ads (FacebookCore) : bootstrap SDK + ATT.
/// Les secrets (App ID, Client Token) restent uniquement dans Info.plist.
enum MetaAdsService {
    /// Garde anti-double appel pendant la même session (onboarding + ContentView).
    private static var didRequestTrackingThisSession = false

    // MARK: - Bootstrap SDK

    /// Initialise FacebookCore au lancement, en lisant App ID / Client Token depuis Info.plist.
    /// À appeler depuis `SophiaApp.init()` (cycle de vie SwiftUI App, sans AppDelegate dédié).
    static func configure() {
        // Transmet le démarrage de l'app au SDK pour activer App Events / AEM.
        ApplicationDelegate.shared.application(
            UIApplication.shared,
            didFinishLaunchingWithOptions: nil
        )
    }

    // MARK: - URL callbacks

    /// Transmet les URL ouvertes (schéma `fb…`) au SDK Meta, sans bloquer les deep links Sophia.
    @discardableResult
    static func handleOpenURL(_ url: URL) -> Bool {
        ApplicationDelegate.shared.application(
            UIApplication.shared,
            open: url,
            sourceApplication: nil,
            annotation: [:]
        )
    }

    // MARK: - App Tracking Transparency

    /// Demande l'autorisation ATT après le premier écran (pas au cold start),
    /// puis aligne `Settings.shared.isAdvertiserTrackingEnabled` sur le résultat.
    static func requestTrackingAuthorizationAfterFirstScreen() {
        // Une seule invite ATT par session, même si onboarding et home appellent tous les deux.
        guard !didRequestTrackingThisSession else { return }
        didRequestTrackingThisSession = true

        // Léger délai pour que le nouvel écran soit visible avant la modale système.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            promptTrackingAuthorizationIfNeeded()
        }
    }

    /// Affiche la modale ATT si le statut est encore `.notDetermined`, sinon synchronise seulement le flag Meta.
    private static func promptTrackingAuthorizationIfNeeded() {
        let currentStatus = ATTrackingManager.trackingAuthorizationStatus

        // Déjà décidé (autorisé / refusé / restreint) : on répercute sans re-demander.
        guard currentStatus == .notDetermined else {
            applyAdvertiserTracking(enabled: currentStatus == .authorized)
            return
        }

        // Première demande : iOS affiche NSUserTrackingUsageDescription depuis Info.plist.
        ATTrackingManager.requestTrackingAuthorization { status in
            DispatchQueue.main.async {
                applyAdvertiserTracking(enabled: status == .authorized)
            }
        }
    }

    /// Indique au SDK Meta si le tracking publicitaire est autorisé (SKAdNetwork / IDFA côté Ads).
    private static func applyAdvertiserTracking(enabled: Bool) {
        Settings.shared.isAdvertiserTrackingEnabled = enabled
    }
}
