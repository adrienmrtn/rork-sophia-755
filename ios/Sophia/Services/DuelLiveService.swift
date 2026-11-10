import Foundation
import Observation
import Supabase

nonisolated enum DuelInviteError: Error, Sendable, Equatable {
    case notSignedIn
    case notFriends
    /// L'ami n'a pas les duels (app dans une autre langue, ou pas à jour).
    case friendUnavailable
    /// L'ami est en pleine partie, ou déjà devant une autre invitation.
    case friendBusy
    case underlying(String)

    static func from(_ error: Error) -> DuelInviteError {
        let message = error.localizedDescription.lowercased()
        if message.contains("not_authenticated") { return .notSignedIn }
        if message.contains("not_friends") { return .notFriends }
        if message.contains("friend_unavailable") { return .friendUnavailable }
        if message.contains("friend_busy") { return .friendBusy }
        return .underlying(error.localizedDescription)
    }
}

/// Les duels entre amis via Supabase : la présence (pastille verte), les invitations et la
/// partie en direct.
///
/// L'app n'a pas de notifications push : tant qu'elle est ouverte, elle se signale au serveur
/// toutes les quatre secondes (`duel_ping`), ce qui tient sa pastille verte chez ses amis, et
/// c'est la réponse à ce signal qui lui apporte une invitation. Une invitation reçue s'affiche
/// en bandeau par-dessus l'écran en cours (`DuelInviteBanner`).
@Observable
@MainActor
final class DuelLiveService {
    static let shared = DuelLiveService()

    /// L'invitation en attente de réponse, et l'instant où elle tombe.
    private(set) var incoming: DuelIncomingInvite?
    private(set) var incomingDeadline: Date?
    /// Une partie entre amis est à l'écran (invitation envoyée comprise).
    var isInFriendDuel = false

    private let client = SupabaseManager.shared
    @ObservationIgnored private var pingTask: Task<Void, Never>?
    /// Une invitation à laquelle on vient de répondre : le prochain signal ne doit pas la rafficher.
    @ObservationIgnored private var answeredInviteId: UUID?

    private static let pingInterval: Duration = .seconds(4)

    private init() {}

    // MARK: - Présence

