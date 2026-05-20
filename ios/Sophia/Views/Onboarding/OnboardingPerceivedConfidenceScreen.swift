import SwiftUI

struct OnboardingPerceivedConfidenceScreen: View {
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var percentValue: Int = 0
    @State private var showText: Bool = false

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 26) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(percentValue)")
                            .font(.system(size: 80, weight: .heavy, design: .rounded))
                            .foregroundStyle(SophiaTheme.emerald)
                            .contentTransition(.numericText(countsDown: false))
                        Text("%")
                            .font(.system(size: 54, weight: .heavy, design: .rounded))
                            .foregroundStyle(SophiaTheme.emerald)
                    }
                    .opacity(appeared ? 1 : 0)

                    if showText {
                        VStack(spacing: 12) {
                            Text("En moyenne, une personne cultivée gagne 23% de plus en confiance perçue")
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)

                            Text("En entretien, en soirée, en réunion. Pas parce qu'elle est plus intelligente, mais parce qu'elle a des choses à dire.")
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .transition(.opacity.combined(with: .offset(y: 10)))
                    }
                }

                Spacer()

                OnboardingButton(title: "Continuer", action: onNext)
                    .opacity(showText ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.2)) {
                appeared = true
            }
            animatePercent()
        }
    }

    private func animatePercent() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        let steps = 26
        let interval = 1.0 / Double(steps)

        for step in 0...steps {
            let delay = 0.35 + interval * Double(step)
            let progress = Double(step) / Double(steps)
            let eased = 1 - pow(1 - progress, 3)
            let value = Int(eased * 23)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.snappy(duration: 0.08)) {
                    percentValue = value
                }
                if step % 4 == 0 {
                    generator.impactOccurred(intensity: 0.3 + 0.7 * progress)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            let heavy = UIImpactFeedbackGenerator(style: .medium)
            heavy.impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showText = true
            }
        }
    }
}
