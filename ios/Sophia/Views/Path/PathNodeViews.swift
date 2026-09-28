import SwiftUI

// MARK: - Layout

/// Geometry of the trail: pods stacked in rows, each row shifted along a sine wave so the
/// trail winds down the screen. Everything is derived from the row index, so the connector
/// shapes can be drawn without measuring the pods.
enum PathLayout {
    static let podSize: CGFloat = 74
    static let quizPodSize: CGFloat = 92
    static let plateDepth: CGFloat = 7
    /// Height reserved for a pod and its plate, whatever its size, so centres line up.
    static let podAreaHeight: CGFloat = 100
    /// Pod area plus the caption underneath.
    static let rowHeight: CGFloat = 138
    static let waveAmplitude: CGFloat = 84

    static func xOffset(for step: Int) -> CGFloat {
        CGFloat(sin(Double(step) * Double.pi / 4)) * waveAmplitude
    }

    /// Centre of the pod face in row `step`, in the coordinates of the trail canvas.
    static func center(step: Int, phase: Int, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.midX + xOffset(for: step + phase),
            y: rect.minY + CGFloat(step) * rowHeight + (podAreaHeight - plateDepth) / 2
        )
    }
}

// MARK: - Palette

/// The app's calm palette, tinted by subject on the pods; gold is kept for the quiz.
enum PathPalette {
    static let gold = Color(red: 0.93, green: 0.70, blue: 0.18)

    static var goldGradient: LinearGradient {
        LinearGradient(
            colors: [gold.mix(with: .white, by: 0.22), gold],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func tint(for subject: Subject) -> Color {
        subject.color.mix(with: .black, by: 0.08)
    }

    /// The darker rim drawn under a pod, giving it its thickness.
    static func plate(for fill: Color) -> Color {
        fill.mix(with: .black, by: 0.3)
    }

    static var availablePlate: Color {
        DS.hairline.mix(with: DS.inkTertiary, by: 0.45)
    }

    static var lockedPlate: Color { DS.hairline }
}

// MARK: - Pod press style

/// A round button with a thick rim underneath; pressing it sinks the face onto the rim.
struct PathPodPressStyle: ButtonStyle {
    let plateColor: Color
    let diameter: CGFloat
    var depth: CGFloat = PathLayout.plateDepth

    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .top) {
            Circle()
                .fill(plateColor)
                .frame(width: diameter, height: diameter)
                .offset(y: depth)
            configuration.label
                .frame(width: diameter, height: diameter)
                .offset(y: configuration.isPressed ? depth : 0)
        }
        .frame(width: diameter, height: diameter + depth, alignment: .top)
        .animation(.spring(response: 0.18, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// MARK: - Pod faces

/// Face of a course pod: filled with the subject colour once completed, ringed while it is
/// the one to play, greyed while locked.
struct PathPodFace: View {
    let state: PathNodeState
    let tint: Color
    let icon: String
    let diameter: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(fillColor)
            if state == .available {
                Circle().strokeBorder(tint, lineWidth: 4)
            } else if state == .locked {
                Circle().strokeBorder(DS.hairline, lineWidth: 1)
            }
            Image(systemName: symbolName)
                .font(.jakarta(size: diameter * 0.36, weight: .semibold))
                .foregroundStyle(symbolColor)
                .contentTransition(.symbolEffect(.replace))
        }
        .frame(width: diameter, height: diameter)
        .animation(.easeInOut(duration: 0.35), value: state)
    }

    private var fillColor: Color {
        switch state {
        case .completed: tint
        case .available: DS.surface
        case .locked: DS.surfaceMuted
        }
    }

    private var symbolName: String {
        switch state {
        case .completed: "checkmark"
        case .available: icon
        case .locked: "lock.fill"
        }
    }

    private var symbolColor: Color {
        switch state {
        case .completed: .white
        case .available: tint
        case .locked: DS.inkTertiary
        }
    }
}

/// Face of the end-of-level quiz pod: a golden trophy once it can be taken, greyed before.
struct PathQuizPodFace: View {
    let state: PathNodeState
    let diameter: CGFloat

    var body: some View {
        ZStack {
            if state == .locked {
                Circle().fill(DS.surfaceMuted)
                Circle().strokeBorder(DS.hairline, lineWidth: 1)
            } else {
                Circle().fill(PathPalette.goldGradient)
                Circle()
                    .strokeBorder(.white.opacity(0.45), lineWidth: 2)
                    .padding(5)
            }
            Image(systemName: "trophy.fill")
                .font(.jakarta(size: diameter * 0.4, weight: .semibold))
                .foregroundStyle(state == .locked ? DS.inkTertiary : .white)
                .shadow(color: .black.opacity(state == .locked ? 0 : 0.18), radius: 2, y: 1)
        }
        .frame(width: diameter, height: diameter)
        .overlay(alignment: .bottomTrailing) {
            if state == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.jakarta(size: diameter * 0.3, weight: .semibold))
                    .foregroundStyle(DS.success)
                    .background {
                        Circle().fill(.white).padding(2)
                    }
                    .offset(x: 2, y: 2)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: state)
    }
}

// MARK: - Start bubble, halo, shake

/// The bobbing "start" call-out above the pod to play next.
struct PathStartBubble: View {
    let text: String
    let tint: Color

