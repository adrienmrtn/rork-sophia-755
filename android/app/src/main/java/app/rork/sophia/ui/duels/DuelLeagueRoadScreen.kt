package app.rork.sophia.ui.duels

import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.DuelHome
import app.rork.sophia.domain.DuelLeague
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.uppercaseInApp
import kotlinx.coroutines.delay
import kotlin.math.abs

// Hauteurs d'une ligne de la route : fixes, pour savoir où est la ligue du joueur avant même
// le premier affichage et ouvrir la page dessus.
private val CARD_HEIGHT = 110.dp
private val CURRENT_CARD_HEIGHT = 200.dp
private val ROW_GAP = 12.dp
private val ROAD_TOP_PADDING = 6.dp

/** Largeur du repère de la route, et son écart avec la carte. */
private val RAIL_WIDTH = 6.dp
private val RAIL_GAP = 12.dp

/**
 * Le retard (ms) du repère d'une ligue atteinte, selon sa distance à celle du joueur : les
 * ligues du bas d'abord, celle du joueur en dernier.
 */
private fun roadFillDelay(distance: Int): Int {
    val near = 4
    return 200 + (near - distance.coerceIn(0, near)) * 110
}

/**
 * La route des ligues (maquette AEr23) : les 30 ligues de la plus haute (en haut) à la première
 * (en bas), chacune avec son illustration et le nombre de trophées qu'elle demande. Les ligues
 * atteintes sont en couleur, celle du joueur est mise en avant avec sa jauge, les suivantes
 * sont en gris. À l'ouverture, la route se remplit de safran jusqu'à la ligue du joueur, sur
 * laquelle la page s'ouvre ; toucher une ligue l'affiche en grand.
 *
 * Même page que `DuelLeagueRoadView.swift`. Elle remplace le contenu de l'onglet Duels (la
 * barre d'onglets reste visible, comme une page poussée) ; [backEnabled] dit si le retour
 * système lui revient (l'onglet est à l'écran et rien n'est dessiné par-dessus).
 */
@Composable
fun DuelLeagueRoadScreen(
    home: DuelHome,
    language: AppLanguage,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    backEnabled: Boolean = true,
) {
    val context = LocalContext.current
    val view = LocalView.current
    val haptics = rememberHaptics()
    var preview by remember { mutableStateOf<DuelLeague?>(null) }
    val currentPosition = home.currentLeague?.position ?: 1
    // De la plus haute à la première, comme une route qu'on monte.
    val leagues = remember(home.leagues) { home.leagues.asReversed() }

    // La route se remplit une fois, à l'ouverture de la page (et pas à chaque retour d'un aperçu
    // ou rotation) : les repères des ligues atteintes passent au safran, de bas en haut, puis
    // un cran quand le remplissage atteint la ligue du joueur.
    var roadFilled by rememberSaveable { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        if (roadFilled) return@LaunchedEffect
        roadFilled = true
        delay(roadFillDelay(0) + 300L)
        haptics.soft()
    }

    BackHandler(enabled = backEnabled) {
        if (preview != null) preview = null else onBack()
    }

    Box(modifier = modifier.fillMaxSize().background(DS.canvas)) {
        Column(modifier = Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
            Row(
                modifier = Modifier.widthIn(max = 640.dp).fillMaxWidth().padding(horizontal = 24.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                DuelRoundIconButton(
                    icon = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = StringStore.text(context, "common.close", language),
                    onClick = onBack,
                )
                Text(
                    text = StringStore.text(context, "duel.league.road", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 16.sp,
                    color = DS.ink,
                    textAlign = TextAlign.Center,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f),
                )
                Box(modifier = Modifier.defaultMinSize(minWidth = 44.dp), contentAlignment = Alignment.CenterEnd) {
                    DuelTrophyCount(value = home.profile.trophies, language = language, size = 15.dp, color = DS.ink)
                }
            }
            BoxWithConstraints(modifier = Modifier.widthIn(max = 640.dp).fillMaxWidth().weight(1f)) {
                // La page s'ouvre avec la ligue du joueur au milieu de l'écran. Trente lignes
                // de hauteur connue : la position se calcule, sans attendre la mise en page.
                val density = LocalDensity.current
                val currentIndex = leagues.indexOfFirst { it.position == currentPosition }
                val initialScroll = remember(currentIndex, maxHeight) {
                    if (currentIndex < 0) {
                        0
                    } else {
                        val rowTop = ROAD_TOP_PADDING + (CARD_HEIGHT + ROW_GAP) * currentIndex
                        val rowCenter = rowTop + (CURRENT_CARD_HEIGHT + ROW_GAP) / 2
                        with(density) { (rowCenter - maxHeight / 2).roundToPx() }.coerceAtLeast(0)
                    }
                }
                // Trente lignes : une pile simple (non paresseuse), comme sur iOS.
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState(initial = initialScroll))
                        .padding(horizontal = 24.dp)
                        .padding(top = ROAD_TOP_PADDING, bottom = 28.dp),
                ) {
                    leagues.forEach { league ->
                        val reached = league.position <= currentPosition
                        val isCurrent = league.position == currentPosition
                        LeagueRow(
                            league = league,
                            home = home,
                            language = language,
                            reached = reached,
                            isCurrent = isCurrent,
                            distance = currentPosition - league.position,
                            roadFilled = roadFilled,
                            onClick = {
                                view.duelHaptic(DuelHaptic.Tap)
                                preview = league
                            },
                        )
                    }
                }
            }
        }

        preview?.let { league ->
            DuelLeaguePreview(
                league = league,
                reached = league.position <= currentPosition,
                // Renseigné seulement pour la ligue du joueur.
                standing = if (league.position == currentPosition) {
                    DuelLeagueStanding(
                        trophies = home.profile.trophies,
                        progress = home.leagueProgress(home.profile.trophies),
                        next = home.nextLeague(home.currentLeague),
                    )
                } else {
                    null
                },
                language = language,
                onClose = {
                    view.duelHaptic(DuelHaptic.Tap)
                    preview = null
                },
            )
        }
    }
}

