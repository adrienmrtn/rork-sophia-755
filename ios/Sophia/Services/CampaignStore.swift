import Foundation

/// Les événements éditoriaux (table `campaigns` côté serveur, servis par le manifeste du
/// catalogue, voir docs/evenements.md) et l'état local du lecteur vis-à-vis d'eux : les cours
/// annoncés pour lesquels il a demandé à être prévenu.
///
/// Rien n'est embarqué : avant le premier manifeste il n'y a pas d'événement, et les vues qui
/// lisent `all` se redessinent dès que `CatalogStore` (observable) en reçoit.
enum CampaignStore {
    private static let notifyKey = "sophia_campaign_notify"

    /// Les événements publiés, du plus ancien au plus récent.
    static var all: [Campaign] { CatalogStore.shared.campaigns }

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
}
