package app.rork.sophia.ui.course

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.WifiOff
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.AuthorStore
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.CourseCoverUrls
import app.rork.sophia.data.CourseImagePrefetch
import app.rork.sophia.data.GlossaryStore
import app.rork.sophia.data.InAppReviewHelper
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.analytics.Analytics
import app.rork.sophia.data.catalog.CatalogStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Course
import app.rork.sophia.domain.FreemiumGate
import app.rork.sophia.ui.audio.CourseReaderAudioButton
import app.rork.sophia.ui.components.CalmProgressBar
import app.rork.sophia.ui.components.CircleIconButton
import app.rork.sophia.ui.components.SophiaPrimaryButton
import app.rork.sophia.ui.components.lockedContentBlur
import app.rork.sophia.ui.newgen.BigHeartOverlay
import app.rork.sophia.ui.newgen.SegmentedProgressBar
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import app.rork.sophia.domain.CourseOrigins
import app.rork.sophia.ui.components.softPress
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.material.icons.filled.Public
import androidx.compose.material.icons.filled.Close

@Composable
fun CourseScreen(
    course: Course,
    language: AppLanguage,
    isPremium: Boolean,
    isDailyFreeCourse: Boolean,
    progressManager: ProgressManager,
    onDismiss: () -> Unit,
    onCourseCompleted: () -> Unit,
    onRequestPaywall: (String) -> Unit,
    /** Byline or "written by" card tapped: the professor's slug. */
    onOpenAuthor: (String) -> Unit = {},
    /** Headphones tapped by a premium listener: show the full audio player. */
    onOpenAudio: () -> Unit = {},
) {
    val context = LocalContext.current
    // Suivi pour le bouton « Suivre » de la carte auteur ; le reste lit `progress.value`.
    val progressSnapshot by progressManager.progress.collectAsState()
    var showQuiz by remember { mutableStateOf(false) }
    // « Voir l'original » : la langue d'écriture du cours, présentée par-dessus le lecteur.
    var originalLanguage by remember(course.id) { mutableStateOf<AppLanguage?>(null) }
    var showCompleted by remember(course.id) { mutableStateOf(false) }
    var showCoachmark by remember { mutableStateOf(false) }
    var coachmarkTerm by remember { mutableStateOf<String?>(null) }
    val wasCompletedBefore = remember(course.id) {
        progressManager.courseProgress(course.id)?.isCompleted == true
    }
    var pages by remember(course.id, language) { mutableStateOf<List<ReaderPage>>(emptyList()) }
    var meta by remember(course.id, language) { mutableStateOf(ReaderMeta()) }
    val author = remember(meta.authorSlug) { meta.authorSlug?.let { AuthorStore.author(it) } }
    var pagesReady by remember(course.id, language) { mutableStateOf(false) }
    // A pager per course, so the page reached in the previous course cannot leak into
    // this one. Resetting it with scrollToPage instead would deadlock: that call waits
    // for the pager's first layout, which only happens once `pagesReady` is true.
    val pagerState = key(course.id, language) {
        rememberPagerState(pageCount = { pages.size.coerceAtLeast(1) })
    }
    val scope = rememberCoroutineScope()
    val haptics = LocalHapticFeedback.current
    // Double-tap sur une leçon : le grand cœur du fil, même règle (il n'éteint jamais).
    var bigHeart by remember(course.id) { mutableIntStateOf(0) }
    fun likeFromDoubleTap() {
        haptics.performHapticFeedback(HapticFeedbackType.LongPress)
        bigHeart++
        if (progressManager.isLiked(course.id)) return
        progressManager.toggleLike(course.id)
        Analytics.log("like", courseId = course.id, screen = "reader")
    }

    // Temps passé par section (`section_view`, docs/events.md) : la section suivie et son
    // heure d'entrée ; -1 quand rien n'est suivi (pages pas prêtes, cours terminé).
    var trackedSection by remember(course.id, language) { mutableIntStateOf(-1) }
    var sectionEnteredAt by remember(course.id, language) { mutableLongStateOf(0L) }
    fun logSectionView(reachedEnd: Boolean) {
        val index = trackedSection
        if (index < 0) return
        trackedSection = -1
        val seconds = ((System.currentTimeMillis() - sectionEnteredAt) / 1000).toInt()
        // Le temps passé sur la section nourrit le compteur « lecture » du profil (plafonné à une heure).
        progressManager.addReadingSeconds(seconds)
        Analytics.log(
            "section_view",
            courseId = course.id,
            props = mapOf(
                "section_index" to index,
                "section_count" to pages.size,
                "seconds" to seconds,
                "reached_end" to reachedEnd,
            ),
        )
    }
    // Lecteur refermé en cours de route : la section en cours compte comme quittée.
    DisposableEffect(course.id, language) {
        onDispose { logSectionView(reachedEnd = false) }
    }

    // Le texte vient du catalogue en ligne : la copie locale (pack de départ ou téléchargée)
    // sert tout de suite ; sinon le paquet est téléchargé avant la première page, et hors
    // ligne le lecteur montre un état d'attente avec « Réessayer ».
    var contentState by remember(course.id, language) { mutableStateOf(ReaderContentState.CHECKING) }
    var loadAttempt by remember(course.id, language) { mutableIntStateOf(0) }

    LaunchedEffect(course.id, language, loadAttempt) {
        val appContext = context.applicationContext
        val hasLocal = withContext(Dispatchers.IO) {
            ContentCatalog.hasStructuredContent(appContext, language, course.id)
        }
        if (!hasLocal && !ContentCatalog.isWithheld(language, course.id)) {
            contentState = ReaderContentState.LOADING
            val fetched = CatalogStore.ensureContent(course.id, language)
            if (fetched == null && course.lessons.isEmpty()) {
                contentState = ReaderContentState.UNAVAILABLE
                return@LaunchedEffect
            }
        }
        contentState = ReaderContentState.READY
        val (loaded, loadedMeta) = withContext(Dispatchers.IO) {
            GlossaryStore.preload(appContext, language)
            AuthorStore.preload(appContext)
            // Resolves inline image slugs; without this the first block would read
            // the map from assets during composition.
            CourseCoverUrls.ensureBlockMap(appContext)
            val built = buildPages(appContext, course, language).also { pages ->
                // Enqueue while the spinner is still up, so the opening pages are
                // already decoded by the time they are scrolled into view.
                CourseImagePrefetch.warmAssets(appContext, pages.leadingImageAssets(PREFETCH_IMAGES))
            }
            built to structuredMeta(appContext, course, language)
        }
        pages = loaded
        meta = loadedMeta
        pagesReady = true
        progressManager.recordFirstCourseOpenedIfNeeded(course.id)
    }

    // Inside a course, back is a step backwards through the reader, not an exit from the
    // app. Only the first page hands back to whoever opened the course.
    BackHandler(enabled = showQuiz) { showQuiz = false }
    BackHandler(enabled = originalLanguage != null) { originalLanguage = null }
    BackHandler(enabled = !showQuiz && showCompleted) { onDismiss() }
    BackHandler(enabled = !showQuiz && !showCompleted) {
        if (pagesReady && pagerState.currentPage > 0) {
            scope.launch { pagerState.animateScrollToPage(pagerState.currentPage - 1) }
        } else {
            onDismiss()
        }
    }

    if (showQuiz) {
        QuizScreen(
            course = course,
            language = language,
            isPremium = isPremium,
            progressManager = progressManager,
            onRequestPaywall = { onRequestPaywall("quizz") },
            onDismiss = {
                showQuiz = false
                onDismiss()
            },
            onFinished = {
                onCourseCompleted()
                onDismiss()
            },
        )
        return
    }

    if (showCompleted) {
        val level = ProgressManager.globalLevelProgress(progressManager.progress.value.globalXP)
        CourseCompletedScreen(
            course = course,
            language = language,
            earnedXP = COURSE_COMPLETION_XP,
            level = level.level,
            xpIntoLevel = level.xpIntoLevel,
            xpForLevel = level.xpForLevel,
            showQuizCta = course.hasQuiz,
            quizLocked = !isPremium,
            freemiumNote = if (!isPremium) {
                StringStore.text(context, "paywall.course.subtitle", language)
            } else {
                null
            },
            progress = progressSnapshot,
            progressManager = progressManager,
            onClose = onDismiss,
            onQuiz = {
                showCompleted = false
                showQuiz = true
            },
        )
        return
    }

    originalLanguage?.let { original ->
        OriginalCourseOverlay(
            course = course,
            original = original,
            language = language,
            onClose = { originalLanguage = null },
        )
        return
    }

    LaunchedEffect(pagerState.currentPage, pagesReady) {
        if (!pagesReady) return@LaunchedEffect
        val pageIndex = pagerState.currentPage
        if (trackedSection != pageIndex) {
            // Page suivante : la précédente a été lue jusqu'au bout ; page précédente : non.
            logSectionView(reachedEnd = pageIndex > trackedSection)
            trackedSection = pageIndex
            sectionEnteredAt = System.currentTimeMillis()
        }
        progressManager.updateLessonIndex(course.id, pageIndex, lessonCount = pages.size)
        InAppReviewHelper.requestIfEligible(
            context = context,
            progressManager = progressManager,
            courseId = course.id,
            lessonIndex = pageIndex,
        )
        val page = pages.getOrNull(pageIndex) ?: return@LaunchedEffect
        val locked = FreemiumGate.isLessonContentLocked(
            pageIndex,
            isPremium,
            isDailyFreeCourse,
        )
        if (!locked && !progressManager.hasSeenCourseTermsCoachmark && !showCoachmark) {
            val term = firstGlossaryTerm(page)
            if (term != null) {
                coachmarkTerm = term
                showCoachmark = true
            }
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        Column(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = DS.Space.s, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                CircleIconButton(icon = Icons.AutoMirrored.Filled.ArrowBack, onClick = onDismiss)
                Text(
                    text = course.title,
                    style = SophiaTypography.titleMedium.copy(fontSize = 16.sp),
                    maxLines = 1,
                    modifier = Modifier.weight(1f).padding(horizontal = 12.dp),
                )
                CourseReaderAudioButton(
                    courseId = course.id,
                    language = language,
                    isPremium = isPremium,
                    onLocked = { onRequestPaywall("audio") },
                    onOpenPlayer = onOpenAudio,
                )
            }
            // Une capsule par section, remplies jusqu'à la courante (maquette) ; au-delà de douze
            // sections les capsules deviendraient des pointillés, la barre continue reprend.
            if (pages.size in 1..12) {
                SegmentedProgressBar(
                    count = pages.size,
                    current = pagerState.currentPage,
                    modifier = Modifier.padding(horizontal = DS.Space.l),
                )
            } else {
                CalmProgressBar(
                    fraction = if (pages.isEmpty()) 0f else (pagerState.currentPage + 1).toFloat() / pages.size,
                    modifier = Modifier.padding(horizontal = DS.Space.l),
                )
            }

            if (!pagesReady) {
                Box(
                    modifier = Modifier.weight(1f).fillMaxWidth(),
                    contentAlignment = Alignment.Center,
                ) {
                    ReaderContentPlaceholder(
                        state = contentState,
                        language = language,
                        onRetry = { loadAttempt += 1 },
                    )
                }
            } else {
                HorizontalPager(
                    state = pagerState,
                    modifier = Modifier.weight(1f).fillMaxWidth(),
                    beyondViewportPageCount = 0,
                    userScrollEnabled = true,
                ) { index ->
                    val locked = FreemiumGate.isLessonContentLocked(index, isPremium, isDailyFreeCourse)
                    val page = pages.getOrNull(index) ?: return@HorizontalPager
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            // Deux taps n'importe où sur une leçon lue : « j'aime », comme sur la carte du fil.
                            .then(if (locked) Modifier else Modifier.pointerInput(course.id) { detectTapGestures(onDoubleTap = { likeFromDoubleTap() }) }),
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxSize()
                                .verticalScroll(rememberScrollState(), enabled = !locked)
                                .padding(DS.Space.l),
                            verticalArrangement = Arrangement.spacedBy(DS.Space.m),
                        ) {
                            // The title stays sharp; only the paid body is blurred.
                            Text(text = page.title, style = SophiaTypography.titleLarge)
                            // The intro is the free page: who wrote the course belongs there.
                            if (index == 0 && author != null) {
                                AuthorByline(
                                    author = author,
                                    language = language,
                                    onClick = { onOpenAuthor(author.slug) },
                                )
                            }
                            // Un cours écrit dans une autre langue le dit sous la signature.
                            if (index == 0) {
                                CourseOrigins.translatedFromCode(course.id, meta.originalLanguage, language)?.let { code ->
                                    // « Voir l'original » : réservé à qui peut lire le cours en
                                    // entier, et seulement si l'app connaît cette langue.
                                    val original = CourseOrigins.language(course.id, meta.originalLanguage, language)
                                    val hasFullAccess = !FreemiumGate.isLessonContentLocked(
                                        pages.lastIndex,
                                        isPremium,
                                        isDailyFreeCourse,
                                    )
                                    TranslatedFromLine(
                                        code = code,
                                        language = language,
                                        onShowOriginal = if (original != null && hasFullAccess) {
                                            { originalLanguage = original }
                                        } else {
                                            null
                                        },
                                    )
                                }
                            }
                            Column(
                                modifier = Modifier.lockedContentBlur(locked),
                                verticalArrangement = Arrangement.spacedBy(DS.Space.m),
                            ) {
                                page.blocks.forEach { block ->
                                    ReaderBlockView(
                                        block = block,
                                        language = language,
                                        courseId = course.id,
                                        locked = locked,
                                    )
                                }
                                // Signature and references close the last page, after "À retenir".
                                if (index == pages.lastIndex) {
                                    if (author != null) {
                                        AuthorCard(
                                            author = author,
                                            language = language,
                                            onOpenAuthor = { onOpenAuthor(author.slug) },
                                            isFollowing = author.slug in progressSnapshot.followedCreatorSlugs,
                                            onFollow = {
                                                val wasFollowing = progressManager.isFollowing(author.slug)
                                                progressManager.toggleFollow(author.slug)
                                                Analytics.log(
                                                    if (wasFollowing) "unfollow" else "follow",
                                                    courseId = course.id,
                                                    screen = "reader",
                                                    props = mapOf("creator" to author.slug),
                                                )
                                            },
                                        )
                                    }
                                    if (meta.sources.isNotEmpty()) {
                                        SourcesCard(sources = meta.sources, language = language)
                                    }
                                }
                            }
                        }
                        if (locked) {
                            CourseLessonLockOverlay {
                                onRequestPaywall("debloquer_cours")
                            }
                        }
                        BigHeartOverlay(trigger = bigHeart, modifier = Modifier.align(Alignment.Center))
                    }
                }
            }

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(DS.Space.l),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                // Sans pages (téléchargement en cours, hors ligne), rien n'est « dernier » : le
                // bouton reste « Continuer », inactif, et ne peut pas terminer un cours jamais lu.
                val isLast = pagesReady && pagerState.currentPage >= pages.lastIndex
                val courseLocked = !isPremium && !isDailyFreeCourse
                SophiaPrimaryButton(
                    text = when {
                        courseLocked || !isLast -> StringStore.text(context, "course.continue", language)
                        course.hasQuiz -> StringStore.text(context, "course.quiz", language)
                        else -> StringStore.text(context, "course.finish", language)
                    },
                    enabled = pagesReady,
                    onClick = {
                        if (!pagesReady) return@SophiaPrimaryButton
                        if (courseLocked) {
                            if (!isLast) {
                                scope.launch { pagerState.animateScrollToPage(pagerState.currentPage + 1) }
                            }
                            return@SophiaPrimaryButton
                        }
                        if (isLast) {
                            if (FreemiumGate.canCompleteCourse(isPremium, isDailyFreeCourse)) {
                                logSectionView(reachedEnd = true)
                                Analytics.log("course_complete", courseId = course.id, props = mapOf("first_time" to !wasCompletedBefore))
                                if (!wasCompletedBefore) {
                                    progressManager.markCourseCompleted(course.id)
                                    onCourseCompleted()
                                }
                                showCompleted = true
                            }
                        } else {
                            scope.launch { pagerState.animateScrollToPage(pagerState.currentPage + 1) }
                        }
                    },
                )
            }
        }

        if (showCoachmark && coachmarkTerm != null) {
            GlossaryTermCoachmark(
                term = coachmarkTerm!!,
                language = language,
                onDismiss = {
                    progressManager.markCourseTermsCoachmarkSeen()
                    showCoachmark = false
                },
            )
        }
    }
}

