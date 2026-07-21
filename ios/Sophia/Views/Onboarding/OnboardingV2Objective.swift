import SwiftUI

/// Page objectifs — sélection **multiple**, puis CTA « Continuer ».
struct OnboardingV2Objective: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var revealed = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 72)

            VStack(spacing: 8) {
                Text(languageManager.text("onboardingV2.objective.title"))
                    .font(DS.title(.title, .heavy))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.center)
                Text(languageManager.text("onboardingV2.objective.subtitle"))
                    .font(DS.sans(.subheadline, .medium))
                    .foregroundStyle(OV2.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
            .ov2Reveal(delay: 0.1)

            Spacer().frame(height: 24)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(Array(OnboardingV2ViewModel.objectiveKeys.enumerated()), id: \.element) { index, key in
                        objectiveRow(key)
                            .opacity(index < revealed ? 1 : 0)
                            .offset(y: index < revealed ? 0 : 18)
                    }
                }
                .padding(.horizontal, 24)
            }

            OnboardingV2Button(
                title: languageManager.text("common.continue"),
                enabled: !vm.objectiveKeys.isEmpty,
                action: onNext
            )
        }
        .ov2Background()
        .onAppear {
            for i in 0..<OnboardingV2ViewModel.objectiveKeys.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 + Double(i) * 0.07) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        revealed = i + 1
                    }
                }
            }
        }
    }

    private func objectiveRow(_ key: String) -> some View {
        let isSelected = vm.isSelected(key)
        return Button {
            OnboardingHaptics.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                vm.toggleObjective(key)
            }
        } label: {
            HStack(spacing: 14) {
                Text(OnboardingV2ViewModel.objectiveEmoji(key))
                    .font(.system(size: 24))
                    .frame(width: 44, height: 44)
                    .background((isSelected ? OV2.accent : OV2.accentSoft).opacity(isSelected ? 0.16 : 0.12), in: Circle())
                Text(OnboardingV2ViewModel.objectiveLabel(key, language: languageManager.current))
                    .font(DS.sans(.body, .semibold))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                checkbox(isSelected)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .fill(isSelected ? OV2.accentSoft.opacity(0.06) : OV2.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .strokeBorder(isSelected ? OV2.accent : OV2.hairline, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(SoftPressButtonStyle())
    }

    private func checkbox(_ isSelected: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(isSelected ? OV2.accent : OV2.hairline, lineWidth: 2)
                .frame(width: 24, height: 24)
            if isSelected {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(OV2.accent)
                    .frame(width: 24, height: 24)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}
