package app.rork.sophia.domain

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.time.LocalDate
import java.time.format.DateTimeFormatter

/**
 * Un événement éditorial (« Movember », une semaine thématique…) : une collection de cours à
 * lire pendant une période, un défi avec un badge, et des cours annoncés en écriture.
 *
 * Mêmes champs que la table `campaigns` prévue côté serveur (prompt 6). En attendant, les
 * événements viennent de JSON de test dans `assets/events/` (source : `content/events/`,
 * mêmes fichiers qu'iOS). Les textes sont donnés par langue (`fr`, `en`…) et retombent sur
 * l'anglais puis le français.
 */
@Serializable
data class Campaign(
    val slug: String,
    /** Symbole SF illustrant l'événement (`mustache.fill`), traduit en icône Material à l'affichage. */
    val symbol: String? = null,
    @SerialName("starts_at") val startsAt: String,
    @SerialName("ends_at") val endsAt: String,
    /** Nombre de cours de la collection à terminer pour obtenir le badge. */
    @SerialName("challenge_target") val challengeTarget: Int = 1,
    /** Lecteurs participants affichés (valeur de test tant que le serveur ne compte pas). */
    val participants: Int = 0,
    @SerialName("course_ids") val courseIds: List<String> = emptyList(),
    val upcoming: List<Upcoming> = emptyList(),
    val title: Map<String, String> = emptyMap(),
    val tagline: Map<String, String> = emptyMap(),
    val description: Map<String, String> = emptyMap(),
    @SerialName("badge_name") val badgeName: Map<String, String> = emptyMap(),
) {
    @Serializable
    data class Upcoming(
        val title: Map<String, String> = emptyMap(),
        /** Slug d'auteur (`CourseAuthor.slug`), s'il est connu. */
        val creator: String? = null,
        /** Date de sortie annoncée, `yyyy-MM-dd`. */
        val date: String = "",
    ) {
        fun title(language: AppLanguage): String = localized(title, language)

        val releaseDate: LocalDate? get() = parseDay(date)
    }

    fun title(language: AppLanguage): String = localized(title, language)
    fun tagline(language: AppLanguage): String = localized(tagline, language)
    fun description(language: AppLanguage): String = localized(description, language)
    fun badgeName(language: AppLanguage): String = localized(badgeName, language)

    val startDate: LocalDate? get() = parseDay(startsAt)
    val endDate: LocalDate? get() = parseDay(endsAt)

    /** Actif entre le premier jour et la fin du dernier jour, inclus. */
    fun isActive(today: LocalDate = LocalDate.now()): Boolean {
        val start = startDate ?: return false
        val end = endDate ?: return false
        return !today.isBefore(start) && !today.isAfter(end)
    }

    companion object {
        /** `yyyy-MM-dd` → ce jour, ou null si le texte n'est pas une date. */
        fun parseDay(text: String): LocalDate? = try {
            LocalDate.parse(text.take(10), DateTimeFormatter.ISO_LOCAL_DATE)
        } catch (_: Exception) {
            null
        }

        fun localized(table: Map<String, String>, language: AppLanguage): String {
            for (code in listOf(language.code, "en", "fr")) {
                table[code]?.trim()?.takeIf { it.isNotEmpty() }?.let { return it }
            }
            return table.values.firstOrNull { it.isNotBlank() }.orEmpty()
        }
    }
}
