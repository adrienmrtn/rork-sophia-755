import SwiftUI

struct OnboardingDailyGoalScreen: View {
    @Environment(LanguageManager.self) private var languageManager
    @Bindable var viewModel: OnboardingViewModel
    let onNext: () -> Void
    @State private var appeared: Bool = true
    @State private var pulse: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 48)

                VStack(spacing: 10) {
                    Text(languageManager.text("onboarding.dailyGoal.title"))
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(BrutalPalette.ink)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)

                    Text(languageManager.text("onboarding.dailyGoal.subtitle"))
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(BrutalPalette.ink.opacity(0.58))
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 14)
                }
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 22) {
                    HStack(spacing: 18) {
                        GoalStepperButton(symbol: "minus", isEnabled: viewModel.dailyLearningGoal > viewModel.dailyLearningGoalRange.lowerBound) {
                            updateGoal(by: -1)
                        }

                        Text("\(viewModel.dailyLearningGoal)")
                            .font(.system(size: 72, weight: .heavy, design: .rounded))
                            .foregroundStyle(BrutalPalette.ink)
                            .contentTransition(.numericText())
                            .frame(width: 100, height: 96)
                            .background(Color.white, in: .rect(cornerRadius: 24))
                            .overlay {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .strokeBorder(BrutalPalette.ink, lineWidth: 3)
                            }
                            .shadow(color: BrutalPalette.ink.opacity(0.16), radius: 0, x: 0, y: 4)
                            .scaleEffect(pulse ? 1.04 : 1)

                        GoalStepperButton(symbol: "plus", isEnabled: viewModel.dailyLearningGoal < viewModel.dailyLearningGoalRange.upperBound) {
                            updateGoal(by: 1)
                        }
                    }

                    Text(String(
                        format: languageManager.text("onboarding.dailyGoal.perDay"),
                        "\(viewModel.dailyLearningGoal) \(viewModel.dailyLearningGoalLabel(language: languageManager.current))"
                    ))
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color(red: 1.0, green: 0.78, blue: 0.88), in: .capsule)
                        .overlay { Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 2) }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)
                .animation(.spring(response: 0.5, dampingFraction: 0.78).delay(0.12), value: appeared)

                Spacer()

                OnboardingPrimaryButton(title: languageManager.text("common.continue"), action: onNext)
                    .opacity(appeared ? 1 : 0)
        }
        .onboardingFullBleedBackground(BrutalPalette.cream)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82).delay(0.08)) {
                appeared = true
            }
        }
    }

    private func updateGoal(by delta: Int) {
        OnboardingHaptics.selection()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.62)) {
            viewModel.adjustDailyLearningGoal(by: delta)
            pulse = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                pulse = false
            }
        }
    }
}

private struct GoalStepperButton: View {
    @Environment(LanguageManager.self) private var languageManager
    let symbol: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(isEnabled ? BrutalPalette.ink : BrutalPalette.ink.opacity(0.32))
                .frame(width: 58, height: 58)
                .background(isEnabled ? BrutalPalette.pink : Color(red: 0.93, green: 0.89, blue: 0.86), in: .circle)
                .overlay { Circle().strokeBorder(BrutalPalette.ink, lineWidth: 2.5) }
                .shadow(color: BrutalPalette.ink.opacity(isEnabled ? 0.18 : 0.08), radius: 0, x: 0, y: 3)
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
        .accessibilityLabel(symbol == "plus"
            ? languageManager.text("common.increaseGoal")
            : languageManager.text("common.decreaseGoal"))
    }
}
