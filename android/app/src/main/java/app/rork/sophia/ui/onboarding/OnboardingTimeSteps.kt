package app.rork.sophia.ui.onboarding

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsDraggedAsState
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.R
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.formatted
import app.rork.sophia.domain.locale
import app.rork.sophia.ui.components.DSHighlightTitle
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlin.math.roundToInt
import kotlinx.coroutines.delay

/** « 3h30 » / « 3h » / « 45 min », like the iOS screen-time label. */
internal fun screenTimeLabel(context: android.content.Context, minutes: Int, language: AppLanguage): String {
    if (minutes < 60) return StringStore.text(context, "onboardingV2.screenTime.minutes", language, minutes)
    val hours = minutes / 60
    val rest = minutes % 60
    return if (rest == 0) "${hours}h" else String.format("%dh%02d", hours, rest)
}

/**
 * « How long do you spend on your phone each day? »: a slider from 30 min to 10 h in blocks
 * of 30 min. Le grand nombre ne bouge pas d'un cran à l'autre : voir [PhoneTimeNumber].
 *
 * « Elevate arrondi » style: centred title, a round illustration when the height allows, the
 * time very large and in blue, the slider and its bounds, then the pinned call to action.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun PhoneTimeStep(
    language: AppLanguage,
    minutes: Int,
    onMinutesChange: (Int) -> Unit,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    var slider by remember { mutableFloatStateOf(minutes.toFloat()) }
    var lastStep by remember { mutableIntStateOf(minutes / 30) }
    val title = StringStore.text(context, "onboardingV2.phoneTime.title", language)
    // Already the biggest text of the flow: it does not grow with the font scale, and it
    // steps down on a narrow screen so « 30 min » stays on one line.
    val fontScale = LocalDensity.current.fontScale.coerceAtLeast(1f)
    val numberSize = ((if (LocalConfiguration.current.screenWidthDp < 340) 66f else 84f) / fontScale).sp

    OV2CorePage(
        footer = {
            OnboardingCta(
                text = StringStore.text(context, "common.continue", language),
                onClick = {
                    onMinutesChange(slider.toInt())
                    onContinue()
                },
            )
        },
    ) { available ->
        val art = OV2Core.artSize(base = 116.dp, available = available, reserved = 360.dp)
        OV2CoreQuestionTitle(
            title = title,
            modifier = Modifier.padding(top = OV2Core.topInset).dsStagger(0),
        )
        if (art > 0.dp) {
            OV2CoreIllustration(
                art = R.drawable.antiscroll_poster,
                size = art,
                modifier = Modifier.padding(top = 22.dp).ov2CalmIn(120),
            )
        }
        // The number and the slider sit in the middle of the height left under the illustration.
        Spacer(Modifier.height(24.dp))
        Spacer(Modifier.weight(1f))
        PhoneTimeNumber(
            minutes = slider.toInt(),
            fontSize = numberSize,
            // Lu comme avant par le lecteur d'écran : « 3h30 », « 30 min ».
            spoken = screenTimeLabel(context, slider.toInt(), language),
            modifier = Modifier.dsStagger(1),
        )
        Column(
            modifier = Modifier
                .padding(horizontal = 32.dp)
                .padding(top = 20.dp)
                .dsStagger(2),
        ) {
            val sliderColors = SliderDefaults.colors(
                thumbColor = DS.accent,
                activeTrackColor = DS.accent,
                inactiveTrackColor = DS.accentTint,
                activeTickColor = Color.Transparent,
                inactiveTickColor = Color.Transparent,
            )
            val interaction = remember { MutableInteractionSource() }
            val pressed by interaction.collectIsPressedAsState()
            val dragged by interaction.collectIsDraggedAsState()
            val thumbScale by animateFloatAsState(
                targetValue = if (pressed || dragged) 1.18f else 1f,
                animationSpec = OV2Calm.quick(),
                label = "phoneTimeThumb",
            )
            // The slider of the style: a thin rounded track without notches, a round blue thumb
            // that swells under the finger.
            Slider(
                value = slider,
                onValueChange = { raw ->
                    val snapped = (raw / 30f).toInt().coerceIn(1, 20) * 30
                    slider = snapped.toFloat()
                    if (snapped / 30 != lastStep) {
                        lastStep = snapped / 30
                        haptics.select()
                        onMinutesChange(snapped)
                    }
                },
                valueRange = 30f..600f,
                steps = 18,
                colors = sliderColors,
                interactionSource = interaction,
                thumb = {
                    Box(
                        modifier = Modifier
                            .size(24.dp)
                            .graphicsLayer {
                                scaleX = thumbScale
                                scaleY = thumbScale
                            }
                            .background(DS.accent, CircleShape)
                            .border(3.dp, DS.surface, CircleShape),
                    )
                },
                track = { state ->
                    SliderDefaults.Track(
                        sliderState = state,
                        modifier = Modifier.height(6.dp),
                        colors = sliderColors,
                        drawStopIndicator = null,
                        drawTick = { _, _ -> },
                        thumbTrackGapSize = 0.dp,
                        trackInsideCornerSize = 0.dp,
                    )
                },
                modifier = Modifier.semantics {
                    contentDescription = title
                    stateDescription = screenTimeLabel(context, slider.toInt(), language)
                },
            )
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                val boundStyle = OV2.caption.copy(color = DS.inkSecondary)
                Text(screenTimeLabel(context, 30, language), style = boundStyle)
                Text(screenTimeLabel(context, 600, language), style = boundStyle)
            }
        }
        Spacer(Modifier.height(24.dp))
        Spacer(Modifier.weight(1f))
    }
}

/**
 * Le grand nombre de la page « temps de téléphone », stable au milieu de l'écran : toujours
 * la même forme, « 3h30 » (« 0h30 », « 3h00 », « 10h00 »), dans trois cases de largeur fixe.
 * Le « h » est au centre exact ; les heures s'alignent contre lui à gauche, les minutes à
 * droite, chacune dans une case de deux chiffres tabulaires. D'un cran à l'autre, seuls les
 * chiffres changent : rien ne se décale, rien ne glisse.
 *
 * La ligne se lit de gauche à droite dans toutes les langues, comme le libellé « 3h30 ».
 */
