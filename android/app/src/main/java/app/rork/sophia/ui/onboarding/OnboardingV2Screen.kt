package app.rork.sophia.ui.onboarding

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
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
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.analytics.Analytics
import app.rork.sophia.data.CourseAffinityStore
import app.rork.sophia.data.DeviceCapabilities
import app.rork.sophia.data.GlossaryStore
import app.rork.sophia.data.InAppReviewHelper
import app.rork.sophia.data.NotificationPermission
import app.rork.sophia.data.OnboardingAnswers
import app.rork.sophia.data.SignInOutcome
import app.rork.sophia.data.AuthorStore
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.TrialReminderScheduler
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.Subject
import app.rork.sophia.ui.components.DSProgressBar
import app.rork.sophia.ui.paywall.OnboardingPaywallFlow
import app.rork.sophia.ui.theme.ForceLightAppearance
import app.rork.sophia.ui.theme.DS
import com.revenuecat.purchases.Package
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * The fixed sequence of the onboarding, as on iOS (`OnboardingV2View`):
 *
 * Welcome · Language · Lessons · Researchers · Presentation (a carousel of four pages that
 * advance by themselves: quiz, path, duels, audio) · Social proof (500,000 users) · First
 * name · Age · General knowledge (slider) · Motivation · Objectives · Subjects · « Sophia
 * will help you » · Phone time · Life in years · « Turn that time » · Questions · Mission ·
 * Personalize · Swipe · 90-day curve · Notifications · Reviews · Loading · Profile ·
 * Login · Follow creators · Welcome aboard · Strengths · Trial · Reminder · Paywall.
 *
 * Two iOS pages are not here: the reading-time page sets the hour of the daily-course
 * notification, which Android does not send, and the account page (avatar and handle).
 *
 * The header (back arrow, carousel segments, progress bar) is laid here, once, over the
 * pages: each page gets [ONBOARDING_HEADER_HEIGHT] of room above it and knows nothing of it.
 */
private enum class OnboardingStep {
    Welcome,
    Language,
    Lessons,
    Researchers,
    Intro,
    SocialProof,
    Name,
    Age,
    Knowledge,
    Motivation,
    Objectives,
    Topics,
    ObjectiveIntro,
    PhoneTime,
    YearsGrid,
    Transform,
    Questions,
    Mission,
    Personalize,
    Swipe,
    Curve90,
    Notifications,
    Review,
    Loading,
    Profile,
    Login,
    FollowCreators,
    WelcomeAboard,
    Features,
    Trial,
    Reminder,
    Paywall,
    ;

    /** Même nom qu'iOS (`OnboardingV2View.Screen.analyticsName`), pour `onboarding_step`. */
    val analyticsName: String
        get() = when (this) {
            Welcome -> "welcome"
            Language -> "language"
            Lessons -> "lessons"
            Researchers -> "researchers"
            Intro -> "intro"
            SocialProof -> "social_proof"
            Name -> "name"
            Age -> "age"
            Knowledge -> "knowledge"
            Motivation -> "motivation"
            Objectives -> "objective"
            Topics -> "topics"
            ObjectiveIntro -> "objective_intro"
            PhoneTime -> "phone_time"
            YearsGrid -> "years_grid"
            Transform -> "transform"
            Questions -> "questions"
            Mission -> "mission"
            Personalize -> "personalize"
            Swipe -> "swipe_courses"
            Curve90 -> "curve_90"
            Notifications -> "notifications"
            Review -> "review"
            Loading -> "loading"
            Profile -> "profile"
            Login -> "login"
            FollowCreators -> "follow_creators"
            WelcomeAboard -> "welcome_aboard"
            Features -> "features"
            Trial -> "trial_steps"
            Reminder -> "reminder"
            // Android enchaîne les deux paywalls dans un seul écran ; iOS les sépare
            // (`paywall_annual`, `paywall_comparison`).
            Paywall -> "paywall"
        }
}

/** What the header shows above a step. */
private enum class HeaderKind {
    /** No header: the welcome page, then the login and everything after it. */
    None,

    /** The back arrow alone. */
    Back,

    /** The back arrow and the four segments of the carousel. */
    Segments,

    /** The back arrow and the 200 dp progress bar. */
    Progress,
}

/** Opening steps: the back arrow, no bar. */
private val BACK_ONLY_STEPS = setOf(OnboardingStep.Language, OnboardingStep.Lessons, OnboardingStep.Researchers)

