import SwiftUI

/// Une session de duel en plein écran : recherche de l'adversaire, partie, résultat ; « Rejouer »
/// repart sur une recherche sans quitter l'écran.
struct DuelFlowView: View {
    @Environment(\.dismiss) private var dismiss
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
                        onFinished: { finish(game.summary) },
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
        .onAppear { service.isPlaying = true }
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
            answers: game.answers
        ))
    }

    private func send(_ summary: DuelSummary) {
        resultFailed = false
        Task {
            do {
                result = try await service.finishMatch(
                    matchId: summary.match.matchId,
                    answers: summary.answers,
                    abandoned: summary.abandoned
                )
            } catch {
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
