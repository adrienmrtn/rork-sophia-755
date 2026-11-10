package app.rork.sophia

import app.rork.sophia.domain.DuelAnswer
import app.rork.sophia.domain.DuelBotAnswer
import app.rork.sophia.domain.DuelMatch
import app.rork.sophia.domain.DuelOpponent
import app.rork.sophia.domain.DuelQuestion
import app.rork.sophia.domain.DuelQuestionKind
import app.rork.sophia.domain.DuelRoundKind
import app.rork.sophia.domain.DuelRoundOption
import app.rork.sophia.domain.DuelRoundPlan
import app.rork.sophia.ui.duels.DuelGameModel
import app.rork.sophia.ui.duels.DuelHaptic
import app.rork.sophia.ui.duels.DuelPhase
import app.rork.sophia.ui.duels.DuelRules
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.random.Random

/**
 * Une partie entière jouée sur une horloge de test : chaque attente du déroulé avance l'horloge
 * d'autant, et un « joueur » scripté répond entre deux pas. Vérifie l'ordre des réponses
 * envoyées au serveur, la matière retenue, la question décisive, le départ de l'adversaire et
 * les durées (celles d'iOS).
 */
class DuelGameModelTest {

    // ------------------------------------------------------------ une partie de test

    private fun mcq(id: String, limit: Int = 12_000) = DuelQuestion(
        id = id, kind = DuelQuestionKind.MCQ, question = id,
        options = listOf("a", "b", "c", "d"), correctIndex = 0, timeLimitMs = limit,
    )

    private fun theirs(correct: Boolean, timeMs: Int = 9_000) =
        DuelBotAnswer(correct = correct, choice = if (correct) 0 else 1, value = null, timeMs = timeMs)

    private val tiebreak = DuelQuestion(
        id = "tiebreak", kind = DuelQuestionKind.SLIDER, question = "tiebreak",
        sliderMin = 0.0, sliderMax = 100.0, sliderStep = 1.0, correctValue = 40.0, timeLimitMs = 15_000,
    )

    /** Quatre manches : mêlée, à moi de choisir, à l'adversaire de choisir, sprint. */
    private fun match(
        opponentCorrect: (Int) -> Boolean = { false },
        leavesAfter: Int? = null,
        tiebreakAnswer: DuelBotAnswer? = DuelBotAnswer(correct = false, value = 70.0, timeMs = 5_000),
    ): DuelMatch {
        fun questions(prefix: String, limit: Int = 12_000) = (0 until 5).map { mcq("$prefix-$it", limit) }
        fun theirAnswers(firstIndex: Int) = (0 until 5).map { theirs(opponentCorrect(firstIndex + it)) }
        return DuelMatch(
            matchId = "match-1",
            opponent = DuelOpponent(handle = "ada", countryCode = "gb", trophies = 120),
            rounds = listOf(
                DuelRoundPlan(number = 1, kind = DuelRoundKind.MIXED, questions = questions("mixed"), bot = theirAnswers(0)),
                DuelRoundPlan(
                    number = 2, kind = DuelRoundKind.PICK, picker = "me",
                    options = listOf("history", "art", "science").map {
                        DuelRoundOption(subject = it, questions = questions(it), bot = theirAnswers(5))
                    },
                ),
                DuelRoundPlan(
                    number = 3, kind = DuelRoundKind.PICK, picker = "opponent", subject = "mythology",
                    questions = questions("mythology"), bot = theirAnswers(10),
                ),
                DuelRoundPlan(number = 4, kind = DuelRoundKind.SPRINT, questions = questions("sprint", limit = 8_000), bot = theirAnswers(15)),
            ),
            tiebreak = tiebreak,
            tiebreakBot = tiebreakAnswer,
            opponentLeavesAfter = leavesAfter,
        )
    }

