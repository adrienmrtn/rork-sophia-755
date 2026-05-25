import SwiftUI

struct OnboardingLoadingScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared: Bool = true
    @State private var pulsing: Bool = false
    @State private var lastStep: String = ""

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 32) {
                    ZStack {
                        Circle()
                            .fill(BrutalPalette.ink)
                            .frame(width: 130, height: 130)
                            .offset(y: 6)

                        Circle()
                            .fill(BrutalPalette.pink)
                            .frame(width: 120, height: 120)
                            .overlay { Circle().strokeBorder(BrutalPalette.ink, lineWidth: 2.5) }
                            .scaleEffect(pulsing ? 1.05 : 0.95)

                        Image(systemName: "sparkles")
                            .font(.system(size: 44, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink)
                            .symbolEffect(.pulse, isActive: !viewModel.isLoadingComplete)
                    }

                    VStack(spacing: 20) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white)
                                    .overlay { Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 2.5) }
                                    .frame(height: 14)
                                Capsule()
                                    .fill(BrutalPalette.pink)
                                    .overlay { Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 2.5) }
                                    .frame(width: max(0, geo.size.width * viewModel.loadingProgress), height: 14)
                                    .animation(.easeInOut(duration: 0.6), value: viewModel.loadingProgress)
                            }
                        }
                        .frame(height: 14)
                        .padding(.horizontal, 48)

                        Text(viewModel.loadingStep)
                            .font(.system(.body, design: .rounded, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink.opacity(0.65))
                            .contentTransition(.opacity)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.loadingStep)

                        Text("\(Int(viewModel.loadingProgress * 100))%")
                            .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                            .foregroundStyle(BrutalPalette.ink)
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
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        .onChange(of: viewModel.loadingProgress) { _, newProgress in
            if newProgress > 0 && Int(newProgress * 100) % 25 == 0 {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
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
