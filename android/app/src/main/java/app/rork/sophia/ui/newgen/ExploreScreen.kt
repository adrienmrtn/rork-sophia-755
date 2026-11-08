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
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForwardIos
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.AuthorStore
import app.rork.sophia.data.CampaignStore
import app.rork.sophia.data.CourseAuthor
import app.rork.sophia.data.GlossaryHit
import app.rork.sophia.data.GlossaryStore
import app.rork.sophia.data.LocalCounters
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.analytics.Analytics
import app.rork.sophia.data.compactCount
import app.rork.sophia.data.rememberCourseSummaries
import app.rork.sophia.data.stripInlineMarkup
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Campaign
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.Subject
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.domain.lowercaseIn
import app.rork.sophia.ui.components.ScreenTitle
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.course.AuthorAvatar
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.delay

/**
 * L'onglet Explorer : recherche (cours, créateurs, termes du glossaire), l'événement en
 * cours, les créateurs à découvrir, les cours les plus aimés et les matières. La rangée
 * vidéos n'apparaît que lorsqu'il y aura des vidéos (prompt 10).
 */
@Composable
fun ExploreScreen(
    modifier: Modifier = Modifier,
    language: AppLanguage,
    progress: UserProgress,
    progressManager: ProgressManager,
    onOpenCourse: (CourseSummary) -> Unit,
    onOpenCreator: (CourseAuthor) -> Unit,
    onOpenCampaign: (Campaign) -> Unit,
    onOpenSubject: (Subject) -> Unit,
) {
    val context = LocalContext.current
    val summaries = rememberCourseSummaries(language)
    val authors = remember { AuthorStore.all(context.applicationContext) }
    val campaign = remember { CampaignStore.active(context.applicationContext).firstOrNull() }
    var query by remember { mutableStateOf("") }
    val trimmed = query.trim()
    val isSearching = trimmed.length >= 2

    // Le glossaire se cherche hors du fil principal, après une courte pause de frappe.
    var glossaryHits by remember { mutableStateOf<List<GlossaryHit>>(emptyList()) }
    LaunchedEffect(trimmed, language) {
        if (!isSearching) {
            glossaryHits = emptyList()
            return@LaunchedEffect
        }
        delay(150)
        glossaryHits = GlossaryStore.search(context.applicationContext, language, trimmed, limit = 8)
    }

    val needle = GlossaryStore.searchKey(trimmed)
    val subjectNames = remember(language) {
        Subject.entries.associateWith { StringStore.text(context, "subject.${it.storageKey}.short", language) }
    }
    val matchingCourses = remember(summaries, needle, subjectNames) {
        if (needle.length < 2) emptyList() else summaries.filter { course ->
            GlossaryStore.searchKey(course.title).contains(needle) ||
                GlossaryStore.searchKey(course.subcategory).contains(needle) ||
                GlossaryStore.searchKey(subjectNames[course.subjectEnum].orEmpty()).contains(needle)
        }
    }
    val matchingAuthors = remember(authors, needle, language) {
        if (needle.length < 2) emptyList() else authors.filter { author ->
            GlossaryStore.searchKey(author.name).contains(needle) ||
                GlossaryStore.searchKey(author.title(language).orEmpty()).contains(needle)
        }
    }
    val discoverable = remember(authors) {
        authors.sortedByDescending { LocalCounters.followers(it.slug) }
    }
    val topLiked = remember(summaries) {
        summaries.sortedByDescending { LocalCounters.likes(it.id) }.take(3)
    }
    val coursesBySubject = remember(summaries) { summaries.groupingBy { it.subjectEnum }.eachCount() }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState())
            .padding(start = 20.dp, end = 20.dp, top = 8.dp, bottom = 32.dp),
        verticalArrangement = Arrangement.spacedBy(22.dp),
    ) {
        ScreenTitle(text = StringStore.text(context, "tab.explore", language))

        // Champ de recherche.
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp)
                .clip(DS.controlShape)
                .background(DS.surface)
                .border(1.dp, DS.hairline, DS.controlShape)
                .padding(horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Icon(Icons.Filled.Search, contentDescription = null, tint = DS.inkTertiary, modifier = Modifier.size(18.dp))
            Box(modifier = Modifier.weight(1f), contentAlignment = Alignment.CenterStart) {
                if (query.isEmpty()) {
                    Text(
                        text = StringStore.text(context, "explore.search.placeholder", language),
                        style = SophiaTypography.bodyLarge,
                        color = DS.inkTertiary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
                BasicTextField(
                    value = query,
                    onValueChange = { query = it },
                    singleLine = true,
                    textStyle = SophiaTypography.bodyLarge.copy(color = DS.ink),
                    cursorBrush = SolidColor(DS.accentSoft),
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                    modifier = Modifier.fillMaxWidth(),
                )
            }
            if (query.isNotEmpty()) {
                Icon(
                    Icons.Filled.Cancel,
                    contentDescription = null,
                    tint = DS.inkTertiary,
                    modifier = Modifier.size(18.dp).softPress(onClick = { query = "" }),
                )
            }
        }

        if (isSearching) {
            if (matchingCourses.isEmpty() && matchingAuthors.isEmpty() && glossaryHits.isEmpty()) {
                Column(
                    modifier = Modifier.fillMaxWidth().padding(vertical = 40.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    Text(
                        text = StringStore.text(context, "library.empty.title", language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 17.sp,
                        color = DS.ink,
                        textAlign = TextAlign.Center,
                    )
                    Text(
                        text = StringStore.text(context, "library.empty.subtitle", language),
                        fontFamily = PlusJakartaSans,
                        fontSize = 15.sp,
                        color = DS.inkSecondary,
                        textAlign = TextAlign.Center,
                    )
                }
            }
            if (matchingCourses.isNotEmpty()) {
                NewGenSectionTitle(
                    text = StringStore.text(context, "library.tab.courses", language),
                    trailing = "· ${matchingCourses.size}",
                )
                matchingCourses.take(12).forEach { course ->
                    val identity = remember(course.id) { CreatorIdentity.forCourse(context.applicationContext, course.id) }
                    CompactCourseRow(
                        course = course,
                        meta = identity.name + " · " + subjectNames[course.subjectEnum].orEmpty(),
                        onTap = { onOpenCourse(course) },
                    )
                }
            }
            if (matchingAuthors.isNotEmpty()) {
                NewGenSectionTitle(
                    text = StringStore.text(context, "explore.results.creators", language),
                    trailing = "· ${matchingAuthors.size}",
                )
                matchingAuthors.forEach { author ->
                    CreatorRow(author, language, progress, progressManager, onOpenCreator)
                }
            }
            if (glossaryHits.isNotEmpty()) {
                NewGenSectionTitle(
                    text = StringStore.text(context, "explore.results.glossary", language),
                    trailing = "· ${glossaryHits.size}",
                )
                glossaryHits.forEach { hit ->
                    val course = summaries.firstOrNull { it.id == hit.courseId }
                    GlossaryRow(hit = hit, course = course, onTap = { course?.let(onOpenCourse) })
                }
            }
        } else {
            campaign?.let { active ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .softPress(onClick = { onOpenCampaign(active) })
                        .clip(RoundedCornerShape(18.dp))
                        .background(DS.accent)
                        .padding(horizontal = 18.dp, vertical = 16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    CampaignSymbol(symbol = active.symbol, size = 36.dp, tint = DS.warm)
                    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                        Text(
                            text = active.title(language),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 17.sp,
                            color = Color.White,
                        )
                        var subtitle = StringStore.text(context, "event.card.summary", language, active.courseIds.size, active.upcoming.size)
                        active.endDate?.let { end ->
                            subtitle += " · " + StringStore.text(context, "event.card.until", language, NewGenFormat.shortDay(end, language)).lowercaseIn(language)
                        }
                        Text(
                            text = subtitle,
                            fontFamily = PlusJakartaSans,
                            fontSize = 13.sp,
                            color = Color.White.copy(alpha = 0.85f),
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowForwardIos,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(14.dp),
                    )
                }
            }

            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                NewGenSectionTitle(text = StringStore.text(context, "explore.creators", language))
                discoverable.take(7).forEach { author ->
                    CreatorRow(author, language, progress, progressManager, onOpenCreator)
                }
            }

            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                NewGenSectionTitle(text = StringStore.text(context, "explore.topLiked", language))
                topLiked.forEachIndexed { index, course ->
                    val identity = remember(course.id) { CreatorIdentity.forCourse(context.applicationContext, course.id) }
                    val liked = course.id in progress.likedCourseIds
                    val shape = RoundedCornerShape(18.dp)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .softPress(onClick = { onOpenCourse(course) })
                            .clip(shape)
                            .background(DS.surface)
                            .border(1.dp, DS.hairline, shape)
                            .padding(10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        Text(
                            text = "${index + 1}",
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 22.sp,
                            color = DS.ink,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.width(22.dp),
                        )
                        CourseCover(courseId = course.id, modifier = Modifier.size(64.dp), cornerRadius = 14.dp)
                        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                            Text(
                                text = stripInlineMarkup(course.title),
                                fontFamily = PlusJakartaSans,
                                fontWeight = FontWeight.Bold,
                                fontSize = 15.sp,
                                lineHeight = 20.sp,
                                color = DS.ink,
                                maxLines = 2,
                                overflow = TextOverflow.Ellipsis,
                            )
                            Text(
                                text = identity.name + " · " +
                                    LocalCounters.likesCount(course.id, liked).compactCount(language) + " " +
                                    StringStore.text(context, "common.likes", language),
                                fontFamily = PlusJakartaSans,
                                fontSize = 12.sp,
                                color = DS.inkSecondary,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                            )
                        }
                    }
                }
            }

            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                NewGenSectionTitle(text = StringStore.text(context, "explore.subjects", language))
                // Deux colonnes, à la main : la grille vit dans un écran déjà défilant.
                Subject.entries.chunked(2).forEach { pair ->
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        pair.forEach { subject ->
                            SubjectTile(
                                subject = subject,
                                name = subjectNames[subject].orEmpty(),
                                count = coursesBySubject[subject] ?: 0,
                                language = language,
                                onClick = { onOpenSubject(subject) },
                                modifier = Modifier.weight(1f),
                            )
                        }
                        if (pair.size == 1) Spacer(Modifier.weight(1f))
                    }
                }
            }
        }
    }
}

