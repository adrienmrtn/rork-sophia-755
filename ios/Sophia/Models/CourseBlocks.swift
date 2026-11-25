import CoreGraphics
import Foundation

/// Structured ("v2") course content model.
///
/// A course is authored as an ordered list of typed blocks per section, replacing the
/// legacy single-string markup. Source of truth lives in `content/courses/fr/<id>.json`
/// and is compiled into the bundled resource `Resources/CoursesV2/<id>.<lang>.json`.

nonisolated struct CourseHeroV2: Decodable, Sendable {
    let image: String
    let ratio: String?
    let credit: String?
    let hook: String?
}

nonisolated struct KeyDateV2: Decodable, Sendable, Identifiable {
    let date: String
    let label: String
    var id: String { "\(date)|\(label)" }
}

nonisolated struct TimelineEventV2: Decodable, Sendable, Identifiable {
    let date: String
    let title: String
    let detail: String?
    var id: String { "\(date)|\(title)" }
}

nonisolated struct ImageBlockV2: Decodable, Sendable {
    let asset: String
    let ratio: String?
    let caption: String?
    let credit: String?
    let fullBleed: Bool?
    /// Image guidée : les arrêts à parcourir (cadrage, texte, contour éventuel). Absent ou
    /// vide pour une image simple. Un lecteur qui ne connaît pas ce champ affiche l'image
    /// et sa légende, comme avant.
    var stops: [GuideStopV2]? = nil
}

/// Un contour tracé sur une image guidée, en fractions de l'image (0 à 1).
nonisolated struct GuideShapeV2: Decodable, Sendable {
    /// Ellipse : `[centreX, centreY, rayonX, rayonY]`.
    let ellipse: [Double]?
    /// Polygone fermé : `[[x, y], …]`, arrondi sauf si `sharp`.
    let polygon: [[Double]]?
    let sharp: Bool?
}

/// Un arrêt d'une image guidée : où regarder, à quel grossissement, et ce qu'on en dit.
nonisolated struct GuideStopV2: Decodable, Sendable {
    /// Point visé, en fractions de l'image.
    let x: Double
    let y: Double
    /// Grossissement (1 = l'image entière).
    let zoom: Double
    let text: String
    /// Contour à tracer une fois le cadrage posé. Réservé aux détails difficiles à repérer.
    let outline: [GuideShapeV2]?
}

/// Une étiquette posée sur une carte guidée.
nonisolated struct MapLabelV2: Decodable, Sendable, Identifiable {
    let id: String
    let lon: Double
    let lat: Double
    let text: String
    /// `city`, `sea`, `tag`, `tagNorth`, `tagSouth` ou `plain`.
    let style: String?
}

/// Un tracé sur une carte guidée (itinéraire, frontière, liaison), en longitude et latitude.
nonisolated struct MapRouteV2: Decodable, Sendable, Identifiable {
    let id: String
    /// `ink`, `boundary`, `accent`, `alt` ou `gold`.
    let style: String?
    let points: [[Double]]
}

/// Une étape d'une carte guidée.
nonisolated struct MapStepV2: Decodable, Sendable {
    /// `[longitude du centre, latitude du centre, hauteur visible en degrés]`.
    let view: [Double]
    /// Ce qui est visible à cette étape : identifiants d'étiquettes, de tracés, de zones
    /// du fond de carte, et `dots` pour les points.
    let show: [String]?
    let text: String
}

/// Une carte guidée : un fond de carte embarqué (`Resources/Maps/<map>.json`), des
/// étiquettes, des tracés et une suite d'étapes.
nonisolated struct MapBlockV2: Decodable, Sendable {
    let map: String
    let ratio: String?
    let labels: [MapLabelV2]?
    let routes: [MapRouteV2]?
    let dots: [[Double]]?
    let steps: [MapStepV2]
}

/// Une question posée dans le fil du cours, sur ce qu'on vient de lire.
nonisolated struct QuestionBlockV2: Decodable, Sendable {
    /// `choice` (une bonne réponse parmi `options`), `truefalse` (deux options) ou
    /// `order` (`items` à remettre dans l'ordre, donnés dans le bon ordre).
    let kind: String
    let prompt: String
    let options: [String]?
    /// Index de la bonne réponse dans `options`.
    let answer: Int?
    let items: [String]?
    /// `order` : ce qui s'affiche à droite de chaque élément une fois validé (une date).
    let labels: [String]?
    let explanation: String?
}

