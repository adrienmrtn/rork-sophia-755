import SwiftUI

struct OnboardingPhoneTimeScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared: Bool = true

    private let options = [
        (icon: "clock", label: "Moins de 1h", index: 0),
        (icon: "clock.badge.checkmark", label: "1h à 2h", index: 1),
        (icon: "clock.badge.exclamationmark", label: "2h à 4h", index: 2),
        (icon: "clock.badge.xmark", label: "Plus de 4h", index: 3),
    ]

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                OnboardingHeader(
                    title: "Combien de temps\nsur ton téléphone ?",
                    subtitle: "Chaque jour, en moyenne.",
                    appeared: appeared
                )

                Spacer().frame(height: 32)

                VStack(spacing: 10) {
                    ForEach(Array(options.enumerated()), id: \.offset) { i, option in
                        let isSelected = viewModel.phoneTimeSelection == option.index
                        BrutalSelectableRow(
                            icon: option.icon,
                            label: option.label,
                            isSelected: isSelected,
                            accentColor: OnboardingPastels.at(i)
                        ) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                viewModel.phoneTimeSelection = option.index
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.5).delay(Double(i) * 0.08), value: appeared)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                OnboardingPrimaryButton(title: "Suivant", isEnabled: viewModel.canProceed, action: onNext)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .sensoryFeedback(.selection, trigger: viewModel.phoneTimeSelection)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.15)) {
                appeared = true
            }
        }
    }
}
