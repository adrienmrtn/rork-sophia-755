import SwiftUI

struct SwipeTutorialOverlay: View {
    @Environment(LanguageManager.self) private var languageManager

    let onDismiss: () -> Void

    @State private var appeared: Bool = false
    @State private var handOffset: CGFloat = 0
    @State private var tapCount: Int = 0

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.5 : 0)
                .ignoresSafeArea()
                .onTapGesture(perform: dismiss)

            card
                .padding(.horizontal, 32)
                .scaleEffect(appeared ? 1 : 0.92)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: tapCount)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.1)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
            startHandAnimation()
        }
    }

    private var card: some View {
        VStack(spacing: 24) {
            swipeGestureDemo

            VStack(spacing: 8) {
                Text(languageManager.text("home.swipe.title"))
                    .font(DS.title(.title2, .semibold))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.center)

                Text(languageManager.text("home.swipe.subtitle"))
                    .font(DS.sans(.subheadline))
                    .foregroundStyle(DS.inkSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: dismiss) {
                Text(languageManager.text("common.letsGo"))
            }
            .buttonStyle(DSPrimaryButtonStyle())
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
        .background(DS.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
        .dsSoftShadow()
    }

    private var swipeGestureDemo: some View {
        HStack(spacing: 24) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(handOffset < -8 ? DS.accent : DS.hairline)

            ZStack {
                Circle().fill(DS.accentTint)
                Image(systemName: "hand.draw.fill")
                    .font(.system(size: 34, weight: .regular))
                    .foregroundStyle(DS.accent)
                    .offset(x: handOffset * 0.35)
            }
            .frame(width: 72, height: 72)

            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(handOffset > 8 ? DS.accent : DS.hairline)
        }
        .frame(height: 72)
    }

    private func dismiss() {
        tapCount += 1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onDismiss()
    }

    private func startHandAnimation() {
        withAnimation(.easeInOut(duration: 0.75).delay(0.4)) {
            handOffset = -56
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
            withAnimation(.easeInOut(duration: 0.75)) {
                handOffset = 56
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            withAnimation(.easeInOut(duration: 0.55)) {
                handOffset = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            startHandAnimation()
        }
    }
}
