import SwiftUI

struct OnboardingWastedTimeScreen: View {
    let viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var showIntro: Bool = false
    @State private var showCounter: Bool = false
    @State private var counterValue: Int = 0
    @State private var showDaysMessage: Bool = false
    @State private var showCTA: Bool = false

    private let ink = BrutalPalette.ink
    private let accentNumber = Color.white

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

    private var introSentence: String {
        "\(viewModel.phoneHoursPerDayLabel) par jour sur ton téléphone, c'est"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 32)

            VStack(alignment: .leading, spacing: 16) {
                Text(introSentence)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(ink.opacity(0.9))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(showIntro ? 1 : 0)
                    .offset(y: showIntro ? 0 : 18)

                if showCounter {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(counterValue)")
                            .font(.system(size: 96, weight: .heavy, design: .rounded))
                            .foregroundStyle(accentNumber)
                            .contentTransition(.numericText(countsDown: false))

                        Text("heures perdues par an.")
                            .font(.system(.title2, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink)
                            .lineSpacing(4)
                    }
                    .transition(.opacity.combined(with: .offset(y: 16)))
                }

                if showDaysMessage {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Soit \(viewModel.wastedTimeDays) complets.")
                            .font(.system(.title3, design: .rounded, weight: .heavy))
                            .foregroundStyle(ink)

                        Text("Avec Sophia, transforme ce temps en culture.")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(ink.opacity(0.72))
                            .lineSpacing(3)
                    }
                    .padding(.top, 12)
                    .transition(.opacity.combined(with: .offset(y: 12)))
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            OnboardingPrimaryButton(title: "C'est parti", action: onNext)
                .opacity(showCTA ? 1 : 0)
                .offset(y: showCTA ? 0 : 24)
        }
        .onboardingFullBleedBackground(OnboardingScreenColors.blush)
        .onOnboardingSlideSettled(delay: 0.65) {
            runSequence()
        }
    }

    private func runSequence() {
        withAnimation(.easeOut(duration: 1.2)) {
            showIntro = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.82)) {
                showCounter = true
            }
            animateCounter()
        }
    }

    private func animateCounter() {
        let duration: Double = 3.0
        let steps = 50
        let interval = duration / Double(steps)

        for step in 0...steps {
            let delay = interval * Double(step)
            let progress = Double(step) / Double(steps)
            let eased = 1 - pow(1 - progress, 3)
            let value = Int(eased * Double(targetValue))

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.14)) {
                    counterValue = value
                }
                OnboardingHaptics.counterTick(progress: progress)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.4) {
            OnboardingHaptics.counterComplete()
            withAnimation(.easeOut(duration: 0.9)) {
                showDaysMessage = true
                showCTA = true
            }
        }
    }
}
