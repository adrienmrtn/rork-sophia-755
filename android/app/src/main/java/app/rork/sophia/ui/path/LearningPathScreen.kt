package app.rork.sophia.ui.path

import android.view.View
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animate
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.animateScrollBy
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.absoluteOffset
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredHeight
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.SportsScore
import androidx.compose.material.icons.outlined.ArrowCircleDown
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.LearningPathSeenStore
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.TutorialFlags
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.LearningPathEngine
import app.rork.sophia.domain.LearningPathSnapshot
import app.rork.sophia.domain.PathLevel
import app.rork.sophia.domain.PathNode
import app.rork.sophia.domain.PathNodeState
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.domain.uppercaseIn
import app.rork.sophia.ui.components.FirstOpenExplanation
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.onboarding.ConfettiBurst
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.pow
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private val TOP_BAR_HEIGHT = 52.dp

/** Banners shrink over the last stretch before they slide under the bar. */
private val RETRACT_DISTANCE = 72.dp

/** Where the page brings things when it moves on its own, as a fraction of its height. */
private object PathScrollAnchor {
    /** A level's banner, far enough under the bar not to be drawn retracted. */
    const val LEVEL_TOP = 0.24f
    /** A pod a little above the middle, so the pod after it (and its bubble) shows too. */
    const val REVEAL_FOCUS = 0.36f
    const val CENTER = 0.5f
}

/**
 * What outlives the tab: the reader is torn down whenever a course opens, and iOS keeps its
 * path alive across tabs. Lands on the pod to play once per app session, then the page keeps
 * the position the reader left it in.
 */
private object PathSession {
    var hasSettledOnce = false
    var firstVisibleItemIndex = 0
    var firstVisibleItemScrollOffset = 0
}

private data class PathToast(val id: Long, val text: String, val icon: ImageVector)

/**
 * The "Parcours" tab. Every collection is a level drawn as a winding trail of pods, closed
 * by a quiz pod. Levels open one after the other, the courses of a level one after the
 * other, and whatever changed since the reader last looked (a course finished, a level
 * passed) is played back as a staged animation when they come back.
 *
 * A translucent bar sits at the top. It reads "Parcours" until a level's banner slides
 * under it; from then on it names that level, and each banner that passes takes its turn.
 */
