package app.rork.sophia.ui.paywall

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.GenericShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Assignment
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.Replay
import androidx.compose.material.icons.outlined.FileDownload
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.Lightbulb
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.PhoneAndroid
import androidx.compose.material.icons.outlined.Speed
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import app.rork.sophia.R
import app.rork.sophia.audio.CourseAudioCatalog
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.PaywallExperiment
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Course
import app.rork.sophia.ui.audio.AudioFormat
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.onboarding.readableWidth
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.uppercaseInApp
import com.revenuecat.purchases.Package
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * The contextual paywalls of the « Elevate arrondi » design: course unlock (two variants, split
 * by [PaywallExperiment]), quiz and audio. They share one frame — a scrolling pitch, the choice
 * of plans, the CTA pinned at the bottom — and the purchase logic of the paywalls they replace:
 * the offering of the context, the plans the store really serves, a trial only when there is one.
 */

/** Sample colours of the quiz illustration (the amber of a subject chip, the dark green of a right answer). */
private val SampleAmberInk = Color(0xFF7A5310)
private val SampleAmberTint = Color(0xFFFBF1D6)
private val SampleRightInk = Color(0xFF24563C)
private val SampleBodyInk = Color(0xFF4B5563)
private val SampleRing = Color(0xFFC3CBD8)
private val SampleTrack = Color(0xFFE1E5EB)

private const val SAMPLE_AUDIO_COURSE = "course_281_comment_meurt_une_etoile"

/** The three courses of the mock-up; any missing one is replaced by another course of the catalogue. */
private val FEATURED_COURSES = listOf(
    SAMPLE_AUDIO_COURSE,
    "course_272_pourquoi_la_coree_est_elle_coupee_en",
    "course_283_qu_y_a_t_il_vraiment_dans_un_smartphone",
)

// region Frame

/** The plans on offer and the one chosen, handed to the pitch so it can draw the plan cards. */
internal class ElevatePlanChoice(
    val language: AppLanguage,
    val storeViewModel: StoreViewModel,
    val annual: Package?,
    /** Monthly today; weekly when the served offering carries a weekly package instead. */
    val shortPlan: Package?,
    private val yearlyChosen: Boolean,
    val select: (yearly: Boolean) -> Unit,
    val legal: ElevateLegalActions,
) {
    val yearlySelected: Boolean get() = yearlyChosen || shortPlan == null
    val selected: Package? get() = if (yearlySelected) annual else shortPlan
    val shortIsWeekly: Boolean get() = storeViewModel.isWeekly(shortPlan)
    val selectedHasTrial: Boolean get() = storeViewModel.hasFreeTrial(selected)
    val selectedTrialDays: Int get() = storeViewModel.trialDays(selected) ?: 3

    /** « Économise 58% », from the real prices; null when the annual plan is not cheaper. */
    fun saveBadge(context: android.content.Context): String? =
        storeViewModel.discountBadge(annual, shortPlan, if (shortIsWeekly) 52 else 12)?.let {
            StringStore.text(context, "onboardingV2.pw.save", language, it.removePrefix("-"))
        }
}

/**
 * What the store charges once the trial is over, for the chosen plan. A weekly plan has no
 * sentence of its own: it reads « 3 jours offerts · 2,99 € / semaine » from existing strings.
 */
private fun elevatePriceLine(context: android.content.Context, choice: ElevatePlanChoice): String {
    val store = choice.storeViewModel
    val language = choice.language
    val pkg = choice.selected
    val price = store.formattedPrice(pkg, StoreViewModel.UNKNOWN_PRICE)
    val hasTrial = choice.selectedHasTrial
    val days = choice.selectedTrialDays
    return when {
        choice.yearlySelected && hasTrial ->
            StringStore.trialText(context, "paywall.price.trialThenYearly", language, days, price)
        choice.yearlySelected -> StringStore.text(context, "paywall.price.yearlyNoTrial", language, price)
        choice.shortIsWeekly -> {
            val perWeek = price + " " + StringStore.text(context, "paywall.plan.perWeek", language)
            if (hasTrial) {
                StringStore.trialText(context, "onboardingV2.pw.trialBadge", language, days) + " · " + perWeek
            } else {
                perWeek
            }
        }
        hasTrial -> StringStore.trialText(context, "paywall.elevate.common.price.trialThenMonthly", language, days, price)
        else -> StringStore.text(context, "paywall.elevate.common.price.monthlyNoTrial", language, price)
    }
}

