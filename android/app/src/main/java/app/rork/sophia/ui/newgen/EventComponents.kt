package app.rork.sophia.ui.newgen

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import app.rork.sophia.domain.Campaign
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.dsPopIn
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import coil.compose.AsyncImage
import kotlinx.coroutines.delay
import kotlin.math.abs

// Briques communes aux événements, comme `EventComponents.swift` : la carte du fil
// (`EventFeedCard`), les cartes de l'onglet Explorer et la page de l'événement
// (`EventPageScreen`). L'illustration (image de l'équipe ou éventail de couvertures), les barres
// du défi et de l'objectif commun, le badge à gagner.

/**
 * Les couleurs « papier » du site (marine, safran, crème). Fixes : elles ne suivent pas le mode
 * nuit, un bloc d'événement garde la même affiche de jour comme de nuit.
 */
object EventPalette {
    val navy = Color(0xFF1A3A6B)
    val night = Color(0xFF0B1220)
    val saffron = Color(0xFFE6B233)
    val cream = Color(0xFFFBF3E0)

    /** Texte posé sur le safran ou la crème (pastilles, bloc du défi). */
    val ink = Color(0xFF16263D)

    /** Or sombre : le sur-titre « Badge à gagner » et le symbole du badge sans illustration. */
    val gold = Color(0xFF6B4E00)

    /** Le fond de l'en-tête de la page d'un événement, sous l'illustration. */
    val pageHeader = Color(0xFF14246E)

    /** Le bleu clair des textes secondaires posés sur un fond marine. */
    val softText = Color(0xFFC9D6EE)
}

/**
 * L'illustration d'un événement, qui remplit la place qu'on lui donne : l'image posée par
 * l'équipe quand il y en a une, sinon un éventail des couvertures de la collection sur fond marine.
 */
@Composable
fun EventArtwork(
    campaign: Campaign,
    courses: List<CourseSummary>,
    modifier: Modifier = Modifier,
    /** Remonte l'éventail (fraction de la hauteur) quand un titre recouvre le bas du cadre ; négatif : le descend. */
    collageLift: Float = 0f,
) {
    Box(modifier = modifier.clipToBounds().background(EventPalette.navy), contentAlignment = Alignment.Center) {
        val imageUrl = campaign.imageUrl
        if (imageUrl == null) {
            EventCoverCollage(courses = courses.take(3), symbol = campaign.symbol, lift = collageLift)
        } else {
            // Le temps que l'image arrive (ou si elle n'arrive pas) : le symbole, discret.
            CampaignSymbol(symbol = campaign.symbol, size = 40.dp, tint = EventPalette.saffron.copy(alpha = 0.35f))
            AsyncImage(
                model = imageUrl,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize(),
            )
        }
    }
}

/**
 * Jusqu'à trois couvertures en éventail devant un halo safran ; le symbole de l'événement quand
 * aucun cours de la collection n'est encore connu de l'app.
 */
@Composable
fun EventCoverCollage(courses: List<CourseSummary>, symbol: String?, lift: Float = 0f) {
    BoxWithConstraints(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        val side = minOf(maxHeight * 0.42f, maxWidth * 0.28f)
        val count = courses.size
        Box(
            modifier = Modifier.fillMaxSize().offset(y = -maxHeight * lift),
            contentAlignment = Alignment.Center,
        ) {
            Box(modifier = Modifier.size(side * 2.6f).clip(CircleShape).background(EventPalette.saffron.copy(alpha = 0.16f)))
            Box(modifier = Modifier.size(side * 3.5f).border(1.dp, EventPalette.saffron.copy(alpha = 0.3f), CircleShape))
            if (courses.isEmpty()) {
                CampaignSymbol(symbol = symbol, size = maxOf(20.dp, side * 0.8f), tint = EventPalette.saffron)
            } else {
                courses.forEachIndexed { index, course ->
                    // -1, 0, 1 pour trois couvertures ; -0,5 et 0,5 pour deux ; 0 pour une.
                    val position = index - (count - 1) / 2f
                    val shape = RoundedCornerShape(side * 0.14f)
                    CourseCover(
                        courseId = course.id,
                        cornerRadius = side * 0.14f,
                        modifier = Modifier
                            .zIndex(-abs(position))
                            .offset(x = side * 0.72f * position, y = side * 0.1f * abs(position))
                            .rotate(position * 9f)
                            .shadow(elevation = 8.dp, shape = shape)
                            .size(width = side, height = side * 1.25f)
                            .border(2.dp, Color.White.copy(alpha = 0.9f), shape),
                    )
                }
            }
        }
    }
}

