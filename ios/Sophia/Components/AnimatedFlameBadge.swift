import SwiftUI

/// Compact animated flame for badges (Home streak, discount, Profile hero) : un dégradé
/// rose → orange → jaune, un halo rose, et un battement vif.
struct AnimatedFlameBadge: View {
    var size: CGFloat = 24
    var showGlow: Bool = true

    @State private var flameScale: CGFloat = 1.0
    @State private var flameRotation: Double = 0

    static let pink = Color(red: 0.96, green: 0.30, blue: 0.56)
    static let orange = Color(red: 1.0, green: 0.55, blue: 0.18)
    static let yellow = Color(red: 1.0, green: 0.84, blue: 0.35)

    var body: some View {
        ZStack {
            if showGlow {
                Circle()
                    .fill(Self.pink.opacity(0.35))
                    .frame(width: size * 1.7, height: size * 1.7)
                    .blur(radius: size * 0.22)
            }

            Image(systemName: "flame.fill")
                .font(.jakarta(size: size, weight: .heavy))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Self.pink, Self.orange, Self.yellow],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .symbolEffect(.variableColor.iterative.reversing)
                .shadow(color: Self.pink.opacity(0.35), radius: size * 0.14, y: size * 0.06)
                .scaleEffect(flameScale)
                .rotationEffect(.degrees(flameRotation))
        }
        .frame(width: size * 1.4, height: size * 1.4)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                flameScale = 1.12
            }
            withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                flameRotation = 5
            }
        }
    }
}
