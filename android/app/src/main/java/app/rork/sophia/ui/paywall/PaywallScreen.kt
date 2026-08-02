package app.rork.sophia.ui.paywall

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import com.revenuecat.purchases.Package
import com.revenuecat.purchases.PurchaseParams
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesError
import com.revenuecat.purchases.interfaces.PurchaseCallback
import com.revenuecat.purchases.models.StoreTransaction

enum class PaywallContext(val offeringId: String) {
    FIN_ONBOARDING("fin_onboarding"),
    OFFRE_DISCOUNT("offre_discount"),
    DEBLOQUER_COURS("debloquer_cours"),
    QUIZZ("quizz"),
    ENTRAINEMENT("quizz"),
}

@Composable
fun OnboardingPaywallFlow(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    onDismiss: () -> Unit,
    onPurchased: () -> Unit,
) {
    var showComparison by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { storeViewModel.fetchOfferings() }
    val offerings by storeViewModel.offerings.collectAsState()
    val annual = remember(offerings) { storeViewModel.annualPackage(PaywallContext.FIN_ONBOARDING.offeringId) }
    val monthly = remember(offerings) { storeViewModel.monthlyPackage(PaywallContext.FIN_ONBOARDING.offeringId) }

    if (!showComparison) {
        OnboardingAnnualPaywall(
            language = language,
            annual = annual,
            storeViewModel = storeViewModel,
            onViewAllPlans = { showComparison = true },
            onDismiss = onDismiss,
            onPurchased = onPurchased,
        )
    } else {
        OnboardingComparisonPaywall(
            language = language,
            annual = annual,
            monthly = monthly,
            storeViewModel = storeViewModel,
            onDismiss = onDismiss,
            onPurchased = onPurchased,
        )
    }
}

@Composable
fun PaywallScreen(
    context: PaywallContext,
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    onDismiss: () -> Unit,
    onPurchased: () -> Unit,
) {
    when (context) {
        PaywallContext.FIN_ONBOARDING -> OnboardingPaywallFlow(
            language = language,
            storeViewModel = storeViewModel,
            onDismiss = onDismiss,
            onPurchased = onPurchased,
        )
        PaywallContext.OFFRE_DISCOUNT -> DiscountPaywall(
            language = language,
            storeViewModel = storeViewModel,
            onDismiss = onDismiss,
            onPurchased = onPurchased,
        )
        PaywallContext.QUIZZ -> QuizPaywall(
            language = language,
            storeViewModel = storeViewModel,
            onDismiss = onDismiss,
            onPurchased = onPurchased,
        )
        else -> StandardPaywall(
            context = context,
            language = language,
            storeViewModel = storeViewModel,
            onDismiss = onDismiss,
            onPurchased = onPurchased,
        )
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
) {
    val context = LocalContext.current
    var purchasing by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val hasTrial = storeViewModel.hasFreeTrial(annual)
    val yearly = storeViewModel.formattedPrice(
        annual,
        StringStore.text(context, "paywall.plan.fallback.yearlyPrice", language),
    )
    val perMonth = storeViewModel.formattedYearlyPerMonth(annual, yearly)

    LaunchedEffect(Unit) {
        storeViewModel.trackPaywallImpression("onboarding_annual")
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas)
            .padding(DS.Space.l),
        verticalArrangement = Arrangement.SpaceBetween,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
            Spacer(Modifier.height(28.dp))
            Box(
                modifier = Modifier
                    .clip(CircleShape)
                    .background(DS.accentTint)
                    .padding(28.dp),
            ) {
                Text("✨", fontSize = 40.sp)
            }
            Spacer(Modifier.height(24.dp))
            if (hasTrial) {
                Text(
                    StringStore.text(context, "onboardingV2.pw.tryFree", language),
                    style = SophiaTypography.titleLarge.copy(color = DS.success),
                    textAlign = TextAlign.Center,
                )
                Spacer(Modifier.height(10.dp))
                Text(
                    StringStore.text(context, "onboardingV2.pw.thenPrice", language, perMonth, yearly),
                    style = SophiaTypography.bodyMedium,
                    textAlign = TextAlign.Center,
                )
            } else {
                Text(
                    StringStore.text(context, "onboardingV2.pw.priceNoTrial", language, perMonth, yearly),
                    style = SophiaTypography.titleLarge,
                    textAlign = TextAlign.Center,
                )
            }
            Spacer(Modifier.height(12.dp))
            Text(
                StringStore.text(context, "onboardingV2.pw.twoTaps", language),
                style = SophiaTypography.labelMedium,
                color = DS.inkTertiary,
                textAlign = TextAlign.Center,
            )
            if (error != null) {
                Spacer(Modifier.height(12.dp))
                Text(error!!, color = DS.danger, style = SophiaTypography.labelMedium)
            }
        }
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            PurchaseButton(
                text = StringStore.text(
                    context,
                    if (hasTrial) "onboardingV2.pw.startTrial" else "onboardingV2.pw.subscribe",
                    language,
                ),
                enabled = !purchasing,
                onClick = {
                    purchasePackage(
                        context = context,
                        pkg = annual,
                        storeViewModel = storeViewModel,
                        onStart = { purchasing = true },
                        onDone = { purchasing = false },
                        onError = { error = it; purchasing = false },
                        onPurchased = onPurchased,
                    )
                },
            )
            TextButton(onClick = onViewAllPlans, modifier = Modifier.fillMaxWidth()) {
                Text(StringStore.text(context, "onboardingV2.pw.viewAllPlans", language), color = DS.accentSoft)
            }
            TextButton(onClick = onDismiss, modifier = Modifier.fillMaxWidth()) {
                Text(StringStore.text(context, "home.skip", language), color = DS.inkTertiary)
            }
        }
    }
}