/** Une ligue : le repère sur la route à gauche, sa carte à droite. */
@Composable
private fun LeagueRow(
    league: DuelLeague,
    home: DuelHome,
    language: AppLanguage,
    reached: Boolean,
    isCurrent: Boolean,
    /** Le nombre de ligues entre celle-ci et celle du joueur (positif : en dessous). */
    distance: Int,
    roadFilled: Boolean,
    onClick: () -> Unit,
) {
    val cardHeight = if (isCurrent) CURRENT_CARD_HEIGHT else CARD_HEIGHT
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(cardHeight + ROW_GAP)
            .padding(vertical = ROW_GAP / 2)
            .dsStagger(minOf(abs(distance), 5), stepMillis = 50, baseMillis = 20, offset = 10.dp),
        horizontalArrangement = Arrangement.spacedBy(RAIL_GAP),
    ) {
        LeagueRail(reached = reached, distance = distance, roadFilled = roadFilled)
        LeagueCard(
            league = league,
            home = home,
            language = language,
            reached = reached,
            isCurrent = isCurrent,
            roadFilled = roadFilled,
            onClick = onClick,
            modifier = Modifier.weight(1f).fillMaxHeight(),
        )
    }
}

/** Le repère de la route : gris, et safran une fois la ligue atteinte (il se remplit du bas). */
@Composable
private fun LeagueRail(reached: Boolean, distance: Int, roadFilled: Boolean) {
    val fill by animateFloatAsState(
        targetValue = if (reached && roadFilled) 1f else 0f,
        animationSpec = tween(durationMillis = 520, delayMillis = roadFillDelay(distance), easing = FastOutSlowInEasing),
        label = "duelRoadFill",
    )
    Box(
        modifier = Modifier
            .width(RAIL_WIDTH)
            .fillMaxHeight()
            .clip(CircleShape)
            .background(DS.ink.copy(alpha = 0.14f))
            .clearAndSetSemantics {},
    ) {
        if (reached) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .graphicsLayer {
                        scaleY = fill
                        transformOrigin = TransformOrigin(0.5f, 1f)
                    }
                    .background(DuelPalette.saffron, CircleShape),
            )
        }
    }
}

