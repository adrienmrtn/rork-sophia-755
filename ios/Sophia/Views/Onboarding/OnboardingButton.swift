import SwiftUI

/// CTA de l'ancien onboarding (V1), gardé pour compatibilité : même signature, habillé comme
/// le CTA « Elevate arrondi » (rectangle arrondi 16 pt bleu, pression élastique, une seule
/// vibration à l'action).
struct OnboardingButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.confirm()
            action()
        } label: {
            HStack(spacing: 10) {
                Text(title)
                    .font(DS.sans(.callout, .semibold))
                    .tracking(0.4)
                Image(systemName: "arrow.forward")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .fill(isEnabled ? DS.accent : DS.accent.opacity(0.35))
            )
        }
        .buttonStyle(PressableStyle(scale: 0.96, haptic: false))
        .disabled(!isEnabled)
        .padding(.horizontal, 24)
        .padding(.bottom, 50)
    }
}