@Composable
private fun OnboardingComparisonPaywall(
    language: AppLanguage,
    annual: Package?,
    monthly: Package?,
    storeViewModel: StoreViewModel,
    onDismiss: () -> Unit,
    onPurchased: () -> Unit,
) {
    val context = LocalContext.current
    var yearlySelected by remember { mutableStateOf(true) }
    var purchasing by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val features = listOf(
        "allSubjects", "unlimited", "quiz", "favorites", "noAds", "weekly",
    )
    val annualPrice = storeViewModel.formattedPrice(
        annual,
        StringStore.text(context, "paywall.plan.fallback.yearlyPrice", language),
    )
    val monthlyPrice = storeViewModel.formattedPrice(
        monthly,
        StringStore.text(context, "paywall.plan.fallback.monthlyPrice", language),
    )
    val yearlyHasTrial = storeViewModel.hasFreeTrial(annual)
    val monthlyHasTrial = storeViewModel.hasFreeTrial(monthly)
    val selectedHasTrial = if (yearlySelected) yearlyHasTrial else monthlyHasTrial

    LaunchedEffect(Unit) {
        storeViewModel.trackPaywallImpression("onboarding_comparison")
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas)
            .padding(DS.Space.l),
    ) {
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState()),
        ) {
            Spacer(Modifier.height(24.dp))
            Text(
                StringStore.text(context, "onboardingV2.pw.compare.title", language),
                style = SophiaTypography.titleLarge,
            )
            Spacer(Modifier.height(16.dp))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text("", modifier = Modifier.weight(1.4f))
                Text(
                    StringStore.text(context, "onboardingV2.pw.free", language),
                    style = SophiaTypography.labelMedium,
                    modifier = Modifier.weight(0.8f),
                    textAlign = TextAlign.Center,
                )
                Text(
                    StringStore.text(context, "onboardingV2.pw.pro", language),
                    style = SophiaTypography.labelMedium,
                    color = DS.accentSoft,
                    modifier = Modifier.weight(0.8f),
                    textAlign = TextAlign.Center,
                )
            }
            features.forEach { key ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        StringStore.text(context, "onboardingV2.pw.feature.$key", language),
                        style = SophiaTypography.bodyMedium,
                        modifier = Modifier.weight(1.4f),
                    )
                    Text("—", modifier = Modifier.weight(0.8f), textAlign = TextAlign.Center, color = DS.inkTertiary)
                    Text("✓", modifier = Modifier.weight(0.8f), textAlign = TextAlign.Center, color = DS.success)
                }
            }
            Spacer(Modifier.height(20.dp))
            PlanCard(
                title = StringStore.text(context, "onboardingV2.pw.yearly", language),
                price = annualPrice,
                badge = if (yearlyHasTrial) {
                    StringStore.text(context, "onboardingV2.pw.trialBadge", language)
                } else {
                    StringStore.text(context, "paywall.discount.perYear", language)
                },
                selected = yearlySelected,
                onClick = { yearlySelected = true },
            )
            Spacer(Modifier.height(10.dp))
            PlanCard(
                title = StringStore.text(context, "onboardingV2.pw.monthly", language),
                price = monthlyPrice,
                badge = if (monthlyHasTrial) {
                    StringStore.text(context, "onboardingV2.pw.trialBadge", language)
                } else {
                    StringStore.text(context, "onboardingV2.pw.monthlyBilling", language)
                },
                selected = !yearlySelected,
                onClick = { yearlySelected = false },
            )
            if (error != null) {
                Spacer(Modifier.height(8.dp))
                Text(error!!, color = DS.danger, style = SophiaTypography.labelMedium)
            }
        }
        PurchaseButton(
            text = StringStore.text(
                context,
                if (selectedHasTrial) "onboardingV2.pw.startTrial" else "onboardingV2.pw.subscribe",
                language,
            ),
            enabled = !purchasing,
            onClick = {
                val pkg = if (yearlySelected) annual else monthly
                purchasePackage(
                    context = context,
                    pkg = pkg,
                    storeViewModel = storeViewModel,
                    onStart = { purchasing = true },
                    onDone = { purchasing = false },
                    onError = { error = it; purchasing = false },
                    onPurchased = onPurchased,
                )
            },
        )
        TextButton(onClick = onDismiss, modifier = Modifier.fillMaxWidth()) {
            Text(StringStore.text(context, "home.skip", language), color = DS.inkTertiary)
        }
    }
}

