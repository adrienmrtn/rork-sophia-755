package app.rork.sophia.ui.training

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
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
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.onboarding.OnboardingCta
import app.rork.sophia.ui.paywall.OnboardingPaywallFlow
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.delay

private enum class TrainingObStep { Welcome, Recall, Algorithm, Paywall }

@Composable
fun TrainingOnboardingScreen(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    startAtPaywall: Boolean,
    onCompletedOnboarding: () -> Unit,
    onPurchased: () -> Unit,
    onClose: () -> Unit,
) {
    var step by remember {
        mutableStateOf(if (startAtPaywall) TrainingObStep.Paywall else TrainingObStep.Welcome)
    }

    Box(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
        when (step) {
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
                onPurchased = onPurchased,
            )
        }
        if (step != TrainingObStep.Paywall) {
            val index = when (step) {
                TrainingObStep.Welcome -> 0
                TrainingObStep.Recall -> 1
                TrainingObStep.Algorithm -> 2
                else -> 0
            }
            Row(
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .padding(top = 14.dp),
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                repeat(3) { i ->
                    Box(
                        modifier = Modifier
                            .size(if (i == index) 8.dp else 6.dp)
                            .background(
                                if (i == index) DS.accent else DS.hairline,
                                shape = androidx.compose.foundation.shape.CircleShape,
                            ),
                    )
                }
            }
        }
    }
}

@Composable
private fun WelcomeReadingPage(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val words = remember(language) {
        StringStore.text(context, "training.ob.welcome.line", language).split(' ')
    }
    var readIndex by remember { mutableIntStateOf(-1) }
    var showHint by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        words.indices.forEach { i ->
            delay(220)
            readIndex = i
        }
        delay(400)
        showHint = true
    }
    Box(
        modifier = Modifier
            .fillMaxSize()
            .clickable(onClick = onContinue)
            .padding(DS.Space.l),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = buildAnnotatedString {
                words.forEachIndexed { i, w ->
                    withStyle(
                        SpanStyle(
                            color = if (i <= readIndex) DS.ink else DS.inkTertiary,
                            fontWeight = if (i <= readIndex) FontWeight.SemiBold else FontWeight.Normal,
                        ),
                    ) {
                        append(w)
                        if (i != words.lastIndex) append(' ')
                    }
                }
            },
            style = SophiaTypography.titleLarge,
            textAlign = TextAlign.Center,
            lineHeight = 32.sp,
        )
        if (showHint) {
            Text(
                StringStore.text(context, "explain.tapToClose", language),
                style = SophiaTypography.labelMedium,
                color = DS.inkTertiary,
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 46.dp),
            )
        }
    }
}

@Composable
private fun ActiveRecallPage(language: AppLanguage, onNext: () -> Unit) {
    val context = LocalContext.current
    // SpaceBetween on a fixed-height column pushed the CTA off-screen as soon as the graph,
    // the legend and the stat sentence together exceeded the viewport — which they do on a
    // short screen and in the languages with longer copy. The page then had no way out.
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(DS.Space.l),
    ) {
        Column(modifier = Modifier.weight(1f).verticalScroll(rememberScrollState())) {
            Spacer(Modifier.height(48.dp))
            Text(
                StringStore.text(context, "training.ob.recall.title", language),
                style = SophiaTypography.titleLarge,
            )
            Spacer(Modifier.height(28.dp))
            RetentionGraph()
            Spacer(Modifier.height(16.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                LegendDot(DS.accent, StringStore.text(context, "training.ob.recall.legend.sophia", language))
                LegendDot(DS.danger, StringStore.text(context, "training.ob.recall.legend.reread", language))
            }
            Spacer(Modifier.height(20.dp))
            Text(
                buildAnnotatedString {
                    append(StringStore.text(context, "training.ob.recall.stat.prefix", language))
                    append(' ')
                    withStyle(SpanStyle(fontWeight = FontWeight.Bold, color = DS.accentSoft)) {
                        append(StringStore.text(context, "training.ob.recall.stat.highlight", language))
                    }
                    append(' ')
                    append(StringStore.text(context, "training.ob.recall.stat.suffix", language))
                },
                style = SophiaTypography.bodyMedium,
            )
            Spacer(Modifier.height(20.dp))
        }
        OnboardingCta(
            text = StringStore.text(context, "training.ob.recall.cta", language),
            onClick = onNext,
            horizontalInset = 0.dp,
            bottomInset = 0.dp,
        )
    }
}

@Composable
private fun AlgorithmPage(language: AppLanguage, onNext: () -> Unit) {
    val context = LocalContext.current
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(DS.Space.l),
    ) {
        Column(modifier = Modifier.weight(1f).verticalScroll(rememberScrollState())) {
            Spacer(Modifier.height(48.dp))
            Text(
                StringStore.text(context, "training.ob.algo.title", language),
                style = SophiaTypography.titleLarge,
            )
            Spacer(Modifier.height(16.dp))
            Text(
                StringStore.text(context, "training.ob.algo.body", language),
                style = SophiaTypography.bodyMedium,
            )
            Spacer(Modifier.height(28.dp))
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(DS.accentTint, DS.cardShape)
                    .padding(DS.Space.m),
            ) {
                Text(
                    StringStore.text(context, "training.ob.algo.highlight.value", language),
                    style = SophiaTypography.displayLarge,
                    color = DS.accentSoft,
                )
                Text(
                    StringStore.text(context, "training.ob.algo.highlight.label", language),
                    style = SophiaTypography.bodyMedium,
                )
            }
            Spacer(Modifier.height(20.dp))
        }
        OnboardingCta(
            text = StringStore.text(context, "training.ob.cta.last", language),
            onClick = onNext,
            horizontalInset = 0.dp,
            bottomInset = 0.dp,
        )
    }
}

@Composable
private fun RetentionGraph() {
    Canvas(
        modifier = Modifier
            .fillMaxWidth()
            .height(140.dp)
            .background(DS.surface, DS.cardShape)
            .padding(12.dp),
    ) {
        fun curve(decay: Float, color: Color) {
            val path = Path()
            val w = size.width
            val h = size.height
            path.moveTo(0f, h * 0.15f)
            for (i in 1..40) {
                val t = i / 40f
                val y = h * (0.15f + (1f - 0.15f) * (1f - kotlin.math.exp(-decay * t)))
                path.lineTo(w * t, y)
            }
            drawPath(path, color = color, style = Stroke(width = 4.dp.toPx(), cap = StrokeCap.Round))
        }
        curve(1.2f, DS.accent)
        curve(4.5f, DS.danger)
        drawLine(DS.hairline, Offset(0f, size.height), Offset(size.width, size.height), 2f)
    }
}

@Composable
private fun LegendDot(color: Color, label: String) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Box(modifier = Modifier.size(10.dp).background(color, androidx.compose.foundation.shape.CircleShape))
        Text(label, style = SophiaTypography.labelMedium)
    }
}
