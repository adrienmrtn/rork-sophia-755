package app.rork.sophia.ui.onboarding

import androidx.activity.compose.BackHandler
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
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.listSaver
import androidx.compose.runtime.saveable.rememberSaveable
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
import app.rork.sophia.data.NotificationPermission
import app.rork.sophia.data.SignInOutcome
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.TrialReminderScheduler
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.ui.paywall.OnboardingPaywallFlow
import app.rork.sophia.ui.theme.DS
import com.revenuecat.purchases.Package
import kotlinx.coroutines.CancellationException
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
    Notifications("notifications"),
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

/** Saves the step by name, so a reordering of the enum cannot restore a different page. */
private val OnboardingStepSaver: Saver<OnboardingStep, String> = Saver(
    save = { it.name },
    restore = { name -> runCatching { OnboardingStep.valueOf(name) }.getOrNull() },
)

/**
 * The page back should land on. Mostly the declaration order, with the two branches the
 * forward flow can skip: the notifications page is not shown once the permission is settled,
 * and the trial explanation is skipped when the served product has no trial. Going back
 * through a page that was never shown would strand the user on a dead end.
 */
private fun previousStep(step: OnboardingStep, showsTrialSteps: Boolean): OnboardingStep? = when (step) {
    OnboardingStep.Welcome -> null
    // The paywall is the end of the flow; its own close button decides what "leaving" means.
    OnboardingStep.Paywall -> null
    OnboardingStep.Reminder -> if (showsTrialSteps) OnboardingStep.Trial else OnboardingStep.Login
    OnboardingStep.Trial -> OnboardingStep.Login
    else -> OnboardingStep.entries.getOrNull(step.ordinal - 1)
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
    // Blur and long infinite animations are dropped on Go phones and emulators.
    val richMotion = remember { !DeviceCapabilities.isConstrained(context) }
    // rememberSaveable, not remember: rotating the phone, switching theme or changing the
    // font size recreates the activity, and plain `remember` sent the user back to the
    // welcome page having lost every answer. The enum is saved by name so reordering the
    // steps later cannot resurrect the wrong one.
    var step by rememberSaveable(stateSaver = OnboardingStepSaver) {
        mutableStateOf(
            app.onboardingStore.lastStep()
                ?.let { name -> runCatching { OnboardingStep.valueOf(name) }.getOrNull() }
                ?: OnboardingStep.Welcome,
        )
    }
    var selectedObjectives by rememberSaveable(
        saver = listSaver<MutableState<Set<String>>, String>(
            save = { it.value.toList() },
            restore = { mutableStateOf(it.toSet()) },
        ),
    ) { mutableStateOf(setOf()) }
    var phoneMinutes by rememberSaveable { mutableIntStateOf(180) }
    var likedCourseIds by rememberSaveable(
        saver = listSaver<MutableState<List<String>>, String>(
            save = { it.value },
            restore = { mutableStateOf(it) },
        ),
    ) { mutableStateOf(listOf()) }
    var sawPaywall by rememberSaveable { mutableStateOf(false) }
    var lastAdvanceAt by remember { mutableLongStateOf(0L) }
    var signingIn by remember { mutableStateOf(false) }
    var signInError by remember { mutableStateOf<String?>(null) }
    var googleAvailable by remember {
        mutableStateOf(DeviceCapabilities.hasGooglePlayServices(context))
    }
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
        // Killing the app mid-onboarding used to restart the whole flow, answers and all.
        app.onboardingStore.rememberStep(step.name)
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

    fun scheduleTrialReminderIfEligible(purchased: Package?) {
        // Only schedule when the product the user actually bought has a free trial. Asking
        // the annual plan instead armed a "your trial ends tomorrow" reminder for someone
        // who had just bought a monthly plan with no trial at all.
        if (!storeViewModel.hasFreeTrial(purchased)) return
        // RevenueCat rarely knows the expiry this early, so this arms an assumed 3-day
        // trial; StoreViewModel re-aims it once the real expiration date arrives — and
        // cancels it if the entitlement turns out not to be in a trial.
        TrialReminderScheduler.scheduleTrialEndingReminder(
            context,
            storeViewModel.trialExpirationDate.value,
        )
    }

    /** The notifications page has nothing to add once the permission is already settled. */
    fun stepAfterProfile(): OnboardingStep =
        if (NotificationPermission.shouldAsk(context)) {
            OnboardingStep.Notifications
        } else {
            OnboardingStep.Login
        }

    /** Login, skipped or done, lands on the same next page. */
    fun advanceFromLogin() {
        // Skip trial explanation when the served annual product has no free trial.
        goTo(
            if (storeViewModel.shouldShowTrialSteps()) {
                OnboardingStep.Trial
            } else {
                OnboardingStep.Reminder
            },
        )
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

    // Back walks the flow backwards. The welcome page is the one place with nothing behind
    // it, so there the system default (leave the app) is the right answer.
    BackHandler(enabled = step != OnboardingStep.Welcome) {
        val previous = previousStep(step, storeViewModel.shouldShowTrialSteps())
        if (previous != null) {
            lastAdvanceAt = System.currentTimeMillis()
            step = previous
        }
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
                    onContinue = { goTo(stepAfterProfile()) },
                )
                OnboardingStep.Notifications -> NotificationsStep(language) {
                    goTo(OnboardingStep.Login)
                }
                OnboardingStep.Login -> LoginStep(
                    language = language,
                    signingIn = signingIn,
                    errorMessage = signInError,
                    googleAvailable = googleAvailable,
                    onGoogle = {
                        // Guard, not just a disabled button: a fast double tap can land two
                        // clicks before recomposition shows the disabled state, and the
                        // second Credential Manager request cancels the first.
                        if (signingIn) return@LoginStep
                        signingIn = true
                        signInError = null
                        scope.launch {
                            val outcome = try {
                                app.authService.signInWithGoogle(context)
                            } catch (e: CancellationException) {
                                // The user left the step while the sheet was up. Nothing to
                                // report, and nothing left to update — this scope is gone.
                                throw e
                            } catch (e: Exception) {
                                SignInOutcome.Failure(
                                    StringStore.text(context, "auth.error.generic", language),
                                )
                            }
                            signingIn = false
                            when (outcome) {
                                is SignInOutcome.Success -> {
                                    // A returning user signing in here gets their cloud
                                    // progress back, same as signing in from settings.
                                    runCatching {
                                        app.progressSyncService.pullOnLogin(
                                            app.progressManager.progress.value,
                                        )
                                    }
                                    app.onboardingStore.markAccountOffered()
                                    advanceFromLogin()
                                }
                                // Dismissed on purpose: leave the page exactly as it was.
                                is SignInOutcome.Cancelled -> Unit
                                is SignInOutcome.Unavailable -> {
                                    googleAvailable = false
                                    signInError = StringStore.text(
                                        context,
                                        "auth.unavailable.body",
                                        language,
                                    )
                                }
                                is SignInOutcome.Failure -> signInError = outcome.message
                            }
                        }
                    },
                    onContinueWithoutAccount = {
                        // Progress lives on the device from here on. The app asks again in
                        // the profile tab and after the third course.
                        app.onboardingStore.markSkippedAccount()
                        advanceFromLogin()
                    },
                    onSkip = {
                        if (DeviceCapabilities.allowsLoginBypass()) advanceFromLogin()
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
                        onPurchased = { purchased ->
                            scheduleTrialReminderIfEligible(purchased)
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
