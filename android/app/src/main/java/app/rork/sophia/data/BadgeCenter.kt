package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.data.catalog.CatalogStore
import app.rork.sophia.domain.Badge
import app.rork.sophia.domain.BadgeCatalog
import app.rork.sophia.domain.BadgeCounter
import app.rork.sophia.domain.BadgeMetric
import app.rork.sophia.domain.BadgeRules
import app.rork.sophia.domain.BadgeStats
import app.rork.sophia.domain.Campaign
import app.rork.sophia.domain.DuelHome
import app.rork.sophia.domain.DuelProfile
import app.rork.sophia.domain.UserProgress
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

/**
 * Les badges côté appareil, comme `BadgeCounters` et `BadgeCelebrationCenter` sur iOS
 * (docs/badges.md) : les compteurs que la progression ne contient pas (exploits de duel,
 * meilleure ligue, nombre d'amis), le constat des badges atteints, et la file des badges à fêter.
 *
 * À chaque changement de ce que les badges mesurent (progression enregistrée, compteur relevé,
 * retour de l'app au premier plan), les badges atteints sont enregistrés dans la progression et
 * ceux qui n'ont pas encore été fêtés sont mis en file. Chacun est montré une seule fois, l'un
 * après l'autre, par `BadgeCelebrationHost` quand l'écran est libre.
 *
 * Ce qui n'est pas fêté, pour ne pas noyer le lecteur sous d'anciens exploits : tout ce qui est
 * déjà gagné à la première ouverture avec cette version ; ce qui arrive du cloud (autre
 * appareil, connexion à un compte) ; à la première lecture du serveur, les victoires, la ligue
 * et les amis d'avant ; un événement découvert alors que son défi est déjà rempli ; les paliers
 * intermédiaires franchis d'un coup.
 */