/** Une barre d'avancement en capsule (défi long), qui glisse jusqu'à sa valeur. */
@Composable
fun EventProgressBar(
    fraction: Float,
    modifier: Modifier = Modifier,
    tint: Color = EventPalette.saffron,
    track: Color = DS.surfaceMuted,
    height: Dp = 8.dp,
) {
    val shown by animateFloatAsState(fraction.coerceIn(0f, 1f), DSMotion.reveal(), label = "eventProgress")
    Box(modifier = modifier.fillMaxWidth().height(height).clip(CircleShape).background(track)) {
        Box(
            modifier = Modifier
                .fillMaxWidth(shown.coerceIn(0f, 1f))
                .fillMaxHeight()
                .clip(CircleShape)
                .background(tint),
        )
    }
}

/**
 * L'avancement du défi : un segment par cours à lire tant qu'il y en a peu (huit au plus), une
 * barre continue au-delà.
 */
@Composable
fun EventChallengeMeter(
    done: Int,
    target: Int,
    modifier: Modifier = Modifier,
    tint: Color = EventPalette.saffron,
    track: Color = DS.surfaceMuted,
    height: Dp = 8.dp,
) {
    val total = maxOf(1, target)
    if (total <= 8) {
        Row(modifier = modifier.fillMaxWidth().height(height), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            repeat(total) { index ->
                val color by animateColorAsState(if (index < done) tint else track, DSMotion.snappy(), label = "eventSegment")
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxHeight()
                        .clip(CircleShape)
                        .background(color),
                )
            }
        }
    } else {
        EventProgressBar(fraction = done.toFloat() / total, modifier = modifier, tint = tint, track = track, height = height)
    }
}

/**
 * Le badge de l'événement dans un anneau qui se remplit avec le défi : son illustration quand
 * l'équipe en a choisi une, sinon le symbole de l'événement, nu dans son anneau. Une coche quand
 * il est gagné. L'anneau part de zéro et rejoint la vraie valeur à l'apparition.
 */
@Composable
fun EventBadgeRing(
    campaign: Campaign,
    done: Int,
    modifier: Modifier = Modifier,
    size: Dp = 96.dp,
    /** La couleur de l'anneau vide, selon le fond sur lequel le badge est posé. */
    track: Color = DS.hairline,
) {
    val target = maxOf(1, campaign.challengeTarget)
    val fraction = (done.toFloat() / target).coerceIn(0f, 1f)
    val earned = done >= target
    val line = maxOf(3.5.dp, size * 0.065f)
    val inner = size - line * 3.2f
    val drawn = remember { Animatable(0f) }
    LaunchedEffect(fraction) {
        if (drawn.value == 0f) delay(150)
        drawn.animateTo(fraction, DSMotion.reveal())
    }
    Box(modifier = modifier.size(size), contentAlignment = Alignment.Center) {
        Canvas(modifier = Modifier.fillMaxSize().padding(line / 2)) {
            val stroke = line.toPx()
            val inset = stroke / 2
            val arcSize = Size(this.size.width - stroke, this.size.height - stroke)
            drawArc(
                color = track,
                startAngle = 0f,
                sweepAngle = 360f,
                useCenter = false,
                topLeft = Offset(inset, inset),
                size = arcSize,
                style = Stroke(width = stroke),
            )
            val shown = drawn.value.coerceIn(0f, 1f)
            if (shown > 0f) {
                drawArc(
                    color = EventPalette.saffron,
                    startAngle = -90f,
                    sweepAngle = 360f * shown,
                    useCenter = false,
                    topLeft = Offset(inset, inset),
                    size = arcSize,
                    style = Stroke(width = stroke, cap = StrokeCap.Round),
                )
            }
        }
        Box(
            modifier = Modifier.size(inner).clip(CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            CampaignSymbol(symbol = campaign.symbol, size = inner * 0.46f, tint = EventPalette.gold)
            campaign.badgeImageUrl?.let { url ->
                AsyncImage(
                    model = url,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize(),
                )
            }
        }
        if (earned) {
            val seal = maxOf(14.dp, size * 0.26f)
            Box(
                modifier = Modifier.align(Alignment.BottomEnd).size(seal).dsPopIn(delayMillis = 350),
                contentAlignment = Alignment.Center,
            ) {
                Box(modifier = Modifier.size(seal * 0.7f).clip(CircleShape).background(Color.White))
                Icon(
                    imageVector = Icons.Filled.Verified,
                    contentDescription = null,
                    tint = EventPalette.saffron,
                    modifier = Modifier.fillMaxSize(),
                )
            }
        }
    }
}

/** Pastille d'un événement posée sur son illustration : safran pour la date, sombre pour « Terminé ». */
@Composable
fun EventPill(text: String, modifier: Modifier = Modifier, dark: Boolean = false) {
    Box(
        modifier = modifier
            .height(26.dp)
            .clip(CircleShape)
            .background(if (dark) EventPalette.night.copy(alpha = 0.78f) else EventPalette.saffron)
            .padding(horizontal = 10.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 12.sp,
            color = if (dark) Color.White else EventPalette.ink,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}