/** Un créateur à découvrir : avatar, nom avec coche, pedigree, abonnés, et « Suivre ». */
@Composable
private fun CreatorRow(
    author: CourseAuthor,
    language: AppLanguage,
    progress: UserProgress,
    progressManager: ProgressManager,
    onOpenCreator: (CourseAuthor) -> Unit,
) {
    val context = LocalContext.current
    val following = author.slug in progress.followedCreatorSlugs
    val shape = RoundedCornerShape(18.dp)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(DS.surface)
            .border(1.dp, DS.hairline, shape)
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(
            modifier = Modifier.weight(1f).softPress(onClick = { onOpenCreator(author) }),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            AuthorAvatar(author = author, size = 48.dp)
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(
                        text = author.name,
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp,
                        color = DS.ink,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f, fill = false),
                    )
                    if (author.isVerified) VerifiedCheck(language = language, size = 13.dp)
                }
                author.title(language)?.let { pedigree ->
                    Text(
                        text = pedigree,
                        fontFamily = PlusJakartaSans,
                        fontSize = 12.sp,
                        color = DS.inkSecondary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
                Text(
                    text = (LocalCounters.followers(author.slug) + (if (following) 1 else 0)).compactCount(language) + " " +
                        StringStore.text(context, "creator.stat.followers", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 12.sp,
                    color = DS.inkSecondary,
                    maxLines = 1,
                )
            }
        }
        FollowButton(
            isFollowing = following,
            language = language,
            compact = true,
            onClick = {
                val wasFollowing = progressManager.isFollowing(author.slug)
                progressManager.toggleFollow(author.slug)
                Analytics.log(if (wasFollowing) "unfollow" else "follow", screen = "explore", props = mapOf("creator" to author.slug))
            },
        )
    }
}

