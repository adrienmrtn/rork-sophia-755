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
    /// Duel entre amis : aucun trophée en jeu, et une égalité parfaite est possible.
    var friendly = false
    var draw = false
    /// La matière que le joueur a choisie pour sa manche (duel classé : le serveur en a besoin
    /// pour recompter le score).
    var pick: String? = nil
}

/// Le lien d'une partie entre amis avec le serveur : la partie, et l'instant (sur l'horloge de
/// l'appareil) où sa première question démarre pour les deux joueurs.
nonisolated struct DuelLiveLink: Sendable, Equatable {
    let matchId: UUID
    let startsAt: Date
}

/// Le déroulé d'une partie : 20 questions l'une après l'autre, chacune avec son chrono, puis une
/// question décisive en cas d'égalité. L'adversaire « répond » aux instants écrits par le serveur
/// (`DuelMatch.bot`), un peu plus tôt si le joueur a déjà répondu, pour ne pas le faire attendre.
/// Le score affiché est recompté par le serveur à la fin, avec les mêmes règles (`DuelScoring`).
///
/// Entre amis (`live`), il n'y a pas de script : les deux joueurs répondent en même temps et le
/// serveur tient l'horloge. Le modèle lui envoie chaque réponse, l'interroge plusieurs fois par
/// seconde, et suit ce qu'il dit : l'ami a répondu, la question est close (avec sa réponse et
/// les points de chacun), la suivante démarre dans tant de millisecondes.
@Observable
@MainActor
final class DuelGameModel {
    enum Phase: Equatable {
        /// Le chrono tourne.
        case answering
        /// Les réponses sont dévoilées.
        case reveal
        /// L'annonce d'une manche : matière à choisir, matière choisie par l'adversaire, sprint.
        case roundIntro
        /// L'annonce de la question décisive.
        case suddenDeathIntro
        case finished
    }

    /// Ce que montre l'annonce d'une manche.
    struct RoundIntro: Equatable {
        let number: Int
        let kind: DuelRoundKind
        /// Manche au choix : c'est à moi de choisir.
        let mine: Bool
        /// Les matières proposées, quand c'est à moi de choisir.
        let options: [String]
        /// La matière retenue, une fois connue.
        var chosen: String?
        /// Le temps laissé pour choisir : son début et sa fin.
        var opensAt = Date()
        var deadline: Date?
    }

    let match: DuelMatch
    /// Présent pour une partie entre amis.
    let live: DuelLiveLink?

    private(set) var index = 0
    private(set) var phase: Phase = .answering
    private(set) var roundIntro: RoundIntro?
    /// Les matières des manches au choix déjà fixées, par numéro de manche.
    private(set) var roundSubjects: [Int: String] = [:]
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
    /// Partie entre amis finie sur une égalité parfaite (personne n'a répondu à la question décisive).
    private(set) var isDraw = false
    /// L'ami a quitté la partie : on la finit seul.
    private(set) var opponentLeft = false

    /// Le dernier état reçu du serveur, et l'instant de sa réception.
    @ObservationIgnored private var liveState: DuelFriendState?
    @ObservationIgnored private var liveStateAt = Date()
    /// Les réponses de l'ami aux questions closes, sous la forme que l'écran sait dévoiler.
    @ObservationIgnored private var liveOpponent: [Int: DuelBotAnswer] = [:]
    /// Ma réponse à la question en cours, pas encore reçue par le serveur.
    @ObservationIgnored private var unsent: (index: Int, answer: DuelAnswer)?
    @ObservationIgnored private var isRefreshing = false
    /// Mon choix de matière, pas encore reçu par le serveur (partie entre amis).
    @ObservationIgnored private var unsentPick: (round: Int, subject: String)?
    /// Les questions des manches déjà commencées, dans l'ordre où elles se jouent, et en duel
    /// classé les réponses de l'adversaire à ces questions.
    @ObservationIgnored private var playedQuestions: [DuelQuestion] = []
    @ObservationIgnored private var playedBot: [DuelBotAnswer] = []
    /// Une réponse est arrivée pendant un échange en cours : il faut en refaire un aussitôt.
    @ObservationIgnored private var refreshAgain = false

