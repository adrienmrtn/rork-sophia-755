package app.rork.sophia.data

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.State
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.platform.LocalContext
import app.rork.sophia.data.catalog.CatalogStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Course
import app.rork.sophia.domain.fakeReadsCount
import app.rork.sophia.domain.locale
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import java.text.DecimalFormatSymbols
import java.util.Locale
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.roundToInt

/**
 * Compteurs affichés sur les cartes, la page créateur et l'événement tant que le serveur ne
 * les fournit pas (prompt 6). Ils sont faux mais stables : dérivés d'un hash FNV-1a de
 * l'identifiant, donc identiques à chaque lancement et sur tous les appareils, comme
 * `Course.readsCount` (et qu'iOS, même formule). Les gestes locaux (j'aime, suivre)
 * s'ajoutent par-dessus.
 */
object LocalCounters {
    fun hash(text: String): ULong {
        var hash = 0xcbf29ce484222325UL
        for (byte in text.encodeToByteArray()) {
            hash = hash xor byte.toULong()
            hash *= 0x100000001b3UL
        }
        return hash
    }

    /** Lectures d'un cours, par son identifiant seul (même valeur que `Course.readsCount`). */
    fun reads(courseId: String): Int = fakeReadsCount(courseId)

    /** Entre 9 % et 16 % des lectures, arrondi à la dizaine. */
    fun likes(courseId: String, reads: Int = reads(courseId)): Int {
        val ratio = 0.09 + (hash("$courseId|likes") % 70UL).toDouble() / 1_000
        return maxOf(10, (reads * ratio).toInt() / 10 * 10)
    }

    /** Nombre de « j'aime » affiché : le compteur local plus le geste de l'utilisateur. */
    fun likesCount(courseId: String, liked: Boolean): Int = likes(courseId) + (if (liked) 1 else 0)

    /** Abonnés d'un créateur : entre 800 et 5 800, arrondi à la dizaine. */
    fun followers(creatorSlug: String): Int =
        800 + (hash("$creatorSlug|followers") % 5_000UL).toInt() / 10 * 10

    /** Lectures cumulées d'un créateur : la somme de celles de ses cours. */
    fun reads(author: CourseAuthor): Int = author.courseIds.sumOf { reads(it) }
}

/**
 * Format compact des compteurs : « 940 », « 7,2 k », « 18 k », « 1,2 M ».
 * Le séparateur décimal suit la langue de l'app.
 */
fun Int.compactCount(language: AppLanguage): String {
    val separator = DecimalFormatSymbols.getInstance(language.locale).decimalSeparator
    fun one(value: Double, suffix: String): String {
        if (value >= 10) return "${value.toInt()} $suffix"
        var text = String.format(Locale.US, "%.1f", value).replace('.', separator)
        if (text.endsWith("${separator}0")) text = text.dropLast(2)
        return "$text $suffix"
    }
    return when {
        this >= 1_000_000 -> one(this / 1_000_000.0, "M")
        this >= 1_000 -> one(this / 1_000.0, "k")
        else -> toString()
    }
}

/**
 * Ce que les nouveaux écrans tirent du contenu structuré d'un cours (le paquet du catalogue
 * en ligne) sans ouvrir le lecteur : temps de lecture, nombre de sections, accroche,
 * introduction, langue d'origine. Lu une fois par cours et par langue, puis servi de mémoire.
 */
data class StructuredCourseInfo(
    /** Temps de lecture estimé en minutes, borné entre 2 et 20. */
    val minutes: Int,
    val sectionCount: Int,
    /** L'accroche du héros, sinon le sous-titre, sinon la description du catalogue. */
    val hook: String,
    /** Les deux premiers paragraphes de la première section, sinon la description. */
    val introduction: String,
    /** Code de la langue d'écriture quand le cours est une traduction (`originalLanguage`). */
    val originalLanguage: String?,
)

/**
 * Temps de lecture estimé d'un cours, à partir du nombre de mots de son contenu structuré
 * (180 mots par minute), borné entre 2 et 20 minutes. Sans contenu structuré, une minute et
 * demie par page. Mis en cache par cours et par langue, comme sur iOS.
 */
object ReadingTime {
    const val WORDS_PER_MINUTE = 180

    private val json = Json { ignoreUnknownKeys = true; isLenient = true }
    private val cache = ConcurrentHashMap<String, StructuredCourseInfo>()

    private fun key(language: AppLanguage, courseId: String) = "${language.code}|$courseId"

    /** Ce qui est déjà en mémoire, sans lecture de fichier. */
    fun cached(language: AppLanguage, courseId: String): StructuredCourseInfo? = cache[key(language, courseId)]

