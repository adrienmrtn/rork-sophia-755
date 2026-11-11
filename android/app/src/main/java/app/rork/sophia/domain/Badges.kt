package app.rork.sophia.domain

import java.time.Instant
import java.time.ZoneId

/*
 * Les badges du profil (docs/badges.md), comme `Badges.swift` sur iOS.
 *
 * Trois sortes : les badges permanents (série, lecture, matières, quiz, duels, social), un badge
 * par ligue de duel atteinte, un badge par événement. Un badge est gagné quand sa mesure atteint
 * sa cible ; il est alors enregistré avec sa date dans la progression
 * (`UserProgress.earnedBadges`) et ne se perd plus. Le lecteur en choisit trois au plus à
 * afficher sur son profil. Mêmes identifiants et mêmes cibles qu'iOS : la progression est
 * partagée entre les deux apps.
 */

enum class BadgeFamily(val raw: String) {
    STREAK("streak"), READING("reading"), SUBJECTS("subjects"), QUIZ("quiz"),
    DUELS("duels"), LEAGUES("leagues"), SOCIAL("social"), EVENTS("events");

    val titleKey: String get() = "badges.family.$raw"

    /** Duels et ligues n'existent que là où l'onglet Duels est ouvert. */
    val needsDuels: Boolean get() = this == DUELS || this == LEAGUES
}

/** Ce qu'un badge mesure. La valeur courante vient de [BadgeStats]. */
sealed class BadgeMetric {
    data object Streak : BadgeMetric()
    data object Courses : BadgeMetric()
    data object EarlyCourse : BadgeMetric()
    data object LateCourse : BadgeMetric()
    data object CoursesInOneDay : BadgeMetric()
    data class SubjectCourses(val key: String) : BadgeMetric()
    data object SubjectsCovered : BadgeMetric()
    data object Quizzes : BadgeMetric()
    data object DuelWins : BadgeMetric()
    data object DuelBestScore : BadgeMetric()
    data object DuelBestMargin : BadgeMetric()
    data object DuelTiebreakWins : BadgeMetric()
    data object DuelBestWinStreak : BadgeMetric()
    data object RivalWins : BadgeMetric()
    data object Follows : BadgeMetric()
    data object Likes : BadgeMetric()
    data object Friends : BadgeMetric()
    data object League : BadgeMetric()
    data class Event(val slug: String) : BadgeMetric()
}

data class Badge(
    val id: String,
    val family: BadgeFamily,
    val metric: BadgeMetric,
    val target: Int,
    /** Symbole SF d'iOS, traduit en icône à l'affichage tant que l'illustration n'est pas là. */
    val symbol: String,
    /** Illustration embarquée (papier découpé) : le nom de la ressource, en minuscules. */
    val imageName: String? = null,
    /** Illustration hébergée (badges d'événement, choisie dans l'admin du site). */
    val imageUrl: String? = null,
    /** Badge de ligue : le nom de la figure (« Vermeer »). */
    val leagueName: String? = null,
    /** Badge d'événement : son nom et le titre de l'événement, par langue. */
    val eventNames: Map<String, String>? = null,
    val eventTitles: Map<String, String>? = null,
)

object BadgeCatalog {
    private fun make(id: String, family: BadgeFamily, metric: BadgeMetric, target: Int, symbol: String) =
        Badge(id = id, family = family, metric = metric, target = target, symbol = symbol, imageName = "badge_${id.lowercase()}")