/** Steps counted by the progress bar, in flow order: from the social proof to the profile included. */
private val PROGRESS_STEPS = listOf(
    OnboardingStep.SocialProof,
    OnboardingStep.Name,
    OnboardingStep.Age,
    OnboardingStep.Knowledge,
    OnboardingStep.Motivation,
    OnboardingStep.Objectives,
    OnboardingStep.Topics,
    OnboardingStep.ObjectiveIntro,
    OnboardingStep.PhoneTime,
    OnboardingStep.YearsGrid,
    OnboardingStep.Transform,
    OnboardingStep.Questions,
    OnboardingStep.Mission,
    OnboardingStep.Personalize,
    OnboardingStep.Swipe,
    OnboardingStep.Curve90,
    OnboardingStep.Notifications,
    OnboardingStep.Review,
    OnboardingStep.Loading,
    OnboardingStep.Profile,
)

private fun headerKind(step: OnboardingStep): HeaderKind = when (step) {
    OnboardingStep.Intro -> HeaderKind.Segments
    in BACK_ONLY_STEPS -> HeaderKind.Back
    in PROGRESS_STEPS -> HeaderKind.Progress
    else -> HeaderKind.None
}

/**
 * How full the bar is: the first counted step shows it barely started, the last fills it.
 * Before the counted steps it is empty, after them full, so it fades in and out at rest.
 */
private fun progressValue(step: OnboardingStep): Float {
    val index = PROGRESS_STEPS.indexOf(step)
    return when {
        index >= 0 -> (index + 1f) / PROGRESS_STEPS.size
        step.ordinal < PROGRESS_STEPS.first().ordinal -> 0f
        else -> 1f
    }
}

/** Subjects behind each objective, for the swipe deck when the subjects page gave nothing. */
private fun subjectsFor(objective: String): List<String> = when (objective) {
    "exams" -> listOf("histoire", "sciences", "litterature", "comprendreLeMonde")
    "impress" -> listOf("histoire", "art", "litterature", "mythologie")
    "curiosity" -> listOf("sciences", "mythologie", "art", "comprendreLeMonde")
    else -> Subject.entries.map { it.storageKey }
}

/** Four hand-picked hooks open the swipe deck, in this order (same list as iOS). */
private val PINNED_SWIPE_COURSE_IDS = listOf(
    "course_47_pourquoi_baille_t_on",
    "course_201_la_naissance_du_conflit_israelo_palestin",
    "course_149_la_joconde",
    "course_44_pourquoi_l_eau_de_mer_est_elle_salee",
)

/** Saves the step by name, so a reordering of the enum cannot restore a different page. */
private val OnboardingStepSaver: Saver<OnboardingStep, String> = Saver(
    save = { it.name },
    restore = { name -> runCatching { OnboardingStep.valueOf(name) }.getOrNull() },
)

/**
 * The page back should land on. Mostly the declaration order, with the branches the forward
 * flow can skip: the notifications page is not shown once the permission is settled, and
 * the trial explanation is skipped when the served product has no trial. Going back
 * through a page that was never shown would strand the user on a dead end. The loading
 * page is skipped too: it moves on by itself and would send the user straight back.
 */
private fun previousStep(
    step: OnboardingStep,
    showsTrialSteps: Boolean,
    showsNotifications: Boolean,
): OnboardingStep? = when (step) {
    OnboardingStep.Welcome -> null
    // The paywall is the end of the flow; its own close button decides what "leaving" means.
    OnboardingStep.Paywall -> null
    OnboardingStep.Reminder -> if (showsTrialSteps) OnboardingStep.Trial else OnboardingStep.Features
    OnboardingStep.Review -> if (showsNotifications) OnboardingStep.Notifications else OnboardingStep.Curve90
    OnboardingStep.Profile -> OnboardingStep.Review
    else -> OnboardingStep.entries.getOrNull(step.ordinal - 1)
}

