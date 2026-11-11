package app.rork.sophia

import app.rork.sophia.domain.DuelFriendState
import app.rork.sophia.domain.DuelInviteOutcome
import app.rork.sophia.domain.DuelPingResponse
import app.rork.sophia.domain.DuelRoundKind
import app.rork.sophia.domain.DuelSentInvite
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Les réponses réelles du serveur pour un duel entre amis, décodées par les modèles de l'app.
 * Les fichiers `friend_*.json` de `src/test/resources/duels` viennent d'une partie entière jouée
 * par deux comptes de test sur une base locale construite avec les migrations (`duel_ping`,
 * `duel_invite_friend`, `duel_invite_status`, `duel_invite_respond`, `duel_friend_state`,
 * `duel_friend_answer`).
 */
class DuelFriendPayloadTest {
    // Les mêmes réglages que DuelLiveService.
    private val json = Json { ignoreUnknownKeys = true; explicitNulls = false; coerceInputValues = true }

    private fun fixture(name: String): String =
        checkNotNull(javaClass.getResourceAsStream("/duels/$name.json")) { "fixture $name" }
            .bufferedReader().use { it.readText() }

    @Test
    fun `a ping carries the invitation while it waits`() {
        val idle: DuelPingResponse = json.decodeFromString(fixture("friend_ping_idle"))
        assertNull(idle.invite)
        val invited: DuelPingResponse = json.decodeFromString(fixture("friend_ping_invited"))
        val invite = checkNotNull(invited.invite)
        assertEquals("alice", invite.from.handle)
        assertTrue(invite.inviteId.isNotEmpty())
        assertTrue(invite.expiresInMs in 1..15_000)
    }

    @Test
    fun `a sent invitation names both players`() {
        val sent: DuelSentInvite = json.decodeFromString(fixture("friend_invite_sent"))
        assertEquals("alice", sent.me.handle)
        assertEquals("bruno", sent.friend.handle)
        assertNotNull(sent.friend.userId)
        assertTrue(sent.expiresInMs in 1..15_000)
        val pending: DuelInviteOutcome = json.decodeFromString(fixture("friend_invite_pending"))
        assertEquals("pending", pending.status)
        assertNull(pending.match)
    }

    @Test
    fun `both players receive the same match with their own pick round`() {
        val mine: DuelInviteOutcome = json.decodeFromString(fixture("friend_invite_accepted"))
        val theirs: DuelInviteOutcome = json.decodeFromString(fixture("friend_respond_accepted"))
        assertEquals("accepted", mine.status)
        assertEquals("accepted", theirs.status)
        val a = checkNotNull(mine.match)
        val b = checkNotNull(theirs.match)
        assertEquals(a.matchId, b.matchId)
        assertEquals("bruno", a.opponent.handle)
        assertEquals("alice", b.opponent.handle)
        assertTrue(a.startsInMs > 0)
        for (start in listOf(a, b)) {
            val match = start.match
            assertEquals(20, match.questionCount)
            assertEquals(
                listOf(DuelRoundKind.MIXED, DuelRoundKind.PICK, DuelRoundKind.PICK, DuelRoundKind.SPRINT),
                match.rounds.map { it.kind },
            )
            assertEquals(5, match.rounds[0].questions?.size)
            assertEquals(5, match.rounds[3].questions?.size)
            // Les deux manches au choix portent trois matières de cinq questions, pour les deux joueurs.
            for (round in match.rounds.subList(1, 3)) {
                assertEquals(3, round.options?.size)
                assertTrue(round.options.orEmpty().all { it.questions.size == 5 })
            }
            assertNull(match.tiebreakBot)
        }
        // Celui qui a lancé le défi choisit à la manche 2, l'autre à la manche 3.
        assertTrue(a.match.rounds[1].isMyPick)
        assertFalse(a.match.rounds[2].isMyPick)
        assertFalse(b.match.rounds[1].isMyPick)
        assertTrue(b.match.rounds[2].isMyPick)
        assertEquals(a.match.rounds[1].options?.map { it.subject }, b.match.rounds[1].options?.map { it.subject })
    }

    @Test
    fun `the state of the match decodes from start to finish`() {
        val start: DuelFriendState = json.decodeFromString(fixture("friend_state_start"))
        assertFalse(start.finished)
        assertEquals(0, start.index)
        assertEquals(0, start.resolved)
        assertTrue(start.questionStartsInMs > 0)
        assertTrue(start.picks.isNullOrEmpty())

        val midway: DuelFriendState = json.decodeFromString(fixture("friend_state_midway"))
        assertEquals(12, midway.resolved)
        assertEquals(12, midway.index)
        assertEquals(12, midway.opponentAnswers.size)
        assertEquals(12, midway.myPoints.size)
        assertEquals(12, midway.opponentPoints.size)
        assertEquals(midway.myScore, midway.myPoints.count { it })
        assertEquals(midway.opponentScore, midway.opponentPoints.count { it })
        assertEquals(setOf("2", "3"), midway.picks?.keys)

        val won: DuelFriendState = json.decodeFromString(fixture("friend_state_final"))
        val lost: DuelFriendState = json.decodeFromString(fixture("friend_state_final_loser"))
        assertTrue(won.finished && lost.finished)
        assertEquals(20, won.resolved)
        assertEquals(true, won.won)
        assertEquals(false, lost.won)
        assertFalse(won.draw)
        assertEquals(won.myScore, lost.opponentScore)
        assertEquals(won.opponentScore, lost.myScore)
        assertEquals(won.myPoints, lost.opponentPoints)
        assertFalse(won.opponentLeft)
    }
}
