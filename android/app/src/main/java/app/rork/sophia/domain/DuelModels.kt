package app.rork.sophia.domain

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.math.abs
import kotlin.math.roundToInt

// Les duels : les formes exactes que renvoient les fonctions Supabase (`duel_home`,
// `duel_start_match_v2`, `duel_finish_match_v2`, `duel_friends_leaderboard`), et la règle du
// point. Mêmes noms et mêmes règles que `ios/Sophia/Models/DuelModels.swift` (docs/duels.md).

/** Une des 30 ligues, de la première (position 1) à la dernière. */
@Serializable
data class DuelLeague(
    val position: Int,
    val slug: String,
    val name: String,
    @SerialName("min_trophies") val minTrophies: Int,
    @SerialName("background_url") val backgroundUrl: String,
    @SerialName("thumb_url") val thumbUrl: String,
    @SerialName("accent_hex") val accentHex: String,
)

@Serializable
data class DuelProfile(
    val trophies: Int = 0,
    @SerialName("best_trophies") val bestTrophies: Int = 0,
    val games: Int = 0,
    val wins: Int = 0,
    val losses: Int = 0,
    @SerialName("win_streak") val winStreak: Int = 0,
    @SerialName("best_win_streak") val bestWinStreak: Int = 0,
    @SerialName("league_position") val leaguePosition: Int = 1,
) {
    /** Part de victoires en pour cent ; absente tant qu'aucune partie n'est jouée. */
    val winRate: Int?
        get() = if (games == 0) null else (wins.toDouble() / games * 100).roundToInt()
}

/** L'adversaire d'une partie, ou la carte d'un joueur dans un duel entre amis. */
@Serializable
data class DuelOpponent(
    @SerialName("user_id") val userId: String? = null,
    val handle: String,
    @SerialName("country_code") val countryCode: String = "",
    @SerialName("avatar_id") val avatarId: String? = null,
    val trophies: Int = 0,
    @SerialName("league_position") val leaguePosition: Int = 1,
) {
    /** Le drapeau du pays en émoji, ou rien si le code n'est pas un code à deux lettres. */
    val flag: String
        get() {
            val code = countryCode.uppercase(java.util.Locale.ROOT)
            if (code.length != 2 || code.any { it !in 'A'..'Z' }) return ""
            return code.map { String(Character.toChars(127397 + it.code)) }.joinToString("")
        }

    val initial: String
        get() = handle.take(1).uppercase(java.util.Locale.ROOT)
}

@Serializable
data class DuelRecentMatch(
    @SerialName("match_id") val matchId: String,
    val opponent: DuelOpponent,
    val won: Boolean = false,
    val abandoned: Boolean = false,
    @SerialName("player_score") val playerScore: Int = 0,
    @SerialName("opponent_score") val opponentScore: Int = 0,
    @SerialName("trophies_delta") val trophiesDelta: Int = 0,
)

/** L'accueil des duels : mon profil, les 30 ligues et mes dernières parties. */
@Serializable
data class DuelHome(
    val handle: String? = null,
    val profile: DuelProfile,
    val leagues: List<DuelLeague>,
    val recent: List<DuelRecentMatch> = emptyList(),
) {
    fun league(forTrophies: Int): DuelLeague? =
        leagues.lastOrNull { it.minTrophies <= maxOf(forTrophies, 0) } ?: leagues.firstOrNull()

    fun leagueAt(position: Int): DuelLeague? = leagues.firstOrNull { it.position == position }

    val currentLeague: DuelLeague? get() = league(profile.trophies)

    fun nextLeague(after: DuelLeague?): DuelLeague? = after?.let { leagueAt(it.position + 1) }

    /** Avancement vers la ligue suivante, de 0 à 1 (1 dans la dernière ligue). */
    fun leagueProgress(forTrophies: Int): Float {
        val current = league(forTrophies) ?: return 0f
        val next = nextLeague(current) ?: return 1f
        val span = next.minTrophies - current.minTrophies
        if (span <= 0) return 1f
        return ((forTrophies - current.minTrophies).toFloat() / span).coerceIn(0f, 1f)
    }
}

@Serializable
enum class DuelQuestionKind {
    @SerialName("mcq") MCQ,
    @SerialName("true_false") TRUE_FALSE,

    /** Une image et quatre réponses : portrait, drapeau, tableau, monument. */
    @SerialName("portrait") PORTRAIT,

    /** Une valeur à estimer : le plus proche marque. */
    @SerialName("slider") SLIDER,
}

