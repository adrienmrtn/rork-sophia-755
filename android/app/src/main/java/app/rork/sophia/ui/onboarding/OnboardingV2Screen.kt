package app.rork.sophia.ui.onboarding

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.DeviceCapabilities
import app.rork.sophia.data.GlossaryStore
import app.rork.sophia.data.InAppReviewHelper
import app.rork.sophia.data.TrialReminderScheduler
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.ui.paywall.OnboardingPaywallFlow
import app.rork.sophia.ui.theme.DS
import kotlinx.coroutines.delay
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

/** Steps that carry the progress dots, matching the iOS `dotScreens` set. */
private val DOT_STEPS = listOf(
    OnboardingStep.Objectives,
    OnboardingStep.ObjectiveIntro,
    OnboardingStep.Questions,
    OnboardingStep.PhoneTime,
    OnboardingStep.YearsGrid,
    OnboardingStep.Review,
    OnboardingStep.Swipe,
    OnboardingStep.Loading,
)

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
    // Blur and long infinite animations are dropped on Go phones and emulators.
    val richMotion = remember { !DeviceCapabilities.isConstrained(context) }
    var step by remember { mutableStateOf(OnboardingStep.Welcome) }
    var selectedObjectives by remember { mutableStateOf(setOf<String>()) }
    var phoneMinutes by remember { mutableIntStateOf(180) }
    var likedCourseIds by remember { mutableStateOf(listOf<String>()) }
    var sawPaywall by remember { mutableStateOf(false) }
    var lastAdvanceAt by remember { mutableLongStateOf(0L) }
    val scope = rememberCoroutineScope()

    // A racing timer (last swipe card, word animation) must not skip a whole screen.
    fun goTo(next: OnboardingStep) {
        val now = System.currentTimeMillis()
        if (now - lastAdvanceAt < 400L) return
        lastAdvanceAt = now
        step = next
    }

    LaunchedEffect(Unit) { app.analytics.trackOnboardingStarted() }
    LaunchedEffect(step) {
        app.analytics.trackOnboardingStep(step.ordinal, step.analyticsName)
    }
    // Warm the home feed + glossary during paywall so arriving on TikTok home is instant.
    LaunchedEffect(step, language) {
        if (step != OnboardingStep.Paywall && step != OnboardingStep.Reminder) return@LaunchedEffect
        val appContext = context.applicationContext
        runCatching {
            ContentCatalog.summariesAsync(appContext, language)
            GlossaryStore.preload(appContext, language)
        }
    }

    fun finish(isPremiumAtExit: Boolean) {
        runCatching {
            likedCourseIds.forEach { id ->
                if (!app.progressManager.isFavorite(id)) {
                    app.progressManager.toggleFavorite(id)
                }
            }
            app.analytics.trackOnboardingCompleted(sawPaywall = sawPaywall, isPremium = isPremiumAtExit)
        }
        onComplete()
    }

    fun scheduleTrialReminderIfEligible() {
        // Only schedule when the served annual product actually has a free trial.
        // Reminder step runs even on no-trial paths; must not notify "trial ending".
        if (storeViewModel.annualHasFreeTrial()) {
            TrialReminderScheduler.scheduleTrialEndingReminder(context)
        }
    }

    fun advanceFromReminder() {
        if (isPremium) finish(true)
        else {
            sawPaywall = true
            step = OnboardingStep.Paywall
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
        AnimatedContent(
            targetState = step,
            transitionSpec = {
                // Pages arrive from above and leave downwards, like the iOS `ov2` transition.
                (slideInVertically(spring(dampingRatio = 0.9f, stiffness = Spring.StiffnessMediumLow)) {
                    -it / 8
                } + fadeIn(tween(280))) togetherWith
                    (slideOutVertically(tween(240)) { it / 6 } + fadeOut(tween(200)))
            },
            label = "onboardingStep",
        ) { current ->
            when (current) {
                OnboardingStep.Welcome -> WelcomeStep(language) { goTo(OnboardingStep.Language) }
                OnboardingStep.Language -> LanguageStep(
                    language = language,
                    onSelect = onLanguageSelected,
                    onContinue = { goTo(OnboardingStep.Objectives) },
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
                        goTo(OnboardingStep.ObjectiveIntro)
                    },
                )
                OnboardingStep.ObjectiveIntro -> ObjectiveIntroStep(language) {
                    goTo(OnboardingStep.Questions)
                }
                OnboardingStep.Questions -> QuestionsStep(language, richMotion) {
                    goTo(OnboardingStep.PhoneTime)
                }
                OnboardingStep.PhoneTime -> PhoneTimeStep(
                    language = language,
                    minutes = phoneMinutes,
                    onMinutesChange = { phoneMinutes = it },
                    onContinue = { goTo(OnboardingStep.YearsGrid) },
                )
                OnboardingStep.YearsGrid -> YearsGridStep(
                    language = language,
                    phoneMinutes = phoneMinutes,
                    onContinue = { goTo(OnboardingStep.Transform) },
                )
                OnboardingStep.Transform -> TransformStep(language) { goTo(OnboardingStep.Review) }
                OnboardingStep.Review -> {
                    // Ask for the Play rating on the page that already talks about ratings,
                    // once the entrance animation has settled.
                    LaunchedEffect(Unit) {
                        delay(900)
                        InAppReviewHelper.requestOnce(context, app.progressManager)
                    }
                    ReviewStep(language, richMotion) {
                        goTo(OnboardingStep.Personalize)
                    }
                }
                OnboardingStep.Personalize -> PersonalizeStep(language) { goTo(OnboardingStep.Swipe) }
                OnboardingStep.Swipe -> SwipeCoursesStep(
                    language = language,
                    courses = swipeCourses,
                    ready = swipeReady,
                    onFinished = { liked ->
                        likedCourseIds = liked
                        goTo(OnboardingStep.Loading)
                    },
                )
                OnboardingStep.Loading -> LoadingProfileStep(language) { goTo(OnboardingStep.Profile) }
                OnboardingStep.Profile -> ProfileRewardStep(
                    language = language,
                    objectiveKeys = selectedObjectives.toList().ifEmpty { listOf(primaryObjective) },
                    likedCourseIds = likedCourseIds,
                    onContinue = { goTo(OnboardingStep.Login) },
                )
                OnboardingStep.Login -> LoginStep(
                    language = language,
                    onGoogle = {
                        scope.launch {
                            val signedIn = runCatching {
                                app.authService.signInWithGoogle(context)
                            }.getOrDefault(false)
                            if (!signedIn) return@launch
                            // A returning user signing in here gets their cloud progress
                            // back, same as signing in from settings.
                            runCatching {
                                app.progressSyncService.pullOnLogin(
                                    app.progressManager.progress.value,
                                )
                            }
                            // Skip trial explanation when the served annual product has no free trial.
                            goTo(
                                if (storeViewModel.shouldShowTrialSteps()) {
                                    OnboardingStep.Trial
                                } else {
                                    OnboardingStep.Reminder
                                },
                            )
                        }
                    },
                    onSkip = {
                        goTo(
                            if (storeViewModel.shouldShowTrialSteps()) {
                                OnboardingStep.Trial
                            } else {
                                OnboardingStep.Reminder
                            },
                        )
                    },
                )
                OnboardingStep.Trial -> TrialStepsStep(language) { goTo(OnboardingStep.Reminder) }
                OnboardingStep.Reminder -> ReminderStep(language, onContinue = { advanceFromReminder() })
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
                                stepIndex = current.ordinal,
                                stepName = "paywall_comparison",
                            )
                        },
                    )
                }
            }
        }

        val dotIndex = DOT_STEPS.indexOf(step)
        if (dotIndex >= 0) {
            OnboardingProgressDots(
                current = dotIndex,
                total = DOT_STEPS.size,
                modifier = Modifier.align(Alignment.TopCenter).padding(top = 14.dp),
            )
        }
    }
}
