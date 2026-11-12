import SwiftUI

/// Page de transition après les objectifs : « Sophia va t'aider à atteindre tous tes objectifs »,
/// avec le prénom devant quand il a été donné.
/// Gras progressif sur le texte (guide la lecture), pas de CTA : tap n'importe où pour continuer.
///
/// Style « Elevate arrondi » : l'illustration ronde du chemin, puis la phrase en très grand,
/// centrée, et l'invitation à toucher l'écran en bas.
struct OnboardingV2ObjectiveIntro: View {
    @Environment(LanguageManager.self) private var languageManager
    var firstName: String = ""
    let onNext: () -> Void

    @State private var boldCount = 0
    @State private var hintPulse = false
    @State private var canTap = false

    private var words: [String] {
        OnboardingV2ViewModel.personalizedText("onboardingV2.objectiveIntro.title", name: firstName, language: languageManager.current)
            .split(separator: " ")
            .map(String.init)
    }

    var body: some View {
        ZStack {
            OV2.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 16)

                OV2CoreIllustration(art: .path, size: 160)
                    .dsPopIn(delay: 0.1)

                Spacer().frame(height: 26)

                progressiveText
                    .padding(.horizontal, OV2CoreMetrics.sideInset)

                Spacer(minLength: 16)

                OV2CoreTapHint(text: languageManager.text("onboardingV2.tapToContinue"))
                    .opacity(canTap ? (hintPulse ? 1 : 0.45) : 0)
                    .padding(.bottom, 28)
            }
            .frame(maxWidth: OV2.readableWidth)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard canTap else { return }
            OnboardingHaptics.primaryCTA()
            onNext()
        }
        .onAppear {
            for i in 0...words.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35 + Double(i) * 0.13) {
                    boldCount = i
                    if i < words.count { OnboardingHaptics.selection() }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35 + Double(words.count) * 0.13 + 0.2) {
                withAnimation(.easeInOut(duration: 0.4)) { canTap = true }
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    hintPulse = true
                }
            }
        }
    }

    /// La phrase, mot après mot : gris et demi-gras avant le passage du gras, encre et très
    /// gras après.
    private var progressiveText: some View {
        words.indices.reduce(Text("")) { partial, i in
            let word = words[i] + (i < words.count - 1 ? " " : "")
            let styled = Text(word)
                .font(DS.title(.largeTitle, i < boldCount ? .heavy : .semibold))
                .foregroundColor(i < boldCount ? OV2.ink : OV2.inkTertiary.opacity(0.6))
            return partial + styled
        }
        .multilineTextAlignment(.center)
        .lineSpacing(2)
        .minimumScaleFactor(0.7)
    }
}