/**
 * The frame of a contextual paywall. [pitch] scrolls; the CTA, the price line and (unless the
 * pitch carries them itself, [pinnedLegal] = false) the legal links stay pinned at the bottom.
 */
@Composable
private fun ElevatePaywallFrame(
    paywallContext: PaywallContext,
    paywallId: String,
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    onDismiss: () -> Unit,
    onPurchased: () -> Unit,
    legal: ElevateLegalActions,
    analyticsProps: Map<String, Any?> = emptyMap(),
    closeDelayMillis: Int = 0,
    /** The translucent cross over the header picture; false when the pitch draws its own close button. */
    floatingClose: Boolean = true,
    pinnedLegal: Boolean = true,
    pitch: @Composable ColumnScope.(ElevatePlanChoice) -> Unit,
) {
    val context = LocalContext.current
    LaunchedEffect(Unit) {
        storeViewModel.fetchOfferings()
        storeViewModel.trackPaywallImpression(paywallId, paywallContext.offeringId, analyticsProps)
    }
    val offerings by storeViewModel.offerings.collectAsState()
    val annual = remember(offerings) { storeViewModel.annualPackage(paywallContext.offeringId) }
    val shortPlan = remember(offerings) { storeViewModel.shortPlanPackage(paywallContext.offeringId) }
    var yearlyChosen by remember { mutableStateOf(true) }
    var purchasing by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var notice by remember { mutableStateOf<String?>(null) }
    val choice = ElevatePlanChoice(
        language = language,
        storeViewModel = storeViewModel,
        annual = annual,
        shortPlan = shortPlan,
        yearlyChosen = yearlyChosen,
        select = { yearlyChosen = it },
        legal = legal,
    )
    val hasTrial = choice.selectedHasTrial
    val priceLine = elevatePriceLine(context, choice)

    Column(
        modifier = Modifier.fillMaxSize().background(DS.canvas),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(modifier = Modifier.weight(1f).readableWidth()) {
            Column(modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
                pitch(choice)
            }
            if (floatingClose) {
                ElevateCloseButton(
                    language = language,
                    onClose = onDismiss,
                    delayMillis = closeDelayMillis,
                    style = ElevateCloseStyle.Floating,
                    modifier = Modifier.align(Alignment.TopEnd).padding(14.dp),
                )
            }
        }
        Box(modifier = Modifier.fillMaxWidth().background(DS.canvas), contentAlignment = Alignment.Center) {
            ElevateBottomBar(
                modifier = Modifier.readableWidth(),
                ctaText = StringStore.text(
                    context,
                    if (hasTrial) "paywall.cta.unlockFree" else "paywall.cta.subscribe",
                    language,
                ),
                ctaIcon = Icons.Outlined.Lock,
                purchasing = purchasing,
                error = error,
                notice = notice,
                // Without a trial the price line already says the plan can be cancelled.
                lines = if (pinnedLegal && hasTrial) {
                    listOf(priceLine, StringStore.text(context, "paywall.cancelAnytime", language))
                } else {
                    listOf(priceLine)
                },
                linesWeight = if (pinnedLegal) FontWeight.Normal else FontWeight.SemiBold,
                legal = if (pinnedLegal) {
                    { ElevateLegalLinks(language = language, actions = legal) }
                } else {
                    null
                },
                onPurchase = {
                    purchasePackage(
                        context = context,
                        language = language,
                        pkg = choice.selected,
                        storeViewModel = storeViewModel,
                        onStart = { purchasing = true },
                        onDone = { purchasing = false },
                        onError = { error = it; notice = null; purchasing = false },
                        onPending = { notice = it; error = null; purchasing = false },
                        onPurchased = onPurchased,
                        paywallId = paywallId,
                        analyticsProps = analyticsProps,
                    )
                },
            )
        }
    }
}

/** The name of the short plan: « Mensuel », or « Hebdomadaire » when the offering serves a weekly one. */
private fun shortPlanName(context: android.content.Context, choice: ElevatePlanChoice): String = StringStore.text(
    context,
    if (choice.shortIsWeekly) "onboardingV2.pw.weekly" else "paywall.plan.monthly",
    choice.language,
)

