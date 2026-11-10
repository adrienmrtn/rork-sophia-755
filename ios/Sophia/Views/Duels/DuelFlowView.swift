import SwiftUI

/// Une session de duel en plein écran : recherche de l'adversaire, partie, résultat ; « Rejouer »
/// repart sur une recherche sans quitter l'écran.
struct DuelFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    let handle: String
    let avatarId: String?
    let service: DuelService

    private enum Stage: Equatable {
        case matchmaking
        case playing
        case result
    }

    @State private var stage: Stage = .matchmaking
    @State private var game: DuelGameModel?
    @State private var summary: DuelSummary?
    @State private var result: DuelResult?
    @State private var resultFailed = false
    /// Numéro de la partie dans cette session : une nouvelle recherche repart d'un écran neuf.
    @State private var round = 0
    /// La page telle qu'elle était au lancement de la partie : le résultat s'anime depuis elle.
    @State private var homeAtStart: DuelHome?
    /// L'instant où l'app est passée à l'arrière-plan pendant une partie.
    @State private var leftAppAt: Date?

    /// Au-delà, quitter l'app en pleine partie est un abandon : un adversaire ne reste pas à
    /// attendre dix minutes. En deçà (une notification, un appel refusé), la partie continue,
    /// et le chrono de la question a tourné pendant l'absence.
    private static let maxAbsence: TimeInterval = 15

    private var player: DuelPlayerIdentity {
        DuelPlayerIdentity(handle: handle, avatarId: avatarId, trophies: service.home?.profile.trophies ?? 0)
    }

    var body: some View {
        ZStack {
            DuelPalette.night.ignoresSafeArea()

            switch stage {
            case .matchmaking:
                DuelMatchmakingView(
                    player: player,
                    league: service.home?.currentLeague,
                    onReady: start,
                    onCancel: { dismiss() }
                )
                .id(round)
                .transition(.opacity)
            case .playing:
                if let game {
                    DuelGameView(
                        model: game,
                        player: player,
                        onFinished: {
                            // Un abandon a pu passer juste avant : il garde la main.
                            if stage == .playing { finish(game.summary) }
                        },
                        onAbandon: { abandon(game) }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            case .result:
                if let summary {
                    DuelResultView(
                        summary: summary,
                        player: player,
                        home: homeAtStart ?? service.home,
                        result: result,
                        resultFailed: resultFailed,
                        onRetrySend: { send(summary) },
                        onPlayAgain: playAgain,
                        onDone: { dismiss() }
                    )
                    .id(summary.match.matchId)
                    .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: stage)
        .interactiveDismissDisabled()
        .statusBarHidden()
        .onAppear { service.isPlaying = true }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                if stage == .playing, leftAppAt == nil { leftAppAt = Date() }
            case .active:
                defer { leftAppAt = nil }
                guard let leftAppAt, stage == .playing, let game, game.phase != .finished,
                      Date().timeIntervalSince(leftAppAt) > Self.maxAbsence else { return }
                abandon(game)
            default:
                break
            }
        }
        .onDisappear {
            service.isPlaying = false
            Task {
                await service.refreshHome()
                await service.refreshLeaderboard()
            }
        }
    }

    private func start(_ match: DuelMatch) {
        homeAtStart = service.home
        game = DuelGameModel(match: match)
        stage = .playing
    }

    private func finish(_ summary: DuelSummary) {
        self.summary = summary
        result = nil
        stage = .result
        send(summary)
    }

    /// Quitter en pleine partie : une défaite, envoyée telle quelle au serveur.
    private func abandon(_ game: DuelGameModel) {
        finish(DuelSummary(
            match: game.match,
            playerScore: game.playerScore,
            opponentScore: game.opponentScore,
            won: false,
            abandoned: true,
            tiebreak: false,
            answers: game.answers,
            pick: game.myPick
        ))
    }

    private func send(_ summary: DuelSummary) {
        resultFailed = false
        let matchId = summary.match.matchId
        Task {
            // La réponse d'une partie précédente (réseau lent, puis « Rejouer ») ne doit pas
            // s'afficher sur le résultat de la suivante.
            do {
                let value = try await service.finishMatch(matchId: matchId, answers: summary.answers, abandoned: summary.abandoned, pick: summary.pick)
                guard self.summary?.match.matchId == matchId else { return }
                result = value
            } catch {
                guard self.summary?.match.matchId == matchId else { return }
                resultFailed = true
            }
        }
    }

    private func playAgain() {
        game = nil
        summary = nil
        result = nil
        resultFailed = false
        round += 1
        stage = .matchmaking
    }
}
