package app.rork.sophia.ui.paywall

import androidx.annotation.DrawableRes
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.PageSize
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.BiasAlignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.R
import app.rork.sophia.data.AuthorStore
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.formatted
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.DSOptionState
import app.rork.sophia.ui.components.dsHighlighted
import app.rork.sophia.ui.components.dsOptionCard
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.onboarding.AssetPicture
import app.rork.sophia.ui.onboarding.onboardingAssets
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.uppercaseInApp
import coil.compose.AsyncImage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * The shared blocks of the « Elevate arrondi » paywalls (onboarding, course, quiz, audio):
 * before/after header, benefit list, experts card, reviews carousel, plan cards, trial offer
 * card and the pinned CTA bar. The discount and training paywalls keep the legacy pieces of
 * `PaywallUi.kt` / `PaywallShowcase.kt`, which is why these live beside them, not in them.
 */

/** Ring of an unselected radio, a touch darker than the hairline. */
private val RadioRing = Color(0xFFC3CBD8)

/** One text of the paywalls: the app family, a size, a weight. */
@Composable
internal fun PwText(
    text: String,
    size: TextUnit,
    weight: FontWeight,
    modifier: Modifier = Modifier,
    color: Color = DS.ink,
    lineHeight: TextUnit = TextUnit.Unspecified,
    align: TextAlign? = null,
    maxLines: Int = Int.MAX_VALUE,
    letterSpacing: TextUnit = TextUnit.Unspecified,
    decoration: TextDecoration? = null,
) {
    Text(
        text = text,
        modifier = modifier,
        fontFamily = PlusJakartaSans,
        fontWeight = weight,
        fontSize = size,
        lineHeight = lineHeight,
        color = color,
        textAlign = align,
        maxLines = maxLines,
        overflow = TextOverflow.Ellipsis,
        letterSpacing = letterSpacing,
        textDecoration = decoration,
    )
}

// region Chrome: close, CTA, legal

internal enum class ElevateCloseStyle {
    /** A bare cross (end of onboarding). */
    Plain,

    /** A bordered white disc (reviews variant). */
    Bordered,

    /** A translucent white disc over an illustration (before/after header). */
    Floating,
}

/** Close button; [delayMillis] holds it back the way the legacy paywalls do. */
@Composable
internal fun ElevateCloseButton(
    language: AppLanguage,
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
    delayMillis: Int = 0,
    style: ElevateCloseStyle = ElevateCloseStyle.Plain,
) {
    val context = LocalContext.current
    var visible by remember { mutableStateOf(delayMillis == 0) }
    LaunchedEffect(delayMillis) {
        if (delayMillis > 0) {
            delay(delayMillis.toLong())
            visible = true
        }
    }
    AnimatedVisibility(visible = visible, enter = fadeIn(tween(400)), exit = fadeOut(), modifier = modifier) {
        Box(
            modifier = Modifier
                .size(44.dp)
                .pressable(onClick = onClose, scaleDown = 0.92f)
                .then(
                    when (style) {
                        ElevateCloseStyle.Plain -> Modifier
                        ElevateCloseStyle.Bordered -> Modifier
                            .clip(CircleShape)
                            .background(DS.surface)
                            .border(1.5.dp, DS.hairline, CircleShape)
                        ElevateCloseStyle.Floating -> Modifier
                            .clip(CircleShape)
                            .background(Color.White.copy(alpha = 0.9f))
                    },
                ),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                Icons.Filled.Close,
                contentDescription = StringStore.text(context, "common.close", language),
                tint = if (style == ElevateCloseStyle.Plain) DS.inkTertiary else DS.inkSecondary,
                modifier = Modifier.size(20.dp),
            )
        }
    }
}

/** The CTA of the design: a 56dp rounded rectangle, elastic press, a confirm tick on tap. */
@Composable
internal fun ElevateCtaButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    purchasing: Boolean = false,
    leadingIcon: ImageVector? = null,
) {
    val haptics = rememberHaptics()
    Row(
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = 56.dp)
            .pressable(
                onClick = {
                    haptics.confirm()
                    onClick()
                },
                enabled = !purchasing,
                scaleDown = 0.96f,
                haptic = false,
            )
            .clip(DS.controlShape)
            .background(DS.accent)
            .padding(vertical = 12.dp, horizontal = 14.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (purchasing) {
            CircularProgressIndicator(color = Color.White, strokeWidth = 2.dp, modifier = Modifier.size(20.dp))
        } else {
            if (leadingIcon != null) {
                Icon(leadingIcon, contentDescription = null, tint = Color.White, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(10.dp))
            }
            PwText(
                text = text,
                size = 17.sp,
                weight = FontWeight.SemiBold,
                color = Color.White,
                align = TextAlign.Center,
                maxLines = 2,
                letterSpacing = 0.4.sp,
            )
        }
    }
}

