package app.rork.sophia.ui.duels

import android.os.SystemClock
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import app.rork.sophia.domain.DuelAnswer
import app.rork.sophia.domain.DuelBotAnswer
import app.rork.sophia.domain.DuelMatch
import app.rork.sophia.domain.DuelQuestion
import app.rork.sophia.domain.DuelQuestionKind
import app.rork.sophia.domain.DuelRoundKind
import app.rork.sophia.domain.DuelRoundPlan
import app.rork.sophia.domain.DuelScoring
import kotlinx.coroutines.delay
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.random.Random

// Le déroulé d'une partie classée, sans rien d'affichage : mêmes règles et mêmes durées que
// `ios/Sophia/Views/Duels/DuelGameModel.swift` (la partie entre amis, en direct, n'est pas portée).

/** Qui a marqué sur une question. */
data class DuelRound(val player: Boolean, val opponent: Boolean)

/** Le joueur tel qu'il s'affiche face à son adversaire. */
data class DuelPlayerIdentity(val handle: String, val avatarId: String?, val trophies: Int) {
    val initial: String get() = handle.take(1).uppercase(java.util.Locale.ROOT)
}

/** Ce que l'app sait d'une partie dès qu'elle se termine, avant la réponse du serveur. */
data class DuelSummary(
    val match: DuelMatch,
    val playerScore: Int,
    val opponentScore: Int,
    val won: Boolean,
    val abandoned: Boolean,
    val tiebreak: Boolean,
    /** Une réponse par question posée, dans l'ordre de jeu ; la question décisive vient en dernier. */
    val answers: List<DuelAnswer>,
    /** L'adversaire a quitté la partie en cours de route : victoire par déconnexion. */
    val forfeit: Boolean = false,
    /** La matière que j'ai choisie pour ma manche : le serveur en a besoin pour recompter le score. */
    val pick: String? = null,
)

enum class DuelPhase {
    /** Le chrono tourne. */
    Answering,

    /** Les réponses sont dévoilées. */
    Reveal,

    /** L'annonce d'une manche : matière à choisir, matière choisie par l'adversaire, sprint. */
    RoundIntro,

    /** L'annonce de la question décisive. */
    SuddenDeathIntro,
    Finished,
}

/** Ce que montre l'annonce d'une manche. Les instants sont ceux de l'horloge de la partie (ms). */
data class DuelRoundAnnouncement(
    val number: Int,
    val kind: DuelRoundKind,
    /** Manche au choix : c'est à moi de choisir. */
    val mine: Boolean,
    /** Les matières proposées, quand c'est à moi de choisir. */
    val options: List<String>,
    /** La matière retenue, une fois connue. */
    val chosen: String? = null,
    /** Le temps laissé pour choisir : son début et sa fin. */
    val opensAtMs: Long,
    val deadlineMs: Long? = null,
)

/**
 * Les règles d'une partie, en fonctions pures : elles ne lisent ni l'horloge ni l'écran, pour
 * être vérifiées par des tests. Les durées sont celles d'iOS, en millisecondes.
 */
object DuelRules {
    /** Le pas de la boucle de jeu : l'état est relu vingt fois par seconde. */
    const val TICK_MS = 50L

    /** Le temps laissé pour choisir sa matière ; passé ce délai, la première proposée. */
    const val PICK_WINDOW_MS = 8_000L

    /** Ma matière choisie reste à l'écran avant la première question. */
    const val AFTER_MY_PICK_MS = 1_300L

    /** L'adversaire choisit, puis sa matière se dévoile. */
    const val OPPONENT_CHOOSING_MS = 2_400L
    const val OPPONENT_CHOSEN_MS = 1_700L
    const val SPRINT_INTRO_MS = 2_800L

    /** Les deux ont répondu : un souffle avant de dévoiler. */
    const val BOTH_ANSWERED_MS = 350L
    const val REVEAL_MS = 1_800L
    const val REVEAL_SLIDER_MS = 2_800L
    const val SUDDEN_DEATH_INTRO_MS = 2_400L

