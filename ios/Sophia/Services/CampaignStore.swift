import Foundation

/// Les événements éditoriaux (table `campaigns` côté serveur, servis par le manifeste du
/// catalogue, voir docs/evenements.md) et l'avancement du lecteur dans leur défi.
///
/// Rien n'est embarqué : avant le premier manifeste il n'y a pas d'événement, et les vues qui
/// lisent `all` se redessinent dès que `CatalogStore` (observable) en reçoit.
enum CampaignStore {
    /// Les événements publiés pour la région du téléphone, du plus ancien au plus récent.
    static var all: [Campaign] {
        let region = Locale.current.region?.identifier
        return CatalogStore.shared.campaigns.filter { $0.isShown(inRegion: region) }
    }

    /// Les événements en cours, le plus proche de sa fin en premier.
    static func active(on date: Date = Date()) -> [Campaign] {
        all.filter { $0.isActive(on: date) }
            .sorted { ($0.endDate ?? .distantFuture) < ($1.endDate ?? .distantFuture) }
    }

    /// Les événements terminés que le serveur sert encore (il les garde tant qu'ils sont publiés,
    /// pour les badges gagnés), le plus récemment terminé en premier. L'onglet Explorer les
    /// montre grisés ; le fil d'accueil ne les montre pas.
    static func ended(on date: Date = Date()) -> [Campaign] {
        all.filter { $0.hasEnded(on: date) }
            .sorted { ($0.endDate ?? .distantPast) > ($1.endDate ?? .distantPast) }
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
}
