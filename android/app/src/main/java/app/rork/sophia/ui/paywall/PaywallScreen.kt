package app.rork.sophia.ui.paywall

import app.rork.sophia.ui.theme.DSLegacy
import app.rork.sophia.ui.theme.SophiaLegacyTypography
import app.rork.sophia.ui.components.sophiaLegacyCard
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.RestartAlt
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.data.DiscountBucket
import app.rork.sophia.data.PaywallExperiment
import app.rork.sophia.data.analytics.Analytics
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.formatted
import app.rork.sophia.ui.LocalFullBleedBackground
import app.rork.sophia.ui.components.SectionLabel
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.legal.LegalDocKind
import app.rork.sophia.ui.legal.LegalDocumentScreen
import app.rork.sophia.ui.onboarding.AssetPicture
import app.rork.sophia.ui.onboarding.readableWidth
import app.rork.sophia.ui.onboarding.studentPhotos
import app.rork.sophia.ui.theme.ForceLightAppearance
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaAppearance
import app.rork.sophia.ui.theme.SophiaTypography
import com.revenuecat.purchases.Package
import com.revenuecat.purchases.PurchaseParams
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesError
import com.revenuecat.purchases.PurchasesErrorCode
import com.revenuecat.purchases.interfaces.PurchaseCallback
import com.revenuecat.purchases.models.StoreTransaction

/**
 * Paywall contexts. [offeringId] is the **fallback** RevenueCat offering of the context: the price
 * shown and charged comes from the offering RevenueCat currently serves (what experiments
 * swap), so a customer sees one price everywhere — see [StoreViewModel.displayedOffering].
 * The discount context is the exception: its offering is picked by the install's bucket.
 */
enum class PaywallContext(val offeringId: String) {
    FIN_ONBOARDING("fin_onboarding"),
    OFFRE_DISCOUNT("offre_discount"),
    DEBLOQUER_COURS("debloquer_cours"),
    QUIZZ("quizz"),
    ENTRAINEMENT(offeringId = "quizz"),
    /** Audio mode unlock. `audio` is only a fallback offering: the current one sells first. */
    AUDIO("audio"),
}

/**
 * The comparison rows, and whether the free plan has each one. This is the real freemium
 * rule: free readers already have every subject and unlimited favourites; what they do not
 * have is more than one course a day, the quizzes and the audio mode. (iOS adds the app
 * blocker, which Android does not have.)
 */
private val COMPARISON_FEATURES = listOf(
    "allSubjects" to true,
    "favorites" to true,
    "unlimited" to false,
    "quiz" to false,
    "audio" to false,
)

@Composable
fun OnboardingPaywallFlow(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    onDismiss: () -> Unit,
    /** The package that was actually bought, so the caller can tell a trial from a plain sale. */
    onPurchased: (Package?) -> Unit,
) {
    // Designed light-only, as on iOS: the night palette stays off while it is shown.
    ForceLightAppearance()
    var showComparison by remember { mutableStateOf(false) }
    var legalDoc by remember { mutableStateOf<LegalDocKind?>(null) }
    LaunchedEffect(Unit) { storeViewModel.fetchOfferings() }
    val offerings by storeViewModel.offerings.collectAsState()
    val annual = remember(offerings) { storeViewModel.annualPackage(PaywallContext.FIN_ONBOARDING.offeringId) }
    val shortPlan = remember(offerings) { storeViewModel.shortPlanPackage(PaywallContext.FIN_ONBOARDING.offeringId) }
    // A restore carries no package: nothing was just bought, so no trial was just started.
    val restore = rememberRestoreAction(language, storeViewModel) { onPurchased(null) }

    val legalActions = ElevateLegalActions(
        onRestore = restore,
        onTerms = { legalDoc = LegalDocKind.Terms },
        onPrivacy = { legalDoc = LegalDocKind.Privacy },
    )

    PaywallLegalOverlay(doc = legalDoc, language = language, onBack = { legalDoc = null }) {
        if (!showComparison) {
            OnboardingAnnualPaywall(
                language = language,
                annual = annual,
                storeViewModel = storeViewModel,
                onViewAllPlans = {
                    showComparison = true
                },
                onDismiss = onDismiss,
                onPurchased = {
                    onPurchased(annual)
                },
                legalActions = legalActions,
            )
        } else {
            ComparisonPaywall(
                language = language,
                annual = annual,
                shortPlan = shortPlan,
                offeringId = PaywallContext.FIN_ONBOARDING.offeringId,
                storeViewModel = storeViewModel,
                onDismiss = onDismiss,
                onPurchased = { pkg ->
                    onPurchased(pkg)
                },
                legalActions = legalActions,
            )
        }
    }
}

