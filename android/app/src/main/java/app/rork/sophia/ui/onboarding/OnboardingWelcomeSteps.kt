package app.rork.sophia.ui.onboarding

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.StartOffset
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
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
import androidx.compose.foundation.layout.offset
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
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDirection
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import app.rork.sophia.data.AuthorStore
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.formatted
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.uppercaseInApp
import kotlinx.coroutines.delay

/**
 * The logo of the app on a soft halo, as on the welcome and mission pages of iOS.
 */
@Composable
private fun LogoWithHalo(logoSize: Dp, haloSizes: List<Dp>, haloScale: Float, modifier: Modifier = Modifier) {
    Box(modifier = modifier, contentAlignment = Alignment.Center) {
        haloSizes.forEachIndexed { i, size ->
            Box(
                modifier = Modifier
                    .size(size)
                    .graphicsLayer { scaleX = haloScale; scaleY = haloScale }
                    .background(OV2.accentSoft.copy(alpha = if (i == 0) 0.10f else 0.12f), CircleShape),
            )
        }
        AssetPicture(
            url = SOPHIA_LOGO,
            contentScale = androidx.compose.ui.layout.ContentScale.Fit,
            modifier = Modifier.size(logoSize),
        )
    }
}

// MARK: - Mission

/**
 * « Sophia is free to try »: the mission, and the team counting on the reader, right after
 * « Sophia will help you reach all your goals ». The logo, three sentences, the team's
 * signature with the professors' faces, one button.
 */
@Composable
internal fun MissionStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val portraits = remember { AuthorStore.all(context).mapNotNull { it.photoModel }.take(5) }
    var haloIn by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(100)
        haloIn = true
    }
    val halo by animateFloatAsState(
        targetValue = if (haloIn) 1.05f else 0.7f,
        animationSpec = spring(dampingRatio = 0.75f, stiffness = Spring.StiffnessVeryLow),
        label = "missionHalo",
    )

    OnboardingPage(
        contentArrangement = Arrangement.Top,
        footer = {
            OnboardingCta(StringStore.text(context, "common.continue", language), onContinue)
        },
    ) {
        Spacer(Modifier.height(72.dp))
        LogoWithHalo(
            logoSize = 84.dp,
            haloSizes = listOf(150.dp),
            haloScale = halo,
            modifier = Modifier.ov2Reveal(50),
        )
        Spacer(Modifier.height(26.dp))
        Text(
            text = StringStore.text(context, "onboardingV2.mission.title", language),
            style = OV2.title,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 28.dp).ov2Reveal(150),
        )
        Spacer(Modifier.height(18.dp))
        Text(
            text = StringStore.text(context, "onboardingV2.mission.body1", language),
            style = OV2.body.copy(color = OV2.ink, fontWeight = FontWeight.SemiBold),
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 32.dp).ov2Reveal(280),
        )
        Spacer(Modifier.height(14.dp))
        Text(
            text = StringStore.text(context, "onboardingV2.mission.body2", language),
            style = OV2.body,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 32.dp).ov2Reveal(400),
        )
        Spacer(Modifier.height(28.dp))
        Row(
            modifier = Modifier.ov2Reveal(550),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy((-10).dp)) {
                portraits.forEachIndexed { i, url ->
                    RoundPortrait(
                        url = url,
                        size = 34.dp,
                        ring = 2.dp,
                        modifier = Modifier.zIndex((portraits.size - i).toFloat()),
                    )
                }
            }
            Text(
                text = StringStore.text(context, "onboardingV2.mission.signature", language),
                style = OV2.subheadline.copy(fontWeight = FontWeight.SemiBold),
            )
        }
        Spacer(Modifier.height(24.dp))
    }
}

// MARK: - Welcome aboard

/** Offset from the logo's centre, size and tilt of each floating course picture. */
private data class FloatingSlot(val x: Dp, val y: Dp, val size: Dp, val rotation: Float)

private val FLOATING_SLOTS = listOf(
    FloatingSlot((-148).dp, (-60).dp, 44.dp, -8f),
    FloatingSlot(150.dp, (-50).dp, 40.dp, 7f),
    FloatingSlot((-128).dp, 46.dp, 38.dp, 5f),
    FloatingSlot(134.dp, 56.dp, 44.dp, -6f),
    FloatingSlot((-62).dp, (-126).dp, 42.dp, 6f),
    FloatingSlot(76.dp, (-130).dp, 46.dp, -5f),
)

private val FLOATING_COURSE_IDS = listOf(
    "course_42_pourquoi_reve_t_on",
    "course_149_la_joconde",
    "course_290_comment_les_etats_unis_ont_ils_gagne_la",
    "course_67_qu_est_ce_qu_un_trou_noir",
    "course_264_qui_a_vraiment_construit_les_pyramides",
    "course_150_la_nuit_etoilee_van_gogh",
)

/**
 * « Welcome aboard, {name}! » with confetti and course pictures drifting around the logo
 * (within its band: a text never sits on a picture), then the club's welcome and a button.
 */
