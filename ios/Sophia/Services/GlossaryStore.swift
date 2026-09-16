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

    /// Short label of the term's kind, in the language the reader chose.
    ///
    /// Only six languages were listed; the other twenty fell through to `shortLabel`
    /// and printed "PERSONNAGE" or "LIEU" in French above an otherwise translated
    /// glossary card. The table is now exhaustive over `AppLanguage`, so a language
    /// added later fails to compile here rather than silently reverting to French.
    func localizedShortLabel(language: AppLanguage) -> String {
        switch language {
        case .french:
            switch self {
            case .referenceHistorique: "Référence"
            case .concept: "Concept"
            case .evenementConnexe: "Événement"
            case .personnage: "Personnage"
            case .lieuInstitution: "Lieu"
            }
        case .english:
            switch self {
            case .referenceHistorique: "Reference"
            case .concept: "Concept"
            case .evenementConnexe: "Event"
            case .personnage: "Figure"
            case .lieuInstitution: "Place"
            }
        case .spanish:
            switch self {
            case .referenceHistorique: "Referencia"
            case .concept: "Concepto"
            case .evenementConnexe: "Evento"
            case .personnage: "Figura"
            case .lieuInstitution: "Lugar"
            }
        case .german:
            switch self {
            case .referenceHistorique: "Bezug"
            case .concept: "Konzept"
            case .evenementConnexe: "Ereignis"
            case .personnage: "Person"
            case .lieuInstitution: "Ort"
            }
        case .portuguese:
            switch self {
            case .referenceHistorique: "Referência"
            case .concept: "Conceito"
            case .evenementConnexe: "Evento"
            case .personnage: "Figura"
            case .lieuInstitution: "Lugar"
            }
        case .italian:
            switch self {
            case .referenceHistorique: "Riferimento"
            case .concept: "Concetto"
            case .evenementConnexe: "Evento"
            case .personnage: "Personaggio"
            case .lieuInstitution: "Luogo"
            }
        case .turkish:
            switch self {
            case .referenceHistorique: "Referans"
            case .concept: "Kavram"
            case .evenementConnexe: "Olay"
            case .personnage: "Kişi"
            case .lieuInstitution: "Yer"
            }
        case .polish:
            switch self {
            case .referenceHistorique: "Odniesienie"
            case .concept: "Pojęcie"
            case .evenementConnexe: "Wydarzenie"
            case .personnage: "Postać"
            case .lieuInstitution: "Miejsce"
            }
        case .romanian:
            switch self {
            case .referenceHistorique: "Referință"
            case .concept: "Concept"
            case .evenementConnexe: "Eveniment"
            case .personnage: "Personaj"
            case .lieuInstitution: "Loc"
            }
        case .dutch:
            switch self {
            case .referenceHistorique: "Verwijzing"
            case .concept: "Begrip"
            case .evenementConnexe: "Gebeurtenis"
            case .personnage: "Figuur"
            case .lieuInstitution: "Plaats"
            }
        case .greek:
            switch self {
            case .referenceHistorique: "Αναφορά"
            case .concept: "Έννοια"
            case .evenementConnexe: "Γεγονός"
            case .personnage: "Πρόσωπο"
            case .lieuInstitution: "Τόπος"
            }
        case .swedish:
            switch self {
            case .referenceHistorique: "Referens"
            case .concept: "Begrepp"
            case .evenementConnexe: "Händelse"
            case .personnage: "Person"
            case .lieuInstitution: "Plats"
            }
        case .hungarian:
            switch self {
            case .referenceHistorique: "Hivatkozás"
            case .concept: "Fogalom"
            case .evenementConnexe: "Esemény"
            case .personnage: "Személy"
            case .lieuInstitution: "Hely"
            }
        case .bulgarian:
            switch self {
            case .referenceHistorique: "Препратка"
            case .concept: "Понятие"
            case .evenementConnexe: "Събитие"
            case .personnage: "Личност"
            case .lieuInstitution: "Място"
            }
        case .czech:
            switch self {
            case .referenceHistorique: "Odkaz"
            case .concept: "Pojem"
            case .evenementConnexe: "Událost"
            case .personnage: "Osobnost"
            case .lieuInstitution: "Místo"
            }
        case .danish:
            switch self {
            case .referenceHistorique: "Reference"
            case .concept: "Begreb"
            case .evenementConnexe: "Begivenhed"
            case .personnage: "Person"
            case .lieuInstitution: "Sted"
            }
        case .norwegian:
            switch self {
            case .referenceHistorique: "Referanse"
            case .concept: "Begrep"
            case .evenementConnexe: "Hendelse"
            case .personnage: "Person"
            case .lieuInstitution: "Sted"
            }
        case .russian:
            switch self {
            case .referenceHistorique: "Отсылка"
            case .concept: "Понятие"
            case .evenementConnexe: "Событие"
            case .personnage: "Личность"
            case .lieuInstitution: "Место"
            }
        case .croatian:
            switch self {
            case .referenceHistorique: "Referenca"
            case .concept: "Pojam"
            case .evenementConnexe: "Događaj"
            case .personnage: "Osoba"
            case .lieuInstitution: "Mjesto"
            }
        case .slovenian:
            switch self {
            case .referenceHistorique: "Sklic"
            case .concept: "Pojem"
            case .evenementConnexe: "Dogodek"
            case .personnage: "Oseba"
            case .lieuInstitution: "Kraj"
            }
        case .slovak:
            switch self {
            case .referenceHistorique: "Odkaz"
            case .concept: "Pojem"
            case .evenementConnexe: "Udalosť"
            case .personnage: "Osobnosť"
            case .lieuInstitution: "Miesto"
            }
        case .serbian:
            switch self {
            case .referenceHistorique: "Referenca"
            case .concept: "Pojam"
            case .evenementConnexe: "Događaj"
            case .personnage: "Ličnost"
            case .lieuInstitution: "Mesto"
            }
        case .arabic:
            switch self {
            case .referenceHistorique: "مرجع"
            case .concept: "مفهوم"
            case .evenementConnexe: "حدث"
            case .personnage: "شخصية"
            case .lieuInstitution: "مكان"
            }
        case .hebrew:
            switch self {
            case .referenceHistorique: "הפניה"
            case .concept: "מושג"
            case .evenementConnexe: "אירוע"
            case .personnage: "דמות"
            case .lieuInstitution: "מקום"
            }
        case .finnish:
            switch self {
            case .referenceHistorique: "Viittaus"
            case .concept: "Käsite"
            case .evenementConnexe: "Tapahtuma"
            case .personnage: "Henkilö"
            case .lieuInstitution: "Paikka"
            }
        case .estonian:
            switch self {
            case .referenceHistorique: "Viide"
            case .concept: "Mõiste"
            case .evenementConnexe: "Sündmus"
            case .personnage: "Isik"
            case .lieuInstitution: "Koht"
            }
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
        case .french:
            return frenchEntry(courseTitle: courseTitle, displayTerm: displayTerm)
        default:
            return localizedEntry(courseId: courseId, displayTerm: displayTerm)
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
