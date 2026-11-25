import SwiftUI
import UIKit

// Les blocs guidés du lecteur : une image (ou une carte, voir `CourseGuidedMapView`) qu'on
// parcourt arrêt par arrêt. Chaque arrêt recadre l'image, change le texte, et peut tracer un
// contour autour d'un détail difficile à repérer.
//
// En lecture pas à pas, c'est le bouton « Continuer » qui fait avancer : la position de chaque
// bloc vit dans `CourseGuideState`, rangée par passage. En lecture par pages (ou hors du
// lecteur), le bloc garde sa position lui-même et avance au toucher.

// MARK: - Position des blocs guidés

/// Où en est chaque bloc guidé du fil, par identifiant de passage.
@Observable
final class CourseGuideState {
    var positions: [String: Int] = [:]

    func position(_ key: String) -> Int {
        positions[key] ?? 0
    }

    /// Passe à l'arrêt suivant du bloc `key`. Faux s'il n'en reste pas (ou si le bloc n'est
    /// pas guidé) : l'appelant révèle alors le passage suivant.
    func advance(_ key: String, total: Int) -> Bool {
        let current = position(key)
        guard total > 1, current < total - 1 else { return false }
        positions[key] = current + 1
        return true
    }
}

private struct CourseGuideKeyKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

extension EnvironmentValues {
    /// L'identifiant du passage en cours de rendu, en lecture pas à pas ; nil ailleurs.
    var courseGuideKey: String? {
        get { self[CourseGuideKeyKey.self] }
        set { self[CourseGuideKeyKey.self] = newValue }
    }
}

// MARK: - Pièces communes

/// Les petits traits sous un bloc guidé : un par arrêt, pleins jusqu'à l'arrêt en cours.
struct GuideDots: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<max(count, 1), id: \.self) { item in
                Capsule()
                    .fill(item <= index ? DS.accent : DS.hairline.opacity(0.75))
                    .frame(width: 22, height: 5)
            }
        }
        .animation(DS.Motion.snappy, value: index)
        .accessibilityElement()
        .accessibilityValue(Text("\(index + 1) / \(count)"))
    }
}

/// Le texte d'un arrêt : même rendu que la prose du cours (gras, termes du glossaire).
struct GuideCaption: View {
    let text: String
    let index: Int
    let accent: Color
    let courseId: String
    let courseTitle: String
    let onGlossaryTap: (GlossaryEntry) -> Void

    var body: some View {
        ProseParagraph(
            raw: text,
            accent: accent,
            courseId: courseId,
            courseTitle: courseTitle,
            onGlossaryTap: onGlossaryTap
        )
        // Un arrêt = un paragraphe neuf : `ProseParagraph` garde son texte mis en forme.
        .id(index)
        .transition(.opacity)
    }
}

// MARK: - Contours

/// Le tracé des contours d'un arrêt, dans le rectangle de l'image.
private struct GuideOutlineShape: Shape {
    let shapes: [GuideShapeV2]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for shape in shapes {
            if let ellipse = shape.ellipse, ellipse.count == 4 {
                let centerX = CGFloat(ellipse[0]) * rect.width
                let centerY = CGFloat(ellipse[1]) * rect.height
                let radiusX = CGFloat(ellipse[2]) * rect.width
                let radiusY = CGFloat(ellipse[3]) * rect.height
                path.addEllipse(in: CGRect(
                    x: rect.minX + centerX - radiusX,
                    y: rect.minY + centerY - radiusY,
                    width: radiusX * 2,
                    height: radiusY * 2
                ))
            } else if let polygon = shape.polygon {
                var points: [CGPoint] = []
                for pair in polygon where pair.count == 2 {
                    points.append(CGPoint(
                        x: rect.minX + CGFloat(pair[0]) * rect.width,
                        y: rect.minY + CGFloat(pair[1]) * rect.height
                    ))
                }
                let count = points.count
                if count < 3 { continue }
                // Arrondi de type Catmull-Rom ; `sharp` garde des angles vifs.
                let tension: CGFloat = shape.sharp == true ? 0 : 1.0 / 6.0
                path.move(to: points[0])
                for index in 0..<count {
                    let before = points[(index - 1 + count) % count]
                    let from = points[index]
                    let to = points[(index + 1) % count]
                    let after = points[(index + 2) % count]
                    let control1 = CGPoint(
                        x: from.x + (to.x - before.x) * tension,
                        y: from.y + (to.y - before.y) * tension
                    )
                    let control2 = CGPoint(
                        x: to.x - (after.x - from.x) * tension,
                        y: to.y - (after.y - from.y) * tension
                    )
                    path.addCurve(to: to, control1: control1, control2: control2)
                }
                path.closeSubpath()
            }
        }
        return path
    }
}