    /** Les 35 badges permanents, dans l'ordre d'affichage. */
    val permanent: List<Badge> = listOf(
        make("streak_3", BadgeFamily.STREAK, BadgeMetric.Streak, 3, "sparkle"),
        make("streak_7", BadgeFamily.STREAK, BadgeMetric.Streak, 7, "flame.fill"),
        make("streak_30", BadgeFamily.STREAK, BadgeMetric.Streak, 30, "flame.fill"),
        make("streak_100", BadgeFamily.STREAK, BadgeMetric.Streak, 100, "flame.circle.fill"),
        make("streak_365", BadgeFamily.STREAK, BadgeMetric.Streak, 365, "bird.fill"),

        make("courses_1", BadgeFamily.READING, BadgeMetric.Courses, 1, "figure.walk"),
        make("courses_10", BadgeFamily.READING, BadgeMetric.Courses, 10, "book.fill"),
        make("courses_50", BadgeFamily.READING, BadgeMetric.Courses, 50, "books.vertical.fill"),
        make("courses_100", BadgeFamily.READING, BadgeMetric.Courses, 100, "building.columns.fill"),
        make("early", BadgeFamily.READING, BadgeMetric.EarlyCourse, 1, "sunrise.fill"),
        make("late", BadgeFamily.READING, BadgeMetric.LateCourse, 1, "moon.stars.fill"),
        make("binge", BadgeFamily.READING, BadgeMetric.CoursesInOneDay, 5, "square.stack.3d.up.fill"),

        make("subject_histoire", BadgeFamily.SUBJECTS, BadgeMetric.SubjectCourses("histoire"), 10, "hourglass"),
        make("subject_sciences", BadgeFamily.SUBJECTS, BadgeMetric.SubjectCourses("sciences"), 10, "atom"),
        make("subject_litterature", BadgeFamily.SUBJECTS, BadgeMetric.SubjectCourses("litterature"), 10, "text.book.closed.fill"),
        make("subject_art", BadgeFamily.SUBJECTS, BadgeMetric.SubjectCourses("art"), 10, "paintpalette.fill"),
        make("subject_mythologie", BadgeFamily.SUBJECTS, BadgeMetric.SubjectCourses("mythologie"), 10, "bolt.fill"),
        make("subject_comprendreLeMonde", BadgeFamily.SUBJECTS, BadgeMetric.SubjectCourses("comprendreLeMonde"), 10, "globe.europe.africa.fill"),
        make("all_subjects", BadgeFamily.SUBJECTS, BadgeMetric.SubjectsCovered, 6, "seal.fill"),

        make("quiz_10", BadgeFamily.QUIZ, BadgeMetric.Quizzes, 10, "checkmark.circle.fill"),
        make("quiz_50", BadgeFamily.QUIZ, BadgeMetric.Quizzes, 50, "graduationcap.fill"),

        make("duel_first", BadgeFamily.DUELS, BadgeMetric.DuelWins, 1, "star.fill"),
        make("duel_wins_10", BadgeFamily.DUELS, BadgeMetric.DuelWins, 10, "figure.fencing"),
        make("duel_wins_50", BadgeFamily.DUELS, BadgeMetric.DuelWins, 50, "trophy.fill"),
        make("duel_wins_200", BadgeFamily.DUELS, BadgeMetric.DuelWins, 200, "crown.fill"),
        make("duel_perfect", BadgeFamily.DUELS, BadgeMetric.DuelBestScore, 20, "target"),
        make("duel_near", BadgeFamily.DUELS, BadgeMetric.DuelBestScore, 18, "scope"),
        make("duel_margin", BadgeFamily.DUELS, BadgeMetric.DuelBestMargin, 10, "water.waves"),
        make("duel_tiebreak", BadgeFamily.DUELS, BadgeMetric.DuelTiebreakWins, 1, "snowflake"),
        make("duel_streak_5", BadgeFamily.DUELS, BadgeMetric.DuelBestWinStreak, 5, "shield.fill"),
        make("duel_streak_10", BadgeFamily.DUELS, BadgeMetric.DuelBestWinStreak, 10, "shield.lefthalf.filled"),
        make("duel_rival", BadgeFamily.DUELS, BadgeMetric.RivalWins, 1, "person.2.fill"),

        make("follows_3", BadgeFamily.SOCIAL, BadgeMetric.Follows, 3, "lamp.desk.fill"),
        make("likes_10", BadgeFamily.SOCIAL, BadgeMetric.Likes, 10, "heart.fill"),
        make("friends_3", BadgeFamily.SOCIAL, BadgeMetric.Friends, 3, "person.3.fill"),
    )

