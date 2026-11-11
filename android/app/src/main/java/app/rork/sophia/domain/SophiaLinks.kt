package app.rork.sophia.domain

import java.net.URI
import java.net.URLEncoder

/**
 * Les adresses du site public (`sophia-culture.com`) que l'app fabrique pour le partage et
 * reconnaît à l'ouverture, comme `SophiaDeepLink` sur iOS (docs/partage.md). Ses pages
 * `/courses/…`, `/c/…` et `/authors/…` sont des liens d'app : app installée, Android les ouvre
 * dans Sophia ; sinon la page montre le cours et mène au store.
 */
object SophiaLinks {
    const val WEB_HOST = "sophia-culture.com"

    /** Ce que désigne une adresse du site. */
    sealed class WebTarget {
        /** `/courses/150` ou `/courses/150-why-does-the-sky-swirl` : le numéro du cours. */
        data class CourseNumber(val number: Int) : WebTarget()

        /** `/c/<identifiant>` : l'identifiant complet, pour un cours sans numéro. */
        data class CourseId(val id: String) : WebTarget()

        /** `/authors/<slug>`. */
        data class Creator(val slug: String) : WebTarget()
    }

    /**
     * L'adresse à partager pour un cours : `https://sophia-culture.com/courses/150` (le site
     * redirige vers l'adresse lisible), ou `/c/<identifiant>` quand l'identifiant n'a pas de numéro.
     */
    fun courseWebUrl(courseId: String): String {
        val number = courseNumber(courseId)
        return if (number != null) "https://$WEB_HOST/courses/$number" else "https://$WEB_HOST/c/${escape(courseId)}"
    }

    fun authorWebUrl(slug: String): String = "https://$WEB_HOST/authors/${escape(slug)}"

    /** `course_150_la_nuit_etoilee` → 150 ; null si l'identifiant n'a pas cette forme. */
    fun courseNumber(courseId: String): Int? {
        val parts = courseId.split("_", limit = 3)
        if (parts.size != 3 || parts[0] != "course") return null
        return parts[1].toIntOrNull()
    }

    /** Une adresse du site qui désigne un cours ou un créateur ; null pour tout le reste. */
    fun webTarget(url: String): WebTarget? {
        val uri = runCatching { URI(url.trim()) }.getOrNull() ?: return null
        val scheme = uri.scheme?.lowercase()
        if (scheme != "https" && scheme != "http") return null
        val host = uri.host?.lowercase() ?: return null
        if (host != WEB_HOST && host != "www.$WEB_HOST") return null
        val parts = (uri.path ?: "").split("/").filter { it.isNotEmpty() }
        if (parts.size < 2) return null
        return when (parts[0]) {
            // Le numéro ouvre l'adresse : `150-why-does…` → 150.
            "courses" -> parts[1].takeWhile { it.isDigit() }.toIntOrNull()?.let { WebTarget.CourseNumber(it) }
            "c" -> WebTarget.CourseId(parts[1])
            "authors" -> WebTarget.Creator(parts[1])
            else -> null
        }
    }

    /** L'identifiant complet du cours qui porte ce numéro, parmi ceux du catalogue. */
    fun courseId(number: Int, catalogIds: Collection<String>): String? =
        catalogIds.firstOrNull { courseNumber(it) == number }

    /**
     * Ce que `MainActivity` passe au reste de l'app pour un lien `/courses/<numéro>` : le
     * catalogue n'est pas forcément lu à la réception de l'intent, le numéro est résolu plus tard.
     */
    fun pendingCourseNumber(number: Int): String = "$NUMBER_PREFIX$number"

    /** L'identifiant à ouvrir pour ce qu'a laissé `MainActivity` : tel quel, ou résolu depuis un numéro. */
    fun resolvePendingCourse(pending: String, catalogIds: Collection<String>): String? {
        if (!pending.startsWith(NUMBER_PREFIX)) return pending
        val number = pending.removePrefix(NUMBER_PREFIX).toIntOrNull() ?: return null
        return courseId(number, catalogIds)
    }

    /** Le texte partagé : la phrase habituelle, suivie du lien. */
    fun shareText(message: String, url: String): String = "$message $url"

    private const val NUMBER_PREFIX = "number:"

    private fun escape(segment: String): String = URLEncoder.encode(segment, "UTF-8").replace("+", "%20")
}
