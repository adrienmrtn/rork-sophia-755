import SwiftUI

/// A short burst of paper pieces, drawn in a `Canvas` and driven by a `TimelineView`.
/// Fire and forget: it fades out on its own once `duration` has elapsed.
struct PathConfettiBurst: View {
    var colors: [Color]
    var pieceCount: Int = 90
    var duration: Double = 2.6
    /// Where the burst starts, in unit coordinates of the view (0...1).
    var origin: CGPoint = CGPoint(x: 0.5, y: 0.35)

    private struct Piece {
        let angle: Double       // radians, upwards is negative
        let speed: Double       // points per second
        let spin: Double        // radians per second
        let size: CGSize
        let colorIndex: Int
        let drift: Double       // phase of the horizontal wobble
        let delay: Double
    }

    @State private var pieces: [Piece] = []
    @State private var startDate = Date()

    private static let gravity: Double = 950

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                guard elapsed < duration, !colors.isEmpty else { return }
                let fade = elapsed > duration - 0.6 ? max(0, (duration - elapsed) / 0.6) : 1
                let start = CGPoint(x: size.width * origin.x, y: size.height * origin.y)

                for piece in pieces {
                    let life = elapsed - piece.delay
                    guard life > 0 else { continue }
                    let vx = cos(piece.angle) * piece.speed
                    let vy = sin(piece.angle) * piece.speed
                    let x = start.x + vx * life * 0.9 + sin(life * 3 + piece.drift) * 10
                    let y = start.y + vy * life + 0.5 * Self.gravity * life * life
                    guard y < size.height + 24 else { continue }

                    var pieceContext = context
                    pieceContext.opacity = fade
                    pieceContext.translateBy(x: x, y: y)
                    pieceContext.rotate(by: .radians(piece.spin * life))
                    let rect = CGRect(
                        x: -piece.size.width / 2,
                        y: -piece.size.height / 2,
                        width: piece.size.width,
                        height: piece.size.height
                    )
                    pieceContext.fill(
                        Path(roundedRect: rect, cornerRadius: 1.5),
                        with: .color(colors[piece.colorIndex % colors.count])
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            startDate = Date()
            let colorCount = max(colors.count, 1)
            pieces = (0..<pieceCount).map { _ in
                Piece(
                    angle: Double.random(in: (-Double.pi * 0.95)...(-Double.pi * 0.05)),
                    speed: Double.random(in: 280...680),
                    spin: Double.random(in: -9...9),
                    size: CGSize(width: Double.random(in: 6...11), height: Double.random(in: 4...8)),
                    colorIndex: Int.random(in: 0..<colorCount),
                    drift: Double.random(in: 0...(Double.pi * 2)),
                    delay: Double.random(in: 0...0.12)
                )
            }
        }
    }
}