/** What the three legal links of a paywall do. */
internal class ElevateLegalActions(
    val onRestore: () -> Unit,
    val onTerms: () -> Unit,
    val onPrivacy: () -> Unit,
)

/** « Restaurer · Conditions · Confidentialité », small and grey (end of onboarding). */
@Composable
internal fun ElevateLegalDots(language: AppLanguage, actions: ElevateLegalActions, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    Row(
        modifier = modifier.fillMaxWidth().padding(bottom = 4.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        listOf(
            "paywall.restore" to actions.onRestore,
            "paywall.terms" to actions.onTerms,
            "paywall.privacy" to actions.onPrivacy,
        ).forEachIndexed { index, (key, action) ->
            if (index > 0) PwText("·", 11.sp, FontWeight.Medium, color = DS.inkTertiary)
            PwText(
                text = StringStore.text(context, key, language),
                size = 11.sp,
                weight = FontWeight.Medium,
                color = DS.inkTertiary,
                align = TextAlign.Center,
                maxLines = 2,
                modifier = Modifier
                    .weight(1f, fill = false)
                    .pressable(onClick = action, haptic = false)
                    .padding(horizontal = 5.dp, vertical = 12.dp),
            )
        }
    }
}

/** Three underlined links, in the order given, spread across the width or grouped in the middle. */
@Composable
internal fun ElevateLegalLinks(
    language: AppLanguage,
    actions: ElevateLegalActions,
    modifier: Modifier = Modifier,
    /** `paywall.terms`, `paywall.restore`, `paywall.privacy` in the order of the mock-up. */
    order: List<String> = listOf("paywall.terms", "paywall.restore", "paywall.privacy"),
    spread: Boolean = true,
) {
    val context = LocalContext.current
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = if (spread) Arrangement.SpaceAround else Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        order.forEach { key ->
            val action = when (key) {
                "paywall.restore" -> actions.onRestore
                "paywall.terms" -> actions.onTerms
                else -> actions.onPrivacy
            }
            PwText(
                text = StringStore.text(context, key, language),
                size = 12.sp,
                weight = FontWeight.Normal,
                color = DS.inkSecondary,
                align = TextAlign.Center,
                maxLines = 2,
                decoration = TextDecoration.Underline,
                modifier = Modifier
                    .weight(1f, fill = false)
                    .pressable(onClick = action, haptic = false)
                    .padding(horizontal = 6.dp, vertical = 12.dp),
            )
        }
    }
}

/**
 * The bar pinned under the scrolling pitch: a hairline, the purchase state, the CTA, the
 * price lines and, when [legal] is given, the legal links.
 */
@Composable
internal fun ElevateBottomBar(
    ctaText: String,
    onPurchase: () -> Unit,
    purchasing: Boolean,
    error: String?,
    notice: String?,
    modifier: Modifier = Modifier,
    ctaIcon: ImageVector? = null,
    lines: List<String> = emptyList(),
    linesWeight: FontWeight = FontWeight.Normal,
    legal: (@Composable () -> Unit)? = null,
) {
    Column(modifier = modifier.fillMaxWidth().background(DS.canvas)) {
        HorizontalDivider(color = DS.hairline, thickness = 1.dp)
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .padding(top = 12.dp, bottom = if (legal == null) 16.dp else 0.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            if (error != null) ElevateNote(error, error = true)
            // A pending Play payment is good news waiting on a bank, not a failure.
            if (notice != null) ElevateNote(notice, error = false)
            ElevateCtaButton(text = ctaText, onClick = onPurchase, purchasing = purchasing, leadingIcon = ctaIcon)
            if (lines.isNotEmpty()) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    lines.forEach { line ->
                        PwText(
                            text = line,
                            size = 13.sp,
                            weight = linesWeight,
                            color = DS.inkSecondary,
                            lineHeight = 19.sp,
                            align = TextAlign.Center,
                        )
                    }
                }
            }
        }
        if (legal != null) {
            Box(modifier = Modifier.padding(horizontal = 20.dp).padding(bottom = 6.dp)) { legal() }
        }
    }
}

