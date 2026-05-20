import SwiftUI

struct OnboardingPhoneTimeScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared: Bool = false

    private let options = [
        (icon: "clock", label: "Moins de 1h", index: 0),
        (icon: "clock.badge.checkmark", label: "1h à 2h", index: 1),
        (icon: "clock.badge.exclamationmark", label: "2h à 4h", index: 2),
        (icon: "clock.badge.xmark", label: "Plus de 4h", index: 3),
    ]

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Image(systemName: "iphone")
                            .font(.system(size: 44))
                            .foregroundStyle(SophiaTheme.accent)
                            .opacity(appeared ? 1 : 0)
                            .scaleEffect(appeared ? 1 : 0.5)

                        Text("Combien de temps par jour\npasses-tu sur ton téléphone ?")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 15)
                    }

                    VStack(spacing: 12) {
                        ForEach(Array(options.enumerated()), id: \.offset) { i, option in
                            let isSelected = viewModel.phoneTimeSelection == option.index
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    viewModel.phoneTimeSelection = option.index
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: option.icon)
                                        .font(.title3)
                                        .foregroundStyle(isSelected ? SophiaTheme.emerald : .white.opacity(0.5))
                                        .frame(width: 32)
                                    Text(option.label)
                                        .font(.system(.body, design: .rounded, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(SophiaTheme.emerald)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .padding(16)
                                .background(
                                    isSelected ? SophiaTheme.emerald.opacity(0.12) : .white.opacity(0.05),
                                    in: .rect(cornerRadius: 14)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(isSelected ? SophiaTheme.emerald.opacity(0.5) : .clear, lineWidth: 1.5)
                                )
                            }
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                            .animation(.spring(response: 0.5).delay(Double(i) * 0.08), value: appeared)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                OnboardingButton(title: "Suivant", isEnabled: viewModel.canProceed, action: onNext)
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