@Composable
fun PaywallScreen(
    context: PaywallContext,
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    onDismiss: () -> Unit,
    onPurchased: () -> Unit,
    onRestored: () -> Unit = onPurchased,
    /** The course a free user wanted to hear, for the audio paywall's cover. */
    courseId: String? = null,
    /** Forces a variant of the course paywall (developer previews); null draws it from the A/B test. */
    forcedCourseVariant: PaywallExperiment.Variant? = null,
    /** Same for the discount paywall. */
    forcedDiscountVariant: PaywallExperiment.DiscountVariant? = null,
) {
    // Designed light-only, as on iOS: the night palette stays off while it is shown.
    ForceLightAppearance()
    var legalDoc by remember { mutableStateOf<LegalDocKind?>(null) }
    // iOS stacks a plan-comparison paywall when the first offer is dismissed, rather than
    // letting the user out on the first tap.
    var secondChance by remember(context) { mutableStateOf(false) }
    val restore = rememberRestoreAction(language, storeViewModel) { onRestored() }
    val legalFooter: @Composable () -> Unit = {
        PaywallLegalRow(
            language = language,
            onRestore = restore,
            onTerms = { legalDoc = LegalDocKind.Terms },
            onPrivacy = { legalDoc = LegalDocKind.Privacy },
        )
    }
    val legalActions = ElevateLegalActions(
        onRestore = restore,
        onTerms = { legalDoc = LegalDocKind.Terms },
        onPrivacy = { legalDoc = LegalDocKind.Privacy },
    )
    // Drawn once per presentation: a setting that arrives meanwhile must not swap the screen.
    val courseVariant = remember { forcedCourseVariant ?: PaywallExperiment.courseVariant() }
    val discountVariant = remember { forcedDiscountVariant ?: PaywallExperiment.discountVariant() }
    // The course paywall's variant follows the reader to the second-chance screen and its purchase.
    val experimentProps = if (context == PaywallContext.DEBLOQUER_COURS) {
        PaywallExperiment.analyticsProps(courseVariant)
    } else {
        emptyMap()
    }
    val offersSecondChance = context == PaywallContext.QUIZZ ||
        context == PaywallContext.DEBLOQUER_COURS ||
        context == PaywallContext.ENTRAINEMENT

    val dismiss: () -> Unit = {
        if (offersSecondChance) secondChance = true else onDismiss()
    }

    PaywallLegalOverlay(doc = legalDoc, language = language, onBack = { legalDoc = null }) {
        if (secondChance) {
            val offerings by storeViewModel.offerings.collectAsState()
            val annual = remember(offerings, context) { storeViewModel.annualPackage(context.offeringId) }
            val shortPlan = remember(offerings, context) { storeViewModel.shortPlanPackage(context.offeringId) }
            ComparisonPaywall(
                language = language,
                annual = annual,
                shortPlan = shortPlan,
                offeringId = context.offeringId,
                storeViewModel = storeViewModel,
                onDismiss = onDismiss,
                onPurchased = { _ ->
                    onPurchased()
                },
                legalActions = legalActions,
                analyticsProps = experimentProps,
            )
            return@PaywallLegalOverlay
        }

        when (context) {
            PaywallContext.FIN_ONBOARDING -> OnboardingPaywallFlow(
                language = language,
                storeViewModel = storeViewModel,
                onDismiss = onDismiss,
                onPurchased = { onPurchased() },
            )
            PaywallContext.OFFRE_DISCOUNT -> DiscountPaywall(
                variant = discountVariant,
                language = language,
                storeViewModel = storeViewModel,
                onDismiss = onDismiss,
                onPurchased = onPurchased,
                onRestore = restore,
                onOpenTerms = { legalDoc = LegalDocKind.Terms },
                onOpenPrivacy = { legalDoc = LegalDocKind.Privacy },
            )
            PaywallContext.QUIZZ -> QuizPaywall(
                language = language,
                storeViewModel = storeViewModel,
                onDismiss = dismiss,
                onPurchased = onPurchased,
                legal = legalActions,
            )
            PaywallContext.ENTRAINEMENT -> TrainingPaywall(
                language = language,
                storeViewModel = storeViewModel,
                onDismiss = dismiss,
                onPurchased = onPurchased,
                legalFooter = legalFooter,
            )
            PaywallContext.DEBLOQUER_COURS -> CourseUnlockPaywall(
                language = language,
                storeViewModel = storeViewModel,
                variant = courseVariant,
                onDismiss = dismiss,
                onPurchased = onPurchased,
                legal = legalActions,
            )
            PaywallContext.AUDIO -> AudioPaywall(
                language = language,
                storeViewModel = storeViewModel,
                courseId = courseId,
                onDismiss = dismiss,
                onPurchased = onPurchased,
                legal = legalActions,
            )
        }
    }
}

