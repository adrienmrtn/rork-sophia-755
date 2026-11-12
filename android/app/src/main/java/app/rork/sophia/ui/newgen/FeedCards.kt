package app.rork.sophia.ui.newgen

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
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
import androidx.compose.material.icons.automirrored.filled.ArrowForwardIos
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Language
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.outlined.Group
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
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
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.CampaignStore
import app.rork.sophia.data.CourseAuthor
import app.rork.sophia.data.LocalCounters
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.analytics.Analytics
import app.rork.sophia.data.compactCount
import app.rork.sophia.data.rememberCourseInfo
import app.rork.sophia.data.stripInlineMarkup
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Campaign
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.domain.formatted
import app.rork.sophia.domain.realReadsCount
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.course.AuthorAvatar
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import coil.compose.AsyncImage
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.layout.Layout
import app.rork.sophia.data.rememberCourseSummaries
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Group
import androidx.compose.ui.graphics.Brush
import androidx.compose.foundation.layout.heightIn

/**
 * Un élément du fil d'accueil. Les cartes vidéo n'existent pas encore (prompt 10) : le cas
 * est là pour que la mise en page les accueille sans changer le fil.
 */
sealed class FeedItem(val id: String) {
    data class CourseCard(val course: CourseSummary) : FeedItem("course:${course.id}")
    data class CampaignCard(val campaign: Campaign) : FeedItem("campaign:${campaign.slug}")
    data object CreatorInvite : FeedItem("creator-invite")
    data class Video(val videoId: String) : FeedItem("video:$videoId")
    /** Une page de texte quand il n'y a rien à montrer (aucun abonnement, tout est lu…). */
    data class Notice(val notice: FeedNotice) : FeedItem("notice:${notice.name}")

    val courseId: String? get() = (this as? CourseCard)?.course?.id
}

enum class FeedNotice { FOLLOWING_EMPTY, FOLLOWING_UP_TO_DATE, ALL_CAUGHT_UP }

/** La hauteur sous laquelle la couverture d'une carte du fil paginé ne descend pas. */
private val FEED_COVER_MIN_HEIGHT = 110.dp

/** Rose des cœurs allumés, comme sur iOS (`DS.liked`). */
internal val LikedTint = Color(0xFFD6336C)

// MARK: - Carte cours