@Composable
fun OnboardingV2Screen(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    onLanguageSelected: (AppLanguage) -> Unit,
    onComplete: () -> Unit,
) {
    // Designed light-only, as on iOS: the night palette stays off while it is shown.
    ForceLightAppearance()
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
    // Saved on every answer, like iOS's resume store: killing the app on any page resumes
    // there with everything given before.
    var answers by remember { mutableStateOf(app.onboardingStore.answers()) }
    fun updateAnswers(transform: (OnboardingAnswers) -> OnboardingAnswers) {
        answers = transform(answers)
        app.onboardingStore.saveAnswers(answers)
    }
    var lastAdvanceAt by remember { mutableLongStateOf(0L) }
    var signingIn by remember { mutableStateOf(false) }
    var signInError by remember { mutableStateOf<String?>(null) }
    var googleAvailable by remember {
        mutableStateOf(DeviceCapabilities.hasGooglePlayServices(context))
    }
    val scope = rememberCoroutineScope()
    // « I already have an account », opened from the welcome page.
    var showExistingAccount by remember { mutableStateOf(false) }
    val haptics = rememberOnboardingHaptics()
    val reduceMotion = rememberOnboardingReduceMotion()
    // Page and clock of the presentation carousel, shared with the segments of the header.
    val carousel = rememberSaveable(saver = OnboardingCarouselState.StateSaver) { OnboardingCarouselState() }
    // The animated logo, played once when the onboarding opens on the welcome page (first
    // launch, or a resume that stayed there). A resume further along does not replay it.
    var showSplash by rememberSaveable { mutableStateOf(step == OnboardingStep.Welcome) }

    // A racing timer (last swipe card, word animation) must not skip a whole screen.
    fun goTo(next: OnboardingStep) {
        val now = System.currentTimeMillis()
        if (now - lastAdvanceAt < 400L) return
        lastAdvanceAt = now
        // The button just vibrated: no doubling. Advances without a button (carousel, end of
        // the swipe) keep their light tick.
        if (!OnboardingHapticGate.justConfirmed) haptics.selection()
        // The carousel always starts from its first page when entered going forward.
        if (next == OnboardingStep.Intro) carousel.go(0)
        step = next
    }

    // Counted long before the strengths page needs it (« 2,600+ quiz questions »).
    LaunchedEffect(language) {
        runCatching { ContentCatalog.quizQuestionCountAsync(context.applicationContext, language) }
    }
    LaunchedEffect(step) {
        // Killing the app mid-onboarding used to restart the whole flow, answers and all.
        app.onboardingStore.rememberStep(step.name)
        Analytics.log("onboarding_step", props = mapOf("step" to step.analyticsName, "index" to step.ordinal))
    }
    // Warm the home feed + glossary during paywall so arriving on TikTok home is instant.
    LaunchedEffect(step, language) {
        if (step != OnboardingStep.Paywall && step != OnboardingStep.Reminder) return@LaunchedEffect
        val appContext = context.applicationContext
        runCatching {
            ContentCatalog.summariesAsync(appContext, language)
            CourseAffinityStore.load(appContext)
            GlossaryStore.preload(appContext, language)
        }
    }

    fun finish() {
        runCatching {
            likedCourseIds.forEach { id ->
                if (!app.progressManager.isFavorite(id)) {
                    app.progressManager.toggleFavorite(id)
                }
            }
        }
        onComplete()
    }

    fun scheduleTrialReminderIfEligible(purchased: Package?) {
        // Only schedule when the product the user actually bought has a free trial. Asking
        // the annual plan instead armed a "your trial ends tomorrow" reminder for someone
        // who had just bought a monthly plan with no trial at all.
        if (!storeViewModel.hasFreeTrial(purchased)) return
        // RevenueCat rarely knows the expiry this early, so this arms a reminder for the
        // trial length the bought product declares; StoreViewModel re-aims it once the real
        // expiration date arrives — and cancels it if the entitlement turns out not to be in
        // a trial.
        TrialReminderScheduler.scheduleTrialEndingReminder(
            context,
            storeViewModel.trialExpirationDate.value,
            assumedTrialDays = storeViewModel.trialDays(purchased) ?: 3,
        )
    }

    /** The notifications page has nothing to add once the permission is already settled. */
    fun stepAfterCurve90(): OnboardingStep =
        if (NotificationPermission.shouldAsk(context)) {
            OnboardingStep.Notifications
        } else {
            OnboardingStep.Review
        }

    /**
     * Google sign-in, shared by the login page and « I already have an account ». A returning
     * user gets their cloud progress back, same as signing in from settings, then [onSignedIn].
     */
    fun signInWithGoogle(onSignedIn: () -> Unit) {
        // Guard, not just a disabled button: a fast double tap can land two clicks before
        // recomposition shows the disabled state, and the second Credential Manager request
        // cancels the first.
        if (signingIn) return
        signingIn = true
        signInError = null
        scope.launch {
            val outcome = try {
                app.authService.signInWithGoogle(context)
            } catch (e: CancellationException) {
                // The user left the step while the sheet was up. Nothing to report, and
                // nothing left to update — this scope is gone.
                throw e
            } catch (e: Exception) {
                SignInOutcome.Failure(StringStore.text(context, "auth.error.generic", language))
            }
            signingIn = false
            when (outcome) {
                is SignInOutcome.Success -> {
                    runCatching {
                        app.progressSyncService.pullOnLogin(app.progressManager.progress.value)
                    }
                    app.onboardingStore.markAccountOffered()
                    onSignedIn()
                }
                // Dismissed on purpose: leave the page exactly as it was.
                is SignInOutcome.Cancelled -> Unit
                is SignInOutcome.Unavailable -> {
                    googleAvailable = false
                    signInError = StringStore.text(context, "auth.unavailable.body", language)
                }
                is SignInOutcome.Failure -> signInError = outcome.message
            }
        }
    }

    /** Login, skipped or done, lands on the same next page. */
    fun advanceFromLogin() {
        // « Suis des profs » n'a rien à montrer sans créateur dans le catalogue.
        val hasCreators = AuthorStore.all(context.applicationContext).any { it.courseIds.isNotEmpty() }
        goTo(if (hasCreators) OnboardingStep.FollowCreators else OnboardingStep.WelcomeAboard)
    }

    fun advanceFromFeatures() {
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
        if (isPremium) finish()
        else {
            step = OnboardingStep.Paywall
        }
    }

    val primaryObjective = selectedObjectives.firstOrNull() ?: "cultivate"
    // Subjects of the subjects page or, when it gave nothing, those of the objectives.
    val interests = answers.topics.toSet().ifEmpty { selectedObjectives.flatMap(::subjectsFor).toSet() }
    var swipeCourses by remember(language) { mutableStateOf<List<CourseSummary>>(emptyList()) }
    var swipeReady by remember(language) { mutableStateOf(false) }
    LaunchedEffect(language, interests) {
        // The four pinned hooks, then two courses from the chosen subjects.
        val all = ContentCatalog.summariesAsync(context.applicationContext, language)
        val byId = all.associateBy { it.id }
        val pinned = PINNED_SWIPE_COURSE_IDS.mapNotNull { byId[it] }
        val pool = all.filter { it.id !in PINNED_SWIPE_COURSE_IDS }
        val matching = pool.filter { interests.isEmpty() || it.subject in interests }.ifEmpty { pool }
        swipeCourses = pinned + matching.shuffled().take(PINNED_SWIPE_COURSE_IDS.size + 2 - pinned.size)
        swipeReady = true
    }

    // Back walks the flow backwards, from the header's arrow as from the system gesture.
    fun goBack() {
        // In the carousel, back walks its pages first.
        if (step == OnboardingStep.Intro && carousel.page > 0) {
            haptics.selection()
            carousel.go(carousel.page - 1, hold = true)
            return
        }
        val previous = previousStep(
            step,
            showsTrialSteps = storeViewModel.shouldShowTrialSteps(),
            showsNotifications = NotificationPermission.shouldAsk(context),
        ) ?: return
        // Back from the social proof, the carousel shows its last page, at rest: it must not
        // send the user by itself to the screen they just left.
        if (previous == OnboardingStep.Intro) {
            carousel.go(OnboardingCarouselState.PAGE_COUNT - 1, hold = true)
        }
        lastAdvanceAt = System.currentTimeMillis()
        haptics.selection()
        step = previous
    }

    // The welcome page is the one place with nothing behind it, so there the system default
    // (leave the app) is the right answer.
    BackHandler(enabled = step != OnboardingStep.Welcome) { goBack() }

    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    val slidePx = with(LocalDensity.current) { (if (reduceMotion) 0.dp else 64.dp).roundToPx() }

    Box(
        modifier = Modifier.fillMaxSize().background(DS.canvas),
        contentAlignment = Alignment.TopCenter,
    ) {
        // Bounded and centred on a tablet. Stretched across a landscape tablet these
        // one-column pages stop resembling the design, and the tallest of them pushes its
        // button below the fold. On a phone the cap is wider than the screen.
        Box(modifier = Modifier.fillMaxSize().readableWidth()) {
        AnimatedContent(
            targetState = step,
            transitionSpec = {
                // A horizontal slide on a spring with a fade, as the iOS `ov2Slide`: the new
                // page comes from the reading side going forward, from the other going back.
                val forward = targetState.ordinal > initialState.ordinal
                val sign = if (forward != rtl) 1 else -1
                (slideInHorizontally(spring(dampingRatio = 0.9f, stiffness = 130f)) { sign * slidePx } +
                    fadeIn(tween(300))) togetherWith
                    (slideOutHorizontally(spring(dampingRatio = 0.9f, stiffness = 130f)) { -sign * slidePx } +
                        fadeOut(tween(200)))
            },
            label = "onboardingStep",
        ) { current ->
            // Room for the header above the steps that carry one.
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(top = if (headerKind(current) == HeaderKind.None) 0.dp else ONBOARDING_HEADER_HEIGHT),
            ) {
            when (current) {
                OnboardingStep.Welcome -> WelcomeStep(
                    language = language,
                    onContinue = { goTo(OnboardingStep.Language) },
                    // The entrance of the page waits for the animated logo to finish playing.
                    entranceDelayMillis = if (showSplash) ONBOARDING_SPLASH_MILLIS else 0,
                    animateWall = richMotion,
                    // Without Google there is nothing to sign in with: no door to show.
                    onExistingAccount = if (googleAvailable) {
                        {
                            signInError = null
                            showExistingAccount = true
                        }
                    } else {
                        null
                    },
                )
                OnboardingStep.Language -> LanguageStep(
                    language = language,
                    onSelect = onLanguageSelected,
                    onContinue = { goTo(OnboardingStep.Lessons) },
                )
                OnboardingStep.Lessons -> LessonsStep(language) { goTo(OnboardingStep.Researchers) }
                OnboardingStep.Researchers -> ResearchersStep(language) { goTo(OnboardingStep.Intro) }
                OnboardingStep.Intro -> IntroCarouselStep(language, carousel) { goTo(OnboardingStep.SocialProof) }
                OnboardingStep.SocialProof -> SocialProofStep(language) { goTo(OnboardingStep.Name) }
                OnboardingStep.Name -> NameStep(
                    language = language,
                    initialName = answers.firstName,
                    onSubmit = { name ->
                        updateAnswers { it.copy(firstName = name.take(FIRST_NAME_MAX_LENGTH)) }
                        goTo(OnboardingStep.Age)
                    },
                )
                OnboardingStep.Age -> AgeStep(
                    language = language,
                    selected = answers.ageRange,
                    onSelect = { key -> updateAnswers { it.copy(ageRange = key) } },
                    onContinue = { goTo(OnboardingStep.Knowledge) },
                )
                OnboardingStep.Knowledge -> KnowledgeStep(
                    language = language,
                    initialLevel = answers.knowledgeLevel,
                    onContinue = { level ->
                        updateAnswers { it.copy(knowledgeLevel = level) }
                        goTo(OnboardingStep.Motivation)
                    },
                )
                OnboardingStep.Motivation -> MotivationStep(
                    language = language,
                    selected = answers.motivation,
                    onSelect = { key -> updateAnswers { it.copy(motivation = key) } },
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
                        goTo(OnboardingStep.Topics)
                    },
                )
                OnboardingStep.Topics -> TopicsStep(
                    language = language,
                    selected = answers.topics,
                    onToggle = { key ->
                        updateAnswers {
                            it.copy(topics = if (key in it.topics) it.topics - key else it.topics + key)
                        }
                    },
                    onContinue = { goTo(OnboardingStep.ObjectiveIntro) },
                )
                OnboardingStep.ObjectiveIntro -> ObjectiveIntroStep(language, answers.firstName) {
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
                OnboardingStep.Transform -> TransformStep(language) { goTo(OnboardingStep.Questions) }
                OnboardingStep.Questions -> QuestionsStep(language, richMotion) {
                    goTo(OnboardingStep.Mission)
                }
                OnboardingStep.Mission -> MissionStep(language) { goTo(OnboardingStep.Personalize) }
                OnboardingStep.Personalize -> PersonalizeStep(language) { goTo(OnboardingStep.Swipe) }
                OnboardingStep.Swipe -> SwipeCoursesStep(
                    language = language,
                    courses = swipeCourses,
                    ready = swipeReady,
                    onFinished = { liked ->
                        likedCourseIds = liked
                        goTo(OnboardingStep.Curve90)
                    },
                )
                OnboardingStep.Curve90 -> Curve90Step(language) { goTo(stepAfterCurve90()) }
                OnboardingStep.Notifications -> NotificationsStep(language) {
                    goTo(OnboardingStep.Review)
                }
                OnboardingStep.Review -> {
                    // Ask for the Play rating on the page that already talks about ratings,
                    // once the entrance animation has settled.
                    LaunchedEffect(Unit) {
                        delay(900)
                        InAppReviewHelper.requestOnce(context, app.progressManager)
                    }
                    ReviewStep(language, richMotion) {
                        goTo(OnboardingStep.Loading)
                    }
                }
                OnboardingStep.Loading -> LoadingProfileStep(language, answers.firstName) {
                    goTo(OnboardingStep.Profile)
                }
                OnboardingStep.Profile -> ProfileRewardStep(
                    language = language,
                    firstName = answers.firstName,
                    objectiveKeys = selectedObjectives.toList().ifEmpty { listOf(primaryObjective) },
                    likedCourseIds = likedCourseIds,
                    onContinue = { goTo(OnboardingStep.Login) },
                )
                OnboardingStep.Login -> LoginStep(
                    language = language,
                    signingIn = signingIn,
                    errorMessage = signInError,
                    googleAvailable = googleAvailable,
                    onGoogle = { signInWithGoogle { advanceFromLogin() } },
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
                OnboardingStep.FollowCreators -> FollowCreatorsStep(
                    language = language,
                    chosenSubjects = answers.topics.toSet(),
                    progressManager = app.progressManager,
                    onContinue = { goTo(OnboardingStep.WelcomeAboard) },
                )
                OnboardingStep.WelcomeAboard -> WelcomeAboardStep(
                    language = language,
                    firstName = answers.firstName,
                    richMotion = richMotion,
                    onContinue = { goTo(OnboardingStep.Features) },
                )
                OnboardingStep.Features -> FeaturesStep(language, answers.firstName) { advanceFromFeatures() }
                OnboardingStep.Trial -> TrialStepsStep(language, storeViewModel.annualTrialDays()) { goTo(OnboardingStep.Reminder) }
                OnboardingStep.Reminder -> ReminderStep(language, onContinue = { advanceFromReminder() })
                OnboardingStep.Paywall -> {
                    OnboardingPaywallFlow(
                        language = language,
                        storeViewModel = storeViewModel,
                        onDismiss = { finish() },
                        onPurchased = { purchased ->
                            scheduleTrialReminderIfEligible(purchased)
                            finish()
                        },
                    )
                }
            }
            }
        }

        }

        // The header of the current step; nothing on the welcome page, nor from the login on.
        val kind = headerKind(step)
        AnimatedVisibility(
            visible = kind != HeaderKind.None,
            modifier = Modifier.align(Alignment.TopCenter),
            enter = fadeIn(tween(220)),
            exit = fadeOut(tween(160)),
        ) {
            OnboardingHeader(
                backLabel = StringStore.text(context, "training.backToTraining", language),
                onBack = { goBack() },
            ) {
                AnimatedContent(
                    targetState = kind,
                    transitionSpec = { fadeIn(tween(200)) togetherWith fadeOut(tween(150)) },
                    label = "onboardingHeader",
                ) { shown ->
                    when (shown) {
                        HeaderKind.Segments -> OnboardingStorySegments(
                            count = OnboardingCarouselState.PAGE_COUNT,
                            current = carousel.page,
                            // A page that does not advance by itself shows its segment full.
                            progress = { if (carousel.isRunning) carousel.progress else 1f },
                        )
                        HeaderKind.Progress -> DSProgressBar(value = progressValue(step))
                        HeaderKind.Back, HeaderKind.None -> Spacer(Modifier.fillMaxWidth().height(5.dp))
                    }
                }
            }
        }

        // Someone reinstalling or switching phone: sign in and land in the app with their
        // history, skipping the questions they answered the first time (as on iOS).
        AnimatedVisibility(
            visible = showExistingAccount,
            enter = slideInVertically(spring(dampingRatio = 0.9f, stiffness = Spring.StiffnessMediumLow)) { it } + fadeIn(),
            exit = slideOutVertically(tween(260)) { it } + fadeOut(tween(200)),
        ) {
            BackHandler { if (!signingIn) showExistingAccount = false }
            ExistingAccountStep(
                language = language,
                signingIn = signingIn,
                errorMessage = signInError,
                onGoogle = {
                    signInWithGoogle {
                        showExistingAccount = false
                        finish()
                    }
                },
                onClose = { if (!signingIn) showExistingAccount = false },
            )
        }

        AnimatedVisibility(
            visible = showSplash,
            enter = EnterTransition.None,
            exit = fadeOut(tween(350)),
        ) {
            OnboardingSplash(onFinished = { showSplash = false })
        }
    }
}