/**
 * Keeps the paywall alive underneath while a legal document is open.
 *
 * Swapping the paywall out for [LegalDocumentScreen] tore down its composition: coming back
 * rebuilt it from scratch, which lost the selected plan, the second-chance state and the
 * countdown, and re-ran the `LaunchedEffect(Unit)` that reports a paywall impression — so
 * reading the terms counted as a second view of the paywall. Drawn on top, nothing below
 * moves.
 */
@Composable
private fun PaywallLegalOverlay(
    doc: LegalDocKind?,
    language: AppLanguage,
    onBack: () -> Unit,
    content: @Composable () -> Unit,
) {
    Box(modifier = Modifier.fillMaxSize()) {
        content()
        if (doc != null) {
            // Opaque and clickable so nothing shows through or reacts underneath.
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(DSLegacy.canvas)
                    .softPress(onClick = {}),
            ) {
                LegalDocumentScreen(kind = doc, language = language, onBack = onBack)
            }
        }
    }
}

/**
 * Restore, with something to show for it. The tap used to fire and return in silence — the
 * user could not tell a restored subscription from a dead button. Reports every outcome, and
 * leaves the paywall when the entitlement really did come back.
 */
@Composable
private fun rememberRestoreAction(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    onRestored: () -> Unit,
): () -> Unit {
    val context = LocalContext.current
    return {
        storeViewModel.restore { result ->
            val key = when (result) {
                StoreViewModel.RestoreResult.RESTORED -> "paywall.restore.success"
                StoreViewModel.RestoreResult.NOTHING_FOUND -> "paywall.restore.none"
                StoreViewModel.RestoreResult.FAILED -> "paywall.restore.error"
            }
            Toast.makeText(
                context,
                StringStore.text(context, key, language),
                Toast.LENGTH_LONG,
            ).show()
            if (result == StoreViewModel.RestoreResult.RESTORED) onRestored()
        }
    }
}

