package app.rork.sophia.data

import app.rork.sophia.domain.UserProgress
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

class ProgressSyncService(
    private val auth: AuthService,
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var pushJob: Job? = null
    private var progressManager: ProgressManager? = null

    data class ProgressConflict(val local: UserProgress, val remote: UserProgress)

    private val _conflict = MutableStateFlow<ProgressConflict?>(null)
    val conflict: StateFlow<ProgressConflict?> = _conflict.asStateFlow()

    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    fun attach(manager: ProgressManager) {
        progressManager = manager
        manager.onProgressChanged = { schedulePush(it) }
    }

    fun schedulePush(progress: UserProgress) {
        if (!auth.isSignedIn) return
        pushJob?.cancel()
        pushJob = scope.launch {
            delay(2_500)
            push(progress)
        }
    }

    suspend fun pushNow(progress: UserProgress) {
        if (!auth.isSignedIn) return
        push(progress)
    }

    private suspend fun push(progress: UserProgress) {
        val userId = auth.userId.value ?: return
        runCatching {
            SupabaseManager.client.from("user_progress").upsert(
                UpsertProgressRow(user_id = userId, progress = progress),
            )
        }
    }

    suspend fun pullOnLogin(local: UserProgress) {
        val userId = auth.userId.value ?: return
        val remote = runCatching {
            SupabaseManager.client.from("user_progress")
                .select {
                    filter { eq("user_id", userId) }
                }
                .decodeSingleOrNull<RemoteProgressRow>()
                ?.progress
        }.getOrNull()

        when {
            remote == null || isEmpty(remote) -> push(local)
            isEmpty(local) -> progressManager?.replaceAll(remote)
            syncSignal(local) != syncSignal(remote) ->
                _conflict.value = ProgressConflict(local, remote)
            else -> Unit
        }
    }

    fun resolveKeepLocal() {
        val c = _conflict.value ?: return
        scope.launch { push(c.local) }
        _conflict.value = null
    }

    fun resolveKeepRemote() {
        val c = _conflict.value ?: return
        progressManager?.replaceAll(c.remote)
        _conflict.value = null
    }

    private fun isEmpty(p: UserProgress): Boolean =
        p.courseProgress.isEmpty() && p.globalXP == 0 && p.favoriteCourseIds.isEmpty()

    private fun syncSignal(p: UserProgress): Int =
        p.globalXP + p.courseProgress.size * 3 + p.completedQuizCourseIds.size * 5 + p.streak

    @Serializable
    private data class UpsertProgressRow(
        val user_id: String,
        val progress: UserProgress,
    )

    @Serializable
    private data class RemoteProgressRow(
        val user_id: String,
        val progress: UserProgress,
    )
}