@Composable
private fun PhoneTimeNumber(
    minutes: Int,
    fontSize: androidx.compose.ui.unit.TextUnit,
    spoken: String,
    modifier: Modifier = Modifier,
) {
    val style = TextStyle(
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.ExtraBold,
        fontSize = fontSize,
        letterSpacing = (-2).sp,
        color = DS.accent,
        // Chiffres tabulaires : un « 1 » prend la même place qu'un « 0 ».
        fontFeatureSettings = "tnum",
    )
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
        Row(
            modifier = modifier
                .fillMaxWidth()
                .clearAndSetSemantics { contentDescription = spoken },
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            PhoneTimeDigits(text = (minutes / 60).toString(), style = style, alignment = Alignment.CenterEnd)
            Text(text = "h", style = style, maxLines = 1, softWrap = false)
            PhoneTimeDigits(text = String.format(java.util.Locale.ROOT, "%02d", minutes % 60), style = style, alignment = Alignment.CenterStart)
        }
    }
}

/** Une case de deux chiffres : sa largeur est celle de « 00 », le texte s'y cale d'un côté. */
@Composable
private fun PhoneTimeDigits(text: String, style: TextStyle, alignment: Alignment) {
    Box(contentAlignment = alignment) {
        // Invisible : donne à la case sa largeur, la même pour « 3 » et pour « 10 ».
        Text(text = "00", style = style, maxLines = 1, softWrap = false, modifier = Modifier.alpha(0f))
        Text(text = text, style = style, maxLines = 1, softWrap = false)
    }
}

/** « 27 ans », « 1 an », « 3 года »: the word for years agreed with the number. */
internal fun yearsText(context: android.content.Context, years: Int, language: AppLanguage): String =
    StringStore.text(context, "onboardingV2.yearsGrid.years", language, years)

private const val TOTAL_YEARS = 80
private const val GRID_COLUMNS = 10

/** A third of a life asleep, a third at work; the rest is free time. */
private const val SLEEP_YEARS = 27
private const val WORK_YEARS = 27
private const val FREE_YEARS = TOTAL_YEARS - SLEEP_YEARS - WORK_YEARS

private val SleepColor = Color(0xFF4D9E6B)
private val WorkColor = Color(0xFF8C613D)
private val FreeColor = Color(0xFFB8D1F2)

/** Red of the years spent on the phone. */
private val PhoneColor = Color(0xFFC8402F)

private val GRID_SPACING = 7.dp

/**
 * 80 squares, one per year of a life. They colour in slowly, one third after the other: sleep
 * in green, work in brown, then the free time that is left. Then, inside that free time,
 * square after square, in red, the years spent on the phone (from the daily screen time given
 * before); the conclusion, the number set large and its sentence, only arrives at the very end.
 *
 * The sequence lasts about 14 seconds and nothing gives the number away before: the title is
 * neutral (« Here's your life in years »), the « phone » line of the legend counts along with
 * the squares. « Continuer » n'apparaît qu'une fois l'animation terminée, avec la conclusion.
 *
 * Every counter is saved, so a rotation or a trip to the background resumes the sequence
 * where it was instead of replaying it.
 */
