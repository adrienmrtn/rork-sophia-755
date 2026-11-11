package app.rork.sophia.ui.newgen

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.CampaignStore
import app.rork.sophia.data.CourseAuthor
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.rememberCourseSummaries
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Campaign
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.domain.formatted
import app.rork.sophia.domain.locale
import app.rork.sophia.domain.uppercaseIn
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import java.math.RoundingMode
import java.text.NumberFormat

/**
 * La page d'un événement, comme sur iOS : un en-tête marine (l'image de l'équipe ou un éventail
 * des couvertures, dates, titre, accroche, participants), la présentation, le défi sur une feuille
 * crème avec le badge à gagner, l'objectif commun, puis les cours de la collection. Les données
 * viennent de [CampaignStore], donc du manifeste du catalogue (docs/evenements.md).
 *
 * [onOpenCreator] et [onBecomeCreator] ne servent plus depuis que la page n'annonce plus de
 * cours « en écriture » ni n'invite à écrire ; gardés pour que les appelants n'aient pas à changer.
 */
@Composable
@Suppress("UNUSED_PARAMETER")
fun EventPageScreen(
    campaign: Campaign,
    language: AppLanguage,
    progress: UserProgress,
    onBack: () -> Unit,
    onOpenCourse: (CourseSummary) -> Unit,
    onOpenCreator: (CourseAuthor) -> Unit,
    onBecomeCreator: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val summaries = rememberCourseSummaries(language)
    val courses = remember(summaries, campaign.slug) {
        campaign.courseIds.mapNotNull { id -> summaries.firstOrNull { it.id == id } }
    }
    val done = CampaignStore.challengeProgress(campaign, progress)
    val complete = CampaignStore.isChallengeComplete(campaign, progress)
    val description = campaign.description(language)
    val tagline = campaign.tagline(language)
    val navy = EventPalette.navy

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState()),
    ) {
        // En-tête : l'illustration fondue dans le marine, puis les dates, le titre, l'accroche
        // et les participants.
        Box(modifier = Modifier.fillMaxWidth().background(navy)) {
            Column {
                Box(modifier = Modifier.fillMaxWidth().height(290.dp)) {
                    EventArtwork(campaign = campaign, courses = courses, modifier = Modifier.fillMaxSize(), collageLift = -0.08f)
                    Box(
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
                            .fillMaxWidth()
                            .height(120.dp)
                            .background(Brush.verticalGradient(listOf(navy.copy(alpha = 0f), navy))),
                    )
                }
                Column(
                    modifier = Modifier
                        .offset(y = (-30).dp)
                        .padding(horizontal = 20.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                        val start = campaign.startDate
                        val end = campaign.endDate
                        if (start != null && end != null) {
                            EventPill(
                                text = StringStore.text(
                                    context, "event.page.dates", language,
                                    NewGenFormat.longDay(start, language), NewGenFormat.longDay(end, language),
                                ),
                                modifier = Modifier.weight(1f, fill = false),
                            )
                        }
                        if (campaign.hasEnded()) {
                            EventPill(text = StringStore.text(context, "event.ended", language), dark = true)
                        }
                    }
                    Text(
                        text = campaign.title(language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 34.sp,
                        lineHeight = 40.sp,
                        color = Color.White,
                    )
                    if (tagline.isNotEmpty()) {
                        Text(
                            text = tagline,
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 17.sp,
                            lineHeight = 23.sp,
                            color = Color.White.copy(alpha = 0.9f),
                        )
                    }
                    if (campaign.participants > 0) {
                        Row(
                            modifier = Modifier.padding(top = 2.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            Icon(
                                imageVector = Icons.Filled.Group,
                                contentDescription = null,
                                tint = EventPalette.saffron,
                                modifier = Modifier.size(16.dp),
                            )
                            Text(
                                text = StringStore.text(context, "event.participants", language, campaign.participants.formatted(language)),
                                fontFamily = PlusJakartaSans,
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 15.sp,
                                color = Color.White.copy(alpha = 0.9f),
                            )
                        }
                    }
                }
            }
            RoundIconButton(
                icon = Icons.AutoMirrored.Filled.ArrowBack,
                onClick = onBack,
                contentDescription = StringStore.text(context, "common.close", language),
                modifier = Modifier.padding(start = 20.dp, top = 12.dp),
            )
        }

        Column(
            modifier = Modifier.padding(start = 20.dp, end = 20.dp, top = 20.dp, bottom = 44.dp),
            verticalArrangement = Arrangement.spacedBy(22.dp),
        ) {
            if (description.isNotEmpty()) {
                Text(
                    text = description,
                    fontFamily = PlusJakartaSans,
                    fontSize = 17.sp,
                    lineHeight = 25.sp,
                    color = DS.ink,
                )
            }

            // Le défi sur une feuille crème, comme les affiches du site : le badge à gagner dans
            // son anneau, son nom, ce qu'il faut lire pour l'obtenir, et un segment par cours.
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(DS.cardShape)
                    .background(EventPalette.cream)
                    .border(1.5.dp, EventPalette.saffron.copy(alpha = 0.55f), DS.cardShape)
                    .padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    EventBadgeRing(campaign = campaign, done = done, size = 96.dp, track = navy.copy(alpha = 0.14f))
                    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(
                            text = StringStore.text(context, "event.badge.toEarn", language).uppercaseIn(language),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 12.sp,
                            letterSpacing = 0.6.sp,
                            color = navy.copy(alpha = 0.62f),
                        )
                        Text(
                            text = campaign.badgeName(language),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 22.sp,
                            lineHeight = 27.sp,
                            color = navy,
                        )
                        Text(
                            text = StringStore.text(context, "event.challenge.title", language, campaign.title(language)),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 15.sp,
                            color = navy.copy(alpha = 0.75f),
                        )
                    }
                }
                Text(
                    text = if (complete) {
                        StringStore.text(context, "event.challenge.unlocked", language, campaign.badgeName(language))
                    } else {
                        StringStore.text(context, "event.challenge.body", language, campaign.challengeTarget, campaign.badgeName(language))
                    },
                    fontFamily = PlusJakartaSans,
                    fontWeight = if (complete) FontWeight.Bold else FontWeight.Normal,
                    fontSize = 15.sp,
                    lineHeight = 21.sp,
                    color = navy.copy(alpha = if (complete) 1f else 0.82f),
                )
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    EventChallengeMeter(
                        done = done,
                        target = campaign.challengeTarget,
                        tint = EventPalette.saffron,
                        track = navy.copy(alpha = 0.14f),
                        height = 10.dp,
                    )
                    Text(
                        text = StringStore.text(context, "event.challenge.progress", language, done, campaign.challengeTarget),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 13.sp,
                        color = navy,
                    )
                }
            }

            // L'objectif commun : tous les lecteurs ensemble, chiffre recalculé par le serveur.
            val goal = campaign.goalTarget
            if (goal != null && goal > 0) {
                val fraction = (campaign.goalCount.toFloat() / goal).coerceIn(0f, 1f)
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(DS.cardShape)
                        .background(DS.surface)
                        .border(1.dp, DS.hairline, DS.cardShape)
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Box(
                            modifier = Modifier.size(40.dp).clip(CircleShape).background(DS.accentTint),
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(
                                imageVector = Icons.Filled.Groups,
                                contentDescription = null,
                                tint = DS.accentSoft,
                                modifier = Modifier.size(18.dp),
                            )
                        }
                        Text(
                            text = StringStore.text(
                                context, "event.goal.progress", language,
                                campaign.goalCount.formatted(language), goal.formatted(language),
                            ),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 15.sp,
                            color = DS.ink,
                            modifier = Modifier.weight(1f),
                        )
                        Text(
                            text = percentText(fraction, language),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 17.sp,
                            color = DS.accentSoft,
                            maxLines = 1,
                        )
                    }
                    EventProgressBar(fraction = fraction, tint = DS.accentSoft, track = DS.surfaceMuted, height = 8.dp)
                }
            }

            // Les cours de la collection.
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                NewGenSectionTitle(
                    text = StringStore.text(context, "event.courses", language),
                    trailing = "· ${courses.size}",
                    modifier = Modifier.padding(bottom = 2.dp),
                )
                courses.forEach { course ->
                    val identity = remember(course.id) { CreatorIdentity.forCourse(context.applicationContext, course.id) }
                    CreatorCourseRow(
                        course = course,
                        language = language,
                        progress = progress,
                        onTap = { onOpenCourse(course) },
                        leading = identity.name,
                    )
                }
            }
        }
    }
}

/** « 62 % », « 62% » : le pourcentage écrit comme la langue de l'app l'écrit, arrondi vers le bas. */
private fun percentText(fraction: Float, language: AppLanguage): String {
    val formatter = NumberFormat.getPercentInstance(language.locale)
    formatter.maximumFractionDigits = 0
    formatter.roundingMode = RoundingMode.DOWN
    return formatter.format(fraction.toDouble())
}