@Serializable
data class DuelQuestion(
    val id: String,
    val kind: DuelQuestionKind,
    val question: String,
    val options: List<String>? = null,
    @SerialName("correct_index") val correctIndex: Int? = null,
    @SerialName("image_url") val imageUrl: String? = null,
    @SerialName("image_credit") val imageCredit: String? = null,
    @SerialName("slider_min") val sliderMin: Double? = null,
    @SerialName("slider_max") val sliderMax: Double? = null,
    @SerialName("slider_step") val sliderStep: Double? = null,
    @SerialName("correct_value") val correctValue: Double? = null,
    val unit: String? = null,
    @SerialName("time_limit_ms") val timeLimitMs: Int = 12000,
)

/** Ce que l'adversaire répond à une question, tel que le serveur l'envoie avec la partie. */
@Serializable
data class DuelBotAnswer(
    val correct: Boolean = false,
    val choice: Int? = null,
    val value: Double? = null,
    @SerialName("time_ms") val timeMs: Int = 0,
)

@Serializable
enum class DuelRoundKind {
    @SerialName("mixed") MIXED,
    @SerialName("pick") PICK,
    @SerialName("sprint") SPRINT,
}

/** Une matière proposée pour une manche au choix, avec ses cinq questions. */
@Serializable
data class DuelRoundOption(
    val subject: String,
    val questions: List<DuelQuestion>,
    val bot: List<DuelBotAnswer>? = null,
)

/**
 * Une des quatre manches de cinq questions. `MIXED` et `SPRINT` portent `questions` ; une manche
 * `PICK` porte `options` quand c'est à moi de choisir (`picker == "me"`), ou `subject` et
 * `questions` quand c'est le choix de l'adversaire.
 */
@Serializable
data class DuelRoundPlan(
    val number: Int,
    val kind: DuelRoundKind,
    val picker: String? = null,
    val subject: String? = null,
    val questions: List<DuelQuestion>? = null,
    val bot: List<DuelBotAnswer>? = null,
    val options: List<DuelRoundOption>? = null,
) {
    val isMyPick: Boolean get() = kind == DuelRoundKind.PICK && picker == "me"
}

@Serializable
data class DuelMatch(
    @SerialName("match_id") val matchId: String,
    val opponent: DuelOpponent,
    val rounds: List<DuelRoundPlan>,
    val tiebreak: DuelQuestion,
    @SerialName("tiebreak_bot") val tiebreakBot: DuelBotAnswer? = null,
    /** L'adversaire se déconnecte après cette question (victoire par déconnexion) ; absent : partie normale. */
    @SerialName("opponent_leaves_after") val opponentLeavesAfter: Int? = null,
    @SerialName("search_ms") val searchMs: Int = 0,
) {
    val questionCount: Int get() = rounds.size * QUESTIONS_PER_ROUND

    /** Toutes les questions qui peuvent être posées (pour précharger leurs images). */
    val allQuestions: List<DuelQuestion>
        get() = rounds.flatMap { round ->
            round.questions.orEmpty() + round.options.orEmpty().flatMap { it.questions }
        } + tiebreak

    companion object {
        const val QUESTIONS_PER_ROUND = 5
    }
}

/** Ma réponse à une question : l'option choisie (`c`) ou la valeur du curseur (`v`), et mon temps (`t`, ms). */
@Serializable
data class DuelAnswer(
    val c: Int? = null,
    val v: Double? = null,
    val t: Int = 0,
)

@Serializable
data class DuelResult(
    @SerialName("match_id") val matchId: String,
    val won: Boolean = false,
    val abandoned: Boolean = false,
    @SerialName("player_score") val playerScore: Int = 0,
    @SerialName("opponent_score") val opponentScore: Int = 0,
    val tiebreak: Boolean = false,
    @SerialName("trophies_before") val trophiesBefore: Int = 0,
    @SerialName("trophies_delta") val trophiesDelta: Int = 0,
    @SerialName("trophies_after") val trophiesAfter: Int = 0,
    @SerialName("league_before") val leagueBefore: Int = 1,
    @SerialName("league_after") val leagueAfter: Int = 1,
    val profile: DuelProfile = DuelProfile(),
) {
    val promoted: Boolean get() = leagueAfter > leagueBefore
}

/** Les trophées d'une victoire, pour l'animation de la jauge de ligue au retour sur la page. */
data class DuelLeagueGain(val before: Int, val after: Int)

/** Une ligne du classement des amis par trophées (moi compris). */
@Serializable
data class DuelLeaderboardEntry(
    @SerialName("user_id") val userId: String,
    val handle: String,
    @SerialName("avatar_id") val avatarId: String? = null,
    val trophies: Int = 0,
    @SerialName("league_position") val leaguePosition: Int = 1,
    @SerialName("is_me") val isMe: Boolean = false,
    val online: Boolean = false,
    @SerialName("can_challenge") val canChallenge: Boolean = false,
)

// ---------------------------------------------------------------- duels entre amis

