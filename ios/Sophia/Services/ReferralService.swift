import Foundation
import Observation
import Supabase

/// Le parrainage : « Invite un ami et gagne 3 cours gratuits » (docs/parrainage.md).
///
/// Le code d'invitation d'un lecteur est son @. L'ami invité crée son compte, puis l'app
/// déclare ce code au serveur (`claim_referral`) : toute seule si elle a été ouverte par le
/// lien d'invitation, sinon quand l'ami saisit le code dans la page « Invite un ami ». La
/// récompense revient à celui qui invite, une seule fois, dès le premier ami inscrit : trois
/// crédits de cours, dépensés depuis le lecteur (`ProgressManager.unlockCourseWithReferralCredit`).
@Observable
@MainActor
final class ReferralService {
    static let shared = ReferralService()

    /// Le nombre de cours offerts par la récompense.
    static let rewardCredits = 3

    /// Ce que répond le serveur à un code saisi.
    enum ClaimOutcome: Equatable {
        case ok, unknownCode, ownCode, alreadyClaimed, accountTooOld, notSignedIn, failed
    }

    /// Amis inscrits avec mon code.
    private(set) var invitedCount = 0
    /// Vrai dès qu'un ami s'est inscrit avec mon code : les trois crédits sont acquis.
    private(set) var rewarded: Bool
    /// Vrai si mon compte est assez récent pour saisir le code de quelqu'un, et ne l'a pas fait.
    private(set) var canClaim = false

    private let client = SupabaseManager.shared

    /// La récompense, gardée d'un lancement à l'autre : les crédits restent utilisables hors ligne.
    private static let rewardedKey = "sophia_referral_rewarded"
    /// Le code porté par un lien d'invitation ouvert avant d'avoir un compte.
    private static let pendingCodeKey = "sophia_referral_pending_code"

    private init() {
        rewarded = UserDefaults.standard.bool(forKey: Self.rewardedKey)
    }

    // MARK: - Code en attente (lien d'invitation)

    var pendingCode: String? {
        UserDefaults.standard.string(forKey: Self.pendingCodeKey)
    }

    /// Un lien d'invitation vient d'ouvrir l'app : on garde le code jusqu'à la création du compte.
    func notePendingCode(_ code: String) {
        UserDefaults.standard.set(code, forKey: Self.pendingCodeKey)
        Task { await sync() }
    }

    private func clearPendingCode() {
        UserDefaults.standard.removeObject(forKey: Self.pendingCodeKey)
    }

    // MARK: - Serveur

    /// À l'ouverture et à chaque connexion : déclare le code en attente s'il y en a un, puis
    /// relit où en est le parrainage.
    func sync() async {
        guard AuthService.shared.isSignedIn else { return }
        if let code = pendingCode {
            let outcome = await claim(code: code)
            // Une erreur réseau garde le code pour la prochaine fois ; toute réponse du serveur le solde.
            if outcome != .failed { clearPendingCode() }
        }
        await refresh()
    }

    func refresh() async {
        guard AuthService.shared.isSignedIn else { return }
        struct Status: Decodable {
            let invited: Int
            let rewarded: Bool
            let can_claim: Bool
        }
        do {
            let status: Status = try await client
                .rpc("referral_status")
                .execute()
                .value
            invitedCount = status.invited
            canClaim = status.can_claim
            // Une récompense acquise le reste, même si le serveur ne répond plus pareil.
            if status.rewarded, !rewarded {
                rewarded = true
                UserDefaults.standard.set(true, forKey: Self.rewardedKey)
            }
        } catch {
            // Hors ligne ou fonction pas encore déployée : on garde le dernier état connu.
        }
    }

    /// Déclare le code (@) de celui qui m'a invité.
    @discardableResult
    func claim(code raw: String) async -> ClaimOutcome {
        guard AuthService.shared.isSignedIn else { return .notSignedIn }
        guard let code = SophiaDeepLink.validFriendHandle(raw) else { return .unknownCode }
        struct Params: Encodable { let p_code: String }
        do {
            let result: String = try await client
                .rpc("claim_referral", params: Params(p_code: code))
                .execute()
                .value
            switch result {
            case "ok":
                canClaim = false
                return .ok
            case "unknown_code": return .unknownCode
            case "self": return .ownCode
            case "already_claimed":
                canClaim = false
                return .alreadyClaimed
            case "account_too_old":
                canClaim = false
                return .accountTooOld
            default: return .failed
            }
        } catch {
            return .failed
        }
    }

    /// Déconnexion : l'état du compte précédent ne doit pas rester à l'écran.
    func clearLocalState() {
        invitedCount = 0
        canClaim = false
        rewarded = false
        UserDefaults.standard.removeObject(forKey: Self.rewardedKey)
    }

    // MARK: - Partage

    /// L'adresse à partager : la page d'invitation du site, qui ouvre l'app si elle est installée.
    static func inviteURL(for handle: String) -> URL? {
        guard let cleaned = SophiaDeepLink.validFriendHandle(handle) else { return nil }
        return URL(string: "https://\(SophiaDeepLink.webHost)/invite/\(cleaned)")
    }

    /// Le message de partage : une phrase, le code, le lien.
    static func shareText(handle: String, language: AppLanguage) -> String {
        let link = inviteURL(for: handle)?.absoluteString ?? "https://\(SophiaDeepLink.webHost)"
        return String(format: AppLocalizable.string("invite.share.text", language: language), "@\(handle)", link)
    }
}
