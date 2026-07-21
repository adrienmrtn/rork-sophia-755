import SwiftUI
import AuthenticationServices
import GoogleSignInSwift

/// Boutons de connexion Apple + Google réutilisables (onboarding & réglages).
///
/// Gère l'état de chargement, l'annulation (silencieuse) et l'échec (message + réessayer,
/// conformément au comportement voulu : pas de « continuer sans compte »).
struct AuthProvidersView: View {
    /// Appelé une fois la session Supabase établie.
    var onSignedIn: () -> Void

    @Environment(LanguageManager.self) private var languageManager
    @State private var isWorking = false
    @State private var currentNonce: String?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            SignInWithAppleButton(.continue) { request in
                let raw = AuthNonce.randomNonceString()
                currentNonce = raw
                request.requestedScopes = [.fullName, .email]
                request.nonce = AuthNonce.sha256(raw)
            } onCompletion: { result in
                handleAppleCompletion(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .clipShape(Capsule(style: .continuous))
            .disabled(isWorking)

            GoogleSignInButton(
                viewModel: GoogleSignInButtonViewModel(scheme: .light, style: .wide, state: .normal)
            ) {
                handleGoogle()
            }
            .frame(height: 52)
            .clipShape(Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
            }
            .opacity(isWorking ? 0.6 : 1)
            .disabled(isWorking)

            if let errorMessage {
                Text(errorMessage)
                    .font(.jakarta(.footnote, weight: .medium))
                    .foregroundStyle(DS.danger)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
                    .padding(.top, 2)
            }

            if isWorking {
                ProgressView()
                    .padding(.top, 4)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
        .animation(.easeInOut(duration: 0.2), value: isWorking)
    }

    // MARK: - Actions

    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                return // annulation : on laisse réessayer sans message
            }
            errorMessage = languageManager.text("auth.error.generic")
        case .success(let authorization):
            guard let rawNonce = currentNonce else {
                errorMessage = languageManager.text("auth.error.generic")
                return
            }
            run {
                try await AuthService.shared.handleAppleAuthorization(authorization, rawNonce: rawNonce)
            }
        }
    }

    private func handleGoogle() {
        run {
            try await AuthService.shared.signInWithGoogle()
        }
    }

    private func run(_ operation: @escaping () async throws -> Void) {
        guard !isWorking else { return }
        errorMessage = nil
        isWorking = true
        Task {
            do {
                try await operation()
                isWorking = false
                onSignedIn()
            } catch let error as AuthError {
                isWorking = false
                if case .cancelled = error { return }
                errorMessage = resolvedMessage(for: error)
            } catch {
                isWorking = false
                errorMessage = languageManager.text("auth.error.generic")
            }
        }
    }

    private func resolvedMessage(for error: AuthError) -> String {
        switch error {
        case .cancelled:
            return ""
        case .missingIdentityToken:
            return languageManager.text("auth.error.token")
        case .underlying(let message):
            // Message serveur remonté pour diagnostic (ex. config provider Supabase).
            return message
        }
    }
}