    /** Une partie sur une horloge de test. `script` est appelé après chaque attente du déroulé. */
    private inner class Simulation(match: DuelMatch, private val script: Simulation.() -> Unit = {}) {
        var now = 10_000L
        val haptics = mutableListOf<DuelHaptic>()

        /** L'instant (sur l'horloge de test) de chaque vibration. */
        val hapticTimes = mutableListOf<Pair<DuelHaptic, Long>>()
        val model: DuelGameModel = DuelGameModel(
            match = match,
            haptic = {
                haptics += it
                hapticTimes += it to now
            },
            clock = { now },
            random = Random(7),
            pause = { ms ->
                now += ms
                script(this@Simulation)
            },
        )
        private var seenIndex = -1
        private var startedAt = 0L

        /** Le temps écoulé depuis le début de la question en cours ; -1 hors d'une question. */
        fun elapsed(): Long {
            if (model.phase != DuelPhase.Answering) return -1
            if (model.index != seenIndex) {
                seenIndex = model.index
                // Le script voit la question pour la première fois un pas après son début.
                startedAt = now - DuelRules.TICK_MS
            }
            return now - startedAt
        }

        /** Choisit `subject` trois secondes après l'ouverture du choix. */
        fun pickAfterThreeSeconds(subject: String) {
            val intro = model.roundIntro ?: return
            if (model.phase == DuelPhase.RoundIntro && intro.mine && intro.chosen == null && now - intro.opensAtMs >= 3_000) {
                model.pickSubject(subject)
            }
        }

        /** Joue la partie jusqu'au bout et rend sa durée. */
        fun play(): Long {
            val start = now
            runBlocking { model.run() }
            return now - start
        }
    }

    /** L'instant (multiple du pas) où le joueur scripté répond à la question `index`. */
    private fun lockTime(index: Int): Long = 1_000L + 50L * index

    // ------------------------------------------------------------ la partie entière

    @Test
    fun `a full match sends one answer per question in play order with the picked subject`() {
        // Je réponds juste aux questions paires ; l'adversaire à une sur quatre.
        val simulation = Simulation(match(opponentCorrect = { it % 4 == 0 })) {
            pickAfterThreeSeconds("art")
            if (elapsed() == lockTime(model.index) && !model.playerLocked) {
                model.choose(if (model.index % 2 == 0) 0 else 1)
            }
        }
        simulation.play()
        val model = simulation.model
        val summary = model.summary

        assertEquals(DuelPhase.Finished, model.phase)
        assertEquals(20, summary.answers.size)
        // L'ordre de jeu : chaque réponse porte l'instant propre à sa question.
        assertEquals(
            List(20) { DuelAnswer(c = if (it % 2 == 0) 0 else 1, v = null, t = lockTime(it).toInt()) },
            summary.answers,
        )
        assertEquals("art", summary.pick)
        assertEquals(List(5) { "art-$it" }, (5 until 10).map { model.questionAt(it).id })
        assertEquals("mythology", model.subjectAt(12))
        assertNull(model.subjectAt(3))
        assertNull(model.subjectAt(17))

        assertEquals(10, summary.playerScore)
        assertEquals(5, summary.opponentScore)
        assertTrue(summary.won)
        assertFalse(summary.tiebreak)
        assertFalse(summary.abandoned)
        assertFalse(summary.forfeit)
        assertEquals(List(20) { it % 2 == 0 }, model.playerMarks)
        assertEquals(List(20) { it % 4 == 0 }, model.opponentMarks)
    }

    @Test
    fun `without a pick the first subject is played after eight seconds`() {
        val simulation = Simulation(match())
        val model = simulation.model
        val duration = simulation.play()

        assertEquals("history", model.summary.pick)
        assertEquals(List(5) { "history-$it" }, (5 until 10).map { model.questionAt(it).id })
        // Personne ne répond : 15 questions de 12 s, 5 de 8 s, 20 révélations, puis les annonces
        // (8 s pour choisir + 1,3 s ; 2,4 s + 1,7 s pour l'adversaire ; 2,8 s pour le sprint),
        // l'annonce de la question décisive (0 à 0), cette question (15 s) et sa révélation.
        val questions = 15 * 12_000L + 5 * 8_000L + 20 * DuelRules.REVEAL_MS
        val intros = (8_000L + 1_300L) + (2_400L + 1_700L) + 2_800L
        val suddenDeath = 2_400L + 15_000L + DuelRules.REVEAL_SLIDER_MS
        assertEquals(questions + intros + suddenDeath, duration)
        assertEquals(List(21) { null }, model.summary.answers.map { it.c ?: it.v })
    }

