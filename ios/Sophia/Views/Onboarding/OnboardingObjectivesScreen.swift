import SwiftUI

struct OnboardingObjectivesScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    @Bindable var viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared: Bool = true

    private let objectives: [(icon: String, key: String)] = [
        ("sparkles", "curious"),
        ("lightbulb.fill", "learnNew"),
        ("star.fill", "impress"),
        ("bubble.left.and.bubble.right.fill", "social"),
        ("arrow.down.circle.fill", "reduceScroll"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)

                OnboardingHeader(
                    title: languageManager.text("onboarding.objectives.title"),
                    subtitle: languageManager.text("onboarding.objectives.subtitle"),
                    appeared: appeared
                )

                Spacer().frame(height: 28)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(Array(objectives.enumerated()), id: \.offset) { i, obj in
                            let isSelected = viewModel.objectives.contains(obj.key)
                            BrutalSelectableRow(
                                icon: obj.icon,
                                label: OnboardingViewModel.objectiveLabel(obj.key, language: languageManager.current),
                                isSelected: isSelected,
                                accentColor: OnboardingPastels.at(i)
                            ) {
                                OnboardingHaptics.selection()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.toggleObjective(obj.key)
                                }
                            }
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 15)
                            .animation(.spring(response: 0.5).delay(Double(i) * 0.06), value: appeared)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
                .scrollIndicators(.hidden)

                OnboardingPrimaryButton(title: languageManager.text("common.next"), isEnabled: viewModel.canProceed, action: onNext)
                    .opacity(appeared ? 1 : 0)
        }
        .onboardingFullBleedBackground(BrutalPalette.cream)
        .sensoryFeedback(.selection, trigger: viewModel.objectives.count)
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.1)) {
                appeared = true
            }
        }
    }
}
