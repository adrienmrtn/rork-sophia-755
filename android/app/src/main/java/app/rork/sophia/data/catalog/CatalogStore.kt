package app.rork.sophia.data.catalog

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import app.rork.sophia.AppConfig
import app.rork.sophia.BuildConfig
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.GlossaryEntry
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.LearningCollection
import app.rork.sophia.domain.QuizQuestion
import app.rork.sophia.domain.Subject
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.util.concurrent.ConcurrentHashMap

/**
 * Le catalogue de cours, en ligne : ce que l'app sait des cours d'une langue ([CatalogSnapshot]),
 * d'où ça vient, et comment ça se met à jour. Même logique que `CatalogStore.swift` sur iOS.
 *
 * Trois couches, dans l'ordre où elles sont consultées :
 * 1. la mémoire (un snapshot par langue, les paquets de cours déjà décodés) ;
 * 2. le cache disque `filesDir/catalog/<code>/` : le dernier manifeste, les trois fichiers de la
 *    langue (catalogue, quiz, glossaire), les hashes téléchargés et un paquet par cours ;
 * 3. le pack de départ embarqué (`assets/starter_pack/<code>/`) : le catalogue complet de la
 *    langue et les 40 premiers cours du Parcours, pour que l'app ait toujours quelque chose à
 *    montrer, même sans réseau et avant le premier rafraîchissement.
 *
 * Le manifeste (`catalog-manifest?lang=xx`) est relu au lancement et toutes les six heures
 * (`app_config.catalog.refresh_hours`) ; un fichier n'est téléchargé que si son hash a changé,
 * et un paquet de cours au moment où le lecteur en a besoin ([ensureContent]) ou en avance
 * ([prefetch]). Les API synchrones des anciens chargeurs (`ContentCatalog`, `GlossaryStore`,
 * `AuthorStore`…) lisent le snapshot : elles n'attendent jamais le réseau, seulement le disque.
 */
object CatalogStore {
    private const val TAG = "CatalogStore"
    private const val PREFS = "sophia_catalog"
    private const val KEY_CONFIG = "config"
    private const val BUCKET = "course-content"
    private const val PREFETCH_LIMIT = 8

