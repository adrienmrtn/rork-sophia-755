import SwiftUI
import UIKit

// La carte guidée du lecteur : un fond de carte embarqué (frontières, fleuves et relief de
// Natural Earth, `Resources/Maps/<nom>.json`) sur lequel le cours pose ses étiquettes, ses
// tracés et ses points, étape par étape. Chaque étape recadre la carte et change le texte.
//
// Elle avance comme l'image guidée (`CourseGuidedImageView`) : avec « Continuer » en lecture
// pas à pas, au toucher sinon.

// MARK: - Fond de carte

/// Un fond de carte embarqué. Les coordonnées sont déjà projetées, en unités de carte :
/// `x = (lon - lon0) * k * cx`, `y = (lat0 - lat) * k`.
nonisolated struct BaseMapData: Decodable, Sendable {
    nonisolated struct Projection: Decodable, Sendable {
        let lon0: Double
        let lat0: Double
        let k: Double
        let cx: Double
    }

    /// Une zone du fond qu'une étape peut colorer (le Nord et le Sud du Vietnam).
    nonisolated struct Area: Decodable, Sendable {
        let id: String
        /// `north` ou `south`.
        let color: String?
        let rings: [[Double]]
    }

    let proj: Projection
    /// Les terres : un tableau par contour, `[x0, y0, x1, y1, …]`.
    let land: [[Double]]
    let areas: [Area]?
    let rivers: [[Double]]?
    /// Emprise de l'image de relief : `[x0, y0, x1, y1]`.
    let relief: [Double]?
    let reliefImage: String?
}

/// Une zone prête à dessiner.
struct BaseMapAreaLayer: Identifiable {
    let id: String
    let color: String
    let path: Path
}

/// Un fond de carte prêt à dessiner : les tracés sont calculés une fois.
struct BaseMapLayers {
    let projection: BaseMapData.Projection
    let land: Path
    let areas: [BaseMapAreaLayer]
    /// Terres et zones réunies : le masque du relief.
    let allLand: Path
    let rivers: Path
    /// Taille de la carte, en unités de carte.
    let size: CGSize
    let relief: UIImage?
    let reliefRect: CGRect

    func point(lon: Double, lat: Double) -> CGPoint {
        CGPoint(
            x: (lon - projection.lon0) * projection.k * projection.cx,
            y: (projection.lat0 - lat) * projection.k
        )
    }
}

/// Charge les fonds de carte du bundle et les garde en mémoire.
enum BaseMapStore {
    private static var cache: [String: BaseMapLayers] = [:]

    static func layers(named name: String) -> BaseMapLayers? {
        if let cached = cache[name] { return cached }
        let url = Bundle.main.url(forResource: name, withExtension: "json")
            ?? Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "Maps")
        guard let url,
              let raw = try? Data(contentsOf: url),
              let data = try? JSONDecoder().decode(BaseMapData.self, from: raw) else {
            return nil
        }

        let land = path(rings: data.land, closed: true)
        var allLand = land
        var areas: [BaseMapAreaLayer] = []
        for area in data.areas ?? [] {
            let areaPath = path(rings: area.rings, closed: true)
            allLand.addPath(areaPath)
            areas.append(BaseMapAreaLayer(id: area.id, color: area.color ?? "", path: areaPath))
        }

        var reliefRect = CGRect.zero
        var relief: UIImage? = nil
        if let box = data.relief, box.count == 4, let imageName = data.reliefImage {
            reliefRect = CGRect(x: box[0], y: box[1], width: box[2] - box[0], height: box[3] - box[1])
            relief = CourseInlineImage.loadImage(named: imageName)
        }

        let bounds = allLand.boundingRect.union(reliefRect)
        let layers = BaseMapLayers(
            projection: data.proj,
            land: land,
            areas: areas,
            allLand: allLand,
            rivers: path(rings: data.rivers ?? [], closed: false),
            size: CGSize(width: max(bounds.maxX, 1), height: max(bounds.maxY, 1)),
            relief: relief,
            reliefRect: reliefRect
        )
        cache[name] = layers
        return layers
    }

    private static func path(rings: [[Double]], closed: Bool) -> Path {
        var path = Path()
        for ring in rings where ring.count >= 4 {
            path.move(to: CGPoint(x: ring[0], y: ring[1]))
            var index = 2
            while index + 1 < ring.count {
                path.addLine(to: CGPoint(x: ring[index], y: ring[index + 1]))
                index += 2
            }
            if closed { path.closeSubpath() }
        }
        return path
    }
}

/// Les couleurs d'une carte : une mer et des terres neutres, deux teintes pour les camps.
private enum MapPalette {
    static let sea = Color(uiColor: DSAdaptive.color(light: (0.812, 0.878, 0.957), dark: (0.059, 0.094, 0.149)))
    static let land = Color(uiColor: DSAdaptive.color(light: (0.953, 0.941, 0.910), dark: (0.169, 0.192, 0.235)))
    static let highlight = Color(uiColor: DSAdaptive.color(light: (0.925, 0.851, 0.635), dark: (0.431, 0.392, 0.259)))
    static let north = Color(uiColor: DSAdaptive.color(light: (0.871, 0.580, 0.533), dark: (0.639, 0.322, 0.282)))
    static let south = Color(uiColor: DSAdaptive.color(light: (0.525, 0.659, 0.894), dark: (0.235, 0.388, 0.702)))

