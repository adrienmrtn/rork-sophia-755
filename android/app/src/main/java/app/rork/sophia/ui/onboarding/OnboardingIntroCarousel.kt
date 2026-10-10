package app.rork.sophia.ui.onboarding

import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Public
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import app.rork.sophia.data.AuthorStore
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.theme.uppercaseInApp
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * The presentation pages right after the language, as in iOS 1.1.8: pages joined by dots at
 * the bottom and one « Continue » button, browsed with the button or a swipe. The last one
 * leads to « Join the 500,000 users » ([SocialProofStep]).
 *
 * Lessons (four cards) · Real researchers (professors and universities) · Quizzes (course
 * pictures) · Personalized route (a preview of the Parcours tab).
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
internal fun IntroCarouselStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val pageCount = 4
    var savedPage by rememberSaveable { mutableIntStateOf(0) }
    val pagerState = rememberPagerState(initialPage = savedPage) { pageCount }
    val scope = rememberCoroutineScope()
    LaunchedEffect(pagerState.currentPage) { savedPage = pagerState.currentPage }
    // Back turns the pages back first; on the first page it leaves the carousel as usual.
    BackHandler(enabled = pagerState.currentPage > 0) {
        scope.launch { pagerState.animateScrollToPage(pagerState.currentPage - 1) }
    }

    Column(modifier = Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
        HorizontalPager(
            state = pagerState,
            modifier = Modifier.weight(1f).fillMaxWidth(),
        ) { page ->
            val active = pagerState.currentPage == page
            when (page) {
                0 -> IntroLessonsPage(language, active)
                1 -> IntroResearchersPage(language, active)
                2 -> IntroQuizzesPage(language, active)
                else -> IntroRoutePage(language, active)
            }
        }
        PagerDots(
            count = pageCount,
            current = pagerState.currentPage,
            modifier = Modifier.padding(vertical = 18.dp),
        )
        OnboardingCta(
            text = StringStore.text(context, "common.continue", language),
            onClick = {
                // « Continue » turns the pages, then leaves the carousel after the last one.
                if (pagerState.currentPage < pageCount - 1) {
                    scope.launch {
                        pagerState.animateScrollToPage(
                            pagerState.currentPage + 1,
                            animationSpec = spring(dampingRatio = 0.9f, stiffness = Spring.StiffnessMediumLow),
                        )
                    }
                } else {
                    onContinue()
                }
            },
        )
    }
}

/** Runs [action] once, when the page becomes the current one (the pager composes neighbours early). */
@Composable
private fun OnPageActivated(active: Boolean, action: suspend () -> Unit) {
    var fired by remember { mutableStateOf(false) }
    LaunchedEffect(active) {
        if (active && !fired) {
            fired = true
            action()
        }
    }
}

/**
 * Shared frame of the presentation pages: the title at the top, the visual centred in what
 * is left, the subtitle right above the dots and the button.
 */
@Composable
private fun IntroPageFrame(
    title: String,
    subtitle: String? = null,
    visual: @Composable (width: Dp, height: Dp) -> Unit,
) {
    BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
        val compact = maxHeight < 600.dp
        val top = if (compact) 40.dp else 64.dp
        val subtitleBlock = if (subtitle != null) 70.dp else 0.dp
        val visualHeight = (maxHeight - top - 132.dp - subtitleBlock - 24.dp).coerceIn(170.dp, 300.dp)
        val visualWidth = maxWidth
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.height(top))
            // Up to four lines, shrinking to 75 % before giving up, like iOS's
            // `minimumScaleFactor(0.75)`: the « personalized route » title runs to five
            // lines in French at full size and lost its end.
            val titleStyle = OV2.title
            var titleScale by remember(title) { mutableFloatStateOf(1f) }
            var titleFits by remember(title) { mutableStateOf(false) }
            Text(
                text = highlighted(title),
                style = titleStyle.copy(
                    fontSize = titleStyle.fontSize * titleScale,
                    lineHeight = titleStyle.lineHeight * titleScale,
                ),
                textAlign = TextAlign.Center,
                maxLines = 4,
                onTextLayout = { layout ->
                    if (layout.hasVisualOverflow && titleScale > 0.75f) {
                        titleScale = (titleScale - 0.05f).coerceAtLeast(0.75f)
                    } else {
                        titleFits = true
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 28.dp)
                    .drawWithContent { if (titleFits) drawContent() },
            )
            Spacer(Modifier.weight(1f))
            Box(
                modifier = Modifier.fillMaxWidth().height(visualHeight),
                contentAlignment = Alignment.Center,
            ) {
                visual(visualWidth, visualHeight)
            }
            Spacer(Modifier.weight(1f))
            if (subtitle != null) {
                Text(
                    text = subtitle,
                    style = OV2.body,
                    textAlign = TextAlign.Center,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 32.dp)
                        .padding(bottom = 6.dp),
                )
            }
        }
    }
}

