import SwiftUI

struct OnboardingButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void
    @State private var tapCount: Int = 0

    var body: some View {
        Button {
            tapCount += 1
            let g = UIImpactFeedbackGenerator(style: .medium)
            g.impactOccurred()
            action()
        } label: {
            HStack(spacing: 10) {
                Text(title)
                    .font(.jakarta(.headline, design: .rounded, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                isEnabled ? SophiaTheme.emerald : SophiaTheme.emerald.opacity(0.3),
                in: .rect(cornerRadius: 16)
            )
        }
        .disabled(!isEnabled)
        .padding(.horizontal, 24)
        .padding(.bottom, 50)
        .sensoryFeedback(.impact(weight: .medium), trigger: tapCount)
    }
}