/**
 * La carte de cours de la maquette : couverture 16:9 avec la pastille de matière, titre,
 * accroche, ligne créateur, puis lectures · j'aime · durée. (Enregistrer et partager se font
 * depuis le cours ouvert, plus depuis la carte.)
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun CourseFeedCard(
    course: CourseSummary,
    language: AppLanguage,
    progress: UserProgress,
    progressManager: ProgressManager,
    onOpen: () -> Unit,
    onOpenCreator: (CourseAuthor) -> Unit,
    modifier: Modifier = Modifier,
    /** Étiquette à côté de la matière : « Nouveau » ou le nom d'un événement. */
    tag: String? = null,
    tagStyle: TagPillStyle = TagPillStyle.ACCENT,
    /** Petite ligne au-dessus du titre (onglet Abonnements). */
    kicker: String? = null,
    /** Écran rapporté dans les événements `like` / `save`. */
    screen: String = "home",
    /**
     * Dans le fil paginé, la carte remplit sa page : la couverture prend toute la hauteur que
     * le texte et les compteurs laissent libre, au lieu d'un vide sous l'accroche.
     */
    fillsPage: Boolean = false,
    /**
     * Plafond de la couverture dans le fil paginé (un carré, en pratique) ; au-delà, le reste
     * de la hauteur revient au texte. Sans plafond ni page à remplir : 16:9.
     */
    coverMaxHeight: Dp? = null,
) {
    val context = LocalContext.current
    val identity = remember(course.id) { CreatorIdentity.forCourse(context.applicationContext, course.id) }
    val info by rememberCourseInfo(course.toStub(), language)
    val liked = course.id in progress.likedCourseIds
    val hook = info?.hook ?: stripInlineMarkup(course.description)
    val haptics = rememberHaptics()
    var likeBurst by remember(course.id) { mutableIntStateOf(0) }
    var bigHeart by remember(course.id) { mutableIntStateOf(0) }

    // Le cœur : au bouton, il bascule ; au double-tap, il n'éteint jamais (comme sur les
    // réseaux vidéo), mais le grand cœur s'affiche quand même.
    fun toggleLike(fromDoubleTap: Boolean) {
        val wasLiked = progressManager.isLiked(course.id)
        // Aimer vibre franchement (comme le double-tap) ; retirer son « j'aime », à peine.
        if (fromDoubleTap || !wasLiked) haptics.confirm() else haptics.tap()
        if (fromDoubleTap) {
            bigHeart++
            if (wasLiked) return
        }
        progressManager.toggleLike(course.id)
        if (!wasLiked) likeBurst++
        Analytics.log(if (wasLiked) "unlike" else "like", courseId = course.id, screen = screen)
    }

    // Un tap ouvre le cours, deux taps l'aiment (le simple tap attend donc un instant, le
    // temps de savoir s'il est doublé). Pression élastique : la carte s'enfonce sous le doigt
    // et revient sur un ressort.
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val pressScale by animateFloatAsState(
        targetValue = if (pressed) 0.975f else 1f,
        animationSpec = DSMotion.press(),
        label = "feedCardPress",
    )

    Box(
        modifier = modifier
            .fillMaxWidth()
            .then(if (fillsPage) Modifier.fillMaxHeight() else Modifier)
            .graphicsLayer {
                scaleX = pressScale
                scaleY = pressScale
            }
            .combinedClickable(
                interactionSource = interaction,
                indication = null,
                onClick = {
                    haptics.tap()
                    onOpen()
                },
                onDoubleClick = { toggleLike(fromDoubleTap = true) },
            )
            .sophiaCard(),
    ) {
    val cover: @Composable (Modifier) -> Unit = { coverModifier ->
        Box(modifier = coverModifier) {
            CourseCover(courseId = course.id, modifier = Modifier.fillMaxSize(), cornerRadius = 0.dp, letterSize = 42.sp)
            Row(
                modifier = Modifier.padding(12.dp),
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                SubjectPill(subject = course.subjectEnum, language = language)
                if (tag != null) TagPill(text = tag, style = tagStyle)
            }
        }
    }
    val body: @Composable (Modifier) -> Unit = { bodyModifier ->
        Column(
            modifier = bodyModifier.padding(start = 16.dp, end = 16.dp, top = 14.dp, bottom = 10.dp),
            verticalArrangement = Arrangement.spacedBy(9.dp),
        ) {
            if (kicker != null) {
                Text(
                    text = kicker,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 12.sp,
                    color = DS.inkSecondary,
                )
            }
            Text(
                text = stripInlineMarkup(course.title),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 20.sp,
                lineHeight = 26.sp,
                color = DS.ink,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                text = hook,
                fontFamily = PlusJakartaSans,
                fontSize = 15.sp,
                lineHeight = 21.sp,
                color = DS.inkSecondary,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
            )
            CreatorLine(
                identity = identity,
                language = language,
                modifier = Modifier.padding(top = 1.dp),
                onTap = identity.author?.let { author -> { onOpenCreator(author) } },
            )
            if (fillsPage) Spacer(Modifier.weight(1f))
            Box(modifier = Modifier.fillMaxWidth().height(1.dp).background(DS.hairline))
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(18.dp),
            ) {
                // Les vraies ouvertures (serveur) ; rien tant que le chiffre n'est pas arrivé.
                course.realReadsCount?.let { reads ->
                    StatChip(icon = Icons.Outlined.Visibility, text = reads.compactCount(language))
                }
                val likeLabel = StringStore.text(context, if (liked) "common.unlike" else "common.like", language)
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(5.dp),
                    modifier = Modifier
                        .pressable(onClick = { toggleLike(fromDoubleTap = false) }, scaleDown = 0.9f, haptic = false)
                        .semantics { contentDescription = likeLabel }
                        .padding(vertical = 8.dp),
                ) {
                    LikeHeartIcon(liked = liked, burst = likeBurst, size = 15.dp)
                    Text(
                        text = LocalCounters.likesCount(course.id, liked).compactCount(language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 13.sp,
                        color = if (liked) LikedTint else DS.inkSecondary,
                    )
                }
                Spacer(Modifier.weight(1f))
                info?.let { details ->
                    StatChip(
                        icon = Icons.Outlined.Schedule,
                        text = NewGenFormat.minutes(context, details.minutes, language),
                    )
                }
            }
        }
    }
    if (fillsPage) {
        // La couverture est prioritaire sur le bloc de texte : elle reçoit toute la hauteur
        // moins celle, incompressible, du texte, jusqu'à son plafond. Le plancher garde une
        // image lisible quand le texte est très grand (grande police, traductions longues) ;
        // ce qui reste au-delà du plafond revient au texte, dont les compteurs descendent en bas.
        Layout(
            content = {
                cover(Modifier.fillMaxWidth())
                body(Modifier.fillMaxWidth())
            },
            modifier = Modifier.fillMaxWidth().fillMaxHeight(),
        ) { measurables, constraints ->
            val width = constraints.maxWidth
            val height = constraints.maxHeight
            val floor = FEED_COVER_MIN_HEIGHT.roundToPx().coerceAtMost(height)
            val ceiling = (coverMaxHeight?.roundToPx() ?: height).coerceAtLeast(floor)
            val bodyNatural = measurables[1].minIntrinsicHeight(width)
            val coverPx = (height - bodyNatural).coerceIn(floor, ceiling)
            val coverPlaceable = measurables[0].measure(Constraints.fixed(width, coverPx))
            val bodyPlaceable = measurables[1].measure(Constraints.fixed(width, (height - coverPx).coerceAtLeast(0)))
            layout(width, height) {
                coverPlaceable.place(0, 0)
                bodyPlaceable.place(0, coverPx)
            }
        }
    } else {
        Column(modifier = Modifier.fillMaxWidth()) {
            cover(Modifier.fillMaxWidth().aspectRatio(16f / 9f))
            body(Modifier)
        }
    }
    BigHeartOverlay(trigger = bigHeart, modifier = Modifier.align(Alignment.Center))
    }
}

