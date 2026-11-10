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
    /// Le compte de l'adversaire quand c'est un ami (duel amical) ; absent en duel classé.
    var userId: UUID? = nil
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
        case userId = "user_id"
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

nonisolated enum DuelRoundKind: String, Codable, Sendable {
    /// Des questions de toutes les matières.
    case mixed
    /// Une matière au choix, parmi trois : le joueur ou son adversaire choisit.
    case pick
    /// La dernière manche : des questions rapides, aux chronos courts.
    case sprint
}

/// Une matière proposée pour une manche au choix, avec ses cinq questions (et, en duel classé,
/// les réponses de l'adversaire à ces questions).
nonisolated struct DuelRoundOption: Codable, Sendable, Equatable {
    let subject: String
    let questions: [DuelQuestion]
    let bot: [DuelBotAnswer]?
}

/// Une manche : cinq questions. Pour une manche au choix, `picker` dit qui choisit (« me » ou
/// « opponent ») ; les questions sont alors dans `options` (une liste par matière proposée),
/// sauf en duel classé quand l'adversaire choisit : sa matière est déjà fixée (`subject`).
nonisolated struct DuelRoundPlan: Codable, Sendable, Equatable {
    let number: Int
    let kind: DuelRoundKind
    let picker: String?
    let subject: String?
    let questions: [DuelQuestion]?
    let bot: [DuelBotAnswer]?
    let options: [DuelRoundOption]?

    var isMyPick: Bool { kind == .pick && picker == "me" }
}