/** A purchase error (red) or a pending-payment notice (blue), in the current tokens. */
@Composable
internal fun ElevateNote(message: String, error: Boolean) {
    PwText(
        text = message,
        size = 12.sp,
        weight = FontWeight.Medium,
        color = if (error) DS.danger else DS.accent,
        align = TextAlign.Center,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(if (error) DS.dangerTint else DS.accentTint)
            .padding(horizontal = 12.dp, vertical = 10.dp),
    )
}

// endregion

// region Before / after header

/** Greyscale, darkened: the « before » half of the header. */
private val BeforeFilter: ColorFilter = run {
    val k = 0.72f
    val r = 0.213f * k
    val g = 0.715f * k
    val b = 0.072f * k
    ColorFilter.colorMatrix(
        ColorMatrix(
            floatArrayOf(
                r, g, b, 0f, 0f,
                r, g, b, 0f, 0f,
                r, g, b, 0f, 0f,
                0f, 0f, 0f, 1f, 0f,
            ),
        ),
    )
}

/**
 * The header of the « bonhomme » paywalls: the grey « before » picture on the left, cut by a
 * large rounded corner over the coloured « after » picture, each with its label. Drawn left to
 * right in every language (it is one illustration); the labels keep the reading direction.
 */
@Composable
internal fun ElevateBeforeAfterHeader(
    @DrawableRes before: Int,
    @DrawableRes after: Int,
    beforeLabel: String,
    modifier: Modifier = Modifier,
    afterLabel: @Composable RowScope.() -> Unit,
) {
    val direction = LocalLayoutDirection.current
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
        BoxWithConstraints(modifier = modifier.fillMaxWidth()) {
            val fullWidth = maxWidth
            val scale = fullWidth / 390.dp
            val height = 268.dp * scale
            val beforeWidth = 208.dp * scale
            val shape = RoundedCornerShape(bottomEnd = 90.dp * scale)
            Box(modifier = Modifier.fillMaxWidth().height(height).clipToBounds().background(DS.canvas)) {
                Image(
                    painter = painterResource(after),
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    alignment = BiasAlignment(0f, -0.8f),
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .width(fullWidth - beforeWidth + 28.dp * scale)
                        .fillMaxHeight(),
                )
                // The white rim that separates the two pictures.
                Box(
                    modifier = Modifier
                        .offset(x = 6.dp * scale)
                        .size(beforeWidth, height)
                        .background(DS.canvas, shape),
                )
                Image(
                    painter = painterResource(before),
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    alignment = BiasAlignment(0f, -0.7f),
                    colorFilter = BeforeFilter,
                    modifier = Modifier.size(beforeWidth, height).clip(shape),
                )
                CompositionLocalProvider(LocalLayoutDirection provides direction) {
                    PwText(
                        text = beforeLabel,
                        size = 12.sp,
                        weight = FontWeight.Bold,
                        color = Color(0xFFDADDE2),
                        maxLines = 1,
                        modifier = Modifier
                            .align(Alignment.BottomStart)
                            .padding(14.dp)
                            .widthIn(max = beforeWidth - 28.dp)
                            .clip(CircleShape)
                            .background(Color(0xB822262E))
                            .padding(horizontal = 10.dp, vertical = 5.dp),
                    )
                    Row(
                        modifier = Modifier
                            .align(Alignment.BottomEnd)
                            .padding(14.dp)
                            .widthIn(max = fullWidth - beforeWidth - 20.dp)
                            .clip(CircleShape)
                            .background(Color.White)
                            .padding(horizontal = 10.dp, vertical = 5.dp),
                        horizontalArrangement = Arrangement.spacedBy(5.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        content = afterLabel,
                    )
                }
            }
        }
    }
}

/** A label of the « after » pill: bold blue, one line. */
@Composable
internal fun ElevateAfterLabel(text: String) {
    PwText(text = text, size = 12.sp, weight = FontWeight.Bold, color = Color(0xFF2E62C4), maxLines = 1)
}

/** « Avec [logo Sophia] »: the `%@` of the string marks where the logo goes. */
@Composable
internal fun ElevateWithLogoLabel(template: String) {
    val parts = template.split("%@", limit = 2)
    val prefix = parts.first().trim()
    val suffix = parts.getOrNull(1).orEmpty().trim()
    if (prefix.isNotEmpty()) ElevateAfterLabel(prefix)
    Image(
        painter = painterResource(R.drawable.sophia_mark),
        contentDescription = "Sophia",
        modifier = Modifier.height(14.dp),
        contentScale = ContentScale.FillHeight,
    )
    if (suffix.isNotEmpty()) ElevateAfterLabel(suffix)
}

// endregion

// region Titles and lists

