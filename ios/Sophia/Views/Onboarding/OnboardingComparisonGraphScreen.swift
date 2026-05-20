import SwiftUI

struct OnboardingComparisonGraphScreen: View {
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var graphProgress: CGFloat = 0
    @State private var showLabels: Bool = false
    @State private var hapticTick: Int = 0

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    VStack(spacing: 10) {
                        Text("Ta progression culturelle")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(SophiaTheme.textPrimary)
                            .opacity(appeared ? 1 : 0)

                        Text("Avec et sans Sophia")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Color.black.opacity(0.5))
                            .opacity(appeared ? 1 : 0)
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                            )

                        VStack(spacing: 0) {
                            HStack {
                                Text("Culture")
                                    .font(.system(.caption, design: .rounded, weight: .medium))
                                    .foregroundStyle(Color.black.opacity(0.3))
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                            GeometryReader { geo in
                                let w = geo.size.width - 40
                                let h = geo.size.height - 20

                                ZStack(alignment: .bottomLeading) {
                                    ForEach(0..<5) { i in
                                        Path { path in
                                            let y = h - (h * CGFloat(i) / 4)
                                            path.move(to: CGPoint(x: 20, y: y))
                                            path.addLine(to: CGPoint(x: 20 + w, y: y))
                                        }
                                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                                    }

                                    ComparisonCurve(progress: graphProgress, isWithSophia: false)
                                        .trim(from: 0, to: graphProgress)
                                        .stroke(
                                            Color.black.opacity(0.25),
                                            style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 4])
                                        )
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 10)

                                    ComparisonCurve(progress: graphProgress, isWithSophia: true)
                                        .trim(from: 0, to: graphProgress)
                                        .stroke(
                                            LinearGradient(
                                                colors: [SophiaTheme.emerald, SophiaTheme.emerald.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                        )
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 10)
                                        .shadow(color: SophiaTheme.emerald.opacity(0.4), radius: 8, y: 2)

                                    if showLabels {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Avec Sophia")
                                                .font(.system(.caption, design: .rounded, weight: .bold))
                                                .foregroundStyle(SophiaTheme.emerald)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 4)
                                                .background(SophiaTheme.emerald.opacity(0.15), in: .capsule)
                                        }
                                        .position(x: 20 + w * 0.75, y: h * 0.15)
                                        .transition(.opacity.combined(with: .scale(scale: 0.8)))

                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Sans Sophia")
                                                .font(.system(.caption, design: .rounded, weight: .bold))
                                                .foregroundStyle(Color.black.opacity(0.4))
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 4)
                                                .background(Color.black.opacity(0.06), in: .capsule)
                                        }
                                        .position(x: 20 + w * 0.75, y: h * 0.65)
                                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                                    }
                                }
                            }

                            HStack {
                                Text("Aujourd'hui")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(Color.black.opacity(0.3))
                                Spacer()
                                Text("1 an")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(Color.black.opacity(0.3))
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)
                        }
                    }
                    .frame(height: 260)
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)

                    Text("Sophia accélère ta culture\ngénérale de manière exponentielle.")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .opacity(showLabels ? 1 : 0)
                        .offset(y: showLabels ? 0 : 10)
                }

                Spacer()

                OnboardingButton(title: "Continuer", action: onNext)
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