    /** Lit le JSON structuré si besoin : à appeler hors du fil principal. */
    fun info(context: Context, language: AppLanguage, course: Course): StructuredCourseInfo {
        cache[key(language, course.id)]?.let { return it }
        // Le contenu vient du catalogue en ligne : tant qu'il n'est pas sur le téléphone, la
        // valeur de repli est rendue sans être retenue, pour être recalculée à son arrivée.
        val raw = ContentCatalog.structuredContentJson(context, language, course.id) ?: return fallback(course)
        val computed = compute(raw, course)
        cache[key(language, course.id)] = computed
        return computed
    }

    suspend fun infoAsync(context: Context, language: AppLanguage, course: Course): StructuredCourseInfo =
        cached(language, course.id) ?: withContext(Dispatchers.IO) { info(context, language, course) }

    fun minutes(context: Context, language: AppLanguage, course: Course): Int = info(context, language, course).minutes

    fun sectionCount(context: Context, language: AppLanguage, course: Course): Int =
        info(context, language, course).sectionCount

    private fun fallback(course: Course): StructuredCourseInfo {
        val pages = course.lessons.size
        val minutes = if (pages > 0) (pages * 1.5).roundToInt().coerceIn(2, 20) else 2
        val description = stripInlineMarkup(course.description)
        return StructuredCourseInfo(
            minutes = minutes,
            sectionCount = maxOf(1, pages),
            hook = description,
            introduction = description,
            originalLanguage = null,
        )
    }

    private fun compute(raw: String, course: Course): StructuredCourseInfo {
        return try {
            val root = json.parseToJsonElement(raw).jsonObject
            val sections = root["sections"]?.jsonArray.orEmpty().mapNotNull { it as? JsonObject }
            if (sections.isEmpty()) return fallback(course)
            var words = 0
            for (section in sections) words += wordCount(section)
            val minutes = (words.toDouble() / WORDS_PER_MINUTE).roundToInt().coerceIn(2, 20)
            val hero = root["hero"] as? JsonObject
            val hook = hero?.text("hook") ?: root.text("subtitle") ?: course.description
            val paragraphs = sections.first()["blocks"]?.jsonArray.orEmpty()
                .mapNotNull { it as? JsonObject }
                .filter { it.text("type") == "paragraph" }
                .mapNotNull { it.text("text") }
                .take(2)
            val introduction = paragraphs.joinToString("\n\n").ifBlank { course.description }
            StructuredCourseInfo(
                minutes = minutes,
                sectionCount = sections.size,
                hook = stripInlineMarkup(hook),
                introduction = stripInlineMarkup(introduction),
                originalLanguage = root.text("originalLanguage"),
            )
        } catch (_: Exception) {
            fallback(course)
        }
    }

    private fun wordCount(section: JsonObject): Int {
        val builder = StringBuilder(section.text("title").orEmpty())
        for (element in section["blocks"]?.jsonArray.orEmpty()) {
            val block = element as? JsonObject ?: continue
            when (block.text("type")) {
                "heading", "paragraph", "funFact", "takeaway", "quote" ->
                    builder.append(' ').append(block.text("text").orEmpty())
                "timeline" -> {
                    for (event in block["events"]?.jsonArray.orEmpty()) {
                        val item = event as? JsonObject ?: continue
                        builder.append(' ').append(item.text("date").orEmpty())
                            .append(' ').append(item.text("title").orEmpty())
                            .append(' ').append(item.text("detail").orEmpty())
                    }
                }
                "image" -> builder.append(' ').append(block.text("caption").orEmpty())
            }
        }
        return builder.split(Regex("\\s+")).count { it.isNotBlank() }
    }

    private fun JsonObject.text(key: String): String? =
        (this[key] as? JsonPrimitive)?.contentOrNull?.takeIf { it.isNotBlank() }

    fun clearCache() {
        cache.clear()
    }
}

/**
 * Enlève les marqueurs d'écriture (`**gras**`, `==surligné==`, `[[terme]]`, `*italique*`)
 * d'un texte destiné à un `Text` simple : titres de cartes, accroches, méta.
 */
fun stripInlineMarkup(raw: String): String =
    raw.replace("**", "")
        .replace("==", "")
        .replace("[[", "")
        .replace("]]", "")
        .replace("*", "")
        .trim()

/**
 * Les infos structurées d'un cours pour une carte ou une fiche, lues hors du fil principal ;
 * null tant qu'elles ne sont pas connues. Relues quand le catalogue change (`CatalogStore.version`),
 * donc quand le paquet du cours vient d'être téléchargé.
 */
@Composable
fun rememberCourseInfo(course: Course, language: AppLanguage): State<StructuredCourseInfo?> {
    val context = LocalContext.current
    val version by CatalogStore.version.collectAsState()
    return produceState(initialValue = ReadingTime.cached(language, course.id), course.id, language, version) {
        value = ReadingTime.infoAsync(context.applicationContext, language, course)
    }
}