    /** Le temps de lire que l'adversaire a quitté la partie, avant le résultat. */
    const val FORFEIT_MS = 2_800L

    /** Une fois ma réponse donnée, l'adversaire répond dans ce délai au plus tard. */
    const val OPPONENT_DELAY_MIN_MS = 500L
    const val OPPONENT_DELAY_MAX_MS = 1_400L

    /** L'adversaire ne répond jamais plus tard que la fin du chrono moins cette marge. */
    const val OPPONENT_MARGIN_MS = 100L

    /** Les dernières secondes du chrono se font sentir. */
    const val CLOCK_SECONDS = 3

    /** Un cran du curseur vibre au plus une fois par ce délai. */
    const val SLIDER_TICK_MS = 45L

    /** Au-delà, quitter l'app en pleine partie est un abandon. */
    const val MAX_ABSENCE_MS = 15_000L

    /** La place d'une réponse de l'adversaire absente des données de la manche. */
    val fillerOpponentAnswer = DuelBotAnswer(correct = false, choice = null, value = null, timeMs = 4000)

    // ------------------------------------------------------------ curseur

    /** La valeur du curseur ramenée sur un cran, entre ses bornes. */
    fun snap(raw: Double, question: DuelQuestion): Double {
        val lower = question.sliderMin ?: 0.0
        val upper = question.sliderMax ?: 100.0
        val step = maxOf(question.sliderStep ?: 1.0, 0.000_001)
        val steps = (raw - lower) / step
        // L'arrondi d'iOS : au plus proche, la moitié s'éloignant de zéro.
        val rounded = if (steps >= 0) floor(steps + 0.5) else ceil(steps - 0.5)
        return (lower + rounded * step).coerceIn(lower, maxOf(lower, upper))
    }

    /** Le curseur démarre au milieu de son étendue. */
    fun sliderStart(question: DuelQuestion): Double =
        snap(((question.sliderMin ?: 0.0) + (question.sliderMax ?: 100.0)) / 2, question)

    // ------------------------------------------------------------ manches

    /** Le numéro de la manche (à partir de 1) de la question `index`. */
    fun roundNumber(index: Int, roundCount: Int): Int =
        minOf(index / DuelMatch.QUESTIONS_PER_ROUND, maxOf(roundCount - 1, 0)) + 1

    /** La matière retenue pour ma manche : mon choix, sinon la première proposée. */
    fun fallbackPick(options: List<String>, chosen: String?): String? = chosen ?: options.firstOrNull()

    /** Les questions d'une manche et les réponses de l'adversaire, une fois la matière connue. */
    data class ResolvedRound(
        val subject: String?,
        val questions: List<DuelQuestion>,
        val opponentAnswers: List<DuelBotAnswer>,
    )

    /**
     * Manche au choix à moi : les questions de la matière `chosen` (la première proposée si elle
     * est absente ou inconnue). Sinon celles de la manche, avec la matière de l'adversaire quand
     * c'est lui qui a choisi. Une manche ne dépasse jamais cinq questions : c'est le compte du
     * serveur, et l'ordre des réponses envoyées en dépend.
     */
    fun resolveRound(plan: DuelRoundPlan, chosen: String?): ResolvedRound {
        val options = plan.options
        if (plan.isMyPick && !options.isNullOrEmpty()) {
            val option = options.firstOrNull { it.subject == chosen } ?: options[0]
            val questions = option.questions.take(DuelMatch.QUESTIONS_PER_ROUND)
            return ResolvedRound(option.subject, questions, option.bot.orEmpty().take(questions.size))
        }
        val subject = if (plan.kind == DuelRoundKind.PICK) plan.subject else null
        val questions = plan.questions.orEmpty().take(DuelMatch.QUESTIONS_PER_ROUND)
        return ResolvedRound(subject, questions, plan.bot.orEmpty().take(questions.size))
    }