@Composable
fun GlossaryTermCoachmark(
    term: String,
    language: AppLanguage,
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    val body = StringStore.text(context, "explain.course.termBody", language)
        .replace("%@", term)
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.45f))
            .padding(DS.Space.l),
        contentAlignment = Alignment.BottomCenter,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(DS.surface, DS.cardShape)
                .padding(DS.Space.m),
        ) {
            Text(
                text = StringStore.text(context, "explain.course.title", language),
                style = SophiaTypography.titleMedium,
            )
            Spacer(Modifier.height(8.dp))
            Text(text = body, style = SophiaTypography.bodyMedium)
            Spacer(Modifier.height(16.dp))
            Button(
                onClick = onDismiss,
                modifier = Modifier.fillMaxWidth().height(48.dp),
                shape = DS.controlShape,
                colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
            ) {
                Text("OK", color = Color.White, fontFamily = PlusJakartaSans, fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

private const val PREFETCH_IMAGES = 4

/** Où en est le texte du cours avant la première page. */
private enum class ReaderContentState {
    /** On regarde si le paquet est déjà sur le téléphone. */
    CHECKING,

    /** Le paquet se télécharge depuis le catalogue en ligne. */
    LOADING,

    /** Le texte est là ; les pages se construisent. */
    READY,

    /** Hors ligne et jamais téléchargé. */
    UNAVAILABLE,
}

/**
 * Ce qu'affiche le lecteur avant la première page : une roue (et « Téléchargement du cours… »
 * quand le paquet vient du réseau), ou l'état hors ligne avec un bouton pour réessayer.
 */
@Composable
private fun ReaderContentPlaceholder(
    state: ReaderContentState,
    language: AppLanguage,
    onRetry: () -> Unit,
) {
    val context = LocalContext.current
    if (state == ReaderContentState.UNAVAILABLE) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = DS.Space.xl),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Icon(
                imageVector = Icons.Filled.WifiOff,
                contentDescription = null,
                tint = DS.inkTertiary,
                modifier = Modifier.size(36.dp),
            )
            Text(
                text = StringStore.text(context, "course.offline.title", language),
                style = SophiaTypography.titleMedium,
                textAlign = TextAlign.Center,
            )
            Text(
                text = StringStore.text(context, "course.offline.body", language),
                style = SophiaTypography.bodyMedium,
                color = DS.inkSecondary,
                textAlign = TextAlign.Center,
            )
            SophiaPrimaryButton(
                text = StringStore.text(context, "course.offline.retry", language),
                onClick = onRetry,
                modifier = Modifier.padding(top = 4.dp),
            )
        }
    } else {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            CircularProgressIndicator(color = DS.accent)
            if (state == ReaderContentState.LOADING) {
                Text(
                    text = StringStore.text(context, "course.loading", language),
                    style = SophiaTypography.bodyMedium,
                    color = DS.inkSecondary,
                )
            }
        }
    }
}