/// Le voile qui assombrit tout sauf l'intérieur des contours (remplissage pair-impair).
private struct GuideDimShape: Shape {
    let shapes: [GuideShapeV2]

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        path.addPath(GuideOutlineShape(shapes: shapes).path(in: rect))
        return path
    }
}

/// Voile et contour posés sur l'image. `lineScale` est le grossissement en cours : le trait
/// garde la même épaisseur à l'écran quel que soit le zoom.
private struct GuideOutlineLayer: View {
    let shapes: [GuideShapeV2]
    let shown: Bool
    let drawn: Bool
    let lineScale: CGFloat

    var body: some View {
        ZStack {
            GuideDimShape(shapes: shapes)
                .fill(Color.black.opacity(0.58), style: FillStyle(eoFill: true))
            GuideOutlineShape(shapes: shapes)
                .trim(from: 0, to: drawn ? 1 : 0)
                .stroke(
                    DS.warm.opacity(0.55),
                    style: StrokeStyle(lineWidth: 7 / max(lineScale, 1), lineCap: .round, lineJoin: .round)
                )
            GuideOutlineShape(shapes: shapes)
                .trim(from: 0, to: drawn ? 1 : 0)
                .stroke(
                    Color.white,
                    style: StrokeStyle(lineWidth: 2.5 / max(lineScale, 1), lineCap: .round, lineJoin: .round)
                )
        }
        .opacity(shown ? 1 : 0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Image guidée

/// Une image qu'on parcourt arrêt par arrêt : recadrage, texte, contour éventuel.
struct GuidedImageView: View {
    let block: ImageBlockV2
    let stops: [GuideStopV2]
    let accent: Color
    let courseId: String
    let courseTitle: String
    let onGlossaryTap: (GlossaryEntry) -> Void

    @Environment(CourseGuideState.self) private var guide: CourseGuideState?
    @Environment(\.courseGuideKey) private var guideKey
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Position hors du lecteur pas à pas (lecture par pages).
    @State private var localIndex = 0
    @State private var image: UIImage?
    @State private var failed = false
    /// Contours affichés. Gardés pendant le fondu de sortie, remplacés une fois le cadrage posé.
    @State private var outlineShapes: [GuideShapeV2] = []
    @State private var outlineShown = false
    @State private var outlineDrawn = false

    /// Durée du recadrage : le contour attend qu'il soit terminé.
    private static let moveDuration: Double = 0.9

    init(
        block: ImageBlockV2,
        stops: [GuideStopV2],
        accent: Color,
        courseId: String,
        courseTitle: String,
        onGlossaryTap: @escaping (GlossaryEntry) -> Void
    ) {
        self.block = block
        self.stops = stops
        self.accent = accent
        self.courseId = courseId
        self.courseTitle = courseTitle
        self.onGlossaryTap = onGlossaryTap
        _image = State(initialValue: CourseImageLoader.cached(block.asset))
    }

    private var index: Int {
        var raw = localIndex
        if let guideKey, let guide {
            raw = guide.position(guideKey)
        }
        return min(max(raw, 0), max(stops.count - 1, 0))
    }

    private var ratio: CGFloat {
        if let explicit = AspectRatioSpec.value(from: block.ratio) { return explicit }
        if let image, image.size.height > 0 { return image.size.width / image.size.height }
        return 3.0 / 2.0
    }

    private var creditText: String? {
        if let credit = block.credit, !credit.isEmpty { return credit }
        return ImageCreditStore.shared.credit(for: CourseInlineImage.slug(block.asset))?.formatted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            imageFrame

            GuideDots(count: stops.count, index: index)

            if stops.indices.contains(index) {
                GuideCaption(
                    text: stops[index].text,
                    index: index,
                    accent: accent,
                    courseId: courseId,
                    courseTitle: courseTitle,
                    onGlossaryTap: onGlossaryTap
                )
            }

            if let creditText, !creditText.isEmpty {
                Text(creditText)
                    .font(DS.sans(.caption2))
                    .foregroundStyle(DS.inkTertiary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: index)
        .task(id: block.asset) {
            guard image == nil else { return }
            let loaded = await CourseImageLoader.image(for: block.asset)
            image = loaded
            failed = loaded == nil
        }
        .task(id: index) {
            await showOutline(for: index)
        }
    }

    private var imageFrame: some View {
        Color.clear
            .aspectRatio(ratio, contentMode: .fit)
            .overlay {
                GeometryReader { geometry in
                    let size = geometry.size
                    let stop = stops.indices.contains(index) ? stops[index] : nil
                    let scale = CGFloat(max(stop?.zoom ?? 1, 1))
                    ZStack {
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: size.width, height: size.height)
                        } else if failed {
                            ImagePlaceholderFallback(label: block.asset)
                        } else {
                            ProgressView()
                        }
                        GuideOutlineLayer(
                            shapes: outlineShapes,
                            shown: outlineShown,
                            drawn: outlineDrawn,
                            lineScale: scale
                        )
                    }
                    .frame(width: size.width, height: size.height)
                    .scaleEffect(scale, anchor: .topLeading)
                    .offset(Self.offset(x: stop?.x ?? 0.5, y: stop?.y ?? 0.5, scale: scale, size: size))
                    .animation(reduceMotion ? nil : .easeInOut(duration: Self.moveDuration), value: index)
                }
            }
            .clipShape(.rect(cornerRadius: DS.Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                    .strokeBorder(DS.hairline, lineWidth: 1)
            }
            .contentShape(Rectangle())
            .onTapGesture { advance() }
            .accessibilityElement()
            .accessibilityAddTraits(.isImage)
            .accessibilityLabel(Text(block.caption ?? ""))
    }

    /// Décalage qui amène le point visé au centre du cadre, sans jamais découvrir un bord.
    private static func offset(x: Double, y: Double, scale: CGFloat, size: CGSize) -> CGSize {
        let rawX = (0.5 - CGFloat(x) * scale) * size.width
        let rawY = (0.5 - CGFloat(y) * scale) * size.height
        let minX = -(scale - 1) * size.width
        let minY = -(scale - 1) * size.height
        return CGSize(width: min(0, max(minX, rawX)), height: min(0, max(minY, rawY)))
    }

    /// Toucher l'image passe à l'arrêt suivant, comme « Continuer ».
    private func advance() {
        guard index < stops.count - 1 else { return }
        Haptics.tap()
        if let guideKey, let guide {
            _ = guide.advance(guideKey, total: stops.count)
        } else {
            localIndex = index + 1
        }
    }

    /// Le contour d'un arrêt : l'ancien s'efface tout de suite, le nouveau n'apparaît qu'une
    /// fois le recadrage terminé (on recule ou on avance d'abord, on entoure ensuite).
    private func showOutline(for target: Int) async {
        withAnimation(.easeOut(duration: 0.2)) {
            outlineShown = false
        }
        outlineDrawn = false
        guard stops.indices.contains(target) else { return }
        let stop = stops[target]
        let shapes = stop.outline ?? []
        guard !shapes.isEmpty else { return }

        var moved = false
        if target > 0, stops.indices.contains(target - 1) {
            let previous = stops[target - 1]
            moved = previous.x != stop.x || previous.y != stop.y || previous.zoom != stop.zoom
        }
        if !reduceMotion {
            let wait = moved ? Self.moveDuration + 0.15 : 0.25
            try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
        }
        if Task.isCancelled { return }

        outlineShapes = shapes
        withAnimation(.easeOut(duration: 0.45)) {
            outlineShown = true
        }
        if reduceMotion {
            outlineDrawn = true
        } else {
            withAnimation(.easeInOut(duration: 0.9).delay(0.1)) {
                outlineDrawn = true
            }
        }
    }
}

/// Cadre gris quand l'image n'existe nulle part (ni bundle, ni cache, ni bucket).
private struct ImagePlaceholderFallback: View {
    let label: String

    var body: some View {
        ZStack {
            DS.surfaceMuted
            Text(label)
                .font(DS.sans(.caption, .medium))
                .foregroundStyle(DS.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
    }
}