@Composable
internal fun YearsGridStep(language: AppLanguage, phoneMinutes: Int, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val reducedMotion = rememberOV2CoreReducedMotion()
    // Free-time years spent on the phone: the daily screen time over 80 years, capped at
    // the free time (beyond it, all the free time goes there).
    val screenYears = remember(phoneMinutes) {
        (TOTAL_YEARS * phoneMinutes / (24.0 * 60.0)).roundToInt().coerceIn(1, FREE_YEARS)
    }
    var revealed by rememberSaveable { mutableIntStateOf(0) }
    var sleepFilled by rememberSaveable { mutableIntStateOf(0) }
    var workFilled by rememberSaveable { mutableIntStateOf(0) }
    var freeFilled by rememberSaveable { mutableIntStateOf(0) }
    var screenFilled by rememberSaveable { mutableIntStateOf(0) }
    var showConclusion by rememberSaveable { mutableStateOf(false) }

    LaunchedEffect(screenYears) {
        if (reducedMotion) {
            // With animations off, the page opens in its final state.
            revealed = TOTAL_YEARS
            sleepFilled = SLEEP_YEARS
            workFilled = WORK_YEARS
            freeFilled = FREE_YEARS
            screenFilled = screenYears
            showConclusion = true
            return@LaunchedEffect
        }
        // 1 — the grey squares open (≈ 0.3 → 1.2 s).
        if (revealed < TOTAL_YEARS) {
            delay(300)
            for (i in revealed + 1..TOTAL_YEARS) {
                revealed = i
                if (i % 10 == 0) haptics.select()
                delay(11)
            }
            delay(800)
        }
        // 2, 3, 4 — the three thirds, each with its legend line and the time to read it.
        suspend fun fill(target: Int, current: Int, apply: (Int) -> Unit) {
            for (i in current + 1..target) {
                apply(i)
                if (i % 9 == 0) haptics.select()
                delay(50)
            }
        }
        if (sleepFilled < SLEEP_YEARS) {
            fill(SLEEP_YEARS, sleepFilled) { sleepFilled = it }
            delay(1250)
        }
        if (workFilled < WORK_YEARS) {
            fill(WORK_YEARS, workFilled) { workFilled = it }
            delay(1250)
        }
        if (freeFilled < FREE_YEARS) {
            fill(FREE_YEARS, freeFilled) { freeFilled = it }
            delay(1500)
        }
        // 5 — the free-time years spent on the phone, one by one (≈ 3 s whatever their number).
        if (screenFilled < screenYears) {
            val perSquare = (3000L / screenYears).coerceIn(120L, 450L)
            for (i in screenFilled + 1..screenYears) {
                screenFilled = i
                haptics.tick()
                delay(perSquare)
            }
            haptics.rigid()
        }
        // 6 — the conclusion, last.
        if (!showConclusion) {
            delay(600)
            showConclusion = true
        }
    }

    fun squareColor(i: Int): Color {
        if (i < SLEEP_YEARS) return if (i < sleepFilled) SleepColor else DS.hairline
        val work = i - SLEEP_YEARS
        if (work < WORK_YEARS) return if (work < workFilled) WorkColor else DS.hairline
        val free = i - SLEEP_YEARS - WORK_YEARS
        if (free < screenFilled) return PhoneColor
        return if (free < freeFilled) FreeColor else DS.hairline
    }

    fun isFilled(i: Int): Boolean {
        if (i < SLEEP_YEARS) return i < sleepFilled
        val work = i - SLEEP_YEARS
        if (work < WORK_YEARS) return work < workFilled
        val free = i - SLEEP_YEARS - WORK_YEARS
        return free < freeFilled || free < screenFilled
    }

    // Le bouton est épinglé hors du défilement et sa place est gardée dès le départ, mais il
    // n'apparaît (et ne répond) qu'à la fin de l'animation, quand la conclusion est là.
    val ctaAlpha by animateFloatAsState(if (showConclusion) 1f else 0f, tween(350), label = "gridCta")
    OV2CorePage(
        footer = {
            OnboardingCta(
                text = StringStore.text(context, "common.continue", language),
                onClick = { if (showConclusion) onContinue() },
                modifier = Modifier
                    .alpha(ctaAlpha)
                    .then(if (showConclusion) Modifier else Modifier.clearAndSetSemantics { }),
            )
        },
    ) { available ->
        // « Here's **your life in years** » and « One square, one year. »: there from the
        // start, saying nothing of the result.
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = OV2Core.sideInset)
                .padding(top = 16.dp)
                .dsStagger(0),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            DSHighlightTitle(
                text = OV2Core.marked(
                    context,
                    titleKey = "onboardingV2.yearsGrid.title",
                    highlightKey = "elevateOnboardingCore.yearsGrid.titleHighlight",
                    language = language,
                ),
                modifier = Modifier.fillMaxWidth().semantics { heading() },
                fontSize = 25.sp,
                lineHeight = 32.sp,
                textAlign = TextAlign.Start,
            )
            Text(
                text = StringStore.text(context, "elevateOnboardingCore.yearsGrid.subtitle", language),
                style = ov2CoreSubtitleStyle.copy(fontSize = 15.sp, lineHeight = 22.sp),
            )
        }
        Spacer(Modifier.height(20.dp))
        Spacer(Modifier.weight(1f))
        // The squares shrink on a short screen rather than push the legend and the conclusion,
        // which comes last under them, out of sight. 292 dp is the height of the rest of the page.
        val rows = TOTAL_YEARS / GRID_COLUMNS
        val cell = (available - 292.dp - GRID_SPACING * (rows - 1)) / rows
        val gridWidth = (cell * GRID_COLUMNS + GRID_SPACING * (GRID_COLUMNS - 1)).coerceAtLeast(200.dp)
        Column(
            modifier = Modifier
                .padding(horizontal = OV2Core.sideInset)
                .widthIn(max = gridWidth)
                .fillMaxWidth()
                .clearAndSetSemantics { },
            verticalArrangement = Arrangement.spacedBy(GRID_SPACING),
        ) {
            repeat(rows) { row ->
                Row(horizontalArrangement = Arrangement.spacedBy(GRID_SPACING)) {
                    repeat(GRID_COLUMNS) { column ->
                        val index = row * GRID_COLUMNS + column
                        val free = index - SLEEP_YEARS - WORK_YEARS
                        YearCell(
                            revealed = index < revealed,
                            filled = isFilled(index),
                            phone = free in 0 until screenFilled,
                            color = squareColor(index),
                            modifier = Modifier.weight(1f),
                        )
                    }
                }
            }
        }
        // One line per colour, on two columns; each appears when its colour starts to land.
        // The « phone » line counts with the red squares.
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = OV2Core.sideInset)
                .padding(top = 20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                LegendRow(SleepColor, "onboardingV2.yearsGrid.sleep", SLEEP_YEARS, sleepFilled > 0, language, Modifier.weight(1f))
                LegendRow(WorkColor, "onboardingV2.yearsGrid.work", WORK_YEARS, workFilled > 0, language, Modifier.weight(1f))
            }
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                LegendRow(FreeColor, "onboardingV2.yearsGrid.free", FREE_YEARS, freeFilled > 0, language, Modifier.weight(1f))
                LegendRow(PhoneColor, "onboardingV2.yearsGrid.screen", screenFilled.coerceAtLeast(1), screenFilled > 0, language, Modifier.weight(1f))
            }
        }
        // The number, large, then the sentence: what the page wants remembered. Its place is
        // kept from the start, so nothing jumps when it arrives.
        val conclusion by animateFloatAsState(if (showConclusion) 1f else 0f, OV2Calm.settle(), label = "gridConclusion")
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = OV2Core.sideInset)
                .padding(top = 20.dp)
                .graphicsLayer {
                    alpha = conclusion.coerceIn(0f, 1f)
                    translationY = (1f - conclusion) * 14.dp.toPx()
                    val s = 0.96f + 0.04f * conclusion
                    scaleX = s
                    scaleY = s
                }
                .clip(DS.cardShape)
                .background(DS.dangerTint)
                .border(1.5.dp, DS.danger.copy(alpha = 0.28f), DS.cardShape)
                .padding(horizontal = 16.dp, vertical = 14.dp)
                .then(
                    if (showConclusion) Modifier.semantics(mergeDescendants = true) { } else Modifier.clearAndSetSemantics { },
                ),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Text(
                text = yearsText(context, screenYears, language),
                style = OV2.titleLarge.copy(fontSize = 36.sp, lineHeight = 42.sp, fontWeight = FontWeight.ExtraBold, color = DS.danger),
                maxLines = 1,
            )
            Text(
                text = StringStore.text(context, "onboardingV2.yearsGrid.captionFree", language, FREE_YEARS, screenYears),
                style = OV2.subheadline.copy(fontSize = 14.sp, lineHeight = 20.sp, fontWeight = FontWeight.SemiBold, color = DS.danger),
                modifier = Modifier.weight(1f),
            )
        }
        Spacer(Modifier.height(16.dp))
        Spacer(Modifier.weight(1f))
    }
}

