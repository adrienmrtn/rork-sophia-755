import Foundation

/// Credit metadata for an inline course image.
nonisolated struct ImageCredit: Decodable, Sendable {
    let title: String
    let author: String
    let license: String
    let source: String

    /// Discreet caption displayed under an image: `Nom original — Auteur (Licence)`.
    var formatted: String {
        var parts: [String] = []
        if !title.isEmpty { parts.append(title) }
        if !author.isEmpty { parts.append("— \(author)") }
        var base = parts.joined(separator: " ")
        if !license.isEmpty {
            base += base.isEmpty ? license : " (\(license))"
        }
        return base
    }
}

/// Loads `image_credits.json` once and exposes credits keyed by image slug.
final class ImageCreditStore {
    static let shared = ImageCreditStore()

    private let credits: [String: ImageCredit]

    private init() {
        guard
            let url = Bundle.main.url(forResource: "image_credits", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([String: ImageCredit].self, from: data)
        else {
            self.credits = [:]
            return
        }
        self.credits = decoded
    }

    func credit(for slug: String) -> ImageCredit? {
        credits[slug]
    }
}