/** The title of a paywall: medium weight, the `**marked**` passage in bold blue. */
@Composable
internal fun ElevatePaywallTitle(
    text: String,
    modifier: Modifier = Modifier,
    fontSize: TextUnit = 27.sp,
    lineHeight: TextUnit = 32.sp,
    textAlign: TextAlign = TextAlign.Center,
) {
    Text(
        text = dsHighlighted(text, DS.accent, FontWeight.Bold),
        modifier = modifier,
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.Medium,
        fontSize = fontSize,
        lineHeight = lineHeight,
        letterSpacing = 0.2.sp,
        color = DS.ink,
        textAlign = textAlign,
    )
}

/** A section heading inside a paywall (« Choisis ta formule », « Ta mémoire, ça s'entraîne »). */
@Composable
internal fun ElevateSectionTitle(
    text: String,
    modifier: Modifier = Modifier,
    size: TextUnit = 20.sp,
    align: TextAlign = TextAlign.Center,
) {
    PwText(text = text, size = size, weight = FontWeight.SemiBold, align = align, lineHeight = size * 1.25f, modifier = modifier)
}

/**
 * What PRO unlocks, one line per benefit with its emoji. « Toutes les matières débloquées »
 * is left out: free readers already have every subject.
 */
@Composable
internal fun ElevateFeatureList(language: AppLanguage, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    Column(modifier = modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        listOf(
            "📚" to "paywall.elevate.common.feature.courses",
            "🧠" to "paywall.elevate.common.feature.quiz",
            "🎧" to "paywall.elevate.common.feature.audio",
        ).forEach { (emoji, key) ->
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(
                    text = emoji,
                    fontSize = 22.sp,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.width(30.dp).clearAndSetSemantics { },
                )
                Text(
                    text = dsHighlighted(StringStore.text(context, key, language), DS.ink, FontWeight.Bold),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Normal,
                    fontSize = 15.sp,
                    lineHeight = 20.sp,
                    color = DS.ink,
                    modifier = Modifier.weight(1f),
                )
            }
        }
    }
}

/** An icon in a tinted tile, a bold title and a grey line under it. */
@Composable
internal fun ElevateIconRow(
    icon: ImageVector,
    title: String,
    body: String,
    modifier: Modifier = Modifier,
    verticalAlignment: Alignment.Vertical = Alignment.Top,
) {
    Row(modifier = modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = verticalAlignment) {
        Box(
            modifier = Modifier.size(40.dp).background(DS.accentTint, RoundedCornerShape(12.dp)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(icon, contentDescription = null, tint = DS.accent, modifier = Modifier.size(20.dp))
        }
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            PwText(title, 15.sp, FontWeight.Bold, lineHeight = 20.sp)
            PwText(body, 13.sp, FontWeight.Normal, color = DS.inkSecondary, lineHeight = 18.sp)
        }
    }
}

// endregion

// region Experts

private class ExpertsData(val photos: List<String>, val institutions: String)

/**
 * « Écrits par des experts »: the illustration, then the portraits and institutions of real
 * authors of the catalogue. With no author photo the card keeps the picture and the title.
 */
@Composable
internal fun ElevateExpertsCard(language: AppLanguage, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val experts by produceState<ExpertsData?>(initialValue = null) {
        value = withContext(Dispatchers.IO) {
            runCatching {
                val withPhoto = AuthorStore.all(context.applicationContext)
                    .filter { it.photoModel != null && !it.institution.isNullOrBlank() }
                    .distinctBy { it.institution!!.trim() }
                    .take(5)
                val names = withPhoto.map { it.institution!!.trim() }.take(4)
                ExpertsData(
                    photos = withPhoto.mapNotNull { it.photoModel },
                    institutions = if (names.isEmpty()) "" else names.joinToString(", ") + "…",
                )
            }.getOrNull()
        }
    }
    Column(modifier = modifier.fillMaxWidth().sophiaCard()) {
        Image(
            painter = painterResource(R.drawable.pw_experts_group),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxWidth().aspectRatio(4f / 3f),
        )
        Column(
            modifier = Modifier.padding(start = 18.dp, end = 18.dp, top = 18.dp, bottom = 20.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            PwText(
                text = StringStore.text(context, "paywall.elevate.common.experts.title", language),
                size = 22.sp,
                weight = FontWeight.SemiBold,
                lineHeight = 27.sp,
            )
            val data = experts
            if (data != null && data.photos.isNotEmpty()) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Row(horizontalArrangement = Arrangement.spacedBy((-10).dp)) {
                        data.photos.forEach { photo ->
                            AsyncImage(
                                model = photo,
                                contentDescription = null,
                                contentScale = ContentScale.Crop,
                                alignment = BiasAlignment(0f, -0.5f),
                                modifier = Modifier
                                    .size(38.dp)
                                    .clip(CircleShape)
                                    .background(DS.surfaceMuted)
                                    .border(2.dp, DS.surface, CircleShape),
                            )
                        }
                    }
                    if (data.institutions.isNotEmpty()) {
                        PwText(
                            text = data.institutions,
                            size = 12.sp,
                            weight = FontWeight.SemiBold,
                            color = DS.inkSecondary,
                            lineHeight = 16.sp,
                            maxLines = 3,
                            modifier = Modifier.weight(1f),
                        )
                    }
                }
            }
        }
    }
}

