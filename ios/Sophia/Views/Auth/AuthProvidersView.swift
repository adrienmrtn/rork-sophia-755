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
    /// Numéro de la tentative en cours : un garde-temps d'une tentative abandonnée ne doit
    /// pas couper la suivante.
    @State private var attempt = 0

    var body: some View {
        VStack(spacing: 12) {
            // Official `SignInWithAppleButton` ignores the in-app language and stays
            // on the system/bundle locale (usually French). Same rounded rectangle as
            // Google, with a localized "Continue with Apple" label.
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
                .frame(height: 54)
                .background(Color.black, in: RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
            }
            .buttonStyle(.pressable)
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
                .frame(height: 54)
                .background(Color.white, in: RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                        .strokeBorder(DS.hairline, lineWidth: 1.5)
                }
                .contentShape(RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
            }
            .buttonStyle(.pressable)
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
        attempt += 1
        let token = attempt

        Task { @MainActor in
            do {
                try await operation()
                guard token == attempt else { return }
                isWorking = false
                // Un message posé par le garde-temps n'a plus lieu d'être si la connexion
                // finit par aboutir.
                errorMessage = nil
                onSignedIn()
            } catch let error as AuthError {
                guard token == attempt else { return }
                isWorking = false
                if case .cancelled = error { return }
                errorMessage = resolvedMessage(for: error)
            } catch {
                guard token == attempt else { return }
                isWorking = false
                errorMessage = languageManager.text("auth.error.generic")
            }
        }

        // Garde-temps. La connexion est **obligatoire** pour finir l'onboarding : un
        // fournisseur qui ne rappelle jamais (feuille système qui ne s'ouvre pas, requête
        // qui ne rend pas la main) laissait le spinner tourner avec les deux boutons grisés,
        // donc un onboarding sans issue — exactement ce que l'App Store a rejeté
        // (Guideline 2.1(a), « indefinite loading during onboarding »). Les boutons
        // reviennent toujours, avec un message et la possibilité de réessayer.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard token == attempt, isWorking else { return }
            isWorking = false
            errorMessage = languageManager.text("auth.error.generic")
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

/// Le « G » de Google en quatre couleurs : les quatre tracés officiels du logo (repère de
/// 48 × 48) et ses couleurs de marque, dessinés en vectoriel — net à toute taille, jamais
/// étiré (même échelle en largeur et en hauteur) ni teinté.
struct GoogleGLogo: View {
    var size: CGFloat = 18

    var body: some View {
        ZStack {
            GoogleGPiece(commands: GoogleGPaths.red)
                .fill(Color(red: 0.918, green: 0.263, blue: 0.208))
            GoogleGPiece(commands: GoogleGPaths.blue)
                .fill(Color(red: 0.259, green: 0.522, blue: 0.957))
            GoogleGPiece(commands: GoogleGPaths.yellow)
                .fill(Color(red: 0.984, green: 0.737, blue: 0.020))
            GoogleGPiece(commands: GoogleGPaths.green)
                .fill(Color(red: 0.204, green: 0.659, blue: 0.325))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Une instruction de tracé, dans le repère de 48 × 48 du logo.
nonisolated private enum GoogleGCommand: Sendable {
    case move(CGFloat, CGFloat)
    case line(CGFloat, CGFloat)
    /// Courbe de Bézier cubique : premier point de contrôle, second, puis point d'arrivée.
    case curve(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)
    case close
}

/// Les quatre morceaux du « G », repris tels quels du logo officiel.
nonisolated private enum GoogleGPaths {
    /// L'arc rouge, en haut.
    static let red: [GoogleGCommand] = [
        .move(24, 9.5),
        .curve(27.54, 9.5, 30.71, 10.72, 33.21, 13.1),
        .line(40.06, 6.25),
        .curve(35.9, 2.38, 30.47, 0, 24, 0),
        .curve(14.62, 0, 6.51, 5.38, 2.56, 13.22),
        .line(10.54, 19.41),
        .curve(12.43, 13.72, 17.74, 9.5, 24, 9.5),
        .close,
    ]

    /// La barre et l'arc bleus, à droite.
    static let blue: [GoogleGCommand] = [
        .move(46.98, 24.55),
        .curve(46.98, 22.98, 46.83, 21.46, 46.6, 20),
        .line(24, 20),
        .line(24, 29.02),
        .line(36.94, 29.02),
        .curve(36.36, 31.98, 34.68, 34.5, 32.16, 36.2),
        .line(39.89, 42.2),
        .curve(44.4, 38.02, 46.98, 31.84, 46.98, 24.55),
        .close,
    ]

    /// L'arc jaune, à gauche.
    static let yellow: [GoogleGCommand] = [
        .move(10.53, 28.59),
        .curve(10.05, 27.14, 9.77, 25.6, 9.77, 24),
        .curve(9.77, 22.4, 10.04, 20.86, 10.53, 19.41),
        .line(2.55, 13.22),
        .curve(0.92, 16.46, 0, 20.12, 0, 24),
        .curve(0, 27.88, 0.92, 31.54, 2.56, 34.78),
        .line(10.53, 28.59),
        .close,
    ]

    /// L'arc vert, en bas.
    static let green: [GoogleGCommand] = [
        .move(24, 48),
        .curve(30.48, 48, 35.93, 45.87, 39.89, 42.19),
        .line(32.16, 36.19),
        .curve(30.01, 37.64, 27.24, 38.49, 24, 38.49),
        .curve(17.74, 38.49, 12.43, 34.27, 10.53, 28.58),
        .line(2.55, 34.77),
        .curve(6.51, 42.62, 14.62, 48, 24, 48),
        .close,
    ]
}

/// Un morceau du « G », mis à l'échelle du cadre sans le déformer et centré dedans.
private struct GoogleGPiece: Shape {
    let commands: [GoogleGCommand]

    func path(in rect: CGRect) -> Path {
        let scale: CGFloat = min(rect.width, rect.height) / 48
        let originX: CGFloat = rect.midX - 24 * scale
        let originY: CGFloat = rect.midY - 24 * scale
        var path = Path()
        for command in commands {
            switch command {
            case .move(let x, let y):
                path.move(to: CGPoint(x: originX + x * scale, y: originY + y * scale))
            case .line(let x, let y):
                path.addLine(to: CGPoint(x: originX + x * scale, y: originY + y * scale))
            case .curve(let c1x, let c1y, let c2x, let c2y, let x, let y):
                path.addCurve(
                    to: CGPoint(x: originX + x * scale, y: originY + y * scale),
                    control1: CGPoint(x: originX + c1x * scale, y: originY + c1y * scale),
                    control2: CGPoint(x: originX + c2x * scale, y: originY + c2y * scale)
                )
            case .close:
                path.closeSubpath()
            }
        }
        return path
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