@Composable
private fun OnboardingAnnualPaywall(
    language: AppLanguage,
    annual: Package?,
    storeViewModel: StoreViewModel,
    onViewAllPlans: () -> Unit,
    onDismiss: () -> Unit,
    onPurchased: () -> Unit,
    legalActions: ElevateLegalActions,
) {
    val context = LocalContext.current
    var purchasing by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var notice by remember { mutableStateOf<String?>(null) }
    // Worded with the trial, as on iOS (decision of 29/09), as long as the store has not said
    // otherwise: products not loaded yet (slow network, emulator without Play) read « Essaie
    // 3 jours gratuitement… », not « Premium à … ». Unlike iOS, a product Google Play serves
    // without a trial (an account that already had one) states the price: promising days the
    // store will not grant would be a misleading offer.
    val hasTrial = annual == null || storeViewModel.hasFreeTrial(annual)
    val trialDays = storeViewModel.trialDays(annual) ?: 3
    val yearly = storeViewModel.formattedPrice(annual, StoreViewModel.UNKNOWN_PRICE)
    val perMonth = perMonthLabel(context, language, storeViewModel, annual)
    val photos = remember { studentPhotos(context).take(3) }

    LaunchedEffect(Unit) { storeViewModel.trackPaywallImpression("onboarding_annual") }

    Column(
        modifier = Modifier.fillMaxSize().background(DS.canvas),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .readableWidth()
                .padding(start = 20.dp, end = 20.dp, top = 8.dp),
        ) {
            ElevateCloseButton(language = language, onClose = onDismiss)
        }
        PaywallEntry(modifier = Modifier.weight(1f)) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .readableWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 28.dp),
                verticalArrangement = Arrangement.spacedBy(20.dp, Alignment.CenterVertically),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Icon(Icons.Filled.School, contentDescription = null, tint = DS.accent, modifier = Modifier.size(52.dp))
                // « Essaie 3 jours gratuitement, puis 3,33 € / mois (facturé annuellement). »:
                // the free days in bold green, then the monthly equivalent in bold blue.
                val headline = buildAnnotatedString {
                    if (hasTrial) {
                        withStyle(SpanStyle(color = DS.success, fontWeight = FontWeight.Bold)) {
                            append(StringStore.trialText(context, "onboardingV2.pw.tryFree", language, trialDays))
                        }
                        append(" ")
                        appendWithBoldPrice(
                            StringStore.text(context, "onboardingV2.pw.thenPrice", language, perMonth), perMonth,
                        )
                    } else {
                        appendWithBoldPrice(
                            StringStore.text(context, "onboardingV2.pw.priceNoTrial", language, perMonth), perMonth,
                        )
                    }
                }
                Text(
                    text = headline,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Medium,
                    fontSize = 23.sp,
                    lineHeight = 30.sp,
                    letterSpacing = 0.2.sp,
                    color = DS.ink,
                    textAlign = TextAlign.Center,
                )
                AnnualSocialProofRow(language = language, photos = photos)
                PwText(
                    text = StringStore.text(context, "onboardingV2.pw.viewAllPlans", language),
                    size = 15.sp,
                    weight = FontWeight.SemiBold,
                    color = DS.accent,
                    align = TextAlign.Center,
                    modifier = Modifier.pressable(onClick = onViewAllPlans).padding(horizontal = 8.dp, vertical = 12.dp),
                )
                if (error != null) ElevateNote(error!!, error = true)
                if (notice != null) ElevateNote(notice!!, error = false)
            }
        }
        // The button sits as low as it can: the price note is glued under it, then the legal
        // row, with no wasted space between the three.
        Column(
            modifier = Modifier
                .readableWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 6.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            PwText(
                text = StringStore.text(context, "onboardingV2.pw.twoTaps", language),
                size = 13.sp,
                weight = FontWeight.Medium,
                color = DS.inkSecondary,
                align = TextAlign.Center,
                modifier = Modifier.padding(bottom = 10.dp),
            )
            ElevateCtaButton(
                text = if (hasTrial) {
                    StringStore.trialText(context, "onboardingV2.pw.startTrial", language, trialDays)
                } else {
                    StringStore.text(context, "onboardingV2.pw.subscribe", language)
                },
                purchasing = purchasing,
                onClick = {
                    purchasePackage(
                        context = context,
                        language = language,
                        pkg = annual,
                        storeViewModel = storeViewModel,
                        onStart = { purchasing = true },
                        onDone = { purchasing = false },
                        onError = { error = it; notice = null; purchasing = false },
                        onPending = { notice = it; error = null; purchasing = false },
                        onPurchased = onPurchased,
                        paywallId = "onboarding_annual",
                    )
                },
            )
            // What the store actually charges, small and grey, right under the button:
            // « (facturé 39,99 € par an) ».
            if (yearly != StoreViewModel.UNKNOWN_PRICE) {
                PwText(
                    text = "(" + StringStore.text(context, "paywall.plan.billedYearly", language, yearly) + ")",
                    size = 13.sp,
                    weight = FontWeight.Medium,
                    color = DS.inkSecondary,
                    align = TextAlign.Center,
                    modifier = Modifier.padding(top = 8.dp),
                )
            } else {
                Spacer(Modifier.height(10.dp))
            }
            ElevateLegalDots(language = language, actions = legalActions)
        }
    }
}

/** [sentence] with the [price] it carries in bold blue (plain when the price is not found in it). */
private fun AnnotatedString.Builder.appendWithBoldPrice(sentence: String, price: String) {
    val at = if (price.isEmpty() || price == StoreViewModel.UNKNOWN_PRICE) -1 else sentence.indexOf(price)
    if (at < 0) {
        append(sentence)
        return
    }
    append(sentence.substring(0, at))
    withStyle(SpanStyle(color = DS.accent, fontWeight = FontWeight.Bold)) { append(price) }
    append(sentence.substring(at + price.length))
}

/** Discreet social proof under the trial promise: three faces, the rating, the user count. */
@Composable
private fun AnnualSocialProofRow(language: AppLanguage, photos: List<String>) {
    val context = LocalContext.current
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        if (photos.isNotEmpty()) {
            // Overlapping faces ringed in white, without the shadow of the onboarding rows.
            Row(horizontalArrangement = Arrangement.spacedBy((-10).dp)) {
                photos.forEach { url ->
                    AssetPicture(
                        url = url,
                        modifier = Modifier
                            .size(32.dp)
                            .clip(CircleShape)
                            .background(DS.surface)
                            .border(2.dp, DS.surface, CircleShape),
                    )
                }
            }
        }
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            Icon(Icons.Filled.Star, contentDescription = null, tint = DS.warm, modifier = Modifier.size(13.dp))
            PwText(4.8.formatted(language, 1), 13.sp, FontWeight.Bold)
            PwText(
                text = "· " + StringStore.text(context, "onboardingV2.loading.social.count", language),
                size = 13.sp,
                weight = FontWeight.Medium,
                color = DS.inkSecondary,
                maxLines = 1,
            )
        }
    }
}

