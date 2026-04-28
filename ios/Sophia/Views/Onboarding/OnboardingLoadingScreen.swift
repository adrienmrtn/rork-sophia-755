import SwiftUI

struct OnboardingLoadingScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var pulsing: Bool = false
    @State private var lastStep: String = ""

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 32) {
                    ZStack {
                        Circle()
                            .fill(SophiaTheme.emerald.opacity(0.08))
                            .frame(width: 120, height: 120)
                            .scaleEffect(pulsing ? 1.15 : 0.95)

                        Circle()
                            .fill(SophiaTheme.emerald.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .scaleEffect(pulsing ? 1.1 : 0.9)

                        Image(systemName: "sparkles")
                            .font(.system(size: 36))
                            .foregroundStyle(SophiaTheme.emerald)
                            .symbolEffect(.pulse, isActive: !viewModel.isLoadingComplete)
                    }

                    VStack(spacing: 20) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.white.opacity(0.1))
                                    .frame(height: 8)
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [SophiaTheme.emerald, SophiaTheme.accent],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * viewModel.loadingProgress, height: 8)
                                    .animation(.easeInOut(duration: 0.6), value: viewModel.loadingProgress)
                            }
                        }
                        .frame(height: 8)
                        .padding(.horizontal, 48)

                        Text(viewModel.loadingStep)
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .contentTransition(.opacity)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.loadingStep)

                        Text("\(Int(viewModel.loadingProgress * 100))%")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(SophiaTheme.emerald)
                            .contentTransition(.numericText(countsDown: false))
                    }
                }

                Spacer()
            }
        }
        .sensoryFeedback(.success, trigger: viewModel.isLoadingComplete)
        .onChange(of: viewModel.loadingStep) { _, newStep in
            if !newStep.isEmpty && newStep != lastStep {
                lastStep = newStep
                let g = UIImpactFeedbackGenerator(style: .light)
                g.impactOccurred()
            }
        }
        .onChange(of: viewModel.loadingProgress) { _, newProgress in
            if newProgress > 0 && Int(newProgress * 100) % 25 == 0 {
                let g = UIImpactFeedbackGenerator(style: .soft)
                g.impactOccurred()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulsing = true
            }
            viewModel.startProfileLoading()
        }
        .onChange(of: viewModel.isLoadingComplete) { _, complete in
            if complete {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onNext()
                }
            }
        }
    }
}
