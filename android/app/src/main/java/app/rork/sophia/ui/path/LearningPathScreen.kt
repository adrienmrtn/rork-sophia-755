package app.rork.sophia.ui.path

import android.view.View
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.SizeTransform
import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animate
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.shrinkVertically
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.animateScrollBy
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredHeight
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
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
import androidx.compose.runtime.key
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
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.onPlaced
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
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
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.FirstOpenExplanation
import app.rork.sophia.ui.components.Haptics
import app.rork.sophia.ui.components.dsPopIn
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.rememberHaptics
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

/** A row of the trail, for where a card not laid out yet should be. */
private val ESTIMATED_ROW_HEIGHT = 150.dp

/** Where the page brings things when it moves on its own, as a fraction of its height. */
private object PathScrollAnchor {
    /** A level's banner, far enough under the bar not to be drawn retracted. */
    const val LEVEL_TOP = 0.24f
    /** A card a little above the middle, so the card after it shows too. */
    const val REVEAL_FOCUS = 0.36f
    const val CENTER = 0.5f
}

/**
 * What outlives the tab: the reader is torn down whenever a course opens, and iOS keeps its
 * path alive across tabs. Lands on the card to play once per app session, then the page
 * keeps the position the reader left it in.
 */
private object PathSession {
    var hasSettledOnce = false
    var firstVisibleItemIndex = 0
    var firstVisibleItemScrollOffset = 0

    /**
     * Levels whose cards already came in as a cascade: it plays the first time a level
     * shows, not each time the lazy list rebuilds it on the way back up.
     */
    val cascadedLevelIds = HashSet<String>()
}

private data class PathToast(val id: Long, val text: String, val icon: ImageVector)

/**
 * The "Parcours" tab. Every collection is a level: a banner, then its courses as cards
 * zigzagging down the page, joined by dotted curves and closed by a quiz pill. Levels still
 * locked fold into one compact row. Levels open one after the other, the courses of a level
 * one after the other, and whatever changed since the reader last looked (a course finished,
 * a level passed) is played back as a staged animation when they come back.
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
    val haptics = rememberHaptics()

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

    fun lockedLevelMessage(level: PathLevel): String =
        StringStore.text(context, "path.locked.level", language, maxOf(1, level.number - 1))

    fun lockedMessage(node: PathNode, level: PathLevel): String = when {
        !level.isUnlocked -> lockedLevelMessage(level)
        node.isQuiz -> StringStore.text(context, "path.locked.quiz", language)
        else -> StringStore.text(context, "path.locked.course", language)
    }

    // The cards press without a vibration of their own: the tap answers with this one.
    fun handleTap(node: PathNode, level: PathLevel) {
        when (state.shownState(node)) {
            PathNodeState.LOCKED -> {
                haptics.error()
                state.shake(node.id)
                state.showToast(lockedMessage(node, level), Icons.Filled.Lock)
            }
            PathNodeState.AVAILABLE, PathNodeState.COMPLETED -> {
                haptics.confirm()
                val course = node.course
                if (course == null) {
                    onOpenQuiz(level, snapshot.levels.lastOrNull()?.id == level.id)
                } else {
                    onOpenCourse(course.id)
                }
            }
        }
    }

    // The compact row of a locked level unfolds on its courses and says what the level is
    // waiting for; a second tap folds it back.
    fun handleTapLockedLevel(level: PathLevel) {
        val willExpand = !state.isExpanded(level.id)
        state.setExpanded(level.id, willExpand)
        if (!willExpand || level.isUnlocked) {
            haptics.select()
            return
        }
        haptics.error()
        state.rattleLock(level.id)
        state.showToast(lockedLevelMessage(level), Icons.Filled.Lock)
    }

    Box(modifier = modifier.fillMaxSize().background(DS.canvas)) {
        LazyColumn(
            state = listState,
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(top = TOP_BAR_HEIGHT + 12.dp, bottom = 40.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            itemsIndexed(snapshot.levels, key = { _, level -> level.id }) { index, level ->
                PathLevelSection(
                    level = level,
                    language = language,
                    state = state,
                    currentNodeId = snapshot.currentNodeId,
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
                    onTapLockedLevel = { handleTapLockedLevel(level) },
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
            // The pressable button carries the tap's vibration.
            onJump = { scope.launch { state.scrollToCurrentNode(PathScrollAnchor.CENTER) } },
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
 * The drawn states of the cards, which trail the real ones while a change is being played,
 * and everything that animates them. Mirrors the iOS view's reveal sequence.
 */