    /// À l'ouverture de l'app et à chaque retour au premier plan : commence à se signaler.
    func start() {
        guard pingTask == nil else { return }
        pingTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.ping()
                try? await Task.sleep(for: DuelLiveService.pingInterval)
            }
        }
    }

    /// L'app passe à l'arrière-plan : plus de signal, et la pastille verte s'éteint tout de suite.
    func stop() {
        pingTask?.cancel()
        pingTask = nil
        clearIncoming()
        guard AuthService.shared.isSignedIn else { return }
        Task {
            _ = try? await client.rpc("duel_go_offline").execute()
        }
    }

    private func ping() async {
        guard AuthService.shared.isSignedIn else {
            clearIncoming()
            return
        }
        struct Params: Encodable {
            let p_lang: String
            let p_busy: Bool
        }
        let busy = isInFriendDuel || DuelService.shared.isPlaying
        do {
            let response: DuelPingResponse = try await client
                .rpc("duel_ping", params: Params(p_lang: "en", p_busy: busy))
                .execute()
                .value
            apply(response.invite)
        } catch {
            // Hors ligne, ou serveur sans les duels entre amis : on réessaie au prochain tour.
        }
        if let deadline = incomingDeadline, Date() > deadline {
            clearIncoming()
        }
    }

    private func apply(_ invite: DuelIncomingInvite?) {
        guard let invite else {
            clearIncoming()
            return
        }
        guard invite.inviteId != answeredInviteId, invite.inviteId != incoming?.inviteId else { return }
        incoming = invite
        incomingDeadline = Date().addingTimeInterval(Double(max(invite.expiresInMs, 0)) / 1000)
        DuelHaptics.opponentFound()
        DuelInviteBanner.shared.show()
    }

    private func clearIncoming() {
        guard incoming != nil else { return }
        incoming = nil
        incomingDeadline = nil
        DuelInviteBanner.shared.hide()
    }

    // MARK: - Invitations

    /// Défie un ami : il a 15 secondes pour répondre.
    func invite(friend userId: UUID) async throws -> DuelSentInvite {
        guard AuthService.shared.isSignedIn else { throw DuelInviteError.notSignedIn }
        struct Params: Encodable { let p_friend: UUID }
        do {
            return try await client
                .rpc("duel_invite_friend", params: Params(p_friend: userId))
                .execute()
                .value
        } catch {
            throw DuelInviteError.from(error)
        }
    }

    func inviteStatus(_ inviteId: UUID) async throws -> DuelInviteOutcome {
        struct Params: Encodable { let p_invite: UUID }
        return try await client
            .rpc("duel_invite_status", params: Params(p_invite: inviteId))
            .execute()
            .value
    }

    func cancelInvite(_ inviteId: UUID) async {
        struct Params: Encodable { let p_invite: UUID }
        _ = try? await client
            .rpc("duel_invite_cancel", params: Params(p_invite: inviteId))
            .execute()
    }

    /// Répond à l'invitation reçue. Acceptée et encore valable : la partie à lancer.
    func respond(to invite: DuelIncomingInvite, accept: Bool) async -> DuelFriendStart? {
        answeredInviteId = invite.inviteId
        clearIncoming()
        struct Params: Encodable {
            let p_invite: UUID
            let p_accept: Bool
        }
        do {
            let outcome: DuelInviteOutcome = try await client
                .rpc("duel_invite_respond", params: Params(p_invite: invite.inviteId, p_accept: accept))
                .execute()
                .value
            return outcome.status == "accepted" ? outcome.match : nil
        } catch {
            return nil
        }
    }

    // MARK: - Partie en direct

    func state(matchId: UUID) async throws -> DuelFriendState {
        struct Params: Encodable { let p_match: UUID }
        return try await client
            .rpc("duel_friend_state", params: Params(p_match: matchId))
            .execute()
            .value
    }

    func answer(matchId: UUID, index: Int, answer: DuelAnswer) async throws -> DuelFriendState {
        struct Params: Encodable {
            let p_match: UUID
            let p_index: Int
            let p_answer: DuelAnswer
        }
        return try await client
            .rpc("duel_friend_answer", params: Params(p_match: matchId, p_index: index, p_answer: answer))
            .execute()
            .value
    }

    func leave(matchId: UUID) async {
        struct Params: Encodable { let p_match: UUID }
        _ = try? await client
            .rpc("duel_friend_leave", params: Params(p_match: matchId))
            .execute()
    }

    // MARK: - Profil d'un ami

    /// Le profil d'un ami. Si le serveur n'a pas encore la fonction (duels entre amis non
    /// déployés), on retombe sur les statistiques d'avant, sans trophées ni abonnements.
    func friendProfile(userId: UUID) async throws -> FriendProfile {
        guard AuthService.shared.isSignedIn else { throw SocialError.notSignedIn }
        struct Params: Encodable { let target: UUID }
        do {
            return try await client
                .rpc("friend_profile", params: Params(target: userId))
                .execute()
                .value
        } catch {
            let social = SocialError.from(error)
            if social == .notFriends || social == .userNotFound || social == .notSignedIn {
                throw social
            }
            let stats = try await SocialService.shared.friendStats(userId: userId)
            return FriendProfile(
                userId: stats.userId,
                handle: stats.handle,
                avatarId: nil,
                globalXP: stats.globalXP,
                streak: stats.streak,
                coursesCompleted: stats.coursesCompleted,
                quizzesCompleted: stats.quizzesCompleted,
                trophies: 0,
                bestTrophies: 0,
                leaguePosition: 1,
                duelGames: 0,
                duelWins: 0,
                follows: [],
                online: false,
                canChallenge: false,
                friendlyPlayed: 0,
                friendlyWon: 0,
                friendlyLost: 0
            )
        }
    }
}