/** Matches the +50 global XP granted by `ProgressManager.markCourseCompleted`. */
private const val COURSE_COMPLETION_XP = 50

private data class ReaderPage(val title: String, val blocks: List<ReaderBlock>)

/**
 * Le cours dans sa langue d'écriture, en un seul défilement, par-dessus le lecteur
 * (`OriginalCourseView` sur iOS). Le texte est téléchargé à la demande : il n'est sur le
 * téléphone que si l'app a déjà été utilisée dans cette langue.
 */
@Composable
private fun OriginalCourseOverlay(
    course: Course,
    original: AppLanguage,
    language: AppLanguage,
    onClose: () -> Unit,
) {
    val context = LocalContext.current
    var pages by remember(course.id, original) { mutableStateOf<List<ReaderPage>?>(null) }
    var loading by remember(course.id, original) { mutableStateOf(true) }
    var attempt by remember(course.id, original) { mutableIntStateOf(0) }
    LaunchedEffect(course.id, original, attempt) {
        loading = true
        val appContext = context.applicationContext
        val text = CatalogStore.ensureContent(course.id, original)
        pages = if (text == null) {
            null
        } else {
            withContext(Dispatchers.IO) {
                CourseCoverUrls.ensureBlockMap(appContext)
                structuredPages(appContext, course, original).takeIf { it.isNotEmpty() }
            }
        }
        loading = false
    }
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas)
            .pointerInput(Unit) { detectTapGestures { } },
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(start = 20.dp, end = 20.dp, top = 12.dp, bottom = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Icon(imageVector = Icons.Filled.Public, contentDescription = null, tint = DS.accent, modifier = Modifier.size(18.dp))
            Text(
                text = original.displayName,
                style = SophiaTypography.titleMedium,
                color = DS.ink,
                modifier = Modifier.weight(1f),
            )
            IconButton(onClick = onClose) {
                Icon(
                    imageVector = Icons.Filled.Close,
                    contentDescription = StringStore.text(context, "common.close", language),
                    tint = DS.ink,
                )
            }
        }
        val loaded = pages
        when {
            loaded != null -> {
                // Le texte suit le sens d'écriture de sa langue, pas celui de l'app.
                CompositionLocalProvider(
                    LocalLayoutDirection provides if (original.isRtl) LayoutDirection.Rtl else LayoutDirection.Ltr,
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .verticalScroll(rememberScrollState())
                            .padding(start = 20.dp, end = 20.dp, top = 8.dp, bottom = 40.dp),
                        verticalArrangement = Arrangement.spacedBy(40.dp),
                    ) {
                        loaded.forEach { page ->
                            Column(verticalArrangement = Arrangement.spacedBy(DS.Space.m)) {
                                Text(text = page.title, style = SophiaTypography.titleLarge)
                                page.blocks.forEach { block ->
                                    ReaderBlockView(block = block, language = original, courseId = course.id, locked = false)
                                }
                            }
                        }
                    }
                }
            }
            loading -> Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = DS.accent)
            }
            else -> Column(
                modifier = Modifier.fillMaxSize().padding(32.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterVertically),
            ) {
                Text(
                    text = StringStore.text(context, "course.offline.body", language),
                    style = SophiaTypography.bodyLarge,
                    color = DS.inkSecondary,
                    textAlign = TextAlign.Center,
                )
                Text(
                    text = StringStore.text(context, "course.offline.retry", language),
                    style = SophiaTypography.titleMedium,
                    color = DS.accentSoft,
                    modifier = Modifier.softPress(onClick = { attempt++ }),
                )
            }
        }
    }
}

