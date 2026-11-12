import SwiftUI

/// Page 10 — connexion obligatoire (Apple / Google).
///
/// La page ne montre qu'un bouton, « Me connecter » ; il ouvre une languette, juste assez
/// haute pour ses deux boutons « Continuer avec Apple » et « Continuer avec Google »
/// (`AuthProvidersView`, avec son état de chargement, ses messages d'erreur et son
/// garde-temps). Le coordinateur avance automatiquement dès qu'une session Supabase est établie.
struct OnboardingV2Login: View {
    @Environment(LanguageManager.self) private var languageManager
    var onSignedIn: () -> Void

    @State private var showTerms = false
    @State private var showPrivacy = false
    /// La languette des deux fournisseurs de connexion est ouverte.
    @State private var showProviders = false

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
                OnboardingV2Button(
                    title: languageManager.text("onboardingV2.login.connect"),
                    bottomPadding: 0,
                    action: { showProviders = true }
                )
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
        .sheet(isPresented: $showProviders) {
            OnboardingV2SignInSheet(onSignedIn: {
                showProviders = false
                onSignedIn()
            })
        }
    }
}

/// Languette de connexion : « Continuer avec Apple » et « Continuer avec Google ».
///
/// Elle épouse son contenu : sa hauteur est celle, mesurée, des deux boutons et de leurs
/// marges (plus le message d'erreur ou l'indicateur d'attente quand ils apparaissent), au
/// lieu d'une demi-page vide. La zone sûre du bas s'ajoute d'elle-même sous cette hauteur.
/// Si le contenu dépassait l'écran (très grande taille de texte, message long), il défile.
struct OnboardingV2SignInSheet: View {
    var onSignedIn: () -> Void

    /// Hauteur mesurée du contenu ; 0 tant que la première mesure n'est pas arrivée.
    @State private var contentHeight: CGFloat = 0

    /// Hauteur de départ, avant la première mesure : la poignée, deux boutons de 54 pt, leur
    /// écart et les marges.
    private static let estimatedHeight: CGFloat = 176

    var body: some View {
        ScrollView(.vertical) {
            AuthProvidersView(onSignedIn: onSignedIn)
                .padding(.horizontal, OV2End.side)
                // Sous la poignée de la languette.
                .padding(.top, 34)
                .padding(.bottom, 16)
                .frame(maxWidth: OV2.readableWidth)
                .frame(maxWidth: .infinity)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    contentHeight = height
                }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .background(OV2.bg.ignoresSafeArea())
        .presentationDetents([.height(contentHeight > 0 ? contentHeight : Self.estimatedHeight)])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.light)
    }
}

/// Illustration ronde des écrans de connexion : un lecteur parmi ses livres, pris dans la
/// série des avatars de l'app. Elle se pose en douceur, et rétrécit d'elle-même quand
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
            .scaleEffect(shown || reduceMotion ? 1 : 0.9)
            .opacity(shown ? 1 : 0)
            .onAppear {
                guard !shown else { return }
                withAnimation(DSCalmMotion.settle.delay(0.15)) { shown = true }
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