@Composable
private fun DiscountPaywall(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    onDismiss: () -> Unit,
    onPurchased: () -> Unit,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val discount by app.discountManager.state.collectAsState()
    LaunchedEffect(Unit) {
        storeViewModel.fetchOfferings()
        storeViewModel.trackPaywallImpression(
            paywallId = "native_discount",
            offeringIdentifier = PaywallContext.OFFRE_DISCOUNT.offeringId,
        )
    }
    val offerings by storeViewModel.offerings.collectAsState()
    val annual = remember(offerings) {
        storeViewModel.annualPackage(PaywallContext.OFFRE_DISCOUNT.offeringId)
    }
    var purchasing by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val promo = storeViewModel.formattedPrice(
        annual,
        StringStore.text(context, "paywall.discount.fallbackPrice", language),
    )
    val regular = StringStore.text(context, "paywall.plan.fallback.yearlyPrice", language)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(DS.accent, DS.accentSoft.copy(alpha = 0.85f), DS.accent),
                ),
            )
            .padding(DS.Space.l),
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.SpaceBetween,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Spacer(Modifier.height(24.dp))
                Text(
                    text = StringStore.text(context, "paywall.discount.endsIn", language) +
                        "  ${discount.formattedRemaining}",
                    color = Color.White,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier
                        .clip(DS.controlShape)
                        .background(Color.Black.copy(alpha = 0.25f))
                        .padding(horizontal = 14.dp, vertical = 8.dp),
                )
                Spacer(Modifier.height(28.dp))
                Text(
                    StringStore.text(context, "paywall.plan.discount", language),
                    color = Color.White,
                    fontSize = 56.sp,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                )
                Spacer(Modifier.height(12.dp))
                Text(
                    StringStore.text(context, "paywall.discount.title", language),
                    color = Color.White,
                    style = SophiaTypography.titleLarge,
                    textAlign = TextAlign.Center,
                )
                Spacer(Modifier.height(8.dp))
                Text(
                    StringStore.text(context, "paywall.discount.subtitle", language),
                    color = Color.White.copy(alpha = 0.9f),
                    style = SophiaTypography.bodyMedium,
                    textAlign = TextAlign.Center,
                )
                Spacer(Modifier.height(28.dp))
                Text(
                    regular,
                    color = Color.White.copy(alpha = 0.7f),
                    textDecoration = TextDecoration.LineThrough,
                    fontSize = 18.sp,
                )
                Text(
                    promo,
                    color = Color.White,
                    fontSize = 40.sp,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                )
                Text(
                    StringStore.text(context, "paywall.discount.perYear", language),
                    color = Color.White.copy(alpha = 0.85f),
                    style = SophiaTypography.labelMedium,
                )
                if (error != null) {
                    Spacer(Modifier.height(8.dp))
                    Text(error!!, color = DS.dangerTint)
                }
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Button(
                    onClick = {
                        purchasePackage(
                            context = context,
                            pkg = annual,
                            storeViewModel = storeViewModel,
                            onStart = { purchasing = true },
                            onDone = { purchasing = false },
                            onError = { error = it; purchasing = false },
                            onPurchased = onPurchased,
                        )
                    },
                    enabled = !purchasing,
                    modifier = Modifier.fillMaxWidth().height(54.dp),
                    shape = DS.controlShape,
                    colors = ButtonDefaults.buttonColors(containerColor = Color.White, contentColor = DS.accent),
                ) {
                    Text(
                        StringStore.text(context, "paywall.discount.cta", language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                    )
                }
                Spacer(Modifier.height(8.dp))
                Text(
                    StringStore.text(context, "paywall.discount.noTrial", language),
                    color = Color.White.copy(alpha = 0.8f),
                    style = SophiaTypography.labelMedium,
                    textAlign = TextAlign.Center,
                )
                TextButton(onClick = onDismiss) {
                    Text(StringStore.text(context, "home.skip", language), color = Color.White.copy(alpha = 0.75f))
                }
            }
        }
    }
}