@Composable
private fun ComparisonPaywall(
    language: AppLanguage,
    annual: Package?,
    /** Monthly today; weekly when the served offering carries a weekly package instead. */
    shortPlan: Package?,
    offeringId: String,
    storeViewModel: StoreViewModel,
    onDismiss: () -> Unit,
    /** The package the user picked and bought — annual or the short plan. */
    onPurchased: (Package?) -> Unit,
    legalActions: ElevateLegalActions,
    /** The A/B variant of the course paywall this screen is the second chance of, if any. */
    analyticsProps: Map<String, Any?> = emptyMap(),
) {
    val context = LocalContext.current
    var yearlySelected by remember { mutableStateOf(true) }
    var purchasing by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var notice by remember { mutableStateOf<String?>(null) }
    val annualPrice = storeViewModel.formattedPrice(annual, StoreViewModel.UNKNOWN_PRICE)
    val shortPlanPrice = storeViewModel.formattedPrice(shortPlan, StoreViewModel.UNKNOWN_PRICE)
    // The short plan is monthly unless the served offering carries a weekly package; the
    // annual card then reads per week too, so both cards share one unit.
    val shortIsWeekly = storeViewModel.isWeekly(shortPlan)
    val perPeriod = if (shortIsWeekly) {
        perWeekLabel(context, language, storeViewModel, annual)
    } else {
        perMonthLabel(context, language, storeViewModel, annual)
    }
    val yearlyHasTrial = storeViewModel.hasFreeTrial(annual)
    val shortHasTrial = storeViewModel.hasFreeTrial(shortPlan)
    val yearlyChosen = yearlySelected || (shortPlan == null && annual != null)
    val selectedHasTrial = if (yearlyChosen) yearlyHasTrial else shortHasTrial
    val yearlyTrialBadge = StringStore.trialText(
        context, "onboardingV2.pw.trialBadge", language, storeViewModel.trialDays(annual) ?: 3,
    )
    val shortTrialBadge = StringStore.trialText(
        context, "onboardingV2.pw.trialBadge", language, storeViewModel.trialDays(shortPlan) ?: 3,
    )

    LaunchedEffect(offeringId) {
        storeViewModel.fetchOfferings()
        storeViewModel.trackPaywallImpression("paywall_comparison", offeringId, analyticsProps)
    }

    Column(
        modifier = Modifier.fillMaxSize().background(DS.canvas),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .readableWidth()
                .padding(start = 20.dp, end = 20.dp, top = 8.dp),
        ) {
            ElevateCloseButton(language = language, onClose = onDismiss)
        }
        Column(
            modifier = Modifier
                .weight(1f)
                .readableWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp)
                .padding(top = 4.dp),
        ) {
            ElevatePaywallTitle(
                text = StringStore.text(context, "onboardingV2.pw.compare.title", language),
                lineHeight = 33.sp,
                textAlign = TextAlign.Start,
                modifier = Modifier.fillMaxWidth().dsStagger(0),
            )
            Spacer(Modifier.height(20.dp))
            ElevateComparisonTable(
                features = COMPARISON_FEATURES.map { (key, free) ->
                    ComparisonFeature(StringStore.text(context, "onboardingV2.pw.feature.$key", language), free)
                },
                freeLabel = StringStore.text(context, "onboardingV2.pw.free", language),
                proLabel = StringStore.text(context, "onboardingV2.pw.pro", language),
                modifier = Modifier.dsStagger(1),
            )
            // Room between the table and the choice of plans.
            Spacer(Modifier.height(30.dp))
        }
        Column(
            modifier = Modifier
                .readableWidth()
                .padding(horizontal = 24.dp)
                .padding(top = 6.dp, bottom = 6.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            // Le gros prix est dans l'unité du plan court des deux côtés (par mois, ou par
            // semaine face à un plan hebdo) : comparer un plan annuel à un plan court demande
            // la même unité, sinon « 39,99 € » à côté de « 9,99 € » fait passer l'annuel pour
            // le plus cher. Le montant réellement prélevé reste juste sous le nom du plan —
            // Google Play l'exige, et c'est honnête pour un abonnement facturé une fois par an.
            ElevatePlanCard(
                style = ElevatePlanStyle.Plain,
                name = StringStore.text(context, "onboardingV2.pw.yearly", language),
                subtitle = StringStore.text(context, "paywall.plan.billedYearly", language, annualPrice),
                price = perPeriod,
                selected = yearlyChosen,
                onClick = { yearlySelected = true },
                trialBadge = if (yearlyHasTrial) yearlyTrialBadge else null,
                badge = storeViewModel.discountBadge(annual, shortPlan, if (shortIsWeekly) 52 else 12)?.let {
                    StringStore.text(context, "onboardingV2.pw.save", language, it.removePrefix("-"))
                },
            )
            // An offering loaded without a short plan shows the annual card alone.
            if (shortPlan != null || annual == null) ElevatePlanCard(
                style = ElevatePlanStyle.Plain,
                name = StringStore.text(
                    context,
                    if (shortIsWeekly) "onboardingV2.pw.weekly" else "onboardingV2.pw.monthly",
                    language,
                ),
                subtitle = StringStore.text(
                    context,
                    if (shortIsWeekly) "onboardingV2.pw.weeklyBilling" else "onboardingV2.pw.monthlyBilling",
                    language,
                ),
                // « 9,99 € / mois » (or « / semaine »): the same unit as the annual card.
                price = if (shortPlan == null) {
                    shortPlanPrice
                } else {
                    shortPlanPrice + " " + StringStore.text(
                        context,
                        if (shortIsWeekly) "paywall.plan.perWeek" else "paywall.plan.perMonth",
                        language,
                    )
                },
                selected = !yearlyChosen,
                onClick = { yearlySelected = false },
                trialBadge = if (shortHasTrial) shortTrialBadge else null,
            )
            if (error != null) ElevateNote(error!!, error = true)
            if (notice != null) ElevateNote(notice!!, error = false)
            ElevateCtaButton(
                text = if (selectedHasTrial) {
                    StringStore.trialText(
                        context, "onboardingV2.pw.startTrial", language,
                        storeViewModel.trialDays(if (yearlyChosen) annual else shortPlan) ?: 3,
                    )
                } else {
                    StringStore.text(context, "onboardingV2.pw.subscribe", language)
                },
                purchasing = purchasing,
                onClick = {
                    val pkg = if (yearlyChosen) annual else shortPlan
                    purchasePackage(
                        context = context,
                        language = language,
                        pkg = pkg,
                        storeViewModel = storeViewModel,
                        onStart = { purchasing = true },
                        onDone = { purchasing = false },
                        onError = { error = it; notice = null; purchasing = false },
                        onPending = { notice = it; error = null; purchasing = false },
                        onPurchased = { onPurchased(pkg) },
                        paywallId = "paywall_comparison",
                        analyticsProps = analyticsProps,
                    )
                },
            )
            ElevateLegalDots(language = language, actions = legalActions)
        }
    }
}

