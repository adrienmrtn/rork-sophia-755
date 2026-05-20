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
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 44))
                            .foregroundStyle(SophiaTheme.accent)
                            .opacity(appeared ? 1 : 0)
                            .scaleEffect(appeared ? 1 : 0.5)

                        Text("Tu as quel âge ?")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(SophiaTheme.textPrimary)
                            .opacity(appeared ? 1 : 0)
                    }

                    VStack(spacing: 10) {
                        ForEach(Array(ageRanges.enumerated()), id: \.offset) { i, range in
                            let isSelected = viewModel.ageRange == range
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.ageRange = range
                                }
                            } label: {
                                HStack {
                                    Text(range)
                                        .font(.system(.body, design: .rounded, weight: .semibold))
                                        .foregroundStyle(SophiaTheme.textPrimary)
                                    Spacer()
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(SophiaTheme.emerald)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .padding(16)
                                .background(
                                    isSelected ? SophiaTheme.emerald.opacity(0.12) : Color.black.opacity(0.05),
                                    in: .rect(cornerRadius: 14)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(isSelected ? SophiaTheme.emerald.opacity(0.5) : .clear, lineWidth: 1.5)
                                )
                            }
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 15)
                            .animation(.spring(response: 0.5).delay(Double(i) * 0.06), value: appeared)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                OnboardingButton(title: "Suivant", isEnabled: viewModel.canProceed, action: onNext)
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
