package app.rork.sophia.data.analytics

import android.content.Context
import app.rork.sophia.BuildConfig
import app.rork.sophia.data.AuthService
import app.rork.sophia.data.FeatureFlags
import app.rork.sophia.data.LanguageManager
import app.rork.sophia.data.SupabaseManager
import io.github.jan.supabase.exceptions.RestException
import io.github.jan.supabase.postgrest.from
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.UUID
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/**
 * Journal d'événements produit (docs/events.md). Mêmes noms et mêmes propriétés qu'iOS.
 *
 * Les événements sont mis en file sur le téléphone puis envoyés par lots dans
 * `course_events`, directement par PostgREST : la règle RLS n'accepte que les lignes de
 * l'utilisateur connecté, et un doublon (`event_id` déjà vu) est ignoré. La file survit à
 * un redémarrage (fichier dans `filesDir`) et au mode avion ; elle est envoyée toutes les
 * 30 secondes, dès 50 événements, et quand l'activité passe en arrière-plan.
 *
 * Rien ne part vers un SDK tiers : ce journal reste chez Sophia.
 */
object Analytics {
    /** Version de l'algorithme qui compose le fil, tant qu'il est calculé sur le téléphone. */
    const val ALGO_VERSION = "local-v1"

    /**
     * Les noms acceptés par la contrainte `course_events_name_check` (docs/events.md). Un nom
     * inconnu ferait refuser tout le lot par le serveur : il est écarté avant d'entrer dans
     * la file (et fait planter une version de debug, pour qu'on le voie).
     */
    val KNOWN_NAMES: Set<String> = setOf(
        "app_open", "onboarding_step",
        "card_impression", "card_skip", "card_open",
        "course_open", "section_view", "course_complete", "glossary_open", "funfact_open", "audio_play",
        "quiz_start", "quiz_answer", "quiz_complete",
        "like", "unlike", "save", "unsave", "share", "follow", "unfollow", "not_interested", "report",
        "paywall_view", "purchase_started", "purchase_completed", "purchase_failed",
    )

    private const val FLUSH_INTERVAL_MS = 30_000L
    private const val FLUSH_THRESHOLD = 50
    private const val BATCH_SIZE = 200
    private const val QUEUE_CAP = 5_000
    private const val SESSION_TIMEOUT_MS = 30 * 60 * 1_000L
    /** La règle RLS refuse un événement de plus de 30 jours : on n'essaie même pas. */
    private const val MAX_EVENT_AGE_MS = 29L * 24 * 3_600 * 1_000
    private const val PREFS = "sophia_prefs"
    private const val INSTALL_ID_KEY = "sophia_install_id"

    /** `free`, `trial`, `paid` ou `unknown` ; tenu à jour par `StoreViewModel`. */
    @Volatile var premiumStatus: String = "unknown"

    /** D'où le prochain cours va s'ouvrir. Posé par l'écran d'origine, lu par `MainTabs.openCourse`. */
    @Volatile var pendingCourseOpenSource: String? = null

    private var appContext: Context? = null
    private var auth: AuthService? = null
    private var languageManager: LanguageManager? = null
    private var scope: CoroutineScope? = null
    private var queueFile: File? = null
    private var installId: String = ""

    /** The install's identifier, read-only (empty before [init]): what `PaywallExperiment` draws from. */
    val installIdentifier: String get() = installId
    private var sessionId: String = UUID.randomUUID().toString()
    private var lastActiveAt = System.currentTimeMillis()
    private var headFailures = 0
    private var lastSnapshotKey: String? = null

