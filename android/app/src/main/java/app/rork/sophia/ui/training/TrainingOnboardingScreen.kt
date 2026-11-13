package app.rork.sophia.ui.training

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.R
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.components.DSProgressBar
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.onboarding.ONBOARDING_HEADER_BAR_WIDTH
import app.rork.sophia.ui.onboarding.OV2
import app.rork.sophia.ui.onboarding.OV2Core
import app.rork.sophia.ui.onboarding.OV2CoreIllustration
import app.rork.sophia.ui.onboarding.OV2CoreTapHint
import app.rork.sophia.ui.onboarding.OV2End
import app.rork.sophia.ui.onboarding.OV2EndHighlightTitle
import app.rork.sophia.ui.onboarding.OnboardingCta
import app.rork.sophia.ui.onboarding.OnboardingPage
import app.rork.sophia.ui.onboarding.ProgressiveWords
import app.rork.sophia.ui.onboarding.ov2CoreSentenceStyle
import app.rork.sophia.ui.onboarding.ov2EndCard
import app.rork.sophia.ui.onboarding.rememberOnboardingReduceMotion
import app.rork.sophia.ui.paywall.OnboardingPaywallFlow
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.ForceLightAppearance
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlin.math.exp
import kotlinx.coroutines.delay

private enum class TrainingObStep { Welcome, Recall, Algorithm, Paywall }

/** Nombre d'écrans de présentation, ceux que la barre de progression compte. */
private const val TRAINING_OB_PAGES = 3

/** Hauteur de la bande qui porte la barre de progression, au-dessus des écrans. */
private val TRAINING_OB_HEADER_HEIGHT: Dp = 34.dp

/** Fond très légèrement bleuté de la carte du graphique (celui de la courbe « 90 jours »). */
private val RetentionCardFill = Color(0xFFF7F9FD)
private val RetentionAxisColor = Color(0xFFC3CBD8)

/**
 * Mini-onboarding de la page Entraînement, au style « Elevate arrondi » de l'onboarding
 * principal (mêmes briques : barre de progression, titres à passage fort, cartes bordées,
 * bouton plein, glissement horizontal entre les écrans). Trois écrans, puis le paywall de fin
 * d'onboarding.
 *
 * La page hôte garde sa propre flèche retour au-dessus : la bande du haut ne porte donc que
 * la barre de progression, et le retour système ramène à l'écran précédent.
 */
@Composable
fun TrainingOnboardingScreen(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    startAtPaywall: Boolean,
    onCompletedOnboarding: () -> Unit,
    onPurchased: () -> Unit,
    onClose: () -> Unit,
) {
    // Designed light-only, as on iOS: the night palette stays off while it is shown.
    ForceLightAppearance()
    val haptics = rememberHaptics()
    val reduceMotion = rememberOnboardingReduceMotion()
    var step by remember {
        mutableStateOf(if (startAtPaywall) TrainingObStep.Paywall else TrainingObStep.Welcome)
    }

    // Retour système : l'écran précédent. Sur le premier écran et sur le paywall, la page
    // hôte et le paywall gardent leur comportement.
    BackHandler(enabled = step == TrainingObStep.Recall || step == TrainingObStep.Algorithm) {
        haptics.select()
        step = if (step == TrainingObStep.Algorithm) TrainingObStep.Recall else TrainingObStep.Welcome
    }

    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    val slidePx = with(LocalDensity.current) { (if (reduceMotion) 0.dp else 64.dp).roundToPx() }

    Box(
        modifier = Modifier.fillMaxSize().background(DS.canvas),
        contentAlignment = Alignment.TopCenter,
    ) {
        AnimatedContent(
            targetState = step,
            transitionSpec = {
                // Glissement horizontal et fondu, comme l'onboarding principal, mais en
                // ease-out : l'écran se pose sans rebond.
                val forward = targetState.ordinal > initialState.ordinal
                val sign = if (forward != rtl) 1 else -1
                (slideInHorizontally(tween(380, easing = LinearOutSlowInEasing)) { sign * slidePx } +
                    fadeIn(tween(300))) togetherWith
                    (slideOutHorizontally(tween(380, easing = LinearOutSlowInEasing)) { -sign * slidePx } +
                        fadeOut(tween(200)))
            },
            label = "trainingObStep",
        ) { current ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(top = if (current == TrainingObStep.Paywall) 0.dp else TRAINING_OB_HEADER_HEIGHT),
            ) {
                when (current) {
                    TrainingObStep.Welcome -> WelcomeReadingPage(language) { step = TrainingObStep.Recall }
                    TrainingObStep.Recall -> ActiveRecallPage(language) { step = TrainingObStep.Algorithm }
                    TrainingObStep.Algorithm -> AlgorithmPage(language) {
                        onCompletedOnboarding()
                        step = TrainingObStep.Paywall
                    }
                    TrainingObStep.Paywall -> OnboardingPaywallFlow(
                        language = language,
                        storeViewModel = storeViewModel,
                        onDismiss = onClose,
                        // The package is only needed where a trial reminder is armed; Training just
                        // unlocks.
                        onPurchased = { onPurchased() },
                    )
                }
            }
        }

        // La barre de progression de l'onboarding, centrée ; rien sur le paywall.
        AnimatedVisibility(
            visible = step != TrainingObStep.Paywall,
            modifier = Modifier.align(Alignment.TopCenter),
            enter = fadeIn(tween(220)),
            exit = fadeOut(tween(160)),
        ) {
            Box(
                modifier = Modifier.fillMaxWidth().height(TRAINING_OB_HEADER_HEIGHT),
                contentAlignment = Alignment.Center,
            ) {
                DSProgressBar(
                    value = (step.ordinal + 1).coerceAtMost(TRAINING_OB_PAGES) / TRAINING_OB_PAGES.toFloat(),
                    modifier = Modifier.width(ONBOARDING_HEADER_BAR_WIDTH),
                )
            }
        }
    }
}

