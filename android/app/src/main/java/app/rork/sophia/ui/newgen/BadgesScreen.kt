package app.rork.sophia.ui.newgen

import android.content.Context
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
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
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.WorkspacePremium
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.catalog.CatalogStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Badge
import app.rork.sophia.domain.BadgeFamily
import app.rork.sophia.domain.BadgeMetric
import app.rork.sophia.domain.BadgeRules
import app.rork.sophia.domain.BadgeStats
import app.rork.sophia.domain.Campaign
import app.rork.sophia.domain.Subject
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.domain.locale
import app.rork.sophia.domain.uppercaseIn
import app.rork.sophia.ui.components.CalmProgressBar
import app.rork.sophia.ui.components.SophiaPrimaryButton
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.onboarding.ConfettiBurst
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import coil.compose.AsyncImage
import kotlinx.coroutines.delay
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

// Les badges à l'écran, comme `BadgesView.swift` et `BadgeCelebrationView.swift` sur iOS : le
// médaillon, la page de toute la collection, le détail d'un badge, la rangée du profil et la
// fête d'un badge gagné.

/** Le nom d'un badge dans la langue de l'app. */
fun Badge.title(context: Context, language: AppLanguage): String = when {
    leagueName != null -> StringStore.text(context, "duel.league.name", language, leagueName)
    eventNames != null -> Campaign.localized(eventNames, language)
    else -> StringStore.text(context, "badge.name.$id", language)
}

/** Ce qu'il faut faire pour l'obtenir. */
fun Badge.condition(context: Context, language: AppLanguage): String {
    fun text(key: String, vararg args: Any) = StringStore.text(context, "badge.cond.$key", language, *args)
    return when (val m = metric) {
        BadgeMetric.Streak -> text("streak", target)
        BadgeMetric.Courses -> if (target == 1) text("firstCourse") else text("courses", target)
        BadgeMetric.EarlyCourse -> text("early")
        BadgeMetric.LateCourse -> text("late")
        BadgeMetric.CoursesInOneDay -> text("binge", target)
        is BadgeMetric.SubjectCourses -> {
            val name = Subject.fromStorageKey(m.key)?.let { StringStore.text(context, "subject.${it.storageKey}.short", language) } ?: m.key
            text("subject", target, name)
        }
        BadgeMetric.SubjectsCovered -> text("allSubjects")
        BadgeMetric.Quizzes -> text("quiz", target)
        BadgeMetric.DuelWins -> if (target == 1) text("firstDuel") else text("duelWins", target)
        BadgeMetric.DuelBestScore -> if (target >= 20) text("duelPerfect") else text("duelScore", target)
        BadgeMetric.DuelBestMargin -> text("duelMargin", target)
        BadgeMetric.DuelTiebreakWins -> text("duelTiebreak")
        BadgeMetric.DuelBestWinStreak -> text("duelStreak", target)
        BadgeMetric.RivalWins -> text("rival")
        BadgeMetric.Follows -> text("follows", target)
        BadgeMetric.Likes -> text("likes", target)
        BadgeMetric.Friends -> text("friends", target)
        BadgeMetric.League -> text("league", leagueName.orEmpty())
        is BadgeMetric.Event -> text("event", target, eventTitles?.let { Campaign.localized(it, language) }.orEmpty())
    }
}

private val GRAYSCALE = ColorFilter.colorMatrix(ColorMatrix().apply { setToSaturation(0f) })

/**
 * Le rond d'un badge : son illustration en papier découpé (embarquée, ou hébergée pour un
 * événement), cerclée d'or quand il est gagné, grisée sinon. Tant que l'illustration n'existe
 * pas, un pictogramme sur un fond uni.
 */
