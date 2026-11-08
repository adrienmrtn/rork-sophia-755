package app.rork.sophia.ui.newgen

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Edit
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.AuthorStore
import app.rork.sophia.data.CampaignStore
import app.rork.sophia.data.CourseAuthor
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.rememberCourseSummaries
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Campaign
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.domain.formatted
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.course.AuthorAvatar
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans

/**
 * La page d'un événement : en-tête, défi avec barre et badge, les cours de la collection,
 * les cours en écriture avec « Me prévenir », et l'appel aux créateurs. Les données viennent
 * de [CampaignStore] (JSON de test embarqué, serveur au prompt 6).
 */
@Composable
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
    // Rafraîchit la page après « Me prévenir » (l'état vit dans les préférences).
    var notifyTick by remember { mutableIntStateOf(0) }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState())
            .padding(start = 20.dp, end = 20.dp, top = 12.dp, bottom = 32.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp),
    ) {
        NewGenBackHeader(language = language, onBack = onBack)

        // En-tête bleu nuit.
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(DS.cardShape)
                .background(DS.accent)
                .padding(22.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                CampaignSymbol(symbol = campaign.symbol, size = 44.dp, tint = DS.warm)
                Spacer(Modifier.weight(1f))
                val start = campaign.startDate
                val end = campaign.endDate
                if (start != null && end != null) {
                    Text(
                        text = StringStore.text(
                            context,
                            "event.page.dates",
                            language,
                            NewGenFormat.longDay(start, language),
                            NewGenFormat.longDay(end, language),
                        ),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 12.sp,
                        color = Color.White,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier
                            .weight(1f, fill = false)
                            .padding(start = 8.dp)
                            .clip(CircleShape)
                            .background(Color.White.copy(alpha = 0.16f))
                            .padding(horizontal = 10.dp, vertical = 6.dp),
                    )
                }
            }
            Text(
                text = campaign.title(language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 34.sp,
                color = Color.White,
            )
            Text(
                text = campaign.description(language),
                fontFamily = PlusJakartaSans,
                fontSize = 17.sp,
                lineHeight = 24.sp,
                color = Color.White.copy(alpha = 0.88f),
            )
            Text(
                text = StringStore.text(context, "event.participants", language, campaign.participants.formatted(language)),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 15.sp,
                color = Color.White.copy(alpha = 0.9f),
            )
        }

        // Le défi et son badge.
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .sophiaCard()
                .padding(18.dp),
            verticalAlignment = Alignment.Top,
            horizontalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Box(
                modifier = Modifier
                    .size(84.dp)
                    .clip(CircleShape)
                    .background(if (complete) DS.warm.copy(alpha = 0.25f) else DS.surfaceMuted),
                contentAlignment = Alignment.Center,
            ) {
                CampaignSymbol(symbol = campaign.symbol, size = 40.dp, tint = if (complete) DS.warm else DS.inkTertiary)
            }
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = StringStore.text(context, "event.challenge.title", language, campaign.title(language)),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 17.sp,
                    color = DS.ink,
                )
                Text(
                    text = StringStore.text(context, "event.challenge.body", language, campaign.challengeTarget, campaign.badgeName(language)),
                    fontFamily = PlusJakartaSans,
                    fontSize = 15.sp,
                    lineHeight = 21.sp,
                    color = DS.inkSecondary,
                )
                Row(
                    modifier = Modifier.padding(top = 4.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .height(6.dp)
                            .clip(CircleShape)
                            .background(DS.surfaceMuted),
                    ) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth((done.toFloat() / maxOf(1, campaign.challengeTarget)).coerceIn(0f, 1f))
                                .height(6.dp)
                                .clip(CircleShape)
                                .background(DS.warm),
                        )
                    }
                    Text(
                        text = StringStore.text(context, "event.challenge.progress", language, done, campaign.challengeTarget),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 12.sp,
                        color = DS.ink,
                        maxLines = 1,
                    )
                }
            }
        }

        NewGenSectionTitle(text = StringStore.text(context, "event.courses", language))
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

        if (campaign.upcoming.isNotEmpty()) {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp), modifier = Modifier.padding(top = 6.dp)) {
                NewGenSectionTitle(text = StringStore.text(context, "event.writing", language))
                Text(
                    text = StringStore.text(context, "event.writing.body", language, campaign.title(language)),
                    fontFamily = PlusJakartaSans,
                    fontSize = 15.sp,
                    lineHeight = 21.sp,
                    color = DS.inkSecondary,
                )
            }
            campaign.upcoming.forEach { upcoming ->
                // `notifyTick` est lu pour que la ligne se recompose après un appui.
                val wants = remember(notifyTick, upcoming) {
                    CampaignStore.wantsNotification(context.applicationContext, campaign, upcoming)
                }
                UpcomingRow(
                    campaign = campaign,
                    upcoming = upcoming,
                    language = language,
                    wants = wants,
                    onOpenCreator = onOpenCreator,
                    onToggleNotify = {
                        CampaignStore.setWantsNotification(context.applicationContext, !wants, campaign, upcoming)
                        notifyTick += 1
                    },
                )
            }
        }

        // L'appel aux créateurs.
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(DS.cardShape)
                .background(DS.accentTint)
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(
                text = StringStore.text(context, "event.write.title", language, campaign.title(language)),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 17.sp,
                color = DS.ink,
            )
            Text(
                text = StringStore.text(context, "event.write.body", language, AppLanguage.entries.size),
                fontFamily = PlusJakartaSans,
                fontSize = 15.sp,
                lineHeight = 21.sp,
                color = DS.inkSecondary,
            )
            NewGenPrimaryButton(
                text = StringStore.text(context, "event.write.cta", language),
                onClick = onBecomeCreator,
                modifier = Modifier.padding(top = 4.dp),
            )
        }
    }
}

