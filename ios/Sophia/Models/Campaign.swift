import Foundation

/// Un événement éditorial (« Movember », une semaine thématique…) : une collection de cours à
/// lire pendant une période, un défi avec un badge, et des cours annoncés en écriture.
///
/// Mêmes champs que la table `campaigns` côté serveur, servie par le manifeste du catalogue
/// (clé `events`, voir docs/evenements.md) ; `CampaignStore` lit ce que `CatalogStore` a reçu.
/// Les textes sont donnés par langue (`fr`, `en`…) et retombent sur l'anglais puis le français.
nonisolated struct Campaign: Decodable, Identifiable, Sendable, Hashable {
    nonisolated struct Upcoming: Decodable, Sendable, Hashable {
        let title: [String: String]
        /// Slug d'auteur (`CourseAuthor.slug`), s'il est connu.
        let creator: String?
        /// Date de sortie annoncée, `yyyy-MM-dd`.
        let date: String

        func title(for language: AppLanguage) -> String {
            Campaign.localized(title, language: language)
        }
    }

    let slug: String
    /// Le type standard : `month`, `week`, `day` ou `series`. Réservé (les apps n'en font rien encore).
    let kind: String?
    /// Symbole SF illustrant l'événement (`mustache.fill`), parmi la liste standard de docs/evenements.md.
    let symbol: String?
    /// Image 16:9 hébergée (bucket course-images), en tête de la carte du fil et de la page ;
    /// sans elle, la carte reste bleu nuit avec le symbole.
    let imageUrl: String?
    /// L'objectif commun : cours de la collection à terminer tous lecteurs confondus pendant
    /// l'événement, et où on en est (recalculé toutes les heures côté serveur). Nil : pas d'objectif.
    let goalTarget: Int?
    let goalCount: Int?
    let startsAt: String
    let endsAt: String
    /// Nombre de cours de la collection à terminer pour obtenir le badge.
    let challengeTarget: Int
    /// Lecteurs participants affichés (valeur de test tant que le serveur ne compte pas).
    let participants: Int
    let courseIds: [String]
    let upcoming: [Upcoming]
    let title: [String: String]
    let tagline: [String: String]
    let description: [String: String]
    let badgeName: [String: String]

    var id: String { slug }

    nonisolated static func == (lhs: Campaign, rhs: Campaign) -> Bool { lhs.slug == rhs.slug }
    nonisolated func hash(into hasher: inout Hasher) { hasher.combine(slug) }

    enum CodingKeys: String, CodingKey {
        case slug, kind, symbol, upcoming, title, tagline, description, participants
        case imageUrl = "image_url"
        case goalTarget = "goal_target"
        case goalCount = "goal_count"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case challengeTarget = "challenge_target"
        case courseIds = "course_ids"
        case badgeName = "badge_name"
    }

    func title(for language: AppLanguage) -> String { Self.localized(title, language: language) }
    func tagline(for language: AppLanguage) -> String { Self.localized(tagline, language: language) }
    func description(for language: AppLanguage) -> String { Self.localized(description, language: language) }
    func badgeName(for language: AppLanguage) -> String { Self.localized(badgeName, language: language) }

    var startDate: Date? { Self.parseDay(startsAt) }
    var endDate: Date? { Self.parseDay(endsAt) }

    /// Actif entre le premier jour et la fin du dernier jour.
    func isActive(on date: Date = Date()) -> Bool {
        guard let start = startDate, let end = endDate else { return false }
        let endOfLastDay = Calendar.current.date(byAdding: .day, value: 1, to: end) ?? end
        return date >= start && date < endOfLastDay
    }

    /// `yyyy-MM-dd` → minuit local de ce jour. Un formateur par appel : les dates sont rares
    /// et un `DateFormatter` partagé n'est pas sûr entre acteurs.
    nonisolated static func parseDay(_ text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: text)
    }

    nonisolated static func localized(_ table: [String: String], language: AppLanguage) -> String {
        for code in [language.rawValue, "en", "fr"] {
            if let value = table[code]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                return value
            }
        }
        return table.values.first ?? ""
    }
}