@Composable
private fun QuizPaywall(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    onDismiss: () -> Unit,
    onPurchased: () -> Unit,
) {
    val context = LocalContext.current
    LaunchedEffect(Unit) {
        storeViewModel.fetchOfferings()
        storeViewModel.trackPaywallImpression(
            paywallId = "native_quiz",
            offeringIdentifier = PaywallContext.QUIZZ.offeringId,
        )
    }
    val offerings by storeViewModel.offerings.collectAsState()
    val annual = remember(offerings) {
        storeViewModel.annualPackage(PaywallContext.QUIZZ.offeringId)
    }
    val hasTrial = storeViewModel.hasFreeTrial(annual)
    val yearly = storeViewModel.formattedPrice(
        annual,
        StringStore.text(context, "paywall.plan.fallback.yearlyPrice", language),
    )
    val perMonth = storeViewModel.formattedYearlyPerMonth(annual, yearly)
    var purchasing by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var expandedFaq by remember { mutableStateOf<Int?>(null) }

    val faq = listOf(
        "paywall.quiz.faq.q1" to "paywall.quiz.faq.a1",
        "paywall.quiz.faq.q2" to "paywall.quiz.faq.a2",
        (if (hasTrial) "paywall.quiz.faq.q3" else "paywall.quiz.faq.q3.noTrial") to
            (if (hasTrial) "paywall.quiz.faq.a3" else "paywall.quiz.faq.a3.noTrial"),
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas)
            .padding(DS.Space.l),
    ) {
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.height(20.dp))
            Text(
                StringStore.text(context, "paywall.quiz.title", language),
                style = SophiaTypography.titleLarge,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(10.dp))
            Text(
                StringStore.text(context, "paywall.quiz.subtitle", language),
                style = SophiaTypography.bodyMedium,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(22.dp))
            faq.forEachIndexed { index, (qKey, aKey) ->
                val expanded = expandedFaq == index
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 5.dp)
                        .clip(DS.cardShape)
                        .background(DS.surface)
                        .border(
                            1.dp,
                            if (expanded) DS.accentSoft.copy(alpha = 0.35f) else DS.hairline,
                            DS.cardShape,
                        )
                        .clickable { expandedFaq = if (expanded) null else index }
                        .padding(16.dp),
                ) {
                    Row(verticalAlignment = Alignment.Top) {
                        Text(
                            StringStore.text(context, qKey, language),
                            style = SophiaTypography.bodyMedium.copy(fontWeight = FontWeight.SemiBold),
                            color = DS.ink,
                            modifier = Modifier.weight(1f),
                        )
                        Text(if (expanded) "▲" else "▼", color = DS.inkTertiary, fontSize = 12.sp)
                    }
                    AnimatedVisibility(visible = expanded) {
                        Text(
                            StringStore.text(context, aKey, language),
                            style = SophiaTypography.labelMedium,
                            color = DS.inkSecondary,
                            modifier = Modifier.padding(top = 10.dp),
                        )
                    }
                }
            }
            Spacer(Modifier.height(16.dp))
            Text(
                "★★★★★  4,8 · " + StringStore.text(context, "paywall.quiz.rating", language),
                style = SophiaTypography.labelMedium,
                color = DS.inkTertiary,
            )
            if (error != null) {
                Spacer(Modifier.height(10.dp))
                Text(error!!, color = DS.danger, style = SophiaTypography.labelMedium)
            }
        }
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(
                StringStore.text(
                    context,
                    if (hasTrial) "paywall.price.trialThenYearly" else "paywall.price.yearlyNoTrial",
                    language,
                    yearly,
                    perMonth,
                ),
                style = SophiaTypography.labelMedium,
                color = DS.inkTertiary,
                textAlign = TextAlign.Center,
            )
            PurchaseButton(
                text = StringStore.text(
                    context,
                    if (hasTrial) "paywall.cta.activateTrial" else "paywall.cta.subscribe",
                    language,
                ),
                enabled = !purchasing,
                onClick = {
                    purchasePackage(
                        context = context,
                        pkg = annual,
                        storeViewModel = storeViewModel,
                        onStart = { purchasing = true },
                        onDone = { purchasing = false },
                        onError = { error = it; purchasing = false },
                        onPurchased = onPurchased,
                    )
                },
            )
            TextButton(onClick = onDismiss) {
                Text(StringStore.text(context, "home.skip", language), color = DS.inkSecondary)
            }
        }
    }
}

