package app.rork.sophia.data

import app.rork.sophia.data.catalog.CatalogStore
import app.rork.sophia.domain.Campaign
import app.rork.sophia.domain.UserProgress
import kotlinx.coroutines.flow.StateFlow
import java.time.LocalDate
import java.util.Locale

/**
 * Les événements éditoriaux (table `campaigns` côté serveur, servis par le manifeste du catalogue,
 * voir docs/evenements.md) et l'état local du lecteur vis-à-vis d'eux : les cours annoncés pour
 * lesquels il a demandé à être prévenu.
 *
 * Rien n'est embarqué : avant le premier manifeste il n'y a pas d'événement. Un écran collecte
 * [flow] pour se recomposer quand le catalogue en apporte.
 */
object CampaignStore {
    /** Les événements publiés, du plus ancien au plus récent ; à collecter dans les écrans. */
    val flow: StateFlow<List<Campaign>> get() = CatalogStore.campaigns

    /** Les événements publiés pour la région du téléphone, du plus ancien au plus récent. */
    fun all(): List<Campaign> {
        val region = Locale.getDefault().country.takeIf { it.length == 2 }
        return CatalogStore.campaigns.value.filter { it.isShownIn(region) }
    }

    /** Les événements en cours, le plus proche de sa fin en premier. */
    fun active(today: LocalDate = LocalDate.now()): List<Campaign> =
        all().filter { it.isActive(today) }.sortedBy { it.endDate ?: LocalDate.MAX }

    /**
     * Les événements terminés que le serveur sert encore, du plus récent au plus ancien. Ils
     * disparaissent d'eux-mêmes quand ils ne sont plus publiés.
     */
    fun ended(today: LocalDate = LocalDate.now()): List<Campaign> =
        all().filter { it.hasEnded(today) }.sortedByDescending { it.endDate ?: LocalDate.MIN }

    fun campaign(slug: String): Campaign? = all().firstOrNull { it.slug == slug }

    /** L'événement actif dont la collection contient ce cours, pour l'étiquette sur les cartes. */
    fun activeCampaign(courseId: String, today: LocalDate = LocalDate.now()): Campaign? =
        active(today).firstOrNull { courseId in it.courseIds }

    /** Cours de la collection terminés par le lecteur, dans la limite du défi. */
    fun challengeProgress(campaign: Campaign, progress: UserProgress): Int {
        val completed = campaign.courseIds.count { progress.courseProgress[it]?.isCompleted == true }
        return minOf(completed, campaign.challengeTarget)
    }

    fun isChallengeComplete(campaign: Campaign, progress: UserProgress): Boolean =
        challengeProgress(campaign, progress) >= campaign.challengeTarget
}
