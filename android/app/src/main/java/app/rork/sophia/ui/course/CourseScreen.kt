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
import androidx.compose.material.icons.filled.WifiOff
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
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
import app.rork.sophia.ui.components.CoursePalette
import app.rork.sophia.ui.components.CoursePrimaryButton
import app.rork.sophia.ui.components.CourseRoundIconButton
import app.rork.sophia.ui.components.DSProgressBar
import app.rork.sophia.ui.components.SophiaPrimaryButton
import app.rork.sophia.ui.components.dsPopIn
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.lockedContentBlur
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.newgen.BigHeartOverlay
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextOverflow
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
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.DropdownMenu
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.AutoStories
import androidx.compose.material.icons.filled.ViewDay

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
    // Le vocabulaire haptique du style, pour les gestes que ce lecteur n'accompagnait pas encore.
    val elevateHaptics = rememberHaptics()
    // Le mode de lecture (pas à pas par défaut, par pages au choix), conservé sur l'appareil.
    var readingMode by remember { mutableStateOf(CourseReadingMode.current(context)) }
    var showModeMenu by remember { mutableStateOf(false) }
    // Pas à pas : les passages du cours, combien sont révélés, et la section où en est la lecture.
    var steps by remember(course.id, language) { mutableStateOf<List<ReaderStep>>(emptyList()) }
    var revealed by remember(course.id, language) { mutableIntStateOf(0) }
    var stepSection by remember(course.id, language) { mutableIntStateOf(0) }
    // Les passages révélés avant cet index étaient déjà là (reprise, changement de mode) : ils
    // n'entrent pas en animation.
    var animateFrom by remember(course.id, language) { mutableIntStateOf(0) }
    var scrollToIndex by remember(course.id, language) { mutableIntStateOf(0) }
    var scrollToken by remember(course.id, language) { mutableIntStateOf(0) }
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
                "mode" to readingMode.raw,
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
        // Par pages, retour revient d'une page ; pas à pas, le fil se remonte en défilant.
        if (pagesReady && readingMode == CourseReadingMode.PAGES && pagerState.currentPage > 0) {
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

    // Les passages du mode pas à pas, recalculés quand l'accès change (achat en cours de lecture) ;
    // la lecture reste sur la section en cours, son titre seul révélé.
    LaunchedEffect(pages, isPremium, isDailyFreeCourse, author, meta) {
        if (pages.isEmpty()) return@LaunchedEffect
        steps = buildReaderSteps(
            pages = pages,
            isLocked = { FreemiumGate.isLessonContentLocked(it, isPremium, isDailyFreeCourse) },
            hasFooter = author != null || meta.sources.isNotEmpty(),
        )
        revealed = maxOf(revealed, revealedThroughSection(steps, stepSection)).coerceAtMost(steps.size)
        animateFrom = revealed
    }

    // La section en cours : la page affichée, ou celle du dernier passage révélé.
    val currentSection = if (readingMode == CourseReadingMode.PAGES) pagerState.currentPage else stepSection

    // Par pages : une vibration légère quand la section change (bouton ou glissement). Pas à pas,
    // `advanceStep` vibre déjà à chaque passage.
    var hapticPage by remember(course.id, language) { mutableIntStateOf(-1) }
    LaunchedEffect(pagerState.currentPage, pagesReady, readingMode) {
        if (!pagesReady || readingMode != CourseReadingMode.PAGES) {
            hapticPage = -1
            return@LaunchedEffect
        }
        if (hapticPage >= 0 && hapticPage != pagerState.currentPage) elevateHaptics.soft()
        hapticPage = pagerState.currentPage
    }

    LaunchedEffect(currentSection, pagesReady) {
        if (!pagesReady) return@LaunchedEffect
        val pageIndex = currentSection
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

    // Tout est lu : progression, événements, puis l'écran de fin. Commun aux deux modes.
    fun finishCourse() {
        if (!FreemiumGate.canCompleteCourse(isPremium, isDailyFreeCourse)) return
        logSectionView(reachedEnd = true)
        Analytics.log(
            "course_complete",
            courseId = course.id,
            props = mapOf("first_time" to !wasCompletedBefore, "mode" to readingMode.raw),
        )
        if (!wasCompletedBefore) {
            progressManager.markCourseCompleted(course.id)
            onCourseCompleted()
        }
        showCompleted = true
    }

    // Pas à pas : révèle le passage suivant, ou termine le cours quand tout est lu.
    fun advanceStep() {
        if (steps.isEmpty()) return
        if (revealed >= steps.size) {
            // Cours verrouillé : comme par pages, le bouton ne fait rien au bout ; le paywall
            // ne s'ouvre que par le cadenas.
            if (isPremium || isDailyFreeCourse) finishCourse()
            return
        }
        val step = steps[revealed]
        haptics.performHapticFeedback(
            if (step.opensChapter) HapticFeedbackType.LongPress else HapticFeedbackType.TextHandleMove,
        )
        scrollToIndex = revealed
        revealed += 1
        scrollToken += 1
        if (step.sectionIndex != stepSection) stepSection = step.sectionIndex
    }

    fun changeReadingMode(mode: CourseReadingMode) {
        showModeMenu = false
        if (mode == readingMode) return
        haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove)
        CourseReadingMode.save(context, mode)
        if (mode == CourseReadingMode.STEPS) {
            // Reprendre à la section en cours : les précédentes entières, puis son titre seul.
            stepSection = pagerState.currentPage
            revealed = revealedThroughSection(steps, stepSection)
            animateFrom = revealed
            if (stepSection > 0) {
                scrollToIndex = revealed - 1
                scrollToken += 1
            }
            readingMode = mode
        } else {
            val target = stepSection.coerceIn(0, (pages.size - 1).coerceAtLeast(0))
            readingMode = mode
            scope.launch { pagerState.scrollToPage(target) }
        }
    }

    // L'en-tête d'une section et le pied du cours, dessinés de la même façon dans les deux modes
    // de lecture (par pages et pas à pas).
    val sectionHeader: @Composable (Int, ReaderPage) -> Unit = { index, page ->
        // The title stays sharp; only the paid body is blurred.
        ReaderSectionTitle(page.title)
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
    }
    val readerFooter: @Composable () -> Unit = {
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

    Box(modifier = Modifier.fillMaxSize()) {
        Column(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
            // L'en-tête de la maquette : fermer, la progression fine par sections et son
            // compteur, le mode de lecture, l'écoute.
            val stepsMode = readingMode == CourseReadingMode.STEPS && steps.isNotEmpty()
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(start = 20.dp, end = 20.dp, top = 10.dp, bottom = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                CourseRoundIconButton(
                    icon = Icons.Filled.Close,
                    onClick = onDismiss,
                    contentDescription = StringStore.text(context, "common.close", language),
                    size = 42.dp,
                )
                // Une capsule par section, remplies jusqu'à la courante (maquette) ; au-delà de douze
                // sections les capsules deviendraient des pointillés, la barre continue reprend.
                // Pas à pas, chaque capsule se remplit passage après passage.
                val sectionLabel = if (pages.isEmpty()) {
                    ""
                } else {
                    StringStore.text(context, "common.sectionOf", language, currentSection + 1, pages.size)
                }
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .padding(horizontal = 2.dp)
                        .clearAndSetSemantics { contentDescription = sectionLabel },
                ) {
                    if (pages.size in 1..12) {
                        SteppedProgressBar(
                            fills = pages.indices.map { section ->
                                if (stepsMode) {
                                    sectionFill(steps, revealed, section)
                                } else if (section <= pagerState.currentPage) {
                                    1f
                                } else {
                                    0f
                                }
                            },
                        )
                    } else {
                        DSProgressBar(
                            value = when {
                                pages.isEmpty() -> 0f
                                stepsMode -> revealed.toFloat() / steps.size
                                else -> (pagerState.currentPage + 1).toFloat() / pages.size
                            },
                            height = 5.dp,
                            track = CoursePalette.track,
                        )
                    }
                }
                if (pages.isNotEmpty()) {
                    Text(
                        text = "${currentSection + 1} / ${pages.size}",
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 13.sp,
                        color = DS.inkSecondary,
                        maxLines = 1,
                        modifier = Modifier.clearAndSetSemantics { },
                    )
                }
                // Le choix du mode de lecture : pas à pas ou par pages, pour tous les cours.
                Box {
                    CourseRoundIconButton(
                        icon = Icons.Filled.MoreHoriz,
                        onClick = { showModeMenu = true },
                        contentDescription = StringStore.text(context, "course.readingMode", language),
                        size = 42.dp,
                    )
                    DropdownMenu(expanded = showModeMenu, onDismissRequest = { showModeMenu = false }) {
                        CourseReadingMode.entries.forEach { mode ->
                            DropdownMenuItem(
                                text = { Text(text = StringStore.text(context, mode.titleKey, language), style = SophiaTypography.bodyLarge) },
                                onClick = { changeReadingMode(mode) },
                                leadingIcon = {
                                    Icon(
                                        imageVector = if (mode == CourseReadingMode.STEPS) Icons.Filled.ViewDay else Icons.Filled.AutoStories,
                                        contentDescription = null,
                                        tint = DS.inkSecondary,
                                    )
                                },
                                trailingIcon = {
                                    if (mode == readingMode) {
                                        Icon(imageVector = Icons.Filled.Check, contentDescription = null, tint = DS.accent)
                                    }
                                },
                            )
                        }
                    }
                }
                CourseReaderAudioButton(
                    courseId = course.id,
                    language = language,
                    isPremium = isPremium,
                    onLocked = { onRequestPaywall("audio") },
                    onOpenPlayer = onOpenAudio,
                )
            }
            // Le titre du cours, en légende discrète sous l'en-tête.
            Text(
                text = course.title,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 13.sp,
                color = DS.inkSecondary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp).padding(bottom = 4.dp),
            )

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
            } else if (readingMode == CourseReadingMode.STEPS) {
                Box(modifier = Modifier.weight(1f).fillMaxWidth()) {
                    CourseStepReader(
                        steps = steps,
                        revealed = revealed,
                        animateFrom = animateFrom,
                        scrollToIndex = scrollToIndex,
                        scrollToken = scrollToken,
                        onDoubleTap = { likeFromDoubleTap() },
                        modifier = Modifier.fillMaxSize(),
                    ) { step ->
                        val page = pages.getOrNull(step.sectionIndex)
                        when (step) {
                            is ReaderStep.Header -> Column(verticalArrangement = Arrangement.spacedBy(DS.Space.m)) {
                                if (page != null) sectionHeader(step.sectionIndex, page)
                            }
                            is ReaderStep.Block -> Column(verticalArrangement = Arrangement.spacedBy(24.dp)) {
                                step.heading?.let { heading ->
                                    ReaderBlockView(
                                        block = ReaderBlock.Heading(heading),
                                        language = language,
                                        courseId = course.id,
                                        locked = false,
                                    )
                                }
                                ReaderBlockView(block = step.block, language = language, courseId = course.id, locked = false)
                            }
                            is ReaderStep.Footer -> Column(verticalArrangement = Arrangement.spacedBy(DS.Space.m)) {
                                readerFooter()
                            }
                            // Une section réservée : la page floutée, raccourcie, le cadenas
                            // par-dessus. Seul le cadenas ouvre le paywall.
                            is ReaderStep.Locked -> Box(modifier = Modifier.fillMaxWidth().height(440.dp)) {
                                Column(
                                    modifier = Modifier.fillMaxSize().clipToBounds(),
                                    verticalArrangement = Arrangement.spacedBy(DS.Space.m),
                                ) {
                                    if (page != null) {
                                        ReaderSectionTitle(page.title)
                                        Column(
                                            modifier = Modifier.lockedContentBlur(true),
                                            verticalArrangement = Arrangement.spacedBy(DS.Space.m),
                                        ) {
                                            page.blocks.forEach { block ->
                                                ReaderBlockView(block = block, language = language, courseId = course.id, locked = true)
                                            }
                                        }
                                    }
                                }
                                CourseLessonLockOverlay { onRequestPaywall("debloquer_cours") }
                            }
                        }
                    }
                    BigHeartOverlay(trigger = bigHeart, modifier = Modifier.align(Alignment.Center))
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
                                .padding(horizontal = 24.dp, vertical = DS.Space.l),
                            verticalArrangement = Arrangement.spacedBy(DS.Space.l),
                        ) {
                            sectionHeader(index, page)
                            Column(
                                modifier = Modifier.lockedContentBlur(locked),
                                verticalArrangement = Arrangement.spacedBy(DS.Space.l),
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
                                if (index == pages.lastIndex) readerFooter()
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
                    .padding(start = 24.dp, end = 24.dp, top = 8.dp, bottom = 24.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                // Sans pages (téléchargement en cours, hors ligne), rien n'est « dernier » : le
                // bouton reste « Continuer », inactif, et ne peut pas terminer un cours jamais lu.
                val isLast = pagesReady && if (readingMode == CourseReadingMode.STEPS) {
                    steps.isNotEmpty() && revealed >= steps.size
                } else {
                    pagerState.currentPage >= pages.lastIndex
                }
                val courseLocked = !isPremium && !isDailyFreeCourse
                // « Terminer le cours » porte une coche ; « Continuer » et « Quiz » une flèche.
                val finishing = isLast && !courseLocked && !course.hasQuiz
                // Le CTA bleu du style, sans vibration propre : chaque geste choisit la sienne
                // (pas à pas dans `advanceStep` ; par pages, au changement de section ; la fin du
                // cours fête elle-même).
                CoursePrimaryButton(
                    text = when {
                        courseLocked || !isLast -> StringStore.text(context, "course.continue", language)
                        course.hasQuiz -> StringStore.text(context, "course.quiz", language)
                        else -> StringStore.text(context, "course.finish", language)
                    },
                    enabled = pagesReady,
                    haptic = false,
                    leadingIcon = if (finishing) Icons.Filled.Check else null,
                    trailingIcon = if (finishing) null else Icons.AutoMirrored.Filled.ArrowForward,
                    onClick = {
                        if (!pagesReady) return@CoursePrimaryButton
                        if (readingMode == CourseReadingMode.STEPS) {
                            advanceStep()
                            return@CoursePrimaryButton
                        }
                        if (courseLocked) {
                            if (!isLast) {
                                scope.launch { pagerState.animateScrollToPage(pagerState.currentPage + 1) }
                            }
                            return@CoursePrimaryButton
                        }
                        if (isLast) {
                            finishCourse()
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
        // La carte du style : blanche, bordée, qui monte en se posant.
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .dsStagger(0, offset = 24.dp)
                .sophiaCard()
                .padding(DS.Space.l),
        ) {
            Text(
                text = StringStore.text(context, "explain.course.title", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 19.sp,
                lineHeight = 25.sp,
                color = DS.ink,
            )
            Spacer(Modifier.height(8.dp))
            Text(text = body, style = SophiaTypography.bodyMedium)
            Spacer(Modifier.height(16.dp))
            SophiaPrimaryButton(text = "OK", onClick = onDismiss)
        }
    }
}

/** Le titre d'une section : graisse moyenne, interlignage posé, annoncé comme un titre. */
@Composable
private fun ReaderSectionTitle(text: String) {
    Text(
        text = text,
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.SemiBold,
        fontSize = 24.sp,
        lineHeight = 31.sp,
        color = DS.ink,
        modifier = Modifier.padding(top = 6.dp).semantics { heading() },
    )
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
            Box(
                modifier = Modifier.size(88.dp).dsPopIn().background(DS.accentTint, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = Icons.Filled.WifiOff,
                    contentDescription = null,
                    tint = DS.accent,
                    modifier = Modifier.size(36.dp),
                )
            }
            Text(
                text = StringStore.text(context, "course.offline.title", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 20.sp,
                lineHeight = 26.sp,
                color = DS.ink,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 6.dp).dsStagger(1),
            )
            Text(
                text = StringStore.text(context, "course.offline.body", language),
                style = SophiaTypography.bodyMedium,
                color = DS.inkSecondary,
                textAlign = TextAlign.Center,
                modifier = Modifier.dsStagger(2),
            )
            SophiaPrimaryButton(
                text = StringStore.text(context, "course.offline.retry", language),
                onClick = onRetry,
                modifier = Modifier.padding(top = 4.dp).dsStagger(3),
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

internal data class ReaderPage(val title: String, val blocks: List<ReaderBlock>)

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
            modifier = Modifier.fillMaxWidth().padding(start = 24.dp, end = 20.dp, top = 10.dp, bottom = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Icon(imageVector = Icons.Filled.Public, contentDescription = null, tint = DS.accent, modifier = Modifier.size(18.dp))
            Text(
                text = original.displayName,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 18.sp,
                color = DS.ink,
                modifier = Modifier.weight(1f),
            )
            CourseRoundIconButton(
                icon = Icons.Filled.Close,
                onClick = onClose,
                contentDescription = StringStore.text(context, "common.close", language),
                size = 42.dp,
            )
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
                            .padding(start = 24.dp, end = 24.dp, top = 8.dp, bottom = 40.dp),
                        verticalArrangement = Arrangement.spacedBy(40.dp),
                    ) {
                        loaded.forEach { page ->
                            Column(verticalArrangement = Arrangement.spacedBy(DS.Space.l)) {
                                ReaderSectionTitle(page.title)
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
