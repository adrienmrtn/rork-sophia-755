package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.data.catalog.CatalogStore
import app.rork.sophia.domain.AppLanguage
import kotlinx.serialization.Serializable

/**
 * A professor who wrote one or more courses, from the `creators` of the online catalogue
 * (`CatalogStore`). Each author carries the ids of the courses that name it, so "other courses
 * by this professor" costs no course decode. Le catalogue d'une langue ne porte le titre et la
 * bio que dans cette langue : les tables n'ont donc qu'une clé, celle de la langue courante.
 */
@Serializable
data class CourseAuthor(
    val slug: String,
    val name: String,
    /** File name (no extension) under `assets/author_photos`; null shows the initials. */
    val photo: String? = null,
    /** Portrait hébergé d'un créateur du Studio (`creators.photo_url`), affiché quand [photo] manque. */
    val photoUrl: String? = null,
    val institution: String? = null,
    val country: String? = null,
    val links: Map<String, String> = emptyMap(),
    val title: Map<String, String> = emptyMap(),
    val bio: Map<String, String> = emptyMap(),
    val courseIds: List<String> = emptyList(),
    /**
     * Expert vérifié (diplôme ou fonction contrôlés par l'équipe). Absent des fichiers
     * actuels : tous les auteurs embarqués sont des universitaires, donc vérifiés par défaut.
     * Le Studio (prompt 5) posera la valeur explicitement pour les nouveaux créateurs.
     */
    val verified: Boolean? = null,
) {
    val isVerified: Boolean get() = verified ?: true

    fun title(language: AppLanguage): String? = localized(title, language)

    fun bio(language: AppLanguage): String? = localized(bio, language)

    /** Coil model for the portrait: the bundled asset, else the hosted photo of a Studio creator, or null. */
    val photoModel: String?
        get() = bundledPhotoModel ?: photoUrl?.takeIf { it.startsWith("https://") }

    /** Only the bundled portrait (`assets/author_photos`), for the screens shown before any network. */
    val bundledPhotoModel: String?
        get() = photo?.takeIf { it.isNotBlank() }?.let { "file:///android_asset/author_photos/$it.jpg" }

    /** Up to two initials for the avatar fallback: "Dusan Nikolic" → "DN". */
    val initials: String
        get() {
            val parts = name.split(' ', '-').filter { it.isNotBlank() }
            val picked = if (parts.size >= 2) listOf(parts.first(), parts.last()) else parts.take(1)
            return picked.mapNotNull { it.firstOrNull()?.uppercaseChar() }.joinToString("")
        }

    private fun localized(table: Map<String, String>, language: AppLanguage): String? {
        for (code in listOf(language.code, "en", "fr")) {
            table[code]?.trim()?.takeIf { it.isNotEmpty() }?.let { return it }
        }
        return table.values.firstOrNull { it.isNotBlank() }
    }
}

/**
 * Les créateurs de cours, lus dans le snapshot du catalogue en ligne de la langue persistée
 * (`CatalogStore`, section `creators`) ; leurs portraits sont embarqués (`author_photos/`) pour les
 * auteurs du pack, hébergés (`photoUrl`, chargés par Coil) pour les créateurs du Studio.
 */
object AuthorStore {
    /** Construit le snapshot de la langue si besoin : à appeler hors du fil principal quand c'est possible. */
    fun preload(context: Context) {
        all(context)
    }

    fun all(context: Context): List<CourseAuthor> =
        CatalogStore.snapshot(LanguageManager.persisted(context)).authors

    /**
     * Only answers from the snapshot already in memory (after [preload]); null before that or for an
     * unknown slug. Never reads a file, so it is safe during composition.
     */
    fun author(slug: String): CourseAuthor? =
        CatalogStore.cachedSnapshot(LanguageManager.persisted(CatalogStore.appContext()))
            ?.authors
            ?.firstOrNull { it.slug == slug }

    fun author(context: Context, slug: String): CourseAuthor? = all(context).firstOrNull { it.slug == slug }

    fun authorForCourse(context: Context, courseId: String): CourseAuthor? =
        all(context).firstOrNull { courseId in it.courseIds }

    /** Les auteurs vivent dans le snapshot : l'oublier le reconstruit à la prochaine lecture. */
    fun clearCache() {
        CatalogStore.resetMemory()
    }
}
