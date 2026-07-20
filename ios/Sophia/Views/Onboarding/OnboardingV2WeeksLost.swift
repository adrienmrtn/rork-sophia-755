import SwiftUI

/// Page 7 — effet « waouh » : 52 carrés (les semaines de l'année), on colorie doucement
/// en rouge les semaines « perdues » au rythme de temps d'écran déclaré.
struct OnboardingV2WeeksLost: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var coloredCount = 0
    @State private var titleIn = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 8)

    private var weeksLost: Int { vm.weeksLostPerYear }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 72)

            VStack(spacing: 10) {
                Text(String(format: languageManager.text("onboardingV2.weeks.title"), weeksLost))
                    .font(DS.title(.title, .heavy))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                Text(languageManager.text("onboardingV2.weeks.subtitle"))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(OV2.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
            .opacity(titleIn ? 1 : 0)
            .offset(y: titleIn ? 0 : 14)

            Spacer()

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<52, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(i < coloredCount ? OV2.danger : OV2.accent.opacity(0.12))
                        .frame(height: 26)
                        .scaleEffect(i < coloredCount ? 1 : 0.85)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: coloredCount)
                }
            }
            .padding(.horizontal, 28)

            Spacer().frame(height: 24)

            Text(languageManager.text("onboardingV2.weeks.caption"))
                .font(DS.sans(.footnote, .medium))
                .foregroundStyle(OV2.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .ov2Reveal(delay: 0.6)

            Spacer()

            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { titleIn = true }
            animateSquares()
        }
    }

    private func animateSquares() {
        for i in 1...weeksLost {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(i) * 0.05) {
                coloredCount = i
                if i % 4 == 0 { OnboardingHaptics.selection() }
                if i == weeksLost { OnboardingHaptics.counterComplete() }
            }
        }
    }
}
