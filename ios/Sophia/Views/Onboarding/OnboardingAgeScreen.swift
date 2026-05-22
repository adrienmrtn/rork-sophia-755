import SwiftUI

struct OnboardingAgeScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared: Bool = false

    private let ageRanges = [
        "Moins de 24 ans",
        "25 - 34 ans",
        "35 - 44 ans",
        "45 - 54 ans",
        "55 ans et plus",
    ]

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                OnboardingHeader(
                    title: "Tu as quel âge ?",
                    subtitle: "Ça nous aide à personnaliser tes cours.",
                    appeared: appeared
                )

                Spacer().frame(height: 32)

                VStack(spacing: 10) {
                    ForEach(Array(ageRanges.enumerated()), id: \.offset) { i, range in
                        let isSelected = viewModel.ageRange == range
                        BrutalSelectableRow(
                            icon: nil,
                            label: range,
                            isSelected: isSelected,
                            accentColor: OnboardingPastels.at(i)
                        ) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.ageRange = range
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 15)
                        .animation(.spring(response: 0.5).delay(Double(i) * 0.06), value: appeared)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                OnboardingPrimaryButton(title: "Suivant", isEnabled: viewModel.canProceed, action: onNext)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .sensoryFeedback(.selection, trigger: viewModel.ageRange)
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.1)) {
                appeared = true
            }
        }
    }
}
