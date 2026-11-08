package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.domain.Campaign
import app.rork.sophia.domain.UserProgress
import kotlinx.serialization.json.Json
import java.time.LocalDate

/**
 * Les événements embarqués (`assets/events/*.json`) et l'état local du lecteur vis-à-vis
 * d'eux : les cours annoncés pour lesquels il a demandé à être prévenu.
 *
 * Le serveur prendra le relais au prompt 6 (table `campaigns`, `campaign_progress`) ; l'API
 * est écrite pour que seul ce fichier change à ce moment-là.
 */
object CampaignStore {
    private const val PREFS = "sophia_prefs"
    private const val NOTIFY_KEY = "sophia_campaign_notify"
    private const val EVENTS_DIR = "events"

    private val json = Json { ignoreUnknownKeys = true; isLenient = true }

    @Volatile
    private var loaded: List<Campaign>? = null

    fun resetCache() {
        loaded = null
    }

    /** Tous les événements embarqués, du plus ancien au plus récent. Lecture unique des assets. */
    fun all(context: Context): List<Campaign> {
        loaded?.let { return it }
        synchronized(this) {
            loaded?.let { return it }
            val campaigns = load(context)
            loaded = campaigns
            return campaigns
        }
    }

    /** Les événements en cours, le plus proche de sa fin en premier. */
    fun active(context: Context, today: LocalDate = LocalDate.now()): List<Campaign> =
        all(context).filter { it.isActive(today) }
            .sortedBy { it.endDate ?: LocalDate.MAX }

    fun campaign(context: Context, slug: String): Campaign? = all(context).firstOrNull { it.slug == slug }

    /** L'événement actif dont la collection contient ce cours, pour l'étiquette sur les cartes. */
    fun activeCampaign(context: Context, courseId: String, today: LocalDate = LocalDate.now()): Campaign? =
        active(context, today).firstOrNull { courseId in it.courseIds }

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

    // Chargement

    private fun load(context: Context): List<Campaign> {
        val names = try {
            context.assets.list(EVENTS_DIR)?.filter { it.endsWith(".json") }.orEmpty()
        } catch (_: Exception) {
            emptyList()
        }
        return names.mapNotNull { name ->
            try {
                val text = context.assets.open("$EVENTS_DIR/$name").bufferedReader().use { it.readText() }
                json.decodeFromString(Campaign.serializer(), text)
            } catch (_: Exception) {
                null
            }
        }.sortedBy { it.startsAt }
    }
}
