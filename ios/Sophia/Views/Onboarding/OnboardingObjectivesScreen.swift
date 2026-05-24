import SwiftUI

struct OnboardingObjectivesScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared: Bool = true

    private let objectives: [(icon: String, label: String)] = [
        ("sparkles", "Être plus curieux"),
        ("lightbulb.fill", "Apprendre de nouvelles choses"),
        ("star.fill", "Impressionner tes proches"),
        ("bubble.left.and.bubble.right.fill", "Renforcer ton aisance en société"),
        ("arrow.down.circle.fill", "Réduire ton temps à scroller"),
    ]

    var body: some View {
        ZStack {
            BrutalPalette.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                OnboardingHeader(
                    title: "Ton objectif\navec Sophia ?",
                    subtitle: "Sélectionne un ou plusieurs objectifs.",
                    appeared: appeared
                )

                Spacer().frame(height: 28)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(Array(objectives.enumerated()), id: \.offset) { i, obj in
                            let isSelected = viewModel.objectives.contains(obj.label)
                            BrutalSelectableRow(
                                icon: obj.icon,
                                label: obj.label,
                                isSelected: isSelected,
                                accentColor: OnboardingPastels.at(i)
                            ) {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.toggleObjective(obj.label)
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

                OnboardingPrimaryButton(title: "Suivant", isEnabled: viewModel.canProceed, action: onNext)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .sensoryFeedback(.selection, trigger: viewModel.objectives.count)
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.1)) {
                appeared = true
            }
        }
    }
}