/**
 * Author slug, references and original language of a course, read from the V2 root.
 * [originalLanguage] n'est posé que pour les cours traduits (`originalLanguage` du JSON).
 */
data class ReaderMeta(
    val authorSlug: String? = null,
    val sources: List<ReaderSource> = emptyList(),
    val originalLanguage: String? = null,
)

private fun JsonObject.text(key: String): String? =
    (this[key] as? JsonPrimitive)?.contentOrNull?.takeIf { it.isNotBlank() }

private fun structuredMeta(
    context: android.content.Context,
    course: Course,
    language: AppLanguage,
): ReaderMeta {
    val raw = ContentCatalog.structuredContentJson(context, language, course.id) ?: return ReaderMeta()
    return try {
        val root = Json.parseToJsonElement(raw).jsonObject
        val sources = root["sources"]?.jsonArray.orEmpty().mapNotNull { element ->
            val source = element as? JsonObject ?: return@mapNotNull null
            val text = source.text("text") ?: return@mapNotNull null
            ReaderSource(text = text, url = source.text("url")?.takeIf { it.startsWith("http") })
        }
        ReaderMeta(
            authorSlug = root.text("author"),
            sources = sources,
            originalLanguage = root.text("originalLanguage"),
        )
    } catch (_: Exception) {
        ReaderMeta()
    }
}