// endregion

// region Reviews

private class PaywallReview(val quote: String, val author: String, val avatar: String?)

/**
 * « Ils lisent avec Sophia »: the title, the store rating, then the app's own reviews
 * (`onboardingV2.review.*` and their portraits) in a carousel with dots and arrows.
 * Lays itself out edge to edge: give it the full width, not a padded column.
 */
@Composable
internal fun ElevateReviewsBlock(language: AppLanguage, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val reviews = remember(language) {
        val avatars = onboardingAssets(context, "review_avatar_")
        (1..5).map { i ->
            PaywallReview(
                quote = StringStore.text(context, "onboardingV2.review.t$i.quote", language),
                author = StringStore.text(context, "onboardingV2.review.t$i.author", language),
                avatar = avatars.firstOrNull { it.endsWith("review_avatar_$i.jpg") || it.endsWith("review_avatar_$i.png") },
            )
        }
    }
    val pager = rememberPagerState { reviews.size }
    val scope = rememberCoroutineScope()
    val haptics = rememberHaptics()
    fun go(page: Int) {
        haptics.select()
        scope.launch { pager.animateScrollToPage(page.mod(reviews.size), animationSpec = DSMotion.reveal()) }
    }

    Column(modifier = modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            PwText(
                text = StringStore.text(context, "paywall.elevate.common.reviews.title", language),
                size = 18.sp,
                weight = FontWeight.SemiBold,
                align = TextAlign.Center,
            )
            Row(
                modifier = Modifier.semantics(mergeDescendants = true) { },
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                    repeat(5) {
                        Icon(Icons.Filled.Star, contentDescription = null, tint = DS.warm, modifier = Modifier.size(16.dp))
                    }
                }
                PwText(
                    // The decimal separator of the reading language: « 4,8 » in French, « 4.8 » in English.
                    text = 4.8.formatted(language, 1) + " " + StringStore.text(context, "paywall.quiz.rating", language),
                    size = 13.sp,
                    weight = FontWeight.Bold,
                    color = DS.inkSecondary,
                )
            }
        }
        BoxWithConstraints(modifier = Modifier.fillMaxWidth()) {
            val pageWidth = (maxWidth - 100.dp).coerceIn(220.dp, 320.dp)
            HorizontalPager(
                state = pager,
                pageSize = PageSize.Fixed(pageWidth),
                pageSpacing = 12.dp,
                contentPadding = PaddingValues(start = 20.dp, end = (maxWidth - pageWidth - 20.dp).coerceAtLeast(20.dp)),
                verticalAlignment = Alignment.Top,
                modifier = Modifier.fillMaxWidth().padding(top = 4.dp, bottom = 6.dp),
            ) { index ->
                val review = reviews[index]
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = 150.dp)
                        .sophiaCard()
                        .padding(18.dp)
                        .semantics(mergeDescendants = true) { },
                    verticalArrangement = Arrangement.SpaceBetween,
                ) {
                    PwText(
                        text = "« ${review.quote} »",
                        size = 15.sp,
                        weight = FontWeight.Medium,
                        lineHeight = 22.sp,
                    )
                    Row(
                        modifier = Modifier.padding(top = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        if (review.avatar != null) {
                            AssetPicture(url = review.avatar, modifier = Modifier.size(36.dp).clip(CircleShape))
                        }
                        PwText(review.author, 13.sp, FontWeight.Bold, color = DS.inkSecondary, modifier = Modifier.weight(1f))
                    }
                }
            }
        }
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Row(
                modifier = Modifier.clearAndSetSemantics { },
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                reviews.indices.forEach { i ->
                    val current = pager.currentPage == i
                    val width by animateDpAsState(if (current) 20.dp else 8.dp, DSMotion.snappy(), label = "reviewDot")
                    val color by animateColorAsState(if (current) DS.accent else RadioRing, DSMotion.snappy(), label = "reviewDotColor")
                    Box(
                        modifier = Modifier
                            .pressable(onClick = { go(i) }, haptic = false)
                            .padding(vertical = 18.dp)
                            .size(width = width, height = 8.dp)
                            .background(color, CircleShape),
                    )
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf(
                    Icons.AutoMirrored.Filled.KeyboardArrowLeft to -1,
                    Icons.AutoMirrored.Filled.KeyboardArrowRight to 1,
                ).forEach { (icon, step) ->
                    Box(
                        modifier = Modifier
                            .size(44.dp)
                            .pressable(onClick = { go(pager.currentPage + step) }, scaleDown = 0.92f, haptic = false)
                            .clip(CircleShape)
                            .background(DS.surface)
                            .border(1.5.dp, DS.hairline, CircleShape)
                            .clearAndSetSemantics { },
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(icon, contentDescription = null, tint = DS.accent, modifier = Modifier.size(22.dp))
                    }
                }
            }
        }
    }
}

