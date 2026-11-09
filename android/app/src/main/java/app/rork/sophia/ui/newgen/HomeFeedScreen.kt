package app.rork.sophia.ui.newgen

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.pager.PageSize
import androidx.compose.foundation.pager.VerticalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.outlined.LocalFireDepartment
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.AuthorStore
import app.rork.sophia.data.CampaignStore
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.CourseAffinityStore
import app.rork.sophia.data.CourseAuthor
import app.rork.sophia.data.CourseImagePrefetch
import app.rork.sophia.data.DeckSkipStore
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.analytics.Analytics
import app.rork.sophia.data.catalog.CatalogStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Campaign
import app.rork.sophia.domain.CourseAffinity
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.DeckContext
import app.rork.sophia.domain.HomeDeckBuilder
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.components.AnimatedFlameBadge
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * L'accueil « nouvelle génération » : un fil **paginé**, une carte par écran, qu'on fait
 * défiler d'un geste vertical comme un réseau vidéo (la carte suivante dépasse un peu en bas
 * pour dire qu'il y en a d'autres). L'en-tête et le segment « Pour toi / Abonnements » restent
 * fixes en haut. « Pour toi » est le deck local de [HomeDeckBuilder], avec l'événement en cours
 * et l'invitation à créer glissés dedans ; « Abonnements », les cours des créateurs suivis.
 *
 * La page courante compte une impression après une seconde, et un passage si on la quitte
 * sans l'avoir ouverte (docs/events.md).
 */