@Composable
private fun YearCell(
    revealed: Boolean,
    filled: Boolean,
    phone: Boolean,
    color: Color,
    modifier: Modifier = Modifier,
) {
    val scale by animateFloatAsState(
        targetValue = if (!revealed) 0.3f else if (filled) 1f else 0.88f,
        animationSpec = OV2Calm.quick(),
        label = "yearScale",
    )
    val alpha by animateFloatAsState(if (revealed) 1f else 0f, tween(200), label = "yearAlpha")
    val animatedColor by animateColorAsState(color, tween(400), label = "yearColor")
    // Une année qui part au téléphone se pose en revenant d'un peu plus grand, sans rebond
    // (pas sur une page restaurée).
    val startedAsPhone = remember { phone }
    val bump = remember { Animatable(1f) }
    LaunchedEffect(phone) {
        if (phone && !startedAsPhone) {
            bump.snapTo(1.18f)
            bump.animateTo(1f, OV2Calm.settle())
        }
    }
    Box(
        modifier = modifier
            .aspectRatio(1f)
            .graphicsLayer {
                val s = scale * bump.value
                scaleX = s
                scaleY = s
                this.alpha = alpha
            }
            // Read while drawing: a colour on its way does not recompose the cell.
            .drawBehind { drawRoundRect(color = animatedColor, cornerRadius = CornerRadius(5.dp.toPx())) },
    )
}

