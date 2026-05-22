import SwiftUI

struct OnboardingComparisonGraphScreen: View {
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var graphProgress: CGFloat = 0
    @State private var showLabels: Bool = false
    @State private var hapticTick: Int = 0

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    VStack(spacing: 10) {
                        Text("Ta progression\nculturelle")
                            .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink)
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)

                        Text("Avec et sans Sophia")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(BrutalPalette.ink.opacity(0.55))
                            .opacity(appeared ? 1 : 0)
                    }

                    ZStack {
                        VStack(spacing: 0) {
                            HStack {
                                Text("CULTURE")
                                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                                    .tracking(1.0)
                                    .foregroundStyle(BrutalPalette.ink.opacity(0.5))
                                Spacer()
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 14)

                            GeometryReader { geo in
                                let w = geo.size.width - 36
                                let h = geo.size.height - 14

                                ZStack(alignment: .bottomLeading) {
                                    ForEach(0..<5) { i in
                                        Path { path in
                                            let y = h - (h * CGFloat(i) / 4)
                                            path.move(to: CGPoint(x: 18, y: y))
                                            path.addLine(to: CGPoint(x: 18 + w, y: y))
                                        }
                                        .stroke(BrutalPalette.ink.opacity(0.1), lineWidth: 1)
                                    }

                                    ComparisonCurve(progress: graphProgress, isWithSophia: false)
                                        .trim(from: 0, to: graphProgress)
                                        .stroke(
                                            BrutalPalette.ink.opacity(0.35),
                                            style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [6, 5])
                                        )
                                        .padding(.horizontal, 18)
                                        .padding(.bottom, 8)

                                    ComparisonCurve(progress: graphProgress, isWithSophia: true)
                                        .trim(from: 0, to: graphProgress)
                                        .stroke(
                                            BrutalPalette.pink,
                                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                        )
                                        .padding(.horizontal, 18)
                                        .padding(.bottom, 8)

                                    if showLabels {
                                        BrutalPill(
                                            text: "Avec Sophia",
                                            background: BrutalPalette.pink,
                                            foreground: BrutalPalette.ink
                                        )
                                        .position(x: 18 + w * 0.72, y: h * 0.18)
                                        .transition(.opacity.combined(with: .scale(scale: 0.8)))

                                        BrutalPill(
                                            text: "Sans Sophia",
                                            background: Color.white,
                                            foreground: BrutalPalette.ink
                                        )
                                        .position(x: 18 + w * 0.72, y: h * 0.62)
                                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                                    }
                                }
                            }

                            HStack {
                                Text("Aujourd'hui")
                                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                                    .foregroundStyle(BrutalPalette.ink.opacity(0.5))
                                Spacer()
                                Text("1 an")
                                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                                    .foregroundStyle(BrutalPalette.ink.opacity(0.5))
                            }
                            .padding(.horizontal, 18)
                            .padding(.bottom, 12)
                        }
                    }
                    .frame(height: 260)
                    .brutalOnboardingCard()
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)

                    Text("Sophia accélère ta culture\nde manière exponentielle.")
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .opacity(showLabels ? 1 : 0)
                        .offset(y: showLabels ? 0 : 10)
                }

                Spacer()

                OnboardingPrimaryButton(title: "Continuer", action: onNext)
                    .opacity(showLabels ? 1 : 0)
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTick)
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.2)) {
                appeared = true
            }
            animateGraph()
        }
    }

    private func animateGraph() {
        let steps = 40
        let duration = 2.0
        let interval = duration / Double(steps)

        for step in 0...steps {
            let delay = 0.6 + interval * Double(step)
            let progress = Double(step) / Double(steps)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: interval * 1.5)) {
                    graphProgress = progress
                }
                if step % 4 == 0 {
                    hapticTick += 1
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showLabels = true
            }
        }
    }
}

struct ComparisonCurve: Shape {
    let progress: CGFloat
    let isWithSophia: Bool

    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        let steps = 50

        for i in 0...steps {
            let x = rect.width * CGFloat(i) / CGFloat(steps)
            let t = CGFloat(i) / CGFloat(steps)

            let y: CGFloat
            if isWithSophia {
                let curve = pow(t, 1.8)
                y = rect.height - (rect.height * 0.85 * curve) - rect.height * 0.05
            } else {
                let curve = t * 0.15 + sin(t * .pi * 2) * 0.03
                y = rect.height - (rect.height * curve) - rect.height * 0.05
            }

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}