    @State private var bob = false

    var body: some View {
        VStack(spacing: -1) {
            Text(text)
                .font(DS.sans(.caption, .bold))
                .tracking(1.2)
                .foregroundStyle(tint)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(DS.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            PathBubblePointer()
                .fill(DS.surface)
                .frame(width: 16, height: 8)
        }
        .compositingGroup()
        .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
        .offset(y: bob ? -4 : 3)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                bob = true
            }
        }
        .accessibilityHidden(true)
    }
}

struct PathBubblePointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Soft breathing glow behind the pod to play next.
struct PathPulseHalo: View {
    let tint: Color
    let diameter: CGFloat

    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(tint.opacity(0.22))
            .frame(width: diameter * 1.4, height: diameter * 1.4)
            .scaleEffect(pulse ? 1.12 : 0.9)
            .opacity(pulse ? 0.35 : 0.95)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// Horizontal rattle: bump `shakes` by one inside `withAnimation` to play it once.
/// `nonisolated`: `Animatable.animatableData` is a nonisolated requirement, and the
/// project's default actor isolation is the main actor.
nonisolated struct PathShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var amplitude: CGFloat = 7

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amplitude * sin(shakes * .pi * 4)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

// MARK: - Connectors

/// The curve joining row `index` to the next one.
struct PathSegmentShape: Shape {
    let index: Int
    let phase: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let start = PathLayout.center(step: index, phase: phase, in: rect)
        let end = PathLayout.center(step: index + 1, phase: phase, in: rect)
        let midY = (start.y + end.y) / 2
        path.move(to: start)
        path.addCurve(
            to: end,
            control1: CGPoint(x: start.x, y: midY),
            control2: CGPoint(x: end.x, y: midY)
        )
        return path
    }
}

/// Every connector of a level at once, for the faint base line under the pods.
struct PathTrailBaseShape: Shape {
    let count: Int
    let phase: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard count > 1 else { return path }
        for index in 0..<(count - 1) {
            path.addPath(PathSegmentShape(index: index, phase: phase).path(in: rect))
        }
        return path
    }
}

// MARK: - Level banner

/// Header of a level: the collection cover, its number and title. Greyed while locked,
/// with a chip saying so; a golden chip once the level is passed.
struct PathLevelBanner: View {
    @Environment(LanguageManager.self) private var languageManager
    let level: PathLevel
    let isUnlocked: Bool
    let isPassed: Bool
    let accentIndex: Int

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            CollectionCoverView(collection: level.collection, accentIndex: accentIndex)
                .grayscale(isUnlocked ? 0 : 1)
                .opacity(isUnlocked ? 1 : 0.6)

            LinearGradient(
                colors: [.clear, .black.opacity(0.25), .black.opacity(0.78)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Text(caption)
                        .font(DS.sans(.caption2, .bold))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    statusChip
                }
                Text(level.collection.title)
                    .font(DS.title(.title3, .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .frame(height: 156)
        .frame(maxWidth: .infinity)
        .clipShape(.rect(cornerRadius: DS.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(DS.hairline, lineWidth: 1)
        }
        .dsSoftShadow()
        .animation(.easeInOut(duration: 0.6), value: isUnlocked)
        .animation(.easeInOut(duration: 0.35), value: isPassed)
    }

    private var caption: String {
        let levelText = String(format: languageManager.text("path.levelCaption"), level.number)
        let coursesText = String(format: languageManager.text("path.courses.count"), level.completedCourseCount, level.courseCount)
        return "\(levelText) · \(coursesText)".uppercased(with: languageManager.current.foundationLocale)
    }

    @ViewBuilder
    private var statusChip: some View {
        if isPassed {
            chip(icon: "checkmark.seal.fill", text: languageManager.text("path.status.passed"), tint: PathPalette.gold)
        } else if !isUnlocked {
            chip(icon: "lock.fill", text: languageManager.text("path.status.locked"), tint: .white.opacity(0.9))
        }
    }

    private func chip(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.jakarta(size: 10, weight: .bold))
            Text(text)
                .font(DS.sans(.caption2, .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.black.opacity(0.35), in: Capsule())
    }
}