    private val mutex = Mutex()
    private val queue = ArrayList<CourseEventRow>()
    @Volatile private var queueDirty = false
    @Volatile private var flushing = false

    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true; explicitNulls = false }
    private val iso = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
        timeZone = TimeZone.getTimeZone("UTC")
    }

    @Serializable
    data class CourseEventRow(
        val event_id: String,
        /** Vide tant que l'utilisateur n'est pas connecté ; rempli au premier envoi. */
        var user_id: String? = null,
        val install_id: String,
        val session_id: String,
        val name: String,
        val course_id: String? = null,
        val lang: String,
        val country: String? = null,
        val platform: String = "android",
        val app_version: String,
        val premium_status: String,
        val screen: String? = null,
        val position: Int? = null,
        val algo_version: String? = null,
        val props: JsonObject,
        /** ISO 8601 avec millisecondes, UTC. */
        val ts: String,
    )

    @Serializable
    data class SubscriberSnapshotRow(
        val user_id: String,
        val is_active: Boolean,
        val period_type: String? = null,
        val product_id: String? = null,
        val store: String? = null,
        val expires_at: String? = null,
        val will_renew: Boolean? = null,
        val platform: String = "android",
        val app_version: String,
        val reported_at: String,
    )

    fun init(context: Context, auth: AuthService, languageManager: LanguageManager, scope: CoroutineScope) {
        this.appContext = context.applicationContext
        this.auth = auth
        this.languageManager = languageManager
        this.scope = scope
        queueFile = File(context.filesDir, "analytics_queue.json")
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        installId = prefs.getString(INSTALL_ID_KEY, null) ?: UUID.randomUUID().toString().also {
            prefs.edit().putString(INSTALL_ID_KEY, it).apply()
        }
        scope.launch(Dispatchers.IO) {
            loadQueue()
            while (isActive) {
                delay(FLUSH_INTERVAL_MS)
                flush()
            }
        }
    }

    // ---------- Enregistrer ----------

    fun log(
        name: String,
        courseId: String? = null,
        screen: String? = null,
        position: Int? = null,
        algoVersion: String? = null,
        props: Map<String, Any?> = emptyMap(),
    ) {
        val scope = scope ?: return
        if (name !in KNOWN_NAMES) {
            check(!BuildConfig.DEBUG) { "Événement inconnu : $name (voir docs/events.md)" }
            return
        }
        val row = CourseEventRow(
            event_id = UUID.randomUUID().toString(),
            user_id = auth?.userId?.value,
            install_id = installId,
            session_id = sessionId,
            name = name,
            course_id = courseId,
            lang = languageManager?.current?.value?.code ?: "fr",
            country = Locale.getDefault().country.takeIf { it.length == 2 },
            app_version = BuildConfig.VERSION_NAME,
            premium_status = premiumStatus,
            screen = screen,
            position = position,
            algo_version = algoVersion,
            props = JsonObject(
                props.filterValues { it != null }.mapValues { (_, value) ->
                    when (value) {
                        is Boolean -> JsonPrimitive(value)
                        is Number -> JsonPrimitive(value)
                        else -> JsonPrimitive(value.toString())
                    }
                },
            ),
            ts = iso.format(Date()),
        )
        scope.launch(Dispatchers.IO) {
            val size = mutex.withLock {
                queue.add(row)
                while (queue.size > QUEUE_CAP) queue.removeAt(0)
                queueDirty = true
                queue.size
            }
            if (size >= FLUSH_THRESHOLD) flush()
        }
    }

    /** Lit et efface la source posée par l'écran d'origine. */
    fun takeCourseOpenSource(): String {
        val source = pendingCourseOpenSource ?: "unknown"
        pendingCourseOpenSource = null
        return source
    }

    // ---------- Cycle de vie ----------

    /** Passage au premier plan : nouvelle session après 30 minutes d'absence, et `app_open`. */
    fun appDidStart() {
        val now = System.currentTimeMillis()
        if (now - lastActiveAt > SESSION_TIMEOUT_MS) sessionId = UUID.randomUUID().toString()
        lastActiveAt = now
        val source = when (pendingCourseOpenSource) {
            "notification" -> "notification"
            "link" -> "link"
            else -> "direct"
        }
        // La variante de navigation : « newgen » pour tous depuis la fin du tirage 50/50.
        val nav = FeatureFlags.navigationVariant.raw
        log("app_open", props = mapOf("source" to source, "nav" to nav))
    }

    /** Passage en arrière-plan : la file part tout de suite. */
    fun appDidStop() {
        lastActiveAt = System.currentTimeMillis()
        scope?.launch(Dispatchers.IO) {
            persistQueue()
            flush()
        }
    }

    // ---------- Abonnement ----------

    /**
     * Statut d'abonnement tel que RevenueCat le donne au client, pour `subscriber_snapshots`.
     * Envoyé une fois par valeur distincte et par lancement.
     */
    fun reportSubscription(
        isActive: Boolean,
        periodType: String?,
        productId: String?,
        store: String?,
        expiresAt: Date?,
        willRenew: Boolean?,
    ) {
        val userId = auth?.userId?.value ?: return
        val scope = scope ?: return
        val key = listOf(userId, isActive, periodType, productId, expiresAt?.time, willRenew).joinToString("|")
        if (key == lastSnapshotKey) return
        lastSnapshotKey = key
        val row = SubscriberSnapshotRow(
            user_id = userId,
            is_active = isActive,
            period_type = periodType,
            product_id = productId,
            store = store,
            expires_at = expiresAt?.let { iso.format(it) },
            will_renew = willRenew,
            app_version = BuildConfig.VERSION_NAME,
            reported_at = iso.format(Date()),
        )
        scope.launch(Dispatchers.IO) {
            runCatching {
                SupabaseManager.client.from("subscriber_snapshots").upsert(row) { onConflict = "user_id" }
            }.onFailure {
                // Réessayé à la prochaine mise à jour de CustomerInfo.
                lastSnapshotKey = null
            }
        }
    }

    // ---------- Envoi ----------

    suspend fun flush() {
        if (flushing) return
        val userId = auth?.userId?.value
        if (userId == null) {
            persistIfNeeded()
            return
        }
        flushing = true
        try {
            val now = System.currentTimeMillis()
            mutex.withLock {
                queue.forEach { if (it.user_id == null) it.user_id = userId }
                // Un autre compte, ou un événement trop vieux pour la règle RLS : abandonné.
                queue.removeAll { row ->
                    row.user_id != userId || runCatching { now - iso.parse(row.ts)!!.time > MAX_EVENT_AGE_MS }.getOrDefault(true)
                }
            }
            while (true) {
                val batch = mutex.withLock { queue.take(BATCH_SIZE) }
                if (batch.isEmpty()) break
                val sent = try {
                    SupabaseManager.client.from("course_events").upsert(batch) {
                        onConflict = "ts,event_id"
                        ignoreDuplicates = true
                    }
                    true
                } catch (e: RestException) {
                    // Refus du serveur (ligne invalide) : au bout de trois fois, le lot est
                    // abandonné plutôt que de bloquer tout le journal derrière lui.
                    headFailures += 1
                    if (headFailures >= 3) {
                        headFailures = 0
                        mutex.withLock { repeat(minOf(batch.size, queue.size)) { queue.removeAt(0) }; queueDirty = true }
                        continue
                    }
                    false
                } catch (_: Exception) {
                    // Réseau : on garde tout et on réessaie plus tard.
                    false
                }
                if (!sent) break
                headFailures = 0
                mutex.withLock {
                    repeat(minOf(batch.size, queue.size)) { queue.removeAt(0) }
                    queueDirty = true
                }
            }
            persistIfNeeded()
        } finally {
            flushing = false
        }
    }

    // ---------- Persistance ----------

    private suspend fun persistIfNeeded() {
        if (queueDirty) persistQueue()
    }

    private suspend fun persistQueue() {
        val file = queueFile ?: return
        val snapshot = mutex.withLock { queueDirty = false; queue.toList() }
        withContext(Dispatchers.IO) {
            runCatching {
                val tmp = File(file.parentFile, file.name + ".tmp")
                tmp.writeText(json.encodeToString(ListSerializer(CourseEventRow.serializer()), snapshot))
                tmp.renameTo(file)
            }
        }
    }

    private suspend fun loadQueue() {
        val file = queueFile ?: return
        if (!file.exists()) return
        val rows = runCatching {
            json.decodeFromString(ListSerializer(CourseEventRow.serializer()), file.readText())
        }.getOrDefault(emptyList())
        mutex.withLock { queue.addAll(0, rows) }
    }
}
