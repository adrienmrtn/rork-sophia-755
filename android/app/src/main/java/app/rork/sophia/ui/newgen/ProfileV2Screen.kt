package app.rork.sophia.ui.newgen

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForwardIos
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Explore
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Settings
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
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.AuthorStore
import app.rork.sophia.data.CampaignStore
import app.rork.sophia.data.CourseAuthor
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.rememberCourseInfo
import app.rork.sophia.data.rememberCourseSummaries
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Campaign
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.Subject
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.domain.lowercaseIn
import app.rork.sophia.ui.components.ScreenTitle
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans

/** Les listes du profil : à lire (favoris), lus, aimés. */
enum class ProfileListKind(val titleKey: String, val emptyKey: String) {
    TO_READ("profile.list.toRead", "profile.list.toRead.empty"),
    READ("profile.list.read", "profile.list.read.empty"),
    LIKED("profile.list.liked", "profile.list.liked.empty"),
}

/** Les cours d'une liste du profil, dans l'ordre d'affichage (les lus du plus récent au plus ancien). */
fun profileListCourses(kind: ProfileListKind, progress: UserProgress, summaries: List<CourseSummary>): List<CourseSummary> {
    val byId = summaries.associateBy { it.id }
    return when (kind) {
        ProfileListKind.TO_READ -> progress.favoriteCourseIds.mapNotNull { byId[it] }
        ProfileListKind.READ -> progress.courseProgress
            .filter { it.value.isCompleted }
            .entries
            .sortedByDescending { it.value.completedAt.orEmpty() }
            .mapNotNull { byId[it.key] }
        ProfileListKind.LIKED -> progress.likedCourseIds.mapNotNull { byId[it] }
    }
}

/**
 * Le profil de la maquette : identité, trois compteurs, Reprendre, Mes abonnements, Badges,
 * listes À lire / Lus / Aimés, « Deviens créateur », puis les pages secondaires (progression,
 * amis). L'ancien profil reste accessible comme page « Ma progression ».
 */