@Composable
private fun TrainingPaywall(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    onDismiss: () -> Unit,
    onPurchased: () -> Unit,
    legalFooter: @Composable () -> Unit,
) {
    val context = LocalContext.current
    LaunchedEffect(Unit) {
        storeViewModel.fetchOfferings()
        storeViewModel.trackPaywallImpression("native_training", PaywallContext.ENTRAINEMENT.offeringId)
    }
    val offerings by storeViewModel.offerings.collectAsState()
    val annual = remember(offerings) {
        storeViewModel.annualPackage(PaywallContext.ENTRAINEMENT.offeringId)
    }
    val hasTrial = storeViewModel.hasFreeTrial(annual)
    val trialDays = storeViewModel.trialDays(annual) ?: 3
    val yearly = storeViewModel.formattedPrice(annual, StoreViewModel.UNKNOWN_PRICE)
    var purchasing by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var notice by remember { mutableStateOf<String?>(null) }

    PaywallShell(
        language = language,
        onDismiss = onDismiss,
        priceLine = priceLineText(context, language, hasTrial, trialDays, yearly),
        ctaText = StringStore.text(
            context,
            if (hasTrial) "paywall.cta.activateTrial" else "paywall.cta.subscribe",
            language,
        ),
        ctaIcon = Icons.Filled.AutoAwesome,
        purchasing = purchasing,
        error = error,
        notice = notice,
        legalFooter = legalFooter,
        onPurchase = {
            purchasePackage(
                context = context,
                language = language,
                pkg = annual,
                storeViewModel = storeViewModel,
                onStart = { purchasing = true },
                onDone = { purchasing = false },
                onError = { error = it; notice = null; purchasing = false },
                onPending = { notice = it; error = null; purchasing = false },
                onPurchased = {
                    onPurchased()
                },
                paywallId = "native_training",
            )
        },
    ) {
        PaywallHero(icon = Icons.Filled.RestartAlt)
        Spacer(Modifier.height(18.dp))
        Text(
            text = StringStore.text(context, "paywall.training.title", language),
            style = SophiaLegacyTypography.titleLarge.copy(fontSize = 24.sp, lineHeight = 30.sp),
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(8.dp))
        Text(
            text = StringStore.text(context, "paywall.training.subtitle", language),
            style = SophiaLegacyTypography.bodyMedium,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(20.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            PaywallStatCard(
                value = StringStore.text(context, "paywall.training.stat1.value", language),
                label = StringStore.text(context, "paywall.training.stat1.label", language),
                valueColor = DSLegacy.success,
                modifier = Modifier.weight(1f),
            )
            PaywallStatCard(
                value = StringStore.text(context, "paywall.training.stat2.value", language),
                label = StringStore.text(context, "paywall.training.stat2.label", language),
                valueColor = DSLegacy.danger,
                modifier = Modifier.weight(1f),
            )
        }
        Spacer(Modifier.height(16.dp))
        Column(
            modifier = Modifier.fillMaxWidth().sophiaLegacyCard().padding(18.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            SectionLabel(StringStore.text(context, "paywall.training.how.title", language))
            (1..3).forEach { step ->
                NumberedStepRow(
                    number = step,
                    text = StringStore.text(context, "paywall.training.how.step$step", language),
                )
            }
        }
        Spacer(Modifier.height(14.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.Top) {
            Text("✨", fontSize = 13.sp)
            Text(
                text = StringStore.text(context, "paywall.training.footnote", language),
                style = SophiaLegacyTypography.labelMedium.copy(fontSize = 12.sp),
            )
        }
    }
}

/**
 * Shared frame of the contextual paywalls: delayed close, scrolling pitch, then the price
 * line, CTA and legal row pinned at the bottom.
 */
@Composable
private fun PaywallShell(
    language: AppLanguage,
    onDismiss: () -> Unit,
    priceLine: String,
    ctaText: String,
    purchasing: Boolean,
    error: String?,
    legalFooter: @Composable () -> Unit,
    onPurchase: () -> Unit,
    notice: String? = null,
    closeDelayMillis: Int = 0,
    ctaIcon: androidx.compose.ui.graphics.vector.ImageVector? = null,
    content: @Composable () -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxSize().background(DSLegacy.canvas),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .readableWidth()
                .padding(horizontal = DSLegacy.Space.l, vertical = 8.dp),
        ) {
            PaywallCloseButton(onClose = onDismiss, delayMillis = closeDelayMillis)
        }
        PaywallEntry(modifier = Modifier.weight(1f)) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .readableWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Spacer(Modifier.height(4.dp))
                content()
                Spacer(Modifier.height(24.dp))
            }
        }
        Column(
            modifier = Modifier
                .readableWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 12.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            if (error != null) PaywallErrorNote(error)
            // A pending Play payment is good news waiting on a bank, not a failure.
            if (notice != null) PaywallNotice(notice)
            PriceLine(priceLine)
            PurchaseButton(
                text = ctaText,
                purchasing = purchasing,
                leadingIcon = ctaIcon,
                onClick = onPurchase,
            )
            legalFooter()
        }
    }
}