/// Une partie lancée : `duel_start_match_v2()`. Quatre manches de cinq questions.
nonisolated struct DuelMatch: Codable, Sendable, Equatable {
    let matchId: UUID
    let opponent: DuelOpponent
    let rounds: [DuelRoundPlan]
    /// La question décisive, jouée seulement en cas d'égalité après les 20 questions.
    let tiebreak: DuelQuestion
    /// La réponse de l'adversaire à la question décisive (duel classé).
    let tiebreakBot: DuelBotAnswer?
    let searchMs: Int

    static let questionsPerRound = 5

    var questionCount: Int { rounds.count * Self.questionsPerRound }

    /// Toutes les questions qui peuvent être posées (pour charger leurs images d'avance).
    var allQuestions: [DuelQuestion] {
        var result: [DuelQuestion] = []
        for round in rounds {
            result += round.questions ?? []
            for option in round.options ?? [] {
                result += option.questions
            }
        }
        result.append(tiebreak)
        return result
    }

    enum CodingKeys: String, CodingKey {
        case opponent, rounds, tiebreak
        case matchId = "match_id"
        case tiebreakBot = "tiebreak_bot"
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
nonisolated struct DuelLeaderboardEntry: Codable, Sendable, Identifiable, Equatable, Hashable {
    let userId: UUID
    let handle: String
    let avatarId: String?
    let trophies: Int
    let leaguePosition: Int
    let isMe: Bool
    /// L'ami a l'app ouverte en ce moment (pastille verte).
    let online: Bool
    /// L'ami peut être défié : son app a les duels.
    let canChallenge: Bool

    var id: UUID { userId }

    enum CodingKeys: String, CodingKey {
        case handle, trophies, online
        case userId = "user_id"
        case avatarId = "avatar_id"
        case leaguePosition = "league_position"
        case isMe = "is_me"
        case canChallenge = "can_challenge"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        userId = try c.decode(UUID.self, forKey: .userId)
        handle = try c.decode(String.self, forKey: .handle)
        avatarId = try c.decodeIfPresent(String.self, forKey: .avatarId)
        trophies = try c.decode(Int.self, forKey: .trophies)
        leaguePosition = try c.decode(Int.self, forKey: .leaguePosition)
        isMe = try c.decode(Bool.self, forKey: .isMe)
        // Absentes tant que le serveur n'a pas les duels entre amis.
        online = try c.decodeIfPresent(Bool.self, forKey: .online) ?? false
        canChallenge = try c.decodeIfPresent(Bool.self, forKey: .canChallenge) ?? false
    }
}

// MARK: - Duels entre amis

/// Une invitation reçue : `duel_ping()` la rapporte tant qu'elle attend une réponse.
nonisolated struct DuelIncomingInvite: Codable, Sendable, Equatable, Identifiable {
    let inviteId: UUID
    let from: DuelOpponent
    let expiresInMs: Int

    var id: UUID { inviteId }

    enum CodingKeys: String, CodingKey {
        case from
        case inviteId = "invite_id"
        case expiresInMs = "expires_in_ms"
    }
}

nonisolated struct DuelPingResponse: Codable, Sendable {
    let invite: DuelIncomingInvite?
}

/// Une invitation envoyée : `duel_invite_friend()`.
nonisolated struct DuelSentInvite: Codable, Sendable, Equatable {
    let inviteId: UUID
    let expiresInMs: Int
    let me: DuelOpponent
    let friend: DuelOpponent
    let online: Bool

    enum CodingKeys: String, CodingKey {
        case me, friend, online
        case inviteId = "invite_id"
        case expiresInMs = "expires_in_ms"
    }
}

/// Le lancement d'une partie entre amis, reçu par les deux joueurs.
nonisolated struct DuelFriendStart: Codable, Sendable, Equatable {
    let matchId: UUID
    let me: DuelOpponent
    let opponent: DuelOpponent
    let rounds: [DuelRoundPlan]
    let tiebreak: DuelQuestion
    /// La première question démarre dans tant de millisecondes, pour les deux joueurs.
    let startsInMs: Int

    enum CodingKeys: String, CodingKey {
        case me, opponent, rounds, tiebreak
        case matchId = "match_id"
        case startsInMs = "starts_in_ms"
    }

    /// La même partie sous la forme que l'écran de jeu connaît (sans script d'adversaire).
    var match: DuelMatch {
        DuelMatch(matchId: matchId, opponent: opponent, rounds: rounds, tiebreak: tiebreak, tiebreakBot: nil, searchMs: 0)
    }
}

/// Où en est une invitation envoyée (`duel_invite_status`) ou la réponse donnée à une
/// invitation reçue (`duel_invite_respond`).
nonisolated struct DuelInviteOutcome: Codable, Sendable, Equatable {
    /// pending, accepted, declined, busy, cancelled, expired.
    let status: String
    let match: DuelFriendStart?
}

/// L'état d'une partie entre amis, vu par ce joueur : `duel_friend_state()`.
nonisolated struct DuelFriendState: Codable, Sendable, Equatable {
    let matchId: UUID
    let finished: Bool
    /// La question en cours (20 : la question décisive).
    let index: Int
    /// Nombre de questions closes : leurs réponses et leurs points sont connus.
    let resolved: Int
    /// Positif : la question en cours démarre dans tant de ms ; négatif : elle tourne déjà.
    let questionStartsInMs: Int
    let myScore: Int
    let opponentScore: Int
    let myAnswered: Bool
    let opponentAnswered: Bool
    let opponentAnswers: [DuelAnswer]
    let myPoints: [Bool]
    let opponentPoints: [Bool]
    let tiebreak: Bool
    /// Les matières retenues pour les manches au choix, par numéro de manche : ["2": "art"].
    let picks: [String: String]?
    let opponentLeft: Bool
    /// Absent tant que la partie n'est pas finie sur un vainqueur.
    let won: Bool?
    let draw: Bool

    enum CodingKeys: String, CodingKey {
        case finished, index, resolved, tiebreak, picks, won, draw
        case matchId = "match_id"
        case questionStartsInMs = "question_starts_in_ms"
        case myScore = "my_score"
        case opponentScore = "opponent_score"
        case myAnswered = "my_answered"
        case opponentAnswered = "opponent_answered"
        case opponentAnswers = "opponent_answers"
        case myPoints = "my_points"
        case opponentPoints = "opponent_points"
        case opponentLeft = "opponent_left"
    }
}

/// Le profil d'un ami : `friend_profile()`.
nonisolated struct FriendProfile: Codable, Sendable, Equatable {
    let userId: UUID
    let handle: String
    let avatarId: String?
    let globalXP: Int
    let streak: Int
    let coursesCompleted: Int
    let quizzesCompleted: Int
    let trophies: Int
    let bestTrophies: Int
    let leaguePosition: Int
    let duelGames: Int
    let duelWins: Int
    /// Les créateurs qu'il suit (leurs identifiants), du plus récent au plus ancien.
    let follows: [String]
    let online: Bool
    let canChallenge: Bool
    /// Nos duels amicaux : joués, gagnés par moi, gagnés par lui.
    let friendlyPlayed: Int
    let friendlyWon: Int
    let friendlyLost: Int

    enum CodingKeys: String, CodingKey {
        case handle, streak, trophies, follows, online
        case userId = "user_id"
        case avatarId = "avatar_id"
        case globalXP = "global_xp"
        case coursesCompleted = "courses_completed"
        case quizzesCompleted = "quizzes_completed"
        case bestTrophies = "best_trophies"
        case leaguePosition = "league_position"
        case duelGames = "duel_games"
        case duelWins = "duel_wins"
        case canChallenge = "can_challenge"
        case friendlyPlayed = "friendly_played"
        case friendlyWon = "friendly_won"
        case friendlyLost = "friendly_lost"
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
