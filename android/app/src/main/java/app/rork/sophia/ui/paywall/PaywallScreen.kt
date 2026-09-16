package app.rork.sophia.ui.paywall

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
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
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.LockOpen
import androidx.compose.material.icons.filled.Quiz
import androidx.compose.material.icons.filled.RestartAlt
import androidx.compose.material.icons.filled.School
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.view.WindowCompat
import app.rork.sophia.SophiaApplication
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.components.SectionLabel
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.LocalFullBleedBackground
import app.rork.sophia.ui.legal.LegalDocKind
import app.rork.sophia.ui.legal.LegalDocumentScreen
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import com.revenuecat.purchases.Package
import com.revenuecat.purchases.PurchaseParams
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesError
import com.revenuecat.purchases.PurchasesErrorCode
import com.revenuecat.purchases.interfaces.PurchaseCallback
import com.revenuecat.purchases.models.StoreTransaction
import kotlinx.coroutines.delay

enum class PaywallContext(val offeringId: String, val analyticsContext: String = offeringId) {
    FIN_ONBOARDING("fin_onboarding"),
    OFFRE_DISCOUNT("offre_discount"),
    DEBLOQUER_COURS("debloquer_cours"),
    QUIZZ("quizz"),
    ENTRAINEMENT(offeringId = "quizz", analyticsContext = "entrainement"),
}

private val COMPARISON_FEATURES = listOf(
    "allSubjects", "unlimited", "quiz", "favorites", "noAds", "weekly",
)