@Composable
fun LearningPathScreen(
    language: AppLanguage,
    progress: UserProgress,
    /** The level quiz is drawn over the path: nothing should move underneath. */
    isCovered: Boolean,
    onOpenCourse: (String) -> Unit,
    onOpenQuiz: (level: PathLevel, isLastLevel: Boolean) -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val tutorialFlags = remember { TutorialFlags(context.applicationContext) }
    val view = LocalView.current
    val density = LocalDensity.current
    val scope = rememberCoroutineScope()

    var collections by remember(language) { mutableStateOf(ContentCatalog.cachedCollections(language)) }
    var coursesById by remember(language) {
        mutableStateOf(ContentCatalog.cachedSummaries(language)?.associateBy { it.id })
    }
    LaunchedEffect(language) {
        if (collections == null) {
            collections = ContentCatalog.collectionsAsync(context.applicationContext, language)
        }
        if (coursesById == null) {
            coursesById = ContentCatalog.summariesAsync(context.applicationContext, language).associateBy { it.id }
        }
    }
    val completedIds = remember(progress.courseProgress) {
        progress.courseProgress.filterValues { it.isCompleted }.keys
    }
    val passedLevelIds = remember(progress.pathLevelResults) {
        progress.pathLevelResults.filterValues { it.isPassed }.keys
    }
    val snapshot = remember(collections, coursesById, completedIds, passedLevelIds) {
        val all = collections
        val byId = coursesById
        if (all == null || byId == null) {
            LearningPathSnapshot.EMPTY
        } else {
            LearningPathEngine.snapshot(all, byId, { it in completedIds }, { it in passedLevelIds })
        }
    }

    val listState = rememberLazyListState(
        PathSession.firstVisibleItemIndex,
        PathSession.firstVisibleItemScrollOffset,
    )
    DisposableEffect(listState) {
        onDispose {
            PathSession.firstVisibleItemIndex = listState.firstVisibleItemIndex
            PathSession.firstVisibleItemScrollOffset = listState.firstVisibleItemScrollOffset
        }
    }
    val state = remember(listState) {
        PathScreenState(
            listState = listState,
            seenStore = LearningPathSeenStore(context.applicationContext),
            view = view,
            density = density,
            scope = scope,
        )
    }
    state.snapshot = snapshot
    state.unlockedToastText = { number -> StringStore.text(context, "path.unlocked.toast", language, number) }

    // Brings the drawn states in line with the real ones whenever either changes, and plays
    // what moved forward once nothing covers the path.
    LaunchedEffect(snapshot, isCovered) {
        state.reconcile(isCovered)
    }

    var showExplain by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        if (tutorialFlags.seen(TutorialFlags.Id.PATH)) return@LaunchedEffect
        delay(600)
        if (!tutorialFlags.seen(TutorialFlags.Id.PATH)) showExplain = true
    }

    val barHeightPx = with(density) { TOP_BAR_HEIGHT.toPx() }
    val retractPx = with(density) { RETRACT_DISTANCE.toPx() }
    // The level the top bar names: the last one whose banner went under it.
    val compactLevel by remember(snapshot) {
        derivedStateOf {
            val info = listState.layoutInfo
            var found: PathLevel? = null
            for (item in info.visibleItemsInfo) {
                val level = snapshot.levels.getOrNull(item.index) ?: continue
                if (info.beforeContentPadding + item.offset < barHeightPx - 4f) found = level
            }
            found
        }
    }

    fun lockedMessage(node: PathNode, level: PathLevel): String = when {
        !level.isUnlocked ->
            StringStore.text(context, "path.locked.level", language, maxOf(1, level.number - 1))
        node.isQuiz -> StringStore.text(context, "path.locked.quiz", language)
        else -> StringStore.text(context, "path.locked.course", language)
    }

    fun handleTap(node: PathNode, level: PathLevel) {
        when (state.shownState(node)) {
            PathNodeState.LOCKED -> {
                view.pathHaptic(PathHaptic.Reject)
                state.shake(node.id)
                state.showToast(lockedMessage(node, level), Icons.Filled.Lock)
            }
            PathNodeState.AVAILABLE, PathNodeState.COMPLETED -> {
                view.pathHaptic(PathHaptic.Tap)
                val course = node.course
                if (course == null) {
                    onOpenQuiz(level, snapshot.levels.lastOrNull()?.id == level.id)
                } else {
                    onOpenCourse(course.id)
                }
            }
        }
    }

    val startLabel = remember(language) {
        StringStore.text(context, "home.start", language).uppercaseIn(language)
    }

    Box(modifier = modifier.fillMaxSize().background(DS.canvas)) {
        LazyColumn(
            state = listState,
            modifier = Modifier.fillMaxSize(),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(
                top = TOP_BAR_HEIGHT + 14.dp,
                bottom = 40.dp,
            ),
            verticalArrangement = Arrangement.spacedBy(30.dp),
        ) {
            itemsIndexed(snapshot.levels, key = { _, level -> level.id }) { index, level ->
                PathLevelSection(
                    level = level,
                    language = language,
                    state = state,
                    currentNodeId = snapshot.currentNodeId,
                    startLabel = startLabel,
                    retract = {
                        val info = listState.layoutInfo
                        val item = info.visibleItemsInfo.firstOrNull { it.index == index }
                        if (item == null) {
                            0f
                        } else {
                            val distanceBelowBar = info.beforeContentPadding + item.offset - barHeightPx
                            ((retractPx - distanceBelowBar) / retractPx).coerceIn(0f, 1f)
                        }
                    },
                    onTapNode = { node -> handleTap(node, level) },
                )
            }
            if (snapshot.levels.isNotEmpty()) {
                item(key = "path-end") {
                    PathEnd(language = language, everythingPassed = snapshot.isEverythingPassed)
                }
            }
        }

        PathTopBar(
            language = language,
            compactLevel = compactLevel,
            canJump = snapshot.currentNodeId != null,
            onJump = {
                view.pathHaptic(PathHaptic.Tap)
                scope.launch { state.scrollToCurrentNode(PathScrollAnchor.CENTER) }
            },
        )

        PathToastHost(toast = state.toast, modifier = Modifier.align(Alignment.BottomCenter))

        if (showExplain) {
            FirstOpenExplanation(
                language = language,
                icon = "🧭",
                titleKey = "explain.path.title",
                bodyKey = "explain.path.body",
                onDismiss = {
                    showExplain = false
                    tutorialFlags.markSeen(TutorialFlags.Id.PATH)
                },
            )
        }
    }
}

