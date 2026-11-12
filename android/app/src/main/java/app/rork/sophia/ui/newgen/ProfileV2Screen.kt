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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.R
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.AuthorStore
import app.rork.sophia.data.CampaignStore
import app.rork.sophia.data.CourseAuthor
import app.rork.sophia.data.FeatureFlags
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.rememberCourseInfo
import app.rork.sophia.data.rememberCourseSummaries
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.BadgeRules
import app.rork.sophia.domain.Campaign
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.domain.lowercaseIn
import app.rork.sophia.domain.uppercaseIn
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.duels.DuelFormat
import app.rork.sophia.ui.duels.DuelLeagueBackdrop
import app.rork.sophia.ui.duels.DuelPalette
import app.rork.sophia.ui.duels.DuelTrophyCount
import app.rork.sophia.ui.profile.ProfileCountText
import app.rork.sophia.ui.profile.ProfileHeaderLink
import app.rork.sophia.ui.profile.ProfileIdentity
import app.rork.sophia.ui.profile.ProfilePillTabs
import app.rork.sophia.ui.profile.ProfilePosterCard
import app.rork.sophia.ui.profile.ProfileRoundButton
import app.rork.sophia.ui.profile.ProfileSectionHeader
import app.rork.sophia.ui.social.ProfileFriendsSection
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
 * Le profil de la maquette « Elevate arrondi » : identité (le @ du compte, sinon le titre de
 * rang), compteurs qui défilent, trophées et ligue des duels, les cartes illustrées de
 * l'Entraînement et de « Ma progression », Mes abonnements, le classement des amis, Badges,
 * puis les listes À lire / Lus / Aimés. Chaque bloc arrive à son tour, en cascade.
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
    onOpenTraining: () -> Unit,
    onOpenBadges: () -> Unit,
    onOpenFriends: (friendUserId: String?) -> Unit,
    onDiscoverCreators: () -> Unit,
    onBecomeCreator: () -> Unit,
    onOpenSettings: () -> Unit,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val handle by app.socialService.myHandle.collectAsState()
    val signedIn by app.authService.userId.collectAsState()
    val duelsVisible = FeatureFlags.duelsVisible(language)
    val duelHome by app.duelService.home.collectAsState()
    LaunchedEffect(signedIn, duelsVisible) {
        if (signedIn != null && duelsVisible) app.duelService.refreshHome()
    }
    val summaries = rememberCourseSummaries(language)
    var listSegment by remember { mutableIntStateOf(0) }
    var showAvatarPicker by remember { mutableStateOf(false) }

    // Le @ du compte ; sans compte (ou tant qu'il n'est pas lu), le titre de rang de l'onboarding.
    val accountHandle = handle?.takeIf { it.isNotBlank() }
    val displayName = remember(accountHandle, language) {
        accountHandle ?: ProfileIdentity.rankTitle(context, language)
    }
    /** Le mois du premier cours ouvert, faute de date de création de compte. */
    val memberSince = remember(progress.courseProgress, language) {
        ProfileIdentity.memberSince(progress, language)
    }
    val completedCount = progress.courseProgress.count { it.value.isCompleted }
    val authors = remember { AuthorStore.all(context.applicationContext) }
    val followedAuthors = remember(progress.followedCreatorSlugs, authors) {
        progress.followedCreatorSlugs.mapNotNull { slug -> authors.firstOrNull { it.slug == slug } }
    }
    val campaigns by CampaignStore.flow.collectAsState()

    if (showAvatarPicker) {
        AvatarPickerSheet(
            language = language,
            current = progress.avatarId,
            initial = displayName.take(1).uppercase(),
            onPick = { id ->
                progressManager.setAvatar(id)
                showAvatarPicker = false
            },
            onDismiss = { showAvatarPicker = false },
        )
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState())
            .padding(start = 20.dp, end = 20.dp, top = 8.dp, bottom = 32.dp),
    ) {
        // Le titre et les réglages.
        Row(
            modifier = Modifier.fillMaxWidth().dsStagger(0),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(
                text = StringStore.text(context, "profile.title", language),
                modifier = Modifier.weight(1f).semantics { heading() },
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Medium,
                fontSize = 34.sp,
                lineHeight = 41.sp,
                color = DS.ink,
            )
            ProfileRoundButton(
                icon = Icons.Outlined.Settings,
                contentDescription = StringStore.text(context, "settings.title", language),
                onClick = onOpenSettings,
            )
        }

        // Identité : l'avatar (qui ouvre le choix), le @ du compte et l'ancienneté.
        val avatarLabel = StringStore.text(context, "profile.avatar.title", language)
        Row(
            modifier = Modifier.fillMaxWidth().padding(top = 14.dp).dsStagger(1),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            AvatarCircle(
                avatarId = progress.avatarId,
                initial = displayName.take(1).uppercase(),
                size = 64.dp,
                modifier = Modifier
                    .pressable(onClick = { showAvatarPicker = true }, scaleDown = 0.92f)
                    .semantics {
                        contentDescription = avatarLabel
                        role = Role.Button
                    },
            )
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(
                    text = if (accountHandle != null) "@$accountHandle" else displayName,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 20.sp,
                    color = DS.ink,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                memberSince?.let {
                    Text(
                        text = StringStore.text(context, "profile.member.since", language, it),
                        fontFamily = PlusJakartaSans,
                        fontSize = 13.sp,
                        color = DS.inkSecondary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
        }

        // Les compteurs : la série et les cours lus, qui défilent à l'arrivée.
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 14.dp)
                .dsStagger(2)
                .sophiaCard()
                .padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            ProfileStatCell(
                icon = Icons.Filled.LocalFireDepartment,
                iconTint = DS.warm,
                value = progress.streak,
                format = { StringStore.text(context, "common.daysShort", language, it) },
                label = StringStore.text(context, "friends.stats.streak", language).lowercaseIn(language),
                modifier = Modifier.weight(1f),
            )
            Box(modifier = Modifier.width(1.dp).height(36.dp).background(DS.hairline))
            ProfileStatCell(
                icon = Icons.AutoMirrored.Outlined.MenuBook,
                iconTint = DS.accent,
                value = completedCount,
                format = null,
                label = StringStore.text(context, "profile.stat.read", language),
                modifier = Modifier.weight(1f),
            )
        }

        // Les trophées et la ligue, là où les duels existent.
        if (duelsVisible && signedIn != null) {
            duelHome?.let { home ->
                val league = home.currentLeague
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 10.dp)
                        .dsStagger(3)
                        .height(96.dp)
                        .clip(DS.cardShape)
                        .semantics(mergeDescendants = true) { },
                ) {
                    DuelLeagueBackdrop(league = league, modifier = Modifier.fillMaxSize(), thumb = true)
                    // Voile uni, pour que le texte blanc reste lisible sur toute l'illustration.
                    Box(modifier = Modifier.fillMaxSize().background(DuelPalette.night.copy(alpha = 0.6f)))
                    Row(
                        modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Text(
                                text = StringStore.text(context, "duel.trophies.title", language).uppercaseIn(language),
                                fontFamily = PlusJakartaSans,
                                fontWeight = FontWeight.ExtraBold,
                                fontSize = 12.sp,
                                letterSpacing = 0.8.sp,
                                color = Color.White,
                            )
                            Text(
                                text = DuelFormat.leagueName(context, league, language),
                                fontFamily = PlusJakartaSans,
                                fontWeight = FontWeight.ExtraBold,
                                fontSize = 20.sp,
                                color = Color.White,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                            )
                        }
                        DuelTrophyCount(value = home.profile.trophies, language = language, size = 20.dp)
                    }
                }
            }
        }

        // Les cartes d'entrée illustrées.
        Column(
            modifier = Modifier.padding(top = 10.dp).dsStagger(3),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            // L'Entraînement n'a plus d'onglet à lui : il s'ouvre d'ici.
            ProfilePosterCard(
                imageRes = R.drawable.training_poster,
                title = StringStore.text(context, "training.title", language),
                subtitle = StringStore.text(context, "training.locked.tagline", language),
                onClick = onOpenTraining,
            )
            // « Ma progression » : la page illustrée (niveau, série, matières, quiz).
            ProfilePosterCard(
                imageRes = R.drawable.progress_poster,
                title = StringStore.text(context, "profile.progress.title", language),
                subtitle = StringStore.text(context, "profile.progress.subtitle", language),
                onClick = onOpenProgression,
            )
        }

        // Mes abonnements.
        Column(
            modifier = Modifier.padding(top = 24.dp).dsStagger(4),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            ProfileSectionHeader(
                title = StringStore.text(context, "profile.following", language),
                detail = if (followedAuthors.isEmpty()) null else "· ${followedAuthors.size}",
            )
            FollowedCreatorsRow(
                authors = followedAuthors,
                language = language,
                onOpen = onOpenCreator,
                onDiscover = onDiscoverCreators,
            )
        }

        // Les amis et leur classement, à même la page.
        ProfileFriendsSection(
            language = language,
            myAvatarId = progress.avatarId,
            onOpenFriend = { onOpenFriends(it) },
            onEditHandle = { onOpenFriends(null) },
            modifier = Modifier.padding(top = 24.dp).dsStagger(5),
        )

        // Badges : ceux choisis, puis les derniers gagnés, puis les plus proches d'être gagnés.
        val badgeCenter = app.badgeCenter
        LaunchedEffect(Unit) { badgeCenter.refresh() }
        val profileBadges = remember(progress, campaigns, summaries) {
            BadgeRules.profileBadges(badgeCenter.visibleBadges(), progress, badgeCenter.stats(progress))
        }
        Column(
            modifier = Modifier.padding(top = 24.dp).dsStagger(6),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            ProfileSectionHeader(
                title = StringStore.text(context, "profile.badges", language),
                trailing = {
                    ProfileHeaderLink(
                        title = StringStore.text(context, "badges.seeAll", language),
                        onClick = onOpenBadges,
                    )
                },
            )
            BadgeRow(
                badges = profileBadges,
                language = language,
                earned = { it.id in progress.earnedBadges },
                onTap = { onOpenBadges() },
            )
        }

        // Listes.
        val kinds = ProfileListKind.entries
        val kind = kinds[listSegment.coerceIn(0, kinds.size - 1)]
        val items = remember(kind, progress, summaries) { profileListCourses(kind, progress, summaries) }
        Column(
            modifier = Modifier.padding(top = 24.dp).dsStagger(7),
            verticalArrangement = Arrangement.spacedBy(9.dp),
        ) {
            ProfilePillTabs(
                items = kinds.map { "${StringStore.text(context, it.titleKey, language)} · ${profileListCourses(it, progress, summaries).size}" },
                selectedIndex = listSegment,
                onSelect = { listSegment = it },
                fills = true,
            )
            if (items.isEmpty()) {
                Text(
                    text = StringStore.text(context, kind.emptyKey, language),
                    fontFamily = PlusJakartaSans,
                    fontSize = 15.sp,
                    lineHeight = 21.sp,
                    color = DS.inkSecondary,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth().padding(vertical = 20.dp),
                )
            } else {
                items.take(3).forEach { course ->
                    ProfileCourseRow(course = course, language = language, progress = progress, onTap = { onOpenCourse(course) })
                }
                if (items.size > 3) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(44.dp)
                            .pressable(onClick = { onOpenList(kind) }),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(
                            text = StringStore.text(context, "library.seeMore", language),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 15.sp,
                            color = DS.accent,
                            textAlign = TextAlign.Center,
                        )
                    }
                }
            }
        }
    }
}

/** Un compteur du profil : pictogramme sur disque bleu pâle, valeur qui défile, libellé. */
@Composable
private fun ProfileStatCell(
    icon: ImageVector,
    iconTint: Color,
    value: Int,
    format: ((Int) -> String)?,
    label: String,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier.semantics(mergeDescendants = true) { },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Box(
            modifier = Modifier.size(40.dp).clip(CircleShape).background(DS.accentTint),
            contentAlignment = Alignment.Center,
        ) {
            Icon(imageVector = icon, contentDescription = null, tint = iconTint, modifier = Modifier.size(18.dp))
        }
        Column {
            ProfileCountText(
                value = value,
                format = format,
                style = TextStyle(fontFamily = PlusJakartaSans, fontWeight = FontWeight.ExtraBold, fontSize = 17.sp),
            )
            Text(
                text = label,
                fontFamily = PlusJakartaSans,
                fontSize = 12.sp,
                color = DS.inkSecondary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
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
                lineHeight = 21.sp,
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
