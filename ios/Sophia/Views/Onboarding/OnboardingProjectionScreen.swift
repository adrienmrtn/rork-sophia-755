import SwiftUI

struct OnboardingProjectionScreen: View {
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var progressWidth: CGFloat = 0
    @State private var showNumber: Bool = false
    @State private var counterValue: Int = 0

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 32) {
                    BrutalPill(
                        text: "Ta projection",
                        icon: "chart.line.uptrend.xyaxis",
                        background: Color(red: 0.70, green: 0.95, blue: 0.80),
                        foreground: BrutalPalette.ink
                    )
                    .opacity(appeared ? 1 : 0)

                    VStack(spacing: 14) {
                        Text("D'ici la fin de l'année,\ntu auras appris")
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundStyle(BrutalPalette.ink.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(counterValue)")
                                .font(.system(size: 76, weight: .heavy, design: .rounded))
                                .foregroundStyle(BrutalPalette.ink)
                                .contentTransition(.numericText(countsDown: false))
                            Text("sujets")
                                .font(.system(.title, design: .rounded, weight: .heavy))
                                .foregroundStyle(BrutalPalette.ink)
                        }
                        .opacity(appeared ? 1 : 0)

                        Text("en seulement 10 minutes par jour.")
                            .font(.system(.body, design: .rounded, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink)
                            .opacity(showNumber ? 1 : 0)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white)
                                .overlay { Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 2.5) }
                                .frame(height: 16)
                            Capsule()
                                .fill(BrutalPalette.pink)
                                .overlay { Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 2.5) }
                                .frame(width: progressWidth, height: 16)
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                withAnimation(.easeInOut(duration: 2.0)) {
                                    progressWidth = geo.size.width
                                }
                            }
                        }
                    }
                    .frame(height: 16)
                    .padding(.horizontal, 40)
                    .opacity(appeared ? 1 : 0)
                }

                Spacer()

                OnboardingPrimaryButton(title: "C'est parti !", action: onNext)
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
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.5)) {
                showNumber = true
            }
        }
    }
}
