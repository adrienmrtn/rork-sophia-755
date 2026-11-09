package app.rork.sophia.ui.newgen

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
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
import app.rork.sophia.data.CourseAuthor
import app.rork.sophia.data.GlossaryHit
import app.rork.sophia.data.GlossaryStore
import app.rork.sophia.data.LocalCounters
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.ReadingTime
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.analytics.Analytics
import app.rork.sophia.data.catalog.CatalogStore
import app.rork.sophia.data.compactCount
import app.rork.sophia.data.rememberCourseSummaries
import app.rork.sophia.data.stripInlineMarkup
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Campaign
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.Subject
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.domain.readsCount
import app.rork.sophia.ui.components.ScreenTitle
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.course.AuthorAvatar
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.Calendar

/**
 * L'onglet Explorer, variante « univers » de la maquette : la recherche (cours, créateurs,
 * termes du glossaire), les sujets qu'on cherche beaucoup cette semaine, la grille des univers
 * (les grandes sous-catégories du catalogue, avec une couverture), et les créateurs à suivre
 * en carrousel. La rangée « En moins d'une minute » arrivera avec les vidéos (prompt 10).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ExploreScreen(
    modifier: Modifier = Modifier,
    language: AppLanguage,
    progress: UserProgress,
    progressManager: ProgressManager,
    onOpenCourse: (CourseSummary) -> Unit,
    onOpenCreator: (CourseAuthor) -> Unit,
    onOpenCampaign: (Campaign) -> Unit,
    onOpenUniverse: (String) -> Unit,
) {
    val context = LocalContext.current
    val summaries = rememberCourseSummaries(language)
    val authors = remember { AuthorStore.all(context.applicationContext) }
    var query by remember { mutableStateOf("") }
    var selectedTrend by remember { mutableStateOf<String?>(null) }
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

    // Six cours au titre court, tirés une fois par semaine (graine = semaine ISO) parmi ceux
    // que le lecteur n'a pas encore lus. Ils tiennent lieu de « tendances » jusqu'à ce que le
    // serveur compte les vraies recherches.
    val trending = remember(summaries, progress.courseProgress) {
        val calendar = Calendar.getInstance().apply {
            firstDayOfWeek = Calendar.MONDAY
            minimalDaysInFirstWeek = 4
        }
        val seed = "${calendar.get(Calendar.YEAR)}-${calendar.get(Calendar.WEEK_OF_YEAR)}"
        summaries
            .filter { stripInlineMarkup(it.title).length <= 22 && progress.courseProgress[it.id]?.isCompleted != true }
            .sortedBy { LocalCounters.hash("$seed|${it.id}") }
            .take(6)
    }

    // Les six plus grandes sous-catégories de la langue courante, avec la couverture de leur
    // cours le plus lu.
    val universes = remember(summaries) {
        summaries
            .filter { it.subcategory.isNotBlank() }
            .groupBy { it.subcategory }
            .mapNotNull { (name, courses) ->
                val cover = courses.maxByOrNull { it.readsCount } ?: return@mapNotNull null
                Universe(name = name, courses = courses, cover = cover)
            }
            .sortedWith(compareByDescending<Universe> { it.courses.size }.thenBy { it.name })
            .take(6)
    }

    fun courseMeta(course: CourseSummary): String {
        val identity = CreatorIdentity.forCourse(context.applicationContext, course.id)
        val minutes = ReadingTime.cached(language, course.id)?.minutes
        return if (minutes != null) {
            identity.name + " · " + NewGenFormat.minutes(context, minutes, language)
        } else {
            identity.name + " · " + subjectNames[course.subjectEnum].orEmpty()
        }
    }

    @Composable
    fun courseRow(course: CourseSummary) {
        val completed = progress.courseProgress[course.id]?.isCompleted == true
        CompactCourseRow(
            course = course,
            meta = remember(course.id, language) { courseMeta(course) },
            onTap = { onOpenCourse(course) },
            trailing = if (completed) {
                { ReadCheck(language = language) }
            } else {
                null
            },
        )
    }

    // Tirer vers le bas relit le catalogue en ligne tout de suite (nouveaux cours, corrections).
    val refreshScope = rememberCoroutineScope()
    var refreshing by remember { mutableStateOf(false) }
    PullToRefreshBox(
        isRefreshing = refreshing,
        onRefresh = {
            refreshScope.launch {
                refreshing = true
                try {
                    CatalogStore.refresh(context.applicationContext, language, force = true)
                } finally {
                    refreshing = false
                }
            }
        },
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas),
    ) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(top = 8.dp, bottom = 32.dp),
        verticalArrangement = Arrangement.spacedBy(22.dp),
    ) {
        ScreenTitle(text = StringStore.text(context, "tab.explore", language), modifier = Modifier.padding(horizontal = 20.dp))

        // Champ de recherche.
        Row(
            modifier = Modifier
                .padding(horizontal = 20.dp)
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
            Column(modifier = Modifier.padding(horizontal = 20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
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
                    matchingCourses.take(12).forEach { course -> courseRow(course) }
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
            }
        } else {
            // On cherche beaucoup cette semaine.
            if (trending.isNotEmpty()) {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        text = StringStore.text(context, "explore.trending", language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 13.sp,
                        color = DS.inkSecondary,
                        modifier = Modifier.padding(horizontal = 20.dp),
                    )
                    Row(
                        modifier = Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 20.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        trending.forEach { course ->
                            val selected = selectedTrend == course.id
                            Row(
                                modifier = Modifier
                                    .softPress(onClick = { selectedTrend = if (selected) null else course.id })
                                    .height(38.dp)
                                    .clip(CircleShape)
                                    .background(if (selected) DS.accent else DS.surface)
                                    .border(1.dp, if (selected) DS.accent else DS.hairline, CircleShape)
                                    .padding(horizontal = 14.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(6.dp),
                            ) {
                                Icon(
                                    imageVector = Icons.AutoMirrored.Filled.TrendingUp,
                                    contentDescription = null,
                                    tint = if (selected) Color.White else DS.ink,
                                    modifier = Modifier.size(14.dp),
                                )
                                Text(
                                    text = stripInlineMarkup(course.title),
                                    fontFamily = PlusJakartaSans,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 14.sp,
                                    color = if (selected) Color.White else DS.ink,
                                    maxLines = 1,
                                )
                            }
                        }
                    }
                    val selectedCourse = trending.firstOrNull { it.id == selectedTrend }
                    AnimatedVisibility(visible = selectedCourse != null) {
                        val course = selectedCourse ?: return@AnimatedVisibility
                        // Le cours de la tendance choisie, puis deux voisins de la même sous-catégorie.
                        val results = remember(course.id, summaries) {
                            listOf(course) + summaries
                                .filter { it.id != course.id && it.subcategory == course.subcategory }
                                .sortedByDescending { it.readsCount }
                                .take(2)
                        }
                        Column(
                            modifier = Modifier.padding(horizontal = 20.dp).padding(top = 4.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            results.forEach { result -> courseRow(result) }
                        }
                    }
                }
            }

            // Univers.
            Column(modifier = Modifier.padding(horizontal = 20.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                NewGenSectionTitle(text = StringStore.text(context, "explore.universes", language))
                // Deux colonnes, à la main : la grille vit dans un écran déjà défilant.
                universes.chunked(2).forEach { pair ->
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        pair.forEach { universe ->
                            UniverseTile(
                                universe = universe,
                                language = language,
                                onClick = { onOpenUniverse(universe.name) },
                                modifier = Modifier.weight(1f),
                            )
                        }
                        if (pair.size == 1) Spacer(Modifier.weight(1f))
                    }
                }
            }

            // Créateurs à suivre.
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                NewGenSectionTitle(
                    text = StringStore.text(context, "explore.creatorsToFollow", language),
                    modifier = Modifier.padding(horizontal = 20.dp),
                )
                Row(
                    modifier = Modifier
                        .horizontalScroll(rememberScrollState())
                        .padding(horizontal = 20.dp)
                        .padding(bottom = 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalAlignment = Alignment.Top,
                ) {
                    discoverable.take(8).forEach { author ->
                        CreatorCard(author, language, progress, progressManager, onOpenCreator)
                    }
                }
            }
        }
    }
    }
}

/** Une sous-catégorie du catalogue, avec la couverture de son cours le plus lu. */
internal data class Universe(val name: String, val courses: List<CourseSummary>, val cover: CourseSummary)