// MARK: - State and reveal

/**
 * The drawn states of the pods, which trail the real ones while a change is being played,
 * and everything that animates them. Mirrors the iOS view's reveal sequence.
 */
@Stable
private class PathScreenState(
    private val listState: LazyListState,
    private val seenStore: LearningPathSeenStore,
    private val view: View,
    private val density: Density,
    private val scope: CoroutineScope,
) {
    var snapshot: LearningPathSnapshot = LearningPathSnapshot.EMPTY
    var unlockedToastText: (Int) -> String = { "" }

    /** States as drawn. They trail the real ones while a change is being animated. */
    val displayed = mutableStateMapOf<String, PathNodeState>()
    /** Connector fill after a pod while it is being animated; otherwise the state decides. */
    val segmentFills = mutableStateMapOf<String, Float>()
    val shakes = mutableStateMapOf<String, Float>()
    val lockShakes = mutableStateMapOf<String, Float>()
    var poppingNodeId by mutableStateOf<String?>(null)
    var celebratingLevelId by mutableStateOf<String?>(null)
    var toast by mutableStateOf<PathToast?>(null)
    private var toastJob: Job? = null
    private var hasLoadedSeenStates = false

    fun shownState(node: PathNode): PathNodeState = displayed[node.id] ?: node.state

    fun shake(id: String) = rattle(shakes, id, 450)

    private fun rattle(map: MutableMap<String, Float>, id: String, millis: Int) {
        scope.launch {
            val from = floor(map[id] ?: 0f)
            animate(from, from + 1f, animationSpec = tween(millis, easing = LinearEasing)) { value, _ ->
                map[id] = value
            }
        }
    }

    fun showToast(text: String, icon: ImageVector) {
        toastJob?.cancel()
        toast = PathToast(System.nanoTime(), text, icon)
        toastJob = scope.launch {
            delay(2400)
            toast = null
        }
    }

    /**
     * Regressions (a progress reset, another device's data) are applied at once; progress
     * is played as a staged animation while the path is uncovered, otherwise it waits.
     */
    suspend fun reconcile(isCovered: Boolean) {
        val current = snapshot
        if (current.levels.isEmpty()) return
        val actual = current.nodeStates
        if (!hasLoadedSeenStates) {
            hasLoadedSeenStates = true
            val seen = seenStore.load()
            if (seen != null) {
                displayed.putAll(seen)
            } else {
                // First visit: nothing to replay, the path is shown as it is.
                displayed.putAll(actual)
                seenStore.save(actual)
            }
        }
        val upgrades = mutableListOf<String>()
        for (id in current.orderedNodeIds) {
            val target = actual[id] ?: continue
            val shown = displayed[id]
            when {
                shown == null -> displayed[id] = target
                shown < target -> upgrades += id
                shown != target -> displayed[id] = target
            }
        }
        if (isCovered) return

        if (upgrades.isEmpty()) {
            seenStore.save(actual)
            if (!PathSession.hasSettledOnce) {
                PathSession.hasSettledOnce = true
                delay(350)
                scrollToCurrentNode(PathScrollAnchor.CENTER)
            }
            return
        }
        PathSession.hasSettledOnce = true
        try {
            runReveal(current, upgrades, actual)
        } finally {
            // A reveal cut short (the snapshot moved on, the tab went away) restarts from
            // the drawn states, so nothing may stay half-animated.
            poppingNodeId = null
            segmentFills.clear()
        }
    }

    private suspend fun runReveal(
        current: LearningPathSnapshot,
        upgrades: List<String>,
        actual: Map<String, PathNodeState>,
    ) {
        delay(450)
        // Where the page was last brought to: pods within a row of it stay on screen, so the
        // page only moves again when the sequence reaches further down.
        var anchor: Pair<String, Int>? = null
        for (id in upgrades) {
            val target = actual[id] ?: continue
            val level = current.levelContaining(id) ?: continue
            val node = level.nodes.firstOrNull { it.id == id } ?: continue
            val opensLevel = target == PathNodeState.AVAILABLE && level.nodes.firstOrNull()?.id == id
            if (opensLevel) {
                // The level unlock brings its banner into view itself.
                anchor = level.id to 0
            } else if (anchor == null || anchor.first != level.id || abs(node.index - anchor.second) >= 2) {
                scrollToNode(id, PathScrollAnchor.REVEAL_FOCUS)
                anchor = level.id to node.index
                delay(250)
            }
            when (target) {
                PathNodeState.COMPLETED -> animateCompletion(level, id)
                PathNodeState.AVAILABLE -> animateUnlock(level, id)
                PathNodeState.LOCKED -> displayed[id] = target
            }
        }
        seenStore.save(actual)

        // Rest on the pod to play, but only when it is not already right there.
        val currentId = current.currentNodeId ?: return
        val level = current.levelContaining(currentId) ?: return
        val node = level.nodes.firstOrNull { it.id == currentId } ?: return
        if (anchor == null || anchor.first != level.id || abs(node.index - anchor.second) >= 2) {
            delay(400)
            scrollToNode(currentId, PathScrollAnchor.REVEAL_FOCUS)
        }
    }

    /**
     * The pod fills with its colour and pops; then the connector below it creeps to the
     * next pod (a quiz pod, last of its level, has none).
     */
    private suspend fun animateCompletion(level: PathLevel, id: String) {
        val isLastOfLevel = level.nodes.lastOrNull()?.id == id
        // Kept empty while the pod turns, so the creep starts from the pod.
        if (!isLastOfLevel) segmentFills[id] = 0f
        view.pathHaptic(PathHaptic.Confirm)
        displayed[id] = PathNodeState.COMPLETED
        poppingNodeId = id
        delay(400)
        poppingNodeId = null
        delay(260)
        if (!isLastOfLevel) fillConnector(id)
    }

    /**
     * The connector's colour advances from the finished pod towards the next one, slowing
     * down as it gets close, ticking all along and knocking once it touches.
     */
    private suspend fun fillConnector(id: String) {
        val duration = 1700
        coroutineScope {
            launch {
                // Ticks at even steps of the fill: as the fill slows, they spread out.
                val ticks = 12
                var elapsed = 0.0
                for (tick in 1..ticks) {
                    val fraction = tick.toDouble() / ticks
                    val time = duration * (1 - (1 - fraction).pow(1.0 / 3.0))
                    delay((time - elapsed).coerceAtLeast(0.0).toLong())
                    elapsed = time
                    view.pathHaptic(PathHaptic.Tick)
                }
            }
            animate(
                0f,
                1f,
                animationSpec = tween(duration, easing = CubicBezierEasing(0.12f, 0.72f, 0.22f, 1f)),
            ) { value, _ -> segmentFills[id] = value }
        }
        delay(40)
        // Contact with the next pod; back to the state-driven value, which is 1 as well.
        view.pathHaptic(PathHaptic.Heavy)
        segmentFills.remove(id)
        delay(120)
    }

    /**
     * The pod's own lock rattles and gives way. When the pod opens a whole level, it is the
     * level's padlock that does so, on the banner, and the pod lights up with it.
     */
    private suspend fun animateUnlock(level: PathLevel, id: String) {
        if (level.nodes.firstOrNull()?.id == id) {
            animateLevelUnlock(level, id)
            return
        }
        rattle(shakes, id, 450)
        view.pathHaptic(PathHaptic.Tap)
        delay(430)
        displayed[id] = PathNodeState.AVAILABLE
        poppingNodeId = id
        view.pathHaptic(PathHaptic.Confirm)
        delay(420)
        poppingNodeId = null
        delay(300)
    }

    /**
     * The padlock rattles on the level's artwork, then flies off as the artwork comes back to
     * life under a shower of confetti, and the level's first pod lights up.
     */
    private suspend fun animateLevelUnlock(level: PathLevel, firstNodeId: String) {
        scrollToLevel(level.id)
        delay(750)
        rattle(lockShakes, level.id, 550)
        repeat(3) {
            view.pathHaptic(PathHaptic.Tick)
            delay(170)
        }
        celebratingLevelId = level.id
        displayed[firstNodeId] = PathNodeState.AVAILABLE
        poppingNodeId = firstNodeId
        view.pathHaptic(PathHaptic.Confirm)
        showToast(unlockedToastText(level.number), Icons.Filled.AutoAwesome)
        scope.launch {
            delay(3200)
            if (celebratingLevelId == level.id) celebratingLevelId = null
        }
        delay(450)
        poppingNodeId = null
        delay(900)
    }

    // MARK: Scrolling

    private fun levelIndex(levelId: String): Int = snapshot.levels.indexOfFirst { it.id == levelId }

    /**
     * Brings the point [yInItem] of item [index] to [anchor] of the page. An item the lazy
     * list has not laid out yet is scrolled to first, then settled on.
     */
    private suspend fun scrollTo(index: Int, yInItem: Float, anchor: Float) {
        if (index < 0) return
        var item = listState.layoutInfo.visibleItemsInfo.firstOrNull { it.index == index }
        if (item == null) {
            listState.animateScrollToItem(index)
            item = listState.layoutInfo.visibleItemsInfo.firstOrNull { it.index == index } ?: return
        }
        val info = listState.layoutInfo
        val pointOnScreen = info.beforeContentPadding + item.offset + yInItem
        val desired = anchor * info.viewportSize.height
        listState.animateScrollBy(pointOnScreen - desired, tween(550, easing = FastOutSlowInEasing))
    }

    suspend fun scrollToLevel(levelId: String) {
        scrollTo(levelIndex(levelId), 0f, PathScrollAnchor.LEVEL_TOP)
    }

    suspend fun scrollToNode(nodeId: String, anchor: Float) {
        val level = snapshot.levelContaining(nodeId) ?: return
        val node = level.nodes.firstOrNull { it.id == nodeId } ?: return
        val y = with(density) { PathLayout.nodeCenterInSection(node.index).toPx() }
        scrollTo(levelIndex(level.id), y, anchor)
    }

    suspend fun scrollToCurrentNode(anchor: Float) {
        val currentId = snapshot.currentNodeId
        if (currentId != null) {
            scrollToNode(currentId, anchor)
        } else {
            snapshot.levels.lastOrNull()?.let { scrollToLevel(it.id) }
        }
    }
}

