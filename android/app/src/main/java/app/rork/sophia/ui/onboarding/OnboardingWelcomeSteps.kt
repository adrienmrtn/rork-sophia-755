package app.rork.sophia.ui.onboarding

import app.rork.sophia.ui.theme.DSLegacy
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Extension
import androidx.compose.material.icons.filled.Headphones
import androidx.compose.material.icons.filled.Science
import androidx.compose.material.icons.filled.Shop
import androidx.compose.material3.Icon
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDirection
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import app.rork.sophia.R
import app.rork.sophia.data.AuthorStore
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.formatted
import app.rork.sophia.ui.components.DSCheckBadge
import app.rork.sophia.ui.components.DSHighlightTitle
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.dsPopIn
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.uppercaseInApp
import kotlinx.coroutines.delay

// MARK: - Mission

/**
 * « Sophia is free to try »: the mission, and the team counting on the reader, right after
 * « Sophia will help you reach all your goals ».
 *
 * « Elevate arrondi » style: a large rounded illustration, « Sophia is free to try » as a blue
 * chip, the mission as the title (its heart in bold blue), the team's text in grey, then the
 * signature with the professors' faces, and one button.
 */
@Composable
internal fun MissionStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val portraits = remember { AuthorStore.all(context).mapNotNull { it.bundledPhotoModel }.take(5) }
    // « Our mission: to make learning **easy and accessible to everyone.** »
    val missionTitle = OV2Core.marked(
        context,
        titleKey = "onboardingV2.mission.body1",
        highlightKey = "elevateOnboardingCore.mission.leadHighlight",
        language = language,
    )
    // « Sophia is free to try », without its full stop: it is a label here.
    val trialChip = OV2Core.trimmingTrailing(StringStore.text(context, "onboardingV2.mission.title", language), ".。")

    OV2CorePage(
        footer = {
            OnboardingCta(StringStore.text(context, "common.continue", language), onContinue)
        },
    ) { available ->
        // The block sits in the middle when it fits, at the top and scrolling otherwise; the
        // illustration gives up some height on a short screen.
        val artHeight = (available - 340.dp).coerceIn(120.dp, 190.dp)
        Spacer(Modifier.weight(1f))
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = OV2Core.sideInset)
                .padding(top = OV2Core.topInset, bottom = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Image(
                painter = painterResource(R.drawable.creator_writing),
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .dsStagger(0)
                    .fillMaxWidth()
                    .height(artHeight)
                    .clip(RoundedCornerShape(24.dp))
                    .background(DS.accentTint),
            )
            Text(
                text = trialChip,
                style = OV2.caption.copy(fontWeight = FontWeight.Bold, color = DS.accent, letterSpacing = 0.4.sp),
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .dsStagger(1)
                    .background(DS.accentTint, RoundedCornerShape(14.dp))
                    .padding(horizontal = 14.dp, vertical = 5.dp),
            )
            DSHighlightTitle(
                text = missionTitle,
                modifier = Modifier
                    .dsStagger(2)
                    .fillMaxWidth()
                    .semantics { heading() },
                fontSize = 25.sp,
                lineHeight = 32.sp,
            )
            Text(
                text = StringStore.text(context, "onboardingV2.mission.body2", language),
                style = OV2.subheadline.copy(fontWeight = FontWeight.Normal, lineHeight = 23.sp, color = DS.inkSecondary),
                textAlign = TextAlign.Center,
                modifier = Modifier.dsStagger(3),
            )
            // The professors' faces overlapping, and « The Sophia team ».
            Row(
                modifier = Modifier.padding(top = 2.dp).dsStagger(4),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                if (portraits.isNotEmpty()) {
                    Row(
                        modifier = Modifier.clearAndSetSemantics { },
                        horizontalArrangement = Arrangement.spacedBy((-10).dp),
                    ) {
                        portraits.forEachIndexed { i, url ->
                            AssetPicture(
                                url = url,
                                modifier = Modifier
                                    .zIndex((portraits.size - i).toFloat())
                                    .size(34.dp)
                                    .clip(CircleShape)
                                    .background(DS.surface)
                                    .border(2.dp, DS.surface, CircleShape),
                            )
                        }
                    }
                }
                Text(
                    text = StringStore.text(context, "onboardingV2.mission.signature", language),
                    style = OV2.body.copy(color = DS.ink, fontWeight = FontWeight.Bold, fontStyle = FontStyle.Italic),
                )
            }
        }
        Spacer(Modifier.weight(1f))
    }
}

// MARK: - Welcome aboard

/**
 * « Welcome aboard, {name}! »: the trophy lands in a large circle with the green check of the
 * created account, confetti burst, then the club's welcome and a button.
 */