    /** Les 30 ligues de duel, dans l'ordre (table `duel_leagues`) : identifiant et figure. */
    private val leagueFigures = listOf(
        "aesop" to "Aesop", "homer" to "Homer", "sappho" to "Sappho", "confucius" to "Confucius",
        "socrates" to "Socrates", "cleopatra" to "Cleopatra", "hypatia" to "Hypatia", "avicenna" to "Avicenna",
        "murasaki" to "Murasaki", "mansa_musa" to "Mansa Musa", "dante" to "Dante", "joan_of_arc" to "Joan of Arc",
        "gutenberg" to "Gutenberg", "leonardo" to "Leonardo", "michelangelo" to "Michelangelo", "copernicus" to "Copernicus",
        "shakespeare" to "Shakespeare", "galileo" to "Galileo", "vermeer" to "Vermeer", "newton" to "Newton",
        "mozart" to "Mozart", "napoleon" to "Napoleon", "austen" to "Austen", "darwin" to "Darwin",
        "lovelace" to "Lovelace", "van_gogh" to "Van Gogh", "curie" to "Curie", "einstein" to "Einstein",
        "kahlo" to "Kahlo", "sophia" to "Sophia",
    )

    /** Un badge par ligue : le buste de sa figure, gagné en atteignant la ligue. */
    val leagues: List<Badge> = leagueFigures.mapIndexed { index, (slug, name) ->
        val position = index + 1
        Badge(
            id = "league_$slug",
            family = BadgeFamily.LEAGUES,
            metric = BadgeMetric.League,
            target = position,
            symbol = "person.crop.circle.fill",
            imageName = "badge_league_%02d_%s".format(position, slug),
            leagueName = name,
        )
    }

    /** Un badge par événement publié, du plus récent au plus ancien. */
    fun events(campaigns: List<Campaign>): List<Badge> = campaigns.reversed().map { campaign ->
        Badge(
            id = "event_${campaign.slug}",
            family = BadgeFamily.EVENTS,
            metric = BadgeMetric.Event(campaign.slug),
            target = campaign.challengeTarget,
            symbol = campaign.symbol ?: "sparkles",
            imageUrl = campaign.badgeImageUrl,
            eventNames = campaign.badgeName,
            eventTitles = campaign.title,
        )
    }

    /** Tout le catalogue, quelle que soit la langue (évaluation, profil d'un ami). */
    fun everything(campaigns: List<Campaign>): List<Badge> = permanent + leagues + events(campaigns)

    /** Tous les badges montrés quand les duels sont visibles ou non, par famille. */
    fun all(campaigns: List<Campaign>, duelsVisible: Boolean): List<Badge> =
        everything(campaigns).filter { duelsVisible || !it.family.needsDuels }
}

/** Les compteurs que la progression ne contient pas (exploits de duel, meilleure ligue, amis). */
enum class BadgeCounter(val raw: String) {
    DUEL_WINS("duelWins"), DUEL_BEST_SCORE("duelBestScore"), DUEL_BEST_MARGIN("duelBestMargin"),
    DUEL_TIEBREAK_WINS("duelTiebreakWins"), DUEL_BEST_WIN_STREAK("duelBestWinStreak"),
    RIVAL_WINS("rivalWins"), BEST_LEAGUE("bestLeague"), FRIENDS("friends"),
}

/**
 * Les valeurs courantes de toutes les mesures, lues une fois pour évaluer tous les badges.
 * [subjectOf] donne la matière d'un cours (catalogue de la langue) ; [counter] les compteurs
 * gardés sur l'appareil.
 */