@Composable
private fun StandardPaywall(
    context: PaywallContext,
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    onDismiss: () -> Unit,
    onPurchased: () -> Unit,
) {
    val appContext = LocalContext.current
    LaunchedEffect(context) {
        storeViewModel.fetchOfferings()
        val paywallId = when (context) {
            PaywallContext.ENTRAINEMENT -> "native_training"
            PaywallContext.DEBLOQUER_COURS -> "native_course_unlock"
            else -> "native_standard"
        }
        storeViewModel.trackPaywallImpression(paywallId, context.offeringId)
    }
    val offerings by storeViewModel.offerings.collectAsState()
    val annual = remember(offerings, context) { storeViewModel.annualPackage(context.offeringId) }
    val hasTrial = storeViewModel.hasFreeTrial(annual)
    var purchasing by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val title = when (context) {
        PaywallContext.DEBLOQUER_COURS -> StringStore.text(appContext, "paywall.course.title", language)
        PaywallContext.ENTRAINEMENT -> StringStore.text(appContext, "paywall.quiz.title", language)
        else -> "Sophia Premium"
    }
    val subtitle = when (context) {
        PaywallContext.DEBLOQUER_COURS -> StringStore.text(appContext, "paywall.course.subtitle", language)
        PaywallContext.ENTRAINEMENT -> StringStore.text(appContext, "paywall.quiz.subtitle", language)
        else -> StringStore.text(appContext, "paywall.premiumHeadline", language)
    }
    val yearly = storeViewModel.formattedPrice(
        annual,
        StringStore.text(appContext, "paywall.plan.fallback.yearlyPrice", language),
    )
    val perMonth = storeViewModel.formattedYearlyPerMonth(annual, yearly)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas)
            .padding(DS.Space.l),
        verticalArrangement = Arrangement.SpaceBetween,
    ) {
        Column {
            Spacer(Modifier.height(36.dp))
            Text(title, style = SophiaTypography.displayLarge, fontSize = 32.sp)
            Spacer(Modifier.height(12.dp))
            Text(subtitle, style = SophiaTypography.bodyMedium)
            Spacer(Modifier.height(20.dp))
            listOf(
                "paywall.benefit.conversations",
                "paywall.benefit.curiosity",
                "paywall.benefit.confidence",
                "paywall.benefit.screenTime",
            ).forEach { key ->
                Text(
                    StringStore.text(appContext, key, language),
                    style = SophiaTypography.bodyLarge,
                    modifier = Modifier.padding(vertical = 6.dp),
                )
            }
            Spacer(Modifier.height(12.dp))
            Text(
                StringStore.text(
                    appContext,
                    if (hasTrial) "paywall.price.trialThenYearly" else "paywall.price.yearlyNoTrial",
                    language,
                    yearly,
                    perMonth,
                ),
                style = SophiaTypography.labelMedium,
                color = DS.inkSecondary,
            )
            if (error != null) {
                Spacer(Modifier.height(12.dp))
                Text(error!!, color = DS.danger, style = SophiaTypography.labelMedium)
            }
            if (!Purchases.isConfigured) {
                Spacer(Modifier.height(12.dp))
                Text(
                    "RevenueCat non configuré — debug: simuler premium.",
                    style = SophiaTypography.labelMedium,
                    color = DS.inkSecondary,
                )
            }
        }
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            PurchaseButton(
                text = StringStore.text(
                    appContext,
                    when {
                        context == PaywallContext.DEBLOQUER_COURS && hasTrial -> "paywall.cta.unlockFree"
                        hasTrial -> "paywall.cta.activateTrial"
                        else -> "paywall.cta.subscribe"
                    },
                    language,
                ),
                enabled = !purchasing,
                onClick = {
                    purchasePackage(
                        context = appContext,
                        pkg = annual,
                        storeViewModel = storeViewModel,
                        onStart = { purchasing = true },
                        onDone = { purchasing = false },
                        onError = { error = it; purchasing = false },
                        onPurchased = onPurchased,
                    )
                },
            )
            TextButton(onClick = onDismiss, modifier = Modifier.align(Alignment.CenterHorizontally)) {
                Text(StringStore.text(appContext, "home.skip", language), color = DS.inkSecondary)
            }
        }
    }
}