@OptIn(ExperimentalFoundationApi::class, ExperimentalMaterial3Api::class)
@Composable
fun HomeFeedScreen(
    modifier: Modifier = Modifier,
    language: AppLanguage,
    progress: UserProgress,
    progressManager: ProgressManager,
    isPremium: Boolean,
    onOpenCourse: (CourseSummary) -> Unit,
    onOpenCreator: (CourseAuthor) -> Unit,
    onOpenCampaign: (Campaign) -> Unit,
    onSearch: () -> Unit,
    onBecomeCreator: () -> Unit,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val skipStore = remember { DeckSkipStore(context.applicationContext) }
    val haptics = LocalHapticFeedback.current
    val completedCount = progress.courseProgress.count { it.value.isCompleted }

    var segment by remember { mutableIntStateOf(HomeFeedSession.segment) }
    var deck by remember(language) { mutableStateOf(HomeFeedSession.restore(language, completedCount)) }
    var deckReady by remember(language) { mutableStateOf(deck.isNotEmpty()) }
    var inviteDismissed by remember { mutableStateOf(HomeFeedSession.isInviteDismissed(context)) }
    // Tirer vers le bas : le catalogue est relu (nouveaux cours, événements), le deck redistribué.
    val refreshScope = rememberCoroutineScope()
    var refreshing by remember { mutableStateOf(false) }

    /** Le deck, à partir des mêmes signaux que l'accueil classique (`HomeTikTokScreen`). */
    fun buildDeck(summaries: List<CourseSummary>): List<CourseSummary> {
        val current = app.progressManager.progress.value
        val deckContext = DeckContext.from(
            progress = current,
            catalogue = summaries,
            objectiveSubjects = app.onboardingStore.answers().topics.toSet(),
            skipCounts = skipStore.counts(),
        )
        return HomeDeckBuilder.deck(
            courses = summaries,
            affinity = CourseAffinityStore.cached() ?: CourseAffinity.NONE,
            context = deckContext,
            isCompleted = { current.courseProgress[it]?.isCompleted == true },
        )
    }

    // Un deck par visite ; redistribué quand la langue change ou qu'un cours a été terminé
    // (comme `onChange(of: completedCount)` sur iOS), gardé sinon d'un onglet à l'autre.
    LaunchedEffect(language, completedCount) {
        if (deckReady && HomeFeedSession.matches(language, completedCount)) return@LaunchedEffect
        val summaries = ContentCatalog.summariesAsync(context.applicationContext, language)
        CourseAffinityStore.load(context.applicationContext)
        withContext(Dispatchers.IO) { AuthorStore.preload(context.applicationContext) }
        val built = withContext(Dispatchers.Default) { buildDeck(summaries) }
        HomeFeedSession.save(language, completedCount, built)
        deck = built
        deckReady = true
        CourseImagePrefetch.warmCovers(context.applicationContext, built.take(6).map { it.id })
        // Les paquets des premières cartes se téléchargent en avance (huit au plus, comme sur
        // iOS), pour que le lecteur s'ouvre sans attendre le réseau.
        CatalogStore.prefetch(built.take(8).map { it.id }, language)
    }

    // Les événements arrivent avec le manifeste du catalogue, parfois après le deck : on les collecte.
    val campaigns by CampaignStore.flow.collectAsState()
    val activeCampaign = remember(deckReady, campaigns) { CampaignStore.active().firstOrNull() }
    val authors = remember(deckReady) { AuthorStore.all(context.applicationContext) }

    /** Le deck, l'événement en troisième position et l'invitation en septième. */
    val forYouItems = remember(deck, deckReady, activeCampaign, inviteDismissed) {
        if (deckReady && deck.isEmpty()) return@remember listOf<FeedItem>(FeedItem.Notice(FeedNotice.ALL_CAUGHT_UP))
        val items = ArrayList<FeedItem>(deck.size + 2)
        deck.forEach { items += FeedItem.CourseCard(it) }
        if (activeCampaign != null) items.add(minOf(2, items.size), FeedItem.CampaignCard(activeCampaign))
        if (!inviteDismissed && items.size >= 4) items.add(minOf(6, items.size), FeedItem.CreatorInvite)
        items.toList()
    }

    val followedAuthors = remember(progress.followedCreatorSlugs, authors) {
        progress.followedCreatorSlugs.mapNotNull { slug -> authors.firstOrNull { it.slug == slug } }
    }
    /** Les cours des créateurs suivis, ceux pas encore lus en premier. */
    val followingCourses = remember(followedAuthors, deckReady, progress.courseProgress) {
        val ids = followedAuthors.flatMap { it.courseIds }
        val courses = ids.mapNotNull { ContentCatalog.cachedSummaries(language)?.firstOrNull { s -> s.id == it } }
        val unread = courses.filter { progress.courseProgress[it.id]?.isCompleted != true }
        val read = courses.filter { progress.courseProgress[it.id]?.isCompleted == true }
        unread + read
    }
    val followingHasUnread = followedAuthors.isNotEmpty() &&
        followingCourses.any { progress.courseProgress[it.id]?.isCompleted != true }

    /** Les pages de l'onglet Abonnements, précédées d'un mot quand tout est lu. */
    val followingItems = remember(followedAuthors, followingCourses, progress.courseProgress) {
        if (followedAuthors.isEmpty()) return@remember listOf<FeedItem>(FeedItem.Notice(FeedNotice.FOLLOWING_EMPTY))
        val items = ArrayList<FeedItem>(followingCourses.size + 1)
        if (followingCourses.all { progress.courseProgress[it.id]?.isCompleted == true }) {
            items += FeedItem.Notice(FeedNotice.FOLLOWING_UP_TO_DATE)
        }
        followingCourses.forEach { items += FeedItem.CourseCard(it) }
        items.toList()
    }

    val pages = if (segment == 0) forYouItems else followingItems
    val screen = if (segment == 0) "home" else "home_following"
    val latestPages = rememberUpdatedState(pages)
    val pagerState = rememberPagerState { latestPages.value.size }

    fun open(course: CourseSummary, position: Int) {
        HomeFeedSession.opened.add(course.id)
        skipStore.clear(course.id)
        Analytics.log(
            "card_open",
            courseId = course.id,
            screen = screen,
            position = position,
            algoVersion = Analytics.ALGO_VERSION,
        )
        onOpenCourse(course)
    }

    /** Vue puis quittée sans être ouverte : un passage, qui nourrit la fatigue du deck. */
    fun cardLeft(courseId: String, position: Int) {
        if (courseId in HomeFeedSession.impressed &&
            courseId !in HomeFeedSession.opened &&
            HomeFeedSession.skipped.add(courseId)
        ) {
            skipStore.registerSkip(courseId)
            Analytics.log("card_skip", courseId = courseId, screen = screen, position = position, algoVersion = Analytics.ALGO_VERSION)
        }
    }

    // Changement de segment : on repart de la première page.
    LaunchedEffect(segment) {
        if (pagerState.currentPage != 0) pagerState.scrollToPage(0)
    }

    // La page qui part sans avoir été ouverte est un passage ; une légère vibration accompagne
    // chaque swipe.
    LaunchedEffect(pages, screen) {
        var previous = pagerState.settledPage
        snapshotFlow { pagerState.settledPage }.collect { page ->
            if (page != previous) {
                pages.getOrNull(previous)?.courseId?.let { id -> cardLeft(id, previous) }
                haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                previous = page
            }
        }
    }

    // La page qui arrive compte comme vue après une seconde (docs/events.md). Le gain par
    // balayage de l'offre découverte suit l'impression, comme sur iOS.
    val settledPage = pagerState.settledPage
    LaunchedEffect(settledPage, pages, screen) {
        val courseId = pages.getOrNull(settledPage)?.courseId ?: return@LaunchedEffect
        if (courseId in HomeFeedSession.impressed) return@LaunchedEffect
        delay(1000)
        if (!HomeFeedSession.impressed.add(courseId)) return@LaunchedEffect
        Analytics.log("card_impression", courseId = courseId, screen = screen, position = settledPage, algoVersion = Analytics.ALGO_VERSION)
        if (!isPremium) app.discountManager.registerSwipe()
    }

    Column(modifier = modifier.fillMaxSize().background(DS.canvas)) {
        FeedHeader(
            language = language,
            streak = progress.streak,
            onSearch = onSearch,
            modifier = Modifier.padding(start = 20.dp, end = 20.dp, top = 8.dp),
        )
        SegmentedPills(
            items = listOf(
                StringStore.text(context, "home.segment.forYou", language),
                StringStore.text(context, "home.segment.following", language),
            ),
            selection = segment,
            onSelect = {
                segment = it
                HomeFeedSession.segment = it
            },
            dotOn = if (followingHasUnread) 1 else null,
            modifier = Modifier.padding(horizontal = 20.dp).padding(top = 12.dp, bottom = 10.dp),
        )
        if (segment == 1 && followedAuthors.isNotEmpty()) {
            FollowedCreatorsRow(
                authors = followedAuthors,
                language = language,
                onOpen = onOpenCreator,
                onDiscover = onSearch,
                modifier = Modifier.padding(horizontal = 20.dp).padding(bottom = 6.dp),
            )
        }

        if (segment == 0 && !deckReady) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = DS.accent)
            }
        } else {
            PullToRefreshBox(
                isRefreshing = refreshing,
                onRefresh = {
                    refreshScope.launch {
                        refreshing = true
                        CatalogStore.refresh(context.applicationContext, language, force = true)
                        val summaries = ContentCatalog.summariesAsync(context.applicationContext, language)
                        val built = withContext(Dispatchers.Default) { buildDeck(summaries) }
                        HomeFeedSession.save(language, completedCount, built)
                        deck = built
                        deckReady = true
                        refreshing = false
                    }
                },
                modifier = Modifier.fillMaxWidth().weight(1f),
            ) {
            BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
                // Ce que la carte suivante laisse voir en bas de l'écran.
                val peek = 44.dp
                val pageHeight = (maxHeight - peek).coerceAtLeast(320.dp)
                // La couverture garde son 16:9 tant que la page est assez haute ; sur un petit
                // écran elle se raccourcit pour laisser la place au texte et aux compteurs.
                val coverHeight = minOf((maxWidth - 32.dp) * 9f / 16f, pageHeight * 0.42f)
                VerticalPager(
                    state = pagerState,
                    modifier = Modifier.fillMaxSize(),
                    pageSize = PageSize.Fixed(pageHeight),
                    // L'espace de fin laisse la dernière page s'aligner en haut, et c'est dans
                    // cette marge que la page suivante dépasse.
                    contentPadding = PaddingValues(bottom = peek),
                    beyondViewportPageCount = 1,
                    key = { index -> latestPages.value.getOrNull(index)?.id ?: index },
                ) { index ->
                    val item = latestPages.value.getOrNull(index) ?: return@VerticalPager
                    Box(modifier = Modifier.fillMaxSize().padding(start = 16.dp, end = 16.dp, bottom = 10.dp)) {
                        when (item) {
                            is FeedItem.CourseCard -> {
                                val course = item.course
                                val campaign = if (segment == 0) activeCampaign?.takeIf { course.id in it.courseIds } else null
                                val completed = segment == 1 && progress.courseProgress[course.id]?.isCompleted == true
                                CourseFeedCard(
                                    course = course,
                                    language = language,
                                    progress = progress,
                                    progressManager = progressManager,
                                    tag = campaign?.title(language) ?: if (completed) StringStore.text(context, "common.read", language) else null,
                                    tagStyle = if (campaign != null) TagPillStyle.WARM else TagPillStyle.ACCENT,
                                    screen = screen,
                                    fillsPage = true,
                                    coverHeight = coverHeight,
                                    onOpen = { open(course, index) },
                                    onOpenCreator = onOpenCreator,
                                )
                            }
                            is FeedItem.CampaignCard -> EventFeedCard(
                                campaign = item.campaign,
                                language = language,
                                progress = progress,
                                onOpen = { onOpenCampaign(item.campaign) },
                                fillsPage = true,
                            )
                            FeedItem.CreatorInvite -> CreatorInviteCard(
                                language = language,
                                authors = authors,
                                onBecomeCreator = onBecomeCreator,
                                onLater = {
                                    HomeFeedSession.dismissInvite(context)
                                    inviteDismissed = true
                                },
                                fillsPage = true,
                            )
                            is FeedItem.Video -> VideoFeedCard(title = item.videoId, fillsPage = true)
                            is FeedItem.Notice -> {
                                val (title, body) = when (item.notice) {
                                    FeedNotice.FOLLOWING_EMPTY ->
                                        StringStore.text(context, "home.following.empty.title", language) to
                                            StringStore.text(context, "home.following.empty.body", language)
                                    FeedNotice.FOLLOWING_UP_TO_DATE ->
                                        StringStore.text(context, "home.following.upToDate.title", language) to
                                            StringStore.text(context, "home.following.upToDate.body", language)
                                    FeedNotice.ALL_CAUGHT_UP ->
                                        StringStore.text(context, "home.allCaughtUp", language) to
                                            StringStore.text(context, "home.following.upToDate.body", language)
                                }
                                NewGenEmptyCard(
                                    title = title,
                                    body = body,
                                    cta = StringStore.text(context, "home.following.discover", language),
                                    onClick = onSearch,
                                )
                            }
                        }
                    }
                }
            }
            }
        }
    }
}

