import SwiftUI
import AuthenticationServices
import UIKit

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
    @State private var applePresenter = AppleSignInPresenter()

    var body: some View {
        VStack(spacing: 12) {
            // Official `SignInWithAppleButton` ignores the in-app language and stays
            // on the system/bundle locale (usually French). Same capsule as Google,
            // with a localized "Continue with Apple" label.
            Button {
                handleApple()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18, weight: .semibold))
                    Text(languageManager.text("auth.continueWithApple"))
                        .font(.jakarta(.body, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.black, in: Capsule(style: .continuous))
            }
            .buttonStyle(SoftPressButtonStyle())
            .opacity(isWorking ? 0.6 : 1)
            .disabled(isWorking)

            Button {
                handleGoogle()
            } label: {
                HStack(spacing: 10) {
                    GoogleGLogo(size: 18)
                    Text(languageManager.text("auth.continueWithGoogle"))
                        .font(.jakarta(.body, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.85))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.white, in: Capsule(style: .continuous))
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(Color.black.opacity(0.15), lineWidth: 1)
                }
            }
            .buttonStyle(SoftPressButtonStyle())
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

    private func handleApple() {
        let raw = AuthNonce.randomNonceString()
        currentNonce = raw
        applePresenter.onComplete = { result in
            handleAppleCompletion(result)
        }
        applePresenter.start(hashedNonce: AuthNonce.sha256(raw))
    }

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
        case .underlying:
            return languageManager.text("auth.error.generic")
        }
    }
}

/// Logo « G » Google multicolore, dessiné en vectoriel avec le placement de couleurs officiel
/// (rouge en haut, bleu à droite + barre, vert en bas, jaune à gauche) — pas d'asset binaire.
struct GoogleGLogo: View {
    var size: CGFloat = 18

    // Couleurs de marque Google.
    private let blue = Color(red: 0.259, green: 0.522, blue: 0.957)
    private let red = Color(red: 0.918, green: 0.263, blue: 0.208)
    private let yellow = Color(red: 0.984, green: 0.737, blue: 0.020)
    private let green = Color(red: 0.204, green: 0.659, blue: 0.325)

    var body: some View {
        let lw = size * 0.30
        let ringSize = size - lw
        ZStack {
            // Anneau à 4 arcs. `trim` part de 3 h et tourne dans le sens horaire :
            // 0.0 = droite, 0.25 = bas, 0.5 = gauche, 0.75 = haut.
            arc(0.111, 0.361, green, lw, ringSize)   // bas
            arc(0.361, 0.592, yellow, lw, ringSize)  // gauche
            arc(0.592, 0.861, red, lw, ringSize)     // haut
            arc(0.861, 1.0, blue, lw, ringSize)      // droite (haut)
            arc(0.0, 0.111, blue, lw, ringSize)      // droite (bas)

            // Barre horizontale bleue : du centre du « G » jusqu'à l'anneau à droite.
            RoundedRectangle(cornerRadius: lw * 0.16, style: .continuous)
                .fill(blue)
                .frame(width: size * 0.34, height: lw)
                .offset(x: size * 0.16)
        }
        .frame(width: size, height: size)
    }

    private func arc(_ from: CGFloat, _ to: CGFloat, _ color: Color, _ lw: CGFloat, _ ringSize: CGFloat) -> some View {
        Circle()
            .trim(from: from, to: to)
            .stroke(color, style: StrokeStyle(lineWidth: lw, lineCap: .butt))
            .frame(width: ringSize, height: ringSize)
    }
}

/// Runs Sign in with Apple so the visible button can follow the in-app language.
@MainActor
final class AppleSignInPresenter: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    var onComplete: ((Result<ASAuthorization, Error>) -> Void)?
    private var controller: ASAuthorizationController?

    func start(hashedNonce: String) {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        self.controller = controller
        controller.performRequests()
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        onComplete?(.success(authorization))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onComplete?(.failure(error))
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        return windows.first(where: \.isKeyWindow) ?? windows.first ?? ASPresentationAnchor()
    }
}