    static func area(_ name: String) -> Color {
        switch name {
        case "north": return north
        case "south": return south
        default: return highlight
        }
    }
}

// MARK: - Carte guidée

struct GuidedMapView: View {
    let block: MapBlockV2
    let accent: Color
    let courseId: String
    let courseTitle: String
    let onGlossaryTap: (GlossaryEntry) -> Void

    @Environment(CourseGuideState.self) private var guide: CourseGuideState?
    @Environment(\.courseGuideKey) private var guideKey
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Position hors du lecteur pas à pas (lecture par pages).
    @State private var localIndex = 0
    @State private var layers: BaseMapLayers?

    private var index: Int {
        var raw = localIndex
        if let guideKey, let guide {
            raw = guide.position(guideKey)
        }
        return min(max(raw, 0), max(block.steps.count - 1, 0))
    }

    private var ratio: CGFloat {
        AspectRatioSpec.value(from: block.ratio) ?? (5.0 / 6.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            mapFrame

            GuideDots(count: block.steps.count, index: index)

            if block.steps.indices.contains(index) {
                GuideCaption(
                    text: block.steps[index].text,
                    index: index,
                    accent: accent,
                    courseId: courseId,
                    courseTitle: courseTitle,
                    onGlossaryTap: onGlossaryTap
                )
            }

            Text("Natural Earth")
                .font(DS.sans(.caption2))
                .foregroundStyle(DS.inkTertiary)
                .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: index)
        .task(id: block.map) {
            if layers == nil {
                layers = BaseMapStore.layers(named: block.map)
            }
        }
    }

    private var mapFrame: some View {
        Color.clear
            .aspectRatio(ratio, contentMode: .fit)
            .overlay {
                GeometryReader { geometry in
                    mapContent(size: geometry.size)
                }
            }
            .background(MapPalette.sea)
            .clipShape(.rect(cornerRadius: DS.Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                    .strokeBorder(DS.hairline, lineWidth: 1)
            }
            .contentShape(Rectangle())
            .onTapGesture { advance() }
            .accessibilityElement()
            .accessibilityAddTraits(.isImage)
    }

    /// La carte entière, à l'échelle de l'étape : on dessine en unités de carte, puis on
    /// agrandit et on décale pour que la zone de l'étape remplisse le cadre.
    @ViewBuilder
    private func mapContent(size: CGSize) -> some View {
        if let layers, block.steps.indices.contains(index), size.width > 0, size.height > 0 {
            let step = block.steps[index]
            let box = viewBox(step.view, layers: layers, aspect: size.width / size.height)
            let zoom = size.height / max(box.height, 1)
            let shown = Set(step.show ?? [])

            MapCanvas(block: block, layers: layers, shown: shown, zoom: zoom, reduceMotion: reduceMotion)
                .frame(width: layers.size.width, height: layers.size.height, alignment: .topLeading)
                .scaleEffect(zoom, anchor: .topLeading)
                .offset(x: -box.minX * zoom, y: -box.minY * zoom)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.95), value: index)
                .frame(width: size.width, height: size.height, alignment: .topLeading)
        }
    }

    /// La zone visible d'une étape, en unités de carte.
    private func viewBox(_ view: [Double], layers: BaseMapLayers, aspect: CGFloat) -> CGRect {
        guard view.count == 3 else {
            return CGRect(origin: .zero, size: layers.size)
        }
        let center = layers.point(lon: view[0], lat: view[1])
        let height = CGFloat(view[2] * layers.projection.k)
        let width = height * aspect
        return CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
    }

    private func advance() {
        guard index < block.steps.count - 1 else { return }
        Haptics.tap()
        if let guideKey, let guide {
            _ = guide.advance(guideKey, total: block.steps.count)
        } else {
            localIndex = index + 1
        }
    }
}

// MARK: - Dessin

/// Le dessin de la carte en unités de carte. `zoom` sert à garder traits, points et
/// étiquettes à la même taille à l'écran quel que soit le cadrage.
private struct MapCanvas: View {
    let block: MapBlockV2
    let layers: BaseMapLayers
    let shown: Set<String>
    let zoom: CGFloat
    let reduceMotion: Bool