/** One line of the legend, shown when its colour starts to land. */
@Composable
private fun LegendRow(
    color: Color,
    key: String,
    years: Int,
    shown: Boolean,
    language: AppLanguage,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val progress by animateFloatAsState(if (shown) 1f else 0f, DSMotion.reveal(), label = "legendIn")
    Row(
        modifier = modifier
            .graphicsLayer {
                alpha = progress.coerceIn(0f, 1f)
                translationY = (1f - progress) * 10.dp.toPx()
            }
            .then(if (shown) Modifier.semantics(mergeDescendants = true) { } else Modifier.clearAndSetSemantics { }),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Box(modifier = Modifier.size(12.dp).background(color, RoundedCornerShape(4.dp)))
        Text(
            text = StringStore.text(context, key, language),
            style = OV2.caption.copy(fontWeight = FontWeight.Normal, lineHeight = 17.sp, color = DS.inkSecondary),
            maxLines = 2,
            modifier = Modifier.weight(1f),
        )
        Text(
            text = yearsText(context, years, language),
            style = OV2.caption.copy(fontSize = 14.sp, fontWeight = FontWeight.Bold, color = DS.ink, fontFeatureSettings = "tnum"),
            maxLines = 1,
        )
    }
}

/**
 * « With Sophia, turn that time into knowledge »: the sentence turns bold word by word, then
 * the last word keeps swapping (knowledge, art, philosophy…) in the blue of the style.
 * No button: a tap anywhere moves on, mais seulement une fois que le mot a commencé à
 * changer : avant, l'invitation à toucher l'écran n'est pas affichée et un appui ne fait rien.
 */
@Composable
internal fun TransformStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val words = remember(language) {
        StringStore.text(context, "onboardingV2.transform.text", language)
            .split(' ')
            .filter { it.isNotBlank() }
    }
    val swapWords = remember(language) {
        StringStore.text(context, "onboardingV2.transform.words", language)
            .split(',')
            .map { it.trim() }
            .filter { it.isNotEmpty() }
    }
    var boldCount by remember { mutableIntStateOf(0) }
    // Vrai dès que le mot a changé une première fois : l'invitation apparaît et l'appui compte.
    var canContinue by remember { mutableStateOf(false) }
    var swapping by remember { mutableStateOf(false) }
    var swapIndex by remember { mutableIntStateOf(0) }

    LaunchedEffect(words) {
        delay(500)
        words.indices.forEach {
            boldCount = it + 1
            haptics.select()
            delay(320)
        }
        if (swapWords.size <= 1) {
            // Un seul mot : rien à faire défiler, la phrase entière suffit.
            canContinue = true
            return@LaunchedEffect
        }
        delay(750)
        // Le premier changement de mot lance l'animation, et ouvre la suite.
        swapping = true
        swapIndex += 1
        haptics.select()
        canContinue = true
        while (true) {
            delay(1150)
            swapIndex += 1
            haptics.select()
        }
    }

    TapToContinueScaffold(
        art = R.drawable.onb_art_nightbook,
        artBase = 150.dp,
        sentenceWords = words + swapWords,
        hint = StringStore.text(context, "onboardingV2.transform.tapHint", language),
        hintVisible = canContinue,
        canContinue = canContinue,
        onContinue = onContinue,
    ) { style ->
        ProgressiveWords(
            words = words,
            boldCount = boldCount,
            style = style,
            lastCell = { bold ->
                SwapWordCell(
                    words = swapWords.ifEmpty { listOf(words.lastOrNull().orEmpty()) },
                    index = swapIndex,
                    swapping = swapping,
                    bold = bold,
                    style = style,
                    // The swapping word is in accent blue as soon as the bold reaches it.
                    color = if (swapping || bold) DS.accent else DS.inkTertiary,
                )
            },
        )
    }
}

