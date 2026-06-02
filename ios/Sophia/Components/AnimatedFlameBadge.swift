import SwiftUI

/// Compact animated flame for badges (Home streak, discount, Profile hero).
struct AnimatedFlameBadge: View {
    var size: CGFloat = 24
    var showGlow: Bool = true

    @State private var flameScale: CGFloat = 1.0
    @State private var flameRotation: Double = 0

    private let orange = Color(red: 1.0, green: 0.55, blue: 0.18)
    private let yellow = Color(red: 1.0, green: 0.84, blue: 0.35)

    var body: some View {
        ZStack {
            if showGlow {
                Circle()
                    .fill(yellow.opacity(0.45))
                    .frame(width: size * 1.6, height: size * 1.6)
                    .blur(radius: size * 0.2)
            }

            Image(systemName: "flame.fill")
                .font(.system(size: size, weight: .heavy))
                .foregroundStyle(
                    LinearGradient(
                        colors: [orange, yellow],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .symbolEffect(.variableColor.iterative.reversing)
                .shadow(color: orange.opacity(0.35), radius: size * 0.12, y: size * 0.06)
                .scaleEffect(flameScale)
                .rotationEffect(.degrees(flameRotation))
        }
        .frame(width: size * 1.4, height: size * 1.4)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                flameScale = 1.08
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                flameRotation = 4
            }
        }
    }
}
