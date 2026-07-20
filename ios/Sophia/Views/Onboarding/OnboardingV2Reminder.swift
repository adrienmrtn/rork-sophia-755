import SwiftUI

/// Page 12 — « You'll get a reminder 1 day before your trial ends ». Cloche animée +
/// texte dont le gras avance mot à mot pour guider la lecture. Inspiré du 2e screenshot.
struct OnboardingV2Reminder: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var boldCount = 0
    @State private var bellWobble = false
    @State private var bellIn = false

    private var words: [String] {
        languageManager.text("onboardingV2.reminder.title").split(separator: " ").map(String.init)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            progressiveText
                .padding(.horizontal, 32)

            Spacer().frame(height: 48)

            Image(systemName: "bell.fill")
                .font(.system(size: 96))
                .foregroundStyle(OV2.warm)
                .rotationEffect(.degrees(bellWobble ? 12 : -12), anchor: .top)
                .scaleEffect(bellIn ? 1 : 0.5)
                .opacity(bellIn ? 1 : 0)

            Spacer()

            OnboardingV2Button(title: languageManager.text("onboardingV2.reminder.cta"), action: onNext)
        }
        .ov2Background()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { bellIn = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                    bellWobble = true
                }
            }
            for i in 0...words.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.12) {
                    boldCount = i
                    if i < words.count { OnboardingHaptics.selection() }
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
