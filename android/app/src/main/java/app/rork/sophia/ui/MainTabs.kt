package app.rork.sophia.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoStories
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.RestartAlt
import androidx.compose.material.icons.filled.ViewModule
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.DeviceCapabilities
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Course
import app.rork.sophia.domain.PostCompletionRewardStep
import app.rork.sophia.ui.collections.CollectionsScreen
import app.rork.sophia.ui.components.PostCompletionRewardFlow
import app.rork.sophia.ui.components.TrialEndingMiniBanner
import app.rork.sophia.ui.course.CourseScreen
import app.rork.sophia.ui.home.DiscountGiftOverlay
import app.rork.sophia.ui.home.DiscountSideTab
import app.rork.sophia.ui.home.HomeTikTokScreen
import app.rork.sophia.ui.library.LibraryScreen
import app.rork.sophia.ui.paywall.PaywallContext
import app.rork.sophia.ui.paywall.PaywallScreen
import app.rork.sophia.ui.legal.LegalDocKind
import app.rork.sophia.ui.legal.LegalDocumentScreen
import app.rork.sophia.ui.profile.AmbassadorScreen
import app.rork.sophia.ui.profile.FeedbackScreen
import app.rork.sophia.ui.profile.ProfileScreen
import app.rork.sophia.ui.social.FriendsScreen
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.training.TrainingScreen
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

private enum class OverlayScreen { Friends, Feedback, Ambassador, Terms, Privacy }