/**
 * Apparition d'un bloc une fois l'écran arrivé : fondu et légère montée, en ease-out, sans
 * rebond. [index] décale les blocs l'un après l'autre.
 */
@Composable
private fun Modifier.trainingReveal(index: Int): Modifier {
    val reduceMotion = rememberOnboardingReduceMotion()
    var shown by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(120L + index * 90L)
        shown = true
    }
    val progress by animateFloatAsState(
        targetValue = if (shown) 1f else 0f,
        animationSpec = tween(450, easing = LinearOutSlowInEasing),
        label = "trainingReveal",
    )
    val offsetPx = with(LocalDensity.current) { (if (reduceMotion) 0.dp else 12.dp).toPx() }
    return this.graphicsLayer {
        alpha = progress
        translationY = (1f - progress) * offsetPx
    }
}

/**
 * Écran 1 : l'illustration ronde et la phrase de bienvenue, en très grand, qui passe en gras
 * mot après mot. Pas de bouton : un appui n'importe où ouvre l'écran suivant.
 */
@Composable
private fun WelcomeReadingPage(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val words = remember(language) {
        StringStore.text(context, "training.ob.welcome.line", language)
            .split(' ')
            .filter { it.isNotBlank() }
    }
    var boldCount by remember { mutableIntStateOf(0) }
    var showHint by remember { mutableStateOf(false) }
    var advanced by remember { mutableStateOf(false) }
    LaunchedEffect(words) {
        delay(550)
        words.indices.forEach {
            boldCount = it + 1
            haptics.select()
            delay(340)
        }
        showHint = true
    }
    val hintAlpha by animateFloatAsState(if (showHint) 1f else 0f, tween(500), label = "trainingObHint")
    BoxWithConstraints(
        modifier = Modifier
            .fillMaxSize()
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
            ) {
                if (!advanced) {
                    advanced = true
                    haptics.confirm()
                    onContinue()
                }
            },
        contentAlignment = Alignment.Center,
    ) {
        val style = ov2CoreSentenceStyle(words, maxWidth - OV2Core.sideInset * 2)
        // L'illustration rétrécit, puis s'efface, quand la phrase a besoin de la hauteur.
        val artSize = OV2Core.artSize(base = 160.dp, available = maxHeight, reserved = 330.dp)
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = OV2Core.sideInset)
                .padding(bottom = 36.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(26.dp),
        ) {
            if (artSize > 0.dp) {
                OV2CoreIllustration(
                    art = R.drawable.training_poster,
                    size = artSize,
                    modifier = Modifier.trainingReveal(0),
                )
            }
            ProgressiveWords(words = words, boldCount = boldCount, style = style)
        }
        OV2CoreTapHint(
            text = StringStore.text(context, "explain.tapToClose", language),
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 28.dp)
                .alpha(hintAlpha),
        )
    }
}