    @ObservationIgnored private var sliderTouched = false
    @ObservationIgnored private var playerLockTime: Double?
    @ObservationIgnored private var opponentDelay: Double = 1
    @ObservationIgnored private var lastSliderTick = Date.distantPast

    init(match: DuelMatch, live: DuelLiveLink? = nil) {
        self.match = match
        self.live = live
        playerMarks = Array(repeating: nil, count: match.questionCount)
        opponentMarks = Array(repeating: nil, count: match.questionCount)
        // La première manche est connue d'avance : sa première question est à l'écran dès le
        // premier affichage, avant même que la partie ne démarre.
        if let first = match.rounds.first, first.kind != .pick {
            playedQuestions = first.questions ?? []
            playedBot = Array((first.bot ?? []).prefix(playedQuestions.count))
        }
    }

    var questionCount: Int { match.questionCount }

    /// La question en cours. Les questions d'une manche ne sont connues qu'à son début (une
    /// manche au choix dépend de la matière retenue).
    var question: DuelQuestion {
        if index >= questionCount { return match.tiebreak }
        if index < playedQuestions.count { return playedQuestions[index] }
        return playedQuestions.last ?? match.tiebreak
    }

    /// Le numéro de la manche en cours (1 à 4).
    var roundNumber: Int {
        min(index / DuelMatch.questionsPerRound, max(match.rounds.count - 1, 0)) + 1
    }

    /// La matière de la manche en cours, quand c'est une manche au choix.
    var currentSubject: String? {
        index < questionCount ? roundSubjects[roundNumber] : nil
    }