// MARK: - Level section

/** One level: its banner, then its pods down a winding trail with the connectors behind. */
@Composable
private fun PathLevelSection(
    level: PathLevel,
    language: AppLanguage,
    state: PathScreenState,
    currentNodeId: String?,
    startLabel: String,
    retract: () -> Float,
    onTapNode: (PathNode) -> Unit,
) {
    val context = LocalContext.current
    val first = level.nodes.firstOrNull()
    val quiz = level.nodes.lastOrNull()
    val displayedUnlocked = first?.let { state.shownState(it) != PathNodeState.LOCKED } ?: level.isUnlocked
    val displayedPassed = quiz?.let { state.shownState(it) == PathNodeState.COMPLETED } ?: level.isPassed

    Column(modifier = Modifier.fillMaxWidth()) {
        Box(modifier = Modifier.padding(horizontal = 20.dp).zIndex(2f)) {
            PathLevelBanner(
                level = level,
                isUnlocked = displayedUnlocked,
                isPassed = displayedPassed,
                language = language,
                lockShakes = { state.lockShakes[level.id] ?: 0f },
                retract = retract,
            )
            if (state.celebratingLevelId == level.id) {
                val colors = remember(level.id) { confettiColors(level) }
                Box(modifier = Modifier.matchParentSize(), contentAlignment = Alignment.Center) {
                    ConfettiBurst(
                        colors = colors,
                        modifier = Modifier.requiredHeight(360.dp),
                        pieceCount = 80,
                        durationMillis = 3000,
                        origin = Offset(0.5f, 0.45f),
                    )
                }
            }
        }
        Spacer(Modifier.height(PathLayout.bannerSpacing + PathLayout.trailTopPadding))
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(PathLayout.rowHeight * level.nodes.size),
        ) {
            PathTrailCanvas(
                level = level,
                shownState = { state.shownState(it) },
                segmentFills = state.segmentFills,
                modifier = Modifier.matchParentSize(),
            )
            level.nodes.forEach { node ->
                val shown = state.shownState(node)
                val isCurrent = node.id == currentNodeId && shown == PathNodeState.AVAILABLE
                val caption = node.course?.title ?: StringStore.text(context, "path.quizPod", language)
                val stateLabel = when (shown) {
                    PathNodeState.LOCKED -> StringStore.text(context, "path.status.locked", language)
                    PathNodeState.AVAILABLE -> StringStore.text(context, "home.start", language)
                    PathNodeState.COMPLETED -> StringStore.text(context, "collections.complete", language)
                }
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(PathLayout.rowHeight)
                        .absoluteOffset(
                            x = PathLayout.xOffset(node.index + level.wavePhase),
                            y = PathLayout.rowHeight * node.index,
                        )
                        .zIndex(if (isCurrent) 1f else 0f)
                        .semantics(mergeDescendants = true) { contentDescription = "$caption, $stateLabel" },
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    PathPod(
                        node = node,
                        state = shown,
                        isCurrent = isCurrent,
                        isPopping = state.poppingNodeId == node.id,
                        shakes = { state.shakes[node.id] ?: 0f },
                        startLabel = startLabel,
                        onTap = { onTapNode(node) },
                    )
                    Spacer(Modifier.height(8.dp))
                    Text(
                        text = caption,
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 11.sp,
                        lineHeight = 14.sp,
                        color = if (shown == PathNodeState.LOCKED) DS.inkTertiary else DS.inkSecondary,
                        textAlign = TextAlign.Center,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.width(132.dp),
                    )
                }
            }
        }
    }
}

