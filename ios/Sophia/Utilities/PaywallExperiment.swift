import CryptoKit
import Foundation

/// Les deux habillages du paywall « débloquer un cours ».
nonisolated enum CoursePaywallVariant: String, Sendable, CaseIterable {
    /// Avant / après (« bonhomme »), avec le bloc d'avis sous les experts.
    case bonhomme
    /// « Toute la bibliothèque » : éventail de cours, experts, avis.
    case reviews

    /// Identifiant de paywall envoyé à RevenueCat et au journal d'événements.
    var paywallId: String { "native_course_unlock_\(rawValue)" }
}

/// Réglage du test, lu dans `app_config` (clé `course_paywall_ab`) :
/// `{"enabled": true, "share_reviews": 0.5, "default_variant": "bonhomme"}`.
nonisolated struct CoursePaywallABConfig: Codable, Sendable, Equatable {
    /// Test en cours. À `false`, tout le monde reçoit `defaultVariant` (ou `bonhomme`).
    var enabled: Bool
    /// Part des installations (0 à 1) qui reçoivent la variante `reviews`.
    var shareReviews: Double
    /// Variante servie quand le test est arrêté : `"bonhomme"` ou `"reviews"`.
    var defaultVariant: String?

    /// Ligne absente, réseau coupé ou valeur illisible : test actif, moitié / moitié.
    static let fallback = CoursePaywallABConfig(enabled: true, shareReviews: 0.5, defaultVariant: nil)

    init(enabled: Bool, shareReviews: Double, defaultVariant: String?) {
        self.enabled = enabled
        self.shareReviews = shareReviews
        self.defaultVariant = defaultVariant
    }

    private enum CodingKeys: String, CodingKey {
        case enabled
        case shareReviews = "share_reviews"
        case defaultVariant = "default_variant"
    }

    /// Lecture tolérante : un champ manquant ou mal typé prend sa valeur par défaut.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedEnabled: Bool? = try? container.decode(Bool.self, forKey: .enabled)
        let decodedShare: Double? = try? container.decode(Double.self, forKey: .shareReviews)
        let decodedDefault: String? = try? container.decode(String.self, forKey: .defaultVariant)
        enabled = decodedEnabled ?? true
        let share: Double = decodedShare ?? 0.5
        shareReviews = share.isFinite ? min(max(share, 0), 1) : 0.5
        defaultVariant = decodedDefault
    }
}

/// Test A/B du paywall cours, piloté depuis Supabase en **lecture seule**.
///
/// Même mécanique que la clé `catalog` de `CatalogStore` : une requête REST sur `app_config`
/// au lancement, la dernière valeur connue gardée sur l'appareil, aucune dépendance au compte.
/// Rien n'attend le réseau : le paywall lit le réglage en mémoire au moment où il s'ouvre.
///
/// Le tirage est stable par installation : `u = (4 premiers octets de SHA-256 de
/// "course_paywall_ab:" + identifiant d'installation, lus comme entier non signé
/// gros-boutiste) / 2^32`, et l'installation reçoit `reviews` si `u < share_reviews`.
/// L'identifiant est celui de l'analytics, écrit en minuscules (la forme de la colonne
/// `install_id`), pour que le tirage se recalcule tel quel côté serveur.
enum PaywallExperiment {
    /// Nom du test : clé de `app_config` et propriété `experiment` des événements.
    static let courseExperimentName = "course_paywall_ab"
    private static let storageKey = "sophia_course_paywall_ab_config"

    private(set) static var courseConfig: CoursePaywallABConfig = loadSaved()
    private static var didStart = false

    /// Lance la lecture du réglage, une fois par lancement. Sans effet sur l'affichage en cours.
    static func start() {
        guard !didStart else { return }
        didStart = true
        Task { await refresh() }
    }

    /// La variante de cette installation, d'après le dernier réglage connu.
    static var courseVariant: CoursePaywallVariant {
        variant(config: courseConfig, installId: installIdString)
    }

    /// Propriétés ajoutées aux événements du paywall cours (impression, achat).
    static func courseAnalyticsProps(_ variant: CoursePaywallVariant) -> [String: AnalyticsValue] {
        [
            "variant": .string(variant.rawValue),
            "experiment": .string(courseExperimentName),
        ]
    }

    // MARK: Tirage

    private static var installIdString: String {
        AnalyticsService.shared.installIdentifier.uuidString.lowercased()
    }

    static func variant(config: CoursePaywallABConfig, installId: String) -> CoursePaywallVariant {
        guard config.enabled else {
            return config.defaultVariant.flatMap { CoursePaywallVariant(rawValue: $0) } ?? .bonhomme
        }
        return unitInterval(installId: installId) < config.shareReviews ? .reviews : .bonhomme
    }

    /// Nombre dans [0, 1) dérivé de l'installation, identique sur iOS et Android.
    static func unitInterval(installId: String) -> Double {
        let input: String = courseExperimentName + ":" + installId
        let digest = SHA256.hash(data: Data(input.utf8))
        var value: UInt32 = 0
        for byte in digest.prefix(4) {
            value = (value << 8) | UInt32(byte)
        }
        return Double(value) / 4_294_967_296.0
    }

    // MARK: Lecture du réglage

    /// `app_config` → `course_paywall_ab`. Une erreur réseau garde la dernière valeur connue ;
    /// une ligne absente ou une valeur illisible ramène au comportement par défaut.
    static func refresh() async {
        guard let base = URL(string: AppConfig.SUPABASE_URL) else { return }
        var components = URLComponents(url: base.appendingPathComponent("rest/v1/app_config"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "key", value: "eq.\(courseExperimentName)"),
            URLQueryItem(name: "select", value: "value"),
        ]
        guard let url = components?.url else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue(AppConfig.SUPABASE_ANON_KEY, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(AppConfig.SUPABASE_ANON_KEY)", forHTTPHeaderField: "Authorization")
        guard let result = try? await URLSession.shared.data(for: request),
              (result.1 as? HTTPURLResponse)?.statusCode == 200 else { return }
        let parsed: CoursePaywallABConfig = parse(result.0) ?? .fallback
        courseConfig = parsed
        if let encoded = try? JSONEncoder().encode(parsed) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    /// La réponse REST est `[{"value": {...}}]` ; `value` peut aussi être du JSON écrit dans
    /// une chaîne. Tout le reste (liste vide, autre forme) est « illisible ».
    private static func parse(_ data: Data) -> CoursePaywallABConfig? {
        struct ObjectRow: Decodable { let value: CoursePaywallABConfig }
        struct StringRow: Decodable { let value: String }
        let decoder = JSONDecoder()
        if let rows = try? decoder.decode([ObjectRow].self, from: data) {
            return rows.first?.value
        }
        if let rows = try? decoder.decode([StringRow].self, from: data),
           let text = rows.first?.value,
           let config = try? decoder.decode(CoursePaywallABConfig.self, from: Data(text.utf8)) {
            return config
        }
        return nil
    }

    private static func loadSaved() -> CoursePaywallABConfig {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode(CoursePaywallABConfig.self, from: data) else {
            return .fallback
        }
        return saved
    }
}
