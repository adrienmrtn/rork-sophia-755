import SwiftUI

/// Aperçu du Parcours (l'onglet façon Duolingo) pour la page « route personnalisée » de
/// l'onboarding : la bannière du premier niveau et ses premiers pods, légèrement floutés,
/// fondus dans le fond de la page sur les bords. Rien ne se tape : c'est une image vivante,
/// la bulle « Commencer » oscille comme dans l'onglet.
///
/// Les pods, la bulle, le halo et la couverture sont ceux du Parcours (`PathNodeViews`,
/// `CollectionCoverView`) ; seule la géométrie est resserrée pour tenir dans la page.
struct OnboardingV2PathPreview: View {
    @Environment(LanguageManager.self) private var languageManager
    let size: CGSize

    @State private var level: PreviewLevel? = nil

    struct PreviewLevel {
        let collection: LearningCollection
        let nodes: [PreviewNode]
    }

    struct PreviewNode: Identifiable {
        let id: String
        /// `nil` pour le quiz de fin de niveau.
        let course: Course?
        let state: PathNodeState
        let index: Int
    }

    var body: some View {
        ZStack(alignment: .top) {
            if let level {
                VStack(spacing: Metrics.bannerGap) {
                    banner(level.collection, courseCount: level.nodes.count - 1)
                    trail(level.nodes)
                }
                .frame(width: min(size.width, 400))
                .scaleEffect(scale, anchor: .top)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .top)
        .clipped()
        .blur(radius: 1.1)
        .mask(bottomFade)
        .overlay(edgeFades)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            if level == nil {
                level = Self.makeLevel(language: languageManager.current)
            }
        }
    }

    /// Réduit sur les petits écrans, pour que le pod à jouer et sa bulle restent visibles.
    private var scale: CGFloat {
        min(0.92, max(0.72, size.height / 320))
    }

    // MARK: - Niveau montré

    /// Le premier niveau du Parcours de la langue courante : un cours terminé, le suivant à
    /// jouer, les autres fermés, le quiz du niveau pour finir.
    private static func makeLevel(language: AppLanguage) -> PreviewLevel? {
        let collections = ContentCatalog.collections(for: language)
        guard let collection = collections.first(where: { !$0.courses.isEmpty }) else { return nil }
        let courses = Array(collection.courses.prefix(4))
        var nodes: [PreviewNode] = []
        for (index, course) in courses.enumerated() {
            let state: PathNodeState = index == 0 ? .completed : (index == 1 ? .available : .locked)
            nodes.append(PreviewNode(id: course.id, course: course, state: state, index: index))
        }
        nodes.append(PreviewNode(id: "quiz", course: nil, state: .locked, index: courses.count))
        return PreviewLevel(collection: collection, nodes: nodes)
    }

    // MARK: - Géométrie

    /// Même tracé que `PathLayout`, en plus serré.
    private enum Metrics {
        static let bannerHeight: CGFloat = 76
        static let bannerGap: CGFloat = 12
        static let rowHeight: CGFloat = 104
        static let podAreaHeight: CGFloat = 80
        static let podSize: CGFloat = 60
        static let quizPodSize: CGFloat = 72
        static let plateDepth: CGFloat = 6
        static let waveAmplitude: CGFloat = 66
        static let captionWidth: CGFloat = 124
    }

    private static func xOffset(for step: Int) -> CGFloat {
        CGFloat(sin(Double(step) * Double.pi / 4)) * Metrics.waveAmplitude
    }

