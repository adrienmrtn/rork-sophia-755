package app.rork.sophia.data

import app.rork.sophia.domain.DuelAnswer
import app.rork.sophia.domain.DuelFriendStart
import app.rork.sophia.domain.DuelFriendState
import app.rork.sophia.domain.DuelIncomingInvite
import app.rork.sophia.domain.DuelInviteOutcome
import app.rork.sophia.domain.DuelPingResponse
import app.rork.sophia.domain.DuelSentInvite
import io.github.jan.supabase.postgrest.postgrest
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.encodeToJsonElement
import kotlinx.serialization.json.put

/** Pourquoi un défi n'a pas pu partir. */
sealed class DuelInviteError(message: String) : Exception(message) {
    object NotSignedIn : DuelInviteError("not_authenticated")
    object NotFriends : DuelInviteError("not_friends")

    /** L'ami n'a pas les duels (app dans une autre langue, ou pas à jour). */
    object FriendUnavailable : DuelInviteError("friend_unavailable")

    /** L'ami est en pleine partie, ou déjà devant une autre invitation. */
    object FriendBusy : DuelInviteError("friend_busy")

    class Underlying(message: String) : DuelInviteError(message)

    companion object {
        fun from(error: Throwable): DuelInviteError {
            if (error is DuelInviteError) return error
            val message = "$error ${error.message}".lowercase(java.util.Locale.ROOT)
            return when {
                "not_authenticated" in message -> NotSignedIn
                "not_friends" in message -> NotFriends
                "friend_unavailable" in message -> FriendUnavailable
                "friend_busy" in message -> FriendBusy
                else -> Underlying(error.message ?: error.toString())
            }
        }
    }
}

/**
 * Les duels entre amis via Supabase : la présence (pastille verte), les invitations et la partie
 * en direct. Même rôle que `ios/Sophia/Services/DuelLiveService.swift`.
 *
 * L'app n'a pas de notifications push : tant qu'elle est ouverte, elle se signale au serveur
 * toutes les quatre secondes (`duel_ping`), ce qui tient sa pastille verte chez ses amis, et
 * c'est la réponse à ce signal qui lui apporte une invitation ([incoming], montrée en bandeau
 * par-dessus l'écran en cours).
 */
class DuelLiveService(private val auth: AuthService, private val duels: DuelService) {
    private val json = Json { ignoreUnknownKeys = true; explicitNulls = false; coerceInputValues = true }
    private val db get() = SupabaseManager.client.postgrest
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    private val _incoming = MutableStateFlow<DuelIncomingInvite?>(null)

    /** L'invitation en attente de réponse. */
    val incoming: StateFlow<DuelIncomingInvite?> = _incoming.asStateFlow()

    /** L'instant (horloge murale, ms) où l'invitation reçue tombe. */
    @Volatile
    var incomingDeadlineMs: Long = 0L
        private set

    /** Une partie entre amis est à l'écran (invitation envoyée comprise). */
    @Volatile
    var isInFriendDuel: Boolean = false

    private var pingJob: Job? = null

    /** Une invitation à laquelle on vient de répondre : le prochain signal ne doit pas la rafficher. */
    private var answeredInviteId: String? = null

    // ---------------------------------------------------------------- présence

    /** À l'ouverture de l'app et à chaque retour au premier plan : commence à se signaler. */
    fun start() {
        if (pingJob != null) return
        pingJob = scope.launch {
            while (isActive) {
                ping()
                delay(PING_INTERVAL_MS)
            }
        }
    }

    /** L'app passe à l'arrière-plan : plus de signal, et la pastille verte s'éteint tout de suite. */
    fun stop() {
        val job = pingJob ?: return
        job.cancel()
        pingJob = null
        clearIncoming()
        if (auth.userId.value == null) return
        scope.launch { runCatching { db.rpc("duel_go_offline") } }
    }

    /** Un signal tout de suite, sans attendre le prochain tour : « je ne suis plus en partie ». */
    fun pingNow() {
        if (pingJob == null) return
        scope.launch { ping() }
    }

