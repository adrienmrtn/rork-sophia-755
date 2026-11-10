import SwiftUI
import UIKit

/// Fête chaque badge au moment où il est gagné (docs/badges.md).
///
/// Le centre garde sur l'appareil la liste des badges déjà fêtés. À chaque changement de ce que
/// les badges mesurent (progression enregistrée, compteur de duel ou d'amis relevé, retour de
/// l'app au premier plan), il fait constater les badges atteints (`ProgressManager.refreshBadges`)
/// et met en file ceux qui sont gagnés sans avoir été fêtés. Chacun est montré une seule fois,
/// l'un après l'autre, par `BadgeCelebrationHost` posé à la racine de l'app.
///
/// Ce qui n'est pas fêté, pour ne pas noyer le lecteur sous d'anciens exploits :
/// - à la première ouverture après cette version, tout ce qui est déjà gagné ;
/// - ce qui arrive du cloud (autre appareil, connexion à un compte) ;
/// - à la première lecture du serveur, les victoires, la ligue et les amis d'avant ;
/// - un événement découvert alors que son défi est déjà rempli ;
/// - les paliers intermédiaires franchis d'un coup : seul le plus haut d'une même mesure est fêté.
@Observable
@MainActor
final class BadgeCelebrationCenter {
    static let shared = BadgeCelebrationCenter()

    /// Le badge à l'écran, s'il y en a un.
    private(set) var current: Badge?

    @ObservationIgnored private var queue: [Badge] = []
    @ObservationIgnored private weak var progressManager: ProgressManager?
    @ObservationIgnored private var detectionScheduled = false
    @ObservationIgnored private var waitTask: Task<Void, Never>?
    /// Vrai tant que l'écran racine (onglets) est monté : sans lui, rien ne peut être montré.
    @ObservationIgnored private var hostMounted = false

    private static let celebratedKey = "sophia_badge_celebrated_ids"
    private static let knownEventsKey = "sophia_badge_known_event_ids"
    /// Garde-fou : jamais plus de fêtes d'affilée que ça, le reste est marqué fêté sans bruit.
    private static let maxBatch = 5

    private init() {}

    // MARK: - Entrées

    /// La progression de l'app. Appelé par l'hôte quand l'écran racine apparaît.
    func attach(_ manager: ProgressManager) {
        progressManager = manager
        hostMounted = true
        detect()
        pump()
    }

    func hostDidDisappear() {
        hostMounted = false
    }

    /// Quelque chose que les badges mesurent vient de changer. Les appels rapprochés sont
    /// regroupés : la vérification a lieu une fois, au prochain tour de la boucle principale.
    func scheduleDetection() {
        guard !detectionScheduled else { return }
        detectionScheduled = true
        Task { @MainActor in
            self.detectionScheduled = false
            self.detect()
        }
    }

    /// Marque comme déjà fêtés, sans animation, les badges atteints ou gagnés à cet instant
    /// (ceux que `matching` retient). Faux quand aucune progression n'est disponible.
    @discardableResult
    func absorb(using manager: ProgressManager? = nil, matching: (Badge) -> Bool = { _ in true }) -> Bool {
        guard let manager = manager ?? progressManager else { return false }
        let stats = BadgeStats(progressManager: manager)
        let catalog = BadgeCatalog.permanent + BadgeCatalog.leagues + BadgeCatalog.events
        let ids = catalog
            .filter { matching($0) && (manager.progress.earnedBadges[$0.id] != nil || stats.isReached($0)) }
            .map(\.id)
        guard var celebrated = storedSet(Self.celebratedKey) else {
            // Jamais vérifié : la première vérification marquera tout ce qui est déjà gagné.
            return true
        }
        celebrated.formUnion(ids)
        store(celebrated, Self.celebratedKey)
        return true
    }

    /// Le lecteur a fermé la fête en cours.
    func dismissCurrent() {
        guard current != nil else { return }
        current = nil
        pump()
    }

    // MARK: - Détection

