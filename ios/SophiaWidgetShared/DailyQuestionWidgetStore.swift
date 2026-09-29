import Foundation

// Compilé dans l'app ET dans l'extension widget. Le widget tourne dans son propre processus,
// sans le catalogue des cours, les tables de traduction ni les services de l'app : tout ce
// qu'il affiche lui est préparé par l'app et passe par l'App Group.

/// Une journée du widget : la question de ce jour-là, déjà traduite.
nonisolated struct DailyQuestionWidgetDay: Codable, Hashable, Sendable {
    /// `yyyy-MM-dd`, calendrier grégorien, fuseau de l'appareil.
    let day: String
    let courseId: String
    let question: String
    /// Nom court de la matière, dans la langue de l'app.
    let subject: String
    /// Vignette de la couverture dans `DailyQuestionWidgetStore.imageDirectory`, si elle existe.
    let imageFile: String?
}

/// Ce que l'app écrit pour le widget.
nonisolated struct DailyQuestionWidgetPayload: Codable, Equatable, Sendable {
    /// « Question du jour », dans la langue de l'app.
    let label: String
    /// Nom et description du widget dans la galerie d'iOS.
    let galleryName: String
    let galleryDescription: String
    /// Les jours à venir. Vide pendant l'essai gratuit : le widget n'affiche alors rien
    /// de la question, seulement Sophia.
    let days: [DailyQuestionWidgetDay]
}

nonisolated enum DailyQuestionWidgetStore {
    /// App Group partagé avec le blocker TikTok. Doit correspondre aux `.entitlements`.
    static let appGroupId = "group.app.rork.sophia"
    /// Identifiant du widget, pour recharger sa timeline et savoir s'il est posé.
    static let widgetKind = "SophiaDailyQuestion"

    private static let payloadKey = "dailyQuestion.widget.payload"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupId) ?? .standard
    }

    static func load() -> DailyQuestionWidgetPayload? {
        guard let data = defaults.data(forKey: payloadKey) else { return nil }
        return try? JSONDecoder().decode(DailyQuestionWidgetPayload.self, from: data)
    }

    static func save(_ payload: DailyQuestionWidgetPayload) {
        guard let data = try? JSONEncoder().encode(payload) else { return }
        defaults.set(data, forKey: payloadKey)
    }

    /// Dossier des vignettes, dans le conteneur de l'App Group.
    static var imageDirectory: URL? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        ) else { return nil }
        let directory = container.appendingPathComponent("DailyQuestion", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func imageURL(_ fileName: String) -> URL? {
        imageDirectory?.appendingPathComponent(fileName)
    }

    /// Lien ouvert au toucher : le cours, avec sa provenance pour les statistiques.
    static func courseURL(courseId: String) -> URL? {
        URL(string: "sophia://course/\(courseId)?from=widget")
    }

    /// Même clé que dans l'app (`DailyQuestion.day(for:)`).
    static func dayKey(for date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