/**
 * The price above the CTA of the feature paywalls: one small grey line, « Essai gratuit de 3
 * jours, puis 39,99 € / an ». The button says what today costs; this says what the store
 * charges once the trial is over.
 */
private fun priceLineText(
    context: android.content.Context,
    language: AppLanguage,
    hasTrial: Boolean,
    trialDays: Int,
    yearly: String,
): String = if (hasTrial) {
    StringStore.trialText(context, "paywall.price.trialThenYearly", language, trialDays, yearly)
} else {
    StringStore.text(context, "paywall.price.yearlyNoTrial", language, yearly)
}

/**
 * The monthly equivalent of an annual plan, with its unit: « 4,00 € / mois ». The bare amount
 * landed in the price line as a naked "(4,00 €)", which reads as a second, cheaper price
 * rather than a per-month breakdown. Falls back to the already-suffixed localised string when
 * RevenueCat has no price to divide.
 */
private fun perMonthLabel(
    context: android.content.Context,
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    annual: Package?,
): String {
    val amount = storeViewModel.formattedYearlyPerMonth(annual, "")
    if (amount.isEmpty()) return StoreViewModel.UNKNOWN_PRICE
    return "$amount ${StringStore.text(context, "paywall.plan.perMonth", language)}"
}

/** The weekly equivalent of an annual plan, with its unit, for the card next to a weekly plan. */
private fun perWeekLabel(
    context: android.content.Context,
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    annual: Package?,
): String {
    val amount = storeViewModel.formattedYearlyPerWeek(annual, "")
    if (amount.isEmpty()) return StoreViewModel.UNKNOWN_PRICE
    return "$amount ${StringStore.text(context, "paywall.plan.perWeek", language)}"
}