// endregion

// region Plans

internal enum class ElevatePlanStyle {
    /** A coloured band on top, a check radio, the price per week on the right (bonhomme paywalls). */
    Banded,

    /** A ring radio, the price over its unit on the right, the saving in a floating pill (reviews variant). */
    Radio,

    /** No radio: name and billing on the left, price and trial on the right (end of onboarding). */
    Plain,
}

/**
 * A plan card of the design: 1.5dp border and a bottom edge instead of a shadow, pale blue
 * with a blue border once chosen. The selection springs and ticks.
 */
@Composable
internal fun ElevatePlanCard(
    style: ElevatePlanStyle,
    selected: Boolean,
    onClick: () -> Unit,
    name: String,
    subtitle: String,
    price: String,
    modifier: Modifier = Modifier,
    /** The unit of [price] (« / semaine »), beside it or under it depending on the style. */
    priceUnit: String = "",
    /** Banded: the text of the band. Radio and Plain: the floating « Économise … » pill. */
    badge: String? = null,
    /** Plain: « 3 jours offerts » under the price. */
    trialBadge: String? = null,
) {
    val haptics = rememberHaptics()
    val scale by animateFloatAsState(if (selected) 1f else 0.985f, DSMotion.snappy(), label = "planScale")
    Box(modifier = modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .semantics(mergeDescendants = true) {
                    this.selected = selected
                    role = Role.RadioButton
                }
                .pressable(
                    onClick = {
                        if (!selected) haptics.select()
                        onClick()
                    },
                    scaleDown = 0.98f,
                    haptic = false,
                )
                .dsOptionCard(if (selected) DSOptionState.Selected else DSOptionState.Idle),
        ) {
            if (style == ElevatePlanStyle.Banded && badge != null) {
                val bandFill by animateColorAsState(if (selected) DS.accent else DS.hairline, DSMotion.snappy(), label = "band")
                val bandInk by animateColorAsState(if (selected) Color.White else DS.inkSecondary, DSMotion.snappy(), label = "bandInk")
                PwText(
                    text = badge.uppercaseInApp(),
                    size = 11.sp,
                    weight = FontWeight.Bold,
                    color = bandInk,
                    align = TextAlign.Center,
                    letterSpacing = 0.9.sp,
                    maxLines = 1,
                    modifier = Modifier.fillMaxWidth().background(bandFill).padding(horizontal = 12.dp, vertical = 6.dp),
                )
            }
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = if (style == ElevatePlanStyle.Radio) 73.dp else 0.dp)
                    .padding(
                        horizontal = if (style == ElevatePlanStyle.Radio) 18.dp else 16.dp,
                        vertical = if (style == ElevatePlanStyle.Banded) 13.dp else 16.dp,
                    )
                    .scale(scale),
                horizontalArrangement = Arrangement.spacedBy(if (style == ElevatePlanStyle.Plain) 12.dp else 14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                when (style) {
                    ElevatePlanStyle.Banded -> CheckRadio(selected)
                    ElevatePlanStyle.Radio -> RingRadio(selected)
                    ElevatePlanStyle.Plain -> Unit
                }
                Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    PwText(name, if (style == ElevatePlanStyle.Radio) 16.sp else 17.sp, FontWeight.Bold)
                    if (subtitle.isNotEmpty()) {
                        PwText(
                            text = subtitle,
                            size = if (style == ElevatePlanStyle.Plain) 12.sp else 13.sp,
                            weight = if (style == ElevatePlanStyle.Plain) FontWeight.Medium else FontWeight.Normal,
                            color = DS.inkSecondary,
                        )
                    }
                }
                when (style) {
                    ElevatePlanStyle.Banded -> Text(
                        text = androidx.compose.ui.text.buildAnnotatedString {
                            pushStyle(androidx.compose.ui.text.SpanStyle(color = DS.ink, fontWeight = FontWeight.Bold, fontSize = 16.sp))
                            append(price)
                            pop()
                            if (priceUnit.isNotEmpty()) append(" $priceUnit")
                        },
                        fontFamily = PlusJakartaSans,
                        fontSize = 13.sp,
                        color = DS.inkSecondary,
                        textAlign = TextAlign.End,
                        modifier = Modifier.widthIn(max = 170.dp),
                    )
                    ElevatePlanStyle.Radio -> Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        PwText(price, 18.sp, FontWeight.Bold, maxLines = 1)
                        if (priceUnit.isNotEmpty()) PwText(priceUnit, 12.sp, FontWeight.Normal, color = DS.inkSecondary, maxLines = 1)
                    }
                    ElevatePlanStyle.Plain -> Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(3.dp)) {
                        PwText(
                            text = if (priceUnit.isEmpty()) price else "$price $priceUnit",
                            size = 17.sp,
                            weight = FontWeight.Bold,
                            align = TextAlign.End,
                            modifier = Modifier.widthIn(max = 190.dp),
                        )
                        if (trialBadge != null) PwText(trialBadge, 11.sp, FontWeight.Bold, color = DS.success)
                    }
                }
            }
        }
        if (style != ElevatePlanStyle.Banded && badge != null) {
            PwText(
                text = badge,
                size = if (style == ElevatePlanStyle.Radio) 12.sp else 11.sp,
                weight = FontWeight.Bold,
                color = Color.White,
                maxLines = 1,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(end = if (style == ElevatePlanStyle.Radio) 16.dp else 12.dp)
                    .offset(y = (-11).dp)
                    .clip(if (style == ElevatePlanStyle.Radio) CircleShape else RoundedCornerShape(12.dp))
                    .background(DS.accent)
                    .padding(horizontal = if (style == ElevatePlanStyle.Radio) 10.dp else 8.dp, vertical = 4.dp),
            )
        }
    }
}

