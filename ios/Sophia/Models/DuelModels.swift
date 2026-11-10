import Foundation

// Les duels : des parties de 20 questions contre un adversaire, avec des trophées et 30 ligues.
// Tout vient du serveur (fonctions `duel_*` de Supabase, voir docs/duels.md) : l'adversaire, les
// questions tirées au niveau du joueur, les réponses de l'adversaire, puis le résultat et les
// trophées. Ces types sont les réponses JSON de ces fonctions.

/// Une ligue : un seuil de trophées, un nom (une figure) et une illustration de fond.
nonisolated struct DuelLeague: Codable, Sendable, Identifiable, Equatable, Hashable {
    let position: Int
    let slug: String
    let name: String
    let minTrophies: Int
    let backgroundURL: String
    let thumbURL: String
    let accentHex: String

    var id: Int { position }

    enum CodingKeys: String, CodingKey {
        case position, slug, name
        case minTrophies = "min_trophies"
        case backgroundURL = "background_url"
        case thumbURL = "thumb_url"
        case accentHex = "accent_hex"
    }
}

/// Les trophées et les statistiques du joueur.
nonisolated struct DuelProfile: Codable, Sendable, Equatable {
    let trophies: Int
    let bestTrophies: Int
    let games: Int
    let wins: Int
    let losses: Int
    let winStreak: Int
    let bestWinStreak: Int
    let leaguePosition: Int

    /// Part de victoires, de 0 à 100 ; nil tant qu'aucune partie n'est jouée.
    var winRate: Int? {
        guard games > 0 else { return nil }
        return Int((Double(wins) / Double(games) * 100).rounded())
    }

    enum CodingKeys: String, CodingKey {
        case trophies, games, wins, losses
        case bestTrophies = "best_trophies"
        case winStreak = "win_streak"
        case bestWinStreak = "best_win_streak"
        case leaguePosition = "league_position"
    }
}

nonisolated struct DuelOpponent: Codable, Sendable, Equatable {
    let handle: String
    let countryCode: String
    let avatarId: String?
    let trophies: Int
    let leaguePosition: Int

    /// Le drapeau du pays (« 🇧🇷 »), composé depuis son code ISO à deux lettres.
    var flag: String {
        let scalars = countryCode.uppercased().unicodeScalars.compactMap { scalar -> Character? in
            guard (65...90).contains(scalar.value), let flagScalar = Unicode.Scalar(127_397 + scalar.value) else { return nil }
            return Character(flagScalar)
        }
        return scalars.count == 2 ? String(scalars) : ""
    }

    var initial: String { String(handle.prefix(1)).uppercased() }

    enum CodingKeys: String, CodingKey {
        case handle, trophies
        case countryCode = "country_code"
        case avatarId = "avatar_id"
        case leaguePosition = "league_position"
    }
}

/// Une partie terminée, dans l'historique de la page Duels.
nonisolated struct DuelRecentMatch: Codable, Sendable, Identifiable, Equatable {
    let matchId: UUID
    let opponent: DuelOpponent
    let won: Bool
    let abandoned: Bool
    let playerScore: Int
    let opponentScore: Int
    let trophiesDelta: Int

    var id: UUID { matchId }

    enum CodingKeys: String, CodingKey {
        case opponent, won, abandoned
        case matchId = "match_id"
        case playerScore = "player_score"
        case opponentScore = "opponent_score"
        case trophiesDelta = "trophies_delta"
    }
}

/// La page Duels : `duel_home()`.
nonisolated struct DuelHome: Codable, Sendable, Equatable {
    let handle: String?
    let profile: DuelProfile
    let leagues: [DuelLeague]
    let recent: [DuelRecentMatch]

    /// La ligue d'un nombre de trophées : la plus haute dont le seuil est atteint.
    func league(forTrophies trophies: Int) -> DuelLeague? {
        leagues.last(where: { $0.minTrophies <= max(trophies, 0) }) ?? leagues.first
    }

    func league(position: Int) -> DuelLeague? {
        leagues.first(where: { $0.position == position })
    }

    var currentLeague: DuelLeague? { league(forTrophies: profile.trophies) }

    func nextLeague(after league: DuelLeague?) -> DuelLeague? {
        guard let league else { return nil }
        return leagues.first(where: { $0.position == league.position + 1 })
    }

    /// Avancement (0 à 1) entre le seuil de la ligue du joueur et celui de la suivante.
    func leagueProgress(forTrophies trophies: Int) -> Double {
        guard let current = league(forTrophies: trophies) else { return 0 }
        guard let next = nextLeague(after: current) else { return 1 }
        let span = Double(next.minTrophies - current.minTrophies)
        guard span > 0 else { return 1 }
        return min(max(Double(trophies - current.minTrophies) / span, 0), 1)
    }
}

nonisolated enum DuelQuestionKind: String, Codable, Sendable {
    case mcq
    case trueFalse = "true_false"
    /// « Qui est-ce ? » : un QCM sur un portrait.
    case portrait
    /// Une valeur à estimer : le plus proche marque.
    case slider
}