/**
 * Runs a Play purchase and reports what actually happened.
 *
 * Two outcomes used to be collapsed into "error, in English". Google Play accepts *pending*
 * transactions — bank transfer, cash at a counter, a parent's approval on a child account —
 * which are common in Poland, Brazil, India and Japan. Those arrive as
 * [PurchasesErrorCode.PaymentPendingError], or as a completed transaction whose entitlement
 * is not active yet, and both mean "paid, waiting for confirmation", not "failed".
 *
 * [onPurchased] therefore only fires once the entitlement is genuinely active, so the paywall
 * never closes on a purchase that has not unlocked anything.
 */
internal fun purchasePackage(
    context: android.content.Context,
    language: AppLanguage,
    pkg: Package?,
    storeViewModel: StoreViewModel,
    onStart: () -> Unit,
    onDone: () -> Unit,
    onError: (String) -> Unit,
    onPurchased: () -> Unit,
    onPending: (String) -> Unit = {},
    /**
     * The paywall the purchase starts from, the same identifier as its `paywall_view`. It rides
     * on the three purchase events (`paywall_id`), so each purchase is tied to its paywall.
     */
    paywallId: String,
    /** Extra properties of the purchase events (the A/B variant of the course paywall). */
    analyticsProps: Map<String, Any?> = emptyMap(),
) {
    @Suppress("NAME_SHADOWING")
    val analyticsProps = analyticsProps + ("paywall_id" to paywallId)
    if (pkg == null) {
        if (!Purchases.isConfigured) {
            // No store keys in this build: unblock the flow locally instead of dead-ending.
            storeViewModel.setPremiumDebug(true)
            onPurchased()
        } else {
            onError(StringStore.text(context, "paywall.unavailable.title", language))
        }
        return
    }
    val activity = context.findActivity() ?: return
    onStart()
    val productId = pkg.product.id
    Analytics.log(
        "purchase_started",
        props = mapOf("product" to productId, "offering" to pkg.presentedOfferingContext.offeringIdentifier) + analyticsProps,
    )
    Purchases.sharedInstance.purchase(
        PurchaseParams.Builder(activity, pkg).build(),
        object : PurchaseCallback {
            override fun onCompleted(
                storeTransaction: StoreTransaction,
                customerInfo: com.revenuecat.purchases.CustomerInfo,
            ) {
                onDone()
                storeViewModel.refresh()
                if (storeViewModel.isEntitlementActive(customerInfo)) {
                    Analytics.log("purchase_completed", props = mapOf("product" to productId) + analyticsProps)
                    onPurchased()
                } else {
                    // Play took the order but has not granted it yet.
                    Analytics.log("purchase_failed", props = mapOf("product" to productId, "reason" to "pending") + analyticsProps)
                    onPending(StringStore.text(context, "purchase.pending", language))
                }
            }

            override fun onError(error: PurchasesError, userCancelled: Boolean) {
                onDone()
                val reason = when {
                    userCancelled -> "cancelled"
                    error.code == PurchasesErrorCode.PaymentPendingError -> "pending"
                    else -> "error"
                }
                Analytics.log("purchase_failed", props = mapOf("product" to productId, "reason" to reason) + analyticsProps)
                if (userCancelled) return
                if (error.code == PurchasesErrorCode.PaymentPendingError) {
                    onPending(StringStore.text(context, "purchase.pending", language))
                } else {
                    onError(localizedPurchaseError(context, language, error))
                }
            }
        },
    )
}

/**
 * RevenueCat messages are English-only and written for developers. Map the codes a user can
 * actually hit to the app's own copy, and keep the raw message as a last resort so a rare
 * failure is still describable in a support thread.
 */
private fun localizedPurchaseError(
    context: android.content.Context,
    language: AppLanguage,
    error: PurchasesError,
): String {
    val key = when (error.code) {
        PurchasesErrorCode.NetworkError -> "paywall.error.network"
        PurchasesErrorCode.StoreProblemError,
        PurchasesErrorCode.ProductNotAvailableForPurchaseError,
        -> "paywall.unavailable.title"
        PurchasesErrorCode.PurchaseNotAllowedError,
        PurchasesErrorCode.PurchaseInvalidError,
        -> "paywall.error.notAllowed"
        else -> null
    } ?: return error.message
    return StringStore.text(context, key, language)
}

private fun android.content.Context.findActivity(): android.app.Activity? {
    var ctx = this
    while (ctx is android.content.ContextWrapper) {
        if (ctx is android.app.Activity) return ctx
        ctx = ctx.baseContext
    }
    return null
}
