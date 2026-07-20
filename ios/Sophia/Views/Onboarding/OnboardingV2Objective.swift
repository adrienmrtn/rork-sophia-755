import SwiftUI

/// Page 3 — objectif principal. Choix unique, avance automatiquement au clic (pas de CTA).
struct OnboardingV2Objective: View {
    @Environment(LanguageManager.self) private var languageManager
    let vm: OnboardingV2ViewModel
    let onNext: () -> Void

    @State private var revealed = 0
    @State private var picked: String?

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 72)

            Text(languageManager.text("onboardingV2.objective.title"))
                .font(DS.title(.title, .heavy))
                .foregroundStyle(OV2.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .ov2Reveal(delay: 0.1)

            Spacer().frame(height: 28)

            VStack(spacing: 12) {
                ForEach(Array(OnboardingV2ViewModel.objectiveKeys.enumerated()), id: \.element) { index, key in
                    objectiveRow(key)
                        .opacity(index < revealed ? 1 : 0)
                        .offset(y: index < revealed ? 0 : 18)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
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
        let isPicked = picked == key
        return Button {
            guard picked == nil else { return }
            picked = key
            vm.objectiveKey = key
            OnboardingHaptics.selection()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                onNext()
            }
        } label: {
            HStack(spacing: 14) {
                Text(OnboardingV2ViewModel.objectiveEmoji(key))
                    .font(.system(size: 24))
                    .frame(width: 44, height: 44)
                    .background(OV2.accentSoft.opacity(0.12), in: Circle())
                Text(OnboardingV2ViewModel.objectiveLabel(key, language: languageManager.current))
                    .font(DS.sans(.body, .semibold))
                    .foregroundStyle(OV2.ink)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(OV2.inkTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .fill(OV2.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .strokeBorder(isPicked ? OV2.accent : OV2.hairline, lineWidth: isPicked ? 2 : 1)
            )
        }
        .buttonStyle(SoftPressButtonStyle())
    }
}
