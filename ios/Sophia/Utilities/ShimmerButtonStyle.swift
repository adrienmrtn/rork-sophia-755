import SwiftUI

/// Duolingo-style 3D button: solid offset shadow plate behind the colored capsule.
/// Optional shimmer: white gloss band sweeps left to right.
struct DuolingoButtonStyle: ButtonStyle {
    let fill: Color
    let shimmer: CGFloat?
    var depth: CGFloat = 5

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .background(
                Capsule().fill(fill)
                    .overlay {
                        if let shimmer {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.35), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .mask {
                                    GeometryReader { geo in
                                        Rectangle()
                                            .frame(width: 80, height: geo.size.height)
                                            .offset(x: shimmer)
                                    }
                                }
                                .allowsHitTesting(false)
                        }
                    }
                    .overlay { Capsule().strokeBorder(.black, lineWidth: 3) }
            )
            .offset(y: pressed ? depth : 0)
            .background(
                Capsule().fill(Color.black).offset(y: depth)
            )
            .animation(.spring(response: 0.18, dampingFraction: 0.7), value: pressed)
            .padding(.bottom, depth)
    }
}

enum ShimmerAnimation {
    /// Animates shimmer offset from left off-screen to right, then repeats while `isActive` returns true.
    static func runLoop(offset: Binding<CGFloat>, isActive: @escaping () -> Bool) {
        offset.wrappedValue = -100
        withAnimation(.easeInOut(duration: 1.5)) {
            offset.wrappedValue = UIScreen.main.bounds.width + 100
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            guard isActive() else { return }
            runLoop(offset: offset, isActive: isActive)
        }
    }
}