@Composable
private fun CheckRadio(selected: Boolean) {
    val fill by animateColorAsState(if (selected) DS.accent else DS.surface, DSMotion.snappy(), label = "radioFill")
    val pop by animateFloatAsState(if (selected) 1f else 0f, DSMotion.pop(), label = "radioCheck")
    Box(
        modifier = Modifier
            .size(24.dp)
            .background(fill, CircleShape)
            .then(if (selected) Modifier else Modifier.border(2.dp, RadioRing, CircleShape)),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            Icons.Filled.Check,
            contentDescription = null,
            tint = Color.White,
            modifier = Modifier.size(15.dp).scale(pop.coerceIn(0f, 1.3f)),
        )
    }
}

@Composable
private fun RingRadio(selected: Boolean) {
    val ring by animateColorAsState(if (selected) DS.accent else RadioRing, DSMotion.snappy(), label = "ring")
    val pop by animateFloatAsState(if (selected) 1f else 0f, DSMotion.pop(), label = "ringDot")
    Box(
        modifier = Modifier.size(24.dp).border(2.dp, ring, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier
                .size(12.dp)
                .scale(pop.coerceIn(0f, 1.3f))
                .background(DS.accent, CircleShape),
        )
    }
}

/**
 * « Offre spéciale »: the free trial of the chosen plan, tied to the plan cards by a small
 * « + ». Only shown when the store really serves a trial.
 */
@Composable
internal fun ElevateTrialOfferCard(badge: String, title: String, body: String, modifier: Modifier = Modifier) {
    Box(modifier = modifier.fillMaxWidth().padding(top = 15.dp)) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .sophiaCard()
                .padding(start = 16.dp, end = 14.dp, top = 18.dp, bottom = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                PwText(
                    text = badge.uppercaseInApp(),
                    size = 11.sp,
                    weight = FontWeight.Bold,
                    letterSpacing = 0.55.sp,
                    maxLines = 1,
                    modifier = Modifier.background(DS.warm, CircleShape).padding(horizontal = 10.dp, vertical = 4.dp),
                )
                PwText(title, 16.sp, FontWeight.Bold, lineHeight = 21.sp)
                PwText(body, 13.sp, FontWeight.Normal, color = DS.inkSecondary, lineHeight = 18.sp)
            }
            Image(
                painter = painterResource(R.drawable.pw_offer_key),
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.size(68.dp).rotate(4f).clip(RoundedCornerShape(16.dp)),
            )
        }
        Box(
            modifier = Modifier
                .align(Alignment.TopCenter)
                .offset(y = (-15).dp)
                .size(28.dp)
                .background(DS.surface, CircleShape)
                .border(1.5.dp, DS.hairline, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.Add, contentDescription = null, tint = DS.inkSecondary, modifier = Modifier.size(15.dp))
        }
    }
}