@Composable
internal fun WelcomeAboardStep(
    language: AppLanguage,
    firstName: String,
    richMotion: Boolean,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    var logoIn by remember { mutableStateOf(false) }
    var badgeIn by remember { mutableStateOf(false) }
    var confetti by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        logoIn = true
        delay(350)
        confetti = true
        haptics.commit()
        delay(150)
        badgeIn = true
    }
    val logoProgress by animateFloatAsState(
        targetValue = if (logoIn) 1f else 0f,
        animationSpec = spring(dampingRatio = 0.85f, stiffness = Spring.StiffnessVeryLow),
        label = "aboardLogo",
    )
    val badgeProgress by animateFloatAsState(
        targetValue = if (badgeIn) 1f else 0f,
        animationSpec = spring(dampingRatio = 0.72f, stiffness = Spring.StiffnessMediumLow),
        label = "aboardBadge",
    )

    Box(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.weight(1f))
            Box(
                modifier = Modifier.graphicsLayer {
                    val s = 0.82f + 0.18f * logoProgress
                    scaleX = s
                    scaleY = s
                    alpha = logoProgress.coerceIn(0f, 1f)
                },
                contentAlignment = Alignment.Center,
            ) {
                FloatingCourseImages(animate = richMotion)
                LogoWithHalo(logoSize = 96.dp, haloSizes = listOf(200.dp, 136.dp), haloScale = 1f)
                CheckBadge(
                    size = 38.dp,
                    modifier = Modifier
                        .offset(x = 40.dp, y = 40.dp)
                        .graphicsLayer {
                            val s = 0.4f + 0.6f * badgeProgress
                            scaleX = s
                            scaleY = s
                            alpha = badgeProgress.coerceIn(0f, 1f)
                        },
                )
            }
            Spacer(Modifier.height(36.dp))
            Text(
                text = personalizedText(context, "onboardingV2.aboard.title", firstName, language),
                style = OV2.titleLarge,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 28.dp).ov2Reveal(450, 12.dp),
            )
            Spacer(Modifier.weight(1f))
            Text(
                text = StringStore.text(context, "onboardingV2.aboard.subtitle", language),
                style = OV2.body,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 32.dp)
                    .padding(bottom = 18.dp)
                    .ov2Reveal(750, 10.dp),
            )
            OnboardingCta(StringStore.text(context, "common.continue", language), onContinue)
        }
        if (confetti) {
            ConfettiBurst(
                colors = listOf(OV2.accent, OV2.accentSoft, OV2Pink, OV2.warm, OV2.success),
                pieceCount = if (richMotion) 70 else 35,
            )
        }
    }
}

/**
 * Six small course pictures around the logo, drifting gently in a loop. Placed from the
 * logo's centre and kept within its band.
 */
@Composable
private fun FloatingCourseImages(animate: Boolean) {
    var shown by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(250)
        shown = true
    }
    val alpha by animateFloatAsState(if (shown) 1f else 0f, tween(1400), label = "floatingIn")
    val transition = rememberInfiniteTransition(label = "floating")
    Box(modifier = Modifier.graphicsLayer { this.alpha = alpha }, contentAlignment = Alignment.Center) {
        FLOATING_SLOTS.forEachIndexed { i, slot ->
            val drift by transition.animateFloat(
                initialValue = -1f,
                targetValue = 1f,
                animationSpec = infiniteRepeatable(
                    animation = tween(3200 + i * 350),
                    repeatMode = RepeatMode.Reverse,
                    initialStartOffset = StartOffset(i * 300),
                ),
                label = "drift$i",
            )
            val d = if (animate) drift else 0f
            val shape = RoundedCornerShape(slot.size * 0.28f)
            CourseImage(
                courseId = FLOATING_COURSE_IDS[i],
                modifier = Modifier
                    .offset(x = slot.x, y = slot.y)
                    .graphicsLayer {
                        rotationZ = slot.rotation + d * 3f
                        translationY = -d * 9f * density
                        this.alpha = 0.72f
                    }
                    .size(slot.size)
                    .shadow(4.dp, shape, ambientColor = Color.Black.copy(alpha = 0.08f), spotColor = Color.Black.copy(alpha = 0.08f))
                    .clip(shape)
                    .border(1.5.dp, Color.White.copy(alpha = 0.8f), shape),
                maxEdgePx = 160,
                letterSize = 14.sp,
            )
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
            OnboardingCta(StringStore.text(context, "common.continue", language), onContinue)
        },
    ) {
        Spacer(Modifier.height(64.dp))
        Text(
            text = personalizedText(context, "onboardingV2.features.title", firstName, language),
            style = OV2.title,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 28.dp).ov2Reveal(50),
        )
        Spacer(Modifier.height(28.dp))
        FeatureRail(features = features, revealed = revealed)
        Spacer(Modifier.height(28.dp))
        LaurelBadge(size = 50.dp, tint = OV2.inkSecondary, modifier = Modifier.ov2Reveal(1100)) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(3.dp),
            ) {
                Icon(Icons.Filled.Shop, contentDescription = null, tint = OV2.ink, modifier = Modifier.size(18.dp))
                Text(
                    text = 4.8.formatted(language, 1) + " / 5",
                    // « 4.8 / 5 » reads left to right in every language; bidi would print « 5 / 4.8 ».
                    style = OV2.headline.copy(fontSize = 20.sp, fontWeight = FontWeight.ExtraBold, textDirection = TextDirection.Ltr),
                )
                Text(
                    text = StringStore.text(context, "onboardingV2.review.appStore", language).uppercaseInApp(),
                    style = OV2.caption.copy(fontSize = 11.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.2.sp),
                    maxLines = 1,
                )
            }
        }
        Spacer(Modifier.height(14.dp))
        StarRow(starSize = 22.dp, spacing = 4.dp, modifier = Modifier.ov2Reveal(1250))
        Spacer(Modifier.height(22.dp))
        Text(
            text = StringStore.text(context, "onboardingV2.features.noCommitment", language),
            style = OV2.headline.copy(fontSize = 20.sp),
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
                .background(DS.accentTint, RoundedCornerShape(24.dp)),
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
                        style = OV2.body.copy(color = OV2.ink, lineHeight = 20.sp),
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
        }
    }
}
