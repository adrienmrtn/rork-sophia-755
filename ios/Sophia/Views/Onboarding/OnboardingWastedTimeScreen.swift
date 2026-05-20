import SwiftUI

struct OnboardingWastedTimeScreen: View {
    let viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var counterValue: Int = 0
    @State private var showMessage: Bool = false

    private var targetValue: Int {
        guard let sel = viewModel.phoneTimeSelection else { return 0 }
        switch sel {
        case 0: return 182
        case 1: return 547
        case 2: return 1095
        case 3: return 2190
        default: return 0
        }
    }

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 48))
                        .foregroundStyle(SophiaTheme.streakOrange)
                        .symbolEffect(.wiggle, value: appeared)
                        .opacity(appeared ? 1 : 0)

                    VStack(spacing: 8) {
                        Text("C'est")
                            .font(.system(.title3, design: .rounded, weight: .medium))
                            .foregroundStyle(Color.black.opacity(0.6))

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(counterValue)")
                                .font(.system(size: 64, weight: .heavy, design: .rounded))
                                .foregroundStyle(SophiaTheme.streakOrange)
                                .contentTransition(.numericText(countsDown: false))
                            Text("heures")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(Color.black.opacity(0.7))
                        }

                        Text("perdues par an.")
                            .font(.system(.title3, design: .rounded, weight: .medium))
                            .foregroundStyle(Color.black.opacity(0.6))
                    }
                    .opacity(appeared ? 1 : 0)

                    if showMessage {
                        VStack(spacing: 6) {
                            Text("Soit " + viewModel.wastedTimeDays + " complets.")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(SophiaTheme.textPrimary)

                            Text("Avec Sophia, fais un bon usage de ton temps.")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(SophiaTheme.emerald)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .offset(y: 10)))
                    }
                }

                Spacer()

                OnboardingButton(title: "Continuer", action: onNext)
                    .opacity(showMessage ? 1 : 0)
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
        let duration: Double = 1.8
        let steps = 40
        let interval = duration / Double(steps)

        for step in 0...steps {
            let delay = 0.6 + interval * Double(step)
            let progress = Double(step) / Double(steps)
            let eased = 1 - pow(1 - progress, 3)
            let value = Int(eased * Double(targetValue))

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.snappy(duration: 0.1)) {
                    counterValue = value
                }
                if step % 5 == 0 {
                    generator.impactOccurred(intensity: 0.4 + 0.6 * progress)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            let heavy = UIImpactFeedbackGenerator(style: .heavy)
            heavy.impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showMessage = true
            }
        }
    }
}