@Composable
fun OnboardingPaywallFlow(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    onDismiss: () -> Unit,
    /** The package that was actually bought, so the caller can tell a trial from a plain sale. */
    onPurchased: (Package?) -> Unit,
    onPurchaseMeta: (offeringId: String?, packageId: String?) -> Unit = { _, _ -> },
    onComparisonShown: () -> Unit = {},
) {
    var showComparison by remember { mutableStateOf(false) }
    var legalDoc by remember { mutableStateOf<LegalDocKind?>(null) }
    LaunchedEffect(Unit) { storeViewModel.fetchOfferings() }
    val offerings by storeViewModel.offerings.collectAsState()
    val annual = remember(offerings) { storeViewModel.annualPackage(PaywallContext.FIN_ONBOARDING.offeringId) }
    val monthly = remember(offerings) { storeViewModel.monthlyPackage(PaywallContext.FIN_ONBOARDING.offeringId) }
    // A restore carries no package: nothing was just bought, so no trial was just started.
    val restore = rememberRestoreAction(language, storeViewModel) { onPurchased(null) }

    val legalFooter: @Composable () -> Unit = {
        PaywallLegalRow(
            language = language,
            onRestore = restore,
            onTerms = { legalDoc = LegalDocKind.Terms },
            onPrivacy = { legalDoc = LegalDocKind.Privacy },
        )
    }

    PaywallLegalOverlay(doc = legalDoc, language = language, onBack = { legalDoc = null }) {
        if (!showComparison) {
            OnboardingAnnualPaywall(
                language = language,
                annual = annual,
                storeViewModel = storeViewModel,
                onViewAllPlans = {
                    showComparison = true
                    onComparisonShown()
                },
                onDismiss = onDismiss,
                onPurchased = {
                    onPurchaseMeta(PaywallContext.FIN_ONBOARDING.offeringId, annual?.identifier)
                    onPurchased(annual)
                },
                legalFooter = legalFooter,
            )
        } else {
            ComparisonPaywall(
                language = language,
                annual = annual,
                monthly = monthly,
                offeringId = PaywallContext.FIN_ONBOARDING.offeringId,
                storeViewModel = storeViewModel,
                onDismiss = onDismiss,
                onPurchased = { pkg ->
                    onPurchaseMeta(PaywallContext.FIN_ONBOARDING.offeringId, pkg?.identifier)
                    onPurchased(pkg)
                },
                legalFooter = legalFooter,
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
    onPurchaseMeta: (offeringId: String?, packageId: String?) -> Unit = { _, _ -> },
    onRestored: () -> Unit = onPurchased,
) {
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
            val monthly = remember(offerings, context) { storeViewModel.monthlyPackage(context.offeringId) }
            ComparisonPaywall(
                language = language,
                annual = annual,
                monthly = monthly,
                offeringId = context.offeringId,
                storeViewModel = storeViewModel,
                onDismiss = onDismiss,
                onPurchased = { pkg ->
                    onPurchaseMeta(context.offeringId, pkg?.identifier)
                    onPurchased()
                },
                legalFooter = legalFooter,
            )
            return@PaywallLegalOverlay
        }

        when (context) {
            PaywallContext.FIN_ONBOARDING -> OnboardingPaywallFlow(
                language = language,
                storeViewModel = storeViewModel,
                onDismiss = onDismiss,
                onPurchased = { onPurchased() },
                onPurchaseMeta = onPurchaseMeta,
            )
            PaywallContext.OFFRE_DISCOUNT -> DiscountPaywall(
                language = language,
                storeViewModel = storeViewModel,
                onDismiss = onDismiss,
                onPurchased = onPurchased,
                onPurchaseMeta = onPurchaseMeta,
                onRestore = restore,
                onOpenTerms = { legalDoc = LegalDocKind.Terms },
                onOpenPrivacy = { legalDoc = LegalDocKind.Privacy },
            )
            PaywallContext.QUIZZ -> QuizPaywall(
                language = language,
                storeViewModel = storeViewModel,
                onDismiss = dismiss,
                onPurchased = onPurchased,
                onPurchaseMeta = onPurchaseMeta,
                legalFooter = legalFooter,
            )
            PaywallContext.ENTRAINEMENT -> TrainingPaywall(
                language = language,
                storeViewModel = storeViewModel,
                onDismiss = dismiss,
                onPurchased = onPurchased,
                onPurchaseMeta = onPurchaseMeta,
                legalFooter = legalFooter,
            )
            PaywallContext.DEBLOQUER_COURS -> CourseUnlockPaywall(
                language = language,
                storeViewModel = storeViewModel,
                onDismiss = dismiss,
                onPurchased = onPurchased,
                onPurchaseMeta = onPurchaseMeta,
                legalFooter = legalFooter,
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
                    .background(DS.canvas)
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
    legalFooter: @Composable () -> Unit,
) {
    val context = LocalContext.current
    var purchasing by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var notice by remember { mutableStateOf<String?>(null) }
    val hasTrial = storeViewModel.hasFreeTrial(annual)
    val yearly = storeViewModel.formattedPrice(
        annual,
        StringStore.text(context, "paywall.plan.fallback.yearlyPrice", language),
    )
    val perMonth = perMonthLabel(context, language, storeViewModel, annual)

    LaunchedEffect(Unit) { storeViewModel.trackPaywallImpression("onboarding_annual") }

    Column(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
        Row(modifier = Modifier.fillMaxWidth().padding(horizontal = DS.Space.l, vertical = 8.dp)) {
            PaywallCloseButton(onClose = onDismiss)
        }
        PaywallEntry(modifier = Modifier.weight(1f)) {
            Column(
                modifier = Modifier.fillMaxSize().padding(horizontal = 28.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                PaywallHero(icon = Icons.Filled.School)
                Spacer(Modifier.height(20.dp))
                if (hasTrial) {
                    Text(
                        text = StringStore.text(context, "onboardingV2.pw.tryFree", language),
                        style = SophiaTypography.titleLarge.copy(fontSize = 22.sp, color = DS.success),
                        textAlign = TextAlign.Center,
                    )
                    Spacer(Modifier.height(6.dp))
                    Text(
                        text = StringStore.text(context, "onboardingV2.pw.thenPrice", language, perMonth, yearly),
                        style = SophiaTypography.titleLarge.copy(fontSize = 22.sp),
                        textAlign = TextAlign.Center,
                    )
                } else {
                    Text(
                        text = StringStore.text(context, "onboardingV2.pw.priceNoTrial", language, perMonth, yearly),
                        style = SophiaTypography.titleLarge.copy(fontSize = 22.sp),
                        textAlign = TextAlign.Center,
                    )
                }
                Spacer(Modifier.height(20.dp))
                Text(
                    text = StringStore.text(context, "onboardingV2.pw.viewAllPlans", language),
                    style = SophiaTypography.labelLarge.copy(fontSize = 15.sp, color = DS.accentSoft),
                    modifier = Modifier.softPress(onClick = onViewAllPlans).padding(8.dp),
                )
                if (error != null) {
                    Spacer(Modifier.height(16.dp))
                    PaywallErrorNote(error!!)
                }
                if (notice != null) {
                    Spacer(Modifier.height(12.dp))
                    PaywallNotice(notice!!)
                }
            }
        }
        Column(
            modifier = Modifier.padding(horizontal = 24.dp).padding(bottom = 12.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = StringStore.text(context, "onboardingV2.pw.twoTaps", language),
                style = SophiaTypography.labelMedium.copy(fontSize = 12.sp),
                textAlign = TextAlign.Center,
            )
            PurchaseButton(
                text = StringStore.text(
                    context,
                    if (hasTrial) "onboardingV2.pw.startTrial" else "onboardingV2.pw.subscribe",
                    language,
                ),
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
                    )
                },
            )
            legalFooter()
        }
    }
}

@Composable
private fun ComparisonPaywall(
    language: AppLanguage,
    annual: Package?,
    monthly: Package?,
    offeringId: String,
    storeViewModel: StoreViewModel,
    onDismiss: () -> Unit,
    /** The package the user picked and bought — annual or monthly. */
    onPurchased: (Package?) -> Unit,
    legalFooter: @Composable () -> Unit,
) {
    val context = LocalContext.current
    var yearlySelected by remember { mutableStateOf(true) }
    var purchasing by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var notice by remember { mutableStateOf<String?>(null) }
    val annualPrice = storeViewModel.formattedPrice(
        annual,
        StringStore.text(context, "paywall.plan.fallback.yearlyPrice", language),
    )
    val monthlyPrice = storeViewModel.formattedPrice(
        monthly,
        StringStore.text(context, "paywall.plan.fallback.monthlyPrice", language),
    )
    val perMonth = perMonthLabel(context, language, storeViewModel, annual)
    val yearlyHasTrial = storeViewModel.hasFreeTrial(annual)
    val monthlyHasTrial = storeViewModel.hasFreeTrial(monthly)
    val selectedHasTrial = if (yearlySelected) yearlyHasTrial else monthlyHasTrial
    val trialBadge = StringStore.text(context, "onboardingV2.pw.trialBadge", language)

    LaunchedEffect(offeringId) {
        storeViewModel.fetchOfferings()
        storeViewModel.trackPaywallImpression("paywall_comparison", offeringId)
    }

    Column(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
        Row(modifier = Modifier.fillMaxWidth().padding(horizontal = DS.Space.l, vertical = 8.dp)) {
            PaywallCloseButton(onClose = onDismiss)
        }
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp),
        ) {
            Text(
                text = StringStore.text(context, "onboardingV2.pw.compare.title", language),
                style = SophiaTypography.titleLarge.copy(fontSize = 26.sp, lineHeight = 32.sp),
            )
            Spacer(Modifier.height(20.dp))
            ComparisonTable(
                features = COMPARISON_FEATURES.map {
                    StringStore.text(context, "onboardingV2.pw.feature.$it", language)
                },
                freeLabel = StringStore.text(context, "onboardingV2.pw.free", language),
                proLabel = StringStore.text(context, "onboardingV2.pw.pro", language),
            )
            Spacer(Modifier.height(12.dp))
        }
        Column(
            modifier = Modifier.padding(horizontal = 24.dp).padding(bottom = 12.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            PlanSelectorCard(
                name = StringStore.text(context, "onboardingV2.pw.yearly", language),
                subtitle = perMonth,
                price = annualPrice,
                selected = yearlySelected,
                onClick = { yearlySelected = true },
                trialBadge = if (yearlyHasTrial) trialBadge else null,
                saveBadge = storeViewModel.discountBadge(annual, monthly)?.let {
                    StringStore.text(context, "onboardingV2.pw.save", language, it)
                },
            )
            PlanSelectorCard(
                name = StringStore.text(context, "onboardingV2.pw.monthly", language),
                subtitle = StringStore.text(context, "onboardingV2.pw.monthlyBilling", language),
                price = monthlyPrice,
                selected = !yearlySelected,
                onClick = { yearlySelected = false },
                trialBadge = if (monthlyHasTrial) trialBadge else null,
            )
            if (error != null) PaywallErrorNote(error!!)
            if (notice != null) PaywallNotice(notice!!)
            PurchaseButton(
                text = StringStore.text(
                    context,
                    if (selectedHasTrial) "onboardingV2.pw.startTrial" else "onboardingV2.pw.subscribe",
                    language,
                ),
                purchasing = purchasing,
                onClick = {
                    val pkg = if (yearlySelected) annual else monthly
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
                    )
                },
            )
            legalFooter()
        }
    }
}

/** Free daily course already used: cover, rating, countdown to the next free course. */
@Composable
private fun CourseUnlockPaywall(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    onDismiss: () -> Unit,
    onPurchased: () -> Unit,
    onPurchaseMeta: (offeringId: String?, packageId: String?) -> Unit,
    legalFooter: @Composable () -> Unit,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    LaunchedEffect(Unit) {
        storeViewModel.fetchOfferings()
        storeViewModel.trackPaywallImpression("native_course_unlock", PaywallContext.DEBLOQUER_COURS.offeringId)
    }
    val offerings by storeViewModel.offerings.collectAsState()
    val annual = remember(offerings) {
        storeViewModel.annualPackage(PaywallContext.DEBLOQUER_COURS.offeringId)
    }
    val hasTrial = storeViewModel.hasFreeTrial(annual)
    val yearly = storeViewModel.formattedPrice(
        annual,
        StringStore.text(context, "paywall.plan.fallback.yearlyPrice", language),
    )
    val perMonth = perMonthLabel(context, language, storeViewModel, annual)
    val dailyCourseId = app.progressManager.progress.value.dailyFreeCourseId
    val secondsToReset = remember { app.progressManager.secondsUntilDailyReset() }
    var purchasing by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var notice by remember { mutableStateOf<String?>(null) }

    PaywallShell(
        language = language,
        onDismiss = onDismiss,
        closeDelayMillis = 2000,
        priceLine = priceLineText(context, language, hasTrial, yearly, perMonth),
        ctaText = StringStore.text(
            context,
            if (hasTrial) "paywall.cta.unlockFree" else "paywall.cta.subscribe",
            language,
        ),
        ctaIcon = if (hasTrial) Icons.Filled.LockOpen else Icons.Filled.AutoAwesome,
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
                    onPurchaseMeta(PaywallContext.DEBLOQUER_COURS.offeringId, annual?.identifier)
                    onPurchased()
                },
            )
        },
    ) {
        if (dailyCourseId != null) {
            PaywallCourseHero(courseId = dailyCourseId)
        } else {
            PaywallHero(icon = Icons.AutoMirrored.Filled.MenuBook)
        }
        Spacer(Modifier.height(14.dp))
        RatingLine(StringStore.text(context, "paywall.rating", language))
        Spacer(Modifier.height(14.dp))
        Text(
            text = StringStore.text(context, "paywall.course.title", language),
            style = SophiaTypography.titleLarge.copy(fontSize = 24.sp, lineHeight = 30.sp),
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(8.dp))
        Text(
            text = StringStore.text(context, "paywall.course.subtitle", language),
            style = SophiaTypography.bodyMedium,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(18.dp))
        CountdownCard(
            label = StringStore.text(context, "paywall.course.comeBack", language),
            secondsRemaining = secondsToReset,
        )
        Spacer(Modifier.height(16.dp))
        Row(
            modifier = Modifier.fillMaxWidth().sophiaCard(fill = DS.accentTint).padding(18.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = StringStore.text(context, "paywall.course.stat.value", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 34.sp,
                    color = DS.accent,
                )
                Text(
                    text = StringStore.text(context, "paywall.course.stat.label", language),
                    style = SophiaTypography.labelMedium.copy(fontSize = 11.sp, color = DS.accentSoft),
                )
            }
            Box(modifier = Modifier.size(width = 1.dp, height = 44.dp).background(DS.hairline))
            Text(
                text = StringStore.text(context, "paywall.course.stat.caption", language),
                style = SophiaTypography.bodyMedium.copy(fontSize = 14.sp),
            )
        }
        Spacer(Modifier.height(18.dp))
        ReviewsCarousel(
            reviews = (1..3).map { i ->
                StringStore.text(context, "paywall.reviews.r$i.quote", language) to
                    StringStore.text(context, "paywall.reviews.r$i.author", language)
            },
        )
    }
}

