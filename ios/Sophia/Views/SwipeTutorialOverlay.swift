import SwiftUI

struct SwipeTutorialOverlay: View {
    @Environment(LanguageManager.self) private var languageManager

    let onDismiss: () -> Void

    @State private var appeared: Bool = false
    @State private var handOffset: CGFloat = 0
    @State private var tapCount: Int = 0

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.62 : 0)
                .ignoresSafeArea()
                .onTapGesture(perform: dismiss)

            VStack(spacing: 28) {
                Spacer()

                swipeGestureDemo

                VStack(spacing: 12) {
                    Text(languageManager.text("home.swipe.title"))
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(languageManager.text("home.swipe.subtitle"))
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .padding(.horizontal, 32)

                Button(action: dismiss) {
                    Text(languageManager.text("common.letsGo"))
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(BrutalPalette.ink)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                }
                .buttonStyle(SwipeTutorialButtonStyle())

                Spacer()
                    .frame(height: 120)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: tapCount)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
            startHandAnimation()
        }
    }

    private var swipeGestureDemo: some View {
        HStack(spacing: 28) {
            Image(systemName: "chevron.left")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(handOffset < -8 ? 0.95 : 0.35))

            Image(systemName: "hand.draw.fill")
                .font(.system(size: 52))
                .foregroundStyle(.white)
                .offset(x: handOffset)
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)

            Image(systemName: "chevron.right")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(handOffset > 8 ? 0.95 : 0.35))
        }
        .frame(height: 64)
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

private struct SwipeTutorialButtonStyle: ButtonStyle {
    private let depth: CGFloat = 5

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .offset(y: pressed ? depth : 0)
            .background(
                ZStack(alignment: .top) {
                    Capsule()
                        .fill(BrutalPalette.ink)
                        .offset(y: depth)
                    Capsule()
                        .fill(BrutalPalette.pink)
                        .overlay {
                            Capsule().strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
                        }
                        .offset(y: pressed ? depth : 0)
                }
            )
            .padding(.bottom, depth)
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: pressed)
    }
}
