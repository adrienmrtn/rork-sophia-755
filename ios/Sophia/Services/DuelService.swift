import Foundation
import Observation
import Supabase

nonisolated enum DuelError: Error, Sendable, Equatable {
    case notSignedIn
    /// Pas assez de questions ou d'adversaires côté serveur (contenu pas encore posé).
    case unavailable
    case underlying(String)

    static func from(_ error: Error) -> DuelError {
        let message = error.localizedDescription.lowercased()
        if message.contains("not_authenticated") { return .notSignedIn }
        if message.contains("not_enough_questions") || message.contains("no_opponent") { return .unavailable }
        return .underlying(error.localizedDescription)
    }
}

/// Les duels via Supabase : la page (trophées, ligues, historique), le lancement d'une partie,
/// son résultat et le classement entre amis. Le serveur fait tous les calculs ; ce service
/// garde la dernière page reçue pour l'afficher tout de suite au prochain lancement, et
/// renvoie plus tard un résultat qui n'a pas pu partir (réseau coupé en fin de partie).
@Observable
@MainActor
final class DuelService {
    static let shared = DuelService()

    private(set) var home: DuelHome?
    private(set) var leaderboard: [DuelLeaderboardEntry] = []
    private(set) var isLoadingHome = false
    /// Le dernier chargement de la page a échoué et rien n'est en mémoire à montrer.
    private(set) var homeFailed = false
    /// Une partie est en cours à l'écran : sa fin en attente ne doit pas partir comme un abandon.
    var isPlaying = false
    /// Les trophées gagnés à la dernière partie, tant que la page ne les a pas montrés : au retour
    /// d'une victoire, la jauge de ligue se remplit de l'ancien total au nouveau, une seule fois.
    /// Gardé en mémoire seulement : rien ne se rejoue au lancement suivant.
    private(set) var pendingLeagueGain: DuelLeagueGain?

    private let client = SupabaseManager.shared
    private let defaults = UserDefaults.standard

    private static let homeCacheKey = "sophia_duel_home_cache"
    private static let pendingKey = "sophia_duel_pending_finish"

    /// Une fin de partie à (ré)envoyer : la partie en cours (abandon si l'app est fermée), ou
    /// un résultat dont l'envoi a échoué.
    private nonisolated struct PendingFinish: Codable, Sendable {
        let userId: String
        let matchId: UUID
        var answers: [DuelAnswer]
        var abandoned: Bool
        /// La matière choisie pour la manche au choix.
        var pick: String?
    }

    private init() {
        if let data = defaults.data(forKey: Self.homeCacheKey),
           let cached = try? JSONDecoder().decode(CachedHome.self, from: data) {
            home = cached.home
            homeUserId = cached.userId
        }
    }

    private nonisolated struct CachedHome: Codable, Sendable {
        let userId: String
        let home: DuelHome
    }

    /// Le compte auquel appartient `home` : un changement de compte vide la page gardée.
    private var homeUserId: String?

    private var userId: String? { AuthService.shared.currentUser?.id.uuidString }

    // MARK: - Page

    func refreshHome() async {
        guard AuthService.shared.isSignedIn, let userId else {
            home = nil
            leaderboard = []
            return
        }
        if homeUserId != userId {
            home = nil
            leaderboard = []
        }
        isLoadingHome = true
        defer { isLoadingHome = false }
        await flushPendingFinish()
        await sendLanguageIfNeeded()
        do {
            let fresh: DuelHome = try await client
                .rpc("duel_home")
                .execute()
                .value
            home = fresh
            BadgeCounters.sync(home: fresh)
            homeFailed = false
            homeUserId = userId
            if let data = try? JSONEncoder().encode(CachedHome(userId: userId, home: fresh)) {
                defaults.set(data, forKey: Self.homeCacheKey)
            }
        } catch {
            homeFailed = home == nil
            #if DEBUG
            print("[Duel] refreshHome failed: \(error)")
            #endif
        }
    }

    /// La langue déjà donnée au serveur pour ce compte (« <compte>|<langue> »).
    private var languageSent: String?

    /// Dit au serveur dans quelle langue envoyer les questions et les noms des ligues, avant la
    /// page des duels (puis à chaque changement de langue ou de compte). Sans réponse, ou sur un
    /// serveur qui n'a pas encore la fonction, les questions restent en anglais : on réessaie au
    /// prochain passage.
    private func sendLanguageIfNeeded() async {
        guard let userId else { return }
        let language = AppLanguage.currentPersisted().rawValue
        let key = "\(userId)|\(language)"
        guard languageSent != key else { return }
        struct Params: Encodable { let p_lang: String }
        do {
            try await client.rpc("duel_set_language", params: Params(p_lang: language)).execute()
            languageSent = key
        } catch {
            #if DEBUG
            print("[Duel] duel_set_language failed: \(error)")
            #endif
        }
    }

    func refreshLeaderboard() async {
        guard AuthService.shared.isSignedIn else {
            leaderboard = []
            return
        }
        do {
            let rows: [DuelLeaderboardEntry] = try await client
                .rpc("duel_friends_leaderboard")
                .execute()
                .value
            leaderboard = rows
        } catch {
            #if DEBUG
            print("[Duel] refreshLeaderboard failed: \(error)")
            #endif
        }
    }

    // MARK: - Partie