class BadgeStats(
    private val progress: UserProgress,
    private val campaigns: List<Campaign>,
    private val subjectOf: (String) -> String?,
    private val counter: (BadgeCounter) -> Int,
    zone: ZoneId = ZoneId.systemDefault(),
) {
    private val completed = progress.courseProgress.filterValues { it.isCompleted }
    private val completionTimes = completed.values.mapNotNull { entry ->
        entry.completedAt?.let { runCatching { Instant.parse(it).atZone(zone) }.getOrNull() }
    }
    private val perSubject: Map<String, Int> by lazy {
        completed.keys.mapNotNull(subjectOf).groupingBy { it }.eachCount()
    }

    fun value(metric: BadgeMetric): Int = when (metric) {
        BadgeMetric.Streak -> progress.streak
        BadgeMetric.Courses -> completed.size
        BadgeMetric.EarlyCourse -> if (completionTimes.any { it.hour < 8 }) 1 else 0
        BadgeMetric.LateCourse -> if (completionTimes.any { it.hour >= 23 }) 1 else 0
        BadgeMetric.CoursesInOneDay -> completionTimes.groupingBy { it.toLocalDate() }.eachCount().values.maxOrNull() ?: 0
        is BadgeMetric.SubjectCourses -> perSubject[metric.key] ?: 0
        BadgeMetric.SubjectsCovered -> perSubject.count { it.value > 0 }
        BadgeMetric.Quizzes -> progress.completedQuizCourseIds.size
        BadgeMetric.DuelWins -> counter(BadgeCounter.DUEL_WINS)
        BadgeMetric.DuelBestScore -> counter(BadgeCounter.DUEL_BEST_SCORE)
        BadgeMetric.DuelBestMargin -> counter(BadgeCounter.DUEL_BEST_MARGIN)
        BadgeMetric.DuelTiebreakWins -> counter(BadgeCounter.DUEL_TIEBREAK_WINS)
        BadgeMetric.DuelBestWinStreak -> counter(BadgeCounter.DUEL_BEST_WIN_STREAK)
        BadgeMetric.RivalWins -> counter(BadgeCounter.RIVAL_WINS)
        BadgeMetric.Follows -> progress.followedCreatorSlugs.size
        BadgeMetric.Likes -> progress.likedCourseIds.size
        BadgeMetric.Friends -> counter(BadgeCounter.FRIENDS)
        BadgeMetric.League -> counter(BadgeCounter.BEST_LEAGUE)
        is BadgeMetric.Event -> campaigns.firstOrNull { it.slug == metric.slug }?.let { campaign ->
            minOf(campaign.courseIds.count { progress.courseProgress[it]?.isCompleted == true }, campaign.challengeTarget)
        } ?: 0
    }

    /** La valeur bornée à la cible, pour la barre de progression (« 4 sur 10 »). */
    fun progress(badge: Badge): Int = minOf(value(badge.metric), badge.target)

    fun isReached(badge: Badge): Boolean = value(badge.metric) >= badge.target
}

/** Les règles des badges sans rien de l'appareil, pour être vérifiées par des tests. */
object BadgeRules {
    const val MAX_FEATURED = 3

    /**
     * Parmi les badges qui viennent d'être gagnés, ceux à fêter : plusieurs paliers d'une même
     * mesure franchis d'un coup ne donnent qu'une fête, celle du plus haut ; jamais plus de
     * [maxBatch] d'affilée. Rend (à fêter, à marquer fêtés sans bruit).
     */
    fun winners(fresh: List<Badge>, maxBatch: Int = 5): Pair<List<Badge>, List<Badge>> {
        val kept = fresh.filter { badge -> fresh.filter { it.metric == badge.metric }.maxByOrNull { it.target }?.id == badge.id }
        val shown = kept.take(maxBatch)
        return shown to (fresh - shown.toSet())
    }

    /**
     * Les trois badges du profil : ceux choisis, puis les derniers gagnés, puis les plus proches
     * d'être gagnés (hors ligues).
     */
    fun profileBadges(all: List<Badge>, progress: UserProgress, stats: BadgeStats): List<Badge> {
        val earned = progress.earnedBadges
        val picked = progress.featuredBadgeIds.filter { it in earned }.mapNotNull { id -> all.firstOrNull { it.id == id } }.toMutableList()
        picked += all.filter { it.id in earned && it !in picked }.sortedByDescending { earned[it.id].orEmpty() }
        if (picked.size < MAX_FEATURED) {
            picked += all
                .filter { it.id !in earned && it.metric != BadgeMetric.League }
                .sortedByDescending { stats.progress(it).toDouble() / maxOf(it.target, 1) }
        }
        return picked.take(MAX_FEATURED)
    }
}
