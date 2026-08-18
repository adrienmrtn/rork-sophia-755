package app.rork.sophia.ui.profile

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
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.WorkspacePremium
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.rememberCourseSummaries
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.components.CalmProgressBar
import app.rork.sophia.ui.components.CircleIconButton
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.components.ScreenTitle
import app.rork.sophia.ui.components.SectionLabel
import app.rork.sophia.ui.components.SophiaPrimaryButton
import app.rork.sophia.ui.components.StatTile
import app.rork.sophia.ui.components.TintedIconBox
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.social.FriendsLeaderboardSection
import app.rork.sophia.ui.social.GlobalRankRing
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.launch

@Composable
fun ProfileScreen(
    modifier: Modifier = Modifier,
    language: AppLanguage,
    progress: UserProgress,
    isPremium: Boolean,
    onOpenCourse: (String) -> Unit,
    onOpenSettings: () -> Unit,
    onShowPaywall: () -> Unit = {},
    onOpenFriends: (friendUserId: String?) -> Unit = {},
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val userId by app.authService.userId.collectAsState()
    val handle by app.socialService.myHandle.collectAsState()
    val leaderboard by app.socialService.leaderboard.collectAsState()
    val pending by app.socialService.pendingRequests.collectAsState()
    val period by app.socialService.period.collectAsState()
    val scope = rememberCoroutineScope()
    val summaries = rememberCourseSummaries(language)
    val favorites = progress.favoriteCourseIds.mapNotNull { id ->
        summaries.firstOrNull { it.id == id }
    }
    val level = ProgressManager.globalLevelProgress(progress.globalXP)
    val rankProgress = if (level.xpForLevel == 0) 0f else level.xpIntoLevel.toFloat() / level.xpForLevel
    val completedCount = progress.courseProgress.count { it.value.isCompleted }

    LaunchedEffect(userId) {
        if (userId != null) app.socialService.refreshAll()
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = DS.Space.l)
            .padding(bottom = 32.dp),
        verticalArrangement = Arrangement.spacedBy(24.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(top = DS.Space.s),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            ScreenTitle(
                text = StringStore.text(context, "tab.profile", language),
                modifier = Modifier.weight(1f),
            )
            CircleIconButton(icon = Icons.Filled.Settings, onClick = onOpenSettings, size = 44.dp)
        }

        // Identity: rank ring, nickname, level, and the climb to the next rank.
        Column(
            modifier = Modifier.fillMaxWidth().sophiaCard().padding(DS.Space.l),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                GlobalRankRing(progress = rankProgress, size = 92.dp)
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    SectionLabel(
                        text = StringStore.text(context, "common.levelShort", language, level.level),
                        color = DS.accentSoft,
                    )
                    Text(
                        text = StringStore.text(context, "globalRank.${level.rank.storageKey}", language),
                        style = SophiaTypography.titleLarge.copy(fontSize = 21.sp),
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                    if (handle != null) {
                        Text(
                            text = "@$handle",
                            style = SophiaTypography.labelLarge.copy(fontSize = 14.sp),
                            color = DS.accentSoft,
                        )
                    }
                    Text(
                        text = "${progress.globalXP} XP",
                        style = SophiaTypography.bodyMedium,
                    )
                }
            }
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                CalmProgressBar(fraction = rankProgress)
                Text(
                    text = "${level.xpIntoLevel} / ${level.xpForLevel} XP",
                    style = SophiaTypography.labelMedium.copy(fontSize = 11.sp),
                )
            }
        }

        // Stats: streak first, then the two counters, as on iOS.
        Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth().sophiaCard().padding(DS.Space.l),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Icon(
                    Icons.Filled.LocalFireDepartment,
                    contentDescription = null,
                    tint = DS.accentSoft,
                    modifier = Modifier.size(24.dp),
                )
                Text(
                    text = "${progress.streak}",
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 32.sp,
                    color = DS.ink,
                )
                Text(
                    text = StringStore.text(
                        context,
                        if (progress.streak <= 1) "common.streak.day" else "common.streak.days",
                        language,
                    ),
                    style = SophiaTypography.bodyMedium,
                )
            }
            Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                StatTile(
                    icon = Icons.AutoMirrored.Filled.MenuBook,
                    value = "$completedCount",
                    label = StringStore.text(context, "settings.courses.completed", language, completedCount),
                    modifier = Modifier.weight(1f),
                )
                StatTile(
                    icon = Icons.Filled.Bolt,
                    value = "${progress.globalXP}",
                    label = "XP",
                    modifier = Modifier.weight(1f),
                )
            }
        }

        if (!isPremium) {
            SophiaPrimaryButton(
                text = StringStore.text(context, "settings.premium.title", language),
                onClick = onShowPaywall,
                leadingIcon = Icons.Filled.WorkspacePremium,
            )
        }

        if (userId != null) {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                SectionLabel(StringStore.text(context, "friends.title", language))
                FriendsLeaderboardSection(
                    language = language,
                    period = period,
                    leaderboard = leaderboard.take(5),
                    onPeriodChange = {
                        app.socialService.setPeriod(it)
                        scope.launch { app.socialService.refreshLeaderboard() }
                    },
                    onOpenFriend = { entry -> onOpenFriends(entry.user_id) },
                    nestedScroll = true,
                )
            }
        }

        ProfileShortcutRow(
            icon = Icons.Filled.Group,
            title = StringStore.text(context, "friends.title", language),
            subtitle = if (pending.isEmpty()) {
                StringStore.text(context, "friends.add.subtitle", language)
            } else {
                StringStore.text(context, "friends.requests.title", language)
            },
            onClick = { onOpenFriends(null) },
            badgeCount = pending.size,
        )

        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            SectionLabel(StringStore.text(context, "library.filter.favorites", language))
            if (favorites.isEmpty()) {
                Row(
                    modifier = Modifier.fillMaxWidth().sophiaCard().padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    TintedIconBox(icon = Icons.Filled.Star, size = 40.dp)
                    Text(
                        text = StringStore.text(context, "library.empty.subtitle", language),
                        style = SophiaTypography.bodyMedium,
                    )
                }
            } else {
                Column(modifier = Modifier.fillMaxWidth().sophiaCard()) {
                    favorites.take(6).forEachIndexed { index, course ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .softPress(onClick = { onOpenCourse(course.id) })
                                .padding(horizontal = 12.dp, vertical = 10.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp),
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(46.dp)
                                    .clip(DS.controlShape)
                                    .background(DS.surfaceMuted),
                            ) {
                                CourseImage(
                                    courseId = course.id,
                                    modifier = Modifier.fillMaxSize(),
                                    contentScale = ContentScale.Crop,
                                    maxEdgePx = 240,
                                )
                            }
                            Text(
                                text = course.title,
                                style = SophiaTypography.titleMedium.copy(fontSize = 15.sp, lineHeight = 20.sp),
                                maxLines = 2,
                                overflow = TextOverflow.Ellipsis,
                                modifier = Modifier.weight(1f),
                            )
                            Icon(
                                Icons.Filled.ChevronRight,
                                contentDescription = null,
                                tint = DS.inkTertiary,
                                modifier = Modifier.size(18.dp),
                            )
                        }
                        if (index != favorites.take(6).lastIndex) {
                            HorizontalDivider(color = DS.hairline)
                        }
                    }
                }
            }
        }
        Spacer(Modifier.height(4.dp))
    }
}

@Composable
private fun ProfileShortcutRow(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String,
    onClick: () -> Unit,
    badgeCount: Int = 0,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .softPress(onClick = onClick)
            .sophiaCard()
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        TintedIconBox(icon = icon, size = 40.dp, shape = CircleShape)
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(text = title, style = SophiaTypography.titleMedium.copy(fontSize = 16.sp))
            Text(
                text = subtitle,
                style = SophiaTypography.labelMedium,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
        if (badgeCount > 0) {
            Text(
                text = "$badgeCount",
                style = SophiaTypography.labelLarge.copy(fontSize = 13.sp),
                color = Color.White,
                modifier = Modifier
                    .clip(CircleShape)
                    .background(DS.accent)
                    .padding(horizontal = 8.dp, vertical = 3.dp),
            )
        }
        Icon(
            Icons.Filled.ChevronRight,
            contentDescription = null,
            tint = DS.inkTertiary,
            modifier = Modifier.size(18.dp),
        )
    }
}