@Composable
private fun FeedHeader(language: AppLanguage, streak: Int, onSearch: () -> Unit, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Text(
            text = "Sophia",
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 24.sp,
            color = DS.ink,
        )
        Spacer(Modifier.weight(1f))
        Row(
            modifier = Modifier
                .height(36.dp)
                .clip(CircleShape)
                .background(DS.surface)
                .border(1.dp, DS.hairline, CircleShape)
                .padding(horizontal = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(5.dp),
        ) {
            if (streak > 0) {
                AnimatedFlameBadge(size = 16.dp, showGlow = false, animated = false, modifier = Modifier.size(18.dp))
            } else {
                Icon(
                    imageVector = Icons.Outlined.LocalFireDepartment,
                    contentDescription = null,
                    tint = DS.inkTertiary,
                    modifier = Modifier.size(16.dp),
                )
            }
            Text(
                text = "$streak",
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 15.sp,
                color = DS.ink,
            )
        }
        RoundIconButton(
            icon = Icons.Filled.Search,
            onClick = onSearch,
            size = 36.dp,
            contentDescription = StringStore.text(context, "tab.explore", language),
        )
    }
}

/**
 * Ce que le fil garde d'une visite à l'autre tant que le processus vit : le deck (pour ne pas
 * redistribuer les cartes à chaque retour sur l'onglet), les cartes déjà comptées, le segment.
 */
