import Foundation
import Observation
import UIKit
import AuthenticationServices
import Supabase
import GoogleSignIn
import RevenueCat

/// Erreurs remontées à l'UI d'authentification.
///
/// `nonisolated` car l'app isole tout sur `MainActor` par défaut : on veut pouvoir propager /
/// capturer cette erreur librement. Les messages destinés à l'utilisateur sont résolus côté vue.
nonisolated enum AuthError: Error, Sendable {
    /// L'utilisateur a annulé (ferme la feuille Apple/Google). Pas un vrai échec : on laisse réessayer.
    case cancelled
    case missingIdentityToken
    case underlying(String)
}

/// Service d'authentification Supabase (Apple + Google natif via idToken).
///
/// - Nouveaux users : login obligatoire en 1re page d'onboarding.
/// - Users existants : création de compte optionnelle depuis les Réglages.
///
/// La session est persistée par le SDK Supabase (Keychain). On expose `currentUser` /
/// `isSignedIn` de façon observable pour piloter l'UI.
@Observable
@MainActor
final class AuthService {
    static let shared = AuthService()

    private(set) var currentUser: User?
    private(set) var isBootstrapping = true

    var isSignedIn: Bool { currentUser != nil }

    private let client = SupabaseManager.shared
    private var authStateTask: Task<Void, Never>?

    private init() {}

    // MARK: - Cycle de vie

    /// À appeler une fois au lancement : configure Google et écoute les changements de session.
    func start() {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: AppConfig.GOOGLE_IOS_CLIENT_ID,
            serverClientID: AppConfig.GOOGLE_WEB_CLIENT_ID
        )

        authStateTask?.cancel()
        authStateTask = Task { [weak self] in
            guard let self else { return }
            for await (event, session) in self.client.auth.authStateChanges {
                self.currentUser = session?.user
                if event == .initialSession {
                    self.isBootstrapping = false
                }
                self.linkAnalyticsIdentity()
            }
        }

        // Filet de sécurité si aucun `initialSession` n'arrive rapidement.
        Task { [weak self] in
            guard let self else { return }
            let session = try? await self.client.auth.session
            self.currentUser = session?.user
            self.isBootstrapping = false
            self.linkAnalyticsIdentity()
        }
    }

    /// Restaure la session au premier plan (le refresh token peut avoir expiré).
    func refreshSessionIfNeeded() async {
        let session = try? await client.auth.session
        currentUser = session?.user
    }

    // MARK: - Sign in with Apple
    //
    // `AuthProvidersView` lance `ASAuthorizationController` : la vue crée un nonce,
    // envoie son SHA-256 à Apple (`request.nonce`) et transmet ici le résultat + le nonce brut.

    func handleAppleAuthorization(_ authorization: ASAuthorization, rawNonce: String) async throws {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            throw AuthError.missingIdentityToken
        }

        do {
            try await client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken,
                    nonce: rawNonce
                )
            )
        } catch {
            throw AuthError.underlying(error.localizedDescription)
        }
    }

    // MARK: - Sign in with Google

    func signInWithGoogle() async throws {
        guard let presenter = Self.topViewController() else {
            throw AuthError.underlying("Impossible de présenter Google Sign-In.")
        }

        let result: GIDSignInResult
        do {
            result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        } catch let error as NSError {
            // -5 = annulation utilisateur (kGIDSignInErrorCodeCanceled) ; on laisse réessayer.
            if error.domain == "com.google.GIDSignIn" && error.code == -5 {
                throw AuthError.cancelled
            }
            throw AuthError.underlying(error.localizedDescription)
        }

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingIdentityToken
        }
        let accessToken = result.user.accessToken.tokenString

        do {
            try await client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .google,
                    idToken: idToken,
                    accessToken: accessToken
                )
            )
        } catch {
            throw AuthError.underlying(error.localizedDescription)
        }
    }

    // MARK: - Sign out / delete

    func signOut() async {
        try? await client.auth.signOut()
        GIDSignIn.sharedInstance.signOut()
        currentUser = nil
        SocialService.shared.clearLocalState()
    }

    /// Supprime définitivement le compte via l'Edge Function `delete-user` (service role côté serveur),
    /// puis déconnecte localement. La cascade DB supprime `profiles` / `user_progress`.
    func deleteAccount() async throws {
        do {
            try await client.functions.invoke("delete-user")
        } catch {
            throw AuthError.underlying(error.localizedDescription)
        }
        await signOut()
    }

    // MARK: - Analytics identity

    /// Lie l'identité Supabase à RevenueCat + Mixpanel pour un même utilisateur cross-device.
    private func linkAnalyticsIdentity() {
        guard let userID = currentUser?.id.uuidString else { return }
        if Purchases.isConfigured {
            Purchases.shared.logIn(userID) { _, _, _ in
                AnalyticsService.linkRevenueCatUserIfNeeded()
            }
        }
    }

    // MARK: - Helpers

    static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        let keyWindow = scene?.windows.first { $0.isKeyWindow } ?? scene?.windows.first
        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
