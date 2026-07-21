import SwiftUI

/// Page 9 — préparation du profil en 3 étapes (satisfaisant), note App Store, CTA « voir mon profil ».
struct OnboardingV2Loading: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var progress: [Double] = [0, 0, 0]
    @State private var completed: [Bool] = [false, false, false]
    @State private var allDone = false

    private var stepKeys: [String] {
        ["onboardingV2.loading.step1", "onboardingV2.loading.step2", "onboardingV2.loading.step3"]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 84)

            Text(languageManager.text("onboardingV2.loading.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .ov2Reveal(delay: 0.05)

            Spacer().frame(height: 40)

            VStack(spacing: 22) {
                ForEach(0..<3, id: \.self) { i in
                    stepRow(i)
                }
            }
            .padding(.horizontal, 32)

            Spacer().frame(height: 32)

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text("4.8/5")
                        .font(DS.title(.headline, .heavy))
                        .foregroundStyle(OV2.ink)
                    HStack(spacing: 3) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill").font(.system(size: 13)).foregroundStyle(OV2.warm)
                        }
                    }
                }
                Text(languageManager.text("onboardingV2.loading.reviews"))
                    .font(DS.sans(.caption, .semibold))
                    .foregroundStyle(OV2.inkSecondary)
            }
            .opacity(allDone ? 1 : 0.4)

            Spacer()

            OnboardingV2Button(
                title: languageManager.text("onboardingV2.loading.cta"),
                enabled: allDone,
                action: onNext
            )
        }
        .ov2Background()
        .onAppear { runLoading() }
    }

    private func stepRow(_ i: Int) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(completed[i] ? OV2.success : OV2.accent.opacity(0.12)).frame(width: 34, height: 34)
                if completed[i] {
                    Image(systemName: "checkmark").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    ProgressView().tint(OV2.accent)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(languageManager.text(stepKeys[i]))
                    .font(DS.sans(.subheadline, .semibold))
                    .foregroundStyle(OV2.ink)
                ProgressView(value: progress[i])
                    .tint(OV2.accent)
            }
        }
    }

    private func runLoading() {
        for i in 0..<3 {
            let start = Double(i) * 1.1
            withAnimation(.easeInOut(duration: 1.0).delay(start)) {
                progress[i] = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + start + 1.05) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { completed[i] = true }
                OnboardingHaptics.loadingStepComplete(step: i)
                if i == 2 {
                    withAnimation(.easeInOut(duration: 0.3)) { allDone = true }
                }
            }
        }
    }
}
