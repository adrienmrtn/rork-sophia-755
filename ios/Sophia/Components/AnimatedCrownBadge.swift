import SwiftUI

/// Compact animated crown for the Home discount badge.
struct AnimatedCrownBadge: View {
    var size: CGFloat = 14

    @State private var scale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.35

    private let gold = Color(red: 1.0, green: 0.82, blue: 0.22)
    private let amber = Color(red: 1.0, green: 0.65, blue: 0.12)

    var body: some View {
        ZStack {
            Circle()
                .fill(gold.opacity(glowOpacity))
                .frame(width: size * 1.7, height: size * 1.7)
                .blur(radius: size * 0.15)

            Image(systemName: "crown.fill")
                .font(.jakarta(size: size, weight: .heavy))
                .foregroundStyle(
                    LinearGradient(
                        colors: [amber, gold, .white.opacity(0.95)],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )
                .symbolEffect(.variableColor.iterative.reversing)
                .shadow(color: amber.opacity(0.45), radius: size * 0.1, y: size * 0.05)
                .scaleEffect(scale)
        }
        .frame(width: size * 1.4, height: size * 1.4)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                scale = 1.1
                glowOpacity = 0.65
            }
        }
    }
}
