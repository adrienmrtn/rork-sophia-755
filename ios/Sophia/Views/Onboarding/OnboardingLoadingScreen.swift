import SwiftUI

struct OnboardingLoadingScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onNext: () -> Void

    @State private var bar1Progress: CGFloat = 0
    @State private var bar2Progress: CGFloat = 0
    @State private var bar3Progress: CGFloat = 0
    @State private var bar1Shimmer: CGFloat = -1
    @State private var bar2Shimmer: CGFloat = -1
    @State private var bar3Shimmer: CGFloat = -1
    @State private var pulsing: Bool = false
    @State private var didTriggerTransition: Bool = false

    private let barDuration: Double = 1.2
    private let barDelay: Double = 0.15

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Sophia icon
                    ZStack {
                        Circle()
                            .fill(BrutalPalette.ink)
                            .frame(width: 100, height: 100)
                            .offset(y: 5)

                        Circle()
                            .fill(BrutalPalette.pink)
                            .frame(width: 92, height: 92)
                            .overlay { Circle().strokeBorder(BrutalPalette.ink, lineWidth: 2.5) }
                            .scaleEffect(pulsing ? 1.06 : 0.94)

                        Image(systemName: "sparkles")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink)
                            .symbolEffect(.pulse, isActive: !didTriggerTransition)
                    }
                    .padding(.bottom, 48)

                    // 3 cascade bars
                    VStack(alignment: .leading, spacing: 24) {
                        loadingBarRow(
                            progress: bar1Progress,
                            shimmerOffset: bar1Shimmer,
                            label: "Analyse de tes objectifs",
                            isComplete: bar1Progress >= 1.0
                        )

                        loadingBarRow(
                            progress: bar2Progress,
                            shimmerOffset: bar2Shimmer,
                            label: "Selection des sujets",
                            isComplete: bar2Progress >= 1.0
                        )

                        loadingBarRow(
                            progress: bar3Progress,
                            shimmerOffset: bar3Shimmer,
                            label: "Personnalisation du contenu",
                            isComplete: bar3Progress >= 1.0
                        )
                    }
                    .padding(.horizontal, 40)

                    // Subtitle
                    if didTriggerTransition {
                        Text("Ton profil est pret !")
                            .font(.system(.body, design: .rounded, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink.opacity(0.6))
                            .padding(.top, 32)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                }

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulsing = true
            }
            startCascadeAnimation()
            startShimmerLoops()
        }
    }

    // MARK: - Bar Row

    private func loadingBarRow(progress: CGFloat, shimmerOffset: CGFloat, label: String, isComplete: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .foregroundStyle(BrutalPalette.ink.opacity(isComplete ? 0.7 : 0.45))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.white)
                        .overlay { Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 2) }

                    // Filled portion
                    Capsule()
                        .fill(BrutalPalette.pink)
                        .overlay { Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 2) }
                        .frame(width: max(0, geo.size.width * progress))

                    // Shimmer overlay
                    if progress > 0 && progress < 1.0 {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0),
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * 0.35)
                            .offset(x: geo.size.width * shimmerOffset)
                            .blendMode(.overlay)
                    }
                }
            }
            .frame(height: 12)
        }
    }

    // MARK: - Cascade animation

    private func startCascadeAnimation() {
        // Bar 1: fills first
        withAnimation(.easeInOut(duration: barDuration)) {
            bar1Progress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + barDuration) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        // Bar 2: starts after bar 1 + delay
        DispatchQueue.main.asyncAfter(deadline: .now() + barDuration + barDelay) {
            withAnimation(.easeInOut(duration: barDuration)) {
                bar2Progress = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + barDuration) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }

        // Bar 3: starts after bar 2 + delay, triggers transition when done
        DispatchQueue.main.asyncAfter(deadline: .now() + (barDuration + barDelay) * 2) {
            withAnimation(.easeInOut(duration: barDuration)) {
                bar3Progress = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + barDuration) {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                triggerTransition()
            }
        }
    }

    private func startShimmerLoops() {
        // Bar 1 shimmer starts immediately
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: false)) {
            bar1Shimmer = 0.7
        }

        // Bar 2 shimmer starts after bar 1 finishes + delay
        DispatchQueue.main.asyncAfter(deadline: .now() + barDuration + barDelay) {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: false)) {
                bar2Shimmer = 0.7
            }
        }

        // Bar 3 shimmer starts after bar 2 finishes + delay
        DispatchQueue.main.asyncAfter(deadline: .now() + (barDuration + barDelay) * 2) {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: false)) {
                bar3Shimmer = 0.7
            }
        }
    }

    private func triggerTransition() {
        guard !didTriggerTransition else { return }
        didTriggerTransition = true

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            // subtitle appears via the didTriggerTransition flag
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onNext()
        }
    }
}