class BadgeCenter(
    context: Context,
    private val progressManager: ProgressManager,
    private val languageManager: LanguageManager,
    private val scope: CoroutineScope,
) {
    private val appContext = context.applicationContext
    private val prefs = appContext.getSharedPreferences("sophia_prefs", Context.MODE_PRIVATE)

    private val _current = MutableStateFlow<Badge?>(null)

    /** Le badge à l'écran, s'il y en a un. */
    val current: StateFlow<Badge?> = _current.asStateFlow()

    private val queue = ArrayList<Badge>()
    private val _pending = MutableStateFlow(0)

    /** Nombre de badges qui attendent d'être fêtés. */
    val pending: StateFlow<Int> = _pending.asStateFlow()

    private var detectionScheduled = false

    init {
        // La progression et les événements publiés : tout changement peut faire gagner un badge.
        scope.launch { progressManager.progress.collect { scheduleDetection() } }
        scope.launch { CatalogStore.campaigns.collect { scheduleDetection() } }
    }

    private val campaigns: List<Campaign> get() = CatalogStore.campaigns.value

    private val duelsVisible: Boolean get() = FeatureFlags.duelsVisible(languageManager.current.value)

    // ---------------------------------------------------------------- compteurs

    fun counter(key: BadgeCounter): Int = prefs.getInt(COUNTER_PREFIX + key.raw, 0)

    /** Ne fait que monter : un compteur est un record. */
    fun raise(key: BadgeCounter, value: Int) {
        if (value <= counter(key)) return
        prefs.edit().putInt(COUNTER_PREFIX + key.raw, value).apply()
        // Un record qui monte peut faire gagner un badge : il sera fêté.
        scheduleDetection()
    }

    /** Les statistiques tenues par le serveur (résultat d'une partie classée). */
    fun sync(profile: DuelProfile) {
        raise(BadgeCounter.DUEL_WINS, profile.wins)
        raise(BadgeCounter.DUEL_BEST_WIN_STREAK, maxOf(profile.winStreak, profile.bestWinStreak))
        raise(BadgeCounter.BEST_LEAGUE, profile.leaguePosition)
    }

    /** L'accueil des duels vient d'être lu. */
    fun sync(home: DuelHome) {
        sync(home.profile)
        home.league(home.profile.bestTrophies)?.let { raise(BadgeCounter.BEST_LEAGUE, it.position) }
        // Première lecture : victoires et ligues d'avant cette version sont attribuées sans fête.
        if (!prefs.getBoolean(DUEL_BASELINE_KEY, false)) {
            absorb { it.family.needsDuels }
            prefs.edit().putBoolean(DUEL_BASELINE_KEY, true).apply()
        }
    }

    /**
     * Une partie vient de finir. Compté une fois par partie. Les exploits (score, écart, question
     * décisive) ne comptent qu'en duel classé ; un duel amical gagné compte pour « Rival ».
     */
    fun recordDuel(
        matchId: String,
        won: Boolean,
        abandoned: Boolean,
        draw: Boolean,
        friendly: Boolean,
        forfeit: Boolean,
        tiebreak: Boolean,
        playerScore: Int,
        opponentScore: Int,
    ) {
        if (prefs.getString(LAST_MATCH_KEY, null) == matchId) return
        prefs.edit().putString(LAST_MATCH_KEY, matchId).apply()
        if (!won || abandoned || draw) return
        if (friendly) {
            raise(BadgeCounter.RIVAL_WINS, counter(BadgeCounter.RIVAL_WINS) + 1)
            return
        }
        // Une victoire par déconnexion compte comme une victoire, pas comme un exploit.
        if (forfeit) return
        raise(BadgeCounter.DUEL_BEST_SCORE, playerScore)
        raise(BadgeCounter.DUEL_BEST_MARGIN, playerScore - opponentScore)
        if (tiebreak) raise(BadgeCounter.DUEL_TIEBREAK_WINS, counter(BadgeCounter.DUEL_TIEBREAK_WINS) + 1)
    }

    /** Le classement des amis vient d'être lu : [count] amis, moi exclu. */
    fun recordFriends(count: Int) {
        raise(BadgeCounter.FRIENDS, count)
        // Première lecture : les amis déjà là sont comptés sans fête.
        if (!prefs.getBoolean(FRIENDS_BASELINE_KEY, false)) {
            absorb { it.metric == BadgeMetric.Friends }
            prefs.edit().putBoolean(FRIENDS_BASELINE_KEY, true).apply()
        }
    }

    // ---------------------------------------------------------------- mesures

    /** Les valeurs courantes de toutes les mesures, pour cette progression. */
    fun stats(progress: UserProgress = progressManager.progress.value): BadgeStats {
        val subjects = ContentCatalog.cachedSummaries(languageManager.current.value)?.associate { it.id to it.subject }.orEmpty()
        return BadgeStats(progress = progress, campaigns = campaigns, subjectOf = { subjects[it] }, counter = ::counter)
    }

    /** Tous les badges montrés dans la langue de l'app, par famille. */
    fun visibleBadges(): List<Badge> = BadgeCatalog.all(campaigns, duelsVisible)

    /** Un badge par son identifiant, quelle que soit la langue. */
    fun badge(id: String): Badge? = BadgeCatalog.everything(campaigns).firstOrNull { it.id == id }

    /** Enregistre les badges dont la cible vient d'être atteinte (avec la date du moment). */
    fun refresh() {
        val progress = progressManager.progress.value
        val stats = stats(progress)
        val reached = BadgeCatalog.everything(campaigns).filter { it.id !in progress.earnedBadges && stats.isReached(it) }
        progressManager.recordEarnedBadges(reached.map { it.id })
    }

    // ---------------------------------------------------------------- fête

    /**
     * Quelque chose que les badges mesurent vient de changer. Les appels rapprochés sont
     * regroupés : la vérification a lieu une fois, au prochain tour de la boucle principale.
     */
    fun scheduleDetection() {
        if (detectionScheduled) return
        detectionScheduled = true
        scope.launch {
            detectionScheduled = false
            detect()
        }
    }

    /**
     * Marque comme déjà fêtés, sans animation, les badges atteints ou gagnés à cet instant (ceux
     * que [matching] retient).
     */
    fun absorb(progress: UserProgress = progressManager.progress.value, matching: (Badge) -> Boolean = { true }) {
        // Jamais vérifié : la première vérification marquera tout ce qui est déjà gagné.
        val celebrated = storedSet(CELEBRATED_KEY) ?: return
        val stats = stats(progress)
        val ids = BadgeCatalog.everything(campaigns)
            .filter { matching(it) && (it.id in progress.earnedBadges || stats.isReached(it)) }
            .map { it.id }
        store(celebrated + ids, CELEBRATED_KEY)
    }

    /** Le lecteur a fermé la fête en cours. */
    fun dismissCurrent() {
        _current.value = null
    }

    /** Montre le badge suivant de la file. Appelé par l'hôte quand l'écran est libre. */
    fun presentNext() {
        if (_current.value != null || queue.isEmpty()) return
        val badge = queue.removeAt(0)
        _pending.value = queue.size
        // Fêté dès qu'il est à l'écran : une app tuée avant ne le rejouera pas.
        store(storedSet(CELEBRATED_KEY).orEmpty() + badge.id, CELEBRATED_KEY)
        _current.value = badge
    }

    private fun detect() {
        refresh()
        val earned = progressManager.progress.value.earnedBadges.keys
        val catalog = BadgeCatalog.everything(campaigns)
        val eventIds = BadgeCatalog.events(campaigns).map { it.id }.toSet()

        var celebrated = storedSet(CELEBRATED_KEY)
        if (celebrated == null) {
            // Première ouverture avec cette version : rien de ce qui est déjà gagné n'est fêté.
            store(earned, CELEBRATED_KEY)
            store(eventIds, KNOWN_EVENTS_KEY)
            return
        }

        // Un événement vu pour la première fois et déjà rempli : gagné avant, pas à l'instant.
        val known = storedSet(KNOWN_EVENTS_KEY).orEmpty()
        val unseen = eventIds - known
        if (unseen.isNotEmpty()) {
            celebrated = celebrated + unseen.intersect(earned)
            store(known + unseen, KNOWN_EVENTS_KEY)
        }

        // Un badge retiré de la progression (remise à zéro) pourra être fêté de nouveau.
        celebrated = celebrated.intersect(earned)

        val waiting = queue.map { it.id }.toMutableSet()
        _current.value?.let { waiting += it.id }
        val showDuels = duelsVisible
        val fresh = ArrayList<Badge>()
        val silent = HashSet<String>()
        for (badge in catalog) {
            if (badge.id !in earned || badge.id in celebrated || badge.id in waiting) continue
            // Famille absente de la page des badges dans cette langue : rien à montrer.
            if (badge.family.needsDuels && !showDuels) silent += badge.id else fresh += badge
        }
        val (winners, skipped) = BadgeRules.winners(fresh)
        store(celebrated + silent + skipped.map { it.id }, CELEBRATED_KEY)
        if (winners.isEmpty()) return
        queue += winners
        _pending.value = queue.size
    }

    // ---------------------------------------------------------------- stockage

    private fun storedSet(key: String): Set<String>? = prefs.getStringSet(key, null)?.toSet()

    private fun store(set: Set<String>, key: String) {
        // Un nouvel ensemble à chaque écriture : `SharedPreferences` ne voit pas une mutation en place.
        prefs.edit().putStringSet(key, HashSet(set)).apply()
    }

    companion object {
        private const val COUNTER_PREFIX = "sophia_badge_counter_"
        private const val LAST_MATCH_KEY = "sophia_badge_last_match"
        private const val DUEL_BASELINE_KEY = "sophia_badge_baseline_duels"
        private const val FRIENDS_BASELINE_KEY = "sophia_badge_baseline_friends"
        private const val CELEBRATED_KEY = "sophia_badge_celebrated_ids"
        private const val KNOWN_EVENTS_KEY = "sophia_badge_known_event_ids"
    }
}