@Composable
private fun GlossaryRow(hit: GlossaryHit, course: CourseSummary?, onTap: () -> Unit) {
    val shape = RoundedCornerShape(18.dp)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .softPress(onClick = onTap)
            .clip(shape)
            .background(DS.surface)
            .border(1.dp, DS.hairline, shape)
            .padding(12.dp),
        verticalAlignment = Alignment.Top,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(
            modifier = Modifier.size(40.dp).clip(RoundedCornerShape(12.dp)).background(DS.accentTint),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.MenuBook,
                contentDescription = null,
                tint = DS.accentSoft,
                modifier = Modifier.size(16.dp),
            )
        }
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(
                text = hit.entry.displayTerm,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 15.sp,
                color = DS.ink,
            )
            Text(
                text = hit.entry.explanation,
                fontFamily = PlusJakartaSans,
                fontSize = 12.sp,
                lineHeight = 16.sp,
                color = DS.inkSecondary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            if (course != null) {
                Text(
                    text = stripInlineMarkup(course.title),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 12.sp,
                    color = DS.accentSoft,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
    }
}

@Composable
private fun SubjectTile(
    subject: Subject,
    name: String,
    count: Int,
    language: AppLanguage,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val shape = RoundedCornerShape(18.dp)
    Column(
        modifier = modifier
            .heightIn(min = 112.dp)
            .softPress(onClick = onClick)
            .clip(shape)
            .background(DS.surface)
            .border(1.dp, DS.hairline, shape)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Box(modifier = Modifier.size(12.dp).clip(CircleShape).background(subject.color))
        Text(
            text = name,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 17.sp,
            lineHeight = 22.sp,
            color = DS.ink,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            text = StringStore.text(context, "subject.courses.count", language, count),
            fontFamily = PlusJakartaSans,
            fontSize = 13.sp,
            color = DS.inkSecondary,
        )
    }
}