@Composable
private fun UpcomingRow(
    campaign: Campaign,
    upcoming: Campaign.Upcoming,
    language: AppLanguage,
    wants: Boolean,
    onOpenCreator: (CourseAuthor) -> Unit,
    onToggleNotify: () -> Unit,
) {
    val context = LocalContext.current
    val author = remember(upcoming.creator) { upcoming.creator?.let { AuthorStore.author(context.applicationContext, it) } }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .dashedBorder(DS.inkTertiary, 18.dp)
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        if (author != null) {
            AuthorAvatar(author = author, size = 44.dp, modifier = Modifier.softPress(onClick = { onOpenCreator(author) }))
        } else {
            Box(
                modifier = Modifier.size(44.dp).clip(CircleShape).background(DS.surfaceMuted),
                contentAlignment = Alignment.Center,
            ) {
                Icon(imageVector = Icons.Filled.Edit, contentDescription = null, tint = DS.inkTertiary, modifier = Modifier.size(18.dp))
            }
        }
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(
                text = upcoming.title(language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 15.sp,
                lineHeight = 20.sp,
                color = DS.ink,
            )
            val parts = mutableListOf<String>()
            author?.let { parts += it.name }
            upcoming.releaseDate?.let { date ->
                parts += StringStore.text(context, "event.upcoming.date", language, NewGenFormat.shortDay(date, language))
            }
            if (parts.isNotEmpty()) {
                Text(
                    text = parts.joinToString(" · "),
                    fontFamily = PlusJakartaSans,
                    fontSize = 12.sp,
                    color = DS.inkSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        Box(
            modifier = Modifier
                .height(36.dp)
                .softPress(onClick = onToggleNotify)
                .clip(RoundedCornerShape(10.dp))
                .background(if (wants) DS.successTint else DS.accentTint)
                .padding(horizontal = 12.dp),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = StringStore.text(context, if (wants) "event.notified" else "event.notify", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 13.sp,
                color = if (wants) DS.success else DS.accent,
                maxLines = 1,
            )
        }
    }
}