@Composable
fun ProfileV2Screen(
    modifier: Modifier = Modifier,
    language: AppLanguage,
    progress: UserProgress,
    progressManager: ProgressManager,
    onOpenCourse: (CourseSummary) -> Unit,
    onResumeCourse: (CourseSummary) -> Unit,
    onOpenCreator: (CourseAuthor) -> Unit,
    onOpenList: (ProfileListKind) -> Unit,
    onOpenCampaign: (Campaign) -> Unit,
    onOpenProgression: () -> Unit,
    onOpenFriends: () -> Unit,
    onDiscoverCreators: () -> Unit,
    onBecomeCreator: () -> Unit,
    onOpenSettings: () -> Unit,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val handle by app.socialService.myHandle.collectAsState()
    val summaries = rememberCourseSummaries(language)
    var listSegment by remember { mutableIntStateOf(0) }

    val displayName = remember(handle, language) {
        handle?.takeIf { it.isNotBlank() } ?: run {
            val interests = app.onboardingStore.answers().topics.toSet()
            val first = Subject.entries.map { it.storageKey }.firstOrNull { it in interests }
            if (first == null) {
                StringStore.text(context, "onboarding.program.nickname.default", language)
            } else {
                StringStore.text(context, "onboarding.program.nickname.$first", language)
            }
        }
    }
    /** Le mois du premier cours ouvert, faute de date de création de compte. */
    val memberSince = remember(progress.courseProgress, language) {
        progress.courseProgress.values.mapNotNull { it.startedAt }.minOrNull()
            ?.let { Campaign.parseDay(it) }
            ?.let { NewGenFormat.monthYear(it, language) }
    }
    val completedCount = progress.courseProgress.count { it.value.isCompleted }
    val authors = remember { AuthorStore.all(context.applicationContext) }
    val followedAuthors = remember(progress.followedCreatorSlugs, authors) {
        progress.followedCreatorSlugs.mapNotNull { slug -> authors.firstOrNull { it.slug == slug } }
    }
    val campaigns = remember { CampaignStore.all(context.applicationContext) }
    val activeCampaign = remember { CampaignStore.active(context.applicationContext).firstOrNull() }
    val completedSubjects = remember(progress.courseProgress, summaries) {
        val subjectsById = summaries.associate { it.id to it.subjectEnum }
        progress.courseProgress.filter { it.value.isCompleted }.keys.mapNotNull { subjectsById[it] }.toSet().size
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState())
            .padding(start = 20.dp, end = 20.dp, top = 8.dp, bottom = 32.dp),
        verticalArrangement = Arrangement.spacedBy(22.dp),
    ) {
        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            ScreenTitle(text = StringStore.text(context, "profile.title", language), modifier = Modifier.weight(1f))
            RoundIconButton(
                icon = Icons.Filled.Settings,
                onClick = onOpenSettings,
                contentDescription = StringStore.text(context, "settings.title", language),
            )
        }

        // Identité.
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            Box(
                modifier = Modifier.size(64.dp).clip(CircleShape).background(DS.accentSoft),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = displayName.take(1).uppercase(),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 24.sp,
                    color = Color.White,
                )
            }
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(
                    text = displayName,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 20.sp,
                    color = DS.ink,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                val parts = mutableListOf<String>()
                handle?.takeIf { it.isNotBlank() }?.let { parts += "@$it" }
                memberSince?.let { parts += StringStore.text(context, "profile.member.since", language, it) }
                if (parts.isNotEmpty()) {
                    Text(
                        text = parts.joinToString(" · "),
                        fontFamily = PlusJakartaSans,
                        fontSize = 13.sp,
                        color = DS.inkSecondary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
        }

        // Trois compteurs.
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(18.dp))
                .background(DS.surface)
                .border(1.dp, DS.hairline, RoundedCornerShape(18.dp))
                .padding(horizontal = 14.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            StatCounter(
                icon = Icons.Filled.LocalFireDepartment,
                iconTint = DS.warm,
                iconBackground = DS.warm.copy(alpha = 0.18f),
                value = StringStore.text(context, "common.daysShort", language, progress.streak),
                label = StringStore.text(context, "friends.stats.streak", language).lowercaseIn(language),
                modifier = Modifier.weight(1f),
            )
            Box(modifier = Modifier.width(1.dp).height(36.dp).background(DS.hairline))
            StatCounter(
                icon = Icons.AutoMirrored.Filled.MenuBook,
                iconTint = DS.accent,
                iconBackground = DS.accentTint,
                value = "$completedCount",
                label = StringStore.text(context, "profile.stat.read", language),
                modifier = Modifier.weight(1f),
            )
            Box(modifier = Modifier.width(1.dp).height(36.dp).background(DS.hairline))
            StatCounter(
                icon = Icons.Filled.Schedule,
                iconTint = DS.success,
                iconBackground = DS.successTint,
                value = NewGenFormat.readingTime(context, progress.readingSeconds, language),
                label = StringStore.text(context, "profile.stat.time", language),
                modifier = Modifier.weight(1f),
            )
        }

        ResumeCoursesSection(
            language = language,
            progress = progress,
            summaries = summaries,
            onResume = onResumeCourse,
            horizontalPadding = 0.dp,
        )

        // Mes abonnements.
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            NewGenSectionTitle(
                text = StringStore.text(context, "profile.following", language),
                trailing = if (followedAuthors.isEmpty()) null else "· ${followedAuthors.size}",
            )
            FollowedCreatorsRow(
                authors = followedAuthors,
                language = language,
                onOpen = onOpenCreator,
                onDiscover = onDiscoverCreators,
            )
        }

        // Badges.
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            NewGenSectionTitle(text = StringStore.text(context, "profile.badges", language))
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                campaigns.lastOrNull()?.let { campaign ->
                    val done = CampaignStore.challengeProgress(campaign, progress)
                    ProfileBadge(
                        title = campaign.badgeName(language),
                        subtitle = StringStore.text(context, "badge.progress", language, done, campaign.challengeTarget),
                        earned = done >= campaign.challengeTarget,
                        modifier = Modifier.weight(1f),
                    ) { tint -> CampaignSymbol(symbol = campaign.symbol, size = 24.dp, tint = tint) }
                }
                ProfileBadge(
                    title = StringStore.text(context, "badge.streak7.title", language),
                    subtitle = StringStore.text(context, "friends.stats.streak", language),
                    earned = progress.streak >= 7,
                    modifier = Modifier.weight(1f),
                ) { tint -> BadgeIcon(Icons.Filled.LocalFireDepartment, tint) }
                ProfileBadge(
                    title = StringStore.text(context, "globalRank.curieux", language),
                    subtitle = StringStore.text(context, "badge.curious.sub", language, completedSubjects),
                    earned = completedSubjects >= 3,
                    modifier = Modifier.weight(1f),
                ) { tint -> BadgeIcon(Icons.Filled.Explore, tint) }
            }
        }

        // Listes.
        val kinds = ProfileListKind.entries
        val kind = kinds[listSegment.coerceIn(0, kinds.size - 1)]
        val items = remember(kind, progress, summaries) { profileListCourses(kind, progress, summaries) }
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            SegmentedPills(
                items = kinds.map { "${StringStore.text(context, it.titleKey, language)} · ${profileListCourses(it, progress, summaries).size}" },
                selection = listSegment,
                onSelect = { listSegment = it },
            )
            if (items.isEmpty()) {
                Text(
                    text = StringStore.text(context, kind.emptyKey, language),
                    fontFamily = PlusJakartaSans,
                    fontSize = 15.sp,
                    color = DS.inkSecondary,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth().padding(vertical = 20.dp),
                )
            } else {
                items.take(3).forEach { course ->
                    ProfileCourseRow(course = course, language = language, progress = progress, onTap = { onOpenCourse(course) })
                }
                if (items.size > 3) {
                    Text(
                        text = StringStore.text(context, "library.seeMore", language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp,
                        color = DS.accentSoft,
                        textAlign = TextAlign.Center,
                        modifier = Modifier
                            .fillMaxWidth()
                            .softPress(onClick = { onOpenList(kind) })
                            .padding(vertical = 10.dp),
                    )
                }
            }
        }

        // Deviens créateur.
        Column(
            modifier = Modifier.fillMaxWidth().sophiaCard().padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                Box(
                    modifier = Modifier.size(48.dp).clip(RoundedCornerShape(14.dp)).background(DS.accentTint),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(imageVector = Icons.Filled.Edit, contentDescription = null, tint = DS.accent, modifier = Modifier.size(20.dp))
                }
                Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(
                        text = StringStore.text(context, "profile.creator.title", language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 20.sp,
                        color = DS.ink,
                    )
                    Text(
                        text = StringStore.text(context, "profile.creator.subtitle", language),
                        fontFamily = PlusJakartaSans,
                        fontSize = 15.sp,
                        lineHeight = 21.sp,
                        color = DS.inkSecondary,
                    )
                }
            }
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                CreatorStep(1, StringStore.text(context, "profile.creator.step1", language))
                CreatorStep(2, StringStore.text(context, "profile.creator.step2", language, AppLanguage.entries.size))
                CreatorStep(3, StringStore.text(context, "profile.creator.step3", language))
            }
            activeCampaign?.let { campaign ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .softPress(onClick = { onOpenCampaign(campaign) })
                        .clip(RoundedCornerShape(14.dp))
                        .background(DS.canvas)
                        .padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    CampaignSymbol(symbol = campaign.symbol, size = 24.dp, tint = DS.warm)
                    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Text(
                            text = StringStore.text(context, "profile.creator.call", language),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 13.sp,
                            color = DS.ink,
                        )
                        Text(
                            text = campaign.title(language) + ", " + campaign.tagline(language).replaceFirstChar { it.lowercase() },
                            fontFamily = PlusJakartaSans,
                            fontSize = 13.sp,
                            color = DS.inkSecondary,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowForwardIos,
                        contentDescription = null,
                        tint = DS.inkTertiary,
                        modifier = Modifier.size(12.dp),
                    )
                }
            }
            NewGenPrimaryButton(
                text = StringStore.text(context, "home.start", language),
                onClick = onBecomeCreator,
                height = 52.dp,
                fontSize = 17.sp,
            )
        }

        // Pages secondaires.
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(20.dp))
                .background(DS.surface)
                .border(1.dp, DS.hairline, RoundedCornerShape(20.dp)),
        ) {
            PageRow(StringStore.text(context, "profile.page.progression", language), onOpenProgression)
            Box(modifier = Modifier.fillMaxWidth().padding(start = 16.dp).height(1.dp).background(DS.hairline))
            PageRow(StringStore.text(context, "profile.page.friends", language), onOpenFriends)
        }
    }
}