/// A single ordered content block within a section.
nonisolated enum ContentBlockV2: Sendable {
    case heading(String)
    case paragraph(String)
    case image(ImageBlockV2)
    case timeline([TimelineEventV2])
    case funFact(String)
    case takeaway(String)
    case quote(text: String, attribution: String?)
    case map(MapBlockV2)
    case question(QuestionBlockV2)

    /// Nombre d'arrêts d'un bloc guidé (image guidée ou carte) ; 0 pour tout autre bloc.
    var guideStopCount: Int {
        switch self {
        case .image(let image): return image.stops?.count ?? 0
        case .map(let map): return map.steps.count
        default: return 0
        }
    }
}

extension ContentBlockV2: Decodable {
    private enum CodingKeys: String, CodingKey {
        case type, text, asset, ratio, caption, credit, fullBleed, events, attribution, stops
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "heading":
            self = .heading(try container.decode(String.self, forKey: .text))
        case "paragraph":
            self = .paragraph(try container.decode(String.self, forKey: .text))
        case "image":
            self = .image(
                ImageBlockV2(
                    asset: try container.decode(String.self, forKey: .asset),
                    ratio: try container.decodeIfPresent(String.self, forKey: .ratio),
                    caption: try container.decodeIfPresent(String.self, forKey: .caption),
                    credit: try container.decodeIfPresent(String.self, forKey: .credit),
                    fullBleed: try container.decodeIfPresent(Bool.self, forKey: .fullBleed),
                    stops: try container.decodeIfPresent([GuideStopV2].self, forKey: .stops)
                )
            )
        case "timeline":
            self = .timeline(try container.decode([TimelineEventV2].self, forKey: .events))
        case "funFact":
            self = .funFact(try container.decode(String.self, forKey: .text))
        case "takeaway":
            self = .takeaway(try container.decode(String.self, forKey: .text))
        case "quote":
            self = .quote(
                text: try container.decode(String.self, forKey: .text),
                attribution: try container.decodeIfPresent(String.self, forKey: .attribution)
            )
        case "map":
            self = .map(try MapBlockV2(from: decoder))
        case "question":
            self = .question(try QuestionBlockV2(from: decoder))
        default:
            // Forward-compatible: unknown block types degrade to a paragraph (or empty).
            self = .paragraph((try? container.decode(String.self, forKey: .text)) ?? "")
        }
    }
}

nonisolated struct CourseSectionV2: Decodable, Sendable, Identifiable {
    let id: String
    let title: String
    let free: Bool?
    let blocks: [ContentBlockV2]
}

/// A bibliographic reference listed under a professor-authored course. Only the
/// reference is shown (never the claim it backs), in its original language.
nonisolated struct CourseSourceV2: Decodable, Sendable, Identifiable {
    let text: String
    let url: String?
    var id: String { text }

    var linkURL: URL? {
        guard let url, let parsed = URL(string: url), parsed.scheme?.hasPrefix("http") == true else {
            return nil
        }
        return parsed
    }
}

nonisolated struct CourseGlossaryTermV2: Decodable, Sendable {
    let term: String
    let classification: String?
    let explanation: String
}

nonisolated struct CourseContentV2: Decodable, Sendable {
    let id: String
    let title: String
    let subtitle: String?
    let subject: String?
    let subcategory: String?
    let description: String?
    let hero: CourseHeroV2?
    let keyDates: [KeyDateV2]?
    let sections: [CourseSectionV2]
    let glossary: [CourseGlossaryTermV2]?
    /// Slug of the professor who wrote the course (see `AuthorStore`); nil for house content.
    let author: String?
    let sources: [CourseSourceV2]?
    /// Code de la langue d'écriture quand le cours est une traduction (« en » pour un cours
    /// écrit en anglais). Prévu pour les cours de créateurs (prompt 3) ; vide aujourd'hui.
    let originalLanguage: String?
}

/// Parses ratio specs like "16:9", "4:3", "1", or "auto" into a width/height ratio.
nonisolated enum AspectRatioSpec {
    /// Returns nil for "auto"/invalid so callers fall back to the image's natural ratio.
    static func value(from string: String?) -> CGFloat? {
        guard let raw = string?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        if raw.lowercased() == "auto" { return nil }
        let parts = raw.split(separator: ":")
        if parts.count == 2,
           let width = Double(parts[0]),
           let height = Double(parts[1]),
           height > 0 {
            return CGFloat(width / height)
        }
        if let single = Double(raw), single > 0 {
            return CGFloat(single)
        }
        return nil
    }
}