private fun confettiColors(level: PathLevel): List<Color> {
    val colors = mutableListOf(PathPalette.gold, DS.accentSoft)
    level.courses.map { it.subjectEnum }.distinct().forEach { colors += PathPalette.tint(it) }
    return colors
}

// MARK: - Top bar, end, toast

/**
 * Navigation-bar-like strip: translucent, the page title in the middle until a level's
 * banner slides underneath, then that level's title and progress.
 */
@Composable
private fun PathTopBar(
    language: AppLanguage,
    compactLevel: PathLevel?,
    canJump: Boolean,
    onJump: () -> Unit,
) {
    val context = LocalContext.current
    Column(modifier = Modifier.fillMaxWidth().background(DS.canvas.copy(alpha = 0.94f))) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(TOP_BAR_HEIGHT)
                .padding(horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .alpha(if (canJump) 1f else 0f)
                    .clip(CircleShape)
                    .softPress(onClick = onJump, enabled = canJump)
                    .semantics {
                        contentDescription = StringStore.text(context, "library.section.continue", language)
                    },
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    Icons.Outlined.ArrowCircleDown,
                    contentDescription = null,
                    tint = DS.accentSoft,
                    modifier = Modifier.size(22.dp),
                )
            }
            AnimatedContent(
                targetState = compactLevel,
                contentKey = { it?.id },
                modifier = Modifier.weight(1f).height(TOP_BAR_HEIGHT).clipToBounds(),
                contentAlignment = Alignment.Center,
                transitionSpec = {
                    if (targetState != null) {
                        (slideInVertically { it } + fadeIn()) togetherWith (slideOutVertically { -it } + fadeOut())
                    } else {
                        (slideInVertically { -it } + fadeIn()) togetherWith (slideOutVertically { it } + fadeOut())
                    }
                },
                label = "pathTitle",
            ) { level ->
                Column(
                    modifier = Modifier.fillMaxSize(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                ) {
                    if (level == null) {
                        Text(
                            text = StringStore.text(context, "path.title", language),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 17.sp,
                            color = DS.ink,
                            maxLines = 1,
                        )
                    } else {
                        Text(
                            text = level.collection.title,
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 16.sp,
                            color = DS.ink,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                        Text(
                            text = StringStore.text(context, "path.levelCaption", language, level.number) +
                                " · " +
                                StringStore.text(
                                    context, "path.courses.count", language,
                                    level.completedCourseCount, level.courseCount,
                                ),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Medium,
                            fontSize = 11.sp,
                            color = DS.inkSecondary,
                            maxLines = 1,
                        )
                    }
                }
            }
            // Same width as the leading button, so the title sits in the middle of the screen.
            Spacer(Modifier.size(36.dp))
        }
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(0.5.dp)
                .alpha(if (compactLevel == null) 0f else 1f)
                .background(DS.hairline),
        )
    }
}

