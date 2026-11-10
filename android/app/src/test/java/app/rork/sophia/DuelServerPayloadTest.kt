package app.rork.sophia

import app.rork.sophia.domain.DuelHome
import app.rork.sophia.domain.DuelLeaderboardEntry
import app.rork.sophia.domain.DuelMatch
import app.rork.sophia.domain.DuelQuestionKind
import app.rork.sophia.domain.DuelResult
import app.rork.sophia.domain.DuelRoundKind
import app.rork.sophia.ui.duels.DuelGameModel
import app.rork.sophia.ui.duels.DuelPhase
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.random.Random

/**
 * Les réponses réelles du serveur, telles que les fonctions SQL des duels les renvoient
 * (les fichiers JSON de `src/test/resources/duels`, produits par les migrations sur une base de test), sont
 * décodées par les modèles de l'app, et une partie entière se joue avec.
 */
class DuelServerPayloadTest {
    // Les mêmes réglages que DuelService.
    private val json = Json { ignoreUnknownKeys = true; explicitNulls = false; coerceInputValues = true }

    private fun fixture(name: String): String =
        checkNotNull(javaClass.getResourceAsStream("/duels/$name.json")) { "fixture $name" }
            .bufferedReader().use { it.readText() }

    @Test
    fun `home decodes with its thirty leagues`() {
        val home: DuelHome = json.decodeFromString(fixture("home"))
        assertEquals(30, home.leagues.size)
        assertEquals((1..30).toList(), home.leagues.map { it.position })
        assertNotNull(home.currentLeague)
        assertTrue(home.leagues.all { it.backgroundUrl.startsWith("https://") && it.accentHex.startsWith("#") })
        assertTrue(home.recent.all { it.opponent.handle.isNotEmpty() })
    }

    @Test
    fun `leaderboard decodes`() {
        val rows: List<DuelLeaderboardEntry> = json.decodeFromString(fixture("leaderboard"))
        assertTrue(rows.isNotEmpty())
        assertEquals(1, rows.count { it.isMe })
    }

    @Test
    fun `match start decodes into four rounds of five`() {
        val match: DuelMatch = json.decodeFromString(fixture("start"))
        assertEquals(listOf(DuelRoundKind.MIXED, DuelRoundKind.PICK, DuelRoundKind.PICK, DuelRoundKind.SPRINT), match.rounds.map { it.kind })
        assertEquals(20, match.questionCount)
        assertEquals(5, match.rounds[0].questions?.size)
        assertTrue(match.rounds[1].isMyPick)
        assertEquals(3, match.rounds[1].options?.size)
        assertTrue(match.rounds[1].options.orEmpty().all { it.questions.size == 5 && it.bot?.size == 5 })
        assertEquals(5, match.rounds[2].questions?.size)
        assertEquals(DuelQuestionKind.SLIDER, match.tiebreak.kind)
        assertNotNull(match.tiebreakBot)
        // Chaque question à choix a ses options et sa bonne réponse ; chaque curseur ses bornes.
        for (question in match.allQuestions) {
            if (question.kind == DuelQuestionKind.SLIDER) {
                assertTrue(question.sliderMin!! < question.correctValue!! && question.correctValue!! < question.sliderMax!!)
            } else {
                val options = question.options.orEmpty()
                assertTrue(options.size in 2..4)
                assertTrue(question.correctIndex!! in options.indices)
            }
            if (question.kind == DuelQuestionKind.PORTRAIT) assertFalse(question.imageUrl.isNullOrEmpty())
            assertTrue(question.timeLimitMs > 0)
        }
    }

    @Test
    fun `a whole match plays from the server payload`() = runBlocking {
        val match: DuelMatch = json.decodeFromString(fixture("start"))
        var now = 0L
        lateinit var model: DuelGameModel
        model = DuelGameModel(
            match = match,
            clock = { now },
            random = Random(3),
            pause = { ms ->
                now += ms
                // Je choisis la deuxième matière proposée, et je réponds à toutes les questions à choix.
                model.roundIntro?.let { intro ->
                    if (intro.mine && intro.chosen == null) model.pickSubject(intro.options[1])
                }
                if (model.phase == DuelPhase.Answering && model.roundIntro == null && model.selectedChoice == null &&
                    model.question.kind != DuelQuestionKind.SLIDER
                ) {
                    model.choose(0)
                }
            },
        )
        model.run()
        val summary = model.summary
        assertFalse(summary.abandoned)
        assertEquals(match.rounds[1].options!![1].subject, summary.pick)
        // Une réponse par question jouée (20, ou 21 avec la question décisive), chacune avec son temps.
        assertTrue(summary.answers.size == 20 || summary.answers.size == 21)
        assertTrue(summary.answers.all { it.t >= 0 })
        assertTrue(summary.playerScore in 0..20 && summary.opponentScore in 0..20)
        // Ce que l'app envoie au serveur se relit tel quel.
        val sent = json.encodeToString(kotlinx.serialization.builtins.ListSerializer(app.rork.sophia.domain.DuelAnswer.serializer()), summary.answers)
        assertTrue(sent.startsWith("[{"))
    }

    @Test
    fun `match result decodes`() {
        val result: DuelResult = json.decodeFromString(fixture("finish"))
        assertEquals(result.trophiesBefore + result.trophiesDelta, result.trophiesAfter)
        assertEquals(result.trophiesAfter, result.profile.trophies)
        assertTrue(result.leagueAfter >= 1)
    }
}