// MARK: - Carte événement

/**
 * L'événement dans le fil, comme sur iOS : l'illustration (image de l'équipe ou éventail de
 * couvertures) avec la date et le titre posés dessus, l'accroche, le nombre de cours, le défi du
 * lecteur avec son badge en anneau, et le bouton vers la collection. (L'objectif commun
 * « Ensemble : N cours lus » n'est plus affiché.)
 */
@Composable
fun EventFeedCard(
    campaign: Campaign,
    language: AppLanguage,
    progress: UserProgress,
    onOpen: () -> Unit,
    modifier: Modifier = Modifier,
    /** Dans le fil paginé, la carte remplit sa page. */
    fillsPage: Boolean = false,
) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val summaries = rememberCourseSummaries(language)
    val courses = remember(summaries, campaign.slug) {
        campaign.courseIds.mapNotNull { id -> summaries.firstOrNull { it.id == id } }
    }
    val done = CampaignStore.challengeProgress(campaign, progress)
    val complete = done >= campaign.challengeTarget
    val tagline = campaign.tagline(language)

    Column(
        modifier = modifier
            .fillMaxWidth()
            .then(if (fillsPage) Modifier.fillMaxHeight() else Modifier)
            // La carte entière ouvre la collection, d'une vibration franche.
            .pressable(
                onClick = {
                    haptics.confirm()
                    onOpen()
                },
                scaleDown = 0.975f,
                haptic = false,
            )
            .semantics { role = Role.Button }
            .sophiaCard(),
    ) {
        // L'illustration, la pastille de date en haut, le titre en bas sur un voile sombre uni. Dans
        // le fil paginé elle prend la hauteur que le reste de la carte laisse libre.
        Box(
            modifier = if (fillsPage) {
                Modifier.fillMaxWidth().weight(1f).heightIn(min = 150.dp)
            } else {
                Modifier.fillMaxWidth().aspectRatio(16f / 10f)
            },
        ) {
            EventArtwork(campaign = campaign, courses = courses, modifier = Modifier.fillMaxSize(), collageLift = 0.08f)
            if (campaign.hasEnded()) {
                EventPill(text = StringStore.text(context, "event.ended", language), dark = true, modifier = Modifier.padding(12.dp))
            } else {
                campaign.endDate?.let { end ->
                    EventPill(
                        text = StringStore.text(context, "event.card.until", language, NewGenFormat.shortDay(end, language)),
                        modifier = Modifier.padding(12.dp),
                    )
                }
            }
            Box(
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .fillMaxWidth()
                    .heightIn(min = 96.dp)
                    .background(EventPalette.night.copy(alpha = 0.62f))
                    .padding(horizontal = 16.dp, vertical = 14.dp),
                contentAlignment = Alignment.BottomStart,
            ) {
                Text(
                    text = campaign.title(language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 24.sp,
                    lineHeight = 30.sp,
                    color = Color.White,
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }

        Column(
            modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 14.dp, bottom = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            if (tagline.isNotEmpty()) {
                Text(
                    text = tagline,
                    fontFamily = PlusJakartaSans,
                    fontSize = 15.sp,
                    lineHeight = 21.sp,
                    color = DS.inkSecondary,
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp), verticalAlignment = Alignment.CenterVertically) {
                StatChip(
                    icon = Icons.AutoMirrored.Filled.MenuBook,
                    text = StringStore.text(context, "event.card.coursesToRead", language, courses.size),
                )
                if (campaign.participants > 0) {
                    StatChip(icon = Icons.Outlined.Group, text = campaign.participants.formatted(language))
                }
            }

            // Le défi du lecteur : le badge dans son anneau, l'avancement en toutes lettres et un
            // segment par cours.
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(DS.Radius.small))
                    .background(DS.accentTint)
                    .padding(12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                EventBadgeRing(campaign = campaign, done = done, size = 52.dp, track = DS.ink.copy(alpha = 0.14f))
                Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(
                        text = if (complete) {
                            StringStore.text(context, "event.challenge.unlocked", language, campaign.badgeName(language))
                        } else {
                            StringStore.text(context, "event.card.challenge", language, done, campaign.challengeTarget)
                        },
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp,
                        lineHeight = 20.sp,
                        color = DS.ink,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                    EventChallengeMeter(
                        done = done,
                        target = campaign.challengeTarget,
                        track = DS.ink.copy(alpha = 0.14f),
                        height = 6.dp,
                    )
                }
            }

            // Ce n'est que l'apparence du CTA : c'est la carte qui reçoit le geste.
            HomeCtaLabel(
                text = StringStore.text(context, "event.card.seeCollection", language),
                trailingIcon = Icons.AutoMirrored.Filled.KeyboardArrowRight,
            )
        }
    }
}

// MARK: - Carte « Deviens créateur »

/**
 * L'invitation à écrire, glissée dans le fil (jamais en tête) : quelques auteurs déjà
 * présents, la promesse en une phrase, trois atouts, et deux boutons.
 */
@Composable
fun CreatorInviteCard(
    language: AppLanguage,
    authors: List<CourseAuthor>,
    onBecomeCreator: () -> Unit,
    onLater: () -> Unit,
    modifier: Modifier = Modifier,
    /** Dans le fil paginé, la carte remplit sa page. */
    fillsPage: Boolean = false,
) {
    val context = LocalContext.current
    val languagesCount = AppLanguage.entries.size
    Column(
        modifier = modifier
            .fillMaxWidth()
            .then(if (fillsPage) Modifier.fillMaxHeight() else Modifier)
            .sophiaCard()
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Row {
                authors.take(4).forEachIndexed { index, author ->
                    Box(
                        modifier = Modifier
                            .offset(x = (-10 * index).dp)
                            .size(36.dp)
                            .clip(CircleShape)
                            .background(DS.surface)
                            .padding(2.dp),
                    ) {
                        AuthorAvatar(author = author, size = 32.dp)
                    }
                }
            }
            Text(
                text = StringStore.text(context, "creator.invite.kicker", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 12.sp,
                color = DS.inkSecondary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.offset(x = (-10 * (authors.take(4).size - 1).coerceAtLeast(0)).dp),
            )
        }
        Text(
            text = StringStore.text(context, "creator.invite.title", language),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 22.sp,
            lineHeight = 28.sp,
            color = DS.ink,
        )
        Text(
            text = StringStore.text(context, "creator.invite.body", language, languagesCount),
            fontFamily = PlusJakartaSans,
            fontSize = 15.sp,
            lineHeight = 22.sp,
            color = DS.inkSecondary,
        )
        // Les atouts passent à la ligne quand la place manque (petits écrans, langues longues).
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                InvitePerk(Icons.Filled.Edit, StringStore.text(context, "creator.invite.perk.write", language))
                InvitePerk(Icons.Filled.Language, StringStore.text(context, "creator.invite.perk.languages", language, languagesCount))
            }
            InvitePerk(Icons.Filled.BarChart, StringStore.text(context, "creator.invite.perk.paid", language))
        }
        if (fillsPage) Spacer(Modifier.weight(1f))
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
            NewGenPrimaryButton(
                text = StringStore.text(context, "creator.invite.cta", language),
                onClick = onBecomeCreator,
                modifier = Modifier.weight(1f),
            )
            NewGenSecondaryButton(
                text = StringStore.text(context, "path.quiz.later", language),
                onClick = onLater,
            )
        }
    }
}

@Composable
private fun InvitePerk(icon: ImageVector, text: String) {
    Row(
        modifier = Modifier
            .height(32.dp)
            .clip(CircleShape)
            .background(DS.canvas)
            .padding(horizontal = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Icon(imageVector = icon, contentDescription = null, tint = DS.accent, modifier = Modifier.size(14.dp))
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 13.sp,
            color = DS.ink,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

// MARK: - Carte vidéo (emplacement)

/**
 * Emplacement d'une carte vidéo du fil. Aucune vidéo n'existe encore : la vue n'est jamais
 * montrée, elle fixe seulement la place et le gabarit (prompt 10).
 */
@Composable
fun VideoFeedCard(title: String, modifier: Modifier = Modifier, fillsPage: Boolean = false) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .then(if (fillsPage) Modifier.fillMaxHeight() else Modifier.height(420.dp))
            .clip(DS.cardShape)
            .background(DS.ink),
        contentAlignment = Alignment.BottomStart,
    ) {
        Text(
            text = title,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 20.sp,
            color = Color.White,
            modifier = Modifier.padding(20.dp),
        )
    }
}
