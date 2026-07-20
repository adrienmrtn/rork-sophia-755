import SwiftUI

struct OnboardingLoadingScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    @Bindable var viewModel: OnboardingViewModel
    let onNext: () -> Void

    @State private var appeared = false
    @State private var hasStartedLoading = false
    @State private var pulse = false
    @State private var glowPulse = false
    @State private var ringSpin = false
    @State private var firedHapticSteps: Set<Int> = []
    @State private var displayedPercent = 0
    @State private var completedFlash = false

    private let ink = BrutalPalette.ink
    private let pink = BrutalPalette.pink
    private let gold = BrutalPalette.yellow

    private var steps: [String] {
        [
            languageManager.text("onboarding.loading.step1"),
            languageManager.text("onboarding.loading.step2"),
            languageManager.text("onboarding.loading.step3"),
        ]
    }

    var body: some View {
        ZStack {
            backdrop

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                medallion
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.7)

                Spacer().frame(height: 30)

                VStack(spacing: 8) {
                    Text(languageManager.text("onboarding.loading.title"))
                        .font(.jakarta(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(ink)
                        .multilineTextAlignment(.center)

                    Text(languageManager.text("onboarding.loading.subtitle"))
                        .font(.jakarta(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

                Spacer().frame(height: 34)

                VStack(spacing: 0) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, label in
                        stepRow(label: label, index: index, isLast: index == steps.count - 1)
                    }
                }
                .padding(20)
                .brutalOnboardingCard(depth: 6, corner: 26)
                .padding(.horizontal, 26)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)

                Spacer(minLength: 24)
            }
        }
        .onOnboardingSlideSettled {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulse = true
                glowPulse = true
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                ringSpin = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                guard !hasStartedLoading else { return }
                hasStartedLoading = true
                viewModel.startProfileLoading()
            }
        }
        .onChange(of: viewModel.loadingBarProgress) { _, bars in
            let target = Int((bars.reduce(0.0, +) / Double(max(bars.count, 1))) * 100)
            if target > displayedPercent {
                withAnimation(.easeOut(duration: 0.3)) { displayedPercent = target }
            }
            for (index, progress) in bars.enumerated() where progress >= 1.0 && !firedHapticSteps.contains(index) {
                firedHapticSteps.insert(index)
                OnboardingHaptics.loadingStepComplete(step: index)
            }
        }
        .onChange(of: viewModel.isLoadingComplete) { _, complete in
            guard complete else { return }
            withAnimation(.easeOut(duration: 0.3)) { displayedPercent = 100 }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { completedFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { onNext() }
        }
    }

    // MARK: - Backdrop

    private var backdrop: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            RadialGradient(
                colors: [gold.opacity(glowPulse ? 0.35 : 0.22), .clear],
                center: .init(x: 0.5, y: 0.32),
                startRadius: 20,
                endRadius: 320
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Medallion (logo + progress ring)

    private var medallion: some View {
        ZStack {
            // Soft glow halo.
            Circle()
                .fill(pink.opacity(glowPulse ? 0.22 : 0.1))
                .frame(width: 210, height: 210)
                .blur(radius: 20)
                .scaleEffect(glowPulse ? 1.06 : 0.94)

            // Track ring.
            Circle()
                .stroke(ink.opacity(0.08), lineWidth: 14)
                .frame(width: 168, height: 168)

            // Progress ring with gradient + rounded tip.
            Circle()
                .trim(from: 0, to: overallProgress)
                .stroke(
                    AngularGradient(
                        colors: [pink, gold, pink],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 168, height: 168)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.45), value: overallProgress)

            // Rotating sparkle orbiting the ring.
            Image(systemName: "sparkle")
                .font(.jakarta(size: 16, weight: .black))
                .foregroundStyle(gold)
                .offset(y: -84)
                .rotationEffect(.degrees(ringSpin ? 360 : 0))
                .opacity(0.9)

            // Center medallion: logo card.
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 120, height: 120)
                    .overlay { Circle().strokeBorder(ink, lineWidth: 3) }
                    .background(alignment: .center) {
                        Circle().fill(ink).frame(width: 120, height: 120).offset(y: 5)
                    }

                Image("sophia_mark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 68, height: 68)
                    .scaleEffect(pulse ? 1.06 : 0.98)
                    .scaleEffect(completedFlash ? 1.15 : 1)
            }

            // Live percentage pill.
            Text("\(displayedPercent)%")
                .font(.jakarta(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(ink)
                .monospacedDigit()
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(gold, in: Capsule())
                .overlay { Capsule().strokeBorder(ink, lineWidth: 2) }
                .offset(y: 96)
                .scaleEffect(completedFlash ? 1.12 : 1)
        }
        .frame(height: 220)
    }

    // MARK: - Steps

    private func stepRow(label: String, index: Int, isLast: Bool) -> some View {
        let progress = stepProgress(at: index)
        let complete = progress >= 1.0
        let active = progress > 0.02 && !complete

        return VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(complete ? pink : (active ? gold.opacity(0.35) : Color.white))
                        .frame(width: 38, height: 38)
                        .overlay { Circle().strokeBorder(ink, lineWidth: 2.5) }

                    if complete {
                        Image(systemName: "checkmark")
                            .font(.jakarta(size: 15, weight: .black))
                            .foregroundStyle(ink)
                            .transition(.scale.combined(with: .opacity))
                    } else if active {
                        Text("\(Int(progress * 100))")
                            .font(.jakarta(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(ink.opacity(0.75))
                            .monospacedDigit()
                    } else {
                        Circle()
                            .fill(ink.opacity(0.18))
                            .frame(width: 8, height: 8)
                    }
                }
                .scaleEffect(complete ? 1.05 : 1)
                .animation(.spring(response: 0.35, dampingFraction: 0.55), value: complete)

                VStack(alignment: .leading, spacing: 7) {
                    Text(label)
                        .font(.jakarta(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(ink.opacity(complete ? 1 : (active ? 0.85 : 0.45)))

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(ink.opacity(0.08))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [pink, gold],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geo.size.width * progress))
                                .animation(.easeOut(duration: 0.4), value: progress)
                        }
                    }
                    .frame(height: 7)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)

            if !isLast {
                HStack {
                    Rectangle()
                        .fill(ink.opacity(0.1))
                        .frame(width: 2.5, height: 14)
                        .padding(.leading, 18)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Progress helpers

    private var overallProgress: CGFloat {
        let bars = viewModel.loadingBarProgress
        guard !bars.isEmpty else { return 0.04 }
        let total = bars.reduce(0.0, +) / Double(bars.count)
        return CGFloat(max(0.04, min(1.0, total)))
    }

    private func stepProgress(at index: Int) -> Double {
        guard viewModel.loadingBarProgress.indices.contains(index) else { return 0 }
        return viewModel.loadingBarProgress[index]
    }
}