@Composable
private fun PathEnd(language: AppLanguage, everythingPassed: Boolean) {
    val context = LocalContext.current
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 36.dp)
            .padding(top = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Box(
            modifier = Modifier.size(64.dp).clip(CircleShape).background(DS.surfaceMuted),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                if (everythingPassed) Icons.Filled.SportsScore else Icons.Filled.Flag,
                contentDescription = null,
                tint = if (everythingPassed) PathPalette.gold else DS.inkTertiary,
                modifier = Modifier.size(28.dp),
            )
        }
        Text(
            text = StringStore.text(context, if (everythingPassed) "path.end.doneTitle" else "path.end.title", language),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 17.sp,
            color = DS.ink,
            textAlign = TextAlign.Center,
        )
        Text(
            text = StringStore.text(context, if (everythingPassed) "path.end.doneBody" else "path.end.body", language),
            fontFamily = PlusJakartaSans,
            fontSize = 15.sp,
            lineHeight = 21.sp,
            color = DS.inkSecondary,
            textAlign = TextAlign.Center,
        )
    }
}

@Composable
private fun PathToastHost(toast: PathToast?, modifier: Modifier = Modifier) {
    // Kept while the toast leaves, so its text does not vanish before it does.
    var last by remember { mutableStateOf(toast) }
    if (toast != null) last = toast
    AnimatedVisibility(
        visible = toast != null,
        modifier = modifier,
        enter = slideInVertically { it } + fadeIn(),
        exit = fadeOut(tween(250)) + slideOutVertically { it / 2 },
    ) {
        val shown = last ?: return@AnimatedVisibility
        Row(
            modifier = Modifier
                .padding(horizontal = 24.dp)
                .padding(bottom = 16.dp)
                .clip(DS.controlShape)
                .background(DS.accent)
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Icon(shown.icon, contentDescription = null, tint = Color.White, modifier = Modifier.size(15.dp))
            Text(
                text = shown.text,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Medium,
                fontSize = 15.sp,
                lineHeight = 20.sp,
                color = Color.White,
            )
        }
    }
}
