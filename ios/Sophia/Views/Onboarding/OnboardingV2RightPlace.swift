import SwiftUI

/// Page 4 — « You're at the right place » : graphe animé doucement montrant qu'une large
/// majorité d'utilisateurs avec le même objectif progressent avec Sophia.
struct OnboardingV2RightPlace: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var progress: CGFloat = 0
    @State private var shownPercent: Int = 0

    private var targetPercent: Int {
        OnboardingV2ViewModel.objectiveStatPercent(vm.objectiveKey)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 84)

            Text(languageManager.text("onboardingV2.rightPlace.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .ov2Reveal(delay: 0.1)

            Spacer()

            ZStack {
                Circle()
                    .stroke(OV2.accent.opacity(0.12), lineWidth: 18)
                    .frame(width: 200, height: 200)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(OV2.accent, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(shownPercent)%")
                        .font(DS.title(.largeTitle, .heavy))
                        .foregroundStyle(OV2.ink)
                        .contentTransition(.numericText())
                    Text(languageManager.text("onboardingV2.rightPlace.ofUsers"))
                        .font(DS.sans(.caption, .semibold))
                        .foregroundStyle(OV2.inkSecondary)
                }
            }

            Spacer().frame(height: 28)

            Text(languageManager.text("onboardingV2.rightPlace.caption"))
                .font(DS.sans(.subheadline, .medium))
                .foregroundStyle(OV2.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .ov2Reveal(delay: 0.5)

            Spacer()

            OnboardingV2Button(title: languageManager.text("common.continue"), action: onNext)
        }
        .ov2Background()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.3).delay(0.35)) {
                progress = CGFloat(targetPercent) / 100.0
            }
            animatePercent()
        }
    }

    private func animatePercent() {
        let steps = max(1, targetPercent)
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35 + Double(i) * (1.3 / Double(steps))) {
                withAnimation(.easeOut(duration: 0.1)) {
                    shownPercent = i
                }
                if i % 12 == 0 { OnboardingHaptics.selection() }
            }
        }
    }
}
