package app.rork.sophia.ui.newgen

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.outlined.LocalFireDepartment
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
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
import kotlinx.coroutines.withContext

/**
 * L'accueil « nouvelle génération » : un seul fil vertical, « Pour toi » (le deck local de
 * [HomeDeckBuilder], avec l'événement en cours et l'invitation à créer glissés dedans) ou
 * « Abonnements » (les cours des créateurs suivis). Chaque carte compte une impression après
 * une seconde à l'écran, et un passage si elle disparaît sans avoir été ouverte.
 */
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
    val completedCount = progress.courseProgress.count { it.value.isCompleted }

    var segment by remember { mutableIntStateOf(HomeFeedSession.segment) }
    var deck by remember(language) { mutableStateOf(HomeFeedSession.restore(language, completedCount)) }
    var deckReady by remember(language) { mutableStateOf(deck.isNotEmpty()) }
    var inviteDismissed by remember { mutableStateOf(HomeFeedSession.isInviteDismissed(context)) }

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
        withContext(Dispatchers.IO) {
            AuthorStore.preload(context.applicationContext)
            CampaignStore.all(context.applicationContext)
        }
        val built = withContext(Dispatchers.Default) { buildDeck(summaries) }
        HomeFeedSession.save(language, completedCount, built)
        deck = built
        deckReady = true
        CourseImagePrefetch.warmCovers(context.applicationContext, built.take(6).map { it.id })
    }

    val activeCampaign = remember(deckReady) { CampaignStore.active(context.applicationContext).firstOrNull() }
    val authors = remember(deckReady) { AuthorStore.all(context.applicationContext) }

    /** Le deck, l'événement en troisième position et l'invitation en septième. */
    val forYouItems = remember(deck, activeCampaign, inviteDismissed) {
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

    fun open(course: CourseSummary, position: Int) {
        HomeFeedSession.opened.add(course.id)
        skipStore.clear(course.id)
        Analytics.log(
            "card_open",
            courseId = course.id,
            screen = if (segment == 0) "home" else "home_following",
            position = position,
            algoVersion = Analytics.ALGO_VERSION,
        )
        onOpenCourse(course)
    }

    LazyColumn(
        modifier = modifier.fillMaxSize().background(DS.canvas),
        contentPadding = PaddingValues(bottom = 32.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        item(key = "header") {
            FeedHeader(
                language = language,
                streak = progress.streak,
                onSearch = onSearch,
                modifier = Modifier.padding(start = 20.dp, end = 20.dp, top = 8.dp),
            )
        }
        item(key = "segments") {
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
                modifier = Modifier.padding(horizontal = 20.dp).padding(bottom = 4.dp),
            )
        }
        if (segment == 0) {
            if (!deckReady) {
                item(key = "loading") {
                    Box(modifier = Modifier.fillMaxWidth().padding(vertical = 60.dp), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = DS.accent)
                    }
                }
            } else if (deck.isEmpty()) {
                item(key = "caught-up") {
                    Text(
                        text = StringStore.text(context, "home.allCaughtUp", language),
                        fontFamily = PlusJakartaSans,
                        color = DS.ink,
                        modifier = Modifier.fillMaxWidth().padding(40.dp),
                    )
                }
            }
            itemsIndexed(forYouItems) { position, item ->
                when (item) {
                    is FeedItem.CourseCard -> {
                        val course = item.course
                        TrackedCard(
                            courseId = course.id,
                            position = position,
                            isPremium = isPremium,
                            skipStore = skipStore,
                        )
                        val campaign = activeCampaign?.takeIf { course.id in it.courseIds }
                        CourseFeedCard(
                            course = course,
                            language = language,
                            progress = progress,
                            progressManager = progressManager,
                            tag = campaign?.title(language),
                            tagStyle = TagPillStyle.WARM,
                            onOpen = { open(course, position) },
                            onOpenCreator = onOpenCreator,
                            modifier = Modifier.padding(horizontal = 16.dp),
                        )
                    }
                    is FeedItem.CampaignCard -> EventFeedCard(
                        campaign = item.campaign,
                        language = language,
                        progress = progress,
                        onOpen = { onOpenCampaign(item.campaign) },
                        modifier = Modifier.padding(horizontal = 16.dp),
                    )
                    FeedItem.CreatorInvite -> CreatorInviteCard(
                        language = language,
                        authors = authors,
                        onBecomeCreator = onBecomeCreator,
                        onLater = {
                            HomeFeedSession.dismissInvite(context)
                            inviteDismissed = true
                        },
                        modifier = Modifier.padding(horizontal = 16.dp),
                    )
                    is FeedItem.Video -> VideoFeedCard(title = item.videoId, modifier = Modifier.padding(horizontal = 16.dp))
                }
            }
        } else {
            if (followedAuthors.isEmpty()) {
                item(key = "following-empty") {
                    NewGenEmptyCard(
                        title = StringStore.text(context, "home.following.empty.title", language),
                        body = StringStore.text(context, "home.following.empty.body", language),
                        cta = StringStore.text(context, "home.following.discover", language),
                        onClick = onSearch,
                        modifier = Modifier.padding(horizontal = 16.dp),
                    )
                }
            } else {
                item(key = "followed-row") {
                    FollowedCreatorsRow(
                        authors = followedAuthors,
                        language = language,
                        onOpen = onOpenCreator,
                        onDiscover = onSearch,
                        modifier = Modifier.padding(horizontal = 20.dp),
                    )
                }
                if (followingCourses.all { progress.courseProgress[it.id]?.isCompleted == true }) {
                    item(key = "following-uptodate") {
                        NewGenEmptyCard(
                            title = StringStore.text(context, "home.following.upToDate.title", language),
                            body = StringStore.text(context, "home.following.upToDate.body", language),
                            cta = StringStore.text(context, "home.following.discover", language),
                            onClick = onSearch,
                            modifier = Modifier.padding(horizontal = 16.dp),
                        )
                    }
                } else {
                    item(key = "following-news") {
                        NewGenSectionTitle(
                            text = StringStore.text(context, "home.following.news", language),
                            modifier = Modifier.padding(horizontal = 20.dp).padding(top = 6.dp),
                        )
                    }
                }
                itemsIndexed(followingCourses, key = { _, course -> "following:${course.id}" }) { position, course ->
                    val completed = progress.courseProgress[course.id]?.isCompleted == true
                    CourseFeedCard(
                        course = course,
                        language = language,
                        progress = progress,
                        progressManager = progressManager,
                        tag = if (completed) StringStore.text(context, "common.read", language) else null,
                        screen = "home_following",
                        onOpen = { open(course, position) },
                        onOpenCreator = onOpenCreator,
                        modifier = Modifier.padding(horizontal = 16.dp),
                    )
                }
            }
        }
    }
}

