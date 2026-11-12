import SwiftUI
import UIKit

/// « Sophia est gratuite à l'essai » : la mission, et l'équipe qui compte sur la personne.
///
/// Style « Elevate arrondi » : une grande illustration arrondie, « Sophia est gratuite à
/// l'essai » en pastille bleue, la mission en titre (son cœur en gras bleu), le texte de
/// l'équipe en gris, puis la signature avec les têtes des profs, et un bouton.
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
    }

    private var pageBody: some View {
        VStack(spacing: 14) {
            illustration
                .dsStagger(0)

            trialChip
                .dsStagger(1)

            OV2CoreHighlightTitle(text: missionTitle, size: 25, alignment: .center)
                .dsStagger(2)

            Text(languageManager.text("onboardingV2.mission.body2"))
                .font(DS.sans(.subheadline, .regular))
                .foregroundStyle(OV2.inkSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .dsStagger(3)

            signature
                .padding(.top, 2)
                .dsStagger(4)
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

    /// « Sophia est gratuite à l'essai », sans son point final : c'est une étiquette ici.
    private var trialChipText: String {
        OV2CoreText.trimmingTrailing(".。", from: languageManager.text("onboardingV2.mission.title"))
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

    private var trialChip: some View {
        Text(trialChipText)
            .font(DS.sans(.footnote, .bold))
            .tracking(0.4)
            .foregroundStyle(DS.accent)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(DS.accentTint)
            )
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
