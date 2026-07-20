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
                    title: ContentCatalog.course(withId: card.courseId)?.title ?? card.title,
                    courseId: card.courseId,
                    rotation: card.rotation,
                    position: CGPoint(
                        x: geo.size.width * card.xRatio,
                        y: geo.size.height * card.yRatio
                    ),
                    cardScale: card.scale,
                    dismissing: dismissing,
                    index: i,
                    phaseOffset: Double(i) * 1.2,
                    accent: OnboardingPastels.at(i)
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
    let accent: Color
    @State private var floatY: CGFloat = 0
    @State private var floatX: CGFloat = 0
    @State private var floatRotation: Double = 0
    @State private var image: UIImage?

    private let baseWidth: CGFloat = 130
    private let baseImageHeight: CGFloat = 80

    var body: some View {
        let w = baseWidth * cardScale
        let h = baseImageHeight * cardScale
        let corner: CGFloat = 14
        let depth: CGFloat = 5

        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(BrutalPalette.ink)
                .frame(width: w, height: h + cardLabelHeight + 4)
                .offset(y: depth)

            VStack(spacing: 0) {
                Color(red: 0.96, green: 0.93, blue: 0.88)
                    .frame(width: w, height: h)
                    .overlay {
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        } else {
                            accent
                        }
                    }
                    .clipShape(.rect(cornerRadii: .init(topLeading: corner, topTrailing: corner)))
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(BrutalPalette.ink).frame(height: 2.5)
                    }

                Text(title)
                    .font(.jakarta(cardScale > 1.1 ? .caption : .caption2, design: .rounded, weight: .heavy))
                    .foregroundStyle(BrutalPalette.ink)
                    .lineLimit(2)
                    .frame(width: w, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .frame(height: cardLabelHeight, alignment: .topLeading)
                    .background(accent)
                    .clipShape(.rect(cornerRadii: .init(bottomLeading: corner, bottomTrailing: corner)))
            }
            .frame(width: w)
            .overlay {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(BrutalPalette.ink, lineWidth: 2.5)
            }
        }
        .rotationEffect(.degrees(rotation + floatRotation))
        .position(x: position.x + floatX, y: position.y + floatY)
        .opacity(dismissing ? 0 : 1)
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

    private var cardLabelHeight: CGFloat {
        cardScale > 1.1 ? 44 : 36
    }
}