/** La tuile d'un univers : la couverture plein fond, un bandeau sombre avec le nom et le compte. */
@Composable
private fun UniverseTile(
    universe: Universe,
    language: AppLanguage,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val shape = RoundedCornerShape(18.dp)
    Box(
        modifier = modifier
            .height(128.dp)
            .softPress(onClick = onClick)
            .clip(shape)
            .background(DS.surfaceMuted),
        contentAlignment = Alignment.BottomStart,
    ) {
        CourseCover(courseId = universe.cover.id, modifier = Modifier.fillMaxSize(), cornerRadius = 0.dp, letterSize = 36.sp)
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(Color(0x9E0B1220))
                .padding(horizontal = 12.dp, vertical = 10.dp),
            verticalArrangement = Arrangement.spacedBy(1.dp),
        ) {
            Text(
                text = universe.name,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 15.sp,
                lineHeight = 19.sp,
                color = Color.White,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                text = StringStore.text(context, "subject.courses.count", language, universe.courses.size),
                fontFamily = PlusJakartaSans,
                fontSize = 12.sp,
                color = Color.White.copy(alpha = 0.88f),
            )
        }
    }
}

/** La carte verticale de la maquette : avatar, nom, pedigree sur deux lignes, abonnés, Suivre. */
@Composable
private fun CreatorCard(
    author: CourseAuthor,
    language: AppLanguage,
    progress: UserProgress,
    progressManager: ProgressManager,
    onOpenCreator: (CourseAuthor) -> Unit,
) {
    val context = LocalContext.current
    val following = author.slug in progress.followedCreatorSlugs
    val shape = RoundedCornerShape(18.dp)
    Column(
        modifier = Modifier
            .width(156.dp)
            .clip(shape)
            .background(DS.surface)
            .border(1.dp, DS.hairline, shape)
            .padding(14.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().softPress(onClick = { onOpenCreator(author) }),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            AuthorAvatar(author = author, size = 60.dp)
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    text = author.name,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 14.sp,
                    color = DS.ink,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f, fill = false),
                )
                if (author.isVerified) VerifiedCheck(language = language, size = 12.dp)
            }
            Text(
                text = author.title(language).orEmpty(),
                fontFamily = PlusJakartaSans,
                fontSize = 12.sp,
                lineHeight = 16.sp,
                color = DS.inkSecondary,
                textAlign = TextAlign.Center,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.height(32.dp),
            )
            Text(
                text = (LocalCounters.followers(author.slug) + (if (following) 1 else 0)).compactCount(language) + " " +
                    StringStore.text(context, "creator.stat.followers", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 12.sp,
                color = DS.inkSecondary,
                maxLines = 1,
            )
        }
        FollowButton(
            isFollowing = following,
            language = language,
            compact = true,
            modifier = Modifier.fillMaxWidth().padding(top = 4.dp),
            onClick = {
                val wasFollowing = progressManager.isFollowing(author.slug)
                progressManager.toggleFollow(author.slug)
                Analytics.log(if (wasFollowing) "unfollow" else "follow", screen = "explore", props = mapOf("creator" to author.slug))
            },
        )
    }
}

