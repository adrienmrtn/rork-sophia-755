package app.rork.sophia.data.catalog

import app.rork.sophia.data.CourseAuthor
import app.rork.sophia.data.GlossaryEntry
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.LearningCollection
import app.rork.sophia.domain.QuizQuestion
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

// Les formats JSON que Supabase sert aux apps depuis le bucket `course-content`, et que le
// pack de départ embarque (`assets/starter_pack/<lang>/`). Produits par
// scripts/import_catalog_to_supabase.py ; mêmes structures que `CatalogModels.swift` sur iOS.

/** Une section d'un cours telle que le catalogue la décrit : l'identifiant, le titre, gratuite ou non. */
@Serializable
data class CatalogSection(
    val id: String,
    val title: String = "",
    val free: Boolean? = null,
)

/**
 * `<lang>/catalog.<hash>.json` → `courses[]` : les métadonnées d'un cours publié (sans le
 * texte). `subject` est la clé de stockage (`histoire`, `sciences`, `litterature`, `art`,
 * `mythologie`, `comprendreLeMonde`).
 */
@Serializable
data class CatalogCourseEntry(
    val id: String,
    val title: String,
    val subtitle: String? = null,
    val description: String = "",
    val subject: String,
    val subcategory: String = "",
    val hook: String? = null,
    /** Slug du créateur (`creators[].slug`), null pour les cours de la rédaction. */
    val creator: String? = null,
    /** Nom de l'objet de couverture dans le bucket `course-images` (sans extension). */
    val cover: String? = null,
    val tier: String? = null,
    val sections: List<CatalogSection> = emptyList(),
    val quizCount: Int? = null,
    /** Hash du paquet du cours : change dès que le texte, le quiz ou le glossaire bougent. */
    val hash: String = "",
)

/** `catalog.json` → `collections[]` : une collection du Parcours, avec ses cours dans l'ordre. */
@Serializable
data class CatalogCollectionEntry(
    val id: String,
    val title: String,
    val description: String = "",
    /** Nom de la couverture embarquée (`assets/collection_covers/`), vide si aucune. */
    val cover: String? = null,
    val courseIds: List<String> = emptyList(),
)

/** `catalog.json` → `creators[]` : un créateur, avec titre et bio déjà dans la langue du fichier. */
@Serializable
data class CatalogCreatorEntry(
    val slug: String,
    val name: String,
    val photo: String? = null,
    val institution: String? = null,
    val country: String? = null,
    val links: Map<String, String>? = null,
    val title: String? = null,
    val bio: String? = null,
    val verified: Boolean? = null,
    val courseIds: List<String>? = null,
) {
    /** Le modèle que les écrans connaissent déjà ; titre et bio rangés sous le code de la langue du fichier. */
    fun toAuthor(language: AppLanguage): CourseAuthor = CourseAuthor(
        slug = slug,
        name = name,
        photo = photo,
        institution = institution,
        country = country,
        links = links.orEmpty(),
        title = title?.takeIf { it.isNotBlank() }?.let { mapOf(language.code to it) }.orEmpty(),
        bio = bio?.takeIf { it.isNotBlank() }?.let { mapOf(language.code to it) }.orEmpty(),
        courseIds = courseIds.orEmpty(),
        verified = verified,
    )
}

/**
 * `<lang>/catalog.<hash>.json` : tous les cours publiés d'une langue (métadonnées et sections,
 * sans le texte), les collections du Parcours et les créateurs.
 */
@Serializable
data class CatalogFile(
    val lang: String = "",
    val hash: String = "",
    val courses: List<CatalogCourseEntry> = emptyList(),
    val collections: List<CatalogCollectionEntry> = emptyList(),
    val creators: List<CatalogCreatorEntry> = emptyList(),
)

/** Le crédit d'une image inline (`credits` du paquet), tel que `content/image_credits.json` le donne. */
@Serializable
data class ImageCredit(
    val title: String? = null,
    val author: String? = null,
    val license: String? = null,
    val source: String? = null,
)