@Composable
private fun TrainingPaywall(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    onDismiss: () -> Unit,
    onPurchased: () -> Unit,
    onPurchaseMeta: (offeringId: String?, packageId: String?) -> Unit,
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
    val yearly = storeViewModel.formattedPrice(
        annual,
        StringStore.text(context, "paywall.plan.fallback.yearlyPrice", language),
    )
    val perMonth = perMonthLabel(context, language, storeViewModel, annual)
    var purchasing by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var notice by remember { mutableStateOf<String?>(null) }

    PaywallShell(
        language = language,
        onDismiss = onDismiss,
        priceLine = priceLineText(context, language, hasTrial, yearly, perMonth),
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
                    onPurchaseMeta(PaywallContext.ENTRAINEMENT.offeringId, annual?.identifier)
                    onPurchased()
                },
            )
        },
    ) {
        PaywallHero(icon = Icons.Filled.RestartAlt)
        Spacer(Modifier.height(18.dp))
        Text(
            text = StringStore.text(context, "paywall.training.title", language),
            style = SophiaTypography.titleLarge.copy(fontSize = 24.sp, lineHeight = 30.sp),
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(8.dp))
        Text(
            text = StringStore.text(context, "paywall.training.subtitle", language),
            style = SophiaTypography.bodyMedium,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(20.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            PaywallStatCard(
                value = StringStore.text(context, "paywall.training.stat1.value", language),
                label = StringStore.text(context, "paywall.training.stat1.label", language),
                valueColor = DS.success,
                modifier = Modifier.weight(1f),
            )
            PaywallStatCard(
                value = StringStore.text(context, "paywall.training.stat2.value", language),
                label = StringStore.text(context, "paywall.training.stat2.label", language),
                valueColor = DS.danger,
                modifier = Modifier.weight(1f),
            )
        }
        Spacer(Modifier.height(16.dp))
        Column(
            modifier = Modifier.fillMaxWidth().sophiaCard().padding(18.dp),
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
                style = SophiaTypography.labelMedium.copy(fontSize = 12.sp),
            )
        }
    }
}