/** Un créateur dans les résultats de recherche : avatar, nom avec coche, pedigree, abonnés, et « Suivre ». */
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

/** Les cours d'un univers (une sous-catégorie), ouverts depuis la grille de l'onglet Explorer. */
@Composable
fun UniverseCoursesScreen(
    subcategory: String,
    language: AppLanguage,
    progress: UserProgress,
    onBack: () -> Unit,
    onOpenCourse: (CourseSummary) -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val summaries = rememberCourseSummaries(language)
    val courses = remember(subcategory, summaries) {
        summaries.filter { it.subcategory == subcategory }.sortedByDescending { it.readsCount }
    }
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
            title = "$subcategory · ${courses.size}",
            modifier = Modifier.padding(bottom = 8.dp),
        )
        courses.forEach { course ->
            val identity = remember(course.id) { CreatorIdentity.forCourse(context.applicationContext, course.id) }
            val completed = progress.courseProgress[course.id]?.isCompleted == true
            CompactCourseRow(
                course = course,
                meta = identity.name + " · " + StringStore.text(context, "subject.${course.subjectEnum.storageKey}.short", language),
                onTap = { onOpenCourse(course) },
                trailing = if (completed) {
                    { ReadCheck(language = language) }
                } else {
                    null
                },
            )
        }
        Spacer(Modifier.height(4.dp))
    }
}