@Composable
internal fun WelcomeAboardStep(
    language: AppLanguage,
    firstName: String,
    richMotion: Boolean,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val reducedMotion = rememberOV2CoreReducedMotion()
    var confetti by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(350)
        confetti = !reducedMotion
        haptics.celebrate()
    }

    Box(modifier = Modifier.fillMaxSize()) {
        OV2CorePage(
            footer = {
                OnboardingCta(StringStore.text(context, "common.continue", language), onContinue)
            },
        ) { available ->
            // The medallion shrinks by itself on a short screen.
            val medallion = (available - 230.dp).coerceIn(120.dp, 240.dp)
            Spacer(Modifier.height(24.dp))
            Spacer(Modifier.weight(1f))
            AboardMedallion(size = medallion, animate = richMotion && !reducedMotion)
            Spacer(Modifier.height(24.dp))
            Spacer(Modifier.weight(1f))
            OV2CoreQuestionTitle(
                title = personalizedText(context, "onboardingV2.aboard.title", firstName, language),
                modifier = Modifier.ov2Reveal(400, 12.dp),
            )
            Text(
                text = StringStore.text(context, "onboardingV2.aboard.subtitle", language),
                style = ov2CoreSubtitleStyle.copy(fontSize = 15.sp, lineHeight = 22.sp),
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = OV2Core.sideInset)
                    .padding(top = 10.dp, bottom = 28.dp)
                    .ov2Reveal(600, 10.dp),
            )
        }
        if (confetti) {
            ConfettiBurst(
                colors = listOf(DS.accent, DS.accentTint, OV2Pink, DS.warm, DS.success),
                pieceCount = if (richMotion) 70 else 35,
            )
        }
    }
}

/**
 * The trophy in a large circle, the green check of the created account on its edge, and a
 * ripple widening behind it as it lands. [animate] lets it float gently afterwards.
 */
@Composable
private fun AboardMedallion(size: Dp, animate: Boolean) {
    var shown by remember { mutableStateOf(false) }
    val ripple = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        delay(50)
        shown = true
        delay(250)
        ripple.animateTo(1f, tween(durationMillis = 1100, easing = LinearOutSlowInEasing))
    }
    val landing by animateFloatAsState(if (shown) 1f else 0f, DSMotion.pop(), label = "aboardLanding")
    val drift by if (animate) {
        rememberInfiniteTransition(label = "aboardFloat").animateFloat(
            initialValue = -1f,
            targetValue = 1f,
            animationSpec = infiniteRepeatable(tween(2600, easing = FastOutSlowInEasing), RepeatMode.Reverse),
            label = "aboardDrift",
        )
    } else {
        remember { mutableStateOf(0f) }
    }
    Box(
        modifier = Modifier
            .size(size)
            .graphicsLayer {
                val s = 0.6f + 0.4f * landing
                scaleX = s
                scaleY = s
                alpha = landing.coerceIn(0f, 1f)
                translationY = drift * 5.dp.toPx()
            }
            .clearAndSetSemantics { },
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer {
                    val s = 1f + 0.28f * ripple.value
                    scaleX = s
                    scaleY = s
                    alpha = 1f - ripple.value
                }
                .border(6.dp, DS.accentTint, CircleShape),
        )
        Image(
            painter = painterResource(R.drawable.duel_trophy),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier
                .fillMaxSize()
                .clip(CircleShape)
                .background(DS.accentTint),
        )
        // The account is created: a green check, ringed in white, on the edge of the trophy.
        Box(
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(size * 0.058f)
                .dsPopIn(450)
                .size(44.dp)
                .background(DS.surface, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            DSCheckBadge(size = 38.dp, delayMillis = 520)
        }
    }
}

// MARK: - Learning doesn't have to be hard

private data class Feature(val icon: ImageVector, val color: Color, val text: String)

/**
 * Sophia's strengths on a vertical rail (the numbers come from the language's catalogue),
 * the store rating between two laurels and the stars, then « No commitment, cancel anytime ».
 *
 * iOS lists six strengths; the sixth is the app blocker, which Android does not have, so it
 * is left out here. The « 1,000+ reviews » line is left out too: it counts App Store
 * reviews, and on Google Play the app has fewer.
 */