@Composable
private fun SwapWordCell(
    words: List<String>,
    index: Int,
    swapping: Boolean,
    bold: Boolean,
    style: TextStyle,
    color: Color,
) {
    val animatedColor by animateColorAsState(color, tween(300), label = "swapColor")
    Box(contentAlignment = Alignment.Center) {
        // Invisible stack of every candidate: keeps the slot as wide as the longest word,
        // so the sentence never reflows while the last word cycles.
        words.forEach { candidate ->
            Text(
                text = candidate,
                style = style.copy(fontWeight = FontWeight.ExtraBold),
                modifier = Modifier.alpha(0f).clearAndSetSemantics { },
            )
        }
        AnimatedContent(
            targetState = if (swapping) index % words.size else 0,
            transitionSpec = {
                // Le mot suivant descend à sa place et s'y arrête, sans rebond.
                (slideInVertically(tween<IntOffset>(260, easing = LinearOutSlowInEasing)) { -it } + fadeIn(tween(220))) togetherWith
                    (slideOutVertically(tween(220)) { it } + fadeOut(tween(160)))
            },
            label = "swapWord",
        ) { i ->
            Text(
                text = words[i],
                style = style.copy(
                    fontWeight = if (bold || swapping) FontWeight.ExtraBold else FontWeight.Normal,
                    color = animatedColor,
                ),
            )
        }
    }
}

/**
 * « Let's personalize your content », right before the course swipe: the sentence turns bold
 * word by word, like « Turn that time ». No button: a tap anywhere opens the next page, once
 * the whole sentence has turned bold (the hint appears at that moment).
 */
@Composable
internal fun PersonalizeStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val words = remember(language) {
        StringStore.text(context, "onboardingV2.personalize.text", language)
            .split(' ')
            .filter { it.isNotBlank() }
    }
    var boldCount by remember { mutableIntStateOf(0) }
    var showHint by remember { mutableStateOf(false) }
    LaunchedEffect(words) {
        delay(500)
        words.indices.forEach {
            boldCount = it + 1
            haptics.select()
            delay(320)
        }
        showHint = true
    }

    TapToContinueScaffold(
        art = R.drawable.onb_art_mirror,
        artBase = 160.dp,
        sentenceWords = words,
        hint = StringStore.text(context, "onboardingV2.personalize.tapHint", language),
        hintVisible = showHint,
        // On ne passe à la suite qu'une fois la phrase entièrement animée.
        canContinue = showHint,
        onContinue = onContinue,
    ) { style ->
        ProgressiveWords(
            words = words,
            boldCount = boldCount,
            style = style,
        )
    }
}

/**
 * A page without a button: a round illustration above a sentence set very large and centred,
 * the invitation to touch the screen at the bottom. The sentence gets the largest style that
 * keeps its longest word on one line.
 */
@Composable
private fun TapToContinueScaffold(
    @androidx.annotation.DrawableRes art: Int,
    artBase: Dp,
    sentenceWords: List<String>,
    hint: String,
    hintVisible: Boolean,
    onContinue: () -> Unit,
    // Faux tant que l'animation de la page n'est pas terminée : le toucher ne fait rien.
    canContinue: Boolean = true,
    content: @Composable (style: TextStyle) -> Unit,
) {
    val haptics = rememberHaptics()
    var advanced by remember { mutableStateOf(false) }
    val hintAlpha by animateFloatAsState(if (hintVisible) 1f else 0f, tween(500), label = "hint")
    BoxWithConstraints(
        modifier = Modifier
            .fillMaxSize()
            .clickable(
                enabled = canContinue,
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
            ) {
                if (canContinue && !advanced) {
                    advanced = true
                    haptics.confirm()
                    onContinue()
                }
            },
        contentAlignment = Alignment.Center,
    ) {
        val style = ov2CoreSentenceStyle(sentenceWords, maxWidth - OV2Core.sideInset * 2)
        // The illustration shrinks, then goes, when the sentence and the hint need the height.
        val artSize = OV2Core.artSize(base = artBase, available = maxHeight, reserved = 330.dp)
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = OV2Core.sideInset)
                .padding(bottom = 36.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(26.dp),
        ) {
            if (artSize > 0.dp) {
                OV2CoreIllustration(art = art, size = artSize, modifier = Modifier.ov2PopIn(100))
            }
            content(style)
        }
        OV2CoreTapHint(
            text = hint,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 28.dp)
                .alpha(hintAlpha),
        )
    }
}

/**
 * Social proof: the title, five stars with the rating and the number of users, then the
 * reviews as stacked cards (the quote, then the portrait and the first name). The cards land
 * in a cascade; those that do not fit are found by scrolling, the button staying pinned.
 */