/** Écran 2 : la mémorisation active, son graphe de rétention et la statistique. */
@Composable
private fun ActiveRecallPage(language: AppLanguage, onNext: () -> Unit) {
    val context = LocalContext.current
    // Le contenu défile et le bouton reste épinglé : sur un petit écran ou dans une langue
    // plus longue, le graphe, la légende et la statistique dépassent la hauteur disponible.
    OnboardingPage(
        contentArrangement = Arrangement.Top,
        footer = {
            OnboardingCta(
                text = StringStore.text(context, "training.ob.recall.cta", language),
                onClick = onNext,
            )
        },
    ) {
        Column(modifier = Modifier.fillMaxWidth().padding(horizontal = OV2End.side)) {
            Spacer(Modifier.height(OV2End.top))
            OV2EndHighlightTitle(
                text = OV2Core.marked(
                    context,
                    "training.ob.recall.title",
                    "training.ob.recall.titleHighlight",
                    language,
                ),
                modifier = Modifier.trainingReveal(0),
            )
            Spacer(Modifier.height(24.dp))
            RetentionGraph(language = language, modifier = Modifier.trainingReveal(1))
            Spacer(Modifier.height(14.dp))
            Text(
                text = buildAnnotatedString {
                    append(StringStore.text(context, "training.ob.recall.stat.prefix", language))
                    append(' ')
                    withStyle(SpanStyle(fontWeight = FontWeight.Bold, color = DS.accent)) {
                        append(StringStore.text(context, "training.ob.recall.stat.highlight", language))
                    }
                    append(' ')
                    append(StringStore.text(context, "training.ob.recall.stat.suffix", language))
                },
                style = OV2.subheadline.copy(lineHeight = 23.sp),
                modifier = Modifier
                    .fillMaxWidth()
                    .trainingReveal(2)
                    .ov2EndCard()
                    .padding(16.dp),
            )
            Spacer(Modifier.height(16.dp))
        }
    }
}

/** Écran 3 : l'algorithme de révision continue et ses « 5 min/jour ». */
@Composable
private fun AlgorithmPage(language: AppLanguage, onNext: () -> Unit) {
    val context = LocalContext.current
    OnboardingPage(
        contentArrangement = Arrangement.Top,
        footer = {
            OnboardingCta(
                text = StringStore.text(context, "training.ob.cta.last", language),
                onClick = onNext,
            )
        },
    ) {
        Column(modifier = Modifier.fillMaxWidth().padding(horizontal = OV2End.side)) {
            Spacer(Modifier.height(OV2End.top))
            OV2EndHighlightTitle(
                text = OV2Core.marked(
                    context,
                    "training.ob.algo.title",
                    "training.ob.algo.titleHighlight",
                    language,
                ),
                modifier = Modifier.trainingReveal(0),
            )
            Spacer(Modifier.height(12.dp))
            Text(
                text = StringStore.text(context, "training.ob.algo.body", language),
                style = OV2.body.copy(fontWeight = FontWeight.Normal, lineHeight = 24.sp),
                modifier = Modifier.fillMaxWidth().trainingReveal(1),
            )
            Spacer(Modifier.height(28.dp))
            // La carte teintée du style : le chiffre en bleu, sa promesse dessous.
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .trainingReveal(2)
                    .ov2EndCard(fill = DS.accentTint, border = OV2End.tintBorder)
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                Text(
                    text = StringStore.text(context, "training.ob.algo.highlight.value", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 30.sp,
                    lineHeight = 36.sp,
                    color = DS.accent,
                )
                Text(
                    text = StringStore.text(context, "training.ob.algo.highlight.label", language),
                    style = OV2.subheadline.copy(fontWeight = FontWeight.SemiBold, color = DS.ink),
                )
            }
            Spacer(Modifier.height(16.dp))
        }
    }
}

// Rétention (0 en bas, 1 en haut) en fonction du temps normalisé x ∈ [0, 1], comme sur iOS.
private fun sophiaRetention(x: Float): Float = 0.70f + 0.30f * exp(-1.35f * x)

private fun rereadRetention(x: Float): Float = 0.10f + 0.90f * exp(-3.1f * x)

/**
 * Le graphe de rétention, dans les couleurs de la courbe « 90 jours » de l'onboarding : les
 * deux courbes partent ensemble du sommet et se tracent de gauche à droite ; la sombre
 * (relecture) décroche vite, la bleue (Sophia) tient dans le temps.
 */
