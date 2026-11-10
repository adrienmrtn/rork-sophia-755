package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.domain.DuelAnswer
import app.rork.sophia.domain.DuelHome
import app.rork.sophia.domain.DuelLeaderboardEntry
import app.rork.sophia.domain.DuelMatch
import app.rork.sophia.domain.DuelResult
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.rpc
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withTimeout
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.encodeToJsonElement
import kotlinx.serialization.json.put

/** Pourquoi une partie n'a pas pu être lancée ou enregistrée. */
sealed class DuelError(message: String) : Exception(message) {
    object NotSignedIn : DuelError("not_authenticated")

    /** Pas d'adversaire ou pas assez de questions : rien à faire côté joueur, sinon réessayer. */
    object Unavailable : DuelError("unavailable")

    class Underlying(message: String) : DuelError(message)

    companion object {
        fun from(error: Throwable): DuelError {
            if (error is DuelError) return error
            val message = (error.message ?: error.toString()).lowercase(java.util.Locale.ROOT)
            return when {
                "not_authenticated" in message -> NotSignedIn
                "not_enough_questions" in message || "no_opponent" in message -> Unavailable
                else -> Underlying(error.message ?: error.toString())
            }
        }
    }
}

/**
 * Les duels classés via Supabase : l'accueil (profil, ligues, dernières parties), le classement
 * des amis, le lancement et la fin d'une partie. Tout le calcul (adversaire, questions, score,
 * trophées) est fait par le serveur ; l'app ne garde que ce qu'il renvoie.
 *
 * Même rôle que `ios/Sophia/Services/DuelService.swift` : mêmes fonctions, mêmes paramètres,
 * même gestion de la fin de partie restée sans réponse du serveur (elle est gardée et renvoyée).
 */
class DuelService(context: Context, private val auth: AuthService) {
    private val prefs = context.applicationContext.getSharedPreferences("sophia_prefs", Context.MODE_PRIVATE)
    private val json = Json { ignoreUnknownKeys = true; explicitNulls = false; coerceInputValues = true }
    private val db get() = SupabaseManager.client.postgrest
    private val pendingLock = Mutex()

    private val _home = MutableStateFlow<DuelHome?>(null)
    /** L'accueil des duels ; d'abord celui gardé en cache pour ce compte, puis celui du serveur. */
    val home: StateFlow<DuelHome?> = _home.asStateFlow()

    private val _homeFailed = MutableStateFlow(false)
    /** Le chargement a échoué et rien n'est en cache : l'écran propose de réessayer. */
    val homeFailed: StateFlow<Boolean> = _homeFailed.asStateFlow()

    private val _leaderboard = MutableStateFlow<List<DuelLeaderboardEntry>>(emptyList())
    val leaderboard: StateFlow<List<DuelLeaderboardEntry>> = _leaderboard.asStateFlow()

    private val _isPlaying = MutableStateFlow(false)
    /** Une partie classée est à l'écran (de la recherche d'adversaire au résultat). */
    val isPlaying: StateFlow<Boolean> = _isPlaying.asStateFlow()

    fun setPlaying(playing: Boolean) {
        _isPlaying.value = playing
    }

    // ---------------------------------------------------------------- accueil

    /** Recharge l'accueil. Le cache de ce compte est montré tout de suite s'il existe. */
    suspend fun refreshHome() {
        val userId = auth.userId.value ?: return
        if (_home.value == null) {
            cachedHome(userId)?.let { _home.value = it }
        }
        // Une fin de partie restée sans réponse part d'abord, sauf pendant une partie.
        if (!_isPlaying.value) flushPendingFinish()
        runCatching {
            val fresh: DuelHome = json.decodeFromString(db.rpc("duel_home").data)
            if (auth.userId.value == userId) {
                _home.value = fresh
                _homeFailed.value = false
                storeHome(userId, fresh)
            }
        }.onFailure {
            if (auth.userId.value == userId) _homeFailed.value = _home.value == null
        }
    }

    suspend fun refreshLeaderboard() {
        if (auth.userId.value == null) return
        runCatching {
            val rows: List<DuelLeaderboardEntry> = json.decodeFromString(db.rpc("duel_friends_leaderboard").data)
            _leaderboard.value = rows
        }
    }

    /** À la déconnexion : plus rien de l'ancien compte à l'écran ni en cache. */
    fun clearLocalState() {
        _home.value = null
        _homeFailed.value = false
        _leaderboard.value = emptyList()
        prefs.edit().remove(HOME_CACHE_KEY).apply()
    }

    // ---------------------------------------------------------------- partie

