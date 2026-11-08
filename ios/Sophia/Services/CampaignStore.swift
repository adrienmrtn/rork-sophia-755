import Foundation

/// Les événements embarqués (`Resources/Events/*.json`) et l'état local du lecteur vis-à-vis
/// d'eux : les cours annoncés pour lesquels il a demandé à être prévenu.
///
/// Le serveur prendra le relais au prompt 6 (table `campaigns`, `campaign_progress`) ; l'API
/// est écrite pour que seul ce fichier change à ce moment-là.
enum CampaignStore {
    private static var loaded: [Campaign]?
    private static let notifyKey = "sophia_campaign_notify"

    static func resetCache() { loaded = nil }

    static var all: [Campaign] {
        if let loaded { return loaded }
        let campaigns = load()
        loaded = campaigns
        return campaigns
    }

    /// Les événements en cours, le plus proche de sa fin en premier.
    static func active(on date: Date = Date()) -> [Campaign] {
        all.filter { $0.isActive(on: date) }
            .sorted { ($0.endDate ?? .distantFuture) < ($1.endDate ?? .distantFuture) }
    }

    static func campaign(slug: String) -> Campaign? {
        all.first { $0.slug == slug }
    }

    /// L'événement actif dont la collection contient ce cours, pour l'étiquette sur les cartes.
    static func activeCampaign(forCourseId courseId: String, on date: Date = Date()) -> Campaign? {
        active(on: date).first { $0.courseIds.contains(courseId) }
    }

    /// Cours de la collection terminés par le lecteur, dans la limite du défi.
    static func challengeProgress(for campaign: Campaign, progressManager: ProgressManager) -> Int {
        let completed = campaign.courseIds.filter { progressManager.courseStatus(for: $0) == .completed }.count
        return min(completed, campaign.challengeTarget)
    }

    static func isChallengeComplete(for campaign: Campaign, progressManager: ProgressManager) -> Bool {
        challengeProgress(for: campaign, progressManager: progressManager) >= campaign.challengeTarget
    }

    // MARK: - « Me prévenir »

    private static func notifyId(_ campaign: Campaign, _ upcoming: Campaign.Upcoming) -> String {
        "\(campaign.slug)|\(upcoming.date)|\(upcoming.title["fr"] ?? upcoming.title["en"] ?? "")"
    }

    static func wantsNotification(for campaign: Campaign, upcoming: Campaign.Upcoming) -> Bool {
        let stored = UserDefaults.standard.stringArray(forKey: notifyKey) ?? []
        return stored.contains(notifyId(campaign, upcoming))
    }

    static func setWantsNotification(_ wants: Bool, for campaign: Campaign, upcoming: Campaign.Upcoming) {
        var stored = UserDefaults.standard.stringArray(forKey: notifyKey) ?? []
        let id = notifyId(campaign, upcoming)
        if wants, !stored.contains(id) { stored.append(id) }
        if !wants { stored.removeAll { $0 == id } }
        UserDefaults.standard.set(stored, forKey: notifyKey)
    }

    // MARK: - Loading

    private struct Index: Decodable {
        let events: [String]
    }

    /// Xcode peut aplatir le dossier `Resources` dans le bundle : comme les autres chargeurs,
    /// chaque fichier est cherché dans `Resources/Events`, `Events`, puis à la racine. Un
    /// index (`index.json`) donne les noms de fichiers, puisqu'on ne peut pas lister la racine.
    private static func resourceURL(name: String) -> URL? {
        let bundle = Bundle.main
        for subdirectory in ["Resources/Events", "Events"] {
            if let url = bundle.url(forResource: name, withExtension: "json", subdirectory: subdirectory) { return url }
        }
        if let url = bundle.url(forResource: name, withExtension: "json") { return url }
        guard let root = bundle.resourceURL else { return nil }
        for subdirectory in ["Resources/Events", "Events", ""] {
            let candidate = root.appendingPathComponent(subdirectory).appendingPathComponent("\(name).json")
            if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
        }
        return nil
    }

    private static func load() -> [Campaign] {
        let decoder = JSONDecoder()
        guard let indexURL = resourceURL(name: "index"),
              let indexData = try? Data(contentsOf: indexURL),
              let index = try? decoder.decode(Index.self, from: indexData) else {
            assertionFailure("Events index.json missing from the bundle")
            return []
        }
        let urls = index.events.compactMap { resourceURL(name: $0) }
        return urls.compactMap { url in
            guard let data = try? Data(contentsOf: url) else { return nil }
            do {
                return try decoder.decode(Campaign.self, from: data)
            } catch {
                assertionFailure("Failed to decode campaign \(url.lastPathComponent): \(error)")
                return nil
            }
        }
        .sorted { $0.startsAt < $1.startsAt }
    }
}