/**
 * « Choisis ta formule » of the bonhomme paywalls: banded cards with the price per week, then
 * the trial of the chosen plan as a special offer when the store grants one.
 */
@Composable
private fun ElevateBandedPlans(choice: ElevatePlanChoice, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val language = choice.language
    val store = choice.storeViewModel
    val perWeek = StringStore.text(context, "paywall.plan.perWeek", language)
    Column(
        modifier = modifier.fillMaxWidth().padding(start = 20.dp, end = 20.dp, top = 32.dp, bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        ElevateSectionTitle(
            text = StringStore.text(context, "paywall.elevate.common.plans.title", language),
            modifier = Modifier.fillMaxWidth().padding(bottom = 4.dp),
        )
        ElevatePlanCard(
            style = ElevatePlanStyle.Banded,
            selected = choice.yearlySelected,
            onClick = { choice.select(true) },
            name = StringStore.text(context, "paywall.plan.yearly", language),
            subtitle = store.formattedPrice(choice.annual, StoreViewModel.UNKNOWN_PRICE),
            price = store.formattedYearlyPerWeek(choice.annual, StoreViewModel.UNKNOWN_PRICE),
            priceUnit = if (choice.annual == null) "" else perWeek,
            badge = choice.saveBadge(context),
        )
        if (choice.shortPlan != null) {
            val shortPrice = store.formattedPrice(choice.shortPlan, StoreViewModel.UNKNOWN_PRICE)
            ElevatePlanCard(
                style = ElevatePlanStyle.Banded,
                selected = !choice.yearlySelected,
                onClick = { choice.select(false) },
                name = shortPlanName(context, choice),
                subtitle = shortPrice,
                price = if (choice.shortIsWeekly) shortPrice else store.formattedMonthlyPerWeek(choice.shortPlan, shortPrice),
                priceUnit = perWeek,
                badge = StringStore.text(context, "paywall.plan.monthlySubtitle", language),
            )
        }
        if (choice.selectedHasTrial) {
            ElevateTrialOfferCard(
                badge = StringStore.text(context, "paywall.elevate.common.offer.badge", language),
                title = StringStore.trialText(context, "onboardingV2.pw.trialBadge", language, choice.selectedTrialDays),
                body = StringStore.text(context, "paywall.elevate.common.offer.body", language),
            )
        }
    }
}

/**
 * « Choisis ta formule » of the reviews variant: radio cards with the price per month, then the
 * cancellation line and the legal links, which this variant keeps in the scroll.
 */
@Composable
private fun ElevateRadioPlans(choice: ElevatePlanChoice, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val language = choice.language
    val store = choice.storeViewModel
    val weekly = choice.shortIsWeekly
    val unit = StringStore.text(context, if (weekly) "paywall.plan.perWeek" else "paywall.plan.perMonth", language)
    val annualPrice = store.formattedPrice(choice.annual, StoreViewModel.UNKNOWN_PRICE)
    // « quelle que soit la formule »: only true when every plan on offer comes with a trial.
    val trialOnEveryPlan = store.hasFreeTrial(choice.annual) &&
        (choice.shortPlan == null || store.hasFreeTrial(choice.shortPlan)) &&
        (choice.shortPlan == null || store.trialDays(choice.shortPlan) == store.trialDays(choice.annual))
    Column(
        modifier = modifier.fillMaxWidth().padding(start = 20.dp, end = 20.dp, top = 40.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(start = 4.dp, end = 4.dp, bottom = 4.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            ElevateSectionTitle(
                text = StringStore.text(context, "paywall.elevate.common.plans.title", language),
                align = TextAlign.Start,
            )
            if (trialOnEveryPlan) {
                PwText(
                    text = StringStore.trialText(
                        context, "paywall.elevate.reviews.plans.subtitle", language, store.trialDays(choice.annual) ?: 3,
                    ),
                    size = 14.sp,
                    weight = FontWeight.Normal,
                    color = DS.inkSecondary,
                    lineHeight = 19.sp,
                )
            }
        }
        ElevatePlanCard(
            style = ElevatePlanStyle.Radio,
            selected = choice.yearlySelected,
            onClick = { choice.select(true) },
            name = StringStore.text(context, "paywall.plan.yearly", language),
            subtitle = if (choice.annual == null) {
                annualPrice
            } else {
                annualPrice + " " + StringStore.text(context, "paywall.plan.perYear", language)
            },
            price = if (weekly) {
                store.formattedYearlyPerWeek(choice.annual, StoreViewModel.UNKNOWN_PRICE)
            } else {
                store.formattedYearlyPerMonth(choice.annual, StoreViewModel.UNKNOWN_PRICE)
            },
            priceUnit = if (choice.annual == null) "" else unit,
            badge = choice.saveBadge(context),
        )
        if (choice.shortPlan != null) {
            ElevatePlanCard(
                style = ElevatePlanStyle.Radio,
                selected = !choice.yearlySelected,
                onClick = { choice.select(false) },
                name = shortPlanName(context, choice),
                subtitle = StringStore.text(context, "paywall.plan.monthlySubtitle", language),
                price = store.formattedPrice(choice.shortPlan, StoreViewModel.UNKNOWN_PRICE),
                priceUnit = unit,
            )
        }
        PwText(
            text = StringStore.text(context, "paywall.cancelAnytime", language),
            size = 13.sp,
            weight = FontWeight.Normal,
            color = DS.inkSecondary,
            align = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(top = 6.dp),
        )
        ElevateLegalLinks(
            language = language,
            actions = choice.legal,
            order = listOf("paywall.terms", "paywall.privacy", "paywall.restore"),
            spread = false,
            modifier = Modifier.padding(bottom = 20.dp),
        )
    }
}

/** Title then grey subtitle under a before/after header. */
@Composable
private fun ElevateTitleBlock(title: String, subtitle: String?, modifier: Modifier = Modifier) {
    Column(modifier = modifier.fillMaxWidth()) {
        ElevatePaywallTitle(
            text = title,
            modifier = Modifier.fillMaxWidth().padding(start = 28.dp, end = 28.dp, top = 20.dp),
        )
        if (subtitle != null) {
            PwText(
                text = subtitle,
                size = 15.sp,
                weight = FontWeight.Normal,
                color = DS.inkSecondary,
                lineHeight = 22.sp,
                align = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(start = 24.dp, end = 24.dp, top = 10.dp),
            )
        }
    }
}

// endregion

// region Course unlock (A/B)

/**
 * Free daily course already used. Two pitches are tested against each other
 * ([PaywallExperiment]): the « bonhomme » before/after, and the library with its reviews.
 * The variant travels with the impression and the purchase events. The close button waits
 * two seconds, as before.
 */
@Composable
internal fun CourseUnlockPaywall(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    variant: PaywallExperiment.Variant,
    onDismiss: () -> Unit,
    onPurchased: () -> Unit,
    legal: ElevateLegalActions,
) {
    val context = LocalContext.current
    val reviews = variant == PaywallExperiment.Variant.REVIEWS
    ElevatePaywallFrame(
        paywallContext = PaywallContext.DEBLOQUER_COURS,
        paywallId = variant.paywallId,
        language = language,
        storeViewModel = storeViewModel,
        onDismiss = onDismiss,
        onPurchased = onPurchased,
        legal = legal,
        analyticsProps = PaywallExperiment.analyticsProps(variant),
        closeDelayMillis = 2000,
        floatingClose = !reviews,
        pinnedLegal = !reviews,
    ) { choice ->
        if (reviews) {
            // The cross keeps its place while it waits, so the title does not jump when it appears.
            Box(modifier = Modifier.padding(start = 20.dp, end = 20.dp, top = 18.dp).size(44.dp)) {
                ElevateCloseButton(
                    language = language,
                    onClose = onDismiss,
                    delayMillis = 2000,
                    style = ElevateCloseStyle.Bordered,
                )
            }
            Column(
                modifier = Modifier.fillMaxWidth().padding(start = 28.dp, end = 28.dp, top = 6.dp).dsStagger(0),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                PwText(
                    text = StringStore.text(context, "paywall.elevate.reviews.title", language),
                    size = 30.sp,
                    weight = FontWeight.Medium,
                    lineHeight = 34.sp,
                    letterSpacing = 0.2.sp,
                    align = TextAlign.Center,
                )
                Image(
                    painter = painterResource(R.drawable.sophia_mark),
                    contentDescription = "Sophia",
                    contentScale = ContentScale.FillHeight,
                    modifier = Modifier.height(38.dp),
                )
            }
            CourseFan(language = language, modifier = Modifier.padding(top = 22.dp).dsStagger(1))
            ElevateFeatureList(
                language = language,
                modifier = Modifier.padding(start = 28.dp, end = 28.dp, top = 22.dp).dsStagger(2),
            )
            ElevateExpertsCard(
                language = language,
                modifier = Modifier.padding(start = 20.dp, end = 20.dp, top = 32.dp).dsStagger(3),
            )
            ElevateReviewsBlock(language = language, modifier = Modifier.padding(top = 32.dp).dsStagger(4))
            ElevateRadioPlans(choice, modifier = Modifier.dsStagger(5))
        } else {
            ElevateBeforeAfterHeader(
                before = R.drawable.pw_course_before,
                after = R.drawable.pw_course_after,
                beforeLabel = StringStore.text(context, "paywall.elevate.common.before", language),
            ) {
                ElevateWithLogoLabel(StringStore.text(context, "paywall.elevate.common.with", language))
            }
            ElevateTitleBlock(
                title = StringStore.text(context, "paywall.elevate.course.title", language),
                subtitle = null,
                modifier = Modifier.dsStagger(0),
            )
            ElevateFeatureList(
                language = language,
                modifier = Modifier.padding(start = 28.dp, end = 28.dp, top = 22.dp).dsStagger(1),
            )
            ElevateExpertsCard(
                language = language,
                modifier = Modifier.padding(start = 20.dp, end = 20.dp, top = 26.dp).dsStagger(2),
            )
            // Not in the bonhomme mock-up: the owner asked for the reviews right under the experts.
            ElevateReviewsBlock(language = language, modifier = Modifier.padding(top = 32.dp).dsStagger(3))
            ElevateBandedPlans(choice, modifier = Modifier.dsStagger(4))
        }
    }
}

private val OvalShape = GenericShape { size, _ -> addOval(Rect(0f, 0f, size.width, size.height)) }

/** Three real course cards fanned out over a soft ground shadow: the library, at a glance. */
@Composable
private fun CourseFan(language: AppLanguage, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val courses by produceState<List<Course>>(initialValue = emptyList(), language) {
        value = withContext(Dispatchers.IO) {
            runCatching {
                val all = ContentCatalog.courses(context.applicationContext, language)
                val byId = all.associateBy { it.id }
                (FEATURED_COURSES.mapNotNull { byId[it] } + all.filter { it.id !in FEATURED_COURSES }).take(3)
            }.getOrDefault(emptyList())
        }
    }
    Box(modifier = modifier.fillMaxWidth().height(262.dp), contentAlignment = Alignment.TopCenter) {
        Box(
            modifier = Modifier
                .offset(y = 232.dp)
                .size(width = 200.dp, height = 18.dp)
                .background(DS.hairline, OvalShape),
        )
        courses.getOrNull(1)?.let {
            FanCard(it, language, large = false, modifier = Modifier.offset(x = (-77).dp, y = 34.dp).rotate(-9f))
        }
        courses.getOrNull(2)?.let {
            FanCard(it, language, large = false, modifier = Modifier.offset(x = 77.dp, y = 34.dp).rotate(9f))
        }
        courses.getOrNull(0)?.let {
            FanCard(it, language, large = true, modifier = Modifier.offset(y = 4.dp).zIndex(2f))
        }
    }
}

@Composable
private fun FanCard(course: Course, language: AppLanguage, large: Boolean, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val width: Dp = if (large) 144.dp else 112.dp
    Column(
        modifier = modifier
            .width(width)
            .clip(RoundedCornerShape(if (large) 10.dp else 8.dp))
            .background(DS.surface)
            .clearAndSetSemantics { },
    ) {
        Column(
            modifier = Modifier.padding(
                start = if (large) 10.dp else 8.dp,
                end = if (large) 10.dp else 8.dp,
                top = if (large) 10.dp else 8.dp,
                bottom = if (large) 8.dp else 6.dp,
            ),
            verticalArrangement = Arrangement.spacedBy(if (large) 4.dp else 3.dp),
        ) {
            Image(
                painter = painterResource(R.drawable.sophia_mark),
                contentDescription = null,
                contentScale = ContentScale.FillHeight,
                modifier = Modifier.height(if (large) 12.dp else 10.dp),
            )
            PwText(
                text = course.title,
                size = if (large) 13.sp else 10.sp,
                weight = FontWeight.Bold,
                lineHeight = if (large) 16.sp else 12.sp,
                maxLines = 3,
            )
            if (large) {
                val subject = StringStore.text(context, "subject.${course.subjectEnum.storageKey}.short", language)
                PwText(
                    text = listOf(subject, course.subcategory).filter { it.isNotBlank() }.joinToString(" · "),
                    size = 10.sp,
                    weight = FontWeight.SemiBold,
                    color = DS.inkSecondary,
                    maxLines = 1,
                )
            }
        }
        CourseImage(
            courseId = course.id,
            modifier = Modifier.fillMaxWidth().height(if (large) 160.dp else 112.dp),
            contentScale = ContentScale.Crop,
            maxEdgePx = 480,
            letterSize = 28.sp,
        )
    }
}

// endregion

// region Quiz

/**
 * Quiz paywall, opened when a free reader taps the quiz at the end of a course: without and
 * with the quizzes, a sample question with its explanation, what the training brings, then the
 * plans. The close button waits four seconds, as before.
 */
@Composable
internal fun QuizPaywall(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    onDismiss: () -> Unit,
    onPurchased: () -> Unit,
    legal: ElevateLegalActions,
) {
    val context = LocalContext.current
    ElevatePaywallFrame(
        paywallContext = PaywallContext.QUIZZ,
        paywallId = "native_quiz",
        language = language,
        storeViewModel = storeViewModel,
        onDismiss = onDismiss,
        onPurchased = onPurchased,
        legal = legal,
        closeDelayMillis = 4000,
    ) { choice ->
        ElevateBeforeAfterHeader(
            before = R.drawable.pw_quiz_before,
            after = R.drawable.pw_quiz_after,
            beforeLabel = StringStore.text(context, "paywall.quiz.chart.without", language),
        ) {
            ElevateAfterLabel(StringStore.text(context, "paywall.quiz.chart.with", language))
        }
        ElevateTitleBlock(
            title = StringStore.text(context, "paywall.elevate.quiz.title", language),
            subtitle = StringStore.text(context, "paywall.elevate.quiz.subtitle", language),
            modifier = Modifier.dsStagger(0),
        )
        SampleQuizCard(language, modifier = Modifier.padding(start = 20.dp, end = 20.dp, top = 24.dp).dsStagger(1))
        Column(
            modifier = Modifier.fillMaxWidth().padding(start = 20.dp, end = 20.dp, top = 32.dp).dsStagger(2),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Image(
                painter = painterResource(R.drawable.pw_quiz_training),
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxWidth().aspectRatio(350f / 262f).clip(DS.cardShape),
            )
            ElevateSectionTitle(
                text = StringStore.text(context, "paywall.elevate.quiz.benefits.title", language),
                modifier = Modifier.fillMaxWidth().padding(start = 4.dp, end = 4.dp, top = 4.dp),
            )
            Column(
                modifier = Modifier.padding(start = 6.dp, end = 6.dp, top = 4.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                listOf(
                    Icons.AutoMirrored.Outlined.Assignment,
                    Icons.Outlined.History,
                    Icons.Outlined.Lightbulb,
                ).forEachIndexed { index, icon ->
                    ElevateIconRow(
                        icon = icon,
                        title = StringStore.text(context, "paywall.elevate.quiz.benefit${index + 1}.title", language),
                        body = StringStore.text(context, "paywall.elevate.quiz.benefit${index + 1}.body", language),
                    )
                }
            }
        }
        ElevateBandedPlans(choice, modifier = Modifier.dsStagger(3))
    }
}

/** A question of a real quiz, answered: what a quiz looks like, without being one. */
@Composable
private fun SampleQuizCard(language: AppLanguage, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    fun t(key: String) = StringStore.text(context, "paywall.sample.quiz.$key", language)
    Column(
        modifier = modifier.fillMaxWidth().sophiaCard().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            PwText(
                text = StringStore.text(context, "paywall.sample.quiz.progress", language, 4, 5).uppercaseInApp(),
                size = 12.sp,
                weight = FontWeight.Bold,
                color = DS.inkSecondary,
                letterSpacing = 0.5.sp,
                modifier = Modifier.weight(1f),
            )
            PwText(
                text = t("course"),
                size = 12.sp,
                weight = FontWeight.Bold,
                color = SampleAmberInk,
                maxLines = 1,
                modifier = Modifier
                    .weight(1f, fill = false)
                    .background(SampleAmberTint, CircleShape)
                    .padding(horizontal = 10.dp, vertical = 4.dp),
            )
        }
        Row(
            modifier = Modifier.fillMaxWidth().clearAndSetSemantics { },
            horizontalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            listOf(DS.success, DS.success, DS.success, DS.accent, DS.hairline).forEach { color ->
                Box(Modifier.weight(1f).height(5.dp).background(color, RoundedCornerShape(3.dp)))
            }
        }
        PwText(t("question"), 16.sp, FontWeight.Bold, lineHeight = 22.sp, modifier = Modifier.padding(top = 4.dp))
        val optionShape = RoundedCornerShape(14.dp)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(DS.successTint, optionShape)
                .border(2.dp, DS.success, optionShape)
                .padding(horizontal = 14.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(Modifier.size(22.dp).background(DS.success, CircleShape), contentAlignment = Alignment.Center) {
                Icon(Icons.Filled.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(14.dp))
            }
            PwText(t("option1"), 14.sp, FontWeight.Bold, color = SampleRightInk, modifier = Modifier.weight(1f))
        }
        listOf("option2", "option3").forEach { key ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(DS.surface, optionShape)
                    .border(1.5.dp, DS.hairline, optionShape)
                    .padding(horizontal = 14.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(Modifier.size(22.dp).border(2.dp, SampleRing, CircleShape))
                PwText(t(key), 14.sp, FontWeight.SemiBold, color = DS.inkSecondary, modifier = Modifier.weight(1f))
            }
        }
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Icon(Icons.Outlined.Lightbulb, contentDescription = null, tint = SampleAmberInk, modifier = Modifier.size(18.dp))
            PwText(t("explanation"), 13.sp, FontWeight.Normal, color = SampleBodyInk, lineHeight = 19.sp, modifier = Modifier.weight(1f))
        }
    }
}

// endregion

// region Audio

/**
 * Audio paywall: a free user tapped « Écouter », « Ajouter à la file » or « Télécharger ». It
 * sells listening itself — lock screen, five languages, speed, offline — around a player
 * showing the course they wanted to hear ([courseId]), or a sample course without one.
 */
@Composable
internal fun AudioPaywall(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    courseId: String?,
    onDismiss: () -> Unit,
    onPurchased: () -> Unit,
    legal: ElevateLegalActions,
) {
    val context = LocalContext.current
    ElevatePaywallFrame(
        paywallContext = PaywallContext.AUDIO,
        paywallId = "native_audio",
        language = language,
        storeViewModel = storeViewModel,
        onDismiss = onDismiss,
        onPurchased = onPurchased,
        legal = legal,
    ) { choice ->
        ElevateBeforeAfterHeader(
            before = R.drawable.pw_audio_before,
            after = R.drawable.pw_audio_after,
            beforeLabel = StringStore.text(context, "paywall.elevate.audio.without", language),
        ) {
            ElevateAfterLabel(StringStore.text(context, "paywall.elevate.audio.with", language))
        }
        ElevateTitleBlock(
            title = StringStore.text(context, "paywall.elevate.audio.title", language),
            subtitle = StringStore.text(context, "paywall.audio.subtitle", language),
            modifier = Modifier.dsStagger(0),
        )
        SamplePlayerCard(
            language = language,
            courseId = courseId,
            modifier = Modifier.padding(start = 20.dp, end = 20.dp, top = 24.dp).dsStagger(1),
        )
        Column(
            modifier = Modifier
                .padding(start = 20.dp, end = 20.dp, top = 28.dp)
                .dsStagger(2)
                .fillMaxWidth()
                .sophiaCard()
                .padding(horizontal = 18.dp, vertical = 6.dp),
        ) {
            listOf(
                Icons.Outlined.PhoneAndroid,
                Icons.Outlined.Language,
                Icons.Outlined.Speed,
                Icons.Outlined.FileDownload,
            ).forEachIndexed { index, icon ->
                if (index > 0) HorizontalDivider(color = DS.hairline, thickness = 1.dp)
                ElevateIconRow(
                    icon = icon,
                    title = StringStore.text(context, "paywall.elevate.audio.feature${index + 1}.title", language),
                    body = StringStore.text(context, "paywall.elevate.audio.feature${index + 1}.body", language),
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.padding(vertical = 12.dp),
                )
            }
        }
        ElevateBandedPlans(choice, modifier = Modifier.dsStagger(3))
    }
}

/** The audio player, paused on a picture: an illustration, so none of it is clickable or read as a control. */
@Composable
private fun SamplePlayerCard(language: AppLanguage, courseId: String?, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val sampleTitle = StringStore.text(context, "paywall.sample.audio.title", language)
    // The course they wanted to hear when there is one; the sample course otherwise.
    val wantedTitle by produceState<String?>(initialValue = null, courseId, language) {
        value = if (courseId == null) {
            null
        } else {
            withContext(Dispatchers.IO) {
                runCatching { ContentCatalog.course(context.applicationContext, language, courseId)?.title }.getOrNull()
            }
        }
    }
    val shownCourse = if (courseId != null && wantedTitle != null) courseId else SAMPLE_AUDIO_COURSE
    val title = if (courseId != null && wantedTitle != null) wantedTitle!! else sampleTitle
    Column(
        modifier = modifier.fillMaxWidth().sophiaCard().padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            CourseImage(
                courseId = shownCourse,
                modifier = Modifier.size(64.dp).clip(RoundedCornerShape(14.dp)),
                contentScale = ContentScale.Crop,
                maxEdgePx = 240,
                letterSize = 24.sp,
            )
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                PwText(
                    text = StringStore.text(context, "audio.nowPlaying", language).uppercaseInApp(),
                    size = 12.sp,
                    weight = FontWeight.Bold,
                    color = DS.accent,
                    letterSpacing = 0.5.sp,
                    maxLines = 1,
                )
                PwText(title, 16.sp, FontWeight.Bold, lineHeight = 20.sp, maxLines = 2)
            }
        }
        Column(modifier = Modifier.clearAndSetSemantics { }, verticalArrangement = Arrangement.spacedBy(6.dp)) {
            BoxWithConstraints(modifier = Modifier.fillMaxWidth().height(14.dp)) {
                val played = maxWidth * 0.36f
                Box(
                    Modifier.align(Alignment.CenterStart).fillMaxWidth().height(6.dp).background(SampleTrack, RoundedCornerShape(3.dp)),
                )
                Box(
                    Modifier.align(Alignment.CenterStart).width(played).height(6.dp).background(DS.accent, RoundedCornerShape(3.dp)),
                )
                Box(
                    Modifier.align(Alignment.CenterStart).offset(x = played - 7.dp).size(14.dp).background(DS.accent, CircleShape),
                )
            }
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                PwText(AudioFormat.time(124_000), 12.sp, FontWeight.SemiBold, color = DS.inkSecondary)
                PwText("−" + AudioFormat.time(221_000), 12.sp, FontWeight.SemiBold, color = DS.inkSecondary)
            }
        }
        Row(
            modifier = Modifier.fillMaxWidth().clearAndSetSemantics { },
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            PlayerPill(AudioFormat.speed(1.5f, language))
            Row(horizontalArrangement = Arrangement.spacedBy(18.dp), verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(44.dp), contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.Replay, contentDescription = null, tint = DS.ink, modifier = Modifier.size(26.dp))
                }
                Box(Modifier.size(60.dp).background(DS.accent, CircleShape), contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.Pause, contentDescription = null, tint = Color.White, modifier = Modifier.size(26.dp))
                }
                Box(Modifier.size(44.dp), contentAlignment = Alignment.Center) {
                    // The same arrow, mirrored: « forward ».
                    Icon(
                        Icons.Filled.Replay,
                        contentDescription = null,
                        tint = DS.ink,
                        modifier = Modifier.size(26.dp).scale(scaleX = -1f, scaleY = 1f),
                    )
                }
            }
            PlayerPill(CourseAudioCatalog.preferredLanguage(context, language).shortCode)
        }
    }
}

@Composable
private fun PlayerPill(text: String) {
    PwText(
        text = text,
        size = 13.sp,
        weight = FontWeight.Bold,
        color = DS.accent,
        maxLines = 1,
        modifier = Modifier.background(DS.accentTint, CircleShape).padding(horizontal = 10.dp, vertical = 6.dp),
    )
}

// endregion
