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
import app.rork.sophia.SophiaApplication
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.paywall.OnboardingPaywallFlow
import app.rork.sophia.ui.theme.DS
import kotlinx.coroutines.launch

private enum class OnboardingStep {
    Welcome,
    Language,
    Objectives,
    ObjectiveIntro,
    Questions,
    PhoneTime,
    YearsGrid,
    Transform,
    Review,
    Personalize,
    Swipe,
    Loading,
    Profile,
    Login,
    Trial,
    Reminder,
    Paywall,
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
    LaunchedEffect(step) { app.analytics.trackOnboardingStep(step.ordinal, step.name) }

    fun finish(isPremiumAtExit: Boolean) {
        likedCourseIds.forEach { id ->
            if (!app.progressManager.isFavorite(id)) {
                app.progressManager.toggleFavorite(id)
            }
        }
        app.analytics.trackOnboardingCompleted(sawPaywall = sawPaywall, isPremium = isPremiumAtExit)
        onComplete()
    }

    fun advanceFromReminder() {
        if (isPremium) finish(true)
        else {
            sawPaywall = true
            step = OnboardingStep.Paywall
        }
    }

    val primaryObjective = selectedObjectives.firstOrNull() ?: "cultivate"
    val swipeCourses = remember(language) {
        ContentCatalog.courses(context, language).shuffled().take(5)
    }

    Box(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
        when (step) {
            OnboardingStep.Welcome -> WelcomeStep(language) { step = OnboardingStep.Language }
            OnboardingStep.Language -> LanguageStep(language) {
                onLanguageSelected(it)
                step = OnboardingStep.Objectives
            }
            OnboardingStep.Objectives -> ObjectivesStep(
                language = language,
                selected = selectedObjectives,
                onToggle = { key ->
                    selectedObjectives = selectedObjectives.toMutableSet().also { set ->
                        if (!set.add(key)) set.remove(key)
                    }
                },
                onContinue = { step = OnboardingStep.ObjectiveIntro },
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
                onFinished = { liked ->
                    likedCourseIds = liked
                    step = OnboardingStep.Loading
                },
            )
            OnboardingStep.Loading -> LoadingProfileStep(language) { step = OnboardingStep.Profile }
            OnboardingStep.Profile -> ProfileRewardStep(
                language = language,
                objectiveKey = primaryObjective,
                likedTitles = likedCourseIds.mapNotNull { id ->
                    ContentCatalog.course(context, language, id)?.title
                },
                onContinue = { step = OnboardingStep.Login },
            )
            OnboardingStep.Login -> LoginStep(
                language = language,
                onGoogle = {
                    scope.launch {
                        runCatching { app.authService.signInWithGoogle(context) }
                        step = OnboardingStep.Trial
                    }
                },
                onSkip = { step = OnboardingStep.Trial },
            )
            OnboardingStep.Trial -> TrialStepsStep(language) { step = OnboardingStep.Reminder }
            OnboardingStep.Reminder -> ReminderStep(language, onContinue = ::advanceFromReminder)
            OnboardingStep.Paywall -> {
                LaunchedEffect(Unit) { sawPaywall = true }
                OnboardingPaywallFlow(
                    language = language,
                    storeViewModel = storeViewModel,
                    onDismiss = { finish(false) },
                    onPurchased = { finish(true) },
                )
            }
        }
    }
}