    private func detect() {
        guard let manager = progressManager else { return }
        manager.refreshBadges()
        let earned = Set(manager.progress.earnedBadges.keys)
        let eventIds = Set(BadgeCatalog.events.map(\.id))

        guard var celebrated = storedSet(Self.celebratedKey) else {
            // Première ouverture avec cette version : rien de ce qui est déjà gagné n'est fêté.
            store(earned, Self.celebratedKey)
            store(eventIds, Self.knownEventsKey)
            return
        }

        // Un événement vu pour la première fois et déjà rempli : gagné avant, pas à l'instant.
        var known = storedSet(Self.knownEventsKey) ?? []
        let unseen = eventIds.subtracting(known)
        if !unseen.isEmpty {
            celebrated.formUnion(unseen.intersection(earned))
            known.formUnion(unseen)
            store(known, Self.knownEventsKey)
        }

        // Un badge retiré de la progression (remise à zéro) pourra être fêté de nouveau.
        celebrated.formIntersection(earned)

        var pending = Set(queue.map(\.id))
        if let shown = current { pending.insert(shown.id) }
        let catalog = BadgeCatalog.permanent + BadgeCatalog.leagues + BadgeCatalog.events
        let duelsVisible = FeatureFlags.duelsVisible(language: LanguageManager.shared.current)
        var fresh: [Badge] = []
        for badge in catalog where earned.contains(badge.id) && !celebrated.contains(badge.id) && !pending.contains(badge.id) {
            if badge.family.needsDuels && !duelsVisible {
                // Famille absente de la page des badges dans cette langue : rien à montrer.
                celebrated.insert(badge.id)
            } else {
                fresh.append(badge)
            }
        }

        // Plusieurs paliers d'une même mesure franchis d'un coup : seul le plus haut est fêté.
        var winners: [Badge] = []
        for badge in fresh {
            let best = fresh.filter { $0.metric == badge.metric }.max { $0.target < $1.target }
            if best?.id == badge.id {
                winners.append(badge)
            } else {
                celebrated.insert(badge.id)
            }
        }
        if winners.count > Self.maxBatch {
            for badge in winners.dropFirst(Self.maxBatch) { celebrated.insert(badge.id) }
            winners = Array(winners.prefix(Self.maxBatch))
        }

        store(celebrated, Self.celebratedKey)
        guard !winners.isEmpty else { return }
        queue.append(contentsOf: winners)
        pump()
    }

    // MARK: - Présentation

    /// Montre le badge suivant dès que l'écran est libre : jamais par-dessus (ni derrière) un
    /// cours, un quiz, un duel ou une feuille. Tant qu'un écran présenté est ouvert, on attend.
    private func pump() {
        guard current == nil, !queue.isEmpty, waitTask == nil else { return }
        waitTask = Task { @MainActor in
            // Laisse l'écran courant se poser (et la fête précédente s'effacer).
            try? await Task.sleep(nanoseconds: 600_000_000)
            while !Task.isCancelled {
                if self.isScreenFree() {
                    self.waitTask = nil
                    self.presentNext()
                    return
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            self.waitTask = nil
        }
    }

    private func presentNext() {
        guard current == nil, !queue.isEmpty else { return }
        let badge = queue.removeFirst()
        // Fêté dès qu'il est à l'écran : une app tuée avant le rejouera au prochain lancement.
        var celebrated = storedSet(Self.celebratedKey) ?? []
        celebrated.insert(badge.id)
        store(celebrated, Self.celebratedKey)
        current = badge
    }

    /// Vrai quand les onglets sont visibles : app active, rien de présenté par-dessus la racine.
    private func isScreenFree() -> Bool {
        guard hostMounted, UIApplication.shared.applicationState == .active else { return false }
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        guard let root = (windows.first { $0.isKeyWindow } ?? windows.first)?.rootViewController else { return false }
        return root.presentedViewController == nil
    }

    // MARK: - Stockage

    private func storedSet(_ key: String) -> Set<String>? {
        UserDefaults.standard.stringArray(forKey: key).map { Set($0) }
    }

    private func store(_ set: Set<String>, _ key: String) {
        UserDefaults.standard.set(Array(set), forKey: key)
    }
}