    private var hairline: CGFloat { 1.2 / max(zoom, 0.01) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ground
            relief
            layers.rivers
                .stroke(MapPalette.sea, style: StrokeStyle(lineWidth: 1.3 / max(zoom, 0.01), lineCap: .round, lineJoin: .round))
            routes
            dots
            labels
        }
    }

    @ViewBuilder
    private var ground: some View {
        layers.land.fill(MapPalette.land)
        layers.land.stroke(DS.canvas, lineWidth: hairline)
        ForEach(layers.areas) { area in
            area.path
                .fill(shown.contains(area.id) ? MapPalette.area(area.color) : MapPalette.highlight)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.7), value: shown.contains(area.id))
            area.path.stroke(DS.canvas, lineWidth: hairline)
        }
    }

    /// Le relief ombré, limité aux terres et fondu en multiplication : les ombres foncent
    /// la couleur du dessous, les aplats la laissent intacte.
    @ViewBuilder
    private var relief: some View {
        if let image = layers.relief, layers.reliefRect.width > 0 {
            Image(uiImage: image)
                .resizable()
                .frame(width: layers.reliefRect.width, height: layers.reliefRect.height)
                .offset(x: layers.reliefRect.minX, y: layers.reliefRect.minY)
                .frame(width: layers.size.width, height: layers.size.height, alignment: .topLeading)
                .mask { layers.allLand.fill(Color.black) }
                .blendMode(.multiply)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var routes: some View {
        ForEach(block.routes ?? []) { route in
            MapRouteView(
                path: routePath(route),
                style: route.style ?? "ink",
                visible: shown.contains(route.id),
                zoom: zoom,
                reduceMotion: reduceMotion
            )
        }
    }

    private func routePath(_ route: MapRouteV2) -> Path {
        var path = Path()
        var started = false
        for pair in route.points where pair.count == 2 {
            let point = layers.point(lon: pair[0], lat: pair[1])
            if started {
                path.addLine(to: point)
            } else {
                path.move(to: point)
                started = true
            }
        }
        return path
    }

    @ViewBuilder
    private var dots: some View {
        let visible = shown.contains("dots")
        ForEach(Array((block.dots ?? []).enumerated()), id: \.offset) { item in
            if item.element.count == 2 {
                Circle()
                    .fill(DS.warm)
                    .overlay { Circle().strokeBorder(DS.ink, lineWidth: 2) }
                    .frame(width: 13, height: 13)
                    .scaleEffect((visible ? 1 : 0.001) / max(zoom, 0.01))
                    .position(layers.point(lon: item.element[0], lat: item.element[1]))
                    .animation(reduceMotion ? nil : DS.Motion.pop.delay(Double(item.offset) * 0.07), value: visible)
            }
        }
    }

    @ViewBuilder
    private var labels: some View {
        ForEach(block.labels ?? []) { label in
            let visible = shown.contains(label.id)
            let isCity = label.style == "city"
            Color.clear
                .frame(width: 0, height: 0)
                .overlay(alignment: isCity ? .leading : .center) {
                    MapLabelView(label: label)
                        .fixedSize()
                        // Ville : le point noir, large de 11 pt, se pose sur le lieu.
                        .offset(x: isCity ? -5.5 : 0)
                }
                .scaleEffect(1 / max(zoom, 0.01))
                .position(layers.point(lon: label.lon, lat: label.lat))
                .opacity(visible ? 1 : 0)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.45), value: visible)
        }
    }
}

/// Un tracé : il se dessine d'un bout à l'autre quand son étape arrive.
private struct MapRouteView: View {
    let path: Path
    let style: String
    let visible: Bool
    let zoom: CGFloat
    let reduceMotion: Bool

    private var color: Color {
        switch style {
        case "accent": return DS.accent
        case "alt": return DS.danger
        case "gold": return DS.warm
        default: return DS.ink
        }
    }

    private var width: CGFloat {
        switch style {
        case "boundary": return 2.5
        case "gold": return 2
        case "ink": return 3.5
        default: return 3
        }
    }

    private var dash: [CGFloat] {
        switch style {
        case "boundary": return [6, 5]
        case "alt": return [7, 6]
        default: return []
        }
    }

    var body: some View {
        let scale = max(zoom, 0.01)
        path
            .trim(from: 0, to: visible ? 1 : 0)
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: width / scale,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: dash.map { $0 / scale }
                )
            )
            .opacity(visible ? 1 : 0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 1.4).delay(0.4), value: visible)
            .allowsHitTesting(false)
    }
}

/// Une étiquette de carte, dans l'un de ses styles.
private struct MapLabelView: View {
    let label: MapLabelV2

    var body: some View {
        switch label.style ?? "plain" {
        case "city":
            HStack(spacing: 6) {
                Circle()
                    .fill(DS.ink)
                    .overlay { Circle().strokeBorder(DS.canvas, lineWidth: 2.5) }
                    .frame(width: 11, height: 11)
                Text(label.text)
                    .font(DS.sans(.footnote, .bold))
                    .foregroundStyle(DS.ink)
                    .shadow(color: DS.canvas, radius: 2)
            }
        case "sea":
            Text(label.text)
                .font(DS.sans(.caption))
                .italic()
                .foregroundStyle(DS.inkSecondary)
        case "tag":
            tag(fill: DS.ink, text: DS.canvas)
        case "tagNorth":
            tag(fill: DS.danger, text: .white)
        case "tagSouth":
            tag(fill: DS.accent, text: .white)
        default:
            Text(label.text)
                .font(DS.sans(.caption2, .heavy))
                .tracking(0.9)
                .textCase(.uppercase)
                .foregroundStyle(DS.inkSecondary)
        }
    }

    private func tag(fill: Color, text: Color) -> some View {
        Text(label.text)
            .font(DS.sans(.caption2, .heavy))
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(text)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(fill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