    // ------------------------------------------------------------ une question

    @Test
    fun `an unanswered question lasts its whole timer then the reveal`() {
        val single = match().copy(rounds = match(opponentCorrect = { true }).rounds.take(1).map { it.copy(questions = it.questions?.take(1)) })
        val simulation = Simulation(single)
        val duration = simulation.play()

        assertEquals(12_000L + DuelRules.REVEAL_MS, duration)
        assertEquals(listOf(DuelAnswer(c = null, v = null, t = 12_000)), simulation.model.answers)
        assertEquals(0, simulation.model.playerScore)
        assertEquals(1, simulation.model.opponentScore)
        assertFalse(simulation.model.summary.won)
        // Le chrono se fait sentir une fois par seconde sur les trois dernières.
        assertEquals(3, simulation.haptics.count { it == DuelHaptic.Clock })
        assertEquals(listOf(DuelHaptic.Wrong), simulation.haptics.takeLast(1))
    }

    @Test
    fun `once the player has answered the opponent follows within a second and a half`() {
        val single = match().copy(rounds = match(opponentCorrect = { false }).rounds.take(1).map { it.copy(questions = it.questions?.take(1)) })
        val simulation = Simulation(single) {
            if (elapsed() == 2_000L && !model.playerLocked) model.choose(0)
        }
        val start = simulation.now
        val duration = simulation.play()
        val opponentAnsweredAt = simulation.hapticTimes.first { it.first == DuelHaptic.OpponentAnswered }.second - start

        // Le même tirage que la partie : entre 0,5 et 1,4 s après ma réponse, au pas suivant.
        val delay = Random(7).nextLong(DuelRules.OPPONENT_DELAY_MIN_MS, DuelRules.OPPONENT_DELAY_MAX_MS + 1)
        assertTrue(delay in 500..1_400)
        val expected = (2_000L + delay + DuelRules.TICK_MS - 1) / DuelRules.TICK_MS * DuelRules.TICK_MS
        assertEquals(expected, opponentAnsweredAt)
        assertEquals(expected + DuelRules.BOTH_ANSWERED_MS + DuelRules.REVEAL_MS, duration)
        assertEquals(listOf(DuelAnswer(c = 0, v = null, t = 2_000)), simulation.model.answers)
        assertTrue(simulation.model.summary.won)
        assertEquals(0, simulation.haptics.count { it == DuelHaptic.Clock })
    }

    // ------------------------------------------------------------ question décisive

    @Test
    fun `a tie is decided by the extra question sent last without changing the score`() {
        // 10 à 10 : je réponds juste aux questions paires, l'adversaire aux impaires.
        val simulation = Simulation(match(opponentCorrect = { it % 2 == 1 })) {
            val index = model.index
            if (elapsed() == lockTime(index) && !model.playerLocked) {
                if (index < model.questionCount) {
                    model.choose(if (index % 2 == 0) 0 else 1)
                } else {
                    // La question décisive : 45 pour une bonne valeur de 40, l'adversaire dit 70.
                    model.setSlider(45.0)
                    model.lockSlider()
                }
            }
        }
        simulation.play()
        val summary = simulation.model.summary

        assertEquals(21, summary.answers.size)
        assertEquals(DuelAnswer(c = null, v = 45.0, t = lockTime(20).toInt()), summary.answers[20])
        assertEquals(10, summary.playerScore)
        assertEquals(10, summary.opponentScore)
        assertTrue(summary.tiebreak)
        assertTrue(summary.won)
        assertEquals("tiebreak", simulation.model.question.id)
        assertEquals(20, simulation.model.playerMarks.size)
        assertTrue(DuelHaptic.SuddenDeath in simulation.haptics)
    }