@Composable
private fun RetentionGraph(language: AppLanguage, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val reduceMotion = rememberOnboardingReduceMotion()
    val drawn = remember { Animatable(if (reduceMotion) 1f else 0f) }
    var showLegend by remember { mutableStateOf(reduceMotion) }
    LaunchedEffect(Unit) {
        if (!reduceMotion) {
            delay(400)
            drawn.animateTo(1f, tween(durationMillis = 1600, easing = FastOutSlowInEasing))
            showLegend = true
        }
    }
    val legendAlpha by animateFloatAsState(
        targetValue = if (showLegend) 1f else 0f,
        animationSpec = tween(500, easing = LinearOutSlowInEasing),
        label = "trainingObLegend",
    )
    val sophia = DS.accent
    val reread = DS.ink
    Column(
        modifier = modifier
            .fillMaxWidth()
            .ov2EndCard(fill = RetentionCardFill)
            .padding(start = 16.dp, top = 18.dp, end = 16.dp, bottom = 14.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Canvas(
            modifier = Modifier
                .fillMaxWidth()
                .height(170.dp)
                .clearAndSetSemantics { },
        ) {
            val w = size.width
            val h = size.height
            val padTop = 6.dp.toPx()
            val progress = drawn.value.coerceIn(0f, 1f)

            fun pointAt(x: Float, curve: (Float) -> Float): Offset =
                Offset(x * w, padTop + (h - padTop) * (1f - curve(x)))

            fun curvePath(curve: (Float) -> Float): Path {
                val path = Path()
                val steps = 60
                for (i in 0..steps) {
                    val point = pointAt(progress * i / steps, curve)
                    if (i == 0) path.moveTo(point.x, point.y) else path.lineTo(point.x, point.y)
                }
                return path
            }

            // Grille horizontale discrète ; la ligne du bas fait l'axe.
            for (i in 0..3) {
                val y = h * i / 3f
                drawLine(
                    color = if (i == 3) RetentionAxisColor else RetentionAxisColor.copy(alpha = 0.45f),
                    start = Offset(0f, y),
                    end = Offset(w, y),
                    strokeWidth = (if (i == 3) 1.5.dp else 1.dp).toPx(),
                )
            }

            if (progress > 0f) {
                // Aire sous la courbe bleue.
                val area = curvePath(::sophiaRetention)
                area.lineTo(progress * w, h)
                area.lineTo(0f, h)
                area.close()
                drawPath(
                    path = area,
                    brush = Brush.verticalGradient(listOf(sophia.copy(alpha = 0.16f), sophia.copy(alpha = 0f))),
                )
                drawPath(
                    path = curvePath(::rereadRetention),
                    color = reread,
                    style = Stroke(width = 3.5.dp.toPx(), cap = StrokeCap.Round, join = StrokeJoin.Round),
                )
                drawPath(
                    path = curvePath(::sophiaRetention),
                    color = sophia,
                    style = Stroke(width = 4.5.dp.toPx(), cap = StrokeCap.Round, join = StrokeJoin.Round),
                )
                // Points en tête de courbe.
                val rereadTip = pointAt(progress, ::rereadRetention)
                drawCircle(color = Color.White, radius = 5.5.dp.toPx(), center = rereadTip)
                drawCircle(color = reread, radius = 3.5.dp.toPx(), center = rereadTip)
                val sophiaTip = pointAt(progress, ::sophiaRetention)
                drawCircle(color = Color.White, radius = 5.5.dp.toPx(), center = sophiaTip)
                drawCircle(color = sophia, radius = 3.5.dp.toPx(), center = sophiaTip)
            }
        }
        Row(
            modifier = Modifier.fillMaxWidth().graphicsLayer { alpha = legendAlpha },
            horizontalArrangement = Arrangement.spacedBy(18.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            LegendDot(sophia, StringStore.text(context, "training.ob.recall.legend.sophia", language))
            LegendDot(reread, StringStore.text(context, "training.ob.recall.legend.reread", language))
        }
    }
}

@Composable
private fun RowScope.LegendDot(color: Color, label: String) {
    Row(
        modifier = Modifier.weight(1f, fill = false),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(7.dp),
    ) {
        Box(modifier = Modifier.size(9.dp).background(color, CircleShape))
        Text(
            text = label,
            style = OV2.caption,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}
