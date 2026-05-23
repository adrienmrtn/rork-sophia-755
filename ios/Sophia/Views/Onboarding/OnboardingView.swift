import SwiftUI
import RevenueCatUI

struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @State private var storeVM = StoreViewModel()
    let onComplete: () -> Void
    @State private var direction: Edge = .trailing
    @State private var showSpecialOffer: Bool = false
    @State private var showRCPaywall: Bool = false

    private let mondeActuelCategories: [(name: String, courses: [(title: String, courseId: String)])] = [
        ("Conflits & géopolitique", [
            ("La naissance du conflit israélo-palestinien", "course_201_la_naissance_du_conflit_israelo_palestin"),
            ("La rivalité Chine-États-Unis", "course_202_la_rivalite_chine_etats_unis"),
            ("Les tensions autour de Taïwan", "course_203_les_tensions_autour_de_taiwan"),
            ("La guerre en Ukraine expliquée", "course_210_la_guerre_en_ukraine_expliquee"),
            ("La Russie de Poutine", "course_209_la_russie_de_poutine"),
            ("L'OTAN : à quoi ça sert ?", "course_207_l_otan_a_quoi_ca_sert_encore"),
        ]),
        ("Économie & société", [
            ("Comment fonctionne le prix du pétrole", "course_211_comment_fonctionne_le_prix_du_petrole"),
            ("Les paradis fiscaux expliqués", "course_212_les_paradis_fiscaux_expliques"),
            ("L'évasion fiscale des multinationales", "course_213_l_evasion_fiscale_des_multinationales"),
            ("La dette mondiale", "course_216_la_dette_mondiale"),
            ("Les inégalités Nord-Sud", "course_215_les_inegalites_nord_sud"),
        ]),
        ("Environnement & avenir", [
            ("La crise de la biodiversité", "course_222_la_crise_de_la_biodiversite"),
            ("La montée des eaux", "course_225_la_montee_des_eaux"),
            ("L'IA et l'emploi", "course_226_l_ia_et_l_emploi"),
            ("Les migrations climatiques", "course_231_les_migrations_climatiques"),
        ]),
    ]

    private let cultureCategories: [(name: String, courses: [(title: String, courseId: String)])] = [
        ("Littérature classique", [
            ("1984, George Orwell", "course_101_1984_george_orwell"),
            ("Hamlet, Shakespeare", "course_103_hamlet_shakespeare"),
            ("Roméo et Juliette, Shakespeare", "course_104_romeo_et_juliette_shakespeare"),
            ("Frankenstein, Mary Shelley", "course_106_frankenstein_mary_shelley"),
            ("Le Meilleur des Mondes, Huxley", "course_105_le_meilleur_des_mondes_aldous_huxley"),
            ("Crime et Châtiment, Dostoïevski", "course_107_crime_et_chatiment_dostoievski"),
        ]),
        ("Art & Cinéma", [
            ("La naissance de la photographie", "course_141_la_naissance_de_la_photographie"),
            ("Orson Welles et Citizen Kane", "course_143_orson_welles_et_citizen_kane"),
            ("La Nouvelle Vague française", "course_144_la_nouvelle_vague_francaise"),
            ("Hitchcock et le suspense", "course_146_hitchcock_et_le_suspense"),
            ("Kubrick : 2001, l'Odyssée de l'espace", "course_145_kubrick_2001_l_odyssee_de_l_espace"),
        ]),
        ("Mythologie", [
            ("Les dieux grecs et l'Olympe", "course_161_la_naissance_des_dieux_grecs_cronos_zeus"),
            ("Ulysse et l'Odyssée", "course_81_l_odyssee_homere"),
            ("Hercule et les 12 travaux", "course_171_hercule_et_ses_12_travaux"),
            ("Thor et Loki, mythologie nordique", "course_180_thor_et_loki_mythologie_nordique"),
            ("Les grands mythes romains", "course_184_romulus_et_remus_la_fondation_de_rome"),
        ]),
    ]

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            Group {
                switch viewModel.currentScreen {
                case 0:
                    OnboardingIntroScreen(onNext: advance)
                case 1:
                    OnboardingWelcomeScreen(onNext: advance)
                case 2:
                    OnboardingPhoneTimeScreen(viewModel: viewModel, onNext: advance)
                case 3:
                    OnboardingWastedTimeScreen(viewModel: viewModel, onNext: advance)
                case 4:
                    OnboardingObjectivesScreen(viewModel: viewModel, onNext: advance)
                case 5:
                    OnboardingSocialProofScreen(onNext: advance)
                case 6:
                    OnboardingTopicsCarouselScreen(
                        title: "Sophia t'aide à comprendre\nle monde qui t'entoure",
                        subtitle: "Géopolitique, économie, environnement...\nles enjeux actuels expliqués simplement.",
                        categories: mondeActuelCategories,
                        onNext: advance
                    )
                case 7:
                    OnboardingTopicsCarouselScreen(
                        title: "Maîtrise enfin les grandes\nœuvres de l'histoire",
                        subtitle: "Littérature, art, cinéma, mythologie...\nles clés pour en parler avec aisance.",
                        categories: cultureCategories,
                        onNext: advance
                    )
                case 8:
                    OnboardingInterestsScreen(viewModel: viewModel, onNext: advance)
                case 9:
                    OnboardingDailyGoalScreen(viewModel: viewModel, onNext: advance)
                case 10:
                    OnboardingProjectionScreen(viewModel: viewModel, onNext: advance)
                case 11:
                    OnboardingAgeScreen(viewModel: viewModel, onNext: advance)
                case 12:
                    OnboardingProfileGenScreen(onNext: advance)
                case 13:
                    OnboardingLoadingScreen(viewModel: viewModel, onNext: advance)
                case 14:
                    OnboardingFinalScreen(onComplete: advance)
                case 15:
                    OnboardingFreeTrialIntroView(onNext: advance)
                case 16:
                    OnboardingFreeTrialTimelineView(onNext: advance)
                case 17:
                    Color.clear
                        .onAppear {
                            showRCPaywall = true
                        }
                default:
                    EmptyView()
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            if viewModel.currentScreen > 0 && viewModel.currentScreen < 12 {
                VStack {
                    OnboardingProgressDots(current: viewModel.currentScreen, total: 12)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                    Spacer()
                }
            }

            if showSpecialOffer {
                OnboardingSpecialOfferView(
                    store: storeVM,
                    onSubscribed: {
                        showSpecialOffer = false
                        viewModel.completeOnboarding()
                        onComplete()
                    },
                    onSkip: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            showSpecialOffer = false
                        }
                        viewModel.completeOnboarding()
                        onComplete()
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showRCPaywall, onDismiss: {
            viewModel.completeOnboarding()
            onComplete()
        }) {
            SophiaPaywallView(
                context: .finOnboarding,
                onPurchased: {
                    showRCPaywall = false
                    viewModel.completeOnboarding()
                    onComplete()
                },
                onRestored: {
                    showRCPaywall = false
                    viewModel.completeOnboarding()
                    onComplete()
                }
            )
        }
    }

    private func advance() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            viewModel.nextScreen()
        }
    }
}

struct OnboardingProgressDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i <= current ? BrutalPalette.ink : BrutalPalette.ink.opacity(0.15))
                    .frame(width: i == current ? 28 : 10, height: 5)
                    .animation(.spring(response: 0.3), value: current)
            }
        }
    }
}