@Stable
private class PathScreenState(
    private val listState: LazyListState,
    private val seenStore: LearningPathSeenStore,
    view: View,
    private val density: Density,
    private val scope: CoroutineScope,
) {
    private val haptics = Haptics(view)

    var snapshot: LearningPathSnapshot = LearningPathSnapshot.EMPTY
    var unlockedToastText: (Int) -> String = { "" }

    /** States as drawn. They trail the real ones while a change is being animated. */
    val displayed = mutableStateMapOf<String, PathNodeState>()
    /** Connector fill after a card while it is being animated; otherwise the state decides. */
    val segmentFills = mutableStateMapOf<String, Float>()
    val shakes = mutableStateMapOf<String, Float>()
    val lockShakes = mutableStateMapOf<String, Float>()
    var poppingNodeId by mutableStateOf<String?>(null)
    /** Card whose padlock is swinging open, just before it is drawn available. */
    var openingNodeId by mutableStateOf<String?>(null)
    /** Locked level whose padlock is swinging open, just before it unfolds. */
    var openingLevelId by mutableStateOf<String?>(null)
    var celebratingLevelId by mutableStateOf<String?>(null)
    var toast by mutableStateOf<PathToast?>(null)
    /** Locked levels the reader unfolded to look inside. */
    private val expandedLockedLevels = mutableStateMapOf<String, Boolean>()
    private var toastJob: Job? = null
    private var hasLoadedSeenStates = false

    /**
     * Where the sections and their rows are laid out, kept while they are composed. The
     * cards are as tall as their titles, so the page measures instead of computing.
     */
    val sectionCoordinates = HashMap<String, LayoutCoordinates>()
    val nodeCoordinates = HashMap<String, LayoutCoordinates>()

    fun shownState(node: PathNode): PathNodeState = displayed[node.id] ?: node.state

    fun isExpanded(levelId: String): Boolean = expandedLockedLevels[levelId] == true

    fun setExpanded(levelId: String, expanded: Boolean) {
        if (expanded) expandedLockedLevels[levelId] = true else expandedLockedLevels.remove(levelId)
    }

    fun shake(id: String) = rattle(shakes, id, 450)

    fun rattleLock(levelId: String) = rattle(lockShakes, levelId, 450)

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
            openingNodeId = null
            openingLevelId = null
            segmentFills.clear()
        }
    }

    private suspend fun runReveal(
        current: LearningPathSnapshot,
        upgrades: List<String>,
        actual: Map<String, PathNodeState>,
    ) {
        delay(450)
        // Where the page was last brought to: cards within a row of it stay on screen, so
        // the page only moves again when the sequence reaches further down.
        var anchor: Pair<String, Int>? = null
        for (id in upgrades) {
            val target = actual[id] ?: continue
            // Already drawn, by the unlock of its level.
            if (displayed[id] == target) continue
            val level = current.levelContaining(id) ?: continue
            val node = level.nodes.firstOrNull { it.id == id } ?: continue
            val first = level.nodes.firstOrNull()
            if (first != null &&
                shownState(first) == PathNodeState.LOCKED &&
                actual[first.id] != PathNodeState.LOCKED
            ) {
                // The level is still drawn folded: its unlock brings it into view itself and
                // draws everything that moved inside it.
                anchor = level.id to 0
                animateLevelUnlock(level, actual)
                continue
            }
            if (anchor == null || anchor.first != level.id || abs(node.index - anchor.second) >= 2) {
                scrollToNode(id, PathScrollAnchor.REVEAL_FOCUS)
                anchor = level.id to node.index
                delay(250)
            }
            when (target) {
                PathNodeState.COMPLETED -> animateCompletion(level, id)
                PathNodeState.AVAILABLE -> animateUnlock(id)
                PathNodeState.LOCKED -> displayed[id] = target
            }
        }
        seenStore.save(actual)

        // Rest on the card to play, but only when it is not already right there.
        val currentId = current.currentNodeId ?: return
        val level = current.levelContaining(currentId) ?: return
        val node = level.nodes.firstOrNull { it.id == currentId } ?: return
        if (anchor == null || anchor.first != level.id || abs(node.index - anchor.second) >= 2) {
            delay(400)
            scrollToNode(currentId, PathScrollAnchor.REVEAL_FOCUS)
        }
    }

    /**
     * The card gets its green check and pops; then the dots below it turn green one by one
     * down to the next card (the quiz pill, last of its level, has none).
     */
    private suspend fun animateCompletion(level: PathLevel, id: String) {
        val isLastOfLevel = level.nodes.lastOrNull()?.id == id
        // Kept empty while the card turns, so the creep starts from the card.
        if (!isLastOfLevel) segmentFills[id] = 0f
        haptics.success()
        displayed[id] = PathNodeState.COMPLETED
        poppingNodeId = id
        delay(400)
        poppingNodeId = null
        delay(260)
        if (!isLastOfLevel) fillConnector(id)
    }

    /**
     * The dots turn green from the finished card towards the next one, slowing down as they
     * get close, ticking all along and knocking once they touch.
     */
    private suspend fun fillConnector(id: String) {
        // A handful of dots between two cards.
        val duration = 1000
        coroutineScope {
            launch {
                // Ticks at even steps of the fill: as the fill slows, they spread out.
                val ticks = 6
                var elapsed = 0.0
                for (tick in 1..ticks) {
                    val fraction = tick.toDouble() / ticks
                    val time = duration * (1 - (1 - fraction).pow(1.0 / 3.0))
                    delay((time - elapsed).coerceAtLeast(0.0).toLong())
                    elapsed = time
                    haptics.tick()
                }
            }
            animate(
                0f,
                1f,
                animationSpec = tween(duration, easing = CubicBezierEasing(0.12f, 0.72f, 0.22f, 1f)),
            ) { value, _ -> segmentFills[id] = value }
        }
        delay(40)
        // Contact with the next card; back to the state-driven value, which is 1 as well.
        haptics.rigid()
        segmentFills.remove(id)
        delay(120)
    }

    /** The card's own padlock rattles, swings open, and the card is uncovered. */
    private suspend fun animateUnlock(id: String) {
        rattle(shakes, id, 450)
        haptics.soft()
        delay(430)
        openingNodeId = id
        delay(280)
        displayed[id] = PathNodeState.AVAILABLE
        poppingNodeId = id
        openingNodeId = null
        haptics.success()
        delay(420)
        poppingNodeId = null
        delay(300)
    }

    /**
     * The padlock of the folded level rattles and swings open, then the level unfolds into
     * its banner and its cards under a shower of confetti, the card to play already lit
     * (the courses finished elsewhere before it are drawn completed at once).
     */
    private suspend fun animateLevelUnlock(level: PathLevel, actual: Map<String, PathNodeState>) {
        scrollToLevel(level.id)
        delay(750)
        rattle(lockShakes, level.id, 550)
        repeat(3) {
            haptics.tick()
            delay(170)
        }
        openingLevelId = level.id
        delay(320)

        celebratingLevelId = level.id
        val entryId = level.nodes
            .firstOrNull { shownState(it) == PathNodeState.LOCKED && actual[it.id] == PathNodeState.AVAILABLE }
            ?.id
        for (node in level.nodes) {
            if (actual[node.id] == PathNodeState.COMPLETED) displayed[node.id] = PathNodeState.COMPLETED
        }
        if (entryId != null) {
            displayed[entryId] = PathNodeState.AVAILABLE
            poppingNodeId = entryId
        }
        openingLevelId = null
        setExpanded(level.id, false)
        haptics.celebrate()
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
     * list has not laid out yet is scrolled to first, then measured and settled on.
     */
    private suspend fun scrollTo(index: Int, anchor: Float, yInItem: () -> Float) {
        if (index < 0) return
        var item = listState.layoutInfo.visibleItemsInfo.firstOrNull { it.index == index }
        if (item == null) {
            listState.animateScrollToItem(index)
            item = listState.layoutInfo.visibleItemsInfo.firstOrNull { it.index == index } ?: return
        }
        val info = listState.layoutInfo
        val pointOnScreen = info.beforeContentPadding + item.offset + yInItem()
        val desired = anchor * info.viewportSize.height
        listState.animateScrollBy(pointOnScreen - desired, tween(550, easing = FastOutSlowInEasing))
    }

    suspend fun scrollToLevel(levelId: String) {
        scrollTo(levelIndex(levelId), PathScrollAnchor.LEVEL_TOP) { 0f }
    }

    /** Middle of a card's row, measured from the top of its level section. */
    private fun nodeCenterInSection(level: PathLevel, node: PathNode): Float {
        val section = sectionCoordinates[level.id]?.takeIf { it.isAttached }
        val row = nodeCoordinates[node.id]?.takeIf { it.isAttached }
        if (section != null && row != null) {
            val measured = runCatching { section.localPositionOf(row, Offset.Zero).y + row.size.height / 2f }
            measured.getOrNull()?.let { return it }
        }
        // Not laid out (a level still folded): about where the row will be.
        return with(density) {
            (PathCardLayout.bannerHeight + PathCardLayout.headerSpacing +
                (ESTIMATED_ROW_HEIGHT + PathCardLayout.rowSpacing) * node.index +
                ESTIMATED_ROW_HEIGHT / 2).toPx()
        }
    }

    suspend fun scrollToNode(nodeId: String, anchor: Float) {
        val level = snapshot.levelContaining(nodeId) ?: return
        val node = level.nodes.firstOrNull { it.id == nodeId } ?: return
        scrollTo(levelIndex(level.id), anchor) { nodeCenterInSection(level, node) }
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

/**
 * One level: its banner, then its courses as cards alternating sides, the dotted connectors
 * behind them and the quiz pill at the end. A level drawn locked is folded into its compact
 * row, and only shows its cards once the reader unfolds it.
 */
@Composable
private fun PathLevelSection(
    level: PathLevel,
    language: AppLanguage,
    state: PathScreenState,
    currentNodeId: String?,
    retract: () -> Float,
    onTapNode: (PathNode) -> Unit,
    onTapLockedLevel: () -> Unit,
) {
    val first = level.nodes.firstOrNull()
    val quiz = level.nodes.lastOrNull()
    val displayedUnlocked = first?.let { state.shownState(it) != PathNodeState.LOCKED } ?: level.isUnlocked
    val displayedPassed = quiz?.let { state.shownState(it) == PathNodeState.COMPLETED } ?: level.isPassed
    val showsCards = displayedUnlocked || state.isExpanded(level.id)
    val playsCascade = remember(level.id) { level.id !in PathSession.cascadedLevelIds }
    if (showsCards && playsCascade) {
        LaunchedEffect(level.id) {
            // Once the cascade had the time to play.
            delay(1200)
            PathSession.cascadedLevelIds += level.id
        }
    }

    DisposableEffect(level.id) {
        onDispose {
            state.sectionCoordinates.remove(level.id)
            level.nodes.forEach { state.nodeCoordinates.remove(it.id) }
        }
    }

    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
        Column(
            modifier = Modifier
                .widthIn(max = PathCardLayout.maxSectionWidth)
                .fillMaxWidth()
                .onPlaced { state.sectionCoordinates[level.id] = it },
        ) {
            Box(modifier = Modifier.padding(horizontal = PathCardLayout.sideInset).zIndex(2f)) {
                PathLevelHeader(
                    level = level,
                    isUnlocked = displayedUnlocked,
                    isPassed = displayedPassed,
                    language = language,
                    lockShakes = { state.lockShakes[level.id] ?: 0f },
                    isOpening = state.openingLevelId == level.id,
                    retract = retract,
                    onTapLocked = onTapLockedLevel,
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
            AnimatedVisibility(
                visible = showsCards,
                enter = fadeIn(tween(300)) + expandVertically(DSMotion.reveal()),
                exit = fadeOut(tween(200)) + shrinkVertically(DSMotion.reveal()),
            ) {
                Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
                    Column(
                        modifier = Modifier
                            .padding(horizontal = PathCardLayout.sideInset)
                            // Room for the halo above the first card and the last card's bottom edge.
                            .padding(top = PathCardLayout.headerSpacing, bottom = 3.dp)
                            .widthIn(max = PathCardLayout.maxTrailWidth)
                            .fillMaxWidth(),
                        verticalArrangement = Arrangement.spacedBy(PathCardLayout.rowSpacing),
                    ) {
                        level.nodes.forEach { node ->
                            key(node.id) {
                                PathNodeRow(
                                    node = node,
                                    level = level,
                                    language = language,
                                    state = state,
                                    currentNodeId = currentNodeId,
                                    playsCascade = playsCascade,
                                    onTap = { onTapNode(node) },
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

/**
 * One row of the trail: the card (or the quiz pill) on its side, the breathing halo behind
 * it while it is the one to play, and the dotted curve hung under it down to the next row.
 * The curve is drawn by the row, not by the card, so the cascade that brings the card in
 * does not clip it.
 */
@Composable
private fun PathNodeRow(
    node: PathNode,
    level: PathLevel,
    language: AppLanguage,
    state: PathScreenState,
    currentNodeId: String?,
    /** The card rises in after the ones above it, and its dotted curve traces itself. */
    playsCascade: Boolean,
    onTap: () -> Unit,
) {
    val context = LocalContext.current
    val shown = state.shownState(node)
    val isCurrent = node.id == currentNodeId && shown == PathNodeState.AVAILABLE
    val isLeading = PathCardLayout.isLeading(node.index)
    val course = node.course
    val caption = course?.title ?: StringStore.text(context, "path.quizPod", language)
    val stateLabel = when (shown) {
        PathNodeState.LOCKED -> StringStore.text(context, "path.status.locked", language)
        PathNodeState.AVAILABLE -> StringStore.text(context, "home.start", language)
        PathNodeState.COMPLETED -> StringStore.text(context, "collections.complete", language)
    }
    val pop by animateFloatAsState(
        targetValue = if (state.poppingNodeId == node.id) 1.06f else 1f,
        animationSpec = spring(dampingRatio = 0.55f, stiffness = 200f),
        label = "pathCardPop",
    )
    // The quiz pill, last of its level, has no curve under it.
    val hasConnector = !node.isQuiz && node.id != level.nodes.lastOrNull()?.id
    val reachesQuiz = node.index == level.nodes.size - 2
    // Past a screenful, the cards come in together rather than keep the reader waiting.
    val cascadeIndex = minOf(node.index, 6)

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .onPlaced { state.nodeCoordinates[node.id] = it }
            .then(
                if (hasConnector) {
                    Modifier.pathDottedConnector(
                        fromStart = isLeading,
                        // Green as far as the drawn state says, or as far as the fill being
                        // animated has got.
                        fill = { state.segmentFills[node.id] ?: if (state.shownState(node) == PathNodeState.COMPLETED) 1f else 0f },
                        width = if (reachesQuiz) PathCardLayout.quizConnectorWidth else PathCardLayout.connectorWidth,
                        appearDelayMillis = 300 + cascadeIndex * 70,
                        animated = playsCascade,
                    )
                } else {
                    Modifier
                },
            )
            .semantics(mergeDescendants = true) { contentDescription = "$caption, $stateLabel" },
        contentAlignment = when {
            node.isQuiz -> Alignment.TopCenter
            isLeading -> Alignment.TopStart
            else -> Alignment.TopEnd
        },
    ) {
        Box(
            modifier = Modifier
                .then(if (playsCascade) Modifier.dsStagger(cascadeIndex, stepMillis = 70) else Modifier)
                .graphicsLayer {
                    translationX = shakeOffset(state.shakes[node.id] ?: 0f, 5.dp.toPx())
                    scaleX = pop
                    scaleY = pop
                }
                .pathCardHalo(visible = isCurrent)
                // No vibration on the press itself: the tap answers with its own (open or refused).
                .pressable(onClick = onTap, haptic = false),
        ) {
            if (course != null) {
                PathCourseCard(
                    course = course,
                    number = node.index + 1,
                    state = shown,
                    isCurrent = isCurrent,
                    language = language,
                    isUnlocking = state.openingNodeId == node.id,
                )
            } else {
                PathQuizPill(
                    state = shown,
                    isCurrent = isCurrent,
                    courseCount = level.courseCount,
                    completedCourseCount = level.completedCourseCount,
                    language = language,
                    isUnlocking = state.openingNodeId == node.id,
                )
            }
        }
    }
}

/**
 * The header of a level as it lives in the trail: its banner, or its compact row while it
 * is drawn locked. [retract] (0 to 1) shrinks and fades it as it slides under the top bar.
 */
@Composable
private fun PathLevelHeader(
    level: PathLevel,
    isUnlocked: Boolean,
    isPassed: Boolean,
    language: AppLanguage,
    lockShakes: () -> Float,
    isOpening: Boolean,
    retract: () -> Float,
    onTapLocked: () -> Unit,
) {
    val context = LocalContext.current
    AnimatedContent(
        targetState = isUnlocked,
        modifier = Modifier
            .fillMaxWidth()
            .graphicsLayer {
                val r = retract()
                val scale = 1f - 0.06f * r
                scaleX = scale
                scaleY = scale
                alpha = 1f - 0.35f * r
                transformOrigin = TransformOrigin(0.5f, 0f)
            },
        transitionSpec = {
            (
                fadeIn(tween(350)) +
                    scaleIn(DSMotion.reveal(), initialScale = 0.94f, transformOrigin = TransformOrigin(0.5f, 0f))
                ) togetherWith fadeOut(tween(200)) using SizeTransform(clip = false)
        },
        label = "pathLevelHeader",
    ) { unlocked ->
        if (unlocked) {
            PathLevelBanner(level = level, isPassed = isPassed, language = language)
        } else {
            val lockedLabel = StringStore.text(context, "path.status.locked", language)
            PathLockedLevelCard(
                level = level,
                language = language,
                lockShakes = lockShakes,
                isOpening = isOpening,
                modifier = Modifier
                    // No vibration on the press itself: the tap answers with its own.
                    .pressable(onClick = onTapLocked, scaleDown = 0.98f, haptic = false)
                    .semantics(mergeDescendants = true) { stateDescription = lockedLabel },
            )
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
                .padding(horizontal = 20.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .alpha(if (canJump) 1f else 0f)
                    .pressable(onClick = onJump, enabled = canJump)
                    .clip(CircleShape)
                    .background(DS.surface)
                    .border(1.5.dp, DS.hairline, CircleShape)
                    .semantics {
                        contentDescription = StringStore.text(context, "library.section.continue", language)
                    },
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    Icons.Outlined.ArrowCircleDown,
                    contentDescription = null,
                    tint = DS.ink,
                    modifier = Modifier.size(20.dp),
                )
            }
            AnimatedContent(
                targetState = compactLevel,
                contentKey = { it?.id },
                modifier = Modifier.weight(1f).height(TOP_BAR_HEIGHT).clipToBounds(),
                contentAlignment = Alignment.Center,
                transitionSpec = {
                    if (targetState != null) {
                        (slideInVertically(DSMotion.snappy()) { it } + fadeIn()) togetherWith
                            (slideOutVertically(DSMotion.snappy()) { -it } + fadeOut())
                    } else {
                        (slideInVertically(DSMotion.snappy()) { -it } + fadeIn()) togetherWith
                            (slideOutVertically(DSMotion.snappy()) { it } + fadeOut())
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
                            fontSize = 16.sp,
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
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 11.sp,
                            color = DS.inkSecondary,
                            maxLines = 1,
                        )
                    }
                }
            }
            // Same width as the leading button, so the title sits in the middle of the screen.
            Spacer(Modifier.size(40.dp))
        }
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(1.dp)
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
            .padding(top = 4.dp)
            .dsStagger(0),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        if (everythingPassed) {
            Box(
                modifier = Modifier
                    .padding(bottom = 6.dp)
                    .dsPopIn(delayMillis = 100)
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(PathCardPalette.goldTint),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    Icons.Filled.SportsScore,
                    contentDescription = null,
                    tint = PathCardPalette.goldInk,
                    modifier = Modifier.size(24.dp),
                )
            }
        }
        Text(
            text = StringStore.text(context, if (everythingPassed) "path.end.doneTitle" else "path.end.title", language),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 15.sp,
            color = DS.ink,
            textAlign = TextAlign.Center,
        )
        Text(
            text = StringStore.text(context, if (everythingPassed) "path.end.doneBody" else "path.end.body", language),
            fontFamily = PlusJakartaSans,
            fontSize = 13.sp,
            lineHeight = 19.5.sp,
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
        enter = slideInVertically(DSMotion.snappy()) { it } + fadeIn(),
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
