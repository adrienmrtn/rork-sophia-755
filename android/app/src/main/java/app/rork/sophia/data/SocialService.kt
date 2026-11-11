package app.rork.sophia.data

import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.rpc
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.Serializable

@Serializable
data class FriendLeaderboardEntry(
    val user_id: String,
    val handle: String,
    val xp: Int = 0,
    val is_me: Boolean = false,
)

@Serializable
data class FriendRequest(
    val request_id: String,
    val user_id: String,
    val handle: String,
)

@Serializable
data class FriendPublicStats(
    val user_id: String,
    val handle: String,
    val global_xp: Int = 0,
    val streak: Int = 0,
    val courses_completed: Int = 0,
    val quizzes_completed: Int = 0,
)

/** La présence d'un ami, lue sur `friend_profile` : en ligne, ou vu il y a tant de secondes. */
@Serializable
data class FriendPresence(
    val online: Boolean = false,
    val last_seen_seconds: Int? = null,
    /** Ses trophées de duel et le rang de sa ligue ; null sur une base sans duels. */
    val trophies: Int? = null,
    val league_position: Int? = null,
    /** Les badges qu'il affiche sur son profil (trois au plus). */
    val featured_badges: List<String> = emptyList(),
)

/** Un lien d'ami (`sophia://friend/<handle>`) reçu par l'app, en attente de confirmation. */
object FriendLinkRouter {
    private val _pendingHandle = MutableStateFlow<String?>(null)
    val pendingHandle: StateFlow<String?> = _pendingHandle.asStateFlow()

    fun open(handle: String) {
        _pendingHandle.value = handle
    }

    fun consume() {
        _pendingHandle.value = null
    }
}

enum class FriendsLeaderboardPeriod(val rpcValue: String) {
    WEEK("week"),
    ALL("all"),
}

class SocialService(private val auth: AuthService) {
    private val _myHandle = MutableStateFlow<String?>(null)
    val myHandle: StateFlow<String?> = _myHandle.asStateFlow()

    private val _pending = MutableStateFlow<List<FriendRequest>>(emptyList())
    val pendingRequests: StateFlow<List<FriendRequest>> = _pending.asStateFlow()

    private val _leaderboard = MutableStateFlow<List<FriendLeaderboardEntry>>(emptyList())
    val leaderboard: StateFlow<List<FriendLeaderboardEntry>> = _leaderboard.asStateFlow()

    private val _period = MutableStateFlow(FriendsLeaderboardPeriod.WEEK)
    val period: StateFlow<FriendsLeaderboardPeriod> = _period.asStateFlow()

    /** StringStore key, so the message follows the app language instead of being baked in French. */
    private val _errorKey = MutableStateFlow<String?>(null)
    val errorKey: StateFlow<String?> = _errorKey.asStateFlow()

    private val db get() = SupabaseManager.client.postgrest

    fun setPeriod(period: FriendsLeaderboardPeriod) {
        _period.value = period
    }

    fun clearError() {
        _errorKey.value = null
    }

    fun clearLocalState() {
        _myHandle.value = null
        _pending.value = emptyList()
        _leaderboard.value = emptyList()
        _errorKey.value = null
    }

    suspend fun refreshAll() {
        if (!auth.isSignedIn) return
        refreshMyHandle()
        refreshPendingRequests()
        refreshLeaderboard()
    }

    suspend fun refreshMyHandle() {
        val userId = auth.userId.value ?: return
        runCatching {
            @Serializable
            data class Row(val handle: String? = null)
            val row = SupabaseManager.client.from("profiles")
                .select { filter { eq("id", userId) } }
                .decodeSingleOrNull<Row>()
            _myHandle.value = row?.handle
        }.onFailure { _errorKey.value = errorKeyFor(it.message) }
    }

    suspend fun updateHandle(raw: String): Result<String> {
        @Serializable
        data class Params(val new_handle: String)
        val handle = sanitizeHandle(raw)
        _errorKey.value = null
        return runCatching {
            val updated = db.rpc("update_my_handle", Params(new_handle = handle)).decodeAs<String>()
            _myHandle.value = updated
            updated
        }.onFailure { _errorKey.value = errorKeyFor(it.message) }
    }

    /** @return [SendRequestOutcome] so the UI can tell "request sent" from "you are now friends". */
    suspend fun sendFriendRequest(rawHandle: String): Result<SendRequestOutcome> {
        @Serializable
        data class Params(val target_handle: String)
        val handle = sanitizeHandle(rawHandle)
        _errorKey.value = null
        if (handle.isEmpty()) {
            _errorKey.value = "friends.error.invalidHandle"
            return Result.failure(IllegalArgumentException("invalid_handle"))
        }
        return runCatching {
            val outcome = db.rpc("send_friend_request", Params(target_handle = handle)).decodeAs<String>()
            refreshPendingRequests()
            refreshLeaderboard()
            if (outcome == "accepted") SendRequestOutcome.AUTO_ACCEPTED else SendRequestOutcome.SENT
        }.onFailure { _errorKey.value = errorKeyFor(it.message) }
    }