@Composable
fun BadgeMedal(badge: Badge, earned: Boolean, modifier: Modifier = Modifier, size: Dp = 64.dp) {
    val context = LocalContext.current
    val resource = remember(badge.imageName) {
        badge.imageName?.let { context.resources.getIdentifier(it, "drawable", context.packageName) }?.takeIf { it != 0 }
    }
    Box(
        modifier = modifier
            .size(size)
            // Pas encore gagné : l'image reste reconnaissable, mais éteinte.
            .alpha(if (earned) 1f else 0.45f)
            .clip(CircleShape)
            .background(if (earned) DS.accent else DS.surfaceMuted)
            .border(if (earned) maxOf(2.dp, size * 0.045f) else 1.dp, if (earned) DS.warm else DS.hairline, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        when {
            resource != null -> Image(
                painter = painterResource(resource),
                contentDescription = null,
                contentScale = ContentScale.Crop,
                colorFilter = if (earned) null else GRAYSCALE,
                modifier = Modifier.fillMaxSize().clip(CircleShape),
            )
            badge.imageUrl != null -> AsyncImage(
                model = badge.imageUrl,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                colorFilter = if (earned) null else GRAYSCALE,
                modifier = Modifier.fillMaxSize().clip(CircleShape),
            )
            badge.family == BadgeFamily.EVENTS -> CampaignSymbol(
                symbol = badge.symbol,
                size = size * 0.4f,
                tint = if (earned) DS.warm else DS.inkTertiary,
            )
            else -> Icon(
                imageVector = Icons.Filled.WorkspacePremium,
                contentDescription = null,
                tint = if (earned) DS.warm else DS.inkTertiary,
                modifier = Modifier.size(size * 0.45f),
            )
        }
    }
}

/**
 * Quelques médaillons avec leur nom, côte à côte : les badges qu'une personne affiche. Toutes les
 * cases ont la même hauteur : le titre réserve toujours deux lignes.
 */
@Composable
fun BadgeRow(
    badges: List<Badge>,
    language: AppLanguage,
    earned: (Badge) -> Boolean,
    modifier: Modifier = Modifier,
    onTap: ((Badge) -> Unit)? = null,
) {
    val context = LocalContext.current
    val shape = RoundedCornerShape(18.dp)
    Row(modifier = modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        badges.forEach { badge ->
            Column(
                modifier = Modifier
                    .weight(1f)
                    .then(if (onTap != null) Modifier.softPress(onClick = { onTap(badge) }) else Modifier)
                    .clip(shape)
                    .background(DS.surface)
                    .border(1.dp, DS.hairline, shape)
                    .padding(horizontal = 6.dp, vertical = 14.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                BadgeMedal(badge = badge, earned = earned(badge), size = 60.dp)
                Text(
                    text = badge.title(context, language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 13.sp,
                    lineHeight = 17.sp,
                    color = DS.ink,
                    textAlign = TextAlign.Center,
                    minLines = 2,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
    }
}

/**
 * Toute la collection : les badges affichés sur le profil (trois au plus) en tête, puis chaque
 * famille en grille, gagnés en couleur, les autres grisés avec leur avancement. Toucher un badge
 * ouvre son détail, d'où on l'ajoute au profil ou on l'en retire.
 */
@Composable
fun BadgesScreen(
    language: AppLanguage,
    progress: UserProgress,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val center = app.badgeCenter
    val campaigns by CatalogStore.campaigns.collectAsState()
    LaunchedEffect(Unit) { center.refresh() }

    val badges = remember(campaigns, language) { center.visibleBadges() }
    val stats = remember(progress, campaigns) { center.stats(progress) }
    val earnedCount = badges.count { it.id in progress.earnedBadges }
    var selected by remember { mutableStateOf<Badge?>(null) }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState())
            .padding(start = 20.dp, end = 20.dp, top = 12.dp, bottom = 44.dp),
        verticalArrangement = Arrangement.spacedBy(26.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    text = StringStore.text(context, "profile.badges", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 28.sp,
                    color = DS.ink,
                )
                Text(
                    text = StringStore.text(context, "badge.progress", language, earnedCount, badges.size),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 15.sp,
                    color = DS.inkSecondary,
                )
            }
            RoundIconButton(
                icon = Icons.Filled.Close,
                onClick = onBack,
                contentDescription = StringStore.text(context, "common.close", language),
            )
        }

        // Les trois emplacements du profil : les badges choisis, puis des ronds vides.
        val featured = progress.featuredBadgeIds.filter { it in progress.earnedBadges }.mapNotNull { center.badge(it) }
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(18.dp))
                .background(DS.surface)
                .border(1.dp, DS.hairline, RoundedCornerShape(18.dp))
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(
                text = StringStore.text(context, "badges.featured.title", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 15.sp,
                color = DS.ink,
            )
            Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                repeat(BadgeRules.MAX_FEATURED) { index ->
                    val badge = featured.getOrNull(index)
                    if (badge != null) {
                        BadgeMedal(badge = badge, earned = true, size = 60.dp, modifier = Modifier.softPress(onClick = { selected = badge }))
                    } else {
                        Box(modifier = Modifier.size(60.dp).dashedBorder(DS.inkTertiary, 30.dp))
                    }
                }
            }
        }

        BadgeFamily.entries.forEach { family ->
            val items = badges.filter { it.family == family }
            if (items.isEmpty()) return@forEach
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                NewGenSectionTitle(
                    text = StringStore.text(context, family.titleKey, language),
                    trailing = "${items.count { it.id in progress.earnedBadges }}/${items.size}",
                )
                // Trois colonnes, à la main : la grille vit dans un écran déjà défilant.
                items.chunked(3).forEach { row ->
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        row.forEach { badge ->
                            BadgeCell(
                                badge = badge,
                                earned = badge.id in progress.earnedBadges,
                                stats = stats,
                                language = language,
                                onClick = { selected = badge },
                                modifier = Modifier.weight(1f),
                            )
                        }
                        repeat(3 - row.size) { Spacer(Modifier.weight(1f)) }
                    }
                }
            }
        }
    }

    selected?.let { badge ->
        BadgeDetailSheet(badge = badge, progress = progress, stats = stats, language = language, onDismiss = { selected = null })
    }
}

