import SwiftUI

struct OnboardingLoadingScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    @Bindable var viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var hasStartedLoading: Bool = false
    @State private var pulse: Bool = false
    @State private var glow: Bool = false
    @State private var firedHapticSteps: Set<Int> = []
    @State private var displayedPercent: Int = 0

    private var steps: [String] {
        [
            languageManager.text("onboarding.loading.step1"),
            languageManager.text("onboarding.loading.step2"),
            languageManager.text("onboarding.loading.step3"),
        ]
    }

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    BrutalPalette.pink.opacity(0.22),
                    Color(red: 0.99, green: 0.97, blue: 0.95),
                    BrutalPalette.cream,
                ],
                center: .top,
                startRadius: 40,
                endRadius: 420
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(BrutalPalette.pink.opacity(glow ? 0.18 : 0.08))
                            .frame(width: 148, height: 148)
                            .blur(radius: 8)
                            .scaleEffect(glow ? 1.08 : 0.92)
                            .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: glow)

                        Circle()
                            .stroke(BrutalPalette.ink.opacity(0.08), lineWidth: 10)
                            .frame(width: 124, height: 124)

                        Circle()
                            .trim(from: 0, to: overallProgress)
                            .stroke(
                                AngularGradient(
                                    colors: [BrutalPalette.pink, BrutalPalette.yellow, BrutalPalette.pink],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .frame(width: 124, height: 124)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 0.4), value: overallProgress)

                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 88, height: 88)
                                .overlay { Circle().strokeBorder(BrutalPalette.ink.opacity(0.12), lineWidth: 2) }

                            Image("sophia_mark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 52, height: 52)
                                .scaleEffect(pulse ? 1.05 : 1.0)
                        }

                        Text("\(displayedPercent)%")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(BrutalPalette.ink.opacity(0.55))
                            .offset(y: 74)
                    }

                    VStack(spacing: 10) {
                        Text(languageManager.text("onboarding.loading.title"))
                            .font(.system(.title2, design: .rounded, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink)
                            .multilineTextAlignment(.center)

                        Text(languageManager.text("onboarding.loading.subtitle"))
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(BrutalPalette.ink.opacity(0.55))
                            .multilineTextAlignment(.center)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)

                Spacer().frame(height: 40)

                VStack(spacing: 12) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, label in
                        loadingStepRow(
                            label: label,
                            progress: stepProgress(at: index),
                            index: index
                        )
                    }
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)

                Spacer()
            }
        }
        .onOnboardingSlideSettled {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
            glow = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                guard !hasStartedLoading else { return }
                hasStartedLoading = true
                viewModel.startProfileLoading()
            }
        }
        .onChange(of: viewModel.loadingBarProgress) { _, bars in
            let target = Int((bars.reduce(0.0, +) / Double(max(bars.count, 1))) * 100)
            if target > displayedPercent {
                withAnimation(.easeOut(duration: 0.25)) {
                    displayedPercent = target
                }
            }

            for (index, progress) in bars.enumerated() {
                if progress >= 1.0, !firedHapticSteps.contains(index) {
                    firedHapticSteps.insert(index)
                    OnboardingHaptics.loadingStepComplete(step: index)
                }
            }
        }
        .onChange(of: viewModel.isLoadingComplete) { _, complete in
            if complete {
                withAnimation(.easeOut(duration: 0.3)) {
                    displayedPercent = 100
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    onNext()
                }
            }
        }
    }

    private var overallProgress: CGFloat {
        let bars = viewModel.loadingBarProgress
        guard !bars.isEmpty else { return 0.06 }
        let total = bars.reduce(0.0, +) / Double(bars.count)
        return CGFloat(max(0.06, min(1.0, total)))
    }

    private func stepProgress(at index: Int) -> Double {
        guard viewModel.loadingBarProgress.indices.contains(index) else { return 0 }
        return viewModel.loadingBarProgress[index]
    }

    private func loadingStepRow(label: String, progress: Double, index: Int) -> some View {
        let complete = progress >= 1.0
        let active = progress > 0.04 && !complete
        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(complete ? BrutalPalette.pink : Color.white)
                    .frame(width: 36, height: 36)
                    .overlay { Circle().strokeBorder(BrutalPalette.ink, lineWidth: 2) }
                if complete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                        .transition(.scale.combined(with: .opacity))
                } else if active {
                    Text("\(Int(progress * 100))")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(BrutalPalette.ink.opacity(0.7))
                        .monospacedDigit()
                } else {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink.opacity(0.25))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink.opacity(complete ? 1 : (active ? 0.85 : 0.55)))

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white)
                            .overlay { Capsule().strokeBorder(BrutalPalette.ink.opacity(0.12), lineWidth: 1) }

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [BrutalPalette.pink, BrutalPalette.yellow.opacity(0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(6, geo.size.width * progress))
                            .animation(.easeOut(duration: 0.35), value: progress)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(active || complete ? 0.9 : 0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(BrutalPalette.ink.opacity(active || complete ? 0.22 : 0.12), lineWidth: 1.5)
        }
        .scaleEffect(active ? 1.01 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: active)
    }
}
