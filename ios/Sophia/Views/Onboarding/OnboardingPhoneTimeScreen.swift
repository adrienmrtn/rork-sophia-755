import SwiftUI

struct OnboardingPhoneTimeScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    @Bindable var viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared: Bool = true

    private var options: [(icon: String, labelKey: String, index: Int)] {
        [
            (icon: "clock", labelKey: "onboarding.phone.lessThan1h", index: 0),
            (icon: "clock.badge.checkmark", labelKey: "onboarding.phone.1to2h", index: 1),
            (icon: "clock.badge.exclamationmark", labelKey: "onboarding.phone.2to4h", index: 2),
            (icon: "clock.badge.xmark", labelKey: "onboarding.phone.moreThan4h", index: 3),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)

                OnboardingHeader(
                    title: languageManager.text("onboarding.phone.title"),
                    subtitle: languageManager.text("onboarding.phone.subtitle"),
                    appeared: appeared
                )

                Spacer().frame(height: 32)

                VStack(spacing: 10) {
                    ForEach(Array(options.enumerated()), id: \.offset) { i, option in
                        let isSelected = viewModel.phoneTimeSelection == option.index
                        BrutalSelectableRow(
                            icon: option.icon,
                            label: languageManager.text(option.labelKey),
                            isSelected: isSelected,
                            accentColor: OnboardingPastels.at(i)
                        ) {
                            OnboardingHaptics.selection()
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

                OnboardingPrimaryButton(title: languageManager.text("common.continue"), isEnabled: viewModel.canProceed, action: onNext)
                    .opacity(appeared ? 1 : 0)
        }
        .onboardingFullBleedBackground(BrutalPalette.cream)
        .sensoryFeedback(.selection, trigger: viewModel.phoneTimeSelection)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.15)) {
                appeared = true
            }
        }
    }
}