/**
 * Une case de la grille. Toutes ont la même taille : le titre réserve toujours deux lignes et la
 * ligne d'avancement garde sa place même quand elle est vide (badge gagné).
 */
@Composable
private fun BadgeCell(
    badge: Badge,
    earned: Boolean,
    stats: BadgeStats,
    language: AppLanguage,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val showsProgress = !earned && badge.target > 1 && badge.metric != BadgeMetric.League
    val shape = RoundedCornerShape(18.dp)
    Column(
        modifier = modifier
            .softPress(onClick = onClick)
            .clip(shape)
            .background(DS.surface)
            .border(1.dp, DS.hairline, shape)
            .padding(horizontal = 6.dp, vertical = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        BadgeMedal(badge = badge, earned = earned, size = 68.dp)
        Text(
            text = badge.title(context, language),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 13.sp,
            lineHeight = 17.sp,
            color = if (earned) DS.ink else DS.inkSecondary,
            textAlign = TextAlign.Center,
            minLines = 2,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            text = if (showsProgress) StringStore.text(context, "badge.progress", language, stats.progress(badge), badge.target) else " ",
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 11.sp,
            color = DS.inkTertiary,
            maxLines = 1,
        )
    }
}

/**
 * Le badge en grand, sa condition, la date où il a été gagné (ou l'avancement), et le bouton qui
 * l'affiche sur le profil ou l'en retire. La feuille s'arrête à la hauteur de son contenu.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun BadgeDetailSheet(
    badge: Badge,
    progress: UserProgress,
    stats: BadgeStats,
    language: AppLanguage,
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val earnedAt = progress.earnedBadges[badge.id]
    val earned = earnedAt != null
    val featured = badge.id in progress.featuredBadgeIds && earned
    var showFull by remember { mutableStateOf(false) }
    ModalBottomSheet(onDismissRequest = onDismiss, containerColor = DS.canvas) {
        Column(
            modifier = Modifier.fillMaxWidth().navigationBarsPadding().padding(horizontal = 24.dp).padding(bottom = 20.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            BadgeMedal(badge = badge, earned = earned, size = 120.dp)
            Text(
                text = badge.title(context, language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 22.sp,
                color = DS.ink,
                textAlign = TextAlign.Center,
            )
            Text(
                text = badge.condition(context, language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Medium,
                fontSize = 15.sp,
                lineHeight = 21.sp,
                color = DS.inkSecondary,
                textAlign = TextAlign.Center,
            )
            if (earned) {
                val date = remember(earnedAt, language) {
                    runCatching {
                        Instant.parse(earnedAt).atZone(ZoneId.systemDefault()).toLocalDate()
                            .format(DateTimeFormatter.ofLocalizedDate(FormatStyle.LONG).withLocale(language.locale))
                    }.getOrNull()
                }
                if (date != null) {
                    Text(
                        text = StringStore.text(context, "badges.earnedOn", language, date),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 13.sp,
                        color = DS.success,
                    )
                }
                if (showFull) {
                    Text(
                        text = StringStore.text(context, "badges.featured.full", language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Medium,
                        fontSize = 12.sp,
                        color = DS.danger,
                        textAlign = TextAlign.Center,
                    )
                }
                val shape = RoundedCornerShape(14.dp)
                Box(
                    modifier = Modifier
                        .padding(top = 8.dp)
                        .fillMaxWidth()
                        .height(50.dp)
                        .softPress(onClick = { showFull = !app.progressManager.toggleFeaturedBadge(badge.id) })
                        .clip(shape)
                        .background(if (featured) DS.surface else DS.accent)
                        .then(if (featured) Modifier.border(1.dp, DS.hairline, shape) else Modifier),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = StringStore.text(context, if (featured) "badges.featured.remove" else "badges.featured.add", language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp,
                        color = if (featured) DS.ink else Color.White,
                    )
                }
            } else {
                if (badge.target > 1 && badge.metric != BadgeMetric.League) {
                    CalmProgressBar(
                        fraction = stats.progress(badge).toFloat() / badge.target,
                        modifier = Modifier.widthIn(max = 220.dp),
                    )
                }
                Text(
                    text = StringStore.text(context, "badges.locked", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 13.sp,
                    color = DS.inkTertiary,
                )
            }
        }
    }
}

// ---------------------------------------------------------------- fête d'un badge

/**
 * Posé par-dessus les onglets : montre, un par un, les badges que `BadgeCenter` met en file, dès
 * que l'écran est libre ([screenFree] : ni cours, ni quiz, ni duel, ni feuille par-dessus).
 */
@Composable
fun BadgeCelebrationHost(screenFree: Boolean, language: AppLanguage, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val center = (context.applicationContext as SophiaApplication).badgeCenter
    val current by center.current.collectAsState()
    val pending by center.pending.collectAsState()
    // Au retour sur les onglets : une série ou un événement a pu bouger entre-temps.
    LaunchedEffect(screenFree) { if (screenFree) center.scheduleDetection() }
    LaunchedEffect(screenFree, pending, current) {
        if (screenFree && current == null && pending > 0) {
            // Laisse l'écran courant se poser (et la fête précédente s'effacer).
            delay(600)
            center.presentNext()
        }
    }
    current?.let { badge ->
        androidx.compose.runtime.key(badge.id) {
            BadgeCelebration(badge = badge, language = language, onContinue = { center.dismissCurrent() }, modifier = modifier)
        }
    }
}

/**
 * Un badge vient d'être gagné : fond assombri, le médaillon qui arrive en rebondissant sur des
 * rayons dorés, une pluie de confettis, son nom, sa condition, et « Continuer ».
 */
@Composable
private fun BadgeCelebration(badge: Badge, language: AppLanguage, onContinue: () -> Unit, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val medalSize = 136.dp
    val backdrop = remember { Animatable(0f) }
    val medal = remember { Animatable(0f) }
    val textIn = remember { Animatable(0f) }
    var showConfetti by remember { mutableStateOf(false) }
    // Un toucher parti avant la fête (défilement en cours) ne doit pas la fermer aussitôt.
    var canDismiss by remember { mutableStateOf(false) }
    val haptics = androidx.compose.ui.platform.LocalHapticFeedback.current
    LaunchedEffect(Unit) {
        backdrop.animateTo(1f, tween(250))
        haptics.performHapticFeedback(androidx.compose.ui.hapticfeedback.HapticFeedbackType.LongPress)
        showConfetti = true
        medal.animateTo(1f, spring(dampingRatio = 0.55f, stiffness = 220f))
        textIn.animateTo(1f, tween(350))
    }
    LaunchedEffect(Unit) {
        delay(700)
        canDismiss = true
    }
    val spin by rememberInfiniteTransition(label = "badgeRays").animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(tween(18_000, easing = LinearEasing), RepeatMode.Restart),
        label = "badgeRaysSpin",
    )
    androidx.activity.compose.BackHandler { if (canDismiss) onContinue() }
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.62f * backdrop.value))
            .pointerInput(Unit) { detectTapGestures { if (canDismiss) onContinue() } },
        contentAlignment = Alignment.Center,
    ) {
        val shape = RoundedCornerShape(30.dp)
        Column(
            modifier = Modifier
                .padding(horizontal = 28.dp)
                .widthIn(max = 420.dp)
                .graphicsLayer {
                    alpha = backdrop.value
                    val scale = 0.92f + 0.08f * backdrop.value
                    scaleX = scale
                    scaleY = scale
                }
                .shadow(24.dp, shape)
                .clip(shape)
                .background(DS.canvas)
                .border(1.dp, DS.hairline, shape)
                // Un toucher sur la carte ne ferme pas la fête.
                .pointerInput(Unit) { detectTapGestures { } }
                .padding(start = 22.dp, end = 22.dp, top = 10.dp, bottom = 22.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(modifier = Modifier.fillMaxWidth().height(medalSize + 56.dp), contentAlignment = Alignment.Center) {
                val warm = DS.warm
                Canvas(
                    modifier = Modifier
                        .size(medalSize * 1.5f)
                        .graphicsLayer {
                            alpha = medal.value.coerceIn(0f, 1f)
                            val scale = 0.4f + 0.6f * medal.value
                            scaleX = scale
                            scaleY = scale
                        }
                        .rotate(spin),
                ) {
                    // Quatorze rayons dorés, qui s'effacent vers l'extérieur.
                    val center = Offset(size.width / 2, size.height / 2)
                    val radius = size.minDimension / 2
                    val brush = Brush.radialGradient(
                        colors = listOf(warm.copy(alpha = 0.55f), warm.copy(alpha = 0f)),
                        center = center,
                        radius = radius,
                    )
                    val count = 14
                    val half = (PI / count / 2).toFloat()
                    repeat(count) { index ->
                        val angle = (2 * PI * index / count).toFloat()
                        val path = Path().apply {
                            moveTo(center.x, center.y)
                            lineTo(center.x + radius * cos(angle - half), center.y + radius * sin(angle - half))
                            lineTo(center.x + radius * cos(angle + half), center.y + radius * sin(angle + half))
                            close()
                        }
                        drawPath(path, brush)
                    }
                }
                BadgeMedal(
                    badge = badge,
                    earned = true,
                    size = medalSize,
                    modifier = Modifier.graphicsLayer {
                        alpha = medal.value.coerceIn(0f, 1f)
                        val scale = 0.2f + 0.8f * medal.value
                        scaleX = scale
                        scaleY = scale
                        rotationZ = -24f * (1f - medal.value)
                    },
                )
            }
            Column(
                modifier = Modifier.padding(top = 4.dp).graphicsLayer {
                    alpha = textIn.value
                    translationY = 14.dp.toPx() * (1f - textIn.value)
                },
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Text(
                    text = StringStore.text(context, "badgeCelebration.kicker", language).uppercaseIn(language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 12.sp,
                    letterSpacing = 1.2.sp,
                    color = DS.accent,
                    textAlign = TextAlign.Center,
                )
                Text(
                    text = badge.title(context, language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 28.sp,
                    lineHeight = 33.sp,
                    color = DS.ink,
                    textAlign = TextAlign.Center,
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis,
                )
                Text(
                    text = badge.condition(context, language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Medium,
                    fontSize = 15.sp,
                    lineHeight = 21.sp,
                    color = DS.inkSecondary,
                    textAlign = TextAlign.Center,
                    maxLines = 4,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            SophiaPrimaryButton(
                text = StringStore.text(context, "common.continue", language),
                onClick = onContinue,
                modifier = Modifier.padding(top = 24.dp).alpha(textIn.value),
            )
        }
        if (showConfetti) {
            ConfettiBurst(
                colors = listOf(DS.warm, DS.accent, DS.accentSoft, DS.success),
                modifier = Modifier.fillMaxSize(),
                pieceCount = 70,
                durationMillis = 2600,
                origin = Offset(0.5f, 0.36f),
            )
        }
    }
}