@Composable
private fun BadgeIcon(icon: ImageVector, tint: Color) {
    Icon(imageVector = icon, contentDescription = null, tint = tint, modifier = Modifier.size(22.dp))
}

@Composable
private fun ProfileBadge(
    title: String,
    subtitle: String,
    earned: Boolean,
    modifier: Modifier = Modifier,
    icon: @Composable (Color) -> Unit,
) {
    val shape = RoundedCornerShape(18.dp)
    Column(
        modifier = modifier
            .clip(shape)
            .background(DS.surface)
            .border(1.dp, DS.hairline, shape)
            .padding(vertical = 16.dp, horizontal = 8.dp)
            .alpha(if (earned) 1f else 0.75f),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Box(
            modifier = Modifier
                .size(48.dp)
                .clip(CircleShape)
                .background(if (earned) DS.warm.copy(alpha = 0.2f) else DS.surfaceMuted),
            contentAlignment = Alignment.Center,
        ) {
            icon(if (earned) DS.warm else DS.inkTertiary)
        }
        Text(
            text = title,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 14.sp,
            color = DS.ink,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center,
        )
        Text(
            text = subtitle,
            fontFamily = PlusJakartaSans,
            fontSize = 12.sp,
            color = DS.inkSecondary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center,
        )
    }
}

