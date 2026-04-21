import SwiftUI

struct FloatingCardInfo {
    let title: String
    let courseId: String
    let rotation: Double
    let xRatio: CGFloat
    let yRatio: CGFloat
    var scale: CGFloat = 1.0
}

struct FloatingCardsBackground: View {
    let dismissing: Bool
    var cards: [FloatingCardInfo] = [
        FloatingCardInfo(title: "Pourquoi la glace flotte ?", courseId: "course_43_pourquoi_la_glace_flotte_t_elle", rotation: -8, xRatio: 0.25, yRatio: 0.15, scale: 1.25),
        FloatingCardInfo(title: "La guerre de Sécession", courseId: "course_40_la_guerre_de_secession_americaine_1861_1", rotation: 6, xRatio: 0.72, yRatio: 0.25, scale: 0.95),
        FloatingCardInfo(title: "La persistance de la mémoire", courseId: "course_157_la_persistance_de_la_memoire_dali", rotation: -3, xRatio: 0.45, yRatio: 0.60, scale: 1.15),
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(Array(cards.enumerated()), id: \.offset) { i, card in
                FloatingCardItem(
                    title: card.title,
                    courseId: card.courseId,
                    rotation: card.rotation,
                    position: CGPoint(
                        x: geo.size.width * card.xRatio,
                        y: geo.size.height * card.yRatio
                    ),
                    cardScale: card.scale,
                    dismissing: dismissing,
                    index: i,
                    phaseOffset: Double(i) * 1.2
                )
            }
        }
        .allowsHitTesting(false)
    }
}

private struct FloatingCardItem: View {
    let title: String
    let courseId: String
    let rotation: Double
    let position: CGPoint
    let cardScale: CGFloat
    let dismissing: Bool
    let index: Int
    let phaseOffset: Double
    @State private var floatY: CGFloat = 0
    @State private var floatX: CGFloat = 0
    @State private var floatRotation: Double = 0
    @State private var image: UIImage?

    private let baseWidth: CGFloat = 130
    private let baseImageHeight: CGFloat = 80

    var body: some View {
        let w = baseWidth * cardScale
        let h = baseImageHeight * cardScale

        VStack(spacing: 0) {
            Color(.secondarySystemBackground)
                .frame(width: w, height: h)
                .overlay {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    } else {
                        LinearGradient(
                            colors: [SophiaTheme.accent.opacity(0.3), SophiaTheme.accent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .clipShape(.rect(cornerRadii: .init(topLeading: 10, topTrailing: 10)))

            Text(title)
                .font(.system(cardScale > 1.1 ? .caption : .caption2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .frame(width: w, alignment: .leading)
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .background(SophiaTheme.cardBackground)
                .clipShape(.rect(cornerRadii: .init(bottomLeading: 10, bottomTrailing: 10)))
        }
        .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
        .rotationEffect(.degrees(rotation + floatRotation))
        .position(x: position.x + floatX, y: position.y + floatY)
        .opacity(dismissing ? 0 : 0.55)
        .offset(y: dismissing ? -250 : 0)
        .scaleEffect(dismissing ? 0.4 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.08), value: dismissing)
        .onAppear {
            image = CourseImageMap.loadImage(for: courseId)
            let baseDuration = Double.random(in: 3.0...4.2)
            let yDuration = baseDuration + phaseOffset * 0.3
            let xDuration = baseDuration * 1.15 + phaseOffset * 0.25
            let rotDuration = baseDuration * 1.3 + phaseOffset * 0.2
            let yAmp = CGFloat.random(in: 14...24)
            let xAmp = CGFloat.random(in: 8...14)
            let rotAmp = Double.random(in: 1.5...3.0)
            let yDelay = phaseOffset * 0.5
            let xDelay = phaseOffset * 0.7
            let rotDelay = phaseOffset * 0.4
            withAnimation(.easeInOut(duration: yDuration).repeatForever(autoreverses: true).delay(yDelay)) {
                floatY = yAmp
            }
            withAnimation(.easeInOut(duration: xDuration).repeatForever(autoreverses: true).delay(xDelay)) {
                floatX = xAmp
            }
            withAnimation(.easeInOut(duration: rotDuration).repeatForever(autoreverses: true).delay(rotDelay)) {
                floatRotation = rotAmp
            }
        }
    }
}