@Composable
internal fun ReviewStep(
    language: AppLanguage,
    @Suppress("UNUSED_PARAMETER") richMotion: Boolean,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val avatars = remember { onboardingAssets(context, "review_avatar_") }
    val testimonials = remember(language) {
        (1..6).map { i ->
            Testimonial(
                index = i,
                quote = StringStore.text(context, "onboardingV2.review.t$i.quote", language),
                author = StringStore.text(context, "onboardingV2.review.t$i.author", language),
                avatar = avatars.firstOrNull { it.endsWith("review_avatar_$i.jpg") || it.endsWith("review_avatar_$i.png") },
            )
        }
    }

    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        // Six reviews do not fit on one screen: the list scrolls, the CTA stays pinned and a
        // fade above it says there is more.
        Box(modifier = Modifier.weight(1f).fillMaxWidth().readableWidth()) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = OV2Core.sideInset)
                    .padding(bottom = 36.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                OV2CoreQuestionTitle(
                    title = StringStore.text(context, "onboardingV2.review.title", language),
                    modifier = Modifier.padding(top = 22.dp).dsStagger(0),
                    horizontalInset = 0.dp,
                )
                // Five stars, the rating and the number of users, on one line.
                Row(
                    modifier = Modifier
                        .padding(top = 12.dp)
                        .dsStagger(1)
                        .semantics(mergeDescendants = true) { },
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    OV2CoreStars(size = 17.dp, baseDelayMillis = 200)
                    Text(
                        text = 4.8.formatted(language, 1) + " · " +
                            StringStore.text(context, "onboardingV2.loading.social.count", language),
                        style = OV2.caption.copy(fontSize = 14.sp, fontWeight = FontWeight.Bold, color = DS.ink),
                        maxLines = 1,
                    )
                }
                Spacer(Modifier.height(14.dp))
                Column(verticalArrangement = Arrangement.spacedBy(9.dp)) {
                    testimonials.forEachIndexed { i, testimonial ->
                        ReviewCard(
                            testimonial = testimonial,
                            modifier = Modifier.dsStagger(i, stepMillis = 80, baseMillis = 220),
                        )
                    }
                }
            }
            Box(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
                    .height(44.dp)
                    .background(Brush.verticalGradient(listOf(DS.canvas.copy(alpha = 0f), DS.canvas))),
            )
        }
        Column(
            modifier = Modifier.fillMaxWidth().readableWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            OnboardingCta(StringStore.text(context, "common.continue", language), onContinue)
        }
    }
}

private data class Testimonial(val index: Int, val quote: String, val author: String, val avatar: String?)

@Composable
private fun ReviewCard(testimonial: Testimonial, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .sophiaCard()
            .padding(14.dp)
            .semantics(mergeDescendants = true) { },
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Text(
            text = testimonial.quote,
            style = OV2.body.copy(color = DS.ink, fontWeight = FontWeight.Normal, fontSize = 14.sp, lineHeight = 20.sp),
        )
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            ReviewAvatar(testimonial)
            Text(
                text = testimonial.author,
                style = OV2.caption.copy(fontSize = 14.sp, fontWeight = FontWeight.Bold, color = DS.ink),
                modifier = Modifier.weight(1f),
            )
            OV2CoreStars(size = 11.dp, spacing = 2.dp, animated = false)
        }
    }
}

/** Gradients of the generated portraits, always the same for the same reviewer. */
private val AvatarPalettes = listOf(
    Color(0xFFFA9E73) to Color(0xFFED5973),
    Color(0xFF73B8FA) to Color(0xFF4073D9),
    Color(0xFF8CD9A6) to Color(0xFF389973),
    Color(0xFFD9A6FA) to Color(0xFF8F66EB),
    Color(0xFFFCCC66) to Color(0xFFEB8C26),
    Color(0xFF8CD9EB) to Color(0xFF4099BF),
)

/** The bundled `review_avatar_<n>` when there is one, otherwise the initial on a gradient. */
@Composable
private fun ReviewAvatar(testimonial: Testimonial) {
    val modifier = Modifier
        .size(40.dp)
        .clip(CircleShape)
        .border(1.dp, DS.hairline, CircleShape)
    if (testimonial.avatar != null) {
        AssetPicture(url = testimonial.avatar, modifier = modifier)
    } else {
        val palette = AvatarPalettes[(testimonial.index - 1).mod(AvatarPalettes.size)]
        Box(
            modifier = modifier.background(Brush.linearGradient(listOf(palette.first, palette.second))),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = testimonial.author.trim().take(1).uppercase(),
                color = Color.White,
                fontWeight = FontWeight.Bold,
                fontSize = 16.sp,
            )
        }
    }
}