    /** Deux rafraîchissements à moins de trente secondes d'écart : le second ne refait rien. */
    private const val DEDUPE_WINDOW_MS = 30_000L
    private val LANGUAGE_FILES = listOf("catalog", "quizzes", "glossary")

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        coerceInputValues = true
    }
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val refreshMutex = Mutex()

    @Volatile
    private var attached: Context? = null

    private val snapshots = ConcurrentHashMap<String, CatalogSnapshot>()
    private val manifests = ConcurrentHashMap<String, CatalogManifest>()
    private val bundles = ConcurrentHashMap<String, LocalBundle>()
    private val missingBundles: MutableSet<String> = ConcurrentHashMap.newKeySet()
    private val downloads = ConcurrentHashMap<String, Deferred<LocalBundle?>>()
    private val starterCourseIds = ConcurrentHashMap<String, Set<String>>()

    private val _version = MutableStateFlow(0)

    /**
     * Incrémenté à chaque changement de ce que le catalogue sait : fichiers de langue mis à jour,
     * snapshot invalidé, paquet de cours arrivé (il apporte un quiz, un glossaire, un temps de
     * lecture). Un écran qui le collecte se recompose quand le catalogue change.
     */
    val version: StateFlow<Int> = _version.asStateFlow()

    @Volatile
    var config: CatalogRemoteConfig = CatalogRemoteConfig()
        private set

    @Volatile
    private var configLoaded = false

    @Volatile
    var isRefreshing = false
        private set

    /** Un paquet décodé, avec le texte JSON de son `content` rendu une seule fois. */
    private class LocalBundle(val bundle: CourseBundle) {
        val contentText: String by lazy { bundle.content.toString() }
    }

    /** Le contexte applicatif, pour le disque, les assets et les préférences. À appeler au lancement. */
    fun attach(context: Context) {
        if (attached == null) attached = context.applicationContext
        loadSavedConfig()
    }

    private fun context(): Context = attached ?: SophiaApplication.instance.also { attached = it }

    /** Le contexte applicatif connu du store, pour les chargeurs appelés sans contexte (`AuthorStore.author`). */
    fun appContext(): Context = context()

    private fun prefs(): SharedPreferences = context().getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun lastRefreshKey(code: String) = "last_refresh_$code"

    private fun etagKey(code: String) = "etag_$code"

    private fun key(courseId: String, language: AppLanguage) = "${language.code}|$courseId"

    // MARK: - Lecture

    /**
     * Le catalogue d'une langue, construit à la demande depuis le disque ou le pack de départ.
     * Lit le disque à la première demande : à appeler hors du fil principal quand c'est possible.
     */
    fun snapshot(language: AppLanguage): CatalogSnapshot {
        snapshots[language.code]?.let { return it }
        return synchronized(snapshots) {
            snapshots[language.code] ?: buildSnapshot(language).also { snapshots[language.code] = it }
        }
    }

    /** Le snapshot déjà en mémoire, sans rien lire ; null tant qu'il n'a pas été construit. */
    fun cachedSnapshot(language: AppLanguage): CatalogSnapshot? = snapshots[language.code]

    /** Le paquet d'un cours s'il est déjà sur le téléphone (disque ou pack de départ) ; sinon null. */
    fun localBundle(courseId: String, language: AppLanguage): CourseBundle? =
        loadLocalBundle(courseId, language)?.bundle

    /** Le paquet déjà décodé en mémoire, sans toucher au disque ; pour les lectures du fil principal. */
    fun cachedBundle(courseId: String, language: AppLanguage): CourseBundle? =
        bundles[key(courseId, language)]?.bundle

    fun hasLocalContent(courseId: String, language: AppLanguage): Boolean =
        loadLocalBundle(courseId, language) != null

    /**
     * Le `content` V2 d'un cours en texte JSON, s'il est sur le téléphone ; sinon null, et c'est
     * [ensureContent] qui ira le chercher. Les lecteurs existants parcourent ce texte eux-mêmes.
     */
    fun localContentJson(courseId: String, language: AppLanguage): String? =
        loadLocalBundle(courseId, language)?.contentText

    /**
     * La couverture d'un cours d'après le catalogue en mémoire (pour un cours arrivé en ligne après
     * le build, absent de `course_image_map.json`). Ne lit rien : null si le snapshot n'est pas construit.
     */
    fun coverSlug(courseId: String, language: AppLanguage): String? =
        cachedSnapshot(language)?.entryById?.get(courseId)?.cover?.takeIf { it.isNotBlank() }

    /** Le quiz d'un cours : le fichier `quizzes.json` de la langue, sinon celui du paquet local. */
    fun quiz(courseId: String, language: AppLanguage): List<QuizQuestion> {
        snapshot(language).quizzes[courseId]?.let { return it }
        return localBundle(courseId, language)?.quiz.orEmpty()
    }

    /**
     * Oublie les snapshots : ils seront reconstruits à la prochaine lecture (changement de langue,
     * fichiers mis à jour). Les paquets déjà décodés restent valables.
     */
    fun resetMemory() {
        snapshots.clear()
        bumpVersion()
    }

    /** Ce qu'affiche la ligne « Catalogue en ligne » des réglages développeur (DEBUG seulement). */
    fun debugSummary(language: AppLanguage): String {
        val snapshot = snapshot(language)
        val code = language.code
        val starter = starterCourseIds(code)
        val local = snapshot.summaries.count { summary ->
            bundles.containsKey(key(summary.id, language)) ||
                summary.id in starter ||
                diskFile(code, "courses/${summary.id}.json").isFile
        }
        val last = prefs().getLong(lastRefreshKey(code), 0L)
        val since = if (last <= 0L) {
            "—"
        } else {
            val minutes = ((System.currentTimeMillis() - last) / 60_000L).toInt()
            if (minutes < 60) "$minutes min" else "${minutes / 60} h"
        }
        return "${snapshot.summaries.size} cours · $local sur le téléphone · ${snapshot.source.label} · maj $since"
    }

    // MARK: - Contenu à la demande

    /**
     * Le contenu d'un cours (texte JSON V2), téléchargé s'il le faut. Rend la copie locale tout de
     * suite quand il y en a une (et rafraîchit en arrière-plan si le manifeste annonce une version
     * plus récente) ; sinon attend le réseau. Null : hors ligne et jamais téléchargé.
     */
    suspend fun ensureContent(courseId: String, language: AppLanguage): String? = withContext(Dispatchers.IO) {
        val local = loadLocalBundle(courseId, language)
        if (local != null) {
            val wanted = manifests[language.code]?.courses?.get(courseId)?.hash
            if (wanted != null && wanted != local.bundle.hash) {
                scope.launch { download(courseId, language) }
            }
            return@withContext local.contentText
        }
        if (!config.enabled) return@withContext null
        if (manifests[language.code] == null) refresh(context(), language, force = false)
        download(courseId, language)?.contentText
    }

    /**
     * Télécharge en avance les paquets qui manquent (les premières cartes du fil, les cours d'une
     * collection), huit au plus, sans bloquer personne.
     */
    fun prefetch(courseIds: List<String>, language: AppLanguage) {
        if (courseIds.isEmpty() || !config.enabled) return
        scope.launch {
            val missing = courseIds.distinct()
                .filter { !hasLocalContent(it, language) }
                .take(PREFETCH_LIMIT)
            if (missing.isEmpty()) return@launch
            if (manifests[language.code] == null) refresh(context(), language, force = false)
            for (courseId in missing) download(courseId, language)
        }
    }

    // MARK: - Rafraîchissement

    /**
     * Au lancement et au retour au premier plan : relit le manifeste si le dernier date de plus de
     * `refresh_hours` (six heures par défaut), ou s'il n'y en a jamais eu pour cette langue.
     */
    suspend fun refreshIfNeeded(context: Context, language: AppLanguage) {
        attach(context)
        withContext(Dispatchers.IO) {
            val code = language.code
            if (manifests[code] == null) readManifestFromDisk(code)?.let { manifests[code] = it }
            val last = prefs().getLong(lastRefreshKey(code), 0L)
            val fresh = manifests[code] != null && last > 0L &&
                System.currentTimeMillis() - last < (config.refreshHours * 3_600_000.0).toLong()
            if (!fresh) refresh(context, language, force = false)
        }
    }

    /**
     * Relit la configuration distante puis le manifeste ; télécharge les fichiers de la langue dont
     * le hash a changé. Le manifeste porte un ETag : rien n'a bougé, la réponse est un 304. Un
     * fichier n'est écrit que s'il se décode, puis d'un bloc (fichier temporaire renommé).
     */
    suspend fun refresh(context: Context, language: AppLanguage, force: Boolean) {
        attach(context)
        withContext(Dispatchers.IO) {
            refreshMutex.withLock {
                isRefreshing = true
                try {
                    performRefresh(language, force)
                } finally {
                    isRefreshing = false
                }
            }
        }
    }

    /**
     * Changement de langue dans les réglages : le snapshot de la nouvelle langue se construit à la
     * lecture ; on lance tout de suite le rafraîchissement pour elle.
     */
    fun languageDidChange(context: Context, language: AppLanguage) {
        attach(context)
        resetMemory()
        scope.launch { refreshIfNeeded(context.applicationContext, language) }
    }

    private fun performRefresh(language: AppLanguage, force: Boolean) {
        val code = language.code
        if (manifests[code] == null) readManifestFromDisk(code)?.let { manifests[code] = it }
        // Deux appelants en même temps (lancement et premier plan, deux fiches ouvertes) : le
        // second trouve un manifeste tout frais et s'arrête là.
        if (!force && manifests[code] != null &&
            System.currentTimeMillis() - prefs().getLong(lastRefreshKey(code), 0L) < DEDUPE_WINDOW_MS
        ) {
            return
        }
        loadRemoteConfig()
        if (!config.enabled) return

        val headers = mutableMapOf("apikey" to AppConfig.SUPABASE_ANON_KEY)
        val etag = prefs().getString(etagKey(code), null)
        if (!force && etag != null && manifests[code] != null) headers["If-None-Match"] = etag
        val response = httpGet(manifestUrl(code), headers, timeoutMs = 20_000) ?: return
        if (response.status == 304) {
            markRefreshed(code)
            return
        }
        if (response.status != 200) return
        val text = response.body ?: return
        val manifest = decodeOrNull<CatalogManifest>(text) ?: return
        manifests[code] = manifest
        write(code, "manifest.json", text)
        response.etag?.let { prefs().edit().putString(etagKey(code), it).apply() }

        val hashes = readHashes(code).toMutableMap()
        var changed = false
        for (kind in LANGUAGE_FILES) {
            val entry = manifest.files[kind] ?: continue
            if (hashes[kind] == entry.hash && diskFile(code, "$kind.json").isFile) continue
            val body = fetchEntry(entry) ?: continue
            if (!looksValid(kind, body)) continue
            write(code, "$kind.json", body)
            hashes[kind] = entry.hash
            changed = true
        }
        if (changed) {
            writeHashes(code, hashes)
            snapshots.remove(code)
            bumpVersion()
        }
        markRefreshed(code)
    }

    private fun markRefreshed(code: String) {
        prefs().edit().putLong(lastRefreshKey(code), System.currentTimeMillis()).apply()
    }

    private fun bumpVersion() {
        _version.update { it + 1 }
    }

    /** `app_config` → `catalog`. Une erreur réseau garde la dernière valeur connue. */
    private fun loadRemoteConfig() {
        val url = "${baseUrl()}/rest/v1/app_config?key=eq.catalog&select=value"
        val headers = mapOf(
            "apikey" to AppConfig.SUPABASE_ANON_KEY,
            "Authorization" to "Bearer ${AppConfig.SUPABASE_ANON_KEY}",
        )
        val body = httpGet(url, headers, timeoutMs = 15_000)?.takeIf { it.status == 200 }?.body ?: return
        val value = decodeOrNull<List<AppConfigRow>>(body)?.firstOrNull()?.value ?: return
        config = value
        prefs().edit().putString(KEY_CONFIG, json.encodeToString(CatalogRemoteConfig.serializer(), value)).apply()
    }

    private fun loadSavedConfig() {
        if (configLoaded) return
        configLoaded = true
        val saved = prefs().getString(KEY_CONFIG, null) ?: return
        decodeOrNull<CatalogRemoteConfig>(saved)?.let { config = it }
    }

    // MARK: - Téléchargement des paquets

    /** Un seul téléchargement à la fois par cours : les appelants concurrents attendent le même. */
    private suspend fun download(courseId: String, language: AppLanguage): LocalBundle? {
        val key = key(courseId, language)
        val created = scope.async(start = CoroutineStart.LAZY) { performDownload(courseId, language) }
        val running = downloads.putIfAbsent(key, created) ?: created
        if (running === created) {
            created.invokeOnCompletion { downloads.remove(key, created) }
            created.start()
        }
        return running.await()
    }

    private fun performDownload(courseId: String, language: AppLanguage): LocalBundle? {
        val code = language.code
        val entry = manifests[code]?.courses?.get(courseId) ?: return null
        val text = fetchEntry(entry) ?: return null
        val bundle = decodeOrNull<CourseBundle>(text) ?: return null
        write(code, "courses/$courseId.json", text)
        val key = key(courseId, language)
        val local = LocalBundle(bundle)
        bundles[key] = local
        missingBundles.remove(key)
        // Le paquet apporte le quiz et le glossaire d'un cours que les fichiers de la langue ne
        // connaissaient pas encore, et le temps de lecture de sa fiche : les écrans se relisent.
        bumpVersion()
        return local
    }

    // MARK: - Construction du snapshot

    private fun buildSnapshot(language: AppLanguage): CatalogSnapshot {
        val code = language.code
        val fromDisk = readDisk(code, "catalog.json")?.let { decodeOrNull<CatalogFile>(it) }
        val fromStarter = if (fromDisk == null) {
            readStarter(code, "catalog.json")?.let { decodeOrNull<CatalogFile>(it) }
        } else {
            null
        }
        val file = fromDisk ?: fromStarter ?: return CatalogSnapshot(language, CatalogSnapshot.Source.EMPTY)
        val source = if (fromDisk != null) CatalogSnapshot.Source.DISK else CatalogSnapshot.Source.STARTER_PACK

        val summaries = ArrayList<CourseSummary>(file.courses.size)
        val entryById = HashMap<String, CatalogCourseEntry>(file.courses.size * 2)
        for (entry in file.courses) {
            // Une matière inconnue de ce build : le cours attendra une mise à jour de l'app.
            if (Subject.fromStorageKey(entry.subject) == null) continue
            if (entryById.containsKey(entry.id)) continue
            entryById[entry.id] = entry
            summaries += CourseSummary(
                id = entry.id,
                title = entry.title,
                description = entry.description,
                subject = entry.subject,
                subcategory = entry.subcategory,
            )
        }
        val collections = file.collections.map {
            LearningCollection(
                id = it.id,
                title = it.title,
                description = it.description,
                coverAssetName = it.cover.orEmpty(),
                courseIds = it.courseIds,
            )
        }
        val authors = file.creators.map { it.toAuthor(language) }
        return CatalogSnapshot(
            language = language,
            source = source,
            hash = file.hash,
            summaries = summaries,
            entryById = entryById,
            collections = collections,
            authors = authors,
            quizzesLoader = {
                readDisk(code, "quizzes.json")
                    ?.let { decodeOrNull<Map<String, List<QuizQuestion>>>(it) }
                    .orEmpty()
            },
            glossaryLoader = {
                readDisk(code, "glossary.json")
                    ?.let { decodeOrNull<Map<String, GlossaryEntry>>(it) }
                    .orEmpty()
            },
        )
    }

    private fun loadLocalBundle(courseId: String, language: AppLanguage): LocalBundle? {
        val key = key(courseId, language)
        bundles[key]?.let { return it }
        if (key in missingBundles) return null
        val code = language.code
        // Un fichier téléchargé qui ne se décode plus n'empêche pas de lire la copie du pack.
        val bundle = readDisk(code, "courses/$courseId.json")?.let { decodeOrNull<CourseBundle>(it) }
            ?: readStarter(code, "courses/$courseId.json")?.let { decodeOrNull<CourseBundle>(it) }
        if (bundle == null) {
            missingBundles.add(key)
            return null
        }
        return LocalBundle(bundle).also { bundles[key] = it }
    }

    /**
     * Un fichier de langue n'est écrit que s'il se décode : un téléchargement tronqué ne doit
     * jamais remplacer un catalogue qui marchait.
     */
    private fun looksValid(kind: String, text: String): Boolean = when (kind) {
        "catalog" -> decodeOrNull<CatalogFile>(text)?.courses?.isNotEmpty() == true
        "quizzes" -> decodeOrNull<Map<String, List<QuizQuestion>>>(text) != null
        "glossary" -> decodeOrNull<Map<String, GlossaryEntry>>(text) != null
        else -> false
    }

    private inline fun <reified T> decodeOrNull(text: String): T? = try {
        json.decodeFromString<T>(text)
    } catch (e: Exception) {
        null
    }

    // MARK: - URLs

    /**
     * Télécharge un fichier annoncé par le manifeste : à son `url` quand il en a une (objet
     * Storage ou Edge Function `catalog-file`), sinon à son `path` sous le bucket. Null si
     * l'entrée ne dit pas où le prendre ou si la requête n'a pas abouti.
     */
    private fun fetchEntry(entry: CatalogManifestEntry): String? {
        val url = entry.url?.takeIf { it.isNotBlank() }
            ?: entry.path.takeIf { it.isNotBlank() }?.let { objectUrl(it) }
            ?: return null
        return httpGet(url, downloadHeaders(url), timeoutMs = 30_000)
            ?.takeIf { it.status == HttpURLConnection.HTTP_OK }
            ?.body
    }

    /**
     * La passerelle Supabase exige l'en-tête `apikey` devant une Edge Function ; un objet public
     * de Storage l'ignore. Envoyé pour tout ce qui vit sur notre projet, jamais ailleurs.
     */
    private fun downloadHeaders(url: String): Map<String, String> =
        if (url.startsWith(baseUrl())) mapOf("apikey" to AppConfig.SUPABASE_ANON_KEY) else emptyMap()

    private fun baseUrl(): String = AppConfig.SUPABASE_URL.trimEnd('/')

    private fun manifestUrl(code: String): String =
        "${baseUrl()}/functions/v1/catalog-manifest?lang=${URLEncoder.encode(code, "UTF-8")}"

    /** Un objet du bucket `course-content`, nommé par son hash : le cache HTTP peut le garder pour toujours. */
    fun objectUrl(path: String): String = "${baseUrl()}/storage/v1/object/public/$BUCKET/${path.trimStart('/')}"

    // MARK: - Réseau

    private class HttpResponse(val status: Int, val body: String?, val etag: String?)

    /** GET bloquant, à appeler sur `Dispatchers.IO`. Null quand la requête n'a pas abouti. */
    private fun httpGet(url: String, headers: Map<String, String>, timeoutMs: Int): HttpResponse? {
        var connection: HttpURLConnection? = null
        return try {
            val conn = URL(url).openConnection() as HttpURLConnection
            connection = conn
            conn.connectTimeout = timeoutMs
            conn.readTimeout = timeoutMs
            conn.useCaches = false
            conn.requestMethod = "GET"
            conn.setRequestProperty("Accept", "application/json")
            for ((name, value) in headers) conn.setRequestProperty(name, value)
            val status = conn.responseCode
            val body = if (status == HttpURLConnection.HTTP_OK) {
                conn.inputStream.bufferedReader().use { it.readText() }
            } else {
                null
            }
            HttpResponse(status, body, conn.getHeaderField("ETag"))
        } catch (e: Exception) {
            if (BuildConfig.DEBUG) Log.w(TAG, "requête échouée $url : ${e.message}")
            null
        } finally {
            connection?.disconnect()
        }
    }

    // MARK: - Disque

    /** `filesDir/catalog/<code>/` : tout s'y retélécharge, rien n'y est irremplaçable. */
    private fun diskFile(code: String, name: String): File = File(File(File(context().filesDir, "catalog"), code), name)

    private fun readDisk(code: String, name: String): String? {
        val file = diskFile(code, name)
        if (!file.isFile) return null
        return try {
            file.readText()
        } catch (e: Exception) {
            null
        }
    }

    /** Écriture atomique : fichier temporaire puis renommage, pour ne jamais laisser un JSON à moitié écrit. */
    private fun write(code: String, name: String, text: String) {
        val target = diskFile(code, name)
        try {
            val directory = target.parentFile ?: return
            directory.mkdirs()
            val tmp = File(directory, "${target.name}.tmp")
            tmp.writeText(text)
            try {
                Files.move(
                    tmp.toPath(),
                    target.toPath(),
                    StandardCopyOption.REPLACE_EXISTING,
                    StandardCopyOption.ATOMIC_MOVE,
                )
            } catch (e: Exception) {
                if (!tmp.renameTo(target)) {
                    target.delete()
                    tmp.renameTo(target)
                }
            }
        } catch (e: Exception) {
            if (BuildConfig.DEBUG) Log.w(TAG, "écriture impossible $code/$name", e)
        }
    }

    private fun readManifestFromDisk(code: String): CatalogManifest? =
        readDisk(code, "manifest.json")?.let { decodeOrNull<CatalogManifest>(it) }

    private fun readHashes(code: String): Map<String, String> =
        readDisk(code, "hashes.json")?.let { decodeOrNull<Map<String, String>>(it) }.orEmpty()

    private fun writeHashes(code: String, hashes: Map<String, String>) {
        write(code, "hashes.json", json.encodeToString(hashes))
    }

    // MARK: - Pack de départ

    private fun readStarter(code: String, name: String): String? = try {
        context().assets.open("starter_pack/$code/$name").bufferedReader().use { it.readText() }
    } catch (e: Exception) {
        null
    }

    /** Les cours embarqués pour une langue, d'après le dossier du pack ; listés une fois. */
    private fun starterCourseIds(code: String): Set<String> = starterCourseIds.getOrPut(code) {
        try {
            context().assets.list("starter_pack/$code/courses")
                .orEmpty()
                .filter { it.endsWith(".json") }
                .map { it.removeSuffix(".json") }
                .toSet()
        } catch (e: Exception) {
            emptySet()
        }
    }
}
