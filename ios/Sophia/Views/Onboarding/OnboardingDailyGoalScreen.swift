import SwiftUI

struct OnboardingDailyGoalScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared: Bool = false
    @State private var tapCount: Int = 0

    private let minGoal = 1
    private let maxGoal = 10

    var body: some View {
        ZStack {
            SophiaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 26) {
                    VStack(spacing: 10) {
                        Text("Chaque jour, tu veux apprendre...")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 18)

                        Text("Tu pourras modifier ton objectif plus tard.")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 18)
                    }
                    .padding(.horizontal, 24)

                    VStack(spacing: 14) {
                        HStack(spacing: 18) {
                            stepButton(systemName: "minus", isEnabled: viewModel.dailyLearningGoal > minGoal) {
                                tapCount += 1
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    viewModel.dailyLearningGoal = max(minGoal, viewModel.dailyLearningGoal - 1)
                                }
                            }

                            Text("\(viewModel.dailyLearningGoal)")
                                .font(.system(size: 64, weight: .heavy, design: .rounded))
                                .foregroundStyle(SophiaTheme.emerald)
                                .contentTransition(.numericText(countsDown: false))
                                .frame(minWidth: 84)

                            stepButton(systemName: "plus", isEnabled: viewModel.dailyLearningGoal < maxGoal) {
                                tapCount += 1
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    viewModel.dailyLearningGoal = min(maxGoal, viewModel.dailyLearningGoal + 1)
                                }
                            }
                        }

                        Text("apprentissage(s) par jour !")
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 22)
                    .frame(maxWidth: .infinity)
                    .background(.white.opacity(0.05), in: .rect(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 18)
                }

                Spacer()

                OnboardingButton(title: "C'est parti !", action: onNext)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
            }
        }
        .sensoryFeedback(.selection, trigger: tapCount)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.15)) {
                appeared = true
            }
        }
    }

    private func stepButton(systemName: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(isEnabled ? .white : .white.opacity(0.25))
                .frame(width: 46, height: 46)
                .background(.white.opacity(isEnabled ? 0.08 : 0.04), in: .circle)
                .overlay(
                    Circle()
                        .strokeBorder(.white.opacity(isEnabled ? 0.14 : 0.06), lineWidth: 1)
                )
        }
        .disabled(!isEnabled)
    }
}
