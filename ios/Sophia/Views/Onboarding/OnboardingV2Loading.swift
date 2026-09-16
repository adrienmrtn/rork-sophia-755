import SwiftUI

/// Page 9 — préparation du profil en 3 étapes (satisfaisant), note App Store, CTA « voir mon profil ».
struct OnboardingV2Loading: View {
    @Environment(LanguageManager.self) private var languageManager
    let onNext: () -> Void

    @State private var progress: [Double] = [0, 0, 0]
    @State private var completed: [Bool] = [false, false, false]
    @State private var allDone = false
    @State private var animTask: Task<Void, Never>?

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
        .onAppear { startLoading() }
        .onDisappear { animTask?.cancel() }
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

    /// Les trois étapes sont une mise en scène (aucun réseau, aucune dépendance) : le CTA
    /// doit donc **toujours** finir par s'activer. C'est la page que l'App Store décrirait
    /// comme « indefinite loading » si elle restait bloquée, alors elle reprend là où elle
    /// s'était arrêtée quand la page réapparaît, et l'interruption elle-même débloque le CTA.
    private func startLoading() {
        guard !allDone else { return }
        animTask?.cancel()
        animTask = Task { @MainActor in
            await playSteps()
            withAnimation(.easeInOut(duration: 0.3)) { allDone = true }
        }
    }

    private func playSteps() async {
        for i in 0..<3 where !completed[i] {
            withAnimation(.easeInOut(duration: 1.0)) { progress[i] = 1.0 }
            try? await Task.sleep(nanoseconds: 1_050_000_000)
            if Task.isCancelled { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { completed[i] = true }
            OnboardingHaptics.loadingStepComplete(step: i)
        }
    }
}