/** Inline image assets in reading order, so the first pages are warmed first. */
private fun List<ReaderPage>.leadingImageAssets(limit: Int): List<String> =
    asSequence()
        .flatMap { it.blocks.asSequence() }
        .filterIsInstance<ReaderBlock.Image>()
        .map { it.asset }
        .distinct()
        .take(limit)
        .toList()

private fun firstGlossaryTerm(page: ReaderPage): String? {
    val pattern = Regex("\\[\\[([^\\]]+)\\]\\]")
    page.blocks.forEach { block ->
        val raw = block.proseText ?: return@forEach
        val term = pattern.find(raw)?.groupValues?.getOrNull(1)?.trim()
        if (!term.isNullOrEmpty()) return term
    }
    return null
}

private fun buildPages(
    context: android.content.Context,
    course: Course,
    language: AppLanguage,
): List<ReaderPage> = structuredPages(context, course, language)
    .ifEmpty { course.lessons.map { ReaderPage(it.title, paragraphs(it.content)) } }
    .ifEmpty { listOf(ReaderPage(course.title, paragraphs(course.description))) }

/** Legacy lessons carry one blob of prose, split on blank lines. */
private fun paragraphs(content: String): List<ReaderBlock> =
    content.split("\n\n")
        .map { it.trim() }
        .filter { it.isNotEmpty() }
        .map { ReaderBlock.Paragraph(it) }

private fun structuredPages(
    context: android.content.Context,
    course: Course,
    language: AppLanguage,
): List<ReaderPage> {
    val raw = ContentCatalog.structuredContentJson(context, language, course.id)
    if (raw != null) {
        return try {
            val root = Json.parseToJsonElement(raw).jsonObject
            val sections = root["sections"]?.jsonArray.orEmpty()
            sections.mapNotNull { el ->
                val obj = el.jsonObject
                val title = obj["title"]?.jsonPrimitive?.content ?: return@mapNotNull null
                val blocks = obj["blocks"]?.jsonArray ?: return@mapNotNull null
                ReaderPage(title, parseReaderBlocks(blocks))
            }
        } catch (_: Exception) {
            emptyList()
        }
    }
    return emptyList()
}
