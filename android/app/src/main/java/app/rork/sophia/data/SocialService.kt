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

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    private val db get() = SupabaseManager.client.postgrest

    fun setPeriod(period: FriendsLeaderboardPeriod) {
        _period.value = period
    }

    fun clearLocalState() {
        _myHandle.value = null
        _pending.value = emptyList()
        _leaderboard.value = emptyList()
        _error.value = null
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
        }.onFailure { _error.value = it.message }
    }

    suspend fun updateHandle(raw: String): Result<String> {
        @Serializable
        data class Params(val new_handle: String)
        val handle = sanitizeHandle(raw)
        return runCatching {
            val updated = db.rpc("update_my_handle", Params(new_handle = handle)).decodeAs<String>()
            _myHandle.value = updated
            updated
        }.onFailure { _error.value = mapSocialError(it.message) }
    }

    suspend fun sendFriendRequest(rawHandle: String): Result<String> {
        @Serializable
        data class Params(val target_handle: String)
        val handle = sanitizeHandle(rawHandle)
        return runCatching {
            val outcome = db.rpc("send_friend_request", Params(target_handle = handle)).decodeAs<String>()
            refreshPendingRequests()
            refreshLeaderboard()
            outcome
        }.onFailure { _error.value = mapSocialError(it.message) }
    }

    suspend fun respondToRequest(requestId: String, accept: Boolean): Result<Unit> {
        @Serializable
        data class Params(val request_id: String, val accept: Boolean)
        return runCatching {
            db.rpc("respond_friend_request", Params(request_id = requestId, accept = accept))
            refreshPendingRequests()
            refreshLeaderboard()
        }.onFailure { _error.value = mapSocialError(it.message) }
    }

    suspend fun refreshPendingRequests() {
        runCatching {
            _pending.value = db.rpc("pending_friend_requests").decodeList()
        }.onFailure { _error.value = mapSocialError(it.message) }
    }

    suspend fun removeFriend(userId: String): Result<Unit> {
        @Serializable
        data class Params(val friend: String)
        return runCatching {
            db.rpc("remove_friend", Params(friend = userId))
            refreshLeaderboard()
        }.onFailure { _error.value = mapSocialError(it.message) }
    }

    suspend fun refreshLeaderboard() {
        @Serializable
        data class Params(val period: String)
        val period = _period.value.rpcValue
        runCatching {
            _leaderboard.value = db.rpc("friends_leaderboard", Params(period = period)).decodeList()
        }.onFailure { _error.value = mapSocialError(it.message) }
    }

    suspend fun friendStats(userId: String): FriendPublicStats? {
        @Serializable
        data class Params(val target: String)
        return runCatching {
            db.rpc("friend_public_stats", Params(target = userId)).decodeList<FriendPublicStats>().firstOrNull()
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
        fun sanitizeHandle(raw: String): String =
            raw.trim().removePrefix("@").lowercase()

        fun mapSocialError(message: String?): String {
            val m = message.orEmpty()
            return when {
                "invalid_handle" in m -> "Pseudo invalide"
                "handle_taken" in m -> "Pseudo déjà pris"
                "user_not_found" in m -> "Utilisateur introuvable"
                "cannot_add_self" in m -> "Tu ne peux pas t'ajouter"
                "already_friends" in m -> "Déjà amis"
                "request_already_sent" in m -> "Demande déjà envoyée"
                "request_not_found" in m -> "Demande introuvable"
                "not_friends" in m -> "Pas amis"
                "not_authenticated" in m -> "Connecte-toi d'abord"
                else -> message ?: "Erreur sociale"
            }
        }
    }
}