// MARK: - 1. Lessons

/**
 * The most-read courses of the app, also picked for a catchy title and varied subjects (same
 * list as iOS). A course withheld from a language is replaced by another one.
 */
private val FEATURED_COURSE_IDS = listOf(
    "course_42_pourquoi_reve_t_on",
    "course_67_qu_est_ce_qu_un_trou_noir",
    "course_201_la_naissance_du_conflit_israelo_palestin",
    "course_150_la_nuit_etoilee_van_gogh",
)

/** « Get smarter with exciting 10-minute lessons »: four course cards land one after the other. */
@Composable
private fun IntroLessonsPage(language: AppLanguage, active: Boolean) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    var courses by remember(language) { mutableStateOf<List<CourseSummary>>(emptyList()) }
    var revealed by remember { mutableIntStateOf(0) }
    LaunchedEffect(language) {
        val all = ContentCatalog.summariesAsync(context.applicationContext, language)
        val byId = all.associateBy { it.id }
        val picked = FEATURED_COURSE_IDS.mapNotNull { byId[it] }
        val fill = all.filter { it.id !in FEATURED_COURSE_IDS }.shuffled().take(FEATURED_COURSE_IDS.size - picked.size)
        courses = picked + fill
    }
    OnPageActivated(active) {
        delay(300)
        repeat(FEATURED_COURSE_IDS.size) { i ->
            revealed = i + 1
            haptics.selection()
            delay(220)
        }
    }

    IntroPageFrame(title = StringStore.text(context, "onboardingV2.intro.lessons.title", language)) { _, height ->
        val spacing = 10.dp
        val count = courses.size.coerceAtLeast(1)
        val cardHeight = ((height - spacing * (count - 1)) / count).coerceIn(54.dp, 74.dp)
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 28.dp),
            verticalArrangement = Arrangement.spacedBy(spacing, Alignment.CenterVertically),
        ) {
            courses.forEachIndexed { i, course ->
                RevealedItem(shown = i < revealed, fromY = 30f, fromScale = 0.94f) {
                    IntroCourseCard(course = course, language = language, height = cardHeight)
                }
            }
        }
    }
}

/** Fade, lift and scale in once [shown] turns true. */
@Composable
private fun RevealedItem(
    shown: Boolean,
    fromY: Float,
    fromScale: Float,
    modifier: Modifier = Modifier,
    fromRotation: Float = 0f,
    dampingRatio: Float = 0.78f,
    content: @Composable () -> Unit,
) {
    val progress by animateFloatAsState(
        targetValue = if (shown) 1f else 0f,
        animationSpec = spring(dampingRatio = dampingRatio, stiffness = Spring.StiffnessMediumLow),
        label = "introReveal",
    )
    Box(
        modifier = modifier.graphicsLayer {
            alpha = progress.coerceIn(0f, 1f)
            translationY = (1f - progress) * fromY * density
            val s = fromScale + (1f - fromScale) * progress
            scaleX = s
            scaleY = s
            rotationZ = (1f - progress) * fromRotation
        },
    ) {
        content()
    }
}

