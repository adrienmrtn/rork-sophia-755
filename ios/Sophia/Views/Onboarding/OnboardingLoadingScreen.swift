import SwiftUI

struct OnboardingLoadingScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var hasStartedLoading: Bool = false
    @State private var pulse: Bool = false
    @State private var firedHapticSteps: Set<Int> = []

    private let steps = [
        "Analyse de tes réponses",
        "Sélection de tes 3 matières",
        "Préparation de ton parcours",
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .stroke(BrutalPalette.ink.opacity(0.08), lineWidth: 10)
                        .frame(width: 112, height: 112)

                    Circle()
                        .trim(from: 0, to: overallProgress)
                        .stroke(
                            BrutalPalette.pink,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 112, height: 112)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.45), value: overallProgress)

                    Image("logo_white")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .padding(18)
                        .background(BrutalPalette.pink, in: Circle())
                        .overlay { Circle().strokeBorder(BrutalPalette.ink, lineWidth: 2.5) }
                        .scaleEffect(pulse ? 1.04 : 1.0)
                }

                VStack(spacing: 10) {
                    Text("On prépare ton parcours")
                        .font(.system(.title, design: .rounded, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                        .multilineTextAlignment(.center)

                    Text("Quelques secondes, promis.")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(BrutalPalette.ink.opacity(0.55))
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)

            Spacer().frame(height: 44)

            VStack(spacing: 14) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, label in
                    loadingStepRow(
                        label: label,
                        progress: stepProgress(at: index),
                        index: index
                    )
                }
            }
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)

            Spacer()
        }
        .onboardingFullBleedBackground(Color(red: 0.99, green: 0.97, blue: 0.95))
        .onOnboardingSlideSettled {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                guard !hasStartedLoading else { return }
                hasStartedLoading = true
                viewModel.startProfileLoading()
            }
        }
        .onChange(of: viewModel.loadingBarProgress) { _, bars in
            for (index, progress) in bars.enumerated() {
                if progress >= 1.0, !firedHapticSteps.contains(index) {
                    firedHapticSteps.insert(index)
                    OnboardingHaptics.loadingStepComplete(step: index)
                }
            }
        }
        .onChange(of: viewModel.isLoadingComplete) { _, complete in
            if complete {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    onNext()
                }
            }
        }
    }

    private var overallProgress: CGFloat {
        let bars = viewModel.loadingBarProgress
        guard !bars.isEmpty else { return 0.08 }
        let total = bars.reduce(0.0, +) / Double(bars.count)
        return CGFloat(max(0.08, min(1.0, total)))
    }

    private func stepProgress(at index: Int) -> Double {
        guard viewModel.loadingBarProgress.indices.contains(index) else { return 0 }
        return viewModel.loadingBarProgress[index]
    }

    private func loadingStepRow(label: String, progress: Double, index: Int) -> some View {
        let complete = progress >= 1.0
        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(complete ? BrutalPalette.pink : Color.white)
                    .frame(width: 34, height: 34)
                    .overlay { Circle().strokeBorder(BrutalPalette.ink, lineWidth: 2) }
                if complete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                } else {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(BrutalPalette.ink.opacity(0.45))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink.opacity(complete ? 1 : 0.65))

                Capsule()
                    .fill(Color.white)
                    .frame(height: 8)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(BrutalPalette.pink)
                            .frame(maxWidth: .infinity)
                            .scaleEffect(x: max(0.04, progress), y: 1, anchor: .leading)
                            .animation(.easeInOut(duration: 0.45), value: progress)
                    }
                    .overlay { Capsule().strokeBorder(BrutalPalette.ink.opacity(0.15), lineWidth: 1) }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(BrutalPalette.ink.opacity(0.12), lineWidth: 1.5)
        }
    }
}
