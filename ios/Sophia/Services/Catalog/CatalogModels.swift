import Foundation

// Les formats JSON que Supabase sert aux apps depuis le bucket `course-content`, et que le
// pack de départ embarque (`Resources/StarterPack/<lang>/`). Produits par
// scripts/import_catalog_to_supabase.py ; décrits dans docs/catalogue-en-ligne.md.

/// `<lang>/catalog.<hash>.json` : tous les cours publiés d'une langue (métadonnées et
/// sections, sans le texte), les collections du Parcours et les créateurs.
struct CatalogFile: Decodable {
    struct Section: Decodable {
        let id: String
        let title: String
        let free: Bool?
    }

    struct CourseEntry: Decodable {
        let id: String
        let title: String
        let subtitle: String?
        let description: String
        let subject: String
        let subcategory: String
        let hook: String?
        let creator: String?
        /// Nom de l'objet de couverture dans le bucket `course-images` (sans extension).
        let cover: String?
        let tier: String?
        let sections: [Section]
        let quizCount: Int?
        let hash: String
    }

    struct CollectionEntry: Decodable {
        let id: String
        let title: String
        let description: String
        let cover: String?
        let courseIds: [String]
    }

    struct CreatorEntry: Decodable {
        let slug: String
        let name: String
        let photo: String?
        let photoUrl: String?
        let institution: String?
        let country: String?
        let links: [String: String]?
        let title: String?
        let bio: String?
        let verified: Bool?
        let courseIds: [String]?
    }

    let lang: String
    let hash: String
    let courses: [CourseEntry]
    let collections: [CollectionEntry]
    let creators: [CreatorEntry]
}

/// Une entrée de glossaire telle qu'elle est servie (`<lang>/glossary.<hash>.json`, clé
/// `"<courseId>|<terme>"`, et le champ `glossary` des paquets de cours).
struct GlossaryEntryDTO: Decodable {
    let displayTerm: String
    let classification: String
    let explanation: String

    var entry: GlossaryEntry? {
        guard let classification = GlossaryClassification(catalogKey: classification) else { return nil }
        return GlossaryEntry(displayTerm: displayTerm, classification: classification, explanation: explanation)
    }
}

/// `<lang>/courses/<courseId>.<hash>.json` : tout ce qu'il faut pour lire un cours hors
/// ligne, en un seul téléchargement.
struct CourseBundle: Decodable {
    let id: String
    let lang: String
    let hash: String
    let content: CourseContentV2
    let quiz: [QuizQuestion]
    let glossary: [String: GlossaryEntryDTO]?
    let credits: [String: ImageCredit]?
}

/// La réponse de `catalog-manifest?lang=xx` : les fichiers de la langue et le paquet de
/// chaque cours publié, avec le hash qui nomme l'objet. Les chemins sont relatifs au bucket.
struct CatalogManifest: Decodable {
    struct Entry: Decodable {
        let hash: String
        let bytes: Int?
        /// Chemin dans le bucket `course-content` (quand l'objet y est).
        let path: String
        /// L'adresse à télécharger : l'objet Storage, ou la fonction `catalog-file` qui produit le
        /// fichier depuis la base. Absente des anciens manifestes : `path` sert alors de repli.
        let url: String?

        var downloadURL: URL? {
            if let url, let absolute = URL(string: url) { return absolute }
            return CatalogStore.objectURL(path: path)
        }
    }

    let lang: String
    let files: [String: Entry]
    let courses: [String: Entry]
}

/// `app_config` → clé `catalog` : le coupe-circuit et la cadence de rafraîchissement.
struct CatalogRemoteConfig: Codable {
    var enabled: Bool = true
    var refreshHours: Double = 6
    var share: Double = 1

    enum CodingKeys: String, CodingKey {
        case enabled
        case refreshHours = "refresh_hours"
        case share
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        refreshHours = try container.decodeIfPresent(Double.self, forKey: .refreshHours) ?? 6
        share = try container.decodeIfPresent(Double.self, forKey: .share) ?? 1
    }
}
