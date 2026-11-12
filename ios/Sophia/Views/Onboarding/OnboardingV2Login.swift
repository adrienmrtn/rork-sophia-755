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
            OV2EndTitle(text: languageManager.text("onboardingV2.login.title"))
                .padding(.top, OV2End.topWithoutHeader)
                .padding(.horizontal, OV2End.side)
                .dsStagger(0)

            OV2EndSubtitle(text: languageManager.text("onboardingV2.login.subtitle"))
                .padding(.top, 10)
                .padding(.horizontal, OV2End.side)
                .dsStagger(1)

            Spacer(minLength: 16)

            OV2EndAccountIllustration()
                .layoutPriority(1)

            Spacer(minLength: 16)

            VStack(spacing: 14) {
                AuthProvidersView(onSignedIn: onSignedIn)
                    .padding(.horizontal, OV2End.side)
                #if DEBUG && targetEnvironment(simulator)
                Button("Skip login · simulator only") {
                    onSignedIn()
                }
                .font(DS.sans(.footnote, .semibold))
                .foregroundStyle(DS.inkTertiary)
                .padding(.top, 4)
                #endif
                OV2EndLegalNote(
                    onTerms: { showTerms = true },
                    onPrivacy: { showPrivacy = true }
                )
                .padding(.horizontal, 32)
            }
            .padding(.bottom, 40)
            .dsStagger(2)
        }
        .ov2Background()
        .sheet(isPresented: $showTerms) { TermsView() }
        .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
    }
}

/// Illustration ronde des écrans de connexion : un lecteur parmi ses livres, pris dans la
/// série des avatars de l'app. Elle se pose avec un rebond, et rétrécit d'elle-même quand
/// l'écran est court (petit iPhone, grande taille de texte).
struct OV2EndAccountIllustration: View {
    var maxSize: CGFloat = 190
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let avatarId = "avatar_04"

    var body: some View {
        Image(Self.avatarId)
            .resizable()
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: maxSize, maxHeight: maxSize)
            .clipShape(Circle())
            .scaleEffect(shown || reduceMotion ? 1 : 0.7)
            .opacity(shown ? 1 : 0)
            .onAppear {
                guard !shown else { return }
                withAnimation(DS.Motion.pop.delay(0.15)) { shown = true }
            }
            .accessibilityHidden(true)
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
                        .foregroundStyle(DS.inkSecondary)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.pressable)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            OV2EndTitle(text: languageManager.text("onboardingV2.existingAccount.title"))
                .padding(.top, 8)
                .padding(.horizontal, OV2End.side)

            OV2EndSubtitle(text: languageManager.text("onboardingV2.existingAccount.subtitle"))
                .padding(.top, 10)
                .padding(.horizontal, OV2End.side)

            Spacer(minLength: 16)

            OV2EndAccountIllustration()
                .layoutPriority(1)

            Spacer(minLength: 16)

            VStack(spacing: 14) {
                AuthProvidersView(onSignedIn: onSignedIn)
                    .padding(.horizontal, OV2End.side)
                // Signing in with Apple creates the account when there isn't one, so the
                // terms belong on this screen exactly as they do on the login step.
                OV2EndLegalNote(
                    onTerms: { showTerms = true },
                    onPrivacy: { showPrivacy = true }
                )
                .padding(.horizontal, 32)
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ov2Background()
        .preferredColorScheme(.light)
        .sheet(isPresented: $showTerms) { TermsView() }
        .sheet(isPresented: $showPrivacy) { PrivacyPolicyView() }
    }
}
