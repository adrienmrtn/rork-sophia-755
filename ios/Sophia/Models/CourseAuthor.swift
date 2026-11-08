import Foundation

/// A professor who wrote one or more courses.
///
/// Source of truth: `content/authors.json`, compiled by `scripts/build_courses.py` into the
/// bundled `Resources/authors.json`, where each author also carries the ids of the courses
/// that name it (`author` field of the course JSON). The pedigree line (`title`) and the
/// biography are keyed by language code; `localized(_:)` falls back to English, then French.
nonisolated struct CourseAuthor: Decodable, Sendable, Identifiable, Hashable {
    let slug: String
    let name: String
    /// File name (no extension) under `Resources/AuthorPhotos`; nil shows the initials.
    let photo: String?
    /// Portrait hébergé d'un créateur du Studio (`creators.photo_url`), affiché quand il n'y a pas
    /// de ressource embarquée ; `AuthorStore.remotePhoto(for:)` le télécharge et le garde en cache.
    let photoUrl: String?
    let institution: String?
    let country: String?
    let links: [String: String]?
    let title: [String: String]?
    let bio: [String: String]?
    let courseIds: [String]
    /// Expert vérifié (diplôme ou fonction contrôlés par l'équipe). Absent dans les fichiers
    /// actuels : tous les auteurs embarqués sont des universitaires, donc vérifiés par défaut.
    /// Le Studio (prompt 5) posera la valeur explicitement pour les nouveaux créateurs.
    let verified: Bool?

    var id: String { slug }

    var isVerified: Bool { verified ?? true }

    nonisolated static func == (lhs: CourseAuthor, rhs: CourseAuthor) -> Bool { lhs.slug == rhs.slug }
    nonisolated func hash(into hasher: inout Hasher) { hasher.combine(slug) }

    /// Pedigree line, e.g. "Docteure en sciences biomédicales, Boston University".
    func title(for language: AppLanguage) -> String? {
        Self.localized(title, language: language)
    }

    func bio(for language: AppLanguage) -> String? {
        Self.localized(bio, language: language)
    }

    /// Up to two initials for the avatar fallback: "Dusan Nikolic" → "DN".
    var initials: String {
        let parts = name
            .split(whereSeparator: { $0 == " " || $0 == "-" })
            .filter { !$0.isEmpty }
        let picked = parts.count >= 2 ? [parts[0], parts[parts.count - 1]] : Array(parts.prefix(1))
        return picked.compactMap { $0.first }.map { String($0).uppercased() }.joined()
    }

    private static func localized(_ table: [String: String]?, language: AppLanguage) -> String? {
        guard let table else { return nil }
        for code in [language.rawValue, "en", "fr"] {
            if let value = table[code]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                return value
            }
        }
        return table.values.first { !$0.isEmpty }
    }
}