/** Quiz paywall: an auto-playing demo of the question types, then the FAQ. */
@Composable
private fun QuizPaywall(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    onDismiss: () -> Unit,
    onPurchased: () -> Unit,
    onPurchaseMeta: (offeringId: String?, packageId: String?) -> Unit,
    legalFooter: @Composable () -> Unit,
) {
    val context = LocalContext.current
    LaunchedEffect(Unit) {
        storeViewModel.fetchOfferings()
        storeViewModel.trackPaywallImpression("native_quiz", PaywallContext.QUIZZ.offeringId)
    }
    val offerings by storeViewModel.offerings.collectAsState()
    val annual = remember(offerings) { storeViewModel.annualPackage(PaywallContext.QUIZZ.offeringId) }
    val hasTrial = storeViewModel.hasFreeTrial(annual)
    val yearly = storeViewModel.formattedPrice(
        annual,
        StringStore.text(context, "paywall.plan.fallback.yearlyPrice", language),
    )
    val perMonth = perMonthLabel(context, language, storeViewModel, annual)
    var purchasing by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var notice by remember { mutableStateOf<String?>(null) }
    var expandedFaq by remember { mutableStateOf<Int?>(null) }
    // The answers are shared with iOS and talk about the App Store. On Android the only
    // place a subscription can be cancelled is Google Play, so cancellation answers use the
    // `.play` variants; the trial answer (a3) names no store and is reused as is.
    val faq = listOf(
        "paywall.quiz.faq.q1" to "paywall.quiz.faq.a1.play",
        "paywall.quiz.faq.q2" to "paywall.quiz.faq.a2",
        (if (hasTrial) "paywall.quiz.faq.q3" else "paywall.quiz.faq.q3.noTrial") to
            (if (hasTrial) "paywall.quiz.faq.a3" else "paywall.quiz.faq.a3.noTrial.play"),
    )

    PaywallShell(
        language = language,
        onDismiss = onDismiss,
        closeDelayMillis = 4000,
        priceLine = priceLineText(context, language, hasTrial, yearly, perMonth),
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
                    onPurchaseMeta(PaywallContext.QUIZZ.offeringId, annual?.identifier)
                    onPurchased()
                },
            )
        },
    ) {
        PaywallHero(icon = Icons.Filled.Quiz)
        Spacer(Modifier.height(18.dp))
        Text(
            text = StringStore.text(context, "paywall.quiz.title", language),
            style = SophiaTypography.titleLarge.copy(fontSize = 24.sp, lineHeight = 30.sp),
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(8.dp))
        Text(
            text = StringStore.text(context, "paywall.quiz.subtitle", language),
            style = SophiaTypography.bodyMedium,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(20.dp))
        QuizShowcase(language = language)
        Spacer(Modifier.height(20.dp))
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            faq.forEachIndexed { index, (qKey, aKey) ->
                FaqItem(
                    question = StringStore.text(context, qKey, language),
                    answer = StringStore.text(context, aKey, language),
                    expanded = expandedFaq == index,
                    onToggle = { expandedFaq = if (expandedFaq == index) null else index },
                )
            }
        }
        Spacer(Modifier.height(12.dp))
        // Play's own subscription centre, deep-linked to Sophia. Saying where to cancel and
        // then making them find it is half an answer.
        Text(
            text = StringStore.text(context, "paywall.manageSubscription", language),
            style = SophiaTypography.labelMedium.copy(fontSize = 12.sp, color = DS.accentSoft),
            modifier = Modifier
                .softPress(onClick = { openPlaySubscriptions(context, annual?.product?.id) })
                .padding(horizontal = 8.dp, vertical = 6.dp),
        )
        Spacer(Modifier.height(12.dp))
        RatingLine(StringStore.text(context, "paywall.quiz.rating", language))
    }
}