nonisolated struct DuelQuestion: Codable, Sendable, Identifiable, Equatable {
    let id: String
    let kind: DuelQuestionKind
    let question: String
    let options: [String]?
    let correctIndex: Int?
    let imageURL: String?
    let imageCredit: String?
    let sliderMin: Double?
    let sliderMax: Double?
    let sliderStep: Double?
    let correctValue: Double?
    let unit: String?
    let timeLimitMs: Int

    var timeLimit: TimeInterval { Double(timeLimitMs) / 1000 }

    enum CodingKeys: String, CodingKey {
        case id, kind, question, options, unit
        case correctIndex = "correct_index"
        case imageURL = "image_url"
        case imageCredit = "image_credit"
        case sliderMin = "slider_min"
        case sliderMax = "slider_max"
        case sliderStep = "slider_step"
        case correctValue = "correct_value"
        case timeLimitMs = "time_limit_ms"
    }
}

/// La réponse de l'adversaire à une question, écrite par le serveur au lancement de la partie.
nonisolated struct DuelBotAnswer: Codable, Sendable, Equatable {
    let correct: Bool
    let choice: Int?
    let value: Double?
    let timeMs: Int

    enum CodingKeys: String, CodingKey {
        case correct, choice, value
        case timeMs = "time_ms"
    }
}

/// Une partie lancée : `duel_start_match()`.
nonisolated struct DuelMatch: Codable, Sendable, Equatable {
    let matchId: UUID
    let opponent: DuelOpponent
    let questions: [DuelQuestion]
    /// La question décisive, jouée seulement en cas d'égalité après les 20 questions.
    let tiebreak: DuelQuestion
    /// Une réponse par question, dans l'ordre ; la dernière est celle de la question décisive.
    let bot: [DuelBotAnswer]
    let searchMs: Int

    enum CodingKeys: String, CodingKey {
        case opponent, questions, tiebreak, bot
        case matchId = "match_id"
        case searchMs = "search_ms"
    }
}

/// La réponse du joueur à une question, telle qu'elle est envoyée au serveur.
nonisolated struct DuelAnswer: Codable, Sendable, Equatable {
    /// Index de l'option choisie (QCM, vrai/faux, portrait).
    var c: Int?
    /// Valeur choisie au curseur.
    var v: Double?
    /// Temps de réponse, en millisecondes.
    var t: Int
}

/// Le résultat d'une partie : `duel_finish_match()`.
nonisolated struct DuelResult: Codable, Sendable, Equatable {
    let matchId: UUID
    let won: Bool
    let abandoned: Bool
    let playerScore: Int
    let opponentScore: Int
    let tiebreak: Bool
    let trophiesBefore: Int
    let trophiesDelta: Int
    let trophiesAfter: Int
    let leagueBefore: Int
    let leagueAfter: Int
    let profile: DuelProfile

    var promoted: Bool { leagueAfter > leagueBefore }

    enum CodingKeys: String, CodingKey {
        case won, abandoned, tiebreak, profile
        case matchId = "match_id"
        case playerScore = "player_score"
        case opponentScore = "opponent_score"
        case trophiesBefore = "trophies_before"
        case trophiesDelta = "trophies_delta"
        case trophiesAfter = "trophies_after"
        case leagueBefore = "league_before"
        case leagueAfter = "league_after"
    }
}

/// Une ligne du classement des trophées entre amis : `duel_friends_leaderboard()`.
nonisolated struct DuelLeaderboardEntry: Codable, Sendable, Identifiable, Equatable {
    let userId: UUID
    let handle: String
    let avatarId: String?
    let trophies: Int
    let leaguePosition: Int
    let isMe: Bool

    var id: UUID { userId }

    enum CodingKeys: String, CodingKey {
        case handle, trophies
        case userId = "user_id"
        case avatarId = "avatar_id"
        case leaguePosition = "league_position"
        case isMe = "is_me"
    }
}

/// Le score d'une manche, calculé comme le serveur le recompte (`duel_finish_match`).
nonisolated enum DuelScoring {
    /// Qui marque sur une question : le joueur, l'adversaire, ou les deux.
    static func round(question: DuelQuestion, answer: DuelAnswer?, bot: DuelBotAnswer) -> (player: Bool, opponent: Bool) {
        if question.kind == .slider {
            guard let correct = question.correctValue else { return (false, false) }
            let playerGap = answer?.v.map { abs($0 - correct) }
            let botGap = bot.value.map { abs($0 - correct) }
            switch (playerGap, botGap) {
            case let (player?, opponent?): return (player <= opponent, opponent <= player)
            case (.some, nil): return (true, false)
            case (nil, .some): return (false, true)
            case (nil, nil): return (false, false)
            }
        }
        let playerRight = answer?.c != nil && answer?.c == question.correctIndex
        return (playerRight, bot.correct)
    }

    /// La question décisive : au plus proche ; à distance égale, au plus rapide.
    static func playerWinsTiebreak(question: DuelQuestion, answer: DuelAnswer?, bot: DuelBotAnswer) -> Bool {
        guard let correct = question.correctValue, let value = answer?.v else { return false }
        guard let botValue = bot.value else { return true }
        let playerGap = abs(value - correct)
        let botGap = abs(botValue - correct)
        if playerGap != botGap { return playerGap < botGap }
        return (answer?.t ?? Int.max) <= bot.timeMs
    }
}