    /** La matière que j'ai choisie pour ma manche au choix (celle qui part au serveur). */
    fun myPick(rounds: List<DuelRoundPlan>, roundSubjects: Map<Int, String>): String? =
        rounds.firstOrNull { it.isMyPick }?.let { roundSubjects[it.number] }

    /** L'adversaire quitte-t-il la partie après la question qui vient d'être jouée ? */
    fun opponentLeaves(leavesAfter: Int?, questionsPlayed: Int): Boolean =
        leavesAfter != null && questionsPlayed == leavesAfter

    // ------------------------------------------------------------ une question

    /** La réponse de l'adversaire quand elle manque aux données de la partie : fausse, à mi-chrono. */
    fun missingOpponentAnswer(question: DuelQuestion): DuelBotAnswer =
        DuelBotAnswer(correct = false, choice = null, value = null, timeMs = question.timeLimitMs / 2)

    /**
     * L'instant (ms depuis le début de la question) où la réponse de l'adversaire est montrée :
     * à son temps de réponse, ou peu après la mienne si j'ai répondu avant lui.
     */
    fun opponentAnswerTimeMs(ownTimeMs: Long, lockedAtMs: Long?, delayMs: Long): Long =
        if (lockedAtMs == null) ownTimeMs else minOf(ownTimeMs, lockedAtMs + delayMs)

    fun opponentHasAnswered(elapsedMs: Long, opponentTimeMs: Long, limitMs: Long): Boolean =
        elapsedMs >= minOf(opponentTimeMs, limitMs - OPPONENT_MARGIN_MS)

    /** Les secondes qui restent, arrondies vers le haut (ce qu'affiche le cadran). */
    fun secondsLeft(limitMs: Long, elapsedMs: Long): Int = ceil((limitMs - elapsedMs) / 1000.0).toInt()

    /** Part du temps restant, de 1 à 0. */
    fun remainingFraction(limitMs: Long, elapsedMs: Long): Double {
        if (limitMs <= 0) return 0.0
        return (1 - elapsedMs.toDouble() / limitMs).coerceIn(0.0, 1.0)
    }

    /**
     * Ma réponse telle qu'elle part au serveur. Sans réponse, le temps est celui du chrono
     * entier. Un curseur touché compte même sans avoir été validé.
     */
    fun answer(
        question: DuelQuestion,
        selectedChoice: Int?,
        sliderValue: Double,
        locked: Boolean,
        sliderTouched: Boolean,
        lockedAtMs: Long?,
    ): DuelAnswer {
        val limitMs = question.timeLimitMs.toLong()
        val time = minOf(lockedAtMs ?: limitMs, limitMs).toInt()
        return if (question.kind == DuelQuestionKind.SLIDER) {
            DuelAnswer(c = null, v = if (locked || sliderTouched) sliderValue else null, t = time)
        } else {
            DuelAnswer(c = selectedChoice, v = null, t = time)
        }
    }

    /** Qui marque. La question décisive n'a qu'un gagnant : l'un, ou l'autre. */
    fun score(question: DuelQuestion, answer: DuelAnswer, theirs: DuelBotAnswer, isTiebreak: Boolean): DuelRound {
        if (isTiebreak) {
            val won = DuelScoring.playerWinsTiebreak(question, answer, theirs)
            return DuelRound(player = won, opponent = !won)
        }
        val (player, opponent) = DuelScoring.round(question, answer, theirs)
        return DuelRound(player, opponent)
    }

    /** Une question au curseur reste dévoilée plus longtemps : il y a deux valeurs à lire. */
    fun revealMs(kind: DuelQuestionKind): Long =
        if (kind == DuelQuestionKind.SLIDER) REVEAL_SLIDER_MS else REVEAL_MS

    // ------------------------------------------------------------ autour de la partie

    /** De retour dans l'app après `awayMs` : la partie est-elle abandonnée ? */
    fun abandonsAfterAbsence(awayMs: Long): Boolean = awayMs > MAX_ABSENCE_MS
}

