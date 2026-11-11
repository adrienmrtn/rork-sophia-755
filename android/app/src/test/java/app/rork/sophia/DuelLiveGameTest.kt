package app.rork.sophia

import app.rork.sophia.domain.DuelAnswer
import app.rork.sophia.domain.DuelFriendState
import app.rork.sophia.domain.DuelMatch
import app.rork.sophia.domain.DuelOpponent
import app.rork.sophia.domain.DuelQuestion
import app.rork.sophia.domain.DuelQuestionKind
import app.rork.sophia.domain.DuelRoundKind
import app.rork.sophia.domain.DuelRoundOption
import app.rork.sophia.domain.DuelRoundPlan
import app.rork.sophia.ui.duels.DuelGameModel
import app.rork.sophia.ui.duels.DuelLiveLink
import app.rork.sophia.ui.duels.DuelPhase
import app.rork.sophia.ui.duels.DuelRules
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.yield
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.IOException

/**
 * Une partie entre amis entière, jouée contre un faux serveur sur une horloge de test. Le faux
 * serveur suit les règles du vrai (`duel_friend_*`) : une question est close quand les deux ont
 * répondu ou quand son temps est écoulé, la suivante démarre après la révélation, et la matière
 * d'une manche au choix est fixée par celui qui choisit (ou la première proposée).
 */
class DuelLiveGameTest {
    private fun mcq(id: String, limit: Int = 12_000) = DuelQuestion(
        id = id, kind = DuelQuestionKind.MCQ, question = id,
        options = listOf("a", "b", "c", "d"), correctIndex = 0, timeLimitMs = limit,
    )

    private val tiebreak = DuelQuestion(
        id = "tiebreak", kind = DuelQuestionKind.SLIDER, question = "tiebreak",
        sliderMin = 0.0, sliderMax = 100.0, sliderStep = 1.0, correctValue = 40.0, timeLimitMs = 15_000,
    )

    private fun questions(prefix: String, limit: Int = 12_000) = (0 until 5).map { mcq("$prefix-$it", limit) }

    private fun options(vararg subjects: String) = subjects.map { DuelRoundOption(subject = it, questions = questions(it)) }

    private val match = DuelMatch(
        matchId = "friend-1",
        opponent = DuelOpponent(userId = "u2", handle = "ada", trophies = 120),
        rounds = listOf(
            DuelRoundPlan(number = 1, kind = DuelRoundKind.MIXED, questions = questions("mixed")),
            DuelRoundPlan(number = 2, kind = DuelRoundKind.PICK, picker = "me", options = options("history", "art", "science")),
            DuelRoundPlan(number = 3, kind = DuelRoundKind.PICK, picker = "opponent", options = options("music", "mythology", "nature")),
            DuelRoundPlan(number = 4, kind = DuelRoundKind.SPRINT, questions = questions("sprint", limit = 8_000)),
        ),
        tiebreak = tiebreak,
    )

    /** Le faux serveur et l'horloge de test. [friendCorrect] : l'ami répond-il juste à la question i ? */
    private inner class Simulation(
        private val friendCorrect: (Int) -> Boolean,
        /** Les appels au serveur échouent tant que l'horloge est dans ces intervalles (coupure réseau). */
        private val outages: List<LongRange> = emptyList(),
    ) : DuelLiveLink {
        var now = 10_000L
        override val startsAtMs = now + 3_000L

        private val starts = HashMap<Int, Long>().apply { put(0, startsAtMs) }
        private val mine = HashMap<Int, DuelAnswer>()
        private val mineAt = HashMap<Int, Long>()
        private val picks = HashMap<String, String>()
        private val myPoints = ArrayList<Boolean>()
        private val theirPoints = ArrayList<Boolean>()
        private val theirAnswers = ArrayList<DuelAnswer>()
        private var finished = false
        var calls = 0

        private fun questionAt(i: Int): DuelQuestion {
            if (i >= 20) return tiebreak
            val plan = match.rounds[i / 5]
            val list = plan.questions
                ?: (plan.options!!.firstOrNull { it.subject == picks[plan.number.toString()] } ?: plan.options!![0]).questions
            return list[i % 5]
        }

        private fun advance() {
            // La matière de l'ami est connue quelques secondes avant sa manche.
            starts[10]?.let { if (now >= it - 6_000) picks.putIfAbsent("3", "mythology") }
            while (!finished) {
                val i = myPoints.size
                val start = starts[i] ?: return
                if (now < start) return
                // Sans choix à temps, la première matière proposée.
                if (i < 20 && i % 5 == 0) match.rounds[i / 5].options?.let { picks.putIfAbsent((i / 5 + 1).toString(), it[0].subject) }
                val question = questionAt(i)
                val friendAt = start + 2_000
                val closeAt = mineAt[i]?.let { maxOf(it, friendAt) } ?: (start + question.timeLimitMs)
                if (now < closeAt) return
                myPoints += mine[i]?.c == question.correctIndex
                theirPoints += friendCorrect(i)
                theirAnswers += DuelAnswer(c = if (friendCorrect(i)) 0 else 1, t = 2_000)
                if (i == 19 && myPoints.count { it } != theirPoints.count { it }) {
                    finished = true
                } else if (i == 19) {
                    error("pas de question décisive dans ce test")
                } else {
                    // La révélation, plus l'annonce quand une manche commence.
                    starts[i + 1] = closeAt + if ((i + 1) % 5 == 0) 11_000 else 2_500
                }
            }
        }

        private fun snapshot(): DuelFriendState {
            calls++
            if (outages.any { now in it }) throw IOException("offline")
            advance()
            val index = myPoints.size
            return DuelFriendState(
                matchId = match.matchId,
                finished = finished,
                index = minOf(index, 19),
                resolved = index,
                questionStartsInMs = ((starts[index] ?: now) - now).toInt(),
                myScore = myPoints.count { it },
                opponentScore = theirPoints.count { it },
                myAnswered = mine.containsKey(index),
                opponentAnswered = starts[index]?.let { now >= it + 2_000 } ?: false,
                opponentAnswers = theirAnswers.toList(),
                myPoints = myPoints.toList(),
                opponentPoints = theirPoints.toList(),
                picks = picks.toMap(),
                won = if (finished) myPoints.count { it } > theirPoints.count { it } else null,
            )
        }

        override suspend fun state(): DuelFriendState = snapshot()

        override suspend fun answer(index: Int, answer: DuelAnswer): DuelFriendState {
            if (outages.none { now in it } && index == myPoints.size && !mine.containsKey(index)) {
                mine[index] = answer
                mineAt[index] = now
            }
            return snapshot()
        }

        override suspend fun pick(round: Int, subject: String): DuelFriendState {
            if (outages.none { now in it }) picks.putIfAbsent(round.toString(), subject)
            return snapshot()
        }

        val model = DuelGameModel(
            match = match,
            live = this,
            clock = { now },
            pause = { ms ->
                now += ms
                script()
                // Le déroulé et les échanges avec le serveur avancent à tour de rôle.
                yield()
            },
        )

        private var seenIndex = -1
        private var seenAt = 0L

        /** Le joueur scripté : choisit « art » une seconde après l'ouverture du choix, répond juste après une seconde. */
        private fun script() {
            val intro = model.roundIntro
            if (model.phase == DuelPhase.RoundIntro && intro != null && intro.mine && intro.chosen == null &&
                now - intro.opensAtMs >= 1_000
            ) {
                model.pickSubject("art")
            }
            if (model.phase != DuelPhase.Answering) return
            if (model.index != seenIndex) {
                seenIndex = model.index
                seenAt = now
            }
            if (!model.playerLocked && now - seenAt >= 1_000) model.choose(0)
        }

        fun play() = runBlocking { model.run() }
    }

    @Test
    fun `a friendly match follows the server to the end`() {
        val simulation = Simulation(friendCorrect = { it % 2 == 0 })
        simulation.play()
        val model = simulation.model
        assertEquals(DuelPhase.Finished, model.phase)
        assertTrue(model.isLive)
        assertEquals(20, model.playerScore)
        assertEquals(10, model.opponentScore)
        assertTrue(model.playerWon)
        assertFalse(model.isDraw)
        assertFalse(model.isSuddenDeath)
        // Une réponse par question, dans l'ordre de jeu.
        assertEquals(20, model.answers.size)
        assertTrue(model.answers.all { it.c == 0 })
        // Ma matière, puis celle que le serveur donne pour la manche de l'ami.
        assertEquals(mapOf(2 to "art", 3 to "mythology"), model.roundSubjects)
        assertEquals("art-0", model.questionAt(5).id)
        assertEquals("mythology-4", model.questionAt(14).id)
        assertEquals(List(20) { true }, model.playerMarks)
        assertEquals(List(20) { it % 2 == 0 }, model.opponentMarks)
        // Les réponses de l'ami viennent du serveur.
        assertEquals(1, model.opponentAnswerAt(1).choice)
        assertTrue(model.opponentAnswerAt(0).correct)
        val summary = model.summary
        assertTrue(summary.friendly)
        assertTrue(summary.won)
        assertFalse(summary.abandoned)
    }

    @Test
    fun `a network cut is caught up without losing the match`() {
        // Douze secondes sans réseau au milieu de la première manche : la question en cours se
        // clôt au chrono côté serveur, puis le modèle rattrape.
        val simulation = Simulation(friendCorrect = { false }, outages = listOf(20_000L..32_000L))
        simulation.play()
        val model = simulation.model
        assertEquals(DuelPhase.Finished, model.phase)
        assertEquals(0, model.opponentScore)
        assertTrue(model.playerWon)
        // Les points suivent le serveur : au plus une question perdue pendant la coupure.
        assertTrue("score ${model.playerScore}", model.playerScore >= 18)
        assertEquals(model.playerScore, model.playerMarks.count { it == true })
        assertEquals(DuelRules.roundNumber(19, 4), model.roundNumber)
    }
}
