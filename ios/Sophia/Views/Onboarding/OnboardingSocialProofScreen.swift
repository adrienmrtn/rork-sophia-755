import SwiftUI

struct OnboardingSocialProofScreen: View {
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var peopleValue: Int = 0
    @State private var expertsValue: Int = 0
    @State private var showText: Bool = false

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 18) {
                    VStack(spacing: 12) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(peopleValue)")
                                .font(.system(size: 46, weight: .heavy, design: .rounded))
                                .foregroundStyle(SophiaTheme.emerald)
                                .contentTransition(.numericText(countsDown: false))
                            Text("personnes")
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .foregroundStyle(.white.opacity(0.75))
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(expertsValue)")
                                .font(.system(size: 46, weight: .heavy, design: .rounded))
                                .foregroundStyle(SophiaTheme.emerald)
                                .contentTransition(.numericText(countsDown: false))
                            Text("experts")
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }
                    .padding(18)
                    .background(.white.opacity(0.05), in: .rect(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)

                    if showText {
                        Text("Cette semaine, \(peopleValue) personnes ont compris ce qu’était un trou noir et \(expertsValue) sont devenus des experts de la Guerre Froide.")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 26)
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
            animateCounts()
        }
    }

    private func animateCounts() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        let steps = 34
        let interval = 1.3 / Double(steps)

        for step in 0...steps {
            let delay = 0.4 + interval * Double(step)
            let progress = Double(step) / Double(steps)
            let eased = 1 - pow(1 - progress, 3)
            let people = Int(eased * 12_847)
            let experts = Int(eased * 8_092)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.snappy(duration: 0.08)) {
                    peopleValue = people
                    expertsValue = experts
                }
                if step % 4 == 0 {
                    generator.impactOccurred(intensity: 0.3 + 0.7 * progress)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let heavy = UIImpactFeedbackGenerator(style: .medium)
            heavy.impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showText = true
            }
        }
    }
}
