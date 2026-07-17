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
}

extension ContentBlockV2: Decodable {
    private enum CodingKeys: String, CodingKey {
        case type, text, asset, ratio, caption, credit, fullBleed, events, attribution
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
                    fullBleed: try container.decodeIfPresent(Bool.self, forKey: .fullBleed)
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
