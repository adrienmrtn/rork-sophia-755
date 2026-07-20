import SwiftUI

struct OnboardingProjectionScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    @Bindable var viewModel: OnboardingViewModel
    let onNext: () -> Void

    private let ink = BrutalPalette.ink
    private let lineFont = Font.jakarta(size: 34, weight: .regular, design: .rounded)
    private let lineFontBold = Font.jakarta(size: 34, weight: .heavy, design: .rounded)
    private let numberFont = Font.jakarta(size: 68, weight: .heavy, design: .rounded)

    @State private var counterValue: Int = 0
    @State private var isRaining: Bool = false
    @State private var showCTA: Bool = false
    @State private var counterStarted: Bool = false

    var body: some View {
        ZStack {
            CourseCardRainOverlay(isActive: isRaining)
                .zIndex(0)

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 2) {
                    Text(languageManager.text("onboarding.projection.line1"))
                        .font(lineFont)
                        .foregroundStyle(ink)

                    Text(languageManager.text("onboarding.projection.line2"))
                        .font(lineFontBold)
                        .foregroundStyle(ink)

                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(languageManager.text("onboarding.projection.its"))
                            .font(lineFont)
                            .foregroundStyle(ink)

                        Text("\(counterValue)")
                            .font(numberFont)
                            .foregroundStyle(.white)
                            .contentTransition(.numericText(countsDown: false))
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                    .padding(.top, 4)

                    Text(languageManager.text("onboarding.projection.newThings"))
                        .font(lineFont)
                        .foregroundStyle(ink)
                        .padding(.top, 2)

                    Text(languageManager.text("onboarding.projection.inOneYear"))
                        .font(lineFontBold)
                        .foregroundStyle(ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .zIndex(1)

                Spacer(minLength: 0)

                OnboardingPrimaryButton(title: languageManager.text("common.continue"), action: onNext)
                    .opacity(showCTA ? 1 : 0)
                    .offset(y: showCTA ? 0 : 24)
                    .zIndex(1)
            }
        }
        .onboardingFullBleedBackground(OnboardingScreenColors.projectionPink)
        .onOnboardingSlideSettled(delay: 0.5) {
            guard !counterStarted else { return }
            counterStarted = true
            isRaining = true
            animateCounter()
        }
        .onDisappear {
            isRaining = false
        }
    }

    private func animateCounter() {
        let steps = 42
        let duration: Double = 2.8
        let interval = duration / Double(steps)
        let target = viewModel.projectedYearlyLearnings

        for step in 0...steps {
            let delay = interval * Double(step)
            let progress = Double(step) / Double(steps)
            let eased = 1 - pow(1 - progress, 3)
            let value = Int(eased * Double(target))

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.12)) {
                    counterValue = value
                }
                OnboardingHaptics.counterTick(progress: progress)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.35) {
            isRaining = false
            OnboardingHaptics.counterComplete()
            withAnimation(.easeOut(duration: 0.75)) {
                showCTA = true
            }
        }
    }
}