/** Une invitation reçue : `duel_ping()` la rapporte tant qu'elle attend une réponse. */
@Serializable
data class DuelIncomingInvite(
    @SerialName("invite_id") val inviteId: String,
    val from: DuelOpponent,
    @SerialName("expires_in_ms") val expiresInMs: Int = 0,
)

@Serializable
data class DuelPingResponse(val invite: DuelIncomingInvite? = null)

/** Une invitation envoyée : `duel_invite_friend()`. */
@Serializable
data class DuelSentInvite(
    @SerialName("invite_id") val inviteId: String,
    @SerialName("expires_in_ms") val expiresInMs: Int = 0,
    val me: DuelOpponent,
    val friend: DuelOpponent,
    val online: Boolean = false,
)

/** Le lancement d'une partie entre amis, reçu par les deux joueurs. */
@Serializable
data class DuelFriendStart(
    @SerialName("match_id") val matchId: String,
    val me: DuelOpponent,
    val opponent: DuelOpponent,
    val rounds: List<DuelRoundPlan>,
    val tiebreak: DuelQuestion,
    /** La première question démarre dans tant de millisecondes, pour les deux joueurs. */
    @SerialName("starts_in_ms") val startsInMs: Int = 0,
) {
    /** La même partie sous la forme que l'écran de jeu connaît (sans script d'adversaire). */
    val match: DuelMatch
        get() = DuelMatch(matchId = matchId, opponent = opponent, rounds = rounds, tiebreak = tiebreak)
}

/**
 * Où en est une invitation envoyée (`duel_invite_status`) ou la réponse donnée à une invitation
 * reçue (`duel_invite_respond`). [status] : pending, accepted, declined, busy, cancelled, expired.
 */
@Serializable
data class DuelInviteOutcome(val status: String = "", val match: DuelFriendStart? = null)

/** L'état d'une partie entre amis, vu par ce joueur : `duel_friend_state()`. */
@Serializable
data class DuelFriendState(
    @SerialName("match_id") val matchId: String = "",
    val finished: Boolean = false,
    /** La question en cours (20 : la question décisive). */
    val index: Int = 0,
    /** Nombre de questions closes : leurs réponses et leurs points sont connus. */
    val resolved: Int = 0,
    /** Positif : la question en cours démarre dans tant de ms ; négatif : elle tourne déjà. */
    @SerialName("question_starts_in_ms") val questionStartsInMs: Int = 0,
    @SerialName("my_score") val myScore: Int = 0,
    @SerialName("opponent_score") val opponentScore: Int = 0,
    @SerialName("my_answered") val myAnswered: Boolean = false,
    @SerialName("opponent_answered") val opponentAnswered: Boolean = false,
    @SerialName("opponent_answers") val opponentAnswers: List<DuelAnswer> = emptyList(),
    @SerialName("my_points") val myPoints: List<Boolean> = emptyList(),
    @SerialName("opponent_points") val opponentPoints: List<Boolean> = emptyList(),
    val tiebreak: Boolean = false,
    /** Les matières retenues pour les manches au choix, par numéro de manche : {"2": "art"}. */
    val picks: Map<String, String>? = null,
    @SerialName("opponent_left") val opponentLeft: Boolean = false,
    /** Absent tant que la partie n'est pas finie sur un vainqueur. */
    val won: Boolean? = null,
    val draw: Boolean = false,
)

/** Qui marque le point d'une question, et qui gagne la question décisive. */
object DuelScoring {
    /** (moi, l'adversaire) : chacun marque-t-il le point de cette question ? */
    fun round(question: DuelQuestion, answer: DuelAnswer?, bot: DuelBotAnswer): Pair<Boolean, Boolean> {
        if (question.kind == DuelQuestionKind.SLIDER) {
            val target = question.correctValue ?: return false to false
            val mine = answer?.v?.let { abs(it - target) }
            val theirs = bot.value?.let { abs(it - target) }
            return when {
                // Le plus proche marque ; à distance égale, les deux marquent.
                mine != null && theirs != null -> (mine <= theirs) to (theirs <= mine)
                mine != null -> true to false
                theirs != null -> false to true
                else -> false to false
            }
        }
        val player = answer?.c != null && answer.c == question.correctIndex
        return player to bot.correct
    }

    /** Mort subite : le plus proche gagne ; à distance égale, le plus rapide. */
    fun playerWinsTiebreak(question: DuelQuestion, answer: DuelAnswer?, bot: DuelBotAnswer): Boolean {
        val target = question.correctValue ?: return false
        val mine = answer?.v?.let { abs(it - target) } ?: return false
        val theirs = bot.value?.let { abs(it - target) } ?: return true
        if (mine != theirs) return mine < theirs
        return (answer.t) <= bot.timeMs
    }
}
