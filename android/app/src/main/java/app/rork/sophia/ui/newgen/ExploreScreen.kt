package app.rork.sophia.ui.newgen

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
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
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
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
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.course.AuthorAvatar
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import java.util.Calendar
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import androidx.compose.foundation.Image
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.layout.ContentScale
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.heightIn
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import app.rork.sophia.domain.LearningPathEngine
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.R
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.ColorFilter
import app.rork.sophia.data.CampaignStore

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
    onOpenPath: () -> Unit,
) {
    val context = LocalContext.current
    val summaries = rememberCourseSummaries(language)
    val authors = remember { AuthorStore.all(context.applicationContext) }
    var query by remember { mutableStateOf("") }
    var selectedTrend by remember { mutableStateOf<String?>(null) }
    var searchFocused by remember { mutableStateOf(false) }
    val haptics = rememberHaptics()
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
    // Les cours les plus ouverts de la semaine (`trending` du manifeste, comptés chaque nuit), moins
    // ceux déjà lus ; faute de données, le tirage local hebdomadaire ci-dessous.
    val serverTrending by CatalogStore.trending.collectAsState()
    val trending = remember(summaries, progress.courseProgress, serverTrending) {
        val fromServer = (serverTrending[language.code] ?: emptyList())
            .mapNotNull { id -> summaries.firstOrNull { it.id == id } }
            .filter { progress.courseProgress[it.id]?.isCompleted != true }
        if (fromServer.size >= 3) return@remember fromServer.take(6)
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
            .padding(top = 16.dp, bottom = 32.dp),
        verticalArrangement = Arrangement.spacedBy(24.dp),
    ) {
        Column(modifier = Modifier.padding(horizontal = SIDE_MARGIN), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Text(
                text = StringStore.text(context, "tab.explore", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Medium,
                fontSize = 32.sp,
                color = DS.ink,
            )

            // Champ de recherche : actif, il prend la bordure bleue des états sélectionnés.
            val fieldBorder by animateColorAsState(
                targetValue = if (searchFocused) DS.accent else DS.hairline,
                animationSpec = DSMotion.snappy(),
                label = "searchBorder",
            )
            val searchTint by animateColorAsState(
                targetValue = if (searchFocused) DS.accent else DS.inkSecondary,
                animationSpec = DSMotion.snappy(),
                label = "searchIcon",
            )
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp)
                    .homeCard(border = fieldBorder)
                    .padding(start = 14.dp, end = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Icon(Icons.Filled.Search, contentDescription = null, tint = searchTint, modifier = Modifier.size(20.dp))
                Box(modifier = Modifier.weight(1f), contentAlignment = Alignment.CenterStart) {
                    if (query.isEmpty()) {
                        Text(
                            text = StringStore.text(context, "explore.search.placeholder", language),
                            fontFamily = PlusJakartaSans,
                            fontSize = 15.sp,
                            color = DS.inkTertiary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                    BasicTextField(
                        value = query,
                        onValueChange = { query = it },
                        singleLine = true,
                        textStyle = SophiaTypography.bodyLarge.copy(color = DS.ink, fontSize = 15.sp),
                        cursorBrush = SolidColor(DS.accent),
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                        modifier = Modifier.fillMaxWidth().onFocusChanged { searchFocused = it.isFocused },
                    )
                }
                AnimatedVisibility(
                    visible = query.isNotEmpty(),
                    enter = scaleIn(DSMotion.pop()) + fadeIn(),
                    exit = scaleOut() + fadeOut(),
                ) {
                    val clearLabel = StringStore.text(context, "explore.search.clear", language)
                    Box(
                        modifier = Modifier
                            .size(28.dp)
                            .pressable(onClick = { query = "" }, scaleDown = 0.88f)
                            .clip(CircleShape)
                            .background(DS.accentTint)
                            .semantics { contentDescription = clearLabel },
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(Icons.Filled.Close, contentDescription = null, tint = DS.ink, modifier = Modifier.size(14.dp))
                    }
                }
            }
        }

        if (isSearching) {
            Column(modifier = Modifier.padding(horizontal = SIDE_MARGIN), verticalArrangement = Arrangement.spacedBy(24.dp)) {
                if (matchingCourses.isEmpty() && matchingAuthors.isEmpty() && glossaryHits.isEmpty()) {
                    Column(
                        modifier = Modifier.fillMaxWidth().homeCard().padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(4.dp),
                    ) {
                        Text(
                            text = StringStore.text(context, "library.empty.title", language),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 16.sp,
                            color = DS.ink,
                        )
                        Text(
                            text = StringStore.text(context, "library.empty.subtitle", language),
                            fontFamily = PlusJakartaSans,
                            fontSize = 15.sp,
                            lineHeight = 21.sp,
                            color = DS.inkSecondary,
                        )
                    }
                }
                // Chaque famille de résultats : son titre, puis ses lignes serrées dessous.
                if (matchingCourses.isNotEmpty()) {
                    Column(verticalArrangement = Arrangement.spacedBy(9.dp)) {
                        NewGenSectionTitle(
                            text = StringStore.text(context, "library.tab.courses", language),
                            trailing = "· ${matchingCourses.size}",
                        )
                        matchingCourses.take(12).forEach { course -> courseRow(course) }
                    }
                }
                if (matchingAuthors.isNotEmpty()) {
                    Column(verticalArrangement = Arrangement.spacedBy(9.dp)) {
                        NewGenSectionTitle(
                            text = StringStore.text(context, "explore.results.creators", language),
                            trailing = "· ${matchingAuthors.size}",
                        )
                        matchingAuthors.forEach { author ->
                            CreatorRow(author, language, progress, progressManager, onOpenCreator)
                        }
                    }
                }
                if (glossaryHits.isNotEmpty()) {
                    Column(verticalArrangement = Arrangement.spacedBy(9.dp)) {
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
            }
        } else {
            // Les événements que le serveur sert : en cours, puis terminés (grisés).
            EventsRow(
                language = language,
                summaries = summaries,
                onOpenCampaign = onOpenCampaign,
                modifier = Modifier.dsStagger(0),
            )

            // On cherche beaucoup cette semaine.
            if (trending.isNotEmpty()) {
                Column(modifier = Modifier.dsStagger(1), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        text = StringStore.text(context, "explore.trending", language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 13.sp,
                        color = DS.inkSecondary,
                        modifier = Modifier.padding(horizontal = SIDE_MARGIN),
                    )
                    Row(
                        modifier = Modifier
                            .horizontalScroll(rememberScrollState())
                            .padding(horizontal = SIDE_MARGIN)
                            .padding(bottom = 2.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        trending.forEach { course ->
                            val selected = selectedTrend == course.id
                            val chipFill by animateColorAsState(if (selected) DS.accent else DS.surface, DSMotion.snappy(), label = "trendFill")
                            val chipBorder by animateColorAsState(if (selected) DS.accent else DS.hairline, DSMotion.snappy(), label = "trendBorder")
                            val chipInk by animateColorAsState(if (selected) Color.White else DS.ink, DSMotion.snappy(), label = "trendInk")
                            Row(
                                modifier = Modifier
                                    .pressable(
                                        onClick = {
                                            haptics.select()
                                            selectedTrend = if (selected) null else course.id
                                        },
                                        scaleDown = 0.96f,
                                        haptic = false,
                                    )
                                    .height(44.dp)
                                    .homeCard(fill = chipFill, border = chipBorder)
                                    .padding(horizontal = 14.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                            ) {
                                Icon(
                                    imageVector = Icons.AutoMirrored.Filled.TrendingUp,
                                    contentDescription = null,
                                    tint = chipInk,
                                    modifier = Modifier.size(15.dp),
                                )
                                Text(
                                    text = stripInlineMarkup(course.title),
                                    fontFamily = PlusJakartaSans,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 15.sp,
                                    color = chipInk,
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
                            modifier = Modifier.padding(horizontal = SIDE_MARGIN).padding(bottom = 2.dp),
                            verticalArrangement = Arrangement.spacedBy(9.dp),
                        ) {
                            results.forEach { result -> courseRow(result) }
                        }
                    }
                }
            }

            // Univers.
            Column(
                modifier = Modifier.padding(horizontal = SIDE_MARGIN).dsStagger(2),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
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
            Column(modifier = Modifier.dsStagger(3), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                NewGenSectionTitle(
                    text = StringStore.text(context, "explore.creatorsToFollow", language),
                    modifier = Modifier.padding(horizontal = SIDE_MARGIN),
                )
                Row(
                    modifier = Modifier
                        .horizontalScroll(rememberScrollState())
                        .padding(horizontal = SIDE_MARGIN)
                        .padding(bottom = 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalAlignment = Alignment.Top,
                ) {
                    discoverable.take(8).forEach { author ->
                        CreatorCard(author, language, progress, progressManager, onOpenCreator)
                    }
                }
            }

            // Le Parcours n'a plus d'onglet à lui : son entrée est tout en bas de la page.
            PathCard(
                language = language,
                progress = progress,
                onClick = onOpenPath,
                modifier = Modifier.padding(horizontal = SIDE_MARGIN).dsStagger(4),
            )
        }
    }
    }
}

/** Marge latérale de l'écran. */
private val SIDE_MARGIN = 24.dp

/**
 * Les événements que le serveur sert (publiés, dans la région du téléphone) : ceux en cours
 * d'abord (le plus proche de sa fin en tête), puis les terminés, du plus récent au plus ancien,
 * grisés. Un événement terminé reste là tant qu'il est en ligne et disparaît quand il n'est plus
 * publié ; ceux qui n'ont pas commencé ne sont pas montrés.
 */
@Composable
private fun EventsRow(
    language: AppLanguage,
    summaries: List<CourseSummary>,
    onOpenCampaign: (Campaign) -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val campaigns by CampaignStore.flow.collectAsState()
    val items = remember(campaigns) {
        CampaignStore.active().map { it to false } + CampaignStore.ended().map { it to true }
    }
    if (items.isEmpty()) return
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(10.dp)) {
        NewGenSectionTitle(
            text = StringStore.text(context, "badges.family.events", language),
            modifier = Modifier.padding(horizontal = SIDE_MARGIN),
        )
        Row(
            modifier = Modifier
                .horizontalScroll(rememberScrollState())
                .padding(horizontal = SIDE_MARGIN)
                .padding(bottom = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.Top,
        ) {
            items.forEach { (campaign, ended) ->
                EventCard(
                    campaign = campaign,
                    ended = ended,
                    language = language,
                    summaries = summaries,
                    onClick = { onOpenCampaign(campaign) },
                )
            }
        }
    }
}

private val EVENT_CARD_WIDTH = 232.dp

/** Gris pour les événements terminés : l'image comme le texte perdent leur couleur. */
private val ENDED_EVENT_FILTER = ColorFilter.colorMatrix(ColorMatrix().apply { setToSaturation(0f) })

/**
 * Une carte d'événement du carrousel. Toutes ont la même taille : l'illustration a une hauteur
 * fixe et chaque ligne de texte réserve sa place (le titre toujours deux lignes).
 */
@Composable
private fun EventCard(
    campaign: Campaign,
    ended: Boolean,
    language: AppLanguage,
    summaries: List<CourseSummary>,
    onClick: () -> Unit,
) {
    val context = LocalContext.current
    val courses = remember(summaries, campaign.slug) {
        campaign.courseIds.mapNotNull { id -> summaries.firstOrNull { it.id == id } }
    }
    // « Jusqu'au 30 nov. » pour un événement en cours, « 1 nov. – 30 nov. » pour un terminé.
    val end = campaign.endDate
    val start = campaign.startDate
    val dates = when {
        end == null -> " "
        !ended -> StringStore.text(context, "event.until", language, NewGenFormat.shortDay(end, language))
        start == null -> NewGenFormat.shortDay(end, language)
        else -> NewGenFormat.shortDay(start, language) + " – " + NewGenFormat.shortDay(end, language)
    }
    Column(
        modifier = Modifier
            .width(EVENT_CARD_WIDTH)
            .pressable(onClick = onClick)
            // Terminé : la carte passe en gris et s'efface un peu, mais reste ouvrable.
            .then(
                if (ended) {
                    Modifier.graphicsLayer {
                        alpha = 0.6f
                        compositingStrategy = CompositingStrategy.Offscreen
                    }.drawWithContent {
                        val paint = Paint().apply { colorFilter = ENDED_EVENT_FILTER }
                        drawIntoCanvas { canvas ->
                            canvas.saveLayer(Rect(0f, 0f, size.width, size.height), paint)
                            drawContent()
                            canvas.restore()
                        }
                    }
                } else {
                    Modifier
                },
            )
            .homeCard(),
    ) {
        Box(modifier = Modifier.fillMaxWidth().height(130.dp)) {
            EventArtwork(campaign = campaign, courses = courses, modifier = Modifier.fillMaxSize())
            if (ended) {
                EventPill(text = StringStore.text(context, "event.ended", language), dark = true, modifier = Modifier.padding(10.dp))
            }
        }
        Column(
            modifier = Modifier.padding(start = 12.dp, end = 12.dp, top = 10.dp, bottom = 12.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            Text(
                text = dates,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 12.sp,
                color = if (ended) DS.inkTertiary else DS.accent,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                text = campaign.title(language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 16.sp,
                lineHeight = 21.sp,
                color = DS.ink,
                // Toujours deux lignes, pour que toutes les cartes aient la même hauteur.
                minLines = 2,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                text = StringStore.text(context, "event.card.coursesToRead", language, courses.size),
                fontFamily = PlusJakartaSans,
                fontSize = 13.sp,
                color = DS.inkSecondary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

/**
 * L'entrée du Parcours : sur fond marine, avec son illustration en papier découpé
 * (`path_poster`, même direction que le site) et le niveau où en est le lecteur.
 */
@Composable
private fun PathCard(
    language: AppLanguage,
    progress: UserProgress,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    // Le niveau en cours : le premier qui n'est pas réussi, sinon le dernier. Les collections
    // se lisent hors du fil principal ; sans elles, la carte annonce le niveau 1.
    var collections by remember(language) { mutableStateOf(ContentCatalog.cachedCollections(language)) }
    var coursesById by remember(language) {
        mutableStateOf(ContentCatalog.cachedSummaries(language)?.associateBy { it.id })
    }
    LaunchedEffect(language) {
        if (collections == null) {
            collections = ContentCatalog.collectionsAsync(context.applicationContext, language)
        }
        if (coursesById == null) {
            coursesById = ContentCatalog.summariesAsync(context.applicationContext, language).associateBy { it.id }
        }
    }
    val level = remember(collections, coursesById, progress.courseProgress, progress.pathLevelResults) {
        val all = collections
        val byId = coursesById
        if (all == null || byId == null) {
            1
        } else {
            val completed = progress.courseProgress.filterValues { it.isCompleted }.keys
            val passed = progress.pathLevelResults.filterValues { it.isPassed }.keys
            val levels = LearningPathEngine.snapshot(all, byId, { it in completed }, { it in passed }).levels
            (levels.firstOrNull { !it.isPassed } ?: levels.lastOrNull())?.number ?: 1
        }
    }
    val posterWidth = 128.dp
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(IntrinsicSize.Min)
            .pressable(onClick = onClick)
            .clip(DS.cardShape)
            .background(PATH_CARD_NAVY),
    ) {
        Image(
            painter = painterResource(R.drawable.path_poster),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.align(Alignment.CenterEnd).width(posterWidth).fillMaxHeight(),
        )
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 132.dp)
                .padding(16.dp)
                .padding(end = posterWidth),
            verticalArrangement = Arrangement.spacedBy(6.dp, Alignment.CenterVertically),
        ) {
            Text(
                text = StringStore.text(context, "path.title", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 20.sp,
                color = Color.White,
            )
            Text(
                text = StringStore.text(context, "explore.path.subtitle", language),
                fontFamily = PlusJakartaSans,
                fontSize = 15.sp,
                lineHeight = 20.sp,
                color = EventPalette.softText,
            )
            Row(
                modifier = Modifier
                    .padding(top = 4.dp)
                    .height(32.dp)
                    .clip(CircleShape)
                    .background(PATH_CARD_SAFFRON)
                    .padding(horizontal = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                Text(
                    text = StringStore.text(context, "path.levelCaption", language, level),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 15.sp,
                    color = EventPalette.ink,
                    maxLines = 1,
                )
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = null,
                    tint = EventPalette.ink,
                    modifier = Modifier.size(16.dp),
                )
            }
        }
    }
}

/** Marine et safran des illustrations du site (`EventPalette` sur iOS). */
private val PATH_CARD_NAVY = EventPalette.navy
private val PATH_CARD_SAFFRON = EventPalette.saffron

/** Une sous-catégorie du catalogue, avec la couverture de son cours le plus lu. */
internal data class Universe(val name: String, val courses: List<CourseSummary>, val cover: CourseSummary)

/**
 * La tuile d'un univers : la couverture en haut, le nom (deux lignes réservées) et le nombre de
 * cours dessous, sur fond blanc.
 */
@Composable
private fun UniverseTile(
    universe: Universe,
    language: AppLanguage,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    Column(
        modifier = modifier
            .pressable(onClick = onClick)
            .homeCard(),
    ) {
        CourseCover(
            courseId = universe.cover.id,
            modifier = Modifier.fillMaxWidth().height(84.dp),
            cornerRadius = 0.dp,
            letterSize = 30.sp,
        )
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(start = 10.dp, end = 10.dp, top = 8.dp, bottom = 10.dp),
            verticalArrangement = Arrangement.spacedBy(2.dp),
        ) {
            Text(
                text = universe.name,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 13.sp,
                lineHeight = 17.sp,
                color = DS.ink,
                minLines = 2,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                text = StringStore.text(context, "subject.courses.count", language, universe.courses.size),
                fontFamily = PlusJakartaSans,
                fontSize = 12.sp,
                color = DS.inkSecondary,
                maxLines = 1,
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
    Column(
        modifier = Modifier
            .width(168.dp)
            .homeCard()
            .padding(horizontal = 12.dp, vertical = 14.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().pressable(onClick = { onOpenCreator(author) }),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            AuthorAvatar(author = author, size = 60.dp)
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
                fontWeight = FontWeight.SemiBold,
                fontSize = 13.sp,
                color = DS.ink,
                maxLines = 1,
            )
        }
        FollowButton(
            isFollowing = following,
            language = language,
            compact = true,
            modifier = Modifier.padding(top = 2.dp),
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
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .homeCard()
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(
            modifier = Modifier.weight(1f).pressable(onClick = { onOpenCreator(author) }),
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
                        lineHeight = 16.sp,
                        color = DS.inkSecondary,
                        maxLines = 3,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
                Text(
                    text = (LocalCounters.followers(author.slug) + (if (following) 1 else 0)).compactCount(language) + " " +
                        StringStore.text(context, "creator.stat.followers", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 12.sp,
                    color = DS.ink,
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
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .pressable(onClick = onTap)
            .homeCard()
            .padding(12.dp),
        verticalAlignment = Alignment.Top,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Icon(
            imageVector = Icons.AutoMirrored.Filled.MenuBook,
            contentDescription = null,
            tint = DS.accent,
            modifier = Modifier.size(22.dp),
        )
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
                fontSize = 13.sp,
                lineHeight = 18.sp,
                color = DS.inkSecondary,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
            )
            if (course != null) {
                Text(
                    text = stripInlineMarkup(course.title),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 12.sp,
                    color = DS.accent,
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
            .padding(start = SIDE_MARGIN, end = SIDE_MARGIN, top = 12.dp, bottom = 32.dp),
        verticalArrangement = Arrangement.spacedBy(9.dp),
    ) {
        NewGenBackHeader(
            language = language,
            onBack = onBack,
            title = "$subcategory · ${courses.size}",
            modifier = Modifier.padding(bottom = 8.dp),
        )
        courses.forEachIndexed { index, course ->
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
                // Les premières lignes entrent en cascade ; au-delà, elles sont hors écran.
                modifier = if (index < 10) Modifier.dsStagger(index) else Modifier,
            )
        }
        Spacer(Modifier.height(4.dp))
    }
}
