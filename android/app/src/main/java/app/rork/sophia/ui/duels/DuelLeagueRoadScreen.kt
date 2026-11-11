package app.rork.sophia.ui.duels

import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
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
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.DuelHome
import app.rork.sophia.domain.DuelLeague
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.newgen.NewGenBackHeader
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.uppercaseInApp

// Hauteurs d'une ligne de la route : fixes, pour savoir où est la ligue du joueur avant même
// le premier affichage et ouvrir la page dessus.
private val CARD_HEIGHT = 124.dp
private val CURRENT_CARD_HEIGHT = 176.dp
private val ROW_GAP = 14.dp
private val ROAD_TOP_PADDING = 8.dp

/**
 * La route des ligues : les 30 ligues de la plus haute (en haut) à la première (en bas), chacune
 * avec son illustration et le nombre de trophées qu'elle demande. Les ligues atteintes sont en
 * couleur, celle du joueur est mise en avant avec sa jauge, les suivantes sont voilées. La page
 * s'ouvre sur la ligue du joueur ; toucher une ligue l'affiche en grand.
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
    var preview by remember { mutableStateOf<DuelLeague?>(null) }
    val currentPosition = home.currentLeague?.position ?: 1
    // De la plus haute à la première, comme une route qu'on monte.
    val leagues = remember(home.leagues) { home.leagues.asReversed() }

    BackHandler(enabled = backEnabled) {
        if (preview != null) preview = null else onBack()
    }

    Box(modifier = modifier.fillMaxSize().background(DS.canvas)) {
        Column(modifier = Modifier.fillMaxSize()) {
            NewGenBackHeader(
                language = language,
                onBack = onBack,
                title = StringStore.text(context, "duel.league.road", language),
                trailing = {
                    DuelTrophyCount(value = home.profile.trophies, language = language, size = 16.dp, color = DS.ink)
                },
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 10.dp),
            )
            BoxWithConstraints(modifier = Modifier.fillMaxWidth().weight(1f)) {
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
                        .padding(horizontal = 20.dp)
                        .padding(top = ROAD_TOP_PADDING, bottom = 28.dp),
                ) {
                    leagues.forEachIndexed { index, league ->
                        val reached = league.position <= currentPosition
                        val isCurrent = league.position == currentPosition
                        LeagueRow(
                            league = league,
                            home = home,
                            language = language,
                            reached = reached,
                            isCurrent = isCurrent,
                            isTop = index == 0,
                            isBottom = index == leagues.lastIndex,
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
    isTop: Boolean,
    isBottom: Boolean,
    onClick: () -> Unit,
) {
    val cardHeight = if (isCurrent) CURRENT_CARD_HEIGHT else CARD_HEIGHT
    Row(modifier = Modifier.fillMaxWidth().height(cardHeight + ROW_GAP)) {
        LeagueRail(reached = reached, isCurrent = isCurrent, isTop = isTop, isBottom = isBottom)
        Spacer(Modifier.width(14.dp))
        LeagueCard(
            league = league,
            home = home,
            language = language,
            reached = reached,
            isCurrent = isCurrent,
            height = cardHeight,
            onClick = onClick,
            modifier = Modifier.weight(1f).padding(vertical = ROW_GAP / 2),
        )
    }
}

/** Le trait de la route et son repère : safran jusqu'à la ligue du joueur, gris au-delà. */
@Composable
private fun LeagueRail(reached: Boolean, isCurrent: Boolean, isTop: Boolean, isBottom: Boolean) {
    Box(modifier = Modifier.width(28.dp).fillMaxHeight(), contentAlignment = Alignment.Center) {
        Column(modifier = Modifier.fillMaxHeight(), horizontalAlignment = Alignment.CenterHorizontally) {
            // Au-dessus de la ligue du joueur, la route n'est pas encore parcourue.
            Box(
                modifier = Modifier
                    .width(4.dp)
                    .weight(1f)
                    .background(
                        when {
                            isTop -> Color.Transparent
                            reached && !isCurrent -> DuelPalette.saffron
                            else -> DS.hairline
                        },
                    ),
            )
            Box(
                modifier = Modifier
                    .width(4.dp)
                    .weight(1f)
                    .background(
                        when {
                            isBottom -> Color.Transparent
                            reached -> DuelPalette.saffron
                            else -> DS.hairline
                        },
                    ),
            )
        }
        Box(
            modifier = Modifier
                .size(if (isCurrent) 26.dp else 16.dp)
                .clip(CircleShape)
                .background(if (reached) DuelPalette.saffron else DS.surface)
                .border(3.dp, if (reached) DuelPalette.saffron else DS.hairline, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            if (isCurrent) DuelTrophyIcon(size = 14.dp, tint = DuelPalette.night)
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
    height: Dp,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val shape = RoundedCornerShape(22.dp)
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(height)
            .softPress(onClick = onClick)
            .clip(shape)
            .then(if (isCurrent) Modifier.border(3.dp, DuelPalette.saffron, shape) else Modifier),
    ) {
        // Une ligue pas encore atteinte : son illustration en gris, sous un voile plus sombre.
        DuelLeagueBackdrop(
            league = league,
            thumb = true,
            modifier = Modifier.matchParentSize().duelGrayscale(!reached),
        )
        Box(
            modifier = Modifier
                .matchParentSize()
                .background(
                    Brush.verticalGradient(
                        listOf(
                            DuelPalette.night.copy(alpha = if (reached) 0.05f else 0.45f),
                            DuelPalette.night.copy(alpha = if (reached) 0.8f else 0.9f),
                        ),
                    ),
                ),
        )
        Column(
            modifier = Modifier.align(Alignment.BottomStart).fillMaxWidth().padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            if (isCurrent) {
                Text(
                    text = StringStore.text(context, "duel.league.here", language).uppercaseInApp(),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 11.sp,
                    letterSpacing = 1.2.sp,
                    color = DuelPalette.night,
                    maxLines = 1,
                    modifier = Modifier
                        .clip(CircleShape)
                        .background(DuelPalette.saffron)
                        .padding(horizontal = 9.dp, vertical = 4.dp),
                )
            }
            DuelFitText(
                text = DuelFormat.leagueName(context, league, language),
                fontSize = if (isCurrent) 24.sp else 20.sp,
                color = Color.White,
                modifier = Modifier.fillMaxWidth(),
            )
            if (isCurrent) {
                // Sa propre ligue : les trophées du joueur (et non le seuil de la ligue, 0 pour
                // la première), puis le seuil de la suivante au bout de la jauge.
                Row(verticalAlignment = Alignment.CenterVertically) {
                    DuelTrophyCount(value = home.profile.trophies, language = language, size = 15.dp, color = Color.White)
                    Spacer(Modifier.weight(1f))
                    home.nextLeague(league)?.let { next ->
                        DuelTrophyCount(
                            value = next.minTrophies,
                            language = language,
                            size = 13.dp,
                            color = Color.White.copy(alpha = 0.75f),
                        )
                    }
                }
            } else {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    DuelTrophyCount(value = league.minTrophies, language = language, size = 14.dp, color = Color.White)
                    if (!reached) {
                        Icon(
                            Icons.Filled.Lock,
                            contentDescription = null,
                            tint = Color.White.copy(alpha = 0.7f),
                            modifier = Modifier.size(12.dp),
                        )
                    }
                }
            }
            if (isCurrent) {
                DuelProgressBar(
                    progress = home.leagueProgress(home.profile.trophies),
                    height = 8.dp,
                    modifier = Modifier.padding(top = 2.dp),
                )
            }
        }
        Box(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(10.dp)
                .defaultMinSize(minWidth = 28.dp, minHeight = 28.dp)
                .clip(CircleShape)
                .background(DuelPalette.night.copy(alpha = 0.55f)),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = league.position.toString(),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 13.sp,
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
            .background(DuelPalette.night)
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
                            DuelPalette.night.copy(alpha = 0.25f),
                            Color.Transparent,
                            DuelPalette.night.copy(alpha = 0.9f),
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
            Box(
                modifier = Modifier
                    .align(Alignment.End)
                    .size(40.dp)
                    .softPress(onClick = onClose)
                    .clip(CircleShape)
                    .background(DuelPalette.night.copy(alpha = 0.5f)),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    Icons.Filled.Close,
                    contentDescription = StringStore.text(context, "common.close", language),
                    tint = Color.White,
                    modifier = Modifier.size(18.dp),
                )
            }
            Spacer(Modifier.weight(1f))
            Text(
                text = StringStore.text(context, "duel.league.position", language, league.position).uppercaseInApp(),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 12.sp,
                letterSpacing = 1.6.sp,
                color = DuelPalette.saffron,
            )
            DuelFitText(
                text = DuelFormat.leagueName(context, league, language),
                fontSize = 40.sp,
                color = Color.White,
                maxLines = 2,
            )
            val caption: @Composable (String) -> Unit = { key ->
                // La petite ligne qui dit ce que compte le nombre de trophées en dessous.
                Text(
                    text = StringStore.text(context, key, language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 13.sp,
                    color = Color.White.copy(alpha = 0.75f),
                    modifier = Modifier.padding(top = 4.dp),
                )
            }
            if (standing != null) {
                // Sa propre ligue : ses trophées et sa jauge passent devant. Le seuil seul (0
                // pour la première ligue) se lisait comme « tu as 0 trophée ».
                caption("duel.league.yourTrophies")
                DuelTrophyCount(value = standing.trophies, language = language, size = 26.dp, color = Color.White)
                DuelProgressBar(progress = standing.progress)
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
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 13.sp,
                    color = Color.White.copy(alpha = 0.85f),
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
