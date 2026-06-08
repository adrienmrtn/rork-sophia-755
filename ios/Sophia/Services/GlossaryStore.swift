import SwiftUI

enum GlossaryClassification: String, CaseIterable, Sendable {
    case referenceHistorique = "Référence historique"
    case concept = "Concept"
    case evenementConnexe = "Événement connexe"
    case personnage = "Personnage"
    case lieuInstitution = "Lieu / institution"

    init?(classification: String) {
        switch classification {
        case Self.referenceHistorique.rawValue: self = .referenceHistorique
        case Self.concept.rawValue: self = .concept
        case Self.evenementConnexe.rawValue: self = .evenementConnexe
        case Self.personnage.rawValue: self = .personnage
        case Self.lieuInstitution.rawValue: self = .lieuInstitution
        default: return nil
        }
    }

    init?(catalogKey: String) {
        switch catalogKey {
        case "referenceHistorique": self = .referenceHistorique
        case "concept": self = .concept
        case "evenementConnexe": self = .evenementConnexe
        case "personnage": self = .personnage
        case "lieuInstitution": self = .lieuInstitution
        default: return nil
        }
    }

    func localizedShortLabel(language: AppLanguage) -> String {
        switch (self, language) {
        case (.referenceHistorique, .english): "Reference"
        case (.concept, .english): "Concept"
        case (.evenementConnexe, .english): "Event"
        case (.personnage, .english): "Figure"
        case (.lieuInstitution, .english): "Place"
        case (.referenceHistorique, .spanish): "Referencia"
        case (.concept, .spanish): "Concepto"
        case (.evenementConnexe, .spanish): "Evento"
        case (.personnage, .spanish): "Figura"
        case (.lieuInstitution, .spanish): "Lugar"
        default: shortLabel
        }
    }

    var pastel: Color {
        switch self {
        case .referenceHistorique:
            Color(red: 1.0, green: 0.86, blue: 0.62)
        case .concept:
            Color(red: 0.74, green: 0.90, blue: 1.0)
        case .evenementConnexe:
            Color(red: 0.70, green: 0.95, blue: 0.80)
        case .personnage:
            Color(red: 0.82, green: 0.78, blue: 1.0)
        case .lieuInstitution:
            Color(red: 1.0, green: 0.95, blue: 0.70)
        }
    }

    var shortLabel: String {
        switch self {
        case .referenceHistorique: "Référence"
        case .concept: "Concept"
        case .evenementConnexe: "Événement"
        case .personnage: "Personnage"
        case .lieuInstitution: "Lieu / institution"
        }
    }
}

struct GlossaryEntry: Sendable, Identifiable {
    let displayTerm: String
    let classification: GlossaryClassification
    let explanation: String

    var id: String { displayTerm }
}

enum GlossaryStore {
    private static func frenchKey(courseTitle: String, displayTerm: String) -> String {
        "\(courseTitle)|\(displayTerm)"
    }

    private static func localizedKey(courseId: String, displayTerm: String) -> String {
        "\(courseId)|\(displayTerm)"
    }

    private static func normKey(_ value: String) -> String {
        value.lowercased().unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }.map(String.init).joined()
    }

    static func entry(courseId: String, courseTitle: String, displayTerm: String) -> GlossaryEntry? {
        switch AppLanguage.currentPersisted() {
        case .english:
            return localizedEntry(courseId: courseId, displayTerm: displayTerm)
        case .spanish:
            if let entry = localizedEntry(courseId: courseId, displayTerm: displayTerm) {
                return entry
            }
            return frenchEntry(courseTitle: courseTitle, displayTerm: displayTerm)
        case .french:
            return frenchEntry(courseTitle: courseTitle, displayTerm: displayTerm)
        }
    }

    private static func localizedEntry(courseId: String, displayTerm: String) -> GlossaryEntry? {
        let language = AppLanguage.currentPersisted()
        let entries = LocalizedContentLoader.glossaryEntries(for: language)
        if let exact = entries[localizedKey(courseId: courseId, displayTerm: displayTerm)] {
            return exact
        }
        return fuzzyEntry(displayTerm: displayTerm, in: entries, prefix: "\(courseId)|")
    }

    private static func frenchEntry(courseTitle: String, displayTerm: String) -> GlossaryEntry? {
        if let exact = GlossaryData.entries[frenchKey(courseTitle: courseTitle, displayTerm: displayTerm)] {
            return exact
        }
        return fuzzyEntry(displayTerm: displayTerm, in: GlossaryData.entries, prefix: "\(courseTitle)|")
    }

    private static func fuzzyEntry(
        displayTerm: String,
        in entries: [String: GlossaryEntry],
        prefix: String
    ) -> GlossaryEntry? {
        let needle = normKey(displayTerm)
        guard needle.count >= 4 else { return nil }
        for (entryKey, entry) in entries where entryKey.hasPrefix(prefix) {
            let stored = String(entryKey.dropFirst(prefix.count))
            let hay = normKey(stored)
            if hay == needle { return entry }
            if needle.count >= 8, hay.contains(needle), Double(needle.count) / Double(hay.count) >= 0.45 {
                return GlossaryEntry(displayTerm: displayTerm, classification: entry.classification, explanation: entry.explanation)
            }
            if hay.count >= 8, needle.contains(hay), Double(hay.count) / Double(needle.count) >= 0.45 {
                return GlossaryEntry(displayTerm: displayTerm, classification: entry.classification, explanation: entry.explanation)
            }
        }
        return nil
    }

    static func linkURL(courseId: String, courseTitle: String, displayTerm: String) -> URL? {
        var components = URLComponents()
        components.scheme = "sophia-glossary"
        components.host = "term"
        components.queryItems = [
            URLQueryItem(name: "courseId", value: courseId),
            URLQueryItem(name: "course", value: courseTitle),
            URLQueryItem(name: "term", value: displayTerm),
        ]
        return components.url
    }

    static func entry(from url: URL) -> GlossaryEntry? {
        guard url.scheme == "sophia-glossary" else { return nil }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let term = items.first(where: { $0.name == "term" })?.value
        guard let term else { return nil }

        if let courseId = items.first(where: { $0.name == "courseId" })?.value {
            let courseTitle = items.first(where: { $0.name == "course" })?.value ?? ""
            return entry(courseId: courseId, courseTitle: courseTitle, displayTerm: term)
        }

        guard let course = items.first(where: { $0.name == "course" })?.value else { return nil }
        return entry(courseId: "", courseTitle: course, displayTerm: term)
    }
}
