import SwiftUI
import UIKit

/// Aperçu du Parcours pour la page « parcours personnalisé » du carrousel : la carte du
/// premier niveau, avec ses quatre premiers cours en zigzag reliés par un pointillé — deux
/// cours faits (coche verte), le cours à lire (bordure bleue, « Commencer »), un cours
/// encore fermé (grisé, cadenas). Les cours, leurs couvertures et le nom du niveau viennent
/// du catalogue de la langue.
struct OnboardingV2PathPreview: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// La page qui montre l'aperçu est-elle la page courante du carrousel ?
    var isActive: Bool = true

    @State private var nodes: [PreviewNode] = []
    @State private var levelTitle: String = ""
    @State private var levelCourseCount: Int = 0
    /// Les cours et leurs liaisons sont apparus (chacun avec son propre retard).
    @State private var shown = false
    @State private var pulse = false

    enum Step {
        case done, current, locked
    }

    struct PreviewNode: Identifiable {
        let id: String
        let course: Course
        let cover: UIImage?
        let step: Step
        let index: Int
    }

    // Géométrie de la maquette, dans un cadre de 310 × 322.
    private static let canvasHeight: CGFloat = 322
    private static let referenceWidth: CGFloat = 310
    private static let centersY: [CGFloat] = [30, 92, 162, 236]
    private static let labelTops: [CGFloat] = [65, 127, 205, 271]
    private static let steps: [Step] = [.done, .done, .current, .locked]
    /// Nombre de cours déjà faits dans l'aperçu.
    private static let doneCount = 2

    // Couleurs de l'illustration : vert des cours faits, gris des cours fermés.
    private static let doneGreen = Color(red: 0.247, green: 0.749, blue: 0.561)
    private static let doneInk = Color(red: 0.173, green: 0.541, blue: 0.400)
    private static let lockedLine = Color(red: 0.765, green: 0.796, blue: 0.847)
    private static let lockedBadge = Color(red: 0.933, green: 0.941, blue: 0.953)

    var body: some View {
        VStack(spacing: 14) {
            header

            GeometryReader { geo in
                canvas(width: geo.size.width)
            }
            .frame(height: Self.canvasHeight)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .ov2Card()
        .padding(.bottom, 2)
        .allowsHitTesting(false)
        .onAppear { loadLevel() }
        .onIntroPageActivated(isActive) { play() }
    }

    // MARK: - En-tête de la carte

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            DSEyebrow(text: String(format: languageManager.text("subject.level"), 1))
                .fixedSize()

            Text(levelTitle)
                .font(DS.sans(.footnote, .bold))
                .foregroundStyle(OV2.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 4)

            Text(String(format: languageManager.text("path.courses.count"), Self.doneCount, max(levelCourseCount, nodes.count)))
                .font(DS.sans(.caption, .bold))
                .foregroundStyle(OV2.inkSecondary)
                .lineLimit(1)
                .fixedSize()
        }
    }

    // MARK: - Zigzag

    private func canvas(width: CGFloat) -> some View {
        let labelWidth: CGFloat = min(140, width * 0.46)
        return ZStack(alignment: .topLeading) {
            ForEach(nodes) { node in
                if node.index + 1 < nodes.count {
                    link(from: node.index, width: width)
                }
            }

            ForEach(nodes) { node in
                tile(node)
                    .position(center(of: node.index, width: width))

                label(node)
                    .frame(width: labelWidth, height: labelSlotHeight(node), alignment: .top)
                    .position(
                        x: centerX(of: node.index, width: width),
                        y: labelTop(of: node.index) + labelSlotHeight(node) / 2
                    )
                    .opacity(shown ? 1 : 0)
                    .animation(revealAnimation(node.index, extra: 0.1), value: shown)
            }
        }
        .frame(width: width, height: Self.canvasHeight, alignment: .topLeading)
    }

    /// Les cours pairs sont à gauche, les impairs à droite.
    private func centerX(of index: Int, width: CGFloat) -> CGFloat {
        let reference: CGFloat = index.isMultiple(of: 2) ? 72 : 238
        return width * reference / Self.referenceWidth
    }

    private func center(of index: Int, width: CGFloat) -> CGPoint {
        CGPoint(x: centerX(of: index, width: width), y: Self.centersY[index % Self.centersY.count])
    }

    private func labelTop(of index: Int) -> CGFloat {
        Self.labelTops[index % Self.labelTops.count]
    }

    private func labelSlotHeight(_ node: PreviewNode) -> CGFloat {
        node.step == .current ? 84 : 46
    }

    private func tileSize(_ step: Step) -> CGFloat {
        step == .current ? 76 : 60
    }

    /// Retard d'apparition du cours n° `index` : ils se posent l'un après l'autre.
    private func revealAnimation(_ index: Int, extra: Double = 0) -> Animation {
        if reduceMotion { return .easeOut(duration: 0.2) }
        return DS.Motion.pop.delay(0.15 + Double(index) * 0.28 + extra)
    }

    /// Le pointillé entre le cours `index` et le suivant : vert tant que le suivant est
    /// atteint, gris vers un cours fermé.
    private func link(from index: Int, width: CGFloat) -> some View {
        let reachesLocked: Bool = nodes[index + 1].step == .locked
        let delay: Double = 0.3 + Double(index) * 0.28
        return OnboardingV2PathLink(
            start: center(of: index, width: width),
            end: center(of: index + 1, width: width)
        )
        .trim(from: 0, to: shown ? 1 : 0)
        .stroke(
            reachesLocked ? Self.lockedLine : Self.doneGreen,
            style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [0.5, 8])
        )
        .animation(reduceMotion ? .easeOut(duration: 0.2) : .easeInOut(duration: 0.4).delay(delay), value: shown)
    }

    // MARK: - Cours

    private func tile(_ node: PreviewNode) -> some View {
        let size: CGFloat = tileSize(node.step)
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return ZStack {
            DS.surface
            tileImage(node)
        }
        .frame(width: size, height: size)
        .clipShape(shape)
        .overlay(shape.strokeBorder(borderColor(node.step), lineWidth: 3))
        .background {
            if node.step == .current {
                shape
                    .stroke(DS.accent, lineWidth: 3)
                    .scaleEffect(pulse ? 1.22 : 1)
                    .opacity(pulse ? 0 : 0.45)
            }
        }
        .overlay(alignment: .topTrailing) {
            if shown {
                badge(node)
                    .offset(x: 6, y: -6)
            }
        }
        .scaleEffect(shown || reduceMotion ? 1 : 0.4)
        .opacity(shown ? 1 : 0)
        .animation(revealAnimation(node.index), value: shown)
    }

    @ViewBuilder
    private func tileImage(_ node: PreviewNode) -> some View {
        let locked: Bool = node.step == .locked
        if let cover = node.cover {
            Image(uiImage: cover)
                .resizable()
                .scaledToFill()
                .saturation(locked ? 0 : 1)
                .opacity(locked ? 0.4 : 1)
        } else {
            node.course.subject.color
                .opacity(locked ? 0.12 : 0.35)
        }
    }

    private func borderColor(_ step: Step) -> Color {
        switch step {
        case .done: Self.doneGreen
        case .current: DS.accent
        case .locked: DS.hairline
        }
    }

    /// Coche verte du cours fait, cadenas du cours fermé ; rien sur le cours à lire.
    @ViewBuilder
    private func badge(_ node: PreviewNode) -> some View {
        switch node.step {
        case .done:
            DSCheckBadge(size: 18, fill: Self.doneGreen, delay: reduceMotion ? 0 : 0.35 + Double(node.index) * 0.28)
                .padding(2)
                .background(Circle().fill(DS.surface))
        case .locked:
            ZStack {
                Circle().fill(Self.lockedBadge)
                Image(systemName: "lock.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(OV2.inkTertiary)
            }
            .frame(width: 18, height: 18)
            .padding(2)
            .background(Circle().fill(DS.surface))
            .transition(.scale.combined(with: .opacity))
        case .current:
            EmptyView()
        }
    }

    private func label(_ node: PreviewNode) -> some View {
        let isCurrent: Bool = node.step == .current
        return VStack(spacing: 1) {
            Text(eyebrow(node))
                .font(.jakarta(size: 9.5, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(eyebrowColor(node.step))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(node.course.title)
                .font(.jakarta(size: isCurrent ? 12 : 11.5, weight: isCurrent ? .bold : .semibold))
                .foregroundStyle(node.step == .locked ? OV2.inkTertiary : OV2.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            if isCurrent {
                startPill
                    .padding(.top, 3)
            }
        }
    }

    private var startPill: some View {
        Text(languageManager.text("home.start"))
            .font(.jakarta(size: 11.5, weight: .semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(DS.accent))
    }

    /// « COURS 3 », suivi de « À LIRE » pour le cours du jour.
    private func eyebrow(_ node: PreviewNode) -> String {
        let number: String = String(format: languageManager.text("onboardingV2.elevate.path.course"), node.index + 1)
        guard node.step == .current else { return number.uppercasedInApp() }
        let toRead: String = languageManager.text("onboardingV2.elevate.path.toRead")
        return "\(number) · \(toRead)".uppercasedInApp()
    }

    private func eyebrowColor(_ step: Step) -> Color {
        switch step {
        case .done: Self.doneInk
        case .current: DS.accent
        case .locked: OV2.inkTertiary
        }
    }

    // MARK: - Données

    /// Le premier niveau du Parcours et ses quatre premiers cours ; le recommandeur complète
    /// si le niveau en compte moins dans la langue.
    private func loadLevel() {
        guard nodes.isEmpty else { return }
        let language: AppLanguage = languageManager.current
        let collections: [LearningCollection] = ContentCatalog.collections(for: language)
        let collection: LearningCollection? = collections.first(where: { $0.courseIds.count >= Self.steps.count })
            ?? collections.first(where: { !$0.courseIds.isEmpty })

        var courses: [Course] = []
        if let collection {
            let found: [Course] = collection.courseIds.compactMap { ContentCatalog.course(withId: $0, language: language) }
            courses = Array(found.prefix(Self.steps.count))
        }
        if courses.count < Self.steps.count {
            let known: Set<String> = Set(courses.map(\.id))
            let fill: [Course] = OnboardingV2IntroCatalog.featuredCourses(language: language).filter { !known.contains($0.id) }
            courses.append(contentsOf: fill.prefix(Self.steps.count - courses.count))
        }

        levelTitle = collection?.title ?? languageManager.text("path.title")
        levelCourseCount = max(collection?.courseIds.count ?? 0, courses.count)

        var built: [PreviewNode] = []
        for (index, course) in courses.enumerated() {
            built.append(PreviewNode(
                id: course.id,
                course: course,
                cover: OnboardingV2IntroCatalog.coverThumbnail(for: course.id),
                step: Self.steps[min(index, Self.steps.count - 1)],
                index: index
            ))
        }
        nodes = built
    }

    // MARK: - Animation

    private func play() {
        guard !shown else { return }
        shown = true
        guard !reduceMotion else { return }
        for index in nodes.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + Double(index) * 0.28) {
                Haptics.tick(0.4)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + Double(nodes.count) * 0.28) {
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
}

/// Segment droit entre deux cours de l'aperçu.
private struct OnboardingV2PathLink: Shape {
    let start: CGPoint
    let end: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }
}
