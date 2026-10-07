import SwiftUI
import UIKit

/// « Sophia est gratuite à l'essai » : la mission, et l'équipe qui compte sur la personne,
/// juste après « Sophia va t'aider à atteindre tous tes objectifs ». Le logo, trois phrases,
/// la signature de l'équipe avec les têtes des profs, un bouton.
struct OnboardingV2Mission: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var portraits: [UIImage] = []
    @State private var haloIn = false

    var body: some View {
        OV2ScrollableContent {
            VStack(spacing: 0) {
                Spacer().frame(height: 72)

                ZStack {
                    Circle()
                        .fill(OV2.accentSoft.opacity(0.10))
                        .frame(width: 150, height: 150)
                        .scaleEffect(haloIn ? 1.05 : 0.7)
                        .opacity(haloIn ? 1 : 0)
                    logo
                }
                .ov2Reveal(delay: 0.05)

                Spacer().frame(height: 26)

                Text(languageManager.text("onboardingV2.mission.title"))
                    .font(DS.title(.title, .heavy))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .ov2Reveal(delay: 0.15)

                Spacer().frame(height: 18)

                Text(languageManager.text("onboardingV2.mission.body1"))
                    .font(DS.sans(.body, .semibold))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
                    .ov2Reveal(delay: 0.28)

                Spacer().frame(height: 14)

                Text(languageManager.text("onboardingV2.mission.body2"))
                    .font(DS.sans(.body, .medium))
                    .foregroundStyle(OV2.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
                    .ov2Reveal(delay: 0.4)

                Spacer().frame(height: 28)

                signature
                    .ov2Reveal(delay: 0.55)

                Spacer(minLength: 24)
            }
        } footer: {
            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .onAppear {
            if portraits.isEmpty {
                portraits = Array(AuthorStore.all.compactMap { AuthorStore.photo(for: $0) }.prefix(5))
            }
            withAnimation(.spring(response: 0.9, dampingFraction: 0.75).delay(0.1)) {
                haloIn = true
            }
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
            HStack(spacing: -10) {
                ForEach(Array(portraits.enumerated()), id: \.offset) { i, image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                        .zIndex(Double(portraits.count - i))
                }
            }
            Text(languageManager.text("onboardingV2.mission.signature"))
                .font(DS.sans(.subheadline, .semibold))
                .foregroundStyle(OV2.inkSecondary)
        }
    }
}