    suspend fun respondToRequest(requestId: String, accept: Boolean): Result<Unit> {
        @Serializable
        data class Params(val request_id: String, val accept: Boolean)
        _errorKey.value = null
        return runCatching {
            db.rpc("respond_friend_request", Params(request_id = requestId, accept = accept))
            refreshPendingRequests()
            refreshLeaderboard()
        }.onFailure { _errorKey.value = errorKeyFor(it.message) }
    }

    suspend fun refreshPendingRequests() {
        runCatching {
            _pending.value = db.rpc("pending_friend_requests").decodeList()
        }.onFailure { _errorKey.value = errorKeyFor(it.message) }
    }

    suspend fun removeFriend(userId: String): Result<Unit> {
        @Serializable
        data class Params(val friend: String)
        _errorKey.value = null
        return runCatching {
            db.rpc("remove_friend", Params(friend = userId))
            refreshLeaderboard()
        }.onFailure { _errorKey.value = errorKeyFor(it.message) }
    }

    /**
     * Two taps between "week" and "all" issue two requests, and the network decides which
     * lands last. Publishing a response whose period is no longer the selected one showed
     * week totals under the "all" chip, so a late reply for a period nobody is looking at is
     * dropped rather than displayed.
     */
    /** Appelé avec le nombre d'amis à chaque lecture réussie du classement. */
    var onFriendsCounted: ((Int) -> Unit)? = null

    suspend fun refreshLeaderboard() {
        @Serializable
        data class Params(val period: String)
        val requested = _period.value
        runCatching {
            val rows: List<FriendLeaderboardEntry> =
                db.rpc("friends_leaderboard", Params(period = requested.rpcValue)).decodeList()
            if (_period.value == requested) _leaderboard.value = rows
            // Le nombre d'amis (moi exclu) compte pour un badge.
            onFriendsCounted?.invoke(rows.count { !it.is_me })
        }.onFailure {
            if (_period.value == requested) _errorKey.value = errorKeyFor(it.message)
        }
    }

    suspend fun friendStats(userId: String): FriendPublicStats? {
        @Serializable
        data class Params(val target: String)
        return runCatching {
            db.rpc("friend_public_stats", Params(target = userId)).decodeList<FriendPublicStats>().firstOrNull()
        }.getOrNull()
    }

    /** En ligne / vu il y a… : null quand le serveur ne sait pas (ancienne base, hors ligne). */
    suspend fun friendPresence(userId: String): FriendPresence? {
        @Serializable
        data class Params(val target: String)
        return runCatching {
            // Lu champ par champ : la réponse porte bien d'autres clés que ces deux-là.
            val row = db.rpc("friend_profile", Params(target = userId)).decodeAs<kotlinx.serialization.json.JsonObject>()
            FriendPresence(
                online = (row["online"] as? kotlinx.serialization.json.JsonPrimitive)?.content == "true",
                last_seen_seconds = (row["last_seen_seconds"] as? kotlinx.serialization.json.JsonPrimitive)?.content?.toIntOrNull(),
                trophies = (row["trophies"] as? kotlinx.serialization.json.JsonPrimitive)?.content?.toIntOrNull(),
                league_position = (row["league_position"] as? kotlinx.serialization.json.JsonPrimitive)?.content?.toIntOrNull(),
                featured_badges = (row["featured_badges"] as? kotlinx.serialization.json.JsonArray)
                    ?.mapNotNull { (it as? kotlinx.serialization.json.JsonPrimitive)?.content }.orEmpty(),
            )
        }.getOrNull()
    }

    suspend fun logXPEvent(amount: Int, reason: String?) {
        if (!auth.isSignedIn || amount <= 0) return
        @Serializable
        data class Params(val amount: Int, val reason: String? = null)
        runCatching {
            db.rpc("log_xp_event", Params(amount = amount, reason = reason))
        }
    }

    companion object {
        // Locale.ROOT, not the device locale: on a Turkish phone `lowercase()` turns "I"
        // into a dotless "ı", which is not a handle anyone can be found by.
        fun sanitizeHandle(raw: String): String =
            raw.trim().removePrefix("@").lowercase(java.util.Locale.ROOT)

        /** Postgres raises bare codes; turn them into StringStore keys. */
        fun errorKeyFor(message: String?): String {
            val m = message.orEmpty()
            return when {
                "invalid_handle" in m -> "friends.error.invalidHandle"
                "handle_taken" in m -> "friends.error.handleTaken"
                "user_not_found" in m -> "friends.error.userNotFound"
                "cannot_add_self" in m -> "friends.error.cannotAddSelf"
                "already_friends" in m -> "friends.error.alreadyFriends"
                "request_already_sent" in m -> "friends.error.requestAlreadySent"
                "request_not_found" in m -> "friends.error.requestNotFound"
                "not_friends" in m -> "friends.error.notFriends"
                "not_authenticated" in m -> "friends.error.notSignedIn"
                else -> "friends.error.generic"
            }
        }
    }
}

enum class SendRequestOutcome { SENT, AUTO_ACCEPTED }