@Composable
internal fun ReminderStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    val words = remember(language) {
        StringStore.text(context, "onboardingV2.reminder.title", language)
            .split(' ')
            .filter { it.isNotBlank() }
    }
    var boldCount by remember { mutableIntStateOf(0) }
    var bellIn by remember { mutableStateOf(false) }
    LaunchedEffect(words) {
        bellIn = true
        delay(300)
        words.indices.forEach {
            boldCount = it + 1
            haptics.selection()
            delay(120)
        }
    }
    val bellScale by animateFloatAsState(
        targetValue = if (bellIn) 1f else 0.5f,
        animationSpec = OnboardingMotion.settle(420),
        label = "bellScale",
    )
    val wobble by rememberInfiniteTransition(label = "bell").animateFloat(
        initialValue = -12f,
        targetValue = 12f,
        animationSpec = infiniteRepeatable(tween(400), RepeatMode.Reverse),
        label = "bellWobble",
    )

    OnboardingPage(
        footer = {
            OnboardingCta(StringStore.text(context, "onboardingV2.reminder.cta", language), onContinue)
        },
    ) {
        ProgressiveWords(
            words = words,
            boldCount = boldCount,
            modifier = Modifier.padding(horizontal = 32.dp),
        )
        Spacer(Modifier.height(48.dp))
        Text(
            text = "🔔",
            fontSize = 86.sp,
            modifier = Modifier.graphicsLayer {
                scaleX = bellScale
                scaleY = bellScale
                alpha = bellScale
                rotationZ = if (bellIn) wobble else 0f
                transformOrigin = androidx.compose.ui.graphics.TransformOrigin(0.5f, 0f)
            },
        )
    }
}

@Composable
internal fun TrialStepsStep(language: AppLanguage, trialDays: Int = 3, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    val endDate = remember(language, trialDays) {
        java.time.LocalDate.now().plusDays(trialDays.toLong()).format(
            // `Locale("sr")` resolves to Cyrillic, which put a Cyrillic month next to the
            // Latin text of Sophia's own Serbian table. `language.locale` pins the script.
            // The pattern is the language's own day-month order ("3. Oktober", "3 de
            // octubre", "October 3"); a fixed "d MMMM" read wrong in half of them.
            java.time.format.DateTimeFormatter.ofPattern(
                android.text.format.DateFormat.getBestDateTimePattern(language.locale, "dMMMM"),
                language.locale,
            ),
        )
    }
    val steps = remember(language, endDate, trialDays) {
        (0..3).map { i ->
            // Steps 2 and 3 name the reminder day and the last day of the trial.
            val dayNumber = when (i) {
                2 -> (trialDays - 1).coerceAtLeast(1)
                3 -> trialDays
                else -> 0
            }
            Triple(
                if (i >= 2) {
                    StringStore.trialText(context, "onboardingV2.trial.step$i.title", language, dayNumber)
                } else {
                    StringStore.text(context, "onboardingV2.trial.step$i.title", language)
                },
                StringStore.text(context, "onboardingV2.trial.step$i.detail", language, endDate),
                i,
            )
        }
    }
    var revealed by remember { mutableIntStateOf(0) }
    LaunchedEffect(Unit) {
        delay(200)
        steps.indices.forEach {
            revealed = it + 1
            haptics.selection()
            delay(180)
        }
    }

    OnboardingPage(
        contentArrangement = Arrangement.Top,
        footer = {
            OnboardingCta(StringStore.text(context, "onboardingV2.trial.cta", language), onContinue)
        },
    ) {
        Spacer(Modifier.height(72.dp))
        Text(
            text = StringStore.text(context, "onboardingV2.trial.title", language),
            style = OV2.titleLarge,
            modifier = Modifier.padding(horizontal = 28.dp).ov2Reveal(50),
        )
        Spacer(Modifier.height(36.dp))
        Column(modifier = Modifier.padding(horizontal = 28.dp)) {
            steps.forEach { (title, detail, index) ->
                TrialTimelineRow(
                    title = title,
                    detail = detail,
                    emoji = TRIAL_EMOJI[index],
                    active = index == 1,
                    done = index == 0,
                    last = index == steps.lastIndex,
                    visible = index < revealed,
                )
            }
        }
    }
}

private val TRIAL_EMOJI = listOf("✓", "🔓", "🔔", "★")

@Composable
private fun TrialTimelineRow(
    title: String,
    detail: String,
    emoji: String,
    active: Boolean,
    done: Boolean,
    last: Boolean,
    visible: Boolean,
) {
    val alpha by animateFloatAsState(if (visible) 1f else 0f, tween(400), label = "trialAlpha")
    val shift by animateFloatAsState(
        targetValue = if (visible) 0f else -12f,
        animationSpec = OnboardingMotion.settle(),
        label = "trialShift",
    )
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .graphicsLayer { this.alpha = alpha; translationX = shift },
        horizontalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            OnboardingCircleBadge(
                size = 40.dp,
                background = if (done || active) OV2.accent else OV2.inkTertiary.copy(alpha = 0.35f),
            ) {
                Text(emoji, fontSize = 16.sp, color = Color.White)
            }
            if (!last) {
                Box(
                    modifier = Modifier
                        .size(width = 3.dp, height = 46.dp)
                        .background(OV2.accent.copy(alpha = 0.18f)),
                )
            }
        }
        Column(modifier = Modifier.padding(bottom = if (last) 0.dp else 14.dp)) {
            Text(
                text = title,
                style = OV2.headline.copy(color = if (active) OV2.accent else OV2.ink),
            )
            Text(text = detail, style = OV2.subheadline)
        }
    }
}