/** `itemsIndexed` sans clé pour le fil « Pour toi » : les positions comptent dans les événements. */
private fun androidx.compose.foundation.lazy.LazyListScope.itemsIndexed(
    items: List<FeedItem>,
    content: @Composable (Int, FeedItem) -> Unit,
) {
    items(items.size, key = { items[it].id }) { index -> content(index, items[index]) }
}

private fun <T> androidx.compose.foundation.lazy.LazyListScope.itemsIndexed(
    items: List<T>,
    key: (Int, T) -> Any,
    content: @Composable (Int, T) -> Unit,
) {
    items(items.size, key = { key(it, items[it]) }) { index -> content(index, items[index]) }
}

/**
 * La mesure d'une carte de cours : une impression après une seconde à l'écran
 * (docs/events.md), un passage si elle quitte l'écran vue mais pas ouverte. Le gain par
 * balayage de l'offre découverte suit l'impression, comme sur iOS.
 */
@Composable
private fun TrackedCard(courseId: String, position: Int, isPremium: Boolean, skipStore: DeckSkipStore) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    LaunchedEffect(courseId) {
        if (courseId in HomeFeedSession.impressed) return@LaunchedEffect
        delay(1000)
        if (!HomeFeedSession.impressed.add(courseId)) return@LaunchedEffect
        Analytics.log("card_impression", courseId = courseId, screen = "home", position = position, algoVersion = Analytics.ALGO_VERSION)
        if (!isPremium) app.discountManager.registerSwipe()
    }
    DisposableEffect(courseId) {
        onDispose {
            if (courseId in HomeFeedSession.impressed &&
                courseId !in HomeFeedSession.opened &&
                HomeFeedSession.skipped.add(courseId)
            ) {
                skipStore.registerSkip(courseId)
                Analytics.log("card_skip", courseId = courseId, screen = "home", position = position, algoVersion = Analytics.ALGO_VERSION)
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
