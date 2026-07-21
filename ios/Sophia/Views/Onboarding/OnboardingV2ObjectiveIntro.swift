import SwiftUI

/// Page de transition après les objectifs : « Sophia va t'aider à atteindre tous tes objectifs ».
/// Gras progressif sur le texte (guide la lecture), pas de CTA : tap n'importe où pour continuer.
struct OnboardingV2ObjectiveIntro: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var boldCount = 0
    @State private var glowIn = false
    @State private var hintPulse = false
    @State private var canTap = false

    private var words: [String] {
        languageManager.text("onboardingV2.objectiveIntro.title").split(separator: " ").map(String.init)
    }

    var body: some View {
        ZStack {
            OV2.bg.ignoresSafeArea()

            // Halo doux qui « respire ».
            Circle()
                .fill(OV2.accentSoft.opacity(0.10))
                .frame(width: 320, height: 320)
                .scaleEffect(glowIn ? 1.05 : 0.8)
                .blur(radius: 30)
                .opacity(glowIn ? 1 : 0)

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle().fill(OV2.accent.opacity(0.10)).frame(width: 108, height: 108)
                    Image(systemName: "target")
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundStyle(OV2.accent)
                        .scaleEffect(glowIn ? 1 : 0.6)
                        .opacity(glowIn ? 1 : 0)
                }

                Spacer().frame(height: 36)

                progressiveText
                    .padding(.horizontal, 34)

                Spacer()

                Text(languageManager.text("onboardingV2.tapToContinue"))
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(OV2.inkTertiary)
                    .opacity(canTap ? (hintPulse ? 1 : 0.4) : 0)
                    .padding(.bottom, 48)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard canTap else { return }
            OnboardingHaptics.primaryCTA()
            onNext()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) { glowIn = true }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                // léger « souffle » du halo
            }
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

    private var progressiveText: some View {
        words.indices.reduce(Text("")) { partial, i in
            let word = words[i] + (i < words.count - 1 ? " " : "")
            let styled = Text(word)
                .font(DS.title(.title, i < boldCount ? .heavy : .semibold))
                .foregroundColor(i < boldCount ? OV2.ink : OV2.inkTertiary.opacity(0.5))
            return partial + styled
        }
        .multilineTextAlignment(.center)
    }
}