@Composable
fun MainTabs(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    deepLinkCourseId: String?,
    onDeepLinkConsumed: () -> Unit,
    onResetOnboarding: () -> Unit,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val scope = rememberCoroutineScope()
    val lowRam = remember { DeviceCapabilities.isLowRam(context) }
    val isPremium by storeViewModel.isPremium.collectAsState()
    val trialExpiresInOneDay by storeViewModel.trialExpiresInOneDay.collectAsState()
    val progress by app.progressManager.progress.collectAsState()
    val discount by app.discountManager.state.collectAsState()
    var selectedTab by remember { mutableIntStateOf(0) }
    var selectedCourse by remember { mutableStateOf<Course?>(null) }
    var autoSwipeCourseId by remember { mutableStateOf<String?>(null) }
    var paywall by remember { mutableStateOf<PaywallContext?>(null) }
    var overlay by remember { mutableStateOf<OverlayScreen?>(null) }
    var rewardSteps by remember { mutableStateOf<List<PostCompletionRewardStep>?>(null) }
    var pendingCompletionCourseId by remember { mutableStateOf<String?>(null) }
    var levelBeforeCompletion by remember { mutableIntStateOf(1) }
    var paywallPresentedAtMs by remember { mutableStateOf<Long?>(null) }
    var showTrialEndingBanner by remember { mutableStateOf(false) }

    LaunchedEffect(language, isPremium, progress.subjectXP) {
        if (lowRam) delay(800)
        app.analytics.updateContext(
            language = language.code,
            isPremium = isPremium,
            onboardingCompleted = app.onboardingStore.isCompleted,
            unlockedSubjects = progress.subjectXP.keys,
        )
    }

    // In-app only: tiny banner the calendar day before trial end, once per day, auto-hides in 1s.
    LaunchedEffect(trialExpiresInOneDay) {
        if (!trialExpiresInOneDay) return@LaunchedEffect
        val prefs = context.getSharedPreferences("sophia_prefs", android.content.Context.MODE_PRIVATE)
        val day = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        if (prefs.getString("sophia_trial_ending_banner_day", null) == day) return@LaunchedEffect
        prefs.edit().putString("sophia_trial_ending_banner_day", day).apply()
        showTrialEndingBanner = true
        delay(1000)
        showTrialEndingBanner = false
    }

    LaunchedEffect(deepLinkCourseId, language) {
        val id = deepLinkCourseId ?: return@LaunchedEffect
        ContentCatalog.courseAsync(context.applicationContext, language, id)?.let {
            selectedCourse = it
            app.analytics.trackDeepLinkOpened(id)
        }
        onDeepLinkConsumed()
    }

    fun openCourse(course: Course) {
        if (!isPremium) {
            app.progressManager.incrementFreeCoursesOpened()
            app.progressManager.claimDailyFreeCourseIfNeeded(course.id)
        }
        app.analytics.trackCourseOpened(
            courseId = course.id,
            subject = course.subjectEnum.storageKey,
            source = "home_tiktok",
            isFreeUser = !isPremium,
        )
        pendingCompletionCourseId = null
        levelBeforeCompletion = ProgressManager.globalLevelProgress(app.progressManager.progress.value.globalXP).level
        selectedCourse = course
    }

    fun openCourseById(courseId: String) {
        val cached = ContentCatalog.cachedCourse(language, courseId)
        if (cached != null) {
            openCourse(cached)
            return
        }
        scope.launch {
            ContentCatalog.courseAsync(context.applicationContext, language, courseId)?.let {
                openCourse(it)
            }
        }
    }

    fun buildRewardSteps(courseId: String): List<PostCompletionRewardStep> {
        val p = app.progressManager.progress.value
        val steps = mutableListOf<PostCompletionRewardStep>()
        if (app.progressManager.shouldShowStreakCelebration()) {
            steps += PostCompletionRewardStep.Streak(p.streak)
        }
        p.pendingGlobalRankUp?.let { pending ->
            steps += PostCompletionRewardStep.RankUp(pending.newRankRawValue, pending.newLevel)
        }
        val collections = ContentCatalog.collections(context, language)
        val events = app.progressManager.collectionProgressEvents(courseId, collections)
        events.forEach { event ->
            if (event.isComplete) {
                app.progressManager.awardCollectionCompletionXpIfNeeded(event.collection)
            }
            app.analytics.trackCollectionProgressed(
                collectionId = event.collection.id,
                completed = event.newCompletedCount,
                total = event.totalCount,
                isComplete = event.isComplete,
            )
            steps += PostCompletionRewardStep.Collection(event)
        }
        val levelAfter = ProgressManager.globalLevelProgress(app.progressManager.progress.value.globalXP).level
        if (levelAfter > levelBeforeCompletion && p.pendingGlobalRankUp == null) {
            steps += PostCompletionRewardStep.LevelUp(levelAfter)
        }
        return steps
    }

    fun presentRewardsIfNeeded(courseId: String?) {
        if (courseId == null) return
        scope.launch {
            val steps = withContext(Dispatchers.IO) { buildRewardSteps(courseId) }
            if (steps.isNotEmpty()) rewardSteps = steps
        }
    }

    when {
        rewardSteps != null -> {
            PostCompletionRewardFlow(
                steps = rewardSteps!!,
                language = language,
                onFinished = {
                    app.progressManager.markStreakShownToday()
                    app.progressManager.clearPendingRankUp()
                    rewardSteps = null
                },
            )
            return
        }
        paywall != null -> {
            val ctx = paywall!!
            LaunchedEffect(ctx) {
                paywallPresentedAtMs = System.currentTimeMillis()
                app.analytics.trackPaywallViewed(ctx.analyticsContext)
            }
            PaywallScreen(
                context = ctx,
                language = language,
                storeViewModel = storeViewModel,
                onDismiss = {
                    val duration = paywallPresentedAtMs?.let {
                        ((System.currentTimeMillis() - it) / 1000).toInt().coerceAtLeast(0)
                    } ?: 0
                    app.analytics.trackPaywallDismissed(ctx.analyticsContext, duration)
                    paywallPresentedAtMs = null
                    paywall = null
                },
                onPurchased = {
                    // Meta filled via onPurchaseMeta below; keep dismiss path clean.
                    if (ctx == PaywallContext.OFFRE_DISCOUNT) {
                        app.discountManager.markExpired()
                    }
                    paywallPresentedAtMs = null
                    paywall = null
                },
                onPurchaseMeta = { offeringId, packageId ->
                    app.analytics.trackPurchaseCompleted(
                        context = ctx.analyticsContext,
                        offeringId = offeringId ?: ctx.offeringId,
                        packageId = packageId,
                    )
                },
            )
            return
        }
        overlay == OverlayScreen.Friends -> {
            FriendsScreen(language = language, onBack = { overlay = null })
            return
        }
        overlay == OverlayScreen.Feedback -> {
            FeedbackScreen(
                language = language,
                isPremium = isPremium,
                onBack = { overlay = null },
            )
            return
        }
        overlay == OverlayScreen.Ambassador -> {
            AmbassadorScreen(
                language = language,
                onBack = { overlay = null },
            )
            return
        }
        overlay == OverlayScreen.Terms -> {
            LegalDocumentScreen(
                kind = LegalDocKind.Terms,
                language = language,
                onBack = { overlay = null },
            )
            return
        }
        overlay == OverlayScreen.Privacy -> {
            LegalDocumentScreen(
                kind = LegalDocKind.Privacy,
                language = language,
                onBack = { overlay = null },
            )
            return
        }
        selectedCourse != null -> {
            CourseScreen(
                course = selectedCourse!!,
                language = language,
                isPremium = isPremium,
                isDailyFreeCourse = app.progressManager.isDailyFreeCourse(selectedCourse!!.id),
                progressManager = app.progressManager,
                onCourseCompleted = {
                    pendingCompletionCourseId = selectedCourse?.id
                },
                onDismiss = {
                    val id = selectedCourse!!.id
                    val completedId = pendingCompletionCourseId
                    pendingCompletionCourseId = null
                    selectedCourse = null
                    autoSwipeCourseId = id
                    presentRewardsIfNeeded(completedId)
                },
                onRequestPaywall = { key ->
                    if (key == "debloquer_cours" || key == "quizz") {
                        app.analytics.trackFreemiumGateHit(key, courseId = selectedCourse?.id)
                    }
                    paywall = when (key) {
                        "quizz" -> PaywallContext.QUIZZ
                        "offre_discount" -> PaywallContext.OFFRE_DISCOUNT
                        "fin_onboarding" -> PaywallContext.FIN_ONBOARDING
                        else -> PaywallContext.DEBLOQUER_COURS
                    }
                },
            )
            return
        }
    }

    val tabs = listOf(
        Triple("tab.home", Icons.Filled.Home, 0),
        Triple("tab.library", Icons.Filled.AutoStories, 1),
        Triple("tab.collections", Icons.Filled.ViewModule, 2),
        Triple("tab.training", Icons.Filled.RestartAlt, 3),
        Triple("tab.profile", Icons.Filled.Person, 4),
    )

    Box(modifier = Modifier.fillMaxSize()) {
        Scaffold(
            containerColor = DS.canvas,
            bottomBar = {
                NavigationBar(containerColor = DS.canvas, contentColor = DS.accent) {
                    tabs.forEach { (key, icon, index) ->
                        NavigationBarItem(
                            selected = selectedTab == index,
                            onClick = { selectedTab = index },
                            icon = { Icon(icon, contentDescription = null) },
                            label = {
                                Text(
                                    text = StringStore.text(context, key, language),
                                    fontFamily = PlusJakartaSans,
                                    fontSize = 11.sp,
                                    fontWeight = if (selectedTab == index) FontWeight.SemiBold else FontWeight.Normal,
                                )
                            },
                            colors = NavigationBarItemDefaults.colors(
                                selectedIconColor = DS.accent,
                                selectedTextColor = DS.accent,
                                unselectedIconColor = DS.inkTertiary,
                                unselectedTextColor = DS.inkTertiary,
                                indicatorColor = DS.accentTint,
                            ),
                        )
                    }
                }
            },
        ) { padding ->
            when (selectedTab) {
                0 -> HomeTikTokScreen(
                    modifier = Modifier.padding(padding),
                    language = language,
                    favoriteIds = progress.favoriteCourseIds.toSet(),
                    autoSwipeCourseId = autoSwipeCourseId,
                    onAutoSwipeConsumed = { autoSwipeCourseId = null },
                    onToggleFavorite = { app.progressManager.toggleFavorite(it) },
                    onStartCourse = { openCourseById(it) },
                    onUserSwipe = {
                        if (!isPremium) app.discountManager.registerSwipe()
                    },
                )
                1 -> LibraryScreen(
                    modifier = Modifier.padding(padding),
                    language = language,
                    progress = progress,
                    onOpenCourse = { openCourseById(it) },
                )
                2 -> CollectionsScreen(
                    modifier = Modifier.padding(padding),
                    language = language,
                    progress = progress,
                    onOpenCourse = { openCourseById(it) },
                )
                3 -> TrainingScreen(
                    modifier = Modifier.padding(padding),
                    language = language,
                    isPremium = isPremium,
                    progress = progress,
                    progressManager = app.progressManager,
                    storeViewModel = storeViewModel,
                    onPremiumUnlocked = { storeViewModel.refresh() },
                )
                4 -> ProfileScreen(
                    modifier = Modifier.padding(padding),
                    language = language,
                    progress = progress,
                    isPremium = isPremium,
                    onLanguageChange = { app.languageManager.setLanguage(it) },
                    onResetOnboarding = onResetOnboarding,
                    onOpenCourse = { openCourseById(it) },
                    onShowPaywall = { paywall = PaywallContext.DEBLOQUER_COURS },
                    onOpenFriends = { overlay = OverlayScreen.Friends },
                    onOpenFeedback = { overlay = OverlayScreen.Feedback },
                    onOpenAmbassador = { overlay = OverlayScreen.Ambassador },
                    onOpenTerms = { overlay = OverlayScreen.Terms },
                    onOpenPrivacy = { overlay = OverlayScreen.Privacy },
                    onRestorePurchases = { storeViewModel.restore() },
                )
            }
        }

        if (!isPremium && !lowRam && selectedTab == 0 && selectedCourse == null && paywall == null) {
            if (discount.isGiftPending) {
                DiscountGiftOverlay(
                    language = language,
                    onOpened = {
                        app.discountManager.consumeGift()
                        app.discountManager.triggerIfNeeded()
                        app.discountManager.markShownToday()
                        app.analytics.trackDiscountOfferViewed("gift")
                        paywall = PaywallContext.OFFRE_DISCOUNT
                    },
                )
            } else if (discount.isActive) {
                DiscountSideTab(
                    state = discount,
                    onClick = {
                        app.analytics.trackDiscountOfferViewed("side_tab")
                        app.discountManager.markShownToday()
                        paywall = PaywallContext.OFFRE_DISCOUNT
                    },
                )
            }
        }

        AnimatedVisibility(
            visible = showTrialEndingBanner,
            modifier = Modifier
                .align(Alignment.TopCenter)
                .statusBarsPadding(),
            enter = fadeIn() + slideInVertically { -it },
            exit = fadeOut() + slideOutVertically { -it },
        ) {
            TrialEndingMiniBanner(language = language)
        }
    }
}
