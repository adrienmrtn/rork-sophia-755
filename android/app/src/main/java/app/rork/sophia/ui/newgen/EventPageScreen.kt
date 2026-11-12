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
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.outlined.Group
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
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
import app.rork.sophia.domain.uppercaseIn
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans

/**
 * La page d'un événement, comme sur iOS : un en-tête bleu nuit (l'image de l'équipe ou un éventail
 * des couvertures, dates, titre, accroche, participants, présentation), le défi sur une feuille
 * crème avec le badge à gagner, puis les cours de la collection. Les données viennent de
 * [CampaignStore], donc du manifeste du catalogue (docs/evenements.md). (L'objectif commun
 * « Ensemble : N cours lus » n'est plus affiché.)
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
    val headerColor = EventPalette.pageHeader
    val softText = EventPalette.softText
    val challengeInk = EventPalette.ink

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState()),
    ) {
        // En-tête : l'illustration, un voile uni en bas, puis les dates, le titre, l'accroche, les
        // participants et la présentation, sur le bleu nuit de l'en-tête.
        Box(modifier = Modifier.fillMaxWidth().background(headerColor)) {
            Column {
                Box(modifier = Modifier.fillMaxWidth().height(270.dp)) {
                    EventArtwork(campaign = campaign, courses = courses, modifier = Modifier.fillMaxSize(), collageLift = -0.08f)
                    Box(
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
                            .fillMaxWidth()
                            .height(90.dp)
                            .background(headerColor.copy(alpha = 0.7f)),
                    )
                }
                Column(
                    modifier = Modifier
                        .offset(y = (-30).dp)
                        .padding(horizontal = 24.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
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
                        fontSize = 28.sp,
                        lineHeight = 34.sp,
                        color = Color.White,
                    )
                    if (tagline.isNotEmpty()) {
                        Text(
                            text = tagline,
                            fontFamily = PlusJakartaSans,
                            fontSize = 15.sp,
                            lineHeight = 21.sp,
                            color = softText,
                        )
                    }
                    if (campaign.participants > 0) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp),
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.Group,
                                contentDescription = null,
                                tint = EventPalette.saffron,
                                modifier = Modifier.size(16.dp),
                            )
                            Text(
                                text = StringStore.text(context, "event.participants", language, campaign.participants.formatted(language)),
                                fontFamily = PlusJakartaSans,
                                fontWeight = FontWeight.Bold,
                                fontSize = 15.sp,
                                color = Color.White,
                            )
                        }
                    }
                    if (description.isNotEmpty()) {
                        Text(
                            text = description,
                            fontFamily = PlusJakartaSans,
                            fontSize = 15.sp,
                            lineHeight = 21.sp,
                            color = softText,
                        )
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
            modifier = Modifier.padding(start = 24.dp, end = 24.dp, top = 18.dp, bottom = 48.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp),
        ) {
            // Le défi sur une feuille crème bordée de safran, centré : le badge à gagner dans son
            // anneau, son nom, ce qu'il faut lire pour l'obtenir, et un segment par cours.
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .dsStagger(0)
                    .clip(DS.cardShape)
                    .background(EventPalette.cream)
                    .border(1.5.dp, EventPalette.saffron, DS.cardShape)
                    .padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                EventBadgeRing(campaign = campaign, done = done, size = 96.dp, track = challengeInk.copy(alpha = 0.14f))
                Text(
                    text = StringStore.text(context, "event.badge.toEarn", language).uppercaseIn(language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 12.sp,
                    letterSpacing = 0.8.sp,
                    color = EventPalette.gold,
                    textAlign = TextAlign.Center,
                )
                Text(
                    text = campaign.badgeName(language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 18.sp,
                    lineHeight = 23.sp,
                    color = challengeInk,
                    textAlign = TextAlign.Center,
                )
                Text(
                    text = StringStore.text(context, "event.challenge.title", language, campaign.title(language)),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 13.sp,
                    color = challengeInk,
                    textAlign = TextAlign.Center,
                )
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
                    color = challengeInk,
                    textAlign = TextAlign.Center,
                )
                EventChallengeMeter(
                    done = done,
                    target = campaign.challengeTarget,
                    tint = EventPalette.saffron,
                    track = challengeInk.copy(alpha = 0.14f),
                    height = 8.dp,
                    modifier = Modifier.padding(top = 2.dp),
                )
                Text(
                    text = StringStore.text(context, "event.challenge.progress", language, done, campaign.challengeTarget),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 13.sp,
                    color = challengeInk,
                    textAlign = TextAlign.Center,
                )
            }

            // Les cours de la collection.
            Column(verticalArrangement = Arrangement.spacedBy(9.dp)) {
                NewGenSectionTitle(
                    text = StringStore.text(context, "event.courses", language),
                    trailing = "· ${courses.size}",
                    modifier = Modifier.dsStagger(1),
                )
                courses.forEachIndexed { index, course ->
                    val identity = remember(course.id) { CreatorIdentity.forCourse(context.applicationContext, course.id) }
                    Box(modifier = Modifier.dsStagger(minOf(index, 8) + 2)) {
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
}