@Composable
private fun LeagueCard(
    league: DuelLeague,
    home: DuelHome,
    language: AppLanguage,
    reached: Boolean,
    isCurrent: Boolean,
    roadFilled: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    Box(
        modifier = modifier
            .fillMaxWidth()
            // Toucher une ligue vibre déjà (`DuelHaptic.Tap`).
            .pressable(onClick = onClick, scaleDown = 0.98f, haptic = false)
            .clip(DS.cardShape),
    ) {
        // Une ligue pas encore atteinte : son illustration en gris, sous un voile uni.
        DuelLeagueBackdrop(
            league = league,
            thumb = true,
            modifier = Modifier.matchParentSize().duelGrayscale(!reached),
        )
        Box(
            modifier = Modifier
                .matchParentSize()
                .background(
                    if (reached) {
                        // L'illustration reste visible en haut de la carte.
                        Brush.verticalGradient(
                            listOf(DuelTheme.scrim.copy(alpha = 0.18f), DuelTheme.scrim.copy(alpha = 0.74f)),
                        )
                    } else {
                        SolidColor(DuelTheme.scrim.copy(alpha = 0.55f))
                    },
                ),
        )
        Column(
            modifier = Modifier
                .align(Alignment.BottomStart)
                .fillMaxWidth()
                .padding(horizontal = 14.dp)
                .padding(bottom = if (isCurrent) 14.dp else 12.dp),
            verticalArrangement = Arrangement.spacedBy(if (isCurrent) 6.dp else 2.dp),
        ) {
            DuelFitText(
                text = DuelFormat.leagueName(context, league, language),
                fontSize = if (isCurrent) 22.sp else 18.sp,
                color = Color.White,
                modifier = Modifier.fillMaxWidth(),
            )
            if (isCurrent) {
                // Sa propre ligue : les trophées du joueur (et non le seuil de la ligue, 0 pour
                // la première), puis le seuil de la suivante au bout de la jauge.
                Row(verticalAlignment = Alignment.CenterVertically) {
                    DuelTrophyCount(value = home.profile.trophies, language = language, size = 13.dp, color = Color.White)
                    Spacer(Modifier.weight(1f))
                    home.nextLeague(league)?.let { next ->
                        DuelTrophyCount(value = next.minTrophies, language = language, size = 13.dp, color = Color.White)
                    }
                }
                // La jauge se remplit une fois la route arrivée à la ligue du joueur.
                val progress by animateFloatAsState(
                    targetValue = if (roadFilled) home.leagueProgress(home.profile.trophies) else 0f,
                    animationSpec = tween(
                        durationMillis = 700,
                        delayMillis = roadFillDelay(0) + 250,
                        easing = FastOutSlowInEasing,
                    ),
                    label = "duelRoadGauge",
                )
                DuelProgressBar(progress = progress, height = 8.dp)
            } else {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(5.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    DuelTrophyCount(value = league.minTrophies, language = language, size = 13.dp, color = Color.White)
                    if (!reached) {
                        Icon(
                            Icons.Filled.Lock,
                            contentDescription = null,
                            tint = Color.White.copy(alpha = 0.85f),
                            modifier = Modifier.size(12.dp),
                        )
                    }
                }
            }
        }
        if (isCurrent) {
            Text(
                text = StringStore.text(context, "duel.league.here", language).uppercaseInApp(),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 12.sp,
                letterSpacing = 0.6.sp,
                color = DuelPalette.night,
                maxLines = 1,
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .padding(start = 14.dp, top = 12.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .background(DuelPalette.saffron)
                    .padding(horizontal = 10.dp, vertical = 4.dp),
            )
        }
        Box(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(10.dp)
                .defaultMinSize(minWidth = 28.dp, minHeight = 28.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.25f)),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = league.position.toString(),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 13.sp,
                style = DuelTabularDigits,
                color = Color.White,
                maxLines = 1,
            )
        }
    }
}

/**
 * Une ligue en grand : son illustration sur toute la page, son nom et son seuil de trophées.
 * Dessinée par-dessus la route ; elle absorbe les touches pour que la route ne défile pas dessous.
 */