/** Thumbnail on the left, subject and title, the duration on the right. */
@Composable
private fun IntroCourseCard(course: CourseSummary, language: AppLanguage, height: Dp) {
    val context = LocalContext.current
    val shape = RoundedCornerShape(18.dp)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(height)
            .shadow(10.dp, shape, ambientColor = Color.Black.copy(alpha = 0.07f), spotColor = Color.Black.copy(alpha = 0.07f))
            .clip(shape)
            .background(OV2.surface)
            .border(1.dp, OV2.hairline, shape)
            .padding(start = 7.dp, top = 6.dp, bottom = 6.dp, end = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        CourseImage(
            courseId = course.id,
            modifier = Modifier
                .size(height - 12.dp)
                .clip(RoundedCornerShape(12.dp)),
            maxEdgePx = 240,
            letterSize = 18.sp,
        )
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                text = StringStore.text(context, "subject.${course.subjectEnum.storageKey}.short", language)
                    .uppercaseInApp(),
                style = OV2.caption.copy(
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 0.8.sp,
                    lineHeight = 13.sp,
                    color = lerp(course.subjectEnum.color, Color.Black, 0.3f),
                ),
                maxLines = 1,
            )
            Text(
                text = course.title,
                style = OV2.subheadline.copy(color = OV2.ink, fontWeight = FontWeight.Bold, fontSize = 14.sp, lineHeight = 17.sp),
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
        Row(
            modifier = Modifier
                .clip(CircleShape)
                .background(app.rork.sophia.ui.theme.DS.accentTint)
                .padding(horizontal = 8.dp, vertical = 5.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            Icon(Icons.Outlined.Schedule, contentDescription = null, tint = OV2.accentSoft, modifier = Modifier.size(11.dp))
            Text(
                text = StringStore.text(context, "onboardingV2.screenTime.minutes", language, 10),
                style = OV2.caption.copy(fontSize = 11.sp, fontWeight = FontWeight.Bold, color = OV2.accentSoft),
                maxLines = 1,
            )
        }
    }
}

// MARK: - 2. Real researchers

/** « Written by real researchers »: the professors' faces in circles, then the universities' logos scrolling by. */
@Composable
private fun IntroResearchersPage(language: AppLanguage, active: Boolean) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    val portraits = remember { AuthorStore.all(context).mapNotNull { it.photoModel } }
    val logos = remember { onboardingAssets(context, "university_") }
    var revealedPortraits by remember { mutableIntStateOf(0) }
    var marqueeIn by remember { mutableStateOf(false) }
    OnPageActivated(active) {
        delay(250)
        repeat(maxOf(portraits.size, 8)) { i ->
            revealedPortraits = i + 1
            if (i < portraits.size) haptics.selection()
            delay(110)
        }
        delay(100)
        marqueeIn = true
    }
    val marqueeProgress by animateFloatAsState(
        targetValue = if (marqueeIn) 1f else 0f,
        animationSpec = spring(dampingRatio = 0.85f, stiffness = Spring.StiffnessLow),
        label = "marqueeIn",
    )

    IntroPageFrame(
        title = StringStore.text(context, "onboardingV2.intro.researchers.title", language),
        subtitle = StringStore.text(context, "onboardingV2.intro.researchers.subtitle", language),
    ) { width, height ->
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(if (height < 220.dp) 22.dp else 34.dp, Alignment.CenterVertically),
        ) {
            val count = portraits.size.coerceAtLeast(1)
            val overlap = 12.dp
            val size = ((width - 56.dp + overlap * (count - 1)) / count).coerceAtMost(60.dp)
            Row(horizontalArrangement = Arrangement.spacedBy(-overlap)) {
                portraits.forEachIndexed { i, url ->
                    RevealedItem(
                        shown = i < revealedPortraits,
                        fromY = 0f,
                        fromScale = 0.3f,
                        dampingRatio = 0.65f,
                        modifier = Modifier.zIndex((portraits.size - i).toFloat()),
                    ) {
                        RoundPortrait(url = url, size = size, ring = 2.5.dp)
                    }
                }
            }
            LogoMarquee(
                logos = logos,
                logoHeight = (height * 0.3f).coerceAtMost(72.dp),
                paused = !active || !marqueeIn,
                modifier = Modifier.graphicsLayer {
                    alpha = marqueeProgress
                    translationY = (1f - marqueeProgress) * 14f * density
                },
            )
        }
    }
}

