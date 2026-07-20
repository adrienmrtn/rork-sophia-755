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
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(BrutalPalette.ink)

                    Text(languageManager.text("auth.onboarding.title"))
                        .font(.jakarta(.title, design: .rounded, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                        .multilineTextAlignment(.center)

                    Text(languageManager.text("auth.onboarding.subtitle"))
                        .font(.jakarta(.body, weight: .medium))
                        .foregroundStyle(BrutalPalette.ink.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .padding(.horizontal, 28)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                Spacer()

                VStack(spacing: 16) {
                    AuthProvidersView(onSignedIn: onSignedIn)
                        .padding(.horizontal, 24)

                    legalNote
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 44)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
            }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showTerms) { TermsView() }
        .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private var legalNote: some View {
        VStack(spacing: 2) {
            Text(languageManager.text("auth.legal.prefix"))
                .font(.jakarta(.caption2, weight: .medium))
                .foregroundStyle(BrutalPalette.ink.opacity(0.5))
            HStack(spacing: 4) {
                Button(languageManager.text("settings.terms.title")) { showTerms = true }
                    .font(.jakarta(.caption2, weight: .semibold))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.7))
                Text("·")
                    .foregroundStyle(BrutalPalette.ink.opacity(0.4))
                Button(languageManager.text("settings.privacy.title")) { showPrivacy = true }
                    .font(.jakarta(.caption2, weight: .semibold))
                    .foregroundStyle(BrutalPalette.ink.opacity(0.7))
            }
        }
        .multilineTextAlignment(.center)
    }
}
