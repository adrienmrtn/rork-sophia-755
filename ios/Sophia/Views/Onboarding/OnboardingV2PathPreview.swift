import SwiftUI

/// Aperçu du Parcours pour la page « route personnalisée » : trois pods reliés par le trait
/// du Parcours (un cours terminé, le cours à jouer avec son halo, le suivant fermé), avec les
/// titres des trois premiers cours du premier niveau. Même dessin que l'onglet
/// (`PathNodeViews`), resserré pour tenir dans la hauteur de la page, sans bannière ni flou.
struct OnboardingV2PathPreview: View {
    @Environment(LanguageManager.self) private var languageManager
    let size: CGSize

    @State private var nodes: [PreviewNode] = []

    struct PreviewNode: Identifiable {
        let id: String
        let course: Course
        let state: PathNodeState
        let index: Int
    }

    private static let plateDepth: CGFloat = 6
    /// Décalage horizontal de chaque rangée, en fraction de l'amplitude : gauche, droite, gauche.
    private static let zigzag: [CGFloat] = [-0.55, 0.6, -0.55]

    /// Trois rangées dans la hauteur reçue ; en dessous de 72 pt par rangée (fenêtre iPad
    /// très basse) les titres disparaissent plutôt que de chevaucher la rangée suivante.
    private var rowHeight: CGFloat { max(56, min(112, size.height / 3)) }
    private var podSize: CGFloat { rowHeight >= 100 ? 60 : (rowHeight >= 84 ? 54 : 44) }
    private var amplitude: CGFloat { min(72, size.width * 0.2) }
    private var podAreaHeight: CGFloat { podSize + Self.plateDepth + 8 }
    private var showsCaptions: Bool { rowHeight >= 72 }
    private var captionLines: Int { rowHeight >= 100 ? 2 : 1 }

    var body: some View {
        ZStack(alignment: .top) {
            if !nodes.isEmpty {
                Segments(from: 0, to: nodes.count - 1, rowHeight: rowHeight, podAreaHeight: podAreaHeight, amplitude: amplitude)
                    .stroke(DS.hairline, style: StrokeStyle(lineWidth: 4, lineCap: .round))

                // Le trait coloré derrière le cours terminé, jusqu'au cours à jouer.
                Segments(from: 0, to: 1, rowHeight: rowHeight, podAreaHeight: podAreaHeight, amplitude: amplitude)
                    .stroke(accentTint(nodes[0]), style: StrokeStyle(lineWidth: 4, lineCap: .round))

                VStack(spacing: 0) {
                    ForEach(nodes) { node in
                        podRow(node)
                    }
                }
            }
        }
        .frame(width: size.width, height: rowHeight * CGFloat(max(nodes.count, 1)))
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            if nodes.isEmpty {
                nodes = Self.makeNodes(language: languageManager.current)
            }
        }
    }

    // MARK: - Cours montrés

    /// Les trois premiers cours du premier niveau du Parcours : terminé, à jouer, fermé.
    private static func makeNodes(language: AppLanguage) -> [PreviewNode] {
        let collections = ContentCatalog.collections(for: language)
        guard let collection = collections.first(where: { $0.courses.count >= 3 }) ?? collections.first(where: { !$0.courses.isEmpty }) else {
            return []
        }
        let states: [PathNodeState] = [.completed, .available, .locked]
        return Array(collection.courses.prefix(3)).enumerated().map { index, course in
            PreviewNode(id: course.id, course: course, state: states[min(index, states.count - 1)], index: index)
        }
    }

    // MARK: - Géométrie

    private static func xOffset(step: Int, amplitude: CGFloat) -> CGFloat {
        zigzag[step % zigzag.count] * amplitude
    }

    /// Les courbes qui relient les rangées `from` à `to`, avec la géométrie de l'aperçu.
    private struct Segments: Shape {
        let from: Int
        let to: Int
        let rowHeight: CGFloat
        let podAreaHeight: CGFloat
        let amplitude: CGFloat

        func path(in rect: CGRect) -> Path {
            var path = Path()
            guard to > from else { return path }
            for step in from..<to {
                let start = center(step: step, in: rect)
                let end = center(step: step + 1, in: rect)
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

        /// Centre de la face du pod de la rangée `step`.
        private func center(step: Int, in rect: CGRect) -> CGPoint {
            CGPoint(
                x: rect.midX + OnboardingV2PathPreview.xOffset(step: step, amplitude: amplitude),
                y: rect.minY + CGFloat(step) * rowHeight + (podAreaHeight - OnboardingV2PathPreview.plateDepth) / 2
            )
        }
    }

    // MARK: - Pods

    private func podRow(_ node: PreviewNode) -> some View {
        let tint = accentTint(node)
        let isCurrent = node.state == .available

        return VStack(spacing: 6) {
            ZStack(alignment: .top) {
                Circle()
                    .fill(plateColor(node, tint: tint))
                    .frame(width: podSize, height: podSize)
                    .offset(y: Self.plateDepth)
                PathPodFace(state: node.state, tint: tint, icon: node.course.subject.icon, diameter: podSize)
            }
            .frame(width: podSize, height: podSize + Self.plateDepth, alignment: .top)
            .background {
                if isCurrent {
                    PathPulseHalo(tint: tint, diameter: podSize)
                        .offset(y: -Self.plateDepth / 2)
                }
            }
            .frame(height: podAreaHeight)

            if showsCaptions {
                Text(node.course.title)
                    .font(DS.sans(.caption2, .semibold))
                    .foregroundStyle(node.state == .locked ? DS.inkTertiary : DS.inkSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(captionLines)
                    .frame(width: 130)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: rowHeight, alignment: .top)
        .offset(x: Self.xOffset(step: node.index, amplitude: amplitude))
        .zIndex(isCurrent ? 1 : 0)
    }

    private func accentTint(_ node: PreviewNode) -> Color {
        PathPalette.tint(for: node.course.subject)
    }

    private func plateColor(_ node: PreviewNode, tint: Color) -> Color {
        switch node.state {
        case .locked:
            return PathPalette.lockedPlate
        case .available:
            return PathPalette.availablePlate
        case .completed:
            return PathPalette.plate(for: tint)
        }
    }
}