@Composable
internal fun FeaturesStep(language: AppLanguage, firstName: String, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    var courseCount by remember(language) { mutableIntStateOf(0) }
    var questionCount by remember(language) { mutableIntStateOf(0) }
    var revealed by remember { mutableIntStateOf(0) }
    val features = listOf(
        Feature(Icons.Filled.Extension, Color(0xFFF07A3D), StringStore.text(context, "onboardingV2.features.row1", language)),
        Feature(
            Icons.AutoMirrored.Filled.MenuBook,
            Color(0xFF7A5CD6),
            StringStore.text(context, "onboardingV2.features.row2", language, courseCount.formatted(language)),
        ),
        Feature(
            Icons.Filled.EmojiEvents,
            Color(0xFF3DBAA8),
            StringStore.text(context, "onboardingV2.features.row3", language, questionCount.formatted(language)),
        ),
        Feature(Icons.Filled.Headphones, Color(0xFF4A7AF7), StringStore.text(context, "onboardingV2.features.row5", language)),
        Feature(Icons.Filled.Science, Color(0xFF4DB07A), StringStore.text(context, "onboardingV2.features.row4", language)),
    )
    LaunchedEffect(language) {
        val appContext = context.applicationContext
        // Rounded down: « 300+ », « 2,600+ ». Counted before the rows appear, so no row
        // ever shows « 0+ ».
        courseCount = ContentCatalog.summariesAsync(appContext, language).size / 10 * 10
        questionCount = ContentCatalog.quizQuestionCountAsync(appContext, language) / 100 * 100
        delay(250)
        repeat(features.size) { i ->
            revealed = i + 1
            haptics.selection()
            delay(140)
        }
    }

    OnboardingPage(
        contentArrangement = Arrangement.Top,
        footer = {
            OnboardingLegacyCta(StringStore.text(context, "common.continue", language), onContinue)
        },
    ) {
        Spacer(Modifier.height(64.dp))
        Text(
            text = personalizedText(context, "onboardingV2.features.title", firstName, language),
            style = OV2Legacy.title,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 28.dp).ov2Reveal(50),
        )
        Spacer(Modifier.height(28.dp))
        FeatureRail(features = features, revealed = revealed)
        Spacer(Modifier.height(28.dp))
        LaurelBadge(size = 50.dp, tint = OV2Legacy.inkSecondary, modifier = Modifier.ov2Reveal(1100)) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(3.dp),
            ) {
                Icon(Icons.Filled.Shop, contentDescription = null, tint = OV2Legacy.ink, modifier = Modifier.size(18.dp))
                Text(
                    text = 4.8.formatted(language, 1) + " / 5",
                    // « 4.8 / 5 » reads left to right in every language; bidi would print « 5 / 4.8 ».
                    style = OV2Legacy.headline.copy(fontSize = 20.sp, fontWeight = FontWeight.ExtraBold, textDirection = TextDirection.Ltr),
                )
                Text(
                    text = StringStore.text(context, "onboardingV2.review.appStore", language).uppercaseInApp(),
                    style = OV2Legacy.caption.copy(fontSize = 11.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.2.sp),
                    maxLines = 1,
                )
            }
        }
        Spacer(Modifier.height(14.dp))
        StarRow(starSize = 22.dp, spacing = 4.dp, modifier = Modifier.ov2Reveal(1250))
        Spacer(Modifier.height(22.dp))
        Text(
            text = StringStore.text(context, "onboardingV2.features.noCommitment", language),
            style = OV2Legacy.headline.copy(fontSize = 20.sp),
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 28.dp).ov2Reveal(1400),
        )
        Spacer(Modifier.height(24.dp))
    }
}

/**
 * The coloured badges on a light rail on the left, the texts aligned on the right; a fixed
 * row height keeps the two columns facing each other.
 */
@Composable
private fun FeatureRail(features: List<Feature>, revealed: Int) {
    val rowHeight = 52.dp
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 28.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Box(
            modifier = Modifier
                .width(48.dp)
                .height(rowHeight * features.size)
                .background(DSLegacy.accentTint, RoundedCornerShape(24.dp)),
        ) {
            Column {
                features.forEachIndexed { i, feature ->
                    val progress by animateFloatAsState(
                        targetValue = if (i < revealed) 1f else 0f,
                        animationSpec = spring(dampingRatio = 0.75f, stiffness = Spring.StiffnessMediumLow),
                        label = "featureBadge$i",
                    )
                    Box(
                        modifier = Modifier.size(48.dp, rowHeight),
                        contentAlignment = Alignment.Center,
                    ) {
                        Box(
                            modifier = Modifier
                                .size(36.dp)
                                .graphicsLayer {
                                    val s = 0.4f + 0.6f * progress
                                    scaleX = s
                                    scaleY = s
                                    alpha = progress.coerceIn(0f, 1f)
                                }
                                .background(feature.color, CircleShape),
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(feature.icon, contentDescription = null, tint = Color.White, modifier = Modifier.size(17.dp))
                        }
                    }
                }
            }
        }
        Column(modifier = Modifier.weight(1f)) {
            features.forEachIndexed { i, feature ->
                val progress by animateFloatAsState(
                    targetValue = if (i < revealed) 1f else 0f,
                    animationSpec = spring(dampingRatio = 0.75f, stiffness = Spring.StiffnessMediumLow),
                    label = "featureText$i",
                )
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(rowHeight)
                        .graphicsLayer {
                            alpha = progress.coerceIn(0f, 1f)
                            translationX = (1f - progress) * -10f * density
                        },
                    contentAlignment = Alignment.CenterStart,
                ) {
                    Text(
                        text = feature.text,
                        style = OV2Legacy.body.copy(color = OV2Legacy.ink, lineHeight = 20.sp),
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
        }
    }
}