/**
 * `<lang>/courses/<courseId>.<hash>.json` : tout ce qu'il faut pour lire un cours hors ligne,
 * en un seul téléchargement. `content` est le JSON V2 complet, gardé tel quel : le lecteur
 * (`CourseBlocks`) et `ReadingTime` le parcourent eux-mêmes en `JsonObject`.
 */
@Serializable
data class CourseBundle(
    val id: String,
    val lang: String = "",
    val hash: String = "",
    val content: JsonObject,
    val quiz: List<QuizQuestion> = emptyList(),
    /** Clé : le terme tel qu'il apparaît dans `[[…]]` (sans le préfixe `courseId|`). */
    val glossary: Map<String, GlossaryEntry>? = null,
    val credits: Map<String, ImageCredit>? = null,
)

/**
 * Un fichier à télécharger d'après le manifeste : son hash, sa taille, et où le prendre. `url`
 * (absolue) est l'adresse à utiliser : l'objet Storage, ou l'Edge Function `catalog-file` qui
 * produit le fichier depuis la base. `path`, relatif au bucket `course-content`, n'est qu'un
 * repli pour un manifeste qui ne porterait pas d'`url`.
 */
@Serializable
data class CatalogManifestEntry(
    val hash: String,
    val bytes: Long? = null,
    val path: String = "",
    val url: String? = null,
)

/**
 * La réponse de `catalog-manifest?lang=xx` : les fichiers de la langue (`catalog`, `quizzes`,
 * `glossary`) et le paquet de chaque cours publié, avec le hash qui nomme l'objet.
 */
@Serializable
data class CatalogManifest(
    val lang: String = "",
    @SerialName("generated_at") val generatedAt: String? = null,
    val files: Map<String, CatalogManifestEntry> = emptyMap(),
    val courses: Map<String, CatalogManifestEntry> = emptyMap(),
)

/** `app_config` → clé `catalog` : le coupe-circuit et la cadence de rafraîchissement. */
@Serializable
data class CatalogRemoteConfig(
    val enabled: Boolean = true,
    @SerialName("refresh_hours") val refreshHours: Double = 6.0,
    val share: Double = 1.0,
)

/** Une ligne de `rest/v1/app_config?select=value`. */
@Serializable
internal data class AppConfigRow(val value: CatalogRemoteConfig)

/**
 * Ce que l'app sait des cours d'une langue à un instant donné : construit depuis le disque ou le
 * pack de départ par [CatalogStore], remplacé d'un bloc quand les fichiers changent. Les listes
 * sont immuables ; quiz et glossaire ne sont décodés qu'à la première demande (fichiers lourds,
 * inutiles au fil d'accueil).
 */
class CatalogSnapshot(
    val language: AppLanguage,
    val source: Source,
    val hash: String = "",
    val summaries: List<CourseSummary> = emptyList(),
    /** Pour ce que `CourseSummary` ne porte pas : couverture, sections, nombre de questions. */
    val entryById: Map<String, CatalogCourseEntry> = emptyMap(),
    val collections: List<LearningCollection> = emptyList(),
    val authors: List<CourseAuthor> = emptyList(),
    quizzesLoader: () -> Map<String, List<QuizQuestion>> = { emptyMap() },
    glossaryLoader: () -> Map<String, GlossaryEntry> = { emptyMap() },
) {
    enum class Source(val label: String) {
        DISK("disque"),
        STARTER_PACK("pack embarqué"),
        EMPTY("vide"),
    }

    val courseById: Map<String, CourseSummary> = summaries.associateBy { it.id }

    /** `quizzes.json` de la langue : les questions par cours. Vide tant que le fichier n'a pas été téléchargé. */
    val quizzes: Map<String, List<QuizQuestion>> by lazy(quizzesLoader)

    /** `glossary.json` de la langue, clé `"<courseId>|<terme>"`. Vide tant que le fichier n'a pas été téléchargé. */
    val glossary: Map<String, GlossaryEntry> by lazy(glossaryLoader)
}
