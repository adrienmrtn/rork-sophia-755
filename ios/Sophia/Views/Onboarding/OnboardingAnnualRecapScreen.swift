import SwiftUI

struct OnboardingAnnualRecapScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var counterValue: Int = 0
    @State private var showText: Bool = false

    private var annualCourses: Int {
        max(1, viewModel.dailyLearningGoal) * 365
    }

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 26) {
                    VStack(spacing: 8) {
                        Text("Ça fait")
                            .font(.system(.title3, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(counterValue)")
                                .font(.system(size: 64, weight: .heavy, design: .rounded))
                                .foregroundStyle(SophiaTheme.emerald)
                                .contentTransition(.numericText(countsDown: false))
                            Text("cours")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(.white.opacity(0.75))
                        }

                        Text("par an.")
                            .font(.system(.title3, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .opacity(appeared ? 1 : 0)

                    if showText {
                        Text("Pas mal non ? Si tu tiens l'habitude, toute ta culture sera changée !")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                            .transition(.opacity.combined(with: .offset(y: 10)))
                    }
                }

                Spacer()

                OnboardingButton(title: "C'est parti !", action: onNext)
                    .opacity(showText ? 1 : 0)
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
        let duration: Double = 1.5
        let steps = 30
        let interval = duration / Double(steps)

        for step in 0...steps {
            let delay = 0.5 + interval * Double(step)
            let progress = Double(step) / Double(steps)
            let eased = 1 - pow(1 - progress, 3)
            let value = Int(eased * Double(annualCourses))

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.snappy(duration: 0.08)) {
                    counterValue = value
                }
                if step % 4 == 0 {
                    generator.impactOccurred(intensity: 0.3 + 0.7 * progress)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            let heavy = UIImpactFeedbackGenerator(style: .medium)
            heavy.impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                showText = true
            }
        }
    }
}