package app.rork.sophia

import app.rork.sophia.domain.DuelAnswer
import app.rork.sophia.domain.DuelBotAnswer
import app.rork.sophia.domain.DuelQuestion
import app.rork.sophia.domain.DuelQuestionKind
import app.rork.sophia.domain.DuelRoundKind
import app.rork.sophia.domain.DuelRoundOption
import app.rork.sophia.domain.DuelRoundPlan
import app.rork.sophia.domain.DuelScoring
import app.rork.sophia.ui.duels.DuelRound
import app.rork.sophia.ui.duels.DuelRules
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Les règles d'une partie de duel, telles que le serveur les recompte : qui marque sur chaque
 * genre de question, qui gagne la question décisive, quelle matière est retenue quand le joueur
 * ne choisit pas, et ce qui part dans la réponse envoyée.
 */
class DuelRulesTest {

    private fun choice(
        kind: DuelQuestionKind = DuelQuestionKind.MCQ,
        correct: Int = 2,
        options: List<String> = listOf("a", "b", "c", "d"),
        limit: Int = 12_000,
    ) = DuelQuestion(id = "q", kind = kind, question = "?", options = options, correctIndex = correct, timeLimitMs = limit)

    private fun slider(
        correct: Double? = 50.0,
        min: Double? = 0.0,
        max: Double? = 100.0,
        step: Double? = 1.0,
        limit: Int = 15_000,
    ) = DuelQuestion(
        id = "s", kind = DuelQuestionKind.SLIDER, question = "?",
        sliderMin = min, sliderMax = max, sliderStep = step, correctValue = correct, timeLimitMs = limit,
    )

    private fun theirs(correct: Boolean = false, choice: Int? = null, value: Double? = null, timeMs: Int = 3_000) =
        DuelBotAnswer(correct = correct, choice = choice, value = value, timeMs = timeMs)

    // ------------------------------------------------------------ le point d'une question

    @Test
    fun `a choice question scores the right option only`() {
        for (kind in listOf(DuelQuestionKind.MCQ, DuelQuestionKind.TRUE_FALSE, DuelQuestionKind.PORTRAIT)) {
            val question = choice(kind = kind, correct = 1, options = listOf("a", "b"))
            assertEquals(true to false, DuelScoring.round(question, DuelAnswer(c = 1, t = 900), theirs(correct = false, choice = 0)))
            assertEquals(false to true, DuelScoring.round(question, DuelAnswer(c = 0, t = 900), theirs(correct = true, choice = 1)))
            assertEquals(true to true, DuelScoring.round(question, DuelAnswer(c = 1, t = 900), theirs(correct = true, choice = 1)))
        }
    }

    @Test
    fun `no answer in time scores nothing but the opponent can still score`() {
        val question = choice(correct = 0)
        assertEquals(false to true, DuelScoring.round(question, DuelAnswer(c = null, t = 12_000), theirs(correct = true, choice = 0)))
        assertEquals(false to false, DuelScoring.round(question, null, theirs(correct = false)))
    }

    @Test
    fun `on a slider the closest scores and a dead heat gives a point each`() {
        val question = slider(correct = 50.0)
        assertEquals(true to false, DuelScoring.round(question, DuelAnswer(v = 48.0), theirs(value = 55.0)))
        assertEquals(false to true, DuelScoring.round(question, DuelAnswer(v = 30.0), theirs(value = 55.0)))
        // 46 et 54 sont à la même distance de 50.
        assertEquals(true to true, DuelScoring.round(question, DuelAnswer(v = 46.0), theirs(value = 54.0)))
        assertEquals(true to true, DuelScoring.round(question, DuelAnswer(v = 50.0), theirs(value = 50.0)))
    }

    @Test
    fun `a slider left untouched gives the point to whoever answered`() {
        val question = slider(correct = 50.0)
        assertEquals(false to true, DuelScoring.round(question, DuelAnswer(v = null, t = 15_000), theirs(value = 99.0)))
        assertEquals(true to false, DuelScoring.round(question, DuelAnswer(v = 1.0), theirs(value = null)))
        assertEquals(false to false, DuelScoring.round(question, DuelAnswer(v = null), theirs(value = null)))
        assertEquals(false to false, DuelScoring.round(question, null, theirs(value = null)))
        // Sans bonne valeur connue, personne ne marque.
        assertEquals(false to false, DuelScoring.round(slider(correct = null), DuelAnswer(v = 50.0), theirs(value = 50.0)))
    }

    // ------------------------------------------------------------ la question décisive

    @Test
    fun `the tie-break goes to the closest then to the fastest`() {
        val question = slider(correct = 1_000.0, min = 0.0, max = 2_000.0)
        assertTrue(DuelScoring.playerWinsTiebreak(question, DuelAnswer(v = 990.0, t = 9_000), theirs(value = 1_020.0, timeMs = 1_000)))
        assertFalse(DuelScoring.playerWinsTiebreak(question, DuelAnswer(v = 900.0, t = 1_000), theirs(value = 1_020.0, timeMs = 9_000)))
        // À distance égale, le plus rapide ; à temps égal, le joueur.
        assertTrue(DuelScoring.playerWinsTiebreak(question, DuelAnswer(v = 990.0, t = 4_000), theirs(value = 1_010.0, timeMs = 5_000)))
        assertTrue(DuelScoring.playerWinsTiebreak(question, DuelAnswer(v = 990.0, t = 5_000), theirs(value = 1_010.0, timeMs = 5_000)))
        assertFalse(DuelScoring.playerWinsTiebreak(question, DuelAnswer(v = 990.0, t = 5_001), theirs(value = 1_010.0, timeMs = 5_000)))
    }

    @Test
    fun `the tie-break is lost without an answer and won against a silent opponent`() {
        val question = slider(correct = 1_000.0, min = 0.0, max = 2_000.0)
        assertFalse(DuelScoring.playerWinsTiebreak(question, DuelAnswer(v = null, t = 15_000), theirs(value = 0.0)))
        assertFalse(DuelScoring.playerWinsTiebreak(question, null, theirs(value = null)))
        assertTrue(DuelScoring.playerWinsTiebreak(question, DuelAnswer(v = 0.0, t = 14_000), theirs(value = null)))
        assertFalse(DuelScoring.playerWinsTiebreak(slider(correct = null), DuelAnswer(v = 1.0), theirs(value = 500.0)))
    }

    @Test
    fun `the tie-break has exactly one winner while a normal question can reward both`() {
        val question = slider(correct = 50.0)
        val answer = DuelAnswer(v = 46.0, t = 2_000)
        val opponent = theirs(value = 54.0, timeMs = 3_000)
        assertEquals(DuelRound(player = true, opponent = true), DuelRules.score(question, answer, opponent, isTiebreak = false))
        assertEquals(DuelRound(player = true, opponent = false), DuelRules.score(question, answer, opponent, isTiebreak = true))
        assertEquals(
            DuelRound(player = false, opponent = true),
            DuelRules.score(question, answer.copy(t = 3_001), opponent, isTiebreak = true),
        )
    }

    // ------------------------------------------------------------ ma réponse

    @Test
    fun `an answer carries the choice and the time it was locked at`() {
        val question = choice(limit = 12_000)
        assertEquals(
            DuelAnswer(c = 3, v = null, t = 2_350),
            DuelRules.answer(question, selectedChoice = 3, sliderValue = 0.0, locked = true, sliderTouched = false, lockedAtMs = 2_350),
        )
        // Sans réponse : pas de choix, et le temps du chrono entier.
        assertEquals(
            DuelAnswer(c = null, v = null, t = 12_000),
            DuelRules.answer(question, selectedChoice = null, sliderValue = 0.0, locked = false, sliderTouched = false, lockedAtMs = null),
        )
        // Le temps ne dépasse jamais le chrono, même si la boucle a pris du retard.
        assertEquals(
            12_000,
            DuelRules.answer(question, selectedChoice = 1, sliderValue = 0.0, locked = true, sliderTouched = false, lockedAtMs = 12_040).t,
        )
    }

    @Test
    fun `a slider counts once touched even without lock in`() {
        val question = slider(limit = 15_000)
        assertEquals(
            DuelAnswer(c = null, v = 62.0, t = 15_000),
            DuelRules.answer(question, selectedChoice = null, sliderValue = 62.0, locked = false, sliderTouched = true, lockedAtMs = null),
        )
        assertEquals(
            DuelAnswer(c = null, v = 50.0, t = 4_000),
            DuelRules.answer(question, selectedChoice = null, sliderValue = 50.0, locked = true, sliderTouched = true, lockedAtMs = 4_000),
        )
        assertNull(
            DuelRules.answer(question, selectedChoice = null, sliderValue = 50.0, locked = false, sliderTouched = false, lockedAtMs = null).v,
        )
    }

    // ------------------------------------------------------------ curseur

    @Test
    fun `the slider snaps to its step and stays within its bounds`() {
        val years = slider(min = 1_400.0, max = 1_600.0, step = 5.0)
        assertEquals(1_490.0, DuelRules.snap(1_492.0, years), 0.0)
        assertEquals(1_495.0, DuelRules.snap(1_492.5, years), 0.0)
        assertEquals(1_400.0, DuelRules.snap(900.0, years), 0.0)
        assertEquals(1_600.0, DuelRules.snap(2_000.0, years), 0.0)
        assertEquals(1_500.0, DuelRules.sliderStart(years), 0.0)

        val decimals = slider(min = 0.0, max = 1.0, step = 0.1)
        assertEquals(0.3, DuelRules.snap(0.34, decimals), 1e-9)
        // Sans bornes ni pas : de 0 à 100, de un en un.
        val bare = slider(min = null, max = null, step = null)
        assertEquals(50.0, DuelRules.sliderStart(bare), 0.0)
        assertEquals(100.0, DuelRules.snap(140.2, bare), 0.0)
        // Un pas nul ne divise pas par zéro.
        assertEquals(42.0, DuelRules.snap(42.0, slider(step = 0.0)), 1e-3)
    }

    // ------------------------------------------------------------ manches

    private val options = listOf("history", "art", "science").map { subject ->
        DuelRoundOption(
            subject = subject,
            questions = (0 until 5).map { choice().copy(id = "$subject-$it") },
            bot = (0 until 5).map { theirs(timeMs = 1_000 + it) },
        )
    }
    private val myPick = DuelRoundPlan(number = 2, kind = DuelRoundKind.PICK, picker = "me", options = options)

    @Test
    fun `without a choice in time the first subject is played`() {
        assertEquals("history", DuelRules.fallbackPick(options.map { it.subject }, chosen = null))
        assertEquals("art", DuelRules.fallbackPick(options.map { it.subject }, chosen = "art"))
        assertNull(DuelRules.fallbackPick(emptyList(), chosen = null))

        val fallback = DuelRules.resolveRound(myPick, chosen = null)
        assertEquals("history", fallback.subject)
        assertEquals(List(5) { "history-$it" }, fallback.questions.map { it.id })
        // Une matière inconnue retombe aussi sur la première.
        assertEquals("history", DuelRules.resolveRound(myPick, chosen = "cooking").subject)
    }

    @Test
    fun `my pick plays the questions and the opponent answers of that subject`() {
        val resolved = DuelRules.resolveRound(myPick, chosen = "science")
        assertEquals("science", resolved.subject)
        assertEquals(List(5) { "science-$it" }, resolved.questions.map { it.id })
        assertEquals(options[2].bot, resolved.opponentAnswers)
        assertEquals("science", DuelRules.myPick(listOf(myPick), mapOf(2 to "science", 3 to "art")))
        assertNull(DuelRules.myPick(listOf(myPick), mapOf(3 to "art")))
    }

    @Test
    fun `the opponent's pick keeps its subject and other rounds have none`() {
        val questions = (0 until 5).map { choice().copy(id = "t-$it") }
        val theirs = DuelRoundPlan(number = 3, kind = DuelRoundKind.PICK, picker = "opponent", subject = "mythology", questions = questions)
        assertEquals("mythology", DuelRules.resolveRound(theirs, chosen = null).subject)
        assertNull(DuelRules.myPick(listOf(theirs), mapOf(3 to "mythology")))

        val sprint = DuelRoundPlan(number = 4, kind = DuelRoundKind.SPRINT, questions = questions + questions)
        val resolved = DuelRules.resolveRound(sprint, chosen = null)
        assertNull(resolved.subject)
        // Jamais plus de cinq questions par manche.
        assertEquals(5, resolved.questions.size)
        assertTrue(resolved.opponentAnswers.isEmpty())
    }

    @Test
    fun `questions are grouped by five into rounds`() {
        assertEquals(1, DuelRules.roundNumber(0, 4))
        assertEquals(1, DuelRules.roundNumber(4, 4))
        assertEquals(2, DuelRules.roundNumber(5, 4))
        assertEquals(4, DuelRules.roundNumber(19, 4))
        // La question décisive reste rattachée à la dernière manche.
        assertEquals(4, DuelRules.roundNumber(20, 4))
        assertEquals(1, DuelRules.roundNumber(0, 0))
    }

    // ------------------------------------------------------------ l'adversaire

    @Test
    fun `the opponent leaves right after the question it is due to leave on`() {
        assertFalse(DuelRules.opponentLeaves(leavesAfter = null, questionsPlayed = 7))
        assertFalse(DuelRules.opponentLeaves(leavesAfter = 7, questionsPlayed = 6))
        assertTrue(DuelRules.opponentLeaves(leavesAfter = 7, questionsPlayed = 7))
        assertFalse(DuelRules.opponentLeaves(leavesAfter = 7, questionsPlayed = 8))
    }

    @Test
    fun `the opponent answers at its own time or shortly after the player`() {
        assertEquals(6_000L, DuelRules.opponentAnswerTimeMs(ownTimeMs = 6_000, lockedAtMs = null, delayMs = 900))
        assertEquals(2_900L, DuelRules.opponentAnswerTimeMs(ownTimeMs = 6_000, lockedAtMs = 2_000, delayMs = 900))
        // Déjà plus rapide que le joueur : son instant ne change pas.
        assertEquals(1_500L, DuelRules.opponentAnswerTimeMs(ownTimeMs = 1_500, lockedAtMs = 2_000, delayMs = 900))
    }

    @Test
    fun `the opponent never answers later than a tenth of a second before the end`() {
        assertFalse(DuelRules.opponentHasAnswered(elapsedMs = 11_850, opponentTimeMs = 30_000, limitMs = 12_000))
        assertTrue(DuelRules.opponentHasAnswered(elapsedMs = 11_900, opponentTimeMs = 30_000, limitMs = 12_000))
        assertTrue(DuelRules.opponentHasAnswered(elapsedMs = 3_000, opponentTimeMs = 3_000, limitMs = 12_000))
        assertFalse(DuelRules.opponentHasAnswered(elapsedMs = 2_950, opponentTimeMs = 3_000, limitMs = 12_000))
        // Sans réponse dans les données de la partie : fausse, à mi-chrono.
        assertEquals(DuelBotAnswer(correct = false, choice = null, value = null, timeMs = 6_000), DuelRules.missingOpponentAnswer(choice()))
    }

    // ------------------------------------------------------------ chrono et absence

    @Test
    fun `the timer counts whole seconds up and empties from one to zero`() {
        assertEquals(12, DuelRules.secondsLeft(12_000, 0))
        assertEquals(12, DuelRules.secondsLeft(12_000, 50))
        assertEquals(3, DuelRules.secondsLeft(12_000, 9_000))
        assertEquals(1, DuelRules.secondsLeft(12_000, 11_950))
        assertEquals(0, DuelRules.secondsLeft(12_000, 12_000))

        assertEquals(1.0, DuelRules.remainingFraction(12_000, 0), 0.0)
        assertEquals(0.25, DuelRules.remainingFraction(12_000, 9_000), 1e-9)
        assertEquals(0.0, DuelRules.remainingFraction(12_000, 40_000), 0.0)
        assertEquals(0.0, DuelRules.remainingFraction(0, 10), 0.0)
        assertEquals(2_800L, DuelRules.revealMs(DuelQuestionKind.SLIDER))
        assertEquals(1_800L, DuelRules.revealMs(DuelQuestionKind.TRUE_FALSE))
    }

    @Test
    fun `the final score counts up slower and slower`() {
        val delays = (1..20).map { DuelRules.scoreCountDelayMs(it, 20) }
        assertEquals(delays.sorted(), delays)
        assertEquals(55L, DuelRules.scoreCountDelayMs(1, 20))
        assertEquals(330L, DuelRules.scoreCountDelayMs(20, 20))
        // Un score d'un seul point, ou aucun : pas de division par zéro.
        assertEquals(330L, DuelRules.scoreCountDelayMs(1, 1))
        assertEquals(0L, DuelRules.scoreCountDelayMs(0, 0))
    }

    @Test
    fun `leaving the app is an abandon only beyond fifteen seconds`() {
        assertFalse(DuelRules.abandonsAfterAbsence(3_000))
        assertFalse(DuelRules.abandonsAfterAbsence(15_000))
        assertTrue(DuelRules.abandonsAfterAbsence(15_001))
    }
}