/**
 * Opens Google Play on the Sophia subscription, falling back to the subscription list and
 * then to the Play listing in the browser — a phone with the Play app removed still has to
 * land somewhere real.
 *
 * [productId] is the store product RevenueCat actually served, never a hardcoded sku: the
 * deep link only lands on the right subscription when the id matches what Play sold, and a
 * guess would silently drop the user on an empty page. When offerings have not loaded yet it
 * is null, and the plain subscription list is the honest destination.
 */
private fun openPlaySubscriptions(context: android.content.Context, productId: String?) {
    val packageName = context.packageName
    // RevenueCat reports a subscription product as "product:base_plan"; Play wants the
    // product alone.
    val sku = productId?.substringBefore(':')?.takeIf { it.isNotBlank() }
    val targets = listOfNotNull(
        sku?.let { "https://play.google.com/store/account/subscriptions?sku=$it&package=$packageName" },
        "https://play.google.com/store/account/subscriptions",
        "https://play.google.com/store/apps/details?id=$packageName",
    )
    for (url in targets) {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (runCatching { context.startActivity(intent) }.isSuccess) return
    }
}

/** Cycles through the question types with the answer revealing itself, like the iOS demo. */
@Composable
private fun QuizShowcase(language: AppLanguage) {
    val context = LocalContext.current
    var step by remember { mutableIntStateOf(0) }
    var revealed by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        while (true) {
            revealed = false
            delay(1350)
            revealed = true
            delay(2600)
            step = (step + 1) % 2
            delay(600)
        }
    }
    Column(
        modifier = Modifier.fillMaxWidth().sophiaCard().padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = StringStore.text(
                    context,
                    if (step == 0) "paywall.quiz.demo.badge.mcq" else "paywall.quiz.demo.badge.trueFalse",
                    language,
                ),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 11.sp,
                letterSpacing = 0.5.sp,
                color = DS.accentSoft,
                modifier = Modifier
                    .clip(CircleShape)
                    .background(DS.accentTint)
                    .padding(horizontal = 10.dp, vertical = 5.dp),
            )
            Spacer(Modifier.weight(1f))
            Text("✨", fontSize = 13.sp)
        }
        Text(
            text = StringStore.text(context, "paywall.quiz.demo.title", language),
            style = SophiaTypography.labelMedium.copy(fontSize = 12.sp, fontWeight = FontWeight.SemiBold),
        )
        AnimatedContent(
            targetState = step,
            transitionSpec = { fadeIn(tween(320)) togetherWith fadeOut(tween(220)) },
            label = "quizDemo",
        ) { current ->
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(
                    text = StringStore.text(
                        context,
                        if (current == 0) "paywall.quiz.demo.mcq.q" else "paywall.quiz.demo.tf.q",
                        language,
                    ),
                    style = SophiaTypography.titleMedium.copy(fontSize = 16.sp),
                )
                val options = if (current == 0) {
                    listOf("paywall.quiz.demo.mcq.o1", "paywall.quiz.demo.mcq.o2", "paywall.quiz.demo.mcq.o3")
                } else {
                    listOf("paywall.quiz.demo.tf.true", "paywall.quiz.demo.tf.false")
                }
                options.forEachIndexed { i, key ->
                    val correct = revealed && i == if (current == 0) 0 else 1
                    Text(
                        text = StringStore.text(context, key, language),
                        style = SophiaTypography.bodyMedium.copy(
                            color = if (correct) DS.success else DS.ink,
                            fontWeight = if (correct) FontWeight.SemiBold else FontWeight.Normal,
                        ),
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(DS.controlShape)
                            .background(if (correct) DS.successTint else DS.canvas)
                            .border(
                                1.dp,
                                if (correct) DS.success else DS.hairline,
                                DS.controlShape,
                            )
                            .padding(horizontal = 12.dp, vertical = 10.dp),
                    )
                }
            }
        }
    }
}

