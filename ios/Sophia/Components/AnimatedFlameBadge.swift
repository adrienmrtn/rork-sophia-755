import SwiftUI

/// Compact animated flame for badges (Home streak, discount, Profile hero) : la flamme
/// safran du style « Elevate arrondi » (même teinte que `DSFlame`), un halo discret et un
/// battement vif. Pour la grande flamme de l'écran de série, voir `DSFlame`.
struct AnimatedFlameBadge: View {
    var size: CGFloat = 24
    var showGlow: Bool = true
    /// `false` : la flamme garde ses couleurs mais ne bouge pas (l'en-tête de l'accueil).
    var animated: Bool = true

    @State private var flameScale: CGFloat = 1.0
    @State private var flameRotation: Double = 0

    // Les trois tons du dégradé, du pied au sommet. Les noms datent de l'ancienne flamme
    // rose ; ils portent désormais le safran du style (#E6B233) et ses voisins.
    static let pink = Color(red: 0.851, green: 0.596, blue: 0.118)
    static let orange = Color(red: 0.902, green: 0.698, blue: 0.200)
    static let yellow = Color(red: 0.969, green: 0.843, blue: 0.455)

    var body: some View {
        ZStack {
            if showGlow {
                Circle()
                    .fill(Self.orange.opacity(0.28))
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
                .symbolEffect(.variableColor.iterative.reversing, isActive: animated)
                .scaleEffect(flameScale)
                .rotationEffect(.degrees(flameRotation))
        }
        .frame(width: size * 1.4, height: size * 1.4)
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                flameScale = 1.12
            }
            withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                flameRotation = 5
            }
        }
    }
}
