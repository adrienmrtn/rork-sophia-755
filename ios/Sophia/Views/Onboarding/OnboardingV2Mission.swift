import StoreKit
import SwiftUI
import UIKit

/// « Notre mission » : la mission, et l'équipe qui compte sur la personne.
///
/// Style « Elevate arrondi » : une grande illustration arrondie, la mission en titre (son
/// cœur en gras bleu), le texte de l'équipe en gris, puis la signature avec les têtes des
/// profs, et un bouton. La pastille « Sophia est gratuite à l'essai » a été retirée.
struct OnboardingV2Mission: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var portraits: [UIImage] = []

    var body: some View {
        OV2CorePage { height in
            pageBody
                // Bloc centré quand il tient, calé en haut et défilant sinon.
                .frame(minHeight: height, alignment: .center)
        } footer: {
            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .onAppear {
            if portraits.isEmpty {
                portraits = Array(AuthorStore.all.compactMap { AuthorStore.photo(for: $0) }.prefix(5))
            }
        }
        .task {
            await requestReviewOnce()
        }
    }

    // MARK: - Demande de note

    private static let reviewRequestedKey = "sophia_onboarding_review_requested"

    /// La demande de note de l'App Store, une seconde après l'apparition de la page et une
    /// seule fois par installation (revenir en arrière ne la rejoue pas). iOS décide seul de
    /// montrer ou non sa fenêtre.
    private func requestReviewOnce() async {
        guard !UserDefaults.standard.bool(forKey: Self.reviewRequestedKey) else { return }
        try? await Task.sleep(for: .seconds(1))
        guard !Task.isCancelled else { return }
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        UserDefaults.standard.set(true, forKey: Self.reviewRequestedKey)
        SKStoreReviewController.requestReview(in: scene)
    }

    private var pageBody: some View {
        VStack(spacing: 14) {
            illustration
                .dsStagger(0)

            OV2CoreHighlightTitle(text: missionTitle, size: 25, alignment: .center)
                .padding(.top, 4)
                .dsStagger(1)

            Text(languageManager.text("onboardingV2.mission.body2"))
                .font(DS.sans(.subheadline, .regular))
                .foregroundStyle(OV2.inkSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .dsStagger(2)

            signature
                .padding(.top, 2)
                .dsStagger(3)
        }
        .padding(.horizontal, OV2CoreMetrics.sideInset)
        .padding(.top, OV2CoreMetrics.topInset)
        .padding(.bottom, 16)
    }

    // MARK: - Textes

    /// « Notre mission : rendre l'apprentissage **facile, et accessible à tous.** »
    private var missionTitle: String {
        OV2CoreText.marked(
            "onboardingV2.mission.body1",
            highlightKey: "elevateOnboardingCore.mission.leadHighlight",
            language: languageManager.current
        )
    }

    // MARK: - Blocs

    /// L'illustration de l'équipe au travail ; à défaut, le logo.
    @ViewBuilder
    private var illustration: some View {
        if let image = UIImage(named: "creator_writing") {
            Color.clear
                .frame(height: 190)
                .frame(maxWidth: .infinity)
                .overlay(
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .accessibilityHidden(true)
        } else {
            logo
        }
    }

    @ViewBuilder
    private var logo: some View {
        if UIImage(named: "SplashLogo") != nil {
            Image("SplashLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 84, height: 84)
        } else {
            ZStack {
                Circle().fill(OV2.accent).frame(width: 84, height: 84)
                Image(systemName: "heart.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    /// Les têtes des profs qui se chevauchent, et « L'équipe Sophia ».
    private var signature: some View {
        HStack(spacing: 12) {
            if !portraits.isEmpty {
                HStack(spacing: -10) {
                    ForEach(Array(portraits.enumerated()), id: \.offset) { i, image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(DS.surface, lineWidth: 2))
                            .zIndex(Double(portraits.count - i))
                    }
                }
                .accessibilityHidden(true)
            }
            Text(languageManager.text("onboardingV2.mission.signature"))
                .font(DS.sans(.callout, .bold))
                .italic()
                .foregroundStyle(OV2.ink)
        }
    }
}
