import SwiftUI

struct OnboardingProjectionScreen: View {
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var progressWidth: CGFloat = 0
    @State private var showNumber: Bool = false
    @State private var counterValue: Int = 0

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 36) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundStyle(SophiaTheme.emerald)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.5)
                        .symbolEffect(.bounce, value: showNumber)

                    VStack(spacing: 16) {
                        Text("D'ici la fin de l'année,\ntu auras appris")
                            .font(.system(.title3, design: .rounded, weight: .medium))
                            .foregroundStyle(Color.black.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(counterValue)")
                                .font(.system(size: 60, weight: .heavy, design: .rounded))
                                .foregroundStyle(SophiaTheme.emerald)
                                .contentTransition(.numericText(countsDown: false))
                            Text("sujets")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(Color.black.opacity(0.7))
                        }
                        .opacity(appeared ? 1 : 0)

                        Text("en seulement 10 minutes par jour.")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(SophiaTheme.streakOrange)
                            .opacity(showNumber ? 1 : 0)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.black.opacity(0.1))
                                .frame(height: 10)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [SophiaTheme.emerald, SophiaTheme.streakOrange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: progressWidth, height: 10)
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                withAnimation(.easeInOut(duration: 2.0)) {
                                    progressWidth = geo.size.width
                                }
                            }
                        }
                    }
                    .frame(height: 10)
                    .padding(.horizontal, 40)
                    .opacity(appeared ? 1 : 0)
                }

                Spacer()

                OnboardingButton(title: "C'est parti !", action: {
                    onNext()
                })
                .opacity(showNumber ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.2)) {
                appeared = true
            }
            animateCounter()
        }
    }

    private func animateCounter() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        let steps = 35
        let interval = 2.0 / Double(steps)

        for step in 0...steps {
            let delay = 0.8 + interval * Double(step)
            let progress = Double(step) / Double(steps)
            let eased = 1 - pow(1 - progress, 3)
            let value = Int(eased * 365)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.snappy(duration: 0.08)) {
                    counterValue = value
                }
                if step % 4 == 0 {
                    generator.impactOccurred(intensity: 0.3 + 0.7 * progress)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            let heavy = UIImpactFeedbackGenerator(style: .medium)
            heavy.impactOccurred()
            withAnimation(.spring(response: 0.5)) {
                showNumber = true
            }
        }
    }
}
