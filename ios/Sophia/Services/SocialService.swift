import Foundation
import Observation
import Supabase

/// Période du classement d'amis.
nonisolated enum FriendsLeaderboardPeriod: String, CaseIterable, Sendable {
    case week
    case all

    var rpcValue: String {
        switch self {
        case .week: "week"
        case .all: "all"
        }
    }
}

nonisolated struct FriendLeaderboardEntry: Identifiable, Decodable, Sendable, Equatable {
    let userId: UUID
    let handle: String
    let xp: Int
    let isMe: Bool

    var id: UUID { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case handle
        case xp
        case isMe = "is_me"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        userId = try c.decode(UUID.self, forKey: .userId)
        handle = try c.decode(String.self, forKey: .handle)
        if let intXP = try? c.decode(Int.self, forKey: .xp) {
            xp = intXP
        } else if let longXP = try? c.decode(Int64.self, forKey: .xp) {
            xp = Int(longXP)
        } else {
            xp = 0
        }
        isMe = try c.decode(Bool.self, forKey: .isMe)
    }
}

nonisolated struct FriendPublicStats: Decodable, Sendable, Equatable {
    let userId: UUID
    let handle: String
    let globalXP: Int
    let streak: Int
    let coursesCompleted: Int
    let quizzesCompleted: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case handle
        case globalXP = "global_xp"
        case streak
        case coursesCompleted = "courses_completed"
        case quizzesCompleted = "quizzes_completed"
    }
}

nonisolated enum SocialError: Error, Sendable, Equatable {
    case notSignedIn
    case invalidHandle
    case handleTaken
    case userNotFound
    case cannotAddSelf
    case notFriends
    case underlying(String)

    static func from(_ error: Error) -> SocialError {
        let message = error.localizedDescription.lowercased()
        if message.contains("invalid_handle") { return .invalidHandle }
        if message.contains("handle_taken") { return .handleTaken }
        if message.contains("user_not_found") { return .userNotFound }
        if message.contains("cannot_add_self") { return .cannotAddSelf }
        if message.contains("not_friends") { return .notFriends }
        if message.contains("not_authenticated") { return .notSignedIn }
        return .underlying(error.localizedDescription)
    }
}

/// Handles (@), amis et classement XP via Supabase.
@Observable
@MainActor
final class SocialService {
    static let shared = SocialService()

    private(set) var myHandle: String?
    private(set) var leaderboard: [FriendLeaderboardEntry] = []
    private(set) var period: FriendsLeaderboardPeriod = .week
    private(set) var isLoadingHandle = false
    private(set) var isLoadingLeaderboard = false

    private let client = SupabaseManager.shared

    private init() {}

    // MARK: - Profile handle

    func refreshMyHandle() async {
        guard AuthService.shared.isSignedIn,
              let userID = AuthService.shared.currentUser?.id.uuidString else {
            myHandle = nil
            return
        }
        isLoadingHandle = true
        defer { isLoadingHandle = false }
        do {
            struct Row: Decodable { let handle: String }
            let rows: [Row] = try await client
                .from("profiles")
                .select("handle")
                .eq("id", value: userID)
                .limit(1)
                .execute()
                .value
            myHandle = rows.first?.handle
        } catch {
            #if DEBUG
            print("[Social] refreshMyHandle failed: \(error)")
            #endif
        }
    }

    @discardableResult
    func updateHandle(_ raw: String) async throws -> String {
        guard AuthService.shared.isSignedIn else { throw SocialError.notSignedIn }
        struct Params: Encodable { let new_handle: String }
        do {
            let updated: String = try await client
                .rpc("update_my_handle", params: Params(new_handle: raw))
                .execute()
                .value
            myHandle = updated
            return updated
        } catch {
            throw SocialError.from(error)
        }
    }

    // MARK: - Friends

    func addFriend(handle raw: String) async throws {
        guard AuthService.shared.isSignedIn else { throw SocialError.notSignedIn }
        struct Params: Encodable { let target_handle: String }
        do {
            let _: UUID = try await client
                .rpc("add_friend_by_handle", params: Params(target_handle: raw))
                .execute()
                .value
            await refreshLeaderboard()
        } catch {
            throw SocialError.from(error)
        }
    }

    func removeFriend(userId: UUID) async throws {
        guard AuthService.shared.isSignedIn else { throw SocialError.notSignedIn }
        struct Params: Encodable { let friend: UUID }
        do {
            try await client
                .rpc("remove_friend", params: Params(friend: userId))
                .execute()
            await refreshLeaderboard()
        } catch {
            throw SocialError.from(error)
        }
    }

    func setPeriod(_ newPeriod: FriendsLeaderboardPeriod) async {
        guard period != newPeriod else { return }
        period = newPeriod
        await refreshLeaderboard()
    }

    func refreshLeaderboard() async {
        guard AuthService.shared.isSignedIn else {
            leaderboard = []
            return
        }
        isLoadingLeaderboard = true
        defer { isLoadingLeaderboard = false }
        struct Params: Encodable { let period: String }
        do {
            let rows: [FriendLeaderboardEntry] = try await client
                .rpc("friends_leaderboard", params: Params(period: period.rpcValue))
                .execute()
                .value
            leaderboard = rows
        } catch {
            #if DEBUG
            print("[Social] refreshLeaderboard failed: \(error)")
            #endif
        }
    }

    func friendStats(userId: UUID) async throws -> FriendPublicStats {
        guard AuthService.shared.isSignedIn else { throw SocialError.notSignedIn }
        struct Params: Encodable { let target: UUID }
        do {
            let rows: [FriendPublicStats] = try await client
                .rpc("friend_public_stats", params: Params(target: userId))
                .execute()
                .value
            guard let stats = rows.first else { throw SocialError.userNotFound }
            return stats
        } catch let social as SocialError {
            throw social
        } catch {
            throw SocialError.from(error)
        }
    }

    // MARK: - XP events

    /// Enregistre un gain d'XP global pour le classement hebdomadaire (best-effort).
    func logXPEvent(amount: Int, reason: String?) {
        guard amount > 0, AuthService.shared.isSignedIn else { return }
        Task { [weak self] in
            await self?.pushXPEvent(amount: amount, reason: reason)
        }
    }

    private func pushXPEvent(amount: Int, reason: String?) async {
        struct Params: Encodable {
            let amount: Int
            let reason: String?
        }
        do {
            try await client
                .rpc("log_xp_event", params: Params(amount: amount, reason: reason))
                .execute()
        } catch {
            #if DEBUG
            print("[Social] logXPEvent failed: \(error)")
            #endif
        }
    }

    /// Charge handle + classement après connexion / au focus profil.
    func refreshAll() async {
        await refreshMyHandle()
        await refreshLeaderboard()
    }

    func clearLocalState() {
        myHandle = nil
        leaderboard = []
    }
}
