package app.rork.sophia.ui.paywall

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
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
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.CircularProgressIndicator
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
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.R
import app.rork.sophia.SophiaApplication
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.data.DiscountBucket
import app.rork.sophia.data.PaywallExperiment
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.LocalFullBleedBackground
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.onboarding.readableWidth
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaAppearance
import kotlin.math.PI

private val OfferBlue = Color(0xFF2E62C4)
private val OfferCoral = Color(0xFFE05A3A)
private val OfferSaffron = Color(0xFFF2C94C)
private val OfferSoft = Color(0xFFDCE6F8)
private val OfferInk = Color(0xFF22262E)

/**
 * The "one-time offer" paywall of the `offre_discount` context, on a flat blue background.
 *
 * One annual plan from the install's discount offering (no free trial), the percentage really
 * saved, the price per month with the amount charged per year right next to it, and the
 * countdown of the discount manager. Two looks share the readers (test `discount_paywall_ab`,
 * see [PaywallExperiment]); prices, offering, purchase and tracking are the same on both.
 */
@Composable
internal fun DiscountPaywall(
    variant: PaywallExperiment.DiscountVariant,
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    onDismiss: () -> Unit,
    onPurchased: () -> Unit,
    onRestore: () -> Unit,
    onOpenTerms: () -> Unit,
    onOpenPrivacy: () -> Unit,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val discount by app.discountManager.state.collectAsState()
    val haptics = rememberHaptics()
    val props = remember(variant) { PaywallExperiment.discountAnalyticsProps(variant) }
    LaunchedEffect(Unit) {
        storeViewModel.fetchOfferings()
        // Reported on the bucket's own offering, never on the experiment-served current one.
        storeViewModel.trackPaywallImpressionForOffering(
            variant.paywallId,
            storeViewModel.promoOffering()?.identifier
                ?: DiscountBucket.offeringIdentifier(DiscountBucket.get(context)),
            props,
        )
    }
    val offerings by storeViewModel.offerings.collectAsState()
    // Picked by the install's discount bucket (A: offre_discount, B: offre_discount_2999).
    val annual = remember(offerings) { storeViewModel.promoPackage() }
    // The saving is measured against the regular annual plan, so the percentage is the real one.
    val regularAnnual = remember(offerings) { storeViewModel.annualPackage(null) }
    var purchasing by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var notice by remember { mutableStateOf<String?>(null) }
    val promo = storeViewModel.formattedPrice(annual, StoreViewModel.UNKNOWN_PRICE)
    val promoPerMonth = storeViewModel.formattedYearlyPerMonth(annual, promo)
    // No percentage at all rather than a remembered one when either price is unknown.
    val percentNumber = storeViewModel.percentOff(annual, regularAnnual)
        ?.filter { it.isDigit() }
        ?.takeIf { it.isNotEmpty() }
    val billedYearly = StringStore.text(context, "paywall.plan.billedYearly", language, promo)
    val offLabel = StringStore.text(context, "paywall.offer.off", language)
    val graduate = variant == PaywallExperiment.DiscountVariant.GRADUATE

    // Insets are consumed at the root, so painting the blue here alone left the strips behind
    // the status and navigation bars on the pale canvas. Handing the brush up paints it edge to
    // edge instead, and the bar icons are flipped to light for the dark backdrop.
    val setFullBleed = LocalFullBleedBackground.current
    val backdrop = remember { SolidColor(OfferBlue) }
    DisposableEffect(Unit) {
        setFullBleed(backdrop)
        SophiaAppearance.darkBackdropBehindBars = true
        onDispose {
            setFullBleed(null)
            SophiaAppearance.darkBackdropBehindBars = false
        }
    }

    var popped by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { popped = true }
    val pop by animateFloatAsState(
        targetValue = if (popped) 1f else 0f,
        animationSpec = spring(dampingRatio = 0.55f, stiffness = Spring.StiffnessMediumLow),
        label = "offerPop",
    )
    val float by rememberInfiniteTransition(label = "offerFloat").animateFloat(
        initialValue = 0f,
        targetValue = -6f,
        animationSpec = infiniteRepeatable(tween(2500), RepeatMode.Reverse),
        label = "offerFloatY",
    )

    // Painted here as well: from the tabs the paywall sits in an opaque layer that hides the
    // root backdrop.
    Box(modifier = Modifier.fillMaxSize().background(OfferBlue)) {
        if (graduate) OfferConfetti(Modifier.fillMaxWidth().height(170.dp).align(Alignment.BottomCenter))
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .readableWidth()
                    .padding(horizontal = 20.dp, vertical = 8.dp),
                horizontalArrangement = if (graduate) Arrangement.End else Arrangement.Start,
            ) {
                PaywallCloseButton(onClose = onDismiss, light = true)
            }
            PaywallEntry(modifier = Modifier.weight(1f)) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .readableWidth()
                        .verticalScroll(rememberScrollState())
                        .padding(horizontal = 24.dp),
                    verticalArrangement = Arrangement.Center,
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    val countdown: @Composable () -> Unit = {
                        OfferCountdown(
                            label = StringStore.text(context, "paywall.discount.endsIn", language),
                            time = discount.formattedRemaining,
                        )
                    }
                    if (graduate) {
                        Text(
                            text = StringStore.text(context, "paywall.offer.title", language),
                            color = Color.White,
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 32.sp,
                            lineHeight = 38.sp,
                            textAlign = TextAlign.Center,
                        )
                        Spacer(Modifier.height(12.dp))
                        countdown()
                        Spacer(Modifier.height(if (percentNumber == null) 20.dp else 14.dp))
                        Box(contentAlignment = Alignment.TopCenter) {
                            OfferIllustration(
                                drawable = R.drawable.pw_offer_graduate,
                                side = 230.dp,
                                floatY = float,
                                modifier = Modifier.padding(top = if (percentNumber == null) 0.dp else 42.dp),
                            )
                            if (percentNumber != null) {
                                OfferPercentMark(
                                    number = percentNumber,
                                    label = offLabel,
                                    numberSize = 52.sp,
                                    signSize = 25.sp,
                                    labelSize = 10.sp,
                                    numberColor = OfferBlue,
                                    textColor = OfferInk,
                                    modifier = Modifier
                                        .graphicsLayer {
                                            val scale = 0.7f + 0.3f * pop
                                            scaleX = scale
                                            scaleY = scale
                                            alpha = pop.coerceIn(0f, 1f)
                                        }
                                        .clip(RoundedCornerShape(16.dp))
                                        .background(Color.White)
                                        .padding(horizontal = 16.dp, vertical = 9.dp),
                                )
                            }
                        }
                        Spacer(Modifier.height(20.dp))
                        Text(
                            text = StringStore.text(context, "paywall.offer.only", language, promoPerMonth),
                            color = Color.White,
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 22.sp,
                            textAlign = TextAlign.Center,
                        )
                        Spacer(Modifier.height(4.dp))
                        OfferBilledNote(billedYearly)
                    } else {
                        Text(
                            text = StringStore.text(context, "paywall.offer.title", language).uppercase(),
                            color = Color.White,
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 13.sp,
                            letterSpacing = 1.sp,
                            modifier = Modifier
                                .clip(CircleShape)
                                .background(OfferCoral)
                                .padding(horizontal = 16.dp, vertical = 7.dp),
                        )
                        if (percentNumber != null) {
                            Spacer(Modifier.height(10.dp))
                            OfferPercentMark(
                                number = percentNumber,
                                label = offLabel,
                                numberSize = 124.sp,
                                signSize = 56.sp,
                                labelSize = 16.sp,
                                numberColor = OfferSaffron,
                                textColor = OfferSaffron,
                                modifier = Modifier.graphicsLayer {
                                    val scale = 0.7f + 0.3f * pop
                                    scaleX = scale
                                    scaleY = scale
                                    alpha = pop.coerceIn(0f, 1f)
                                },
                            )
                        }
                        Spacer(Modifier.height(10.dp))
                        Text(
                            text = promoPerMonth + " " + StringStore.text(context, "paywall.plan.perMonth", language),
                            color = Color.White,
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 19.sp,
                            textAlign = TextAlign.Center,
                        )
                        Spacer(Modifier.height(4.dp))
                        OfferBilledNote(billedYearly)
                        Spacer(Modifier.height(14.dp))
                        countdown()
                        Spacer(Modifier.height(20.dp))
                        OfferIllustration(drawable = R.drawable.pw_offer_brain, side = 220.dp, floatY = float)
                    }
                    if (error != null) {
                        Spacer(Modifier.height(16.dp))
                        PaywallErrorNote(error!!, light = true)
                    }
                    if (notice != null) {
                        Spacer(Modifier.height(16.dp))
                        PaywallNotice(notice!!, light = true)
                    }
                    Spacer(Modifier.height(8.dp))
                }
            }
            Column(
                modifier = Modifier
                    .readableWidth()
                    .padding(horizontal = 24.dp)
                    .padding(bottom = 12.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                OfferCta(
                    text = if (graduate) {
                        StringStore.text(context, "paywall.discount.cta", language)
                    } else {
                        StringStore.text(context, "paywall.offer.cta", language, promoPerMonth)
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
                            onPurchased = {
                                haptics.confirm()
                                onPurchased()
                            },
                            paywallId = variant.paywallId,
                            analyticsProps = props,
                        )
                    },
                )
                Text(
                    text = StringStore.text(context, "paywall.discount.noTrial", language),
                    color = OfferSoft,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Medium,
                    fontSize = 12.sp,
                    textAlign = TextAlign.Center,
                )
                // This paywall sells a subscription like every other one, so it owes the same
                // links as the others: Restore, Terms and Privacy.
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

/** "50 % OFF": the number in large type, the sign and the word stacked on its right. */
@Composable
private fun OfferPercentMark(
    number: String,
    label: String,
    numberSize: TextUnit,
    signSize: TextUnit,
    labelSize: TextUnit,
    numberColor: Color,
    textColor: Color,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier.clearAndSetSemantics { contentDescription = "$number % $label" },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Text(
            text = number,
            color = numberColor,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = numberSize,
            lineHeight = numberSize,
            maxLines = 1,
        )
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                text = "%",
                color = textColor,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = signSize,
                lineHeight = signSize,
            )
            Text(
                text = label,
                color = textColor,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = labelSize,
                lineHeight = labelSize * 1.2f,
                letterSpacing = 0.5.sp,
            )
        }
    }
}

