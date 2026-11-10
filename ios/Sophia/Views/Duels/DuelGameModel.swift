import Foundation
import Observation
import SwiftUI

/// Qui a marqué sur une question.
nonisolated struct DuelRound: Sendable, Equatable {
    let player: Bool
    let opponent: Bool
}

/// Le joueur tel qu'il s'affiche face à son adversaire.
nonisolated struct DuelPlayerIdentity: Sendable, Equatable {
    let handle: String
    let avatarId: String?
    let trophies: Int

    var initial: String { String(handle.prefix(1)).uppercased() }
}

/// Ce que l'app sait d'une partie dès qu'elle se termine, avant la réponse du serveur.
nonisolated struct DuelSummary: Sendable, Equatable {
    let match: DuelMatch
    let playerScore: Int
    let opponentScore: Int
    let won: Bool
    let abandoned: Bool
    let tiebreak: Bool
    let answers: [DuelAnswer]
}

/// Le déroulé d'une partie : 20 questions l'une après l'autre, chacune avec son chrono, puis une
/// question décisive en cas d'égalité. L'adversaire « répond » aux instants écrits par le serveur
/// (`DuelMatch.bot`), un peu plus tôt si le joueur a déjà répondu, pour ne pas le faire attendre.
/// Le score affiché est recompté par le serveur à la fin, avec les mêmes règles (`DuelScoring`).
@Observable
@MainActor
final class DuelGameModel {
    enum Phase: Equatable {
        /// Le chrono tourne.
        case answering
        /// Les réponses sont dévoilées.
        case reveal
        /// L'annonce de la question décisive.
        case suddenDeathIntro
        case finished
    }

    let match: DuelMatch

    private(set) var index = 0
    private(set) var phase: Phase = .answering
    private(set) var playerScore = 0
    private(set) var opponentScore = 0
    /// Une case par question : le camp a-t-il marqué ? `nil` tant que la question n'est pas jouée.
    private(set) var playerMarks: [Bool?]
    private(set) var opponentMarks: [Bool?]
    private(set) var answers: [DuelAnswer] = []

    // La question en cours.
    private(set) var selectedChoice: Int?
    private(set) var sliderValue: Double = 0
    private(set) var playerLocked = false
    private(set) var opponentAnswered = false
    private(set) var questionStart = Date()
    /// Part du temps restant figée à la révélation (le cadran s'arrête).
    private(set) var frozenFraction: Double = 1
    private(set) var lastRound: DuelRound?
    private(set) var isSuddenDeath = false
    private(set) var playerWon = false

    @ObservationIgnored private var sliderTouched = false
    @ObservationIgnored private var playerLockTime: Double?
    @ObservationIgnored private var opponentDelay: Double = 1
    @ObservationIgnored private var lastSliderTick = Date.distantPast

    init(match: DuelMatch) {
        self.match = match
        playerMarks = Array(repeating: nil, count: match.questions.count)
        opponentMarks = Array(repeating: nil, count: match.questions.count)
    }

    var questionCount: Int { match.questions.count }

    var question: DuelQuestion {
        index < match.questions.count ? match.questions[index] : match.tiebreak
    }

    var botAnswer: DuelBotAnswer {
        guard !match.bot.isEmpty else {
            return DuelBotAnswer(correct: false, choice: nil, value: nil, timeMs: question.timeLimitMs / 2)
        }
        return match.bot[min(index, match.bot.count - 1)]
    }

    /// Part du temps restant (1 → 0) à un instant donné, pour le cadran.
    func remainingFraction(at date: Date) -> Double {
        guard phase == .answering else { return frozenFraction }
        let limit = question.timeLimit
        guard limit > 0 else { return 0 }
        return min(max(1 - date.timeIntervalSince(questionStart) / limit, 0), 1)
    }

    var summary: DuelSummary {
        DuelSummary(
            match: match,
            playerScore: playerScore,
            opponentScore: opponentScore,
            won: playerWon,
            abandoned: false,
            tiebreak: isSuddenDeath,
            answers: answers
        )
    }

    // MARK: - Actions du joueur

    func choose(_ option: Int) {
        guard phase == .answering, !playerLocked, question.kind != .slider else { return }
        selectedChoice = option
        lockPlayer()
    }

    func setSlider(_ raw: Double) {
        guard phase == .answering, !playerLocked, question.kind == .slider else { return }
        let snapped = snap(raw)
        guard snapped != sliderValue else { return }
        sliderValue = snapped
        sliderTouched = true
        if Date().timeIntervalSince(lastSliderTick) > 0.045 {
            lastSliderTick = Date()
            DuelHaptics.tick()
        }
    }