    /// Lance une partie. Elle est notée « en cours » sur l'appareil : si l'app est fermée avant
    /// la fin, le prochain passage sur la page l'envoie comme un abandon (une défaite).
    func startMatch() async throws -> DuelMatch {
        guard AuthService.shared.isSignedIn, let userId else { throw DuelError.notSignedIn }
        // Le serveur compte comme un abandon toute partie encore ouverte au lancement de la
        // suivante : un résultat resté en attente (réseau coupé) doit donc partir avant.
        await flushPendingFinish(evenWhilePlaying: true)
        do {
            // `p_can_forfeit` : cette version sait montrer un adversaire qui se déconnecte. Un
            // serveur qui ne connaît pas encore le paramètre refuse l'appel : on le refait sans.
            struct Params: Encodable { let p_can_forfeit: Bool }
            let client = self.client
            let match: DuelMatch
            do {
                match = try await client
                    .rpc("duel_start_match_v2", params: Params(p_can_forfeit: true))
                    .execute()
                    .value
            } catch where Self.isUnknownFunction(error) {
                match = try await client
                    .rpc("duel_start_match_v2")
                    .execute()
                    .value
            }
            storePending(PendingFinish(userId: userId, matchId: match.matchId, answers: [], abandoned: true, pick: nil))
            return match
        } catch {
            throw DuelError.from(error)
        }
    }

    /// PostgREST ne trouve pas la fonction avec ces paramètres (PGRST202) : base pas encore à jour.
    private static func isUnknownFunction(_ error: Error) -> Bool {
        let text = "\(error) \(error.localizedDescription)".lowercased()
        return text.contains("pgrst202") || text.contains("could not find the function")
    }

    /// Envoie la fin d'une partie et applique le résultat (trophées, statistiques) à la page.
    /// En cas d'échec, les réponses restent gardées et repartiront au prochain passage.
    func finishMatch(matchId: UUID, answers: [DuelAnswer], abandoned: Bool, pick: String?) async throws -> DuelResult {
        guard AuthService.shared.isSignedIn, let userId else { throw DuelError.notSignedIn }
        storePending(PendingFinish(userId: userId, matchId: matchId, answers: answers, abandoned: abandoned, pick: pick))
        do {
            let result = try await sendFinish(matchId: matchId, answers: answers, abandoned: abandoned, pick: pick)
            clearPending(matchId: matchId)
            apply(result)
            return result
        } catch {
            throw DuelError.from(error)
        }
    }

    private func sendFinish(matchId: UUID, answers: [DuelAnswer], abandoned: Bool, pick: String?) async throws -> DuelResult {
        struct Params: Encodable {
            let p_match_id: UUID
            let p_answers: [DuelAnswer]
            let p_abandoned: Bool
            let p_pick: String?
        }
        return try await client
            .rpc("duel_finish_match_v2", params: Params(p_match_id: matchId, p_answers: answers, p_abandoned: abandoned, p_pick: pick))
            .execute()
            .value
    }

    private func apply(_ result: DuelResult) {
        BadgeCounters.sync(profile: result.profile)
        // Seule la dernière partie compte : une défaite après une victoire efface l'animation.
        if result.won, result.trophiesAfter > result.trophiesBefore {
            pendingLeagueGain = DuelLeagueGain(before: result.trophiesBefore, after: result.trophiesAfter)
        } else {
            pendingLeagueGain = nil
        }
        guard let current = home else { return }
        home = DuelHome(handle: current.handle, profile: result.profile, leagues: current.leagues, recent: current.recent)
    }

    /// Rend les trophées gagnés à montrer, et les oublie : l'animation ne se joue qu'une fois.
    func takePendingLeagueGain() -> DuelLeagueGain? {
        let gain = pendingLeagueGain
        pendingLeagueGain = nil
        return gain
    }

    // MARK: - Fin de partie en attente

    private func loadPending() -> PendingFinish? {
        guard let data = defaults.data(forKey: Self.pendingKey) else { return nil }
        return try? JSONDecoder().decode(PendingFinish.self, from: data)
    }

    private func storePending(_ pending: PendingFinish) {
        if let data = try? JSONEncoder().encode(pending) {
            defaults.set(data, forKey: Self.pendingKey)
        }
    }

    private func clearPending(matchId: UUID) {
        guard loadPending()?.matchId == matchId else { return }
        defaults.removeObject(forKey: Self.pendingKey)
    }

    private func flushPendingFinish(evenWhilePlaying: Bool = false) async {
        guard evenWhilePlaying || !isPlaying, let pending = loadPending() else { return }
        guard pending.userId == userId else {
            defaults.removeObject(forKey: Self.pendingKey)
            return
        }
        do {
            _ = try await sendFinish(matchId: pending.matchId, answers: pending.answers, abandoned: pending.abandoned, pick: pending.pick)
            clearPending(matchId: pending.matchId)
        } catch {
            // Partie inconnue du serveur (compte changé, base réinitialisée) : rien à renvoyer.
            if error.localizedDescription.lowercased().contains("match_not_found") {
                clearPending(matchId: pending.matchId)
            }
        }
    }

    func clearLocalState() {
        home = nil
        pendingLeagueGain = nil
        leaderboard = []
        homeFailed = false
        homeUserId = nil
        defaults.removeObject(forKey: Self.homeCacheKey)
    }
}