/** The amount really charged once a year, next to the price per month. */
@Composable
private fun OfferBilledNote(text: String) {
    Text(
        text = text,
        color = OfferSoft,
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.SemiBold,
        fontSize = 14.sp,
        textAlign = TextAlign.Center,
    )
}

@Composable
private fun OfferCountdown(label: String, time: String) {
    Row(
        modifier = Modifier
            .clip(CircleShape)
            .background(Color.White.copy(alpha = 0.14f))
            .border(1.dp, Color.White.copy(alpha = 0.35f), CircleShape)
            .padding(horizontal = 14.dp, vertical = 7.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Icon(Icons.Filled.Schedule, contentDescription = null, tint = Color.White, modifier = Modifier.size(14.dp))
        Text(
            text = label,
            color = Color.White,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 14.sp,
        )
        Text(
            text = time,
            color = Color.White,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 15.sp,
        )
    }
}

/** The paper-cut picture in its white frame, slightly tilted and gently floating. */
@Composable
private fun OfferIllustration(drawable: Int, side: Dp, floatY: Float, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .graphicsLayer { translationY = floatY * density }
            .rotate(-2f)
            .size(side)
            .clip(RoundedCornerShape(24.dp))
            .background(Color.White)
            .padding(3.dp),
    ) {
        Image(
            painter = painterResource(drawable),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxSize().clip(RoundedCornerShape(21.dp)),
        )
    }
}

