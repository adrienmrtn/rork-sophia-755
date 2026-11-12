import SwiftUI

/// Première page de l'onboarding : connexion obligatoire (Apple ou Google) pour les nouveaux
/// utilisateurs. Pas d'option « continuer sans compte ». Une fois connecté, le funnel démarre.
struct OnboardingAuthScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    var onSignedIn: () -> Void

    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            DS.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    OV2EndTitle(text: languageManager.text("auth.onboarding.title"))
                    OV2EndSubtitle(text: languageManager.text("auth.onboarding.subtitle"))
                }
                .padding(.top, OV2End.topWithoutHeader)
                .padding(.horizontal, OV2End.side)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)

                Spacer(minLength: 16)

                OV2EndAccountIllustration()
                    .layoutPriority(1)

                Spacer(minLength: 16)

                VStack(spacing: 14) {
                    AuthProvidersView(onSignedIn: onSignedIn)
                        .padding(.horizontal, OV2End.side)

                    OV2EndLegalNote(
                        onTerms: { showTerms = true },
                        onPrivacy: { showPrivacy = true }
                    )
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 44)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showTerms) { TermsView() }
        .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
        .onAppear {
            withAnimation(DS.Motion.reveal) {
                appeared = true
            }
        }
    }
}