@Composable
private fun DiscountPaywall(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    onDismiss: () -> Unit,
    onPurchased: () -> Unit,
    onPurchaseMeta: (offeringId: String?, packageId: String?) -> Unit,
    onRestore: () -> Unit,
    onOpenTerms: () -> Unit,
    onOpenPrivacy: () -> Unit,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val discount by app.discountManager.state.collectAsState()
    LaunchedEffect(Unit) {
        storeViewModel.fetchOfferings()
        storeViewModel.trackPaywallImpression("native_discount", PaywallContext.OFFRE_DISCOUNT.offeringId)
    }
    val offerings by storeViewModel.offerings.collectAsState()
    val annual = remember(offerings) {
        storeViewModel.annualPackage(PaywallContext.OFFRE_DISCOUNT.offeringId)
    }
    // The struck-through price is the regular annual plan, so the saving shown is the real one.
    val regularAnnual = remember(offerings) { storeViewModel.annualPackage(null) }
    var purchasing by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var notice by remember { mutableStateOf<String?>(null) }
    val promo = storeViewModel.formattedPrice(
        annual,
        StringStore.text(context, "paywall.discount.fallbackPrice", language),
    )
    val regular = storeViewModel.formattedPrice(
        regularAnnual,
        StringStore.text(context, "paywall.plan.fallback.yearlyPrice", language),
    )
    val badge = storeViewModel.percentOff(annual, regularAnnual)
        ?: StringStore.text(context, "paywall.plan.discount", language)

    // Insets are consumed at the root, so painting the gradient here alone left the strips
    // behind the status and navigation bars on the pale canvas. Handing the brush up paints it
    // edge to edge instead, and the bar icons are flipped to light for the dark gradient.
    val setFullBleed = LocalFullBleedBackground.current
    val gradient = remember { Brush.verticalGradient(listOf(DS.accent, DS.accentSoft)) }
    val view = LocalView.current
    DisposableEffect(Unit) {
        setFullBleed(gradient)
        val window = (view.context as? Activity)?.window
        val controller = window?.let { WindowCompat.getInsetsController(it, view) }
        val previousLightBars = controller?.isAppearanceLightStatusBars
        controller?.isAppearanceLightStatusBars = false
        controller?.isAppearanceLightNavigationBars = false
        onDispose {
            setFullBleed(null)
            previousLightBars?.let {
                controller.isAppearanceLightStatusBars = it
                controller.isAppearanceLightNavigationBars = it
            }
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        Column(modifier = Modifier.fillMaxSize()) {
            Row(modifier = Modifier.fillMaxWidth().padding(horizontal = DS.Space.l, vertical = 8.dp)) {
                PaywallCloseButton(onClose = onDismiss, light = true)
            }
            PaywallEntry(modifier = Modifier.weight(1f)) {
                Column(
                    modifier = Modifier.fillMaxSize().padding(horizontal = 28.dp),
                    verticalArrangement = Arrangement.Center,
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    DiscountCountdownChip(
                        label = StringStore.text(context, "paywall.discount.endsIn", language),
                        time = discount.formattedRemaining,
                    )
                    Spacer(Modifier.height(18.dp))
                    Text(
                        text = badge,
                        color = Color.White,
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 40.sp,
                        modifier = Modifier
                            .clip(CircleShape)
                            .background(Color.White.copy(alpha = 0.16f))
                            .border(1.5.dp, Color.White.copy(alpha = 0.4f), CircleShape)
                            .padding(horizontal = 22.dp, vertical = 8.dp),
                    )
                    Spacer(Modifier.height(18.dp))
                    Text(
                        text = StringStore.text(context, "paywall.discount.title", language),
                        color = Color.White,
                        style = SophiaTypography.titleLarge.copy(fontSize = 24.sp, color = Color.White),
                        textAlign = TextAlign.Center,
                    )
                    Spacer(Modifier.height(8.dp))
                    Text(
                        text = StringStore.text(context, "paywall.discount.subtitle", language),
                        color = Color.White.copy(alpha = 0.85f),
                        style = SophiaTypography.bodyMedium.copy(color = Color.White.copy(alpha = 0.85f)),
                        textAlign = TextAlign.Center,
                    )
                    Spacer(Modifier.height(18.dp))
                    DiscountPriceBlock(
                        regular = regular,
                        promo = promo,
                        perYear = StringStore.text(context, "paywall.discount.perYear", language),
                    )
                    if (error != null) {
                        Spacer(Modifier.height(16.dp))
                        PaywallErrorNote(error!!, light = true)
                    }
                    if (notice != null) {
                        Spacer(Modifier.height(16.dp))
                        PaywallNotice(notice!!, light = true)
                    }
                }
            }
            Column(
                modifier = Modifier.padding(horizontal = 24.dp).padding(bottom = 12.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                PurchaseButton(
                    text = StringStore.text(context, "paywall.discount.cta", language),
                    purchasing = purchasing,
                    leadingIcon = Icons.Filled.Bolt,
                    fill = Color.White,
                    contentColor = DS.accent,
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
                            onPurchased = {
                                onPurchaseMeta(PaywallContext.OFFRE_DISCOUNT.offeringId, annual?.identifier)
                                onPurchased()
                            },
                        )
                    },
                )
                Text(
                    text = StringStore.text(context, "paywall.discount.noTrial", language),
                    color = Color.White.copy(alpha = 0.75f),
                    style = SophiaTypography.labelMedium.copy(
                        fontSize = 11.sp,
                        color = Color.White.copy(alpha = 0.75f),
                    ),
                    textAlign = TextAlign.Center,
                )
                // This paywall sells a subscription like every other one, so it owes the
                // same links: Restore alone was missing Terms and Privacy.
                PaywallLegalRow(
                    language = language,
                    onRestore = onRestore,
                    onTerms = onOpenTerms,
                    onPrivacy = onOpenPrivacy,
                    light = true,
                )
            }
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
    Column(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
        Row(modifier = Modifier.fillMaxWidth().padding(horizontal = DS.Space.l, vertical = 8.dp)) {
            PaywallCloseButton(onClose = onDismiss, delayMillis = closeDelayMillis)
        }
        PaywallEntry(modifier = Modifier.weight(1f)) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
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
            modifier = Modifier.padding(horizontal = 24.dp).padding(bottom = 12.dp),
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

private fun priceLineText(
    context: android.content.Context,
    language: AppLanguage,
    hasTrial: Boolean,
    yearly: String,
    perMonth: String,
): String = StringStore.text(
    context,
    if (hasTrial) "paywall.price.trialThenYearly" else "paywall.price.yearlyNoTrial",
    language,
    yearly,
    perMonth,
)

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
    if (amount.isEmpty()) {
        return StringStore.text(context, "paywall.plan.fallback.yearlyMonthly", language)
    }
    return "$amount ${StringStore.text(context, "paywall.plan.perMonth", language)}"
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
private fun purchasePackage(
    context: android.content.Context,
    language: AppLanguage,
    pkg: Package?,
    storeViewModel: StoreViewModel,
    onStart: () -> Unit,
    onDone: () -> Unit,
    onError: (String) -> Unit,
    onPurchased: () -> Unit,
    onPending: (String) -> Unit = {},
) {
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
                    onPurchased()
                } else {
                    // Play took the order but has not granted it yet.
                    onPending(StringStore.text(context, "purchase.pending", language))
                }
            }

            override fun onError(error: PurchasesError, userCancelled: Boolean) {
                onDone()
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