// endregion

// region Comparison table (end of onboarding)

/**
 * The FREE / PRO table in the current tokens: a bordered card with a bottom edge and no
 * shadow, the PRO column on a pale blue band. Same rows and same reading as the legacy
 * [ComparisonTable], which the discount-era screens keep.
 */
@Composable
internal fun ElevateComparisonTable(
    features: List<ComparisonFeature>,
    freeLabel: String,
    proLabel: String,
    modifier: Modifier = Modifier,
) {
    val columnWidth = 72.dp
    Box(modifier = modifier.fillMaxWidth().sophiaCard()) {
        Box(
            modifier = Modifier
                .matchParentSize(),
        ) {
            Row(modifier = Modifier.align(Alignment.CenterEnd).width(columnWidth).fillMaxHeight()) {
                Box(Modifier.width(1.dp).fillMaxHeight().background(DS.accent.copy(alpha = 0.25f)))
                Box(Modifier.weight(1f).fillMaxHeight().background(DS.accentTint))
            }
        }
        Column(modifier = Modifier.fillMaxWidth().padding(start = 16.dp)) {
            Row(modifier = Modifier.fillMaxWidth().height(64.dp), verticalAlignment = Alignment.CenterVertically) {
                Spacer(Modifier.weight(1f))
                PwText(
                    text = freeLabel,
                    size = 12.sp,
                    weight = FontWeight.SemiBold,
                    color = DS.inkTertiary,
                    align = TextAlign.Center,
                    maxLines = 2,
                    modifier = Modifier.width(columnWidth),
                )
                Column(
                    modifier = Modifier.width(columnWidth),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    Text("👑", fontSize = 15.sp, modifier = Modifier.clearAndSetSemantics { })
                    PwText(
                        text = proLabel,
                        size = 12.sp,
                        weight = FontWeight.ExtraBold,
                        color = Color.White,
                        maxLines = 1,
                        align = TextAlign.Center,
                        modifier = Modifier
                            .clip(RoundedCornerShape(12.dp))
                            .background(DS.accent)
                            .padding(horizontal = 10.dp, vertical = 4.dp),
                    )
                }
            }
            features.forEachIndexed { index, feature ->
                if (index > 0) HorizontalDivider(color = DS.hairline.copy(alpha = 0.6f))
                Row(modifier = Modifier.fillMaxWidth().heightIn(min = 46.dp), verticalAlignment = Alignment.CenterVertically) {
                    PwText(
                        text = feature.label,
                        size = 15.sp,
                        weight = FontWeight.SemiBold,
                        lineHeight = 20.sp,
                        modifier = Modifier.weight(1f).padding(vertical = 10.dp),
                    )
                    Box(modifier = Modifier.width(columnWidth), contentAlignment = Alignment.Center) {
                        if (feature.free) {
                            Icon(Icons.Filled.Check, contentDescription = null, tint = DS.inkTertiary, modifier = Modifier.size(16.dp))
                        } else {
                            Icon(Icons.Filled.Close, contentDescription = null, tint = DS.inkTertiary.copy(alpha = 0.6f), modifier = Modifier.size(15.dp))
                        }
                    }
                    Box(modifier = Modifier.width(columnWidth), contentAlignment = Alignment.Center) {
                        Box(modifier = Modifier.size(22.dp).background(DS.accent, CircleShape), contentAlignment = Alignment.Center) {
                            Icon(Icons.Filled.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(13.dp))
                        }
                    }
                }
            }
        }
    }
}

// endregion

/** A highlighted run inside a sentence, for the titles built from several strings. */
internal fun AnnotatedString.Builder.appendBold(text: String, color: Color) {
    pushStyle(androidx.compose.ui.text.SpanStyle(color = color, fontWeight = FontWeight.Bold))
    append(text)
    pop()
}

/** Keeps a block's width readable on tablets without touching its own paddings. */
internal val ElevateSideInset: Dp = 20.dp