    /// Centre de la face du pod de la rangée `step`, dans le repère du tracé.
    private static func center(step: Int, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.midX + xOffset(for: step),
            y: rect.minY + CGFloat(step) * Metrics.rowHeight + (Metrics.podAreaHeight - Metrics.plateDepth) / 2
        )
    }

    /// Les courbes qui relient les rangées `from` à `to`.
    private struct Segments: Shape {
        let from: Int
        let to: Int

        func path(in rect: CGRect) -> Path {
            var path = Path()
            guard to > from else { return path }
            for step in from..<to {
                let start = OnboardingV2PathPreview.center(step: step, in: rect)
                let end = OnboardingV2PathPreview.center(step: step + 1, in: rect)
                let midY = (start.y + end.y) / 2
                path.move(to: start)
                path.addCurve(
                    to: end,
                    control1: CGPoint(x: start.x, y: midY),
                    control2: CGPoint(x: end.x, y: midY)
                )
            }
            return path
        }
    }

    // MARK: - Bannière

    private func banner(_ collection: LearningCollection, courseCount: Int) -> some View {
        let levelText = String(format: languageManager.text("path.levelCaption"), 1)
        let coursesText = String(format: languageManager.text("path.courses.count"), 1, courseCount)
        let caption = "\(levelText) · \(coursesText)".uppercased(with: languageManager.current.foundationLocale)
        return CollectionCoverView(collection: collection, accentIndex: 0)
            .frame(height: Metrics.bannerHeight)
            .frame(maxWidth: .infinity)
            .overlay(
                LinearGradient(
                    colors: [.black.opacity(0.30), .black.opacity(0.58)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .overlay {
                VStack(spacing: 5) {
                    Text(caption)
                        .font(DS.sans(.caption2, .bold))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                    Text(collection.title)
                        .font(DS.title(.subheadline, .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 18)
                .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
            .padding(.horizontal, 20)
    }

    // MARK: - Tracé et pods

    private func trail(_ nodes: [PreviewNode]) -> some View {
        ZStack(alignment: .top) {
            Segments(from: 0, to: nodes.count - 1)
                .stroke(DS.hairline, style: StrokeStyle(lineWidth: 4, lineCap: .round))

            // Le trait coloré suit les pods terminés, jusqu'au pod à jouer.
            ForEach(Array(nodes.dropLast().enumerated()), id: \.element.id) { index, node in
                if node.state == .completed {
                    Segments(from: index, to: index + 1)
                        .stroke(accentTint(node), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                }
            }

            VStack(spacing: 0) {
                ForEach(nodes) { node in
                    podRow(node)
                }
            }
        }
        .frame(height: CGFloat(nodes.count) * Metrics.rowHeight)
    }

    private func podRow(_ node: PreviewNode) -> some View {
        let diameter = node.course == nil ? Metrics.quizPodSize : Metrics.podSize
        let tint = accentTint(node)
        let isCurrent = node.state == .available

        return VStack(spacing: 6) {
            ZStack(alignment: .top) {
                Circle()
                    .fill(plateColor(node, tint: tint))
                    .frame(width: diameter, height: diameter)
                    .offset(y: Metrics.plateDepth)
                face(node, tint: tint, diameter: diameter)
            }
            .frame(width: diameter, height: diameter + Metrics.plateDepth, alignment: .top)
            .background {
                if isCurrent {
                    PathPulseHalo(tint: tint, diameter: diameter)
                        .offset(y: -Metrics.plateDepth / 2)
                }
            }
            .overlay(alignment: .top) {
                if isCurrent {
                    PathStartBubble(
                        text: languageManager.text("home.start").uppercased(with: languageManager.current.foundationLocale),
                        tint: tint
                    )
                    .offset(y: -44)
                }
            }
            .frame(height: Metrics.podAreaHeight)

            Text(caption(node))
                .font(DS.sans(.caption2, .semibold))
                .foregroundStyle(node.state == .locked ? DS.inkTertiary : DS.inkSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: Metrics.captionWidth)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Metrics.rowHeight, alignment: .top)
        .offset(x: Self.xOffset(for: node.index))
        .zIndex(isCurrent ? 1 : 0)
    }

    @ViewBuilder
    private func face(_ node: PreviewNode, tint: Color, diameter: CGFloat) -> some View {
        if let course = node.course {
            PathPodFace(state: node.state, tint: tint, icon: course.subject.icon, diameter: diameter)
        } else {
            PathQuizPodFace(state: node.state, diameter: diameter)
        }
    }

    private func accentTint(_ node: PreviewNode) -> Color {
        if let course = node.course {
            return PathPalette.tint(for: course.subject)
        }
        return PathPalette.gold
    }

    private func plateColor(_ node: PreviewNode, tint: Color) -> Color {
        switch node.state {
        case .locked:
            return PathPalette.lockedPlate
        case .available:
            return node.course == nil ? PathPalette.plate(for: PathPalette.gold) : PathPalette.availablePlate
        case .completed:
            return PathPalette.plate(for: tint)
        }
    }

    private func caption(_ node: PreviewNode) -> String {
        node.course?.title ?? languageManager.text("path.quizPod")
    }

    // MARK: - Bords

    private var bottomFade: some View {
        LinearGradient(
            stops: [
                .init(color: .black, location: 0),
                .init(color: .black, location: 0.7),
                .init(color: .clear, location: 1),
            ],
            startPoint: .top, endPoint: .bottom
        )
    }

    /// Les bords blancs : le fond de la page remonte sur les côtés et en haut, pour que
    /// l'aperçu semble posé dans la page plutôt que découpé.
    private var edgeFades: some View {
        ZStack {
            HStack(spacing: 0) {
                LinearGradient(colors: [OV2.bg, OV2.bg.opacity(0)], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 34)
                Spacer(minLength: 0)
                LinearGradient(colors: [OV2.bg.opacity(0), OV2.bg], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 34)
            }
            VStack(spacing: 0) {
                LinearGradient(colors: [OV2.bg, OV2.bg.opacity(0)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 22)
                Spacer(minLength: 0)
            }
        }
    }
}