internal object HomeFeedSession {
    private const val INVITE_DISMISS_KEY = "sophia_creator_invite_dismissed_at"
    private const val PREFS = "sophia_prefs"

    private var language: AppLanguage? = null
    private var completedCount = -1
    private var deckIds: List<String> = emptyList()

    var segment = 0
    val impressed = HashSet<String>()
    val opened = HashSet<String>()
    val skipped = HashSet<String>()

    fun matches(language: AppLanguage, completedCount: Int): Boolean =
        this.language == language && this.completedCount == completedCount && deckIds.isNotEmpty()

    fun save(language: AppLanguage, completedCount: Int, deck: List<CourseSummary>) {
        this.language = language
        this.completedCount = completedCount
        deckIds = deck.map { it.id }
        impressed.clear()
        opened.clear()
        skipped.clear()
    }

    /** Le deck de la visite précédente, s'il vaut encore pour cette langue et cette progression. */
    fun restore(language: AppLanguage, completedCount: Int): List<CourseSummary> {
        if (!matches(language, completedCount)) return emptyList()
        val summaries = ContentCatalog.cachedSummaries(language) ?: return emptyList()
        val byId = summaries.associateBy { it.id }
        return deckIds.mapNotNull { byId[it] }
    }

    /** L'invitation à créer est masquée pour deux semaines après « Plus tard ». */
    fun isInviteDismissed(context: android.content.Context): Boolean {
        val stamp = context.getSharedPreferences(PREFS, android.content.Context.MODE_PRIVATE).getLong(INVITE_DISMISS_KEY, 0L)
        if (stamp <= 0L) return false
        return System.currentTimeMillis() - stamp < 14L * 24 * 3_600 * 1_000
    }

    fun dismissInvite(context: android.content.Context) {
        context.getSharedPreferences(PREFS, android.content.Context.MODE_PRIVATE)
            .edit()
            .putLong(INVITE_DISMISS_KEY, System.currentTimeMillis())
            .apply()
    }
}
