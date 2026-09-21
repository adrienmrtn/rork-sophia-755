import SwiftUI

/// Page 10 — connexion obligatoire (Apple / Google). Réutilise `AuthProvidersView`.
/// Le coordinateur avance automatiquement dès qu'une session Supabase est établie.
struct OnboardingV2Login: View {
    @Environment(LanguageManager.self) private var languageManager
    var onSignedIn: () -> Void

    @State private var showTerms = false
    @State private var showPrivacy = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(OV2.accentSoft.opacity(0.12)).frame(width: 96, height: 96)
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(OV2.accent)
                }
                .ov2Reveal(delay: 0.05)

                Text(languageManager.text("onboardingV2.login.title"))
                    .font(DS.title(.title, .heavy))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                    .ov2Reveal(delay: 0.12)

                Text(languageManager.text("onboardingV2.login.subtitle"))
                    .font(DS.sans(.body, .medium))
                    .foregroundStyle(OV2.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .ov2Reveal(delay: 0.18)
            }

            Spacer()

            VStack(spacing: 16) {
                AuthProvidersView(onSignedIn: onSignedIn)
                    .padding(.horizontal, 24)
                #if DEBUG && targetEnvironment(simulator)
                Button("Skip login · simulator only") {
                    onSignedIn()
                }
                .font(DS.sans(.footnote, .semibold))
                .foregroundStyle(OV2.inkTertiary)
                .padding(.top, 4)
                #endif
                legalNote.padding(.horizontal, 32)
            }
            .padding(.bottom, 40)
            .ov2Reveal(delay: 0.24)
        }
        .ov2Background()
        .sheet(isPresented: $showTerms) { TermsView() }
        .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
    }

    private var legalNote: some View {
        VStack(spacing: 2) {
            Text(languageManager.text("auth.legal.prefix"))
                .font(DS.sans(.caption2, .medium))
                .foregroundStyle(OV2.inkTertiary)
            HStack(spacing: 4) {
                Button(languageManager.text("settings.terms.title")) { showTerms = true }
                    .font(DS.sans(.caption2, .semibold))
                    .foregroundStyle(OV2.inkSecondary)
                Text("·").foregroundStyle(OV2.inkTertiary)
                Button(languageManager.text("settings.privacy.title")) { showPrivacy = true }
                    .font(DS.sans(.caption2, .semibold))
                    .foregroundStyle(OV2.inkSecondary)
            }
        }
        .multilineTextAlignment(.center)
    }
}

/// Sign-in offered from the welcome page, for someone who already has an account.
///
/// Deliberately not the `.login` step of the flow: that one sits near the end, after
/// the objective, the swipe deck and the profile screen have all been answered. A
/// returning reader has answered them once already, and their real history comes back
/// from the cloud the moment they sign in — so this signs them in and drops them into
/// the app, skipping everything in between.
struct OnboardingV2ExistingAccountSheet: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.dismiss) private var dismiss

    var onSignedIn: () -> Void

    @State private var showTerms = false
    @State private var showPrivacy = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(OV2.inkSecondary)
                        .frame(width: 40, height: 40)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            Spacer()

            VStack(spacing: 12) {
                Text(languageManager.text("onboardingV2.existingAccount.title"))
                    .font(DS.title(.title, .heavy))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)

                Text(languageManager.text("onboardingV2.existingAccount.subtitle"))
                    .font(DS.sans(.body, .medium))
                    .foregroundStyle(OV2.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 16) {
                AuthProvidersView(onSignedIn: onSignedIn)
                    .padding(.horizontal, 24)
                legalNote.padding(.horizontal, 32)
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ov2Background()
        .preferredColorScheme(.light)
        .sheet(isPresented: $showTerms) { TermsView() }
        .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
    }

    /// Signing in with Apple creates the account when there isn't one, so the terms
    /// belong on this screen exactly as they do on the login step.
    private var legalNote: some View {
        VStack(spacing: 2) {
            Text(languageManager.text("auth.legal.prefix"))
                .font(DS.sans(.caption2, .medium))
                .foregroundStyle(OV2.inkTertiary)
            HStack(spacing: 4) {
                Button(languageManager.text("settings.terms.title")) { showTerms = true }
                    .font(DS.sans(.caption2, .semibold))
                    .foregroundStyle(OV2.inkSecondary)
                Text("·").foregroundStyle(OV2.inkTertiary)
                Button(languageManager.text("settings.privacy.title")) { showPrivacy = true }
                    .font(DS.sans(.caption2, .semibold))
                    .foregroundStyle(OV2.inkSecondary)
            }
        }
        .multilineTextAlignment(.center)
    }
}