@Composable
private fun PlanCard(
    title: String,
    price: String,
    badge: String,
    selected: Boolean,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(DS.cardShape)
            .background(if (selected) DS.accentTint else DS.surface)
            .border(1.dp, if (selected) DS.accentSoft else DS.hairline, DS.cardShape)
            .clickable(onClick = onClick)
            .padding(16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column {
            Text(title, style = SophiaTypography.titleMedium)
            Text(badge, style = SophiaTypography.labelMedium, color = DS.accentSoft)
        }
        Text(price, style = SophiaTypography.titleMedium)
    }
}

@Composable
private fun PurchaseButton(text: String, enabled: Boolean, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = Modifier.fillMaxWidth().height(54.dp),
        shape = DS.controlShape,
        colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
    ) {
        Text(
            text = text,
            color = Color.White,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 16.sp,
            textAlign = TextAlign.Center,
        )
    }
}

private fun purchasePackage(
    context: android.content.Context,
    pkg: Package?,
    storeViewModel: StoreViewModel,
    onStart: () -> Unit,
    onDone: () -> Unit,
    onError: (String) -> Unit,
    onPurchased: () -> Unit,
) {
    if (pkg == null) {
        if (!Purchases.isConfigured) {
            storeViewModel.setPremiumDebug(true)
            onPurchased()
        } else {
            onError("Offre indisponible")
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
                onPurchased()
            }

            override fun onError(error: PurchasesError, userCancelled: Boolean) {
                onDone()
                if (!userCancelled) onError(error.message)
            }
        },
    )
}

private fun android.content.Context.findActivity(): android.app.Activity? {
    var ctx = this
    while (ctx is android.content.ContextWrapper) {
        if (ctx is android.app.Activity) return ctx
        ctx = ctx.baseContext
    }
    return null
}