/**
 * The universities' logos scrolling by without end. The band starts with the first logo
 * (Oxford) in the middle of the screen and drifts slowly to the left; it stays still while
 * the page is not showing it, and starts again from Oxford when it is revealed.
 */
@Composable
private fun LogoMarquee(
    logos: List<String>,
    logoHeight: Dp,
    paused: Boolean,
    modifier: Modifier = Modifier,
) {
    if (logos.isEmpty()) return
    val density = LocalDensity.current
    val slotWidth = logoHeight * 1.6f
    val gap = 28.dp
    val slotWidthPx = with(density) { slotWidth.toPx() }
    val periodPx = with(density) { (slotWidth + gap).toPx() } * logos.size
    // Points per second; the first iOS version moved at 38.
    val speedPx = with(density) { 11.5.dp.toPx() }
    var travelled by remember { mutableFloatStateOf(0f) }
    LaunchedEffect(paused, periodPx) {
        if (paused) return@LaunchedEffect
        travelled = 0f
        var last = withFrameNanos { it }
        while (true) {
            withFrameNanos { now ->
                travelled = (travelled + (now - last) / 1_000_000_000f * speedPx) % periodPx
                last = now
            }
        }
    }
    // Logos, not text: the band runs the same way in every language.
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
    BoxWithConstraints(
        modifier = modifier
            .fillMaxWidth()
            .height(logoHeight + 12.dp)
            .clipToBounds()
            .graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
            .drawWithContent {
                drawContent()
                drawRect(
                    brush = Brush.horizontalGradient(
                        0f to Color.Transparent,
                        0.12f to Color.Black,
                        0.88f to Color.Black,
                        1f to Color.Transparent,
                    ),
                    blendMode = BlendMode.DstIn,
                )
            },
        contentAlignment = Alignment.CenterStart,
    ) {
        val startInset = (constraints.maxWidth - slotWidthPx) / 2f
        Row(
            modifier = Modifier
                .wrapContentWidth(align = Alignment.Start, unbounded = true)
                .graphicsLayer { translationX = startInset - periodPx - travelled },
            horizontalArrangement = Arrangement.spacedBy(gap),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            repeat(3) {
                logos.forEach { url ->
                    AssetPicture(
                        url = url,
                        contentScale = ContentScale.Fit,
                        modifier = Modifier.width(slotWidth).height(logoHeight),
                    )
                }
            }
        }
    }
    }
}

// MARK: - 3. Quizzes

/** Six courses picked for their picture: Apollo 11, Tutankhamun, the Mona Lisa, the pyramids, the Crab Nebula, the Eiffel Tower. */
private val QUIZ_IMAGE_COURSE_IDS = listOf(
    "course_290_comment_les_etats_unis_ont_ils_gagne_la",
    "course_247_pourquoi_les_momies_font_elles_peur",
    "course_149_la_joconde",
    "course_264_qui_a_vraiment_construit_les_pyramides",
    "course_281_comment_meurt_une_etoile",
    "course_241_pourquoi_voulait_on_demolir_la_tour_eiffel",
)

/** Squares that get a tick, in the order the ticks appear. */
private val CHECKED_SQUARES = listOf(1, 3, 4)