    /**
     * Lance une partie : le serveur tire l'adversaire et les quatre manches. La partie est
     * aussitôt notée « abandonnée » en attente : si l'app meurt en cours de route, c'est ce
     * que le serveur recevra au prochain lancement.
     */
    suspend fun startMatch(): Result<DuelMatch> {
        val userId = auth.userId.value ?: return Result.failure(DuelError.NotSignedIn)
        flushPendingFinish()
        return try {
            val match: DuelMatch = withTimeout(START_TIMEOUT_MS) {
                val data = try {
                    db.rpc("duel_start_match_v2", buildJsonObject { put("p_can_forfeit", true) }).data
                } catch (error: Throwable) {
                    // Serveur sans le paramètre (fonction plus ancienne) : le même appel, sans lui.
                    val text = "$error ${error.message}".lowercase(java.util.Locale.ROOT)
                    if ("pgrst202" in text || "could not find the function" in text) {
                        db.rpc("duel_start_match_v2").data
                    } else {
                        throw error
                    }
                }
                json.decodeFromString(data)
            }
            storePending(PendingFinish(userId, match.matchId, emptyList(), abandoned = true, pick = null))
            Result.success(match)
        } catch (error: TimeoutCancellationException) {
            Result.failure(DuelError.Underlying("timeout"))
        } catch (error: Throwable) {
            Result.failure(DuelError.from(error))
        }
    }

    /**
     * Envoie la fin d'une partie et renvoie son résultat (score, trophées, ligue). `answers` suit
     * l'ordre de jeu : une entrée par question posée, puis la question décisive s'il y en a eu
     * une. `pick` est la matière que j'ai choisie pour la manche 2.
     *
     * En cas d'échec, la fin de partie reste en attente et repartira au prochain chargement de
     * l'accueil ou au prochain lancement.
     */
    suspend fun finishMatch(
        matchId: String,
        answers: List<DuelAnswer>,
        abandoned: Boolean,
        pick: String?,
    ): Result<DuelResult> {
        val userId = auth.userId.value ?: return Result.failure(DuelError.NotSignedIn)
        val pending = PendingFinish(userId, matchId, answers, abandoned, pick)
        storePending(pending)
        return runCatching { send(pending) }
            .onSuccess { result ->
                clearPending(matchId)
                apply(result)
            }
            .recoverCatching { throw DuelError.from(it) }
    }

    /** Renvoie une fin de partie restée en attente (réseau coupé, app fermée en pleine partie). */
    suspend fun flushPendingFinish() {
        pendingLock.withLock {
            val pending = loadPending() ?: return
            val userId = auth.userId.value ?: return
            if (pending.userId != userId) {
                prefs.edit().remove(PENDING_KEY).apply()
                return
            }
            runCatching { send(pending) }
                .onSuccess { result ->
                    clearPending(pending.matchId)
                    apply(result)
                }
                .onFailure { error ->
                    // La partie n'existe plus côté serveur : rien à renvoyer.
                    if ("match_not_found" in (error.message ?: "").lowercase(java.util.Locale.ROOT)) {
                        clearPending(pending.matchId)
                    }
                }
        }
    }

    private suspend fun send(pending: PendingFinish): DuelResult {
        val params = buildJsonObject {
            put("p_match_id", pending.matchId)
            put("p_answers", json.encodeToJsonElement(pending.answers))
            put("p_abandoned", pending.abandoned)
            pending.pick?.let { put("p_pick", it) }
        }
        return json.decodeFromString(db.rpc("duel_finish_match_v2", params).data)
    }

    /** Le profil renvoyé avec un résultat remplace celui de l'accueil (trophées, ligue, statistiques). */
    private fun apply(result: DuelResult) {
        val current = _home.value ?: return
        val updated = current.copy(profile = result.profile)
        _home.value = updated
        auth.userId.value?.let { storeHome(it, updated) }
    }

    // ---------------------------------------------------------------- stockage local

    @Serializable
    private data class PendingFinish(
        val userId: String,
        val matchId: String,
        val answers: List<DuelAnswer>,
        val abandoned: Boolean,
        val pick: String? = null,
    )

    @Serializable
    private data class CachedHome(val userId: String, val home: DuelHome)

    private fun storePending(pending: PendingFinish) {
        prefs.edit().putString(PENDING_KEY, json.encodeToString(PendingFinish.serializer(), pending)).apply()
    }

    private fun loadPending(): PendingFinish? =
        prefs.getString(PENDING_KEY, null)?.let { raw ->
            runCatching { json.decodeFromString(PendingFinish.serializer(), raw) }.getOrNull()
        }

    /** N'efface l'attente que si elle porte encore sur cette partie (une autre a pu commencer). */
    private fun clearPending(matchId: String) {
        if (loadPending()?.matchId == matchId) prefs.edit().remove(PENDING_KEY).apply()
    }

    private fun storeHome(userId: String, home: DuelHome) {
        prefs.edit().putString(HOME_CACHE_KEY, json.encodeToString(CachedHome.serializer(), CachedHome(userId, home))).apply()
    }

    private fun cachedHome(userId: String): DuelHome? =
        prefs.getString(HOME_CACHE_KEY, null)?.let { raw ->
            runCatching { json.decodeFromString(CachedHome.serializer(), raw) }.getOrNull()
        }?.takeIf { it.userId == userId }?.home

    companion object {
        private const val PENDING_KEY = "sophia_duel_pending_finish"
        private const val HOME_CACHE_KEY = "sophia_duel_home_cache"
        private const val START_TIMEOUT_MS = 12_000L
    }
}