    private suspend fun ping() {
        if (auth.userId.value == null) {
            clearIncoming()
            return
        }
        val busy = isInFriendDuel || duels.isPlaying.value
        try {
            val response: DuelPingResponse = withTimeout(PING_TIMEOUT_MS) {
                val params = buildJsonObject {
                    put("p_lang", duels.appLanguageCode())
                    put("p_busy", busy)
                }
                json.decodeFromString(db.rpc("duel_ping", params).data)
            }
            apply(response.invite)
        } catch (cancelled: CancellationException) {
            // Un dépassement de délai n'arrête pas la boucle ; une vraie annulation, si.
            if (cancelled !is kotlinx.coroutines.TimeoutCancellationException) throw cancelled
        } catch (_: Throwable) {
            // Hors ligne, ou serveur sans les duels entre amis : on réessaie au prochain tour.
        }
        if (_incoming.value != null && System.currentTimeMillis() > incomingDeadlineMs) clearIncoming()
    }

    private fun apply(invite: DuelIncomingInvite?) {
        if (invite == null) {
            clearIncoming()
            return
        }
        if (invite.inviteId == answeredInviteId || invite.inviteId == _incoming.value?.inviteId) return
        val lifetime = maxOf(invite.expiresInMs, 0).toLong()
        incomingDeadlineMs = System.currentTimeMillis() + lifetime
        _incoming.value = invite
        // Le bandeau tombe à l'instant où l'invitation expire, sans attendre le prochain signal.
        scope.launch {
            delay(lifetime)
            if (_incoming.value?.inviteId == invite.inviteId) clearIncoming()
        }
    }

    private fun clearIncoming() {
        _incoming.value = null
    }

    // ---------------------------------------------------------------- invitations

    /** Défie un ami : il a 15 secondes pour répondre. */
    suspend fun invite(friendUserId: String): DuelSentInvite {
        if (auth.userId.value == null) throw DuelInviteError.NotSignedIn
        return try {
            json.decodeFromString(db.rpc("duel_invite_friend", buildJsonObject { put("p_friend", friendUserId) }).data)
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (error: Throwable) {
            throw DuelInviteError.from(error)
        }
    }

    suspend fun inviteStatus(inviteId: String): DuelInviteOutcome =
        json.decodeFromString(db.rpc("duel_invite_status", buildJsonObject { put("p_invite", inviteId) }).data)

    /** Mené à son terme même si l'écran qui l'a demandé se ferme : aucune invitation ne reste en plan. */
    fun cancelInvite(inviteId: String) {
        scope.launch { runCatching { db.rpc("duel_invite_cancel", buildJsonObject { put("p_invite", inviteId) }) } }
    }

    /** Répond à l'invitation reçue. Acceptée et encore valable : la partie à lancer. */
    suspend fun respond(invite: DuelIncomingInvite, accept: Boolean): DuelFriendStart? {
        answeredInviteId = invite.inviteId
        clearIncoming()
        return try {
            val params = buildJsonObject {
                put("p_invite", invite.inviteId)
                put("p_accept", accept)
            }
            val outcome: DuelInviteOutcome = json.decodeFromString(db.rpc("duel_invite_respond", params).data)
            if (outcome.status == "accepted") outcome.match else null
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (_: Throwable) {
            null
        }
    }

    /** Refuse sans attendre la réponse du serveur (le bandeau se ferme tout de suite). */
    fun decline(invite: DuelIncomingInvite) {
        scope.launch { respond(invite, accept = false) }
    }

    // ---------------------------------------------------------------- partie en direct

    suspend fun state(matchId: String): DuelFriendState =
        json.decodeFromString(db.rpc("duel_friend_state", buildJsonObject { put("p_match", matchId) }).data)

    suspend fun answer(matchId: String, index: Int, answer: DuelAnswer): DuelFriendState {
        val params = buildJsonObject {
            put("p_match", matchId)
            put("p_index", index)
            put("p_answer", json.encodeToJsonElement(answer))
        }
        return json.decodeFromString(db.rpc("duel_friend_answer", params).data)
    }

    /** Mon choix de matière pour une manche au choix. */
    suspend fun pick(matchId: String, round: Int, subject: String): DuelFriendState {
        val params = buildJsonObject {
            put("p_match", matchId)
            put("p_round", round)
            put("p_subject", subject)
        }
        return json.decodeFromString(db.rpc("duel_friend_pick", params).data)
    }

    /** Je quitte la partie : j'ai perdu, mon ami la finit seul. Mené à son terme hors de l'écran. */
    fun leave(matchId: String) {
        scope.launch { runCatching { db.rpc("duel_friend_leave", buildJsonObject { put("p_match", matchId) }) } }
    }

    companion object {
        private const val PING_INTERVAL_MS = 4_000L
        private const val PING_TIMEOUT_MS = 6_000L
    }
}
