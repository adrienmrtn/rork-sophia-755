import Foundation
import Observation
import Supabase

/// Conflit détecté au moment de lier un compte : la progression locale et celle du cloud
/// sont toutes deux non vides et divergentes. L'utilisateur choisit laquelle conserver.
nonisolated struct ProgressConflict: Identifiable, Sendable {
    let id = UUID()
    let local: UserProgress
    let remote: UserProgress
}

/// Synchronisation « offline-first » de `UserProgress`.
///
/// - Le local (`UserDefaults` via `ProgressManager`) reste la source de vérité pour l'UX,
///   l'app fonctionne hors ligne.
/// - Quand une session Supabase existe, chaque changement est poussé (upsert, debouncé) dans
///   `public.user_progress.progress`, et lu au lancement pour le multi-appareils.
/// - À la liaison d'un compte, si local ET cloud contiennent des données divergentes, on
///   demande à l'utilisateur (choix explicite) plutôt que d'écraser.
@Observable
@MainActor
final class ProgressSyncService {
    static let shared = ProgressSyncService()

    /// Conflit en attente de résolution par l'utilisateur (piloté par l'UI racine).
    var pendingConflict: ProgressConflict?

    private let client = SupabaseManager.shared
    private weak var progressManager: ProgressManager?
    private var pushTask: Task<Void, Never>?
    private let pushDebounce: UInt64 = 2_500_000_000 // 2,5 s

    private init() {}

    // MARK: - Wiring

    func attach(_ manager: ProgressManager) {
        progressManager = manager
    }

    // MARK: - Push (local → cloud)

    /// Programme un envoi debouncé de la progression locale vers le cloud (no-op si déconnecté).
    func schedulePush(_ progress: UserProgress) {
        guard AuthService.shared.isSignedIn else { return }
        let snapshot = progress
        pushTask?.cancel()
        pushTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: self?.pushDebounce ?? 2_500_000_000)
            guard !Task.isCancelled else { return }
            await self?.push(snapshot)
        }
    }

    /// Envoi immédiat (ex. avant déconnexion), best-effort.
    func pushNow(_ progress: UserProgress) async {
        guard AuthService.shared.isSignedIn else { return }
        await push(progress)
    }

    private func push(_ progress: UserProgress) async {
        guard let userID = AuthService.shared.currentUser?.id.uuidString else { return }
        let row = UpsertProgressRow(user_id: userID, progress: progress)
        do {
            try await client
                .from("user_progress")
                .upsert(row, onConflict: "user_id")
                .execute()
        } catch {
            #if DEBUG
            print("[ProgressSync] push failed: \(error)")
            #endif
        }
    }

    // MARK: - Pull (cloud → local)

    private func fetchRemote() async -> UserProgress? {
        guard let userID = AuthService.shared.currentUser?.id.uuidString else { return nil }
        do {
            let rows: [RemoteProgressRow] = try await client
                .from("user_progress")
                .select("progress")
                .eq("user_id", value: userID)
                .limit(1)
                .execute()
                .value
            return rows.first?.progress
        } catch {
            #if DEBUG
            print("[ProgressSync] fetch failed: \(error)")
            #endif
            return nil
        }
    }

    // MARK: - Orchestration

    /// À appeler juste après une connexion réussie (liaison de compte). Décide quoi conserver ;
    /// remonte un conflit si local et cloud divergent tous les deux.
    func syncAfterSignIn() async {
        guard let manager = progressManager else {
            // Pas de ProgressManager actif (ex. connexion pendant l'onboarding) :
            // on pousse la progression locale telle quelle si elle existe.
            return
        }
        let local = manager.progress
        let remote = await fetchRemote()

        guard let remote, !remote.isEssentiallyEmpty else {
            await push(local)
            return
        }
        if local.isEssentiallyEmpty {
            manager.applyRemoteProgress(remote)
            return
        }
        if remote.syncSignalScore == local.syncSignalScore {
            // Considérées équivalentes : on adopte le cloud, pas besoin de déranger l'utilisateur.
            manager.applyRemoteProgress(remote)
            return
        }
        pendingConflict = ProgressConflict(local: local, remote: remote)
    }

    /// À appeler au lancement quand une session existe déjà. Le cloud est privilégié pour
    /// rester cohérent en multi-appareils, sauf si le local est plus avancé (gains hors ligne).
    func syncAtLaunch() async {
        guard let manager = progressManager else { return }
        let local = manager.progress
        let remote = await fetchRemote()

        guard let remote, !remote.isEssentiallyEmpty else {
            await push(local)
            return
        }
        if local.syncSignalScore > remote.syncSignalScore {
            await push(local)
        } else {
            manager.applyRemoteProgress(remote)
        }
    }

    /// Résout un conflit selon le choix de l'utilisateur.
    func resolveConflict(keepLocal: Bool) async {
        guard let manager = progressManager, let conflict = pendingConflict else {
            pendingConflict = nil
            return
        }
        if keepLocal {
            await push(conflict.local)
        } else {
            manager.applyRemoteProgress(conflict.remote)
        }
        pendingConflict = nil
    }

    // MARK: - Rows

    private struct UpsertProgressRow: Encodable {
        let user_id: String
        let progress: UserProgress
    }

    private struct RemoteProgressRow: Decodable {
        let progress: UserProgress
    }
}