/** « Sophia tests you with fun quizzes »: course pictures in squares, one by one, then « right answer » ticks. */
@Composable
private fun IntroQuizzesPage(language: AppLanguage, active: Boolean) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    var revealed by remember { mutableIntStateOf(0) }
    var badges by remember { mutableIntStateOf(0) }
    OnPageActivated(active) {
        delay(250)
        repeat(QUIZ_IMAGE_COURSE_IDS.size) { i ->
            revealed = i + 1
            haptics.selection()
            delay(140)
        }
        delay(250)
        repeat(CHECKED_SQUARES.size) { i ->
            badges = i + 1
            haptics.commit()
            delay(300)
        }
    }

    IntroPageFrame(
        title = StringStore.text(context, "onboardingV2.intro.quizzes.title", language),
        subtitle = StringStore.text(context, "onboardingV2.intro.quizzes.subtitle", language),
    ) { width, height ->
        val columns = 3
        val rows = QUIZ_IMAGE_COURSE_IDS.size / columns
        val spacing = 12.dp
        val side = minOf(
            (width - 56.dp - spacing * (columns - 1)) / columns,
            (height - spacing * (rows - 1)) / rows,
        )
        Column(verticalArrangement = Arrangement.spacedBy(spacing)) {
            repeat(rows) { row ->
                Row(horizontalArrangement = Arrangement.spacedBy(spacing)) {
                    repeat(columns) { column ->
                        val index = row * columns + column
                        val badgeRank = CHECKED_SQUARES.indexOf(index)
                        QuizSquare(
                            courseId = QUIZ_IMAGE_COURSE_IDS[index],
                            side = side,
                            shown = index < revealed,
                            tilt = if (index % 2 == 0) -8f else 8f,
                            hasBadge = badgeRank >= 0,
                            badgeShown = badgeRank in 0 until badges,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun QuizSquare(
    courseId: String,
    side: Dp,
    shown: Boolean,
    tilt: Float,
    hasBadge: Boolean,
    badgeShown: Boolean,
) {
    val shape = RoundedCornerShape(18.dp)
    val badgeScale by animateFloatAsState(
        targetValue = if (badgeShown) 1f else 0.2f,
        animationSpec = spring(dampingRatio = 0.55f, stiffness = Spring.StiffnessMedium),
        label = "quizBadge",
    )
    RevealedItem(shown = shown, fromY = 0f, fromScale = 0.6f, fromRotation = tilt, dampingRatio = 0.7f) {
        Box(modifier = Modifier.size(side)) {
            CourseImage(
                courseId = courseId,
                modifier = Modifier
                    .size(side)
                    .shadow(10.dp, shape, ambientColor = Color.Black.copy(alpha = 0.10f), spotColor = Color.Black.copy(alpha = 0.10f))
                    .clip(shape)
                    .border(1.dp, Color.White.copy(alpha = 0.8f), shape),
                maxEdgePx = 360,
                letterSize = 24.sp,
            )
            if (hasBadge) {
                CheckBadge(
                    size = 26.dp,
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .offset(x = 7.dp, y = (-7).dp)
                        .graphicsLayer {
                            scaleX = badgeScale
                            scaleY = badgeScale
                            alpha = if (badgeShown) 1f else 0f
                        },
                )
            }
        }
    }
}

// MARK: - 4. Personalized route

/** « Sophia builds you a personalized route »: the Parcours preview, fading and growing in. */
@Composable
private fun IntroRoutePage(language: AppLanguage, active: Boolean) {
    val context = LocalContext.current
    val shown = remember { Animatable(0f) }
    OnPageActivated(active) {
        delay(150)
        shown.animateTo(1f, spring(dampingRatio = 0.85f, stiffness = 80f))
    }
    IntroPageFrame(
        title = StringStore.text(context, "onboardingV2.intro.route.title", language),
        subtitle = StringStore.text(context, "onboardingV2.intro.route.subtitle", language),
    ) { width, height ->
        OnboardingPathPreview(
            language = language,
            width = width,
            height = height,
            modifier = Modifier.graphicsLayer {
                val scale = 0.94f + 0.06f * shown.value
                scaleX = scale
                scaleY = scale
                alpha = shown.value.coerceIn(0f, 1f)
            },
        )
    }
}

// MARK: - Social proof

/**
 * « Join the 500,000 happy users who learn with Sophia » at the top, students' photos, the
 * store rating between two laurels, « available in more than 140 countries » above the
 * button, and the « Let's go » CTA.
 */
@Composable
internal fun SocialProofStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    val photos = remember { studentPhotos(context).take(MAX_STUDENT_PHOTOS) }
    var revealedPhotos by remember { mutableIntStateOf(0) }
    var ratingIn by remember { mutableStateOf(false) }
    var textIn by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(300)
        repeat(photos.size) { i ->
            revealedPhotos = i + 1
            haptics.selection()
            delay(80)
        }
        delay(100)
        ratingIn = true
        haptics.commit()
        delay(250)
        textIn = true
    }
    val ratingProgress by animateFloatAsState(
        targetValue = if (ratingIn) 1f else 0f,
        animationSpec = spring(dampingRatio = 0.6f, stiffness = Spring.StiffnessMediumLow),
        label = "socialRating",
    )
    val textProgress by animateFloatAsState(
        targetValue = if (textIn) 1f else 0f,
        animationSpec = spring(dampingRatio = 0.85f, stiffness = Spring.StiffnessLow),
        label = "socialText",
    )

    // Photos, laurels, title and countries outgrow a small phone at a large font size: the
    // content scrolls, the CTA stays pinned. When it fits, the title sits at the top, the
    // countries right above the button, and the photos and rating in the middle.
    OnboardingPage(
        contentArrangement = Arrangement.SpaceBetween,
        footer = {
            OnboardingCta(StringStore.text(context, "onboardingV2.intro.social.cta", language), onContinue)
        },
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Spacer(Modifier.height(64.dp))
            Text(
                text = highlighted(StringStore.text(context, "onboardingV2.intro.social.title", language)),
                style = OV2.title,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 28.dp)
                    .ov2Reveal(50),
            )
        }
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(vertical = 20.dp),
        ) {
            if (photos.isNotEmpty()) {
                StudentCluster(photos = photos, revealed = revealedPhotos)
                Spacer(Modifier.height(26.dp))
            }
            LaurelBadge(
                modifier = Modifier.graphicsLayer {
                    val s = 0.7f + 0.3f * ratingProgress
                    scaleX = s
                    scaleY = s
                    alpha = ratingProgress.coerceIn(0f, 1f)
                },
            ) {
                RatingStack(
                    caption = StringStore.text(context, "onboardingV2.review.appStore", language),
                    language = language,
                )
            }
        }
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier
                .fillMaxWidth()
                .padding(start = 32.dp, end = 32.dp, top = 4.dp, bottom = 10.dp)
                .graphicsLayer {
                    alpha = textProgress.coerceIn(0f, 1f)
                    translationY = (1f - textProgress) * 14f * density
                },
        ) {
            Icon(Icons.Filled.Public, contentDescription = null, tint = OV2.accentSoft, modifier = Modifier.size(20.dp))
            Text(
                text = StringStore.text(context, "onboardingV2.intro.social.countries", language),
                style = OV2.body,
                textAlign = TextAlign.Center,
            )
        }
    }
}

private const val MAX_STUDENT_PHOTOS = 10

/**
 * Students' photos in same-size circles, in centred rows of at most five, the rows as full
 * as each other: 10 → 5 + 5, 7 → 4 + 3, 5 → 5.
 */
@Composable
private fun StudentCluster(photos: List<String>, revealed: Int) {
    val perRow = 5
    val rowCount = (photos.size + perRow - 1) / perRow
    if (rowCount == 0) return
    val base = photos.size / rowCount
    val extra = photos.size % rowCount
    var next = 0
    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        repeat(rowCount) { row ->
            val size = base + if (row < extra) 1 else 0
            val indices = next until next + size
            next += size
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                indices.forEach { i ->
                    RevealedItem(shown = i < revealed, fromY = 0f, fromScale = 0.2f, dampingRatio = 0.62f) {
                        RoundPortrait(url = photos[i], size = 58.dp)
                    }
                }
            }
        }
    }
}
