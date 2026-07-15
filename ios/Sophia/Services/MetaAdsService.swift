import AppTrackingTransparency
import FacebookCore
import Foundation
import UIKit

/// Intégration Meta Ads (FacebookCore) : bootstrap SDK, App Events et ATT.
/// Les secrets (App ID, Client Token) restent uniquement dans Info.plist.
enum MetaAdsService {
    /// Garde anti-double appel pendant la même session (onboarding + ContentView).
    private static var didRequestTrackingThisSession = false

    // MARK: - Bootstrap SDK

    /// Initialise FacebookCore au lancement via AppDelegate (cycle de vie UIKit attendu par Meta).
    /// Lit App ID / Client Token depuis Info.plist — aucun secret en dur ici.
    static func configure(launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) {
        ApplicationDelegate.shared.application(
            UIApplication.shared,
            didFinishLaunchingWithOptions: launchOptions
        )

        // Utilisateur déjà onboardé : reflète tout de suite le choix ATT connu (retour app / relance).
        syncAdvertiserTrackingFromATT()
    }

    /// Notifie Meta à chaque retour au premier plan (App Events + détection SDK côté App Manager).
    static func handleBecomeActive() {
        AppEvents.shared.activateApp()
        syncAdvertiserTrackingFromATT()
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
    /// puis active AdvertisingTrackingEnabled et les flags Meta associés.
    static func requestTrackingAuthorizationAfterFirstScreen() {
        guard !didRequestTrackingThisSession else { return }
        didRequestTrackingThisSession = true

        // Léger délai pour que le nouvel écran soit visible avant la modale système.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            promptTrackingAuthorizationIfNeeded()
        }
    }

    /// Affiche la modale ATT si le statut est encore `.notDetermined`, sinon synchronise seulement les flags Meta.
    private static func promptTrackingAuthorizationIfNeeded() {
        let currentStatus = ATTrackingManager.trackingAuthorizationStatus

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

    /// Lit le statut ATT courant (iOS 17+ : le SDK s'appuie dessus pour AdvertisingTrackingEnabled).
    private static func syncAdvertiserTrackingFromATT() {
        guard #available(iOS 14, *) else { return }
        applyAdvertiserTracking(enabled: ATTrackingManager.trackingAuthorizationStatus == .authorized)
    }

    /// Active le suivi publicitaire Meta (ATE) et les collectes associées selon le consentement ATT.
    private static func applyAdvertiserTracking(enabled: Bool) {
        // iOS 14–16 : flag explicite requis par Meta pour compter les events iOS 14.5+.
        if #unavailable(iOS 17) {
            Settings.shared.isAdvertiserTrackingEnabled = enabled
        }

        // Auto-log App Events + IDFA : activés seulement si l'utilisateur a autorisé le tracking.
        Settings.shared.isAutoLogAppEventsEnabled = enabled
        Settings.shared.isAdvertiserIDCollectionEnabled = enabled
    }
}