@Composable
private fun DuelLeaguePreview(
    league: DuelLeague,
    reached: Boolean,
    standing: DuelLeagueStanding?,
    language: AppLanguage,
    onClose: () -> Unit,
) {
    val context = LocalContext.current
    // L'illustration recule doucement pendant que le texte apparaît.
    val reveal = remember(league.position) { Animatable(0f) }
    LaunchedEffect(league.position) {
        reveal.animateTo(1f, tween(durationMillis = 700, easing = LinearOutSlowInEasing))
    }
    Box(
        modifier = Modifier
            .fillMaxSize()
            // L'illustration démarre agrandie : elle ne déborde pas sur la barre d'onglets.
            .clipToBounds()
            .background(DuelTheme.scrim)
            .pointerInput(Unit) { detectTapGestures { } },
    ) {
        DuelLeagueBackdrop(
            league = league,
            modifier = Modifier.matchParentSize().graphicsLayer {
                val scale = 1.12f - 0.12f * reveal.value
                scaleX = scale
                scaleY = scale
            },
        )
        Box(
            modifier = Modifier
                .matchParentSize()
                .background(
                    Brush.verticalGradient(
                        listOf(
                            DuelTheme.scrim.copy(alpha = 0.25f),
                            Color.Transparent,
                            DuelTheme.scrim.copy(alpha = 0.9f),
                        ),
                    ),
                ),
        )
        Column(
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer { alpha = reveal.value }
                .padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            DuelRoundIconButton(
                icon = Icons.Filled.Close,
                contentDescription = StringStore.text(context, "common.close", language),
                onClick = onClose,
                // La fermeture vibre déjà (`DuelHaptic.Tap`).
                haptic = false,
                modifier = Modifier.align(Alignment.End),
            )
            Spacer(Modifier.weight(1f))
            Text(
                text = StringStore.text(context, "duel.league.position", language, league.position).uppercaseInApp(),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 12.sp,
                letterSpacing = 0.8.sp,
                color = DuelPalette.saffron,
            )
            DuelFitText(
                text = DuelFormat.leagueName(context, league, language),
                fontSize = 36.sp,
                color = Color.White,
                maxLines = 2,
            )
            val caption: @Composable (String) -> Unit = { key ->
                // La petite ligne qui dit ce que compte le nombre de trophées en dessous.
                Text(
                    text = StringStore.text(context, key, language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Medium,
                    fontSize = 13.sp,
                    color = DuelTheme.onArtSecondary,
                    modifier = Modifier.padding(top = 4.dp),
                )
            }
            if (standing != null) {
                // Sa propre ligue : ses trophées et sa jauge passent devant. Le seuil seul (0
                // pour la première ligue) se lisait comme « tu as 0 trophée ».
                caption("duel.league.yourTrophies")
                DuelTrophyCount(value = standing.trophies, language = language, size = 26.dp, color = Color.White)
                // La jauge se remplit pendant que la ligue se dévoile.
                var gaugeShown by remember(league.position) { mutableStateOf(false) }
                LaunchedEffect(league.position) { gaugeShown = true }
                val gauge by animateFloatAsState(
                    targetValue = if (gaugeShown) standing.progress else 0f,
                    animationSpec = tween(durationMillis = 700, delayMillis = 350, easing = FastOutSlowInEasing),
                    label = "duelPreviewGauge",
                )
                DuelProgressBar(progress = gauge, height = 8.dp)
                Text(
                    text = if (standing.next != null) {
                        StringStore.text(
                            context,
                            "duel.league.toNext",
                            language,
                            maxOf(standing.next.minTrophies - standing.trophies, 0),
                            DuelFormat.leagueName(context, standing.next, language),
                        )
                    } else {
                        StringStore.text(context, "duel.league.top", language)
                    },
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Medium,
                    fontSize = 13.sp,
                    color = DuelTheme.onArtSecondary,
                )
            } else {
                caption("duel.league.required")
                Row(
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    DuelTrophyCount(value = league.minTrophies, language = language, size = 18.dp, color = Color.White)
                    if (!reached) {
                        Icon(
                            Icons.Filled.Lock,
                            contentDescription = null,
                            tint = Color.White.copy(alpha = 0.75f),
                            modifier = Modifier.size(14.dp),
                        )
                    }
                }
            }
        }
    }
}

/** Où en est le joueur dans sa ligue : ce que la ligue en grand montre quand c'est la sienne. */
private data class DuelLeagueStanding(val trophies: Int, val progress: Float, val next: DuelLeague?)

/**
 * Passe ce qui est dessiné en niveaux de gris. Le fond d'une ligue charge son image lui-même :
 * le filtre est donc posé sur le calque entier plutôt que sur l'image.
 */
private fun Modifier.duelGrayscale(enabled: Boolean): Modifier =
    if (!enabled) {
        this
    } else {
        drawWithCache {
            val paint = Paint().apply {
                colorFilter = ColorFilter.colorMatrix(ColorMatrix().apply { setToSaturation(0f) })
            }
            onDrawWithContent {
                drawIntoCanvas { canvas ->
                    canvas.saveLayer(Rect(Offset.Zero, size), paint)
                    drawContent()
                    canvas.restore()
                }
            }
        }
    }
