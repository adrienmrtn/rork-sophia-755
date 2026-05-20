import SwiftUI

struct SwipeTutorialOverlay: View {
    let onDismiss: () -> Void
    @State private var appeared: Bool = false
    @State private var handOffset: CGFloat = 0
    @State private var handOpacity: Double = 1
    @State private var tapCount: Int = 0

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.6 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    tapCount += 1
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onDismiss()
                }

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(SophiaTheme.textPrimary)
                        .offset(x: handOffset)
                        .opacity(handOpacity)
                }

                VStack(spacing: 10) {
                    Text("Swipe pour explorer")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(SophiaTheme.textPrimary)

                    Text("Glisse a gauche ou a droite\npour decouvrir de nouveaux cours")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                Button {
                    tapCount += 1
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onDismiss()
                } label: {
                    Text("Compris !")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 14)
                        .background(SophiaTheme.emerald, in: .capsule)
                }

                Spacer()
                    .frame(height: 120)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: tapCount)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
            startHandAnimation()
        }
    }

    private func startHandAnimation() {
        withAnimation(.easeInOut(duration: 0.8).delay(0.5)) {
            handOffset = -60
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.8)) {
                handOffset = 60
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.6)) {
                handOffset = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            startHandAnimation()
        }
    }
}
