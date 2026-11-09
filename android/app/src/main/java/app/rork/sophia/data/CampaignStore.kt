package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.data.catalog.CatalogStore
import app.rork.sophia.domain.Campaign
import app.rork.sophia.domain.UserProgress
import kotlinx.coroutines.flow.StateFlow
import java.time.LocalDate

/**
 * Les événements éditoriaux (table `campaigns` côté serveur, servis par le manifeste du catalogue,
 * voir docs/evenements.md) et l'état local du lecteur vis-à-vis d'eux : les cours annoncés pour
 * lesquels il a demandé à être prévenu.
 *
 * Rien n'est embarqué : avant le premier manifeste il n'y a pas d'événement. Un écran collecte
 * [flow] pour se recomposer quand le catalogue en apporte.
 */
object CampaignStore {
    private const val PREFS = "sophia_prefs"
    private const val NOTIFY_KEY = "sophia_campaign_notify"

    /** Les événements publiés, du plus ancien au plus récent ; à collecter dans les écrans. */
    val flow: StateFlow<List<Campaign>> get() = CatalogStore.campaigns

    /** Les événements publiés, du plus ancien au plus récent, tels que le catalogue les a reçus. */
    fun all(): List<Campaign> = CatalogStore.campaigns.value

    /** Les événements en cours, le plus proche de sa fin en premier. */
    fun active(today: LocalDate = LocalDate.now()): List<Campaign> =
        all().filter { it.isActive(today) }.sortedBy { it.endDate ?: LocalDate.MAX }

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

    // « Me prévenir »

    private fun notifyId(campaign: Campaign, upcoming: Campaign.Upcoming): String =
        "${campaign.slug}|${upcoming.date}|${upcoming.title["fr"] ?: upcoming.title["en"] ?: ""}"

    private fun stored(context: Context): Set<String> =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getStringSet(NOTIFY_KEY, null)
            ?.toSet()
            .orEmpty()

    fun wantsNotification(context: Context, campaign: Campaign, upcoming: Campaign.Upcoming): Boolean =
        notifyId(campaign, upcoming) in stored(context)

    fun setWantsNotification(context: Context, wants: Boolean, campaign: Campaign, upcoming: Campaign.Upcoming) {
        val id = notifyId(campaign, upcoming)
        val next = stored(context).toMutableSet()
        if (wants) next.add(id) else next.remove(id)
        // Un nouvel ensemble à chaque écriture : `SharedPreferences` ne voit pas une mutation en place.
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putStringSet(NOTIFY_KEY, HashSet(next))
            .apply()
    }
}
