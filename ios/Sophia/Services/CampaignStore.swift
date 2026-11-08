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

    private static func load() -> [Campaign] {
        let bundle = Bundle.main
        var urls: [URL] = []
        for subdirectory in ["Resources/Events", "Events"] {
            if let found = bundle.urls(forResourcesWithExtension: "json", subdirectory: subdirectory), !found.isEmpty {
                urls = found
                break
            }
        }
        if urls.isEmpty, let root = bundle.resourceURL {
            for subdirectory in ["Resources/Events", "Events"] {
                let folder = root.appendingPathComponent(subdirectory)
                if let found = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) {
                    urls = found.filter { $0.pathExtension == "json" }
                    if !urls.isEmpty { break }
                }
            }
        }
        let decoder = JSONDecoder()
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
