package app.rork.sophia.ui.course

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
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
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.CourseCoverUrls
import app.rork.sophia.data.CourseImagePrefetch
import app.rork.sophia.data.CourseSessionTracker
import app.rork.sophia.data.GlossaryStore
import app.rork.sophia.data.InAppReviewHelper
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Course
import app.rork.sophia.domain.FreemiumGate
import app.rork.sophia.ui.components.CalmProgressBar
import app.rork.sophia.ui.components.lockedContentBlur
import app.rork.sophia.ui.components.CircleIconButton
import app.rork.sophia.ui.components.SophiaPrimaryButton
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

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
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    var showQuiz by remember { mutableStateOf(false) }
    var showCompleted by remember(course.id) { mutableStateOf(false) }
    var showCoachmark by remember { mutableStateOf(false) }
    var coachmarkTerm by remember { mutableStateOf<String?>(null) }
    val wasCompletedBefore = remember(course.id) {
        progressManager.courseProgress(course.id)?.isCompleted == true
    }
    var pages by remember(course.id, language) { mutableStateOf<List<ReaderPage>>(emptyList()) }
    var pagesReady by remember(course.id, language) { mutableStateOf(false) }
    // A pager per course, so the page reached in the previous course cannot leak into
    // this one. Resetting it with scrollToPage instead would deadlock: that call waits
    // for the pager's first layout, which only happens once `pagesReady` is true.
    val pagerState = key(course.id, language) {
        rememberPagerState(pageCount = { pages.size.coerceAtLeast(1) })
    }
    val scope = rememberCoroutineScope()
    val sessionTracker = remember(course.id) {
        CourseSessionTracker(
            courseId = course.id,
            subject = course.subjectEnum.storageKey,
            lessonCount = 1,
        )
    }

    LaunchedEffect(course.id, language) {
        val appContext = context.applicationContext
        val loaded = withContext(Dispatchers.IO) {
            GlossaryStore.preload(appContext, language)
            // Resolves inline image slugs; without this the first block would read
            // the map from assets during composition.
            CourseCoverUrls.ensureBlockMap(appContext)
            buildPages(appContext, course, language).also { pages ->
                // Enqueue while the spinner is still up, so the opening pages are
                // already decoded by the time they are scrolled into view.
                CourseImagePrefetch.warmAssets(appContext, pages.leadingImageAssets(PREFETCH_IMAGES))
            }
        }
        pages = loaded
        sessionTracker.lessonCount = loaded.size.coerceAtLeast(1)
        pagesReady = true
        progressManager.recordFirstCourseOpenedIfNeeded(course.id)
    }

    DisposableEffect(course.id) {
        onDispose {
            app.analytics.trackCourseSessionEnded(sessionTracker.endProps())
        }
    }

    if (showQuiz) {
        LaunchedEffect(Unit) { sessionTracker.markQuiz() }
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
            onClose = onDismiss,
            onQuiz = {
                showCompleted = false
                showQuiz = true
            },
        )
        return
    }

    LaunchedEffect(pagerState.currentPage, pagesReady) {
        if (!pagesReady) return@LaunchedEffect
        val pageIndex = pagerState.currentPage
        sessionTracker.recordLessonReached(pageIndex)
        progressManager.updateLessonIndex(course.id, pageIndex)
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
            }
            CalmProgressBar(
                fraction = if (pages.isEmpty()) 0f else (pagerState.currentPage + 1).toFloat() / pages.size,
                modifier = Modifier.padding(horizontal = DS.Space.l),
            )

            if (!pagesReady) {
                Box(
                    modifier = Modifier.weight(1f).fillMaxWidth(),
                    contentAlignment = Alignment.Center,
                ) {
                    CircularProgressIndicator(color = DS.accent)
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
                    Box(modifier = Modifier.fillMaxSize()) {
                        Column(
                            modifier = Modifier
                                .fillMaxSize()
                                .verticalScroll(rememberScrollState(), enabled = !locked)
                                .padding(DS.Space.l),
                            verticalArrangement = Arrangement.spacedBy(DS.Space.m),
                        ) {
                            // The title stays sharp; only the paid body is blurred.
                            Text(text = page.title, style = SophiaTypography.titleLarge)
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
                            }
                        }
                        if (locked) {
                            CourseLessonLockOverlay {
                                app.analytics.trackLockedContentTapped(
                                    gateType = "debloquer_cours",
                                    courseId = course.id,
                                    subject = course.subjectEnum.storageKey,
                                )
                                onRequestPaywall("debloquer_cours")
                            }
                        }
                    }
                }
            }

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(DS.Space.l),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                val isLast = pagerState.currentPage >= pages.lastIndex
                val courseLocked = !isPremium && !isDailyFreeCourse
                SophiaPrimaryButton(
                    text = when {
                        courseLocked || !isLast -> StringStore.text(context, "course.continue", language)
                            .takeIf { it != "course.continue" } ?: "Continuer"
                        course.hasQuiz -> StringStore.text(context, "course.quiz", language)
                            .takeIf { it != "course.quiz" } ?: "Quiz"
                        else -> StringStore.text(context, "course.finish", language)
                            .takeIf { it != "course.finish" } ?: "Terminer"
                    },
                    onClick = {
                        if (courseLocked) {
                            if (!isLast) {
                                sessionTracker.recordContinueTap()
                                scope.launch { pagerState.animateScrollToPage(pagerState.currentPage + 1) }
                            }
                            return@SophiaPrimaryButton
                        }
                        if (isLast) {
                            if (FreemiumGate.canCompleteCourse(isPremium, isDailyFreeCourse)) {
                                if (!wasCompletedBefore) {
                                    progressManager.markCourseCompleted(course.id)
                                    sessionTracker.markCompleted()
                                    app.analytics.trackCourseCompleted(
                                        courseId = course.id,
                                        subject = course.subjectEnum.storageKey,
                                        lessonCount = pages.size,
                                        hasQuiz = course.hasQuiz,
                                    )
                                    onCourseCompleted()
                                }
                                showCompleted = true
                            }
                        } else {
                            sessionTracker.recordContinueTap()
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

/** Matches the +50 global XP granted by `ProgressManager.markCourseCompleted`. */
private const val COURSE_COMPLETION_XP = 50

private data class ReaderPage(val title: String, val blocks: List<ReaderBlock>)

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