/**
 * Le déroulé d'une partie : quatre manches de cinq questions, chacune avec son chrono, puis une
 * question décisive en cas d'égalité. Les réponses de l'adversaire arrivent avec la partie :
 * chacune est montrée à son temps de réponse, ou peu après celle du joueur s'il a répondu avant.
 * Le score affiché est recompté par le serveur à la fin, avec les mêmes règles (`DuelScoring`).
 *
 * L'écran lit l'état (des états Compose) ; [run] joue la partie dans une coroutine et s'arrête
 * dès qu'elle est annulée (abandon, écran fermé). L'horloge, le hasard et l'attente sont
 * passés en paramètres pour que les tests jouent une partie entière sans attendre.
 */
class DuelGameModel(
    val match: DuelMatch,
    private val haptic: (DuelHaptic) -> Unit = {},
    /** Une horloge qui avance aussi quand l'app est à l'arrière-plan : le chrono n'attend pas. */
    private val clock: () -> Long = { SystemClock.elapsedRealtime() },
    private val random: Random = Random.Default,
    private val pause: suspend (Long) -> Unit = { delay(it) },
) {
    val questionCount: Int get() = match.questionCount

    var index by mutableIntStateOf(0)
        private set
    var phase by mutableStateOf(DuelPhase.Answering)
        private set
    var roundIntro by mutableStateOf<DuelRoundAnnouncement?>(null)
        private set

    /** Les matières des manches au choix déjà fixées, par numéro de manche. */
    var roundSubjects by mutableStateOf<Map<Int, String>>(emptyMap())
        private set
    var playerScore by mutableIntStateOf(0)
        private set
    var opponentScore by mutableIntStateOf(0)
        private set

    /** Une case par question : le camp a-t-il marqué ? Vide tant que la question n'est pas jouée. */
    var playerMarks by mutableStateOf<List<Boolean?>>(List(match.questionCount) { null })
        private set
    var opponentMarks by mutableStateOf<List<Boolean?>>(List(match.questionCount) { null })
        private set

    // La question en cours.
    var selectedChoice by mutableStateOf<Int?>(null)
        private set
    var sliderValue by mutableDoubleStateOf(0.0)
        private set
    var playerLocked by mutableStateOf(false)
        private set
    var opponentAnswered by mutableStateOf(false)
        private set

    /** Part du temps restant figée à la révélation (le cadran s'arrête). */
    var frozenFraction by mutableDoubleStateOf(1.0)
        private set
    var lastRound by mutableStateOf<DuelRound?>(null)
        private set
    var isSuddenDeath by mutableStateOf(false)
        private set
    var playerWon by mutableStateOf(false)
        private set

    /** L'adversaire a quitté la partie : elle s'arrête sur une victoire. */
    var opponentForfeited by mutableStateOf(false)
        private set

    /**
     * Les questions des manches déjà commencées, dans l'ordre où elles se jouent, et les
     * réponses de l'adversaire à ces questions. Les questions d'une manche ne sont connues qu'à
     * son début : une manche au choix dépend de la matière retenue.
     */
    private var playedQuestions by mutableStateOf<List<DuelQuestion>>(emptyList())
    private val playedOpponentAnswers = mutableListOf<DuelBotAnswer>()
    private val givenAnswers = mutableListOf<DuelAnswer>()

    private var questionStartMs = clock()
    private var sliderTouched = false
    private var lockedAtMs: Long? = null
    private var opponentDelayMs = 1_000L
    private var lastSliderTickMs = Long.MIN_VALUE / 2

    init {
        // La première manche est connue d'avance : sa première question est à l'écran dès le
        // premier affichage, avant même que la partie ne démarre.
        val first = match.rounds.firstOrNull()
        if (first != null && first.kind != DuelRoundKind.PICK) {
            val resolved = DuelRules.resolveRound(first, null)
            playedQuestions = resolved.questions
            playedOpponentAnswers += resolved.opponentAnswers
        }
    }

    /** Mes réponses jusqu'ici, dans l'ordre de jeu. */
    val answers: List<DuelAnswer> get() = givenAnswers.toList()

    /** L'instant présent sur l'horloge de la partie (celle des délais de [roundIntro]). */
    fun nowMs(): Long = clock()

    /** La question à la place `i` ; au-delà de la dernière, la question décisive. */
    fun questionAt(i: Int): DuelQuestion {
        val played = playedQuestions
        return when {
            i >= questionCount -> match.tiebreak
            i in played.indices -> played[i]
            else -> played.lastOrNull() ?: match.tiebreak
        }
    }

    val question: DuelQuestion get() = questionAt(index)

    /** Le numéro de la manche en cours (1 à 4). */
    val roundNumber: Int get() = DuelRules.roundNumber(index, match.rounds.size)

    /** La matière de la manche de la question `i`, quand c'est une manche au choix. */
    fun subjectAt(i: Int): String? =
        if (i < questionCount) roundSubjects[DuelRules.roundNumber(i, match.rounds.size)] else null

    val currentSubject: String? get() = subjectAt(index)

    /** La réponse de l'adversaire à la question `i`. */
    fun opponentAnswerAt(i: Int): DuelBotAnswer {
        if (i >= questionCount) match.tiebreakBot?.let { return it }
        return playedOpponentAnswers.getOrNull(i) ?: DuelRules.missingOpponentAnswer(questionAt(i))
    }

    val opponentAnswer: DuelBotAnswer get() = opponentAnswerAt(index)

    /** Part du temps restant (1 → 0) à cet instant, pour le cadran. */
    fun remainingFraction(): Double {
        if (phase != DuelPhase.Answering) return frozenFraction
        return DuelRules.remainingFraction(question.timeLimitMs.toLong(), clock() - questionStartMs)
    }

    /** La matière que j'ai choisie pour ma manche au choix. */
    val myPick: String? get() = DuelRules.myPick(match.rounds, roundSubjects)

    /** La partie jouée jusqu'au bout (ou jusqu'au départ de l'adversaire). */
    val summary: DuelSummary
        get() = DuelSummary(
            match = match,
            playerScore = playerScore,
            opponentScore = opponentScore,
            won = playerWon,
            abandoned = false,
            tiebreak = isSuddenDeath,
            answers = answers,
            forfeit = opponentForfeited,
            pick = myPick,
        )

    /** Quitter en pleine partie : une défaite, avec les réponses données jusque-là. */
    fun abandonSummary(): DuelSummary = DuelSummary(
        match = match,
        playerScore = playerScore,
        opponentScore = opponentScore,
        won = false,
        abandoned = true,
        tiebreak = false,
        answers = answers,
        pick = myPick,
    )

    // ------------------------------------------------------------ actions du joueur

    /** Choisit la matière de la manche annoncée (quand c'est à moi de choisir). */
    fun pickSubject(subject: String) {
        val intro = roundIntro ?: return
        if (phase != DuelPhase.RoundIntro || !intro.mine || intro.chosen != null || subject !in intro.options) return
        // Passé le délai, la première matière est déjà retenue.
        if (intro.deadlineMs != null && clock() >= intro.deadlineMs) return
        roundIntro = intro.copy(chosen = subject)
        haptic(DuelHaptic.Lock)
    }

    /** Une option touchée est verrouillée aussitôt : on ne change pas d'avis. */
    fun choose(option: Int) {
        if (phase != DuelPhase.Answering || playerLocked || question.kind == DuelQuestionKind.SLIDER) return
        selectedChoice = option
        lockPlayer()
    }

    fun setSlider(raw: Double) {
        if (phase != DuelPhase.Answering || playerLocked || question.kind != DuelQuestionKind.SLIDER) return
        val snapped = DuelRules.snap(raw, question)
        if (snapped == sliderValue) return
        sliderValue = snapped
        sliderTouched = true
        val now = clock()
        if (now - lastSliderTickMs > DuelRules.SLIDER_TICK_MS) {
            lastSliderTickMs = now
            haptic(DuelHaptic.Tick)
        }
    }

    fun nudgeSlider(steps: Double) {
        setSlider(sliderValue + steps * (question.sliderStep ?: 1.0))
    }

    fun lockSlider() {
        if (phase != DuelPhase.Answering || playerLocked || question.kind != DuelQuestionKind.SLIDER) return
        sliderTouched = true
        lockPlayer()
    }

    private fun lockPlayer() {
        playerLocked = true
        lockedAtMs = clock() - questionStartMs
        opponentDelayMs = random.nextLong(DuelRules.OPPONENT_DELAY_MIN_MS, DuelRules.OPPONENT_DELAY_MAX_MS + 1)
        haptic(DuelHaptic.Lock)
    }

    // ------------------------------------------------------------ déroulé

    /** Joue la partie jusqu'au bout. L'annulation de la coroutine l'arrête où elle en est. */
    suspend fun run() {
        for ((r, plan) in match.rounds.withIndex()) {
            if (r > 0) announce(plan)
            // La première manche est déjà en place (voir `init`).
            val preloaded = r == 0 && playedQuestions.isNotEmpty()
            val first = if (preloaded) 0 else playedQuestions.size
            val count = if (preloaded) playedQuestions.size else resolve(plan)
            for (k in 0 until count) {
                play(first + k)
                // L'adversaire quitte la partie après cette question (rare) : le temps de lire
                // l'annonce, puis la victoire.
                if (DuelRules.opponentLeaves(match.opponentLeavesAfter, first + k + 1)) {
                    forfeitByOpponent()
                    return
                }
            }
        }
        if (playerScore == opponentScore) {
            isSuddenDeath = true
            phase = DuelPhase.SuddenDeathIntro
            haptic(DuelHaptic.SuddenDeath)
            pause(DuelRules.SUDDEN_DEATH_INTRO_MS)
            play(questionCount)
        } else {
            playerWon = playerScore > opponentScore
        }
        phase = DuelPhase.Finished
    }

    /** L'adversaire a quitté la partie : la ligne d'état le dit, puis l'écran de résultat. */
    private suspend fun forfeitByOpponent() {
        // La dernière question reste à l'écran, dévoilée : seule la ligne d'état change.
        opponentForfeited = true
        haptic(DuelHaptic.SuddenDeath)
        playerWon = true
        pause(DuelRules.FORFEIT_MS)
        phase = DuelPhase.Finished
    }

    /**
     * Les questions d'une manche (et les réponses de l'adversaire), ajoutées à la suite de
     * celles déjà jouées. Renvoie leur nombre.
     */
    private fun resolve(plan: DuelRoundPlan): Int {
        val resolved = DuelRules.resolveRound(plan, roundSubjects[plan.number])
        resolved.subject?.let { roundSubjects = roundSubjects + (plan.number to it) }
        // Les réponses de l'adversaire restent en face de leurs questions, même si la partie
        // en a livré moins que de questions à la manche précédente.
        while (playedOpponentAnswers.size < playedQuestions.size) playedOpponentAnswers += DuelRules.fillerOpponentAnswer
        playedQuestions = playedQuestions + resolved.questions
        playedOpponentAnswers += resolved.opponentAnswers
        return resolved.questions.size
    }

    /**
     * L'annonce d'une manche. Au choix : huit secondes pour choisir parmi les matières
     * proposées (passé ce délai, la première) ; ou l'adversaire choisit, puis sa matière
     * se dévoile. Sprint : le temps de lire l'annonce.
     */
    private suspend fun announce(plan: DuelRoundPlan) {
        when (plan.kind) {
            DuelRoundKind.MIXED -> Unit
            DuelRoundKind.SPRINT -> {
                show(DuelRoundAnnouncement(plan.number, DuelRoundKind.SPRINT, mine = false, options = emptyList(), opensAtMs = clock()))
                pause(DuelRules.SPRINT_INTRO_MS)
            }
            DuelRoundKind.PICK -> if (plan.isMyPick) {
                val subjects = plan.options.orEmpty().map { it.subject }
                val opensAt = clock()
                val deadline = opensAt + DuelRules.PICK_WINDOW_MS
                show(
                    DuelRoundAnnouncement(
                        plan.number, DuelRoundKind.PICK, mine = true, options = subjects,
                        opensAtMs = opensAt, deadlineMs = deadline,
                    ),
                )
                while (roundIntro?.chosen == null && clock() < deadline) pause(DuelRules.TICK_MS)
                val chosen = DuelRules.fallbackPick(subjects, roundIntro?.chosen)
                if (chosen != null) {
                    if (roundIntro?.chosen == null) roundIntro = roundIntro?.copy(chosen = chosen)
                    roundSubjects = roundSubjects + (plan.number to chosen)
                }
                pause(DuelRules.AFTER_MY_PICK_MS)
            } else {
                show(DuelRoundAnnouncement(plan.number, DuelRoundKind.PICK, mine = false, options = emptyList(), opensAtMs = clock()))
                pause(DuelRules.OPPONENT_CHOOSING_MS)
                roundIntro = roundIntro?.copy(chosen = plan.subject)
                haptic(DuelHaptic.OpponentAnswered)
                pause(DuelRules.OPPONENT_CHOSEN_MS)
            }
        }
    }

    private fun show(intro: DuelRoundAnnouncement) {
        roundIntro = intro
        phase = DuelPhase.RoundIntro
        haptic(DuelHaptic.OpponentFound)
    }

    /** Une question : le chrono, ma réponse, celle de l'adversaire, puis la révélation. */
    private suspend fun play(i: Int) {
        val isTiebreak = i >= questionCount
        index = i
        selectedChoice = null
        playerLocked = false
        opponentAnswered = false
        lastRound = null
        frozenFraction = 1.0
        phase = DuelPhase.Answering

        val current = question
        val theirs = opponentAnswer
        sliderTouched = false
        lockedAtMs = null
        if (current.kind == DuelQuestionKind.SLIDER) sliderValue = DuelRules.sliderStart(current)
        questionStartMs = clock()

        val limitMs = current.timeLimitMs.toLong()
        var lastClock = Int.MAX_VALUE
        var bothAnswered = false
        while (true) {
            pause(DuelRules.TICK_MS)
            val elapsed = clock() - questionStartMs
            val opponentTime = DuelRules.opponentAnswerTimeMs(theirs.timeMs.toLong(), lockedAtMs, opponentDelayMs)
            if (!opponentAnswered && DuelRules.opponentHasAnswered(elapsed, opponentTime, limitMs)) {
                opponentAnswered = true
                haptic(DuelHaptic.OpponentAnswered)
            }
            if (playerLocked && opponentAnswered) {
                bothAnswered = true
                break
            }
            if (elapsed >= limitMs) break
            val remaining = DuelRules.secondsLeft(limitMs, elapsed)
            if (remaining <= DuelRules.CLOCK_SECONDS && remaining < lastClock && !playerLocked) {
                lastClock = remaining
                haptic(DuelHaptic.Clock)
            }
        }
        if (bothAnswered) pause(DuelRules.BOTH_ANSWERED_MS)
        frozenFraction = remainingFraction()

        val answer = DuelRules.answer(current, selectedChoice, sliderValue, playerLocked, sliderTouched, lockedAtMs)
        givenAnswers += answer
        val round = DuelRules.score(current, answer, theirs, isTiebreak)
        if (isTiebreak) playerWon = round.player

        playerLocked = true
        opponentAnswered = true
        lastRound = round
        phase = DuelPhase.Reveal
        // La question décisive désigne le gagnant sans changer le score.
        if (!isTiebreak) {
            if (round.player) playerScore += 1
            if (round.opponent) opponentScore += 1
            if (i in playerMarks.indices) {
                playerMarks = playerMarks.toMutableList().also { it[i] = round.player }
                opponentMarks = opponentMarks.toMutableList().also { it[i] = round.opponent }
            }
        }
        haptic(if (round.player) DuelHaptic.Correct else DuelHaptic.Wrong)
        pause(DuelRules.revealMs(current.kind))
    }
}
