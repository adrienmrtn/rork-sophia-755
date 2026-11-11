package app.rork.sophia.ui.newgen

import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
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
import app.rork.sophia.data.rememberCourseSummaries
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Campaign
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.readsCount
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.course.AuthorAvatar
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans

/**
 * La page d'un créateur, plein écran : portrait, badge, pedigree, quatre compteurs,
 * « Suivre », bio, ce qu'il écrit pour l'événement en cours, puis ses cours (populaires,
 * récents, séries). Remplace `AuthorScreen`, depuis le lecteur aussi.
 */
@Composable
fun CreatorPageScreen(
    author: CourseAuthor,
    language: AppLanguage,
    progress: UserProgress,
    progressManager: ProgressManager,
    onBack: () -> Unit,
    onOpenCourse: (CourseSummary) -> Unit,
    /** Null quand la page est ouverte depuis le lecteur : l'annonce « en écriture » n'y mène nulle part. */
    onOpenCampaign: ((Campaign) -> Unit)?,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val summaries = rememberCourseSummaries(language)
    val courses = remember(summaries, author) {
        author.courseIds.mapNotNull { id -> summaries.firstOrNull { it.id == id } }
    }
    var segment by remember { mutableIntStateOf(0) }
    val isFollowing = author.slug in progress.followedCreatorSlugs
    val followers = LocalCounters.followers(author.slug) + (if (isFollowing) 1 else 0)

    val listed = remember(courses, segment) {
        when (segment) {
            0 -> courses.sortedByDescending { it.readsCount }
            1 -> courses.reversed()
            else -> emptyList()
        }
    }

    fun toggleFollow() {
        val wasFollowing = progressManager.isFollowing(author.slug)
        progressManager.toggleFollow(author.slug)
        Analytics.log(if (wasFollowing) "unfollow" else "follow", screen = "creator", props = mapOf("creator" to author.slug))
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState())
            .padding(start = 20.dp, end = 20.dp, top = 12.dp, bottom = 32.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        NewGenBackHeader(
            language = language,
            onBack = onBack,
            trailing = {
                RoundIconButton(
                    icon = Icons.Filled.Share,
                    onClick = {
                        // La phrase habituelle, suivie du lien de sa page sur le site.
                        val message = app.rork.sophia.domain.SophiaLinks.shareText(
                            StringStore.text(context, "share.creator.message", language, author.name),
                            app.rork.sophia.domain.SophiaLinks.authorWebUrl(author.slug),
                        )
                        val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, message)
                        runCatching { context.startActivity(Intent.createChooser(send, null)) }
                    },
                )
            },
        )

        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            AuthorAvatar(author = author, size = 92.dp)
            Text(
                text = author.name,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 28.sp,
                color = DS.ink,
                textAlign = TextAlign.Center,
            )
            CreatorBadge(verified = author.isVerified, language = language)
            author.title(language)?.let { pedigree ->
                Text(
                    text = pedigree,
                    fontFamily = PlusJakartaSans,
                    fontSize = 17.sp,
                    color = DS.inkSecondary,
                    textAlign = TextAlign.Center,
                )
            }
        }

        // Quatre compteurs : abonnés, lectures, cours, langues.
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(18.dp))
                .background(DS.surface)
                .border(1.dp, DS.hairline, RoundedCornerShape(18.dp))
                .padding(vertical = 16.dp),
        ) {
            CreatorStat(followers.compactCount(language), StringStore.text(context, "creator.stat.followers", language), Modifier.weight(1f))
            CreatorStat(LocalCounters.reads(author).compactCount(language), StringStore.text(context, "creator.stat.reads", language), Modifier.weight(1f))
            CreatorStat("${courses.size}", StringStore.text(context, "creator.stat.courses", language), Modifier.weight(1f))
            CreatorStat("${AppLanguage.entries.size}", StringStore.text(context, "creator.stat.languages", language), Modifier.weight(1f))
        }

        Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
            FollowButton(isFollowing = isFollowing, language = language, onClick = { toggleFollow() }, modifier = Modifier.weight(1f))
            Box(
                modifier = Modifier
                    .width(54.dp)
                    .height(44.dp)
                    .softPress(onClick = { if (!isFollowing) toggleFollow() })
                    .clip(RoundedCornerShape(14.dp))
                    .background(DS.surface)
                    .border(1.dp, DS.hairline, RoundedCornerShape(14.dp)),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = if (isFollowing) Icons.Filled.Notifications else Icons.Outlined.Notifications,
                    contentDescription = StringStore.text(context, "creator.notify", language),
                    tint = DS.ink,
                    modifier = Modifier.size(18.dp),
                )
            }
        }

        author.bio(language)?.let { bio ->
            Text(
                text = bio,
                fontFamily = PlusJakartaSans,
                fontSize = 17.sp,
                lineHeight = 25.sp,
                color = DS.ink,
            )
        }

        SegmentedPills(
            items = listOf(
                StringStore.text(context, "creator.tab.popular", language),
                StringStore.text(context, "creator.tab.recent", language),
                StringStore.text(context, "creator.tab.series", language),
            ),
            selection = segment,
            onSelect = { segment = it },
        )

        if (segment == 2) {
            Text(
                text = StringStore.text(context, "creator.series.empty", language),
                fontFamily = PlusJakartaSans,
                fontSize = 15.sp,
                color = DS.inkSecondary,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(vertical = 24.dp),
            )
        } else {
            listed.forEach { course ->
                CreatorCourseRow(
                    course = course,
                    language = language,
                    progress = progress,
                    onTap = { onOpenCourse(course) },
                )
            }
        }
    }
}

@Composable
private fun CreatorStat(value: String, label: String, modifier: Modifier = Modifier) {
    Column(modifier = modifier, horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(
            text = value,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 20.sp,
            color = DS.ink,
            maxLines = 1,
        )
        Text(
            text = label,
            fontFamily = PlusJakartaSans,
            fontSize = 12.sp,
            color = DS.inkSecondary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center,
        )
    }
}

/** Une ligne de cours avec matière · durée (ou « Lu »), lectures · j'aime, et la coche « lu ». */
@Composable
internal fun CreatorCourseRow(
    course: CourseSummary,
    language: AppLanguage,
    progress: UserProgress,
    onTap: () -> Unit,
    /** Ce qui ouvre la ligne de détail : la matière (page créateur) ou le créateur (événement). */
    leading: String? = null,
) {
    val context = LocalContext.current
    val info by rememberCourseInfo(course.toStub(), language)
    val completed = progress.courseProgress[course.id]?.isCompleted == true
    val liked = course.id in progress.likedCourseIds
    val first = leading ?: StringStore.text(context, "subject.${course.subjectEnum.storageKey}.short", language)
    val second = if (completed) {
        StringStore.text(context, "common.read", language)
    } else {
        info?.let { NewGenFormat.minutes(context, it.minutes, language) }
    }
    CompactCourseRow(
        course = course,
        meta = listOfNotNull(first, second).joinToString(" · "),
        secondMeta = LocalCounters.statsLine(context, course.id, liked, language),
        onTap = onTap,
        trailing = if (completed) ({ ReadCheck(language = language) }) else null,
    )
}