    func nudgeSlider(by steps: Double) {
        setSlider(sliderValue + steps * (question.sliderStep ?? 1))
    }

    func lockSlider() {
        guard phase == .answering, !playerLocked, question.kind == .slider else { return }
        sliderTouched = true
        lockPlayer()
    }

    private func lockPlayer() {
        playerLocked = true
        playerLockTime = Date().timeIntervalSince(questionStart)
        opponentDelay = Double.random(in: 0.5...1.4)
        DuelHaptics.lock()
    }

    private func snap(_ raw: Double) -> Double {
        let lower = question.sliderMin ?? 0
        let upper = question.sliderMax ?? 100
        let step = max(question.sliderStep ?? 1, 0.000_001)
        let stepped = lower + ((raw - lower) / step).rounded() * step
        return min(max(stepped, lower), upper)
    }

    // MARK: - Déroulé

    /// Joue la partie jusqu'au bout. Revient plus tôt si la tâche est annulée (abandon, écran fermé).
    func run() async {
        for i in 0..<match.questions.count {
            guard await play(i) else { return }
        }
        if playerScore == opponentScore {
            isSuddenDeath = true
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                phase = .suddenDeathIntro
            }
            DuelHaptics.suddenDeath()
            guard await pause(2.4) else { return }
            guard await play(match.questions.count) else { return }
        } else {
            playerWon = playerScore > opponentScore
        }
        phase = .finished
    }

    private func play(_ i: Int) async -> Bool {
        let isTiebreak = i >= match.questions.count
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
            index = i
            selectedChoice = nil
            playerLocked = false
            opponentAnswered = false
            lastRound = nil
            frozenFraction = 1
            phase = .answering
        }
        let current = question
        sliderTouched = false
        playerLockTime = nil
        if current.kind == .slider {
            sliderValue = snap(((current.sliderMin ?? 0) + (current.sliderMax ?? 100)) / 2)
        }
        questionStart = Date()

        let limit = current.timeLimit
        var opponentTime = Double(botAnswer.timeMs) / 1000
        var lastClock = Int.max
        var bothAnswered = false
        while true {
            guard await pause(0.05) else { return false }
            let elapsed = Date().timeIntervalSince(questionStart)
            if let lockedAt = playerLockTime, !opponentAnswered {
                opponentTime = min(opponentTime, lockedAt + opponentDelay)
            }
            if !opponentAnswered, elapsed >= min(opponentTime, limit - 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    opponentAnswered = true
                }
                DuelHaptics.opponentAnswered()
            }
            if playerLocked && opponentAnswered {
                bothAnswered = true
                break
            }
            if elapsed >= limit { break }
            let remaining = Int((limit - elapsed).rounded(.up))
            if remaining <= 3, remaining < lastClock, !playerLocked {
                lastClock = remaining
                DuelHaptics.clock()
            }
        }
        if bothAnswered {
            guard await pause(0.35) else { return false }
        }
        frozenFraction = remainingFraction(at: Date())

        let elapsedMs = Int((playerLockTime ?? limit) * 1000)
        var answer = DuelAnswer(c: nil, v: nil, t: min(elapsedMs, current.timeLimitMs))
        if current.kind == .slider {
            answer.v = (playerLocked || sliderTouched) ? sliderValue : nil
        } else {
            answer.c = selectedChoice
        }
        answers.append(answer)

        let round: DuelRound
        if isTiebreak {
            playerWon = DuelScoring.playerWinsTiebreak(question: current, answer: answer, bot: botAnswer)
            round = DuelRound(player: playerWon, opponent: !playerWon)
        } else {
            let scored = DuelScoring.round(question: current, answer: answer, bot: botAnswer)
            round = DuelRound(player: scored.player, opponent: scored.opponent)
        }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.62)) {
            playerLocked = true
            opponentAnswered = true
            lastRound = round
            phase = .reveal
            if !isTiebreak {
                if round.player { playerScore += 1 }
                if round.opponent { opponentScore += 1 }
                playerMarks[i] = round.player
                opponentMarks[i] = round.opponent
            }
        }
        if round.player {
            DuelHaptics.correct()
        } else {
            DuelHaptics.wrong()
        }
        return await pause(current.kind == .slider ? 2.8 : 1.8)
    }

    private func pause(_ seconds: Double) async -> Bool {
        do {
            try await Task.sleep(for: .seconds(seconds))
            return !Task.isCancelled
        } catch {
            return false
        }
    }
}