    /// La réponse de l'adversaire à la question en cours : le script du serveur en duel classé,
    /// la vraie réponse de l'ami (connue une fois la question close) en duel amical.
    var botAnswer: DuelBotAnswer {
        if live != nil {
            return liveOpponent[index] ?? DuelBotAnswer(correct: false, choice: nil, value: nil, timeMs: question.timeLimitMs)
        }
        if index >= questionCount, let tiebreakBot = match.tiebreakBot {
            return tiebreakBot
        }
        guard index < playedBot.count else {
            return DuelBotAnswer(correct: false, choice: nil, value: nil, timeMs: question.timeLimitMs / 2)
        }
        return playedBot[index]
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
            answers: answers,
            friendly: live != nil,
            draw: isDraw,
            pick: myPick
        )
    }

    /// La matière que j'ai choisie pour ma manche au choix.
    var myPick: String? {
        guard let mine = match.rounds.first(where: { $0.isMyPick }) else { return nil }
        return roundSubjects[mine.number]
    }

    // MARK: - Actions du joueur

    /// Choisit la matière de la manche annoncée (quand c'est à moi de choisir).
    func pickSubject(_ subject: String) {
        guard phase == .roundIntro, let intro = roundIntro, intro.mine, intro.chosen == nil,
              intro.options.contains(subject) else { return }
        // Passé le délai, le choix n'arriverait plus à temps au serveur.
        if let deadline = intro.deadline, Date() >= deadline { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            roundIntro?.chosen = subject
        }
        DuelHaptics.lock()
        if live != nil {
            unsentPick = (intro.number, subject)
            Task { await refreshLive() }
        }
    }

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
        if live != nil {
            queueLiveAnswer()
        }
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
        if let live {
            await runLive(live)
            return
        }
        for (r, plan) in match.rounds.enumerated() {
            if r > 0 {
                guard await announce(plan) else { return }
            }
            // La première manche est déjà en place (voir `init`).
            let preloaded = r == 0 && !playedQuestions.isEmpty
            let first = preloaded ? 0 : playedQuestions.count
            let count = preloaded ? playedQuestions.count : resolve(plan).count
            for k in 0..<count {
                guard await play(first + k) else { return }
            }
        }
        if playerScore == opponentScore {
            isSuddenDeath = true
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                phase = .suddenDeathIntro
            }
            DuelHaptics.suddenDeath()
            guard await pause(2.4) else { return }
            guard await play(questionCount) else { return }
        } else {
            playerWon = playerScore > opponentScore
        }
        phase = .finished
    }

    // MARK: - Manches (duel classé)

    /// Les questions d'une manche (et les réponses de l'adversaire), ajoutées à la suite de
    /// celles déjà jouées. Manche au choix : celles de la matière retenue.
    private func resolve(_ plan: DuelRoundPlan) -> [DuelQuestion] {
        var questions = plan.questions ?? []
        var bot = plan.bot ?? []
        if plan.isMyPick, let options = plan.options, !options.isEmpty {
            let option = options.first(where: { $0.subject == roundSubjects[plan.number] }) ?? options[0]
            roundSubjects[plan.number] = option.subject
            questions = option.questions
            bot = option.bot ?? []
        } else if plan.kind == .pick, let subject = plan.subject {
            roundSubjects[plan.number] = subject
        }
        // Une manche tient toujours cinq places dans la partie, même si le serveur en livre moins.
        while playedBot.count < playedQuestions.count { playedBot.append(DuelBotAnswer(correct: false, choice: nil, value: nil, timeMs: 4000)) }
        playedQuestions.append(contentsOf: questions)
        playedBot.append(contentsOf: bot.prefix(questions.count))
        return questions
    }

    /// L'annonce d'une manche. Au choix : huit secondes pour choisir parmi les trois matières
    /// proposées (passé ce délai, la première) ; ou l'adversaire « réfléchit » puis sa matière
    /// se dévoile. Sprint : le temps de lire l'annonce.
    private func announce(_ plan: DuelRoundPlan) async -> Bool {
        switch plan.kind {
        case .mixed:
            return true
        case .sprint:
            show(RoundIntro(number: plan.number, kind: .sprint, mine: false, options: []))
            return await pause(2.8)
        case .pick:
            if plan.isMyPick {
                let subjects = (plan.options ?? []).map(\.subject)
                let deadline = Date().addingTimeInterval(8)
                show(RoundIntro(number: plan.number, kind: .pick, mine: true, options: subjects, deadline: deadline))
                while roundIntro?.chosen == nil, Date() < deadline {
                    guard await pause(0.05) else { return false }
                }
                if roundIntro?.chosen == nil, let fallback = subjects.first {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { roundIntro?.chosen = fallback }
                }
                roundSubjects[plan.number] = roundIntro?.chosen
                return await pause(1.3)
            }
            show(RoundIntro(number: plan.number, kind: .pick, mine: false, options: []))
            guard await pause(2.4) else { return false }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) { roundIntro?.chosen = plan.subject }
            DuelHaptics.opponentAnswered()
            return await pause(1.7)
        }
    }

    private func show(_ intro: RoundIntro) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            roundIntro = intro
            phase = .roundIntro
        }
        DuelHaptics.opponentFound()
    }

    private func play(_ i: Int) async -> Bool {
        let isTiebreak = i >= questionCount
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

    // MARK: - Partie entre amis

    /// Ma réponse à la question en cours, telle qu'elle part au serveur.
    private func currentAnswer() -> DuelAnswer {
        let limit = question.timeLimit
        let elapsedMs = Int((playerLockTime ?? limit) * 1000)
        var answer = DuelAnswer(c: nil, v: nil, t: min(elapsedMs, question.timeLimitMs))
        if question.kind == .slider {
            answer.v = sliderTouched ? sliderValue : nil
        } else {
            answer.c = selectedChoice
        }
        return answer
    }

    private func queueLiveAnswer() {
        unsent = (index, currentAnswer())
        Task { await refreshLive() }
    }

    /// Un échange avec le serveur : ma réponse si elle n'est pas encore partie, sinon l'état de
    /// la partie. Un échec (réseau) est simplement retenté au tour suivant.
    private func refreshLive() async {
        guard let live else { return }
        if isRefreshing {
            refreshAgain = true
            return
        }
        isRefreshing = true
        defer { isRefreshing = false }
        let matchId = live.matchId
        repeat {
            refreshAgain = false
            do {
                let state: DuelFriendState
                if let pick = unsentPick {
                    state = try await DuelTimeout.run(seconds: 5) {
                        try await DuelLiveService.shared.pick(matchId: matchId, round: pick.round, subject: pick.subject)
                    }
                    if unsentPick?.round == pick.round {
                        unsentPick = nil
                    }
                } else if let pending = unsent {
                    // Bornés à 5 s : une requête qui ne revient pas ne doit pas figer la partie.
                    state = try await DuelTimeout.run(seconds: 5) {
                        try await DuelLiveService.shared.answer(matchId: matchId, index: pending.index, answer: pending.answer)
                    }
                    if unsent?.index == pending.index {
                        unsent = nil
                    }
                } else {
                    state = try await DuelTimeout.run(seconds: 5) {
                        try await DuelLiveService.shared.state(matchId: matchId)
                    }
                }
                liveState = state
                liveStateAt = Date()
            } catch {
                #if DEBUG
                print("[Duel] live refresh failed: \(error)")
                #endif
                break
            }
        } while refreshAgain && !Task.isCancelled
    }

    private func runLive(_ live: DuelLiveLink) async {
        let poller = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshLive()
                try? await Task.sleep(for: .milliseconds(700))
            }
        }
        defer { poller.cancel() }

        var i = 0
        var startsAt = live.startsAt
        while true {
            // Une nouvelle manche commence : son annonce occupe le temps qui la précède.
            if i > 0, i < questionCount, i % DuelMatch.questionsPerRound == 0, i >= playedQuestions.count {
                guard await announceLive(match.rounds[i / DuelMatch.questionsPerRound], startsAt: startsAt) else { return }
            }
            // La question démarre au même instant pour les deux joueurs.
            while Date() < startsAt {
                guard await pause(0.05) else { return }
            }
            guard await resolveLive(through: i) else { return }
            guard let state = await playLive(i, startedAt: startsAt) else { return }

            if state.finished {
                playerWon = state.won ?? false
                isDraw = state.draw
                guard await pause(question.kind == .slider ? 3.0 : 2.2) else { return }
                phase = .finished
                return
            }

            let next = max(state.index, i + 1)
            startsAt = liveStateAt.addingTimeInterval(Double(state.questionStartsInMs) / 1000)
            if next >= questionCount, !isSuddenDeath {
                // Égalité après la dernière question : l'annonce, puis la question décisive.
                guard await pause(2.4) else { return }
                isSuddenDeath = true
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    phase = .suddenDeathIntro
                }
                DuelHaptics.suddenDeath()
            }
            i = next
        }
    }

    /// L'annonce d'une manche en direct, jusqu'à l'instant où sa première question démarre. Au
    /// choix : celui qui choisit a jusqu'à 1,5 s avant le départ ; l'autre voit la matière dès
    /// que le serveur la connaît.
    private func announceLive(_ plan: DuelRoundPlan, startsAt: Date) async -> Bool {
        guard plan.kind != .mixed else { return true }
        // En retard sur le serveur (coupure réseau) : pas d'annonce, on rattrape la partie.
        guard startsAt.timeIntervalSinceNow > 2.5 else { return true }
        // La révélation de la question précédente reste un instant à l'écran.
        guard await pause(2.0) else { return false }
        let mine = plan.isMyPick
        show(RoundIntro(
            number: plan.number,
            kind: plan.kind,
            mine: mine,
            options: mine ? (plan.options ?? []).map(\.subject) : [],
            deadline: mine ? startsAt.addingTimeInterval(-1.5) : nil
        ))
        while Date() < startsAt {
            guard await pause(0.05) else { return false }
            guard plan.kind == .pick else { continue }
            if let chosen = liveState?.picks?[String(plan.number)], roundIntro?.chosen != chosen {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) { roundIntro?.chosen = chosen }
                if !mine { DuelHaptics.opponentAnswered() }
            } else if mine, roundIntro?.chosen == nil, let deadline = roundIntro?.deadline, Date() >= deadline,
                      let fallback = plan.options?.first?.subject {
                // Pas de choix à temps : la première matière proposée, celle que le serveur retient.
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { roundIntro?.chosen = fallback }
            }
        }
        return true
    }

    /// Fixe les questions des manches jusqu'à la question `i` (plusieurs d'un coup après une
    /// coupure réseau). Pour une manche au choix, attend que le serveur donne la matière.
    private func resolveLive(through i: Int) async -> Bool {
        while playedQuestions.count <= i, i < questionCount {
            let plan = match.rounds[min(playedQuestions.count / DuelMatch.questionsPerRound, match.rounds.count - 1)]
            var questions = plan.questions ?? []
            if plan.kind == .pick {
                var subject = liveState?.picks?[String(plan.number)]
                while subject == nil {
                    // Sans choix, le serveur ne fixe la matière qu'au départ de la manche : on
                    // la lui demande tout de suite plutôt que d'attendre le prochain tour.
                    await refreshLive()
                    guard await pause(0.05) else { return false }
                    subject = liveState?.picks?[String(plan.number)]
                }
                let options = plan.options ?? []
                questions = (options.first(where: { $0.subject == subject }) ?? options.first)?.questions ?? []
                roundSubjects[plan.number] = subject
            }
            guard !questions.isEmpty else { return false }
            playedQuestions.append(contentsOf: questions)
        }
        return true
    }

    /// Joue une question en direct : jusqu'à ce que le serveur la close. Rend l'état reçu à ce
    /// moment-là, ou nil si la tâche est annulée.
    private func playLive(_ i: Int, startedAt: Date) async -> DuelFriendState? {
        let isTiebreak = i >= questionCount
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
        questionStart = startedAt

        let limit = current.timeLimit
        var lastClock = Int.max
        var closed: DuelFriendState?
        while closed == nil {
            guard await pause(0.05) else { return nil }
            let elapsed = Date().timeIntervalSince(questionStart)
            if let state = liveState {
                if state.opponentLeft != opponentLeft {
                    withAnimation { opponentLeft = state.opponentLeft }
                }
                if state.resolved > i || state.finished {
                    closed = state
                    break
                }
                if state.index == i, state.opponentAnswered, !opponentAnswered {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        opponentAnswered = true
                    }
                    DuelHaptics.opponentAnswered()
                }
            }
            if elapsed >= limit, !playerLocked {
                // Temps écoulé : le serveur est prévenu, pour ne pas faire attendre l'ami.
                playerLocked = true
                playerLockTime = limit
                queueLiveAnswer()
            }
            let remaining = Int((limit - elapsed).rounded(.up))
            if remaining <= 3, remaining > 0, remaining < lastClock, !playerLocked {
                lastClock = remaining
                DuelHaptics.clock()
            }
        }
        guard let state = closed else { return nil }
        frozenFraction = remainingFraction(at: Date())

        answers.append(currentAnswer())
        // La réponse de l'ami et les points de chacun viennent du serveur, qui fait foi.
        if i < state.opponentAnswers.count {
            let theirs = state.opponentAnswers[i]
            let theirPoint = i < state.opponentPoints.count ? state.opponentPoints[i] : false
            liveOpponent[i] = DuelBotAnswer(correct: theirPoint, choice: theirs.c, value: theirs.v, timeMs: theirs.t)
        }
        let round = DuelRound(
            player: i < state.myPoints.count ? state.myPoints[i] : false,
            opponent: i < state.opponentPoints.count ? state.opponentPoints[i] : false
        )
        withAnimation(.spring(response: 0.38, dampingFraction: 0.62)) {
            playerLocked = true
            opponentAnswered = true
            lastRound = round
            phase = .reveal
            if !isTiebreak {
                playerScore = state.myScore
                opponentScore = state.opponentScore
                // Les questions closes pendant une coupure réseau sont marquées d'un coup.
                for k in 0..<min(state.resolved, playerMarks.count) {
                    if k < state.myPoints.count { playerMarks[k] = state.myPoints[k] }
                    if k < state.opponentPoints.count { opponentMarks[k] = state.opponentPoints[k] }
                }
            }
        }
        if round.player {
            DuelHaptics.correct()
        } else {
            DuelHaptics.wrong()
        }
        return state
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