@Composable
private fun CreatorStep(number: Int, text: String) {
    Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Box(
            modifier = Modifier.size(26.dp).clip(CircleShape).background(DS.accentTint),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = "$number",
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 13.sp,
                color = DS.accent,
            )
        }
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontSize = 15.sp,
            lineHeight = 21.sp,
            color = DS.ink,
            modifier = Modifier.weight(1f),
        )
    }
}

@Composable
private fun PageRow(title: String, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .softPress(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 17.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = title,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 15.sp,
            color = DS.ink,
            modifier = Modifier.weight(1f),
        )
        Icon(
            imageVector = Icons.AutoMirrored.Filled.ArrowForwardIos,
            contentDescription = null,
            tint = DS.inkTertiary,
            modifier = Modifier.size(13.dp),
        )
    }
}

/** Une ligne de liste du profil : « Créateur · 7 min », et la coche quand le cours est lu. */
@Composable
private fun ProfileCourseRow(course: CourseSummary, language: AppLanguage, progress: UserProgress, onTap: () -> Unit) {
    val context = LocalContext.current
    val identity = remember(course.id) { CreatorIdentity.forCourse(context.applicationContext, course.id) }
    val info by rememberCourseInfo(course.toStub(), language)
    val completed = progress.courseProgress[course.id]?.isCompleted == true
    CompactCourseRow(
        course = course,
        meta = listOfNotNull(identity.name, info?.let { NewGenFormat.minutes(context, it.minutes, language) }).joinToString(" · "),
        onTap = onTap,
        trailing = if (completed) ({ ReadCheck(language = language) }) else null,
    )
}

/** Une liste complète du profil (À lire, Lus, Aimés). */
@Composable
fun ProfileCourseListScreen(
    kind: ProfileListKind,
    language: AppLanguage,
    progress: UserProgress,
    onBack: () -> Unit,
    onOpenCourse: (CourseSummary) -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val summaries = rememberCourseSummaries(language)
    val courses = remember(kind, progress, summaries) { profileListCourses(kind, progress, summaries) }
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState())
            .padding(start = 20.dp, end = 20.dp, top = 12.dp, bottom = 32.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        NewGenBackHeader(
            language = language,
            onBack = onBack,
            title = "${StringStore.text(context, kind.titleKey, language)} · ${courses.size}",
            modifier = Modifier.padding(bottom = 8.dp),
        )
        if (courses.isEmpty()) {
            Text(
                text = StringStore.text(context, kind.emptyKey, language),
                fontFamily = PlusJakartaSans,
                fontSize = 15.sp,
                color = DS.inkSecondary,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(vertical = 40.dp),
            )
        }
        courses.forEach { course ->
            ProfileCourseRow(course = course, language = language, progress = progress, onTap = { onOpenCourse(course) })
        }
        Spacer(Modifier.height(4.dp))
    }
}
