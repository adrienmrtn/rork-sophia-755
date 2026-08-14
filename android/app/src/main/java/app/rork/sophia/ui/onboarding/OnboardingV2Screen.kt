package app.rork.sophia.ui.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import app.rork.sophia.SophiaApplication
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.MetaAdsService
import app.rork.sophia.data.TrialReminderScheduler
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.ui.paywall.OnboardingPaywallFlow
import app.rork.sophia.ui.theme.DS
import kotlinx.coroutines.launch

private enum class OnboardingStep(val analyticsName: String) {
    Welcome("welcome"),
    Language("language"),
    Objectives("objective"),
    ObjectiveIntro("objective_intro"),
    Questions("questions"),
    PhoneTime("phone_time"),
    YearsGrid("years_grid"),
    Transform("transform"),
    Review("review"),
    Personalize("personalize"),
    Swipe("swipe_courses"),
    Loading("loading"),
    Profile("profile"),
    Login("login"),
    Trial("trial_steps"),
    Reminder("reminder"),
    Paywall("paywall_annual"),
}

@Composable
fun OnboardingV2Screen(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    onLanguageSelected: (AppLanguage) -> Unit,
    onComplete: () -> Unit,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val isPremium by storeViewModel.isPremium.collectAsState()
    var step by remember { mutableStateOf(OnboardingStep.Welcome) }
    var selectedObjectives by remember { mutableStateOf(setOf<String>()) }
    var phoneMinutes by remember { mutableIntStateOf(180) }
    var likedCourseIds by remember { mutableStateOf(listOf<String>()) }
    var sawPaywall by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    LaunchedEffect(Unit) { app.analytics.trackOnboardingStarted() }
    LaunchedEffect(step) {
        app.analytics.trackOnboardingStep(step.ordinal, step.analyticsName)
    }
    // Warm the home feed during paywall so arriving on TikTok home is instant.
    LaunchedEffect(step, language) {
        if (step != OnboardingStep.Paywall && step != OnboardingStep.Reminder) return@LaunchedEffect
        val appContext = context.applicationContext
        runCatching {
            ContentCatalog.summariesAsync(appContext, language)
        }
    }

    fun finish(isPremiumAtExit: Boolean) {
        likedCourseIds.forEach { id ->
            if (!app.progressManager.isFavorite(id)) {
                app.progressManager.toggleFavorite(id)
            }
        }
        app.analytics.trackOnboardingCompleted(sawPaywall = sawPaywall, isPremium = isPremiumAtExit)
        onComplete()
    }

    fun scheduleTrialReminderIfEligible() {
        // Only schedule when the served annual product actually has a free trial.
        // Reminder step runs even on no-trial paths; must not notify "trial ending".
        if (storeViewModel.annualHasFreeTrial()) {
            TrialReminderScheduler.scheduleTrialEndingReminder(context)
        }
    }

    val notificationPermission = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) {
        MetaAdsService.setTrackingEnabled(true)
        if (isPremium) finish(true)
        else {
            sawPaywall = true
            step = OnboardingStep.Paywall
        }
    }

    fun advanceFromReminder() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            notificationPermission.launch(Manifest.permission.POST_NOTIFICATIONS)
        } else {
            MetaAdsService.setTrackingEnabled(true)
            if (isPremium) finish(true)
            else {
                sawPaywall = true
                step = OnboardingStep.Paywall
            }
        }
    }

    val primaryObjective = selectedObjectives.firstOrNull() ?: "cultivate"
    var swipeCourses by remember(language) { mutableStateOf<List<CourseSummary>>(emptyList()) }
    var swipeReady by remember(language) { mutableStateOf(false) }
    LaunchedEffect(language) {
        swipeCourses = ContentCatalog.summariesAsync(context.applicationContext, language).shuffled().take(5)
        swipeReady = true
    }

    Box(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
        when (step) {
            OnboardingStep.Welcome -> WelcomeStep(language) { step = OnboardingStep.Language }
            OnboardingStep.Language -> LanguageStep(
                language = language,
                onSelect = onLanguageSelected,
                onContinue = { step = OnboardingStep.Objectives },
            )
            OnboardingStep.Objectives -> ObjectivesStep(
                language = language,
                selected = selectedObjectives,
                onToggle = { key ->
                    selectedObjectives = selectedObjectives.toMutableSet().also { set ->
                        if (!set.add(key)) set.remove(key)
                    }
                },
                onContinue = {
                    app.analytics.trackOnboardingInterestsSet(selectedObjectives)
                    step = OnboardingStep.ObjectiveIntro
                },
            )
            OnboardingStep.ObjectiveIntro -> TapContinueStep(
                titleKey = "onboardingV2.objectiveIntro.title",
                language = language,
                onContinue = { step = OnboardingStep.Questions },
            )
            OnboardingStep.Questions -> QuestionsStep(language) { step = OnboardingStep.PhoneTime }
            OnboardingStep.PhoneTime -> PhoneTimeStep(
                language = language,
                minutes = phoneMinutes,
                onMinutesChange = { phoneMinutes = it },
                onContinue = { step = OnboardingStep.YearsGrid },
            )
            OnboardingStep.YearsGrid -> YearsGridStep(
                language = language,
                phoneMinutes = phoneMinutes,
                onContinue = { step = OnboardingStep.Transform },
            )
            OnboardingStep.Transform -> TransformStep(language) { step = OnboardingStep.Review }
            OnboardingStep.Review -> ReviewStep(language) { step = OnboardingStep.Personalize }
            OnboardingStep.Personalize -> TapContinueStep(
                titleKey = "onboardingV2.personalize.text",
                language = language,
                hintKey = "onboardingV2.personalize.tapHint",
                onContinue = { step = OnboardingStep.Swipe },
            )
            OnboardingStep.Swipe -> SwipeCoursesStep(
                language = language,
                courses = swipeCourses,
                ready = swipeReady,
                onFinished = { liked ->
                    likedCourseIds = liked
                    step = OnboardingStep.Loading
                },
            )
            OnboardingStep.Loading -> LoadingProfileStep(language) { step = OnboardingStep.Profile }
            OnboardingStep.Profile -> ProfileRewardStep(
                language = language,
                objectiveKeys = selectedObjectives.toList().ifEmpty { listOf(primaryObjective) },
                likedCourseIds = likedCourseIds,
                onContinue = { step = OnboardingStep.Login },
            )
            OnboardingStep.Login -> LoginStep(
                language = language,
                onGoogle = {
                    scope.launch {
                        runCatching { app.authService.signInWithGoogle(context) }
                        // Skip trial explanation when the served annual product has no free trial.
                        step = if (storeViewModel.shouldShowTrialSteps()) {
                            OnboardingStep.Trial
                        } else {
                            OnboardingStep.Reminder
                        }
                    }
                },
                onSkip = {
                    step = if (storeViewModel.shouldShowTrialSteps()) {
                        OnboardingStep.Trial
                    } else {
                        OnboardingStep.Reminder
                    }
                },
            )
            OnboardingStep.Trial -> TrialStepsStep(language) { step = OnboardingStep.Reminder }
            OnboardingStep.Reminder -> ReminderStep(language, onContinue = ::advanceFromReminder)
            OnboardingStep.Paywall -> {
                LaunchedEffect(Unit) { sawPaywall = true }
                OnboardingPaywallFlow(
                    language = language,
                    storeViewModel = storeViewModel,
                    onDismiss = { finish(false) },
                    onPurchased = {
                        scheduleTrialReminderIfEligible()
                        finish(true)
                    },
                    onPurchaseMeta = { offeringId, packageId ->
                        app.analytics.trackPurchaseCompleted(
                            context = "fin_onboarding",
                            offeringId = offeringId,
                            packageId = packageId,
                        )
                    },
                    onComparisonShown = {
                        app.analytics.trackOnboardingStep(
                            stepIndex = step.ordinal,
                            stepName = "paywall_comparison",
                        )
                    },
                )
            }
        }
    }
}