@Composable
private fun OfferCta(text: String, purchasing: Boolean, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .pressable(onClick = onClick, enabled = !purchasing)
            .heightIn(min = 58.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(Color.White)
            .padding(horizontal = 14.dp, vertical = 12.dp),
        contentAlignment = Alignment.Center,
    ) {
        if (purchasing) {
            CircularProgressIndicator(color = OfferBlue, strokeWidth = 2.dp, modifier = Modifier.size(20.dp))
        } else {
            Text(
                text = text,
                color = OfferBlue,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 17.sp,
                maxLines = 2,
                textAlign = TextAlign.Center,
            )
        }
    }
}

/** Small paper pieces resting at the bottom of the screen, always in the same places. */
@Composable
private fun OfferConfetti(modifier: Modifier = Modifier) {
    val palette = remember { listOf(OfferSaffron, OfferCoral, Color.White, OfferSoft, OfferSaffron) }
    Canvas(modifier = modifier) {
        var seed = 7L
        fun next(): Float {
            seed = seed * 6364136223846793005L + 1442695040888963407L
            return ((seed ushr 33) % 10_000L).toFloat() / 10_000f
        }
        repeat(34) { index ->
            val x = next() * size.width
            val y = size.height - 12.dp.toPx() - next() * (size.height - 24.dp.toPx())
            val w = (8f + next() * 4f).dp.toPx()
            val h = (5f + next() * 3f).dp.toPx()
            val degrees = (next() * PI).toFloat() * 57.29578f
            rotate(degrees, pivot = Offset(x, y)) {
                drawRoundRect(
                    color = palette[index % palette.size].copy(alpha = 0.9f),
                    topLeft = Offset(x - w / 2, y - h / 2),
                    size = Size(w, h),
                    cornerRadius = CornerRadius(2.dp.toPx()),
                )
            }
        }
    }
}