    @Test
    fun `a tie-break left unanswered is lost`() {
        val simulation = Simulation(match(opponentCorrect = { false }))
        simulation.play()
        val summary = simulation.model.summary
        assertEquals(0, summary.playerScore)
        assertEquals(0, summary.opponentScore)
        assertTrue(summary.tiebreak)
        assertFalse(summary.won)
        assertEquals(DuelAnswer(c = null, v = null, t = 15_000), summary.answers[20])
    }

    // ------------------------------------------------------------ départ de l'adversaire, abandon

    @Test
    fun `the match stops on a win right after the question the opponent leaves on`() {
        val simulation = Simulation(match(opponentCorrect = { true }, leavesAfter = 7)) {
            pickAfterThreeSeconds("science")
        }
        val duration = simulation.play()
        val model = simulation.model
        val summary = model.summary

        assertEquals(DuelPhase.Finished, model.phase)
        assertTrue(model.opponentForfeited)
        assertEquals(7, summary.answers.size)
        assertEquals(6, model.index)
        assertTrue(summary.forfeit)
        // Une victoire, même menée 0 à 7, et sans question décisive.
        assertTrue(summary.won)
        assertFalse(summary.abandoned)
        assertFalse(summary.tiebreak)
        assertEquals(0, summary.playerScore)
        assertEquals(7, summary.opponentScore)
        assertEquals("science", summary.pick)
        // Sept questions sans réponse, l'annonce de ma manche (3 s puis 1,3 s), puis 2,8 s d'annonce du départ.
        assertEquals(7 * (12_000L + DuelRules.REVEAL_MS) + (3_000L + 1_300L) + DuelRules.FORFEIT_MS, duration)
    }

    @Test
    fun `quitting sends the answers given so far as a defeat`() {
        val simulation = Simulation(match(opponentCorrect = { false })) {
            pickAfterThreeSeconds("art")
            if (elapsed() == lockTime(model.index) && !model.playerLocked) model.choose(0)
            // Le joueur quitte pendant la huitième question, après y avoir répondu.
            if (model.index == 7 && model.phase == DuelPhase.Reveal) throw CancellationException("quit")
        }
        try {
            simulation.play()
        } catch (_: CancellationException) {
            // La partie s'arrête là où elle en est, comme une coroutine annulée.
        }
        val summary = simulation.model.abandonSummary()

        assertEquals(8, summary.answers.size)
        assertTrue(summary.abandoned)
        assertFalse(summary.won)
        assertFalse(summary.tiebreak)
        assertFalse(summary.forfeit)
        assertEquals(8, summary.playerScore)
        assertEquals("art", summary.pick)
        assertEquals("match-1", summary.match.matchId)
    }

    @Test
    fun `quitting before my round is played sends no pick`() {
        val simulation = Simulation(match()) {
            if (model.index == 2 && model.phase == DuelPhase.Answering) throw CancellationException("quit")
        }
        try {
            simulation.play()
        } catch (_: CancellationException) {
        }
        val summary = simulation.model.abandonSummary()
        assertEquals(2, summary.answers.size)
        assertNull(summary.pick)
    }

    // ------------------------------------------------------------ gestes du joueur

    @Test
    fun `an answer cannot be changed and a late pick is refused`() {
        var lateTry = false
        val simulation = Simulation(match()) {
            if (model.index == 0 && elapsed() == 1_000L) {
                model.choose(2)
                // Un second geste ne change rien.
                model.choose(0)
                assertEquals(2, model.selectedChoice)
            }
            val intro = model.roundIntro
            if (!lateTry && model.phase == DuelPhase.RoundIntro && intro != null && intro.mine &&
                intro.deadlineMs != null && now >= intro.deadlineMs!!
            ) {
                lateTry = true
                model.pickSubject("science")
            }
        }
        simulation.play()
        assertTrue(lateTry)
        assertEquals(2, simulation.model.answers[0].c)
        assertEquals("history", simulation.model.summary.pick)
    }
}
