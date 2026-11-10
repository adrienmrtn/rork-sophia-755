package app.rork.sophia.ui.newgen

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Autorenew
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Explore
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Route
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.snapshots.SnapshotStateList
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.data.AuthorStore
import app.rork.sophia.data.CampaignStore
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.rememberCourseSummaries
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.PathLevel
import app.rork.sophia.domain.Subject
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.audio.AudioMiniPlayer
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.duels.DUELS_TAB_INDEX
import app.rork.sophia.ui.duels.DuelsTabHost
import app.rork.sophia.ui.path.LearningPathScreen
import app.rork.sophia.ui.profile.ProfileScreen
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.training.TrainingScreen
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Le nombre d'index d'onglet (0 à 5), donc de piles d'écrans tenues par `MainTabs` : Accueil,
 * Explorer, Parcours, Entraînement, Profil (4) et Duels ([DUELS_TAB_INDEX] = 5, affiché avant
 * le Profil quand l'app est en anglais ; sa pile existe mais reste vide, il ne pousse rien).
 */
const val NEWGEN_TAB_COUNT = 6

/** L'index de l'onglet Profil, le dernier de la barre. */
private const val PROFILE_TAB_INDEX = 4

/**
 * Les écrans qu'un onglet peut pousser. Les cours sont désignés par leur id, comme sur iOS :
 * un id suffit à les retrouver dans le catalogue de la langue.
 */
sealed class NewGenRoute {
    /** La fiche d'un cours, avec l'origine rapportée (`course_open`) quand le lecteur s'ouvrira. */
    data class CourseDetail(val courseId: String, val source: String) : NewGenRoute()
    data class Creator(val slug: String) : NewGenRoute()
    data class Event(val slug: String) : NewGenRoute()
    data class CourseList(val kind: ProfileListKind) : NewGenRoute()
    data class SubjectCourses(val subject: Subject) : NewGenRoute()
    /** Un « univers » de l'onglet Explorer : une sous-catégorie du catalogue, dans la langue courante. */
    data class Universe(val subcategory: String) : NewGenRoute()

    /** L'ancien profil (rang, matières, quiz, amis), désormais page secondaire. */
    data object Progression : NewGenRoute()
    data object Path : NewGenRoute()
    data object Training : NewGenRoute()
}

/**
 * Widest the tab content is allowed to get: Sophia's screens are a single column; past this
 * they stop reading like the design (même borne que `MainTabs`).
 */
private val TABLET_CONTENT_WIDTH = 640.dp

/**
 * La navigation « nouvelle génération » : la barre de 5 onglets (Accueil, Explorer, Parcours,
 * Entraînement, Profil ; Parcours et Entraînement sont les écrans classiques, gardés pour ne pas
 * perdre les anciens lecteurs), 6 avec Duels entre Entraînement et Profil quand [showsDuels]
 * (l'app est en anglais), l'écran racine de l'onglet,
 * et par-dessus l'écran poussé en tête de sa pile ([routeStacks], une par onglet, tenue par
 * `MainTabs` qui gère aussi le retour système). Le lecteur, les paywalls et les overlays
 * restent présentés par `MainTabs` au-dessus de tout ; [onOpenCourse] est la seule porte vers
 * le lecteur, avec la source de l'événement `course_open`.
 */
@Composable
fun NewGenTabs(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    progress: UserProgress,
    progressManager: ProgressManager,
    isPremium: Boolean,
    selectedTab: Int,
    onSelectTab: (Int) -> Unit,
    routeStacks: List<SnapshotStateList<NewGenRoute>>,
    /**
     * Un écran est dessiné par-dessus les onglets : le Parcours ne rejoue ses changements
     * qu'une fois découvert, et l'onglet Duels ne se recharge pas tant qu'il est recouvert.
     */
    pathCovered: Boolean,
    /** L'onglet Duels est affiché (décidé une fois par `MainTabs`, à la première composition). */
    showsDuels: Boolean,
    /** Une partie de duel est à l'écran par-dessus les onglets (présentée par `MainTabs`). */
    duelFlowShown: Boolean,
    onPlayDuel: () -> Unit,
    onOpenCourse: (CourseSummary, String) -> Unit,
    onOpenCourseById: (String, String) -> Unit,
    onOpenSettings: () -> Unit,
    onOpenFriends: () -> Unit,
    onShowPaywall: () -> Unit,
    onOpenPathQuiz: (PathLevel, Boolean) -> Unit,
    onOpenAudioPlayer: () -> Unit,
    onBecomeCreator: () -> Unit,
) {
    val context = LocalContext.current
    // Les nouveaux écrans lisent auteurs et événements de manière synchrone : chauffés ici,
    // hors du fil principal, avant qu'une carte ne les demande.
    LaunchedEffect(language) {
        withContext(Dispatchers.IO) {
            AuthorStore.preload(context.applicationContext)
            ContentCatalog.summaries(context.applicationContext, language)
        }
    }

    val tabs = remember(showsDuels) {
        buildList {
            add(Triple("tab.home", Icons.Filled.Home, 0))
            add(Triple("tab.explore", Icons.Filled.Explore, 1))
            add(Triple("tab.path", Icons.Filled.Route, 2))
            add(Triple("tab.training", Icons.Filled.Autorenew, 3))
            // Dessiné avant le Profil mais avec son propre index (5, comme sur iOS) : les
            // onglets existants gardent leurs numéros.
            if (showsDuels) add(Triple("tab.duels", Icons.Filled.EmojiEvents, DUELS_TAB_INDEX))
            add(Triple("tab.profile", Icons.Filled.Person, PROFILE_TAB_INDEX))
        }
    }
    // Six onglets sur un téléphone de 360 dp : environ 53 dp par libellé. En 10 sp (la taille
    // de la barre à six onglets d'iOS) « Practice » tient sans être coupé.
    val tabLabelSize = if (tabs.size > 5) 10.sp else 11.sp
    // Un index inconnu, ou celui des Duels quand l'onglet n'est pas affiché, retombe sur le Profil.
    val tabIndex = selectedTab.coerceIn(0, NEWGEN_TAB_COUNT - 1)
        .let { if (it == DUELS_TAB_INDEX && !showsDuels) PROFILE_TAB_INDEX else it }
    val stack = routeStacks[tabIndex]
    fun push(route: NewGenRoute) {
        stack.add(route)
    }
    fun pop() {
        if (stack.isNotEmpty()) stack.removeAt(stack.lastIndex)
    }

    Scaffold(
        containerColor = DS.canvas,
        bottomBar = {
            // Le mini-lecteur audio juste au-dessus de la barre d'onglets, comme en classique.
            Column {
                AudioMiniPlayer(language = language, onOpen = onOpenAudioPlayer)
                NavigationBar(containerColor = DS.canvas, contentColor = DS.accent) {
                    tabs.forEach { (key, icon, index) ->
                        NavigationBarItem(
                            selected = tabIndex == index,
                            onClick = { onSelectTab(index) },
                            icon = { Icon(icon, contentDescription = null) },
                            label = {
                                Text(
                                    text = StringStore.text(context, key, language),
                                    fontFamily = PlusJakartaSans,
                                    fontSize = tabLabelSize,
                                    fontWeight = if (tabIndex == index) FontWeight.SemiBold else FontWeight.Normal,
                                    maxLines = 1,
                                    softWrap = false,
                                    overflow = TextOverflow.Ellipsis,
                                )
                            },
                            colors = NavigationBarItemDefaults.colors(
                                selectedIconColor = DS.accent,
                                selectedTextColor = DS.accent,
                                unselectedIconColor = DS.inkTertiary,
                                unselectedTextColor = DS.inkTertiary,
                                indicatorColor = DS.accentTint,
                            ),
                        )
                    }
                }
            }
        },
    ) { padding ->
        Box(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentAlignment = Alignment.TopCenter,
        ) {
            val tabModifier = Modifier.widthIn(max = TABLET_CONTENT_WIDTH)
            when (tabIndex) {
                0 -> HomeFeedScreen(
                    modifier = tabModifier,
                    language = language,
                    progress = progress,
                    progressManager = progressManager,
                    isPremium = isPremium,
                    onOpenCourse = { push(NewGenRoute.CourseDetail(it.id, "feed")) },
                    onOpenCreator = { push(NewGenRoute.Creator(it.slug)) },
                    onOpenCampaign = { push(NewGenRoute.Event(it.slug)) },
                    onSearch = { onSelectTab(1) },
                    onBecomeCreator = onBecomeCreator,
                )
                1 -> ExploreScreen(
                    modifier = tabModifier,
                    language = language,
                    progress = progress,
                    progressManager = progressManager,
                    onOpenCourse = { push(NewGenRoute.CourseDetail(it.id, "search")) },
                    onOpenCreator = { push(NewGenRoute.Creator(it.slug)) },
                    onOpenCampaign = { push(NewGenRoute.Event(it.slug)) },
                    onOpenUniverse = { push(NewGenRoute.Universe(it)) },
                )
                2 -> LearningPathScreen(
                    language = language,
                    progress = progress,
                    isCovered = pathCovered,
                    onOpenCourse = { onOpenCourseById(it, "path") },
                    onOpenQuiz = onOpenPathQuiz,
                    modifier = tabModifier,
                )
                3 -> TrainingScreen(
                    modifier = tabModifier,
                    language = language,
                    isPremium = isPremium,
                    progress = progress,
                    progressManager = progressManager,
                    storeViewModel = storeViewModel,
                    onPremiumUnlocked = { storeViewModel.refresh() },
                )
                // Dessiné plus bas, hors du `when`, pour rester monté quand on change d'onglet.
                DUELS_TAB_INDEX -> Unit
                else -> ProfileV2Screen(
                    modifier = tabModifier,
                    language = language,
                    progress = progress,
                    progressManager = progressManager,
                    onOpenCourse = { push(NewGenRoute.CourseDetail(it.id, "profile")) },
                    onResumeCourse = { onOpenCourse(it, "profile") },
                    onOpenCreator = { push(NewGenRoute.Creator(it.slug)) },
                    onOpenList = { push(NewGenRoute.CourseList(it)) },
                    onOpenCampaign = { push(NewGenRoute.Event(it.slug)) },
                    onOpenProgression = { push(NewGenRoute.Progression) },
                    onOpenFriends = onOpenFriends,
                    onDiscoverCreators = { onSelectTab(1) },
                    onBecomeCreator = onBecomeCreator,
                    onOpenSettings = onOpenSettings,
                )
            }

            if (showsDuels) {
                DuelsTabHost(
                    language = language,
                    selected = tabIndex == DUELS_TAB_INDEX,
                    // Un paywall ou le lecteur audio par-dessus : l'onglet n'est plus à l'écran.
                    covered = pathCovered,
                    flowShown = duelFlowShown,
                    onPlay = onPlayDuel,
                    modifier = tabModifier,
                )
            }

            // L'écran en tête de pile, opaque, au-dessus de la racine qui garde ainsi son état
            // (deck du fil, position de défilement) pour le retour.
            stack.lastOrNull()?.let { route ->
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(DS.canvas)
                        .softPress(onClick = {}),
                    contentAlignment = Alignment.TopCenter,
                ) {
                    RouteScreen(
                        route = route,
                        language = language,
                        storeViewModel = storeViewModel,
                        progress = progress,
                        progressManager = progressManager,
                        isPremium = isPremium,
                        pathCovered = pathCovered,
                        onBack = { pop() },
                        push = { push(it) },
                        onOpenCourse = onOpenCourse,
                        onOpenCourseById = onOpenCourseById,
                        onOpenSettings = onOpenSettings,
                        onOpenFriends = onOpenFriends,
                        onShowPaywall = onShowPaywall,
                        onOpenPathQuiz = onOpenPathQuiz,
                        onBecomeCreator = onBecomeCreator,
                        modifier = tabModifier,
                    )
                }
            }
        }
    }
}

@Composable
private fun RouteScreen(
    route: NewGenRoute,
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    progress: UserProgress,
    progressManager: ProgressManager,
    isPremium: Boolean,
    pathCovered: Boolean,
    onBack: () -> Unit,
    push: (NewGenRoute) -> Unit,
    onOpenCourse: (CourseSummary, String) -> Unit,
    onOpenCourseById: (String, String) -> Unit,
    onOpenSettings: () -> Unit,
    onOpenFriends: () -> Unit,
    onShowPaywall: () -> Unit,
    onOpenPathQuiz: (PathLevel, Boolean) -> Unit,
    onBecomeCreator: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    when (route) {
        is NewGenRoute.CourseDetail -> {
            val summaries = rememberCourseSummaries(language)
            val course = remember(summaries, route.courseId) { summaries.firstOrNull { it.id == route.courseId } }
            if (course == null) {
                MissingRoute(language = language, onBack = onBack, modifier = modifier)
            } else {
                CourseDetailScreen(
                    course = course,
                    language = language,
                    progress = progress,
                    progressManager = progressManager,
                    onBack = onBack,
                    onStart = { onOpenCourse(course, route.source) },
                    onOpenCreator = { push(NewGenRoute.Creator(it.slug)) },
                    onOpenCourse = { push(NewGenRoute.CourseDetail(it.id, "author")) },
                    modifier = modifier,
                )
            }
        }
        is NewGenRoute.Creator -> {
            val author = remember(route.slug) { AuthorStore.author(context.applicationContext, route.slug) }
            if (author == null) {
                MissingRoute(language = language, onBack = onBack, modifier = modifier)
            } else {
                CreatorPageScreen(
                    author = author,
                    language = language,
                    progress = progress,
                    progressManager = progressManager,
                    onBack = onBack,
                    onOpenCourse = { push(NewGenRoute.CourseDetail(it.id, "author")) },
                    onOpenCampaign = { push(NewGenRoute.Event(it.slug)) },
                    modifier = modifier,
                )
            }
        }
        is NewGenRoute.Event -> {
            val campaigns by CampaignStore.flow.collectAsState()
            val campaign = remember(route.slug, campaigns) { CampaignStore.campaign(route.slug) }
            if (campaign == null) {
                MissingRoute(language = language, onBack = onBack, modifier = modifier)
            } else {
                EventPageScreen(
                    campaign = campaign,
                    language = language,
                    progress = progress,
                    onBack = onBack,
                    onOpenCourse = { push(NewGenRoute.CourseDetail(it.id, "event")) },
                    onOpenCreator = { push(NewGenRoute.Creator(it.slug)) },
                    onBecomeCreator = onBecomeCreator,
                    modifier = modifier,
                )
            }
        }
        is NewGenRoute.CourseList -> ProfileCourseListScreen(
            kind = route.kind,
            language = language,
            progress = progress,
            onBack = onBack,
            onOpenCourse = { push(NewGenRoute.CourseDetail(it.id, "profile")) },
            modifier = modifier,
        )
        is NewGenRoute.Universe -> UniverseCoursesScreen(
            subcategory = route.subcategory,
            language = language,
            progress = progress,
            onBack = onBack,
            onOpenCourse = { push(NewGenRoute.CourseDetail(it.id, "search")) },
            modifier = modifier,
        )
        is NewGenRoute.SubjectCourses -> SubjectCoursesScreen(
            subject = route.subject,
            language = language,
            progress = progress,
            onBack = onBack,
            onOpenCourse = { push(NewGenRoute.CourseDetail(it.id, "search")) },
            modifier = modifier,
        )
        // Les trois pages ci-dessous étaient des racines d'onglet : elles n'ont pas de bouton
        // retour à elles, un en-tête le leur donne (barre système sur iOS).
        NewGenRoute.Progression -> Column(modifier = modifier.fillMaxSize()) {
            NewGenBackHeader(
                language = language,
                onBack = onBack,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp),
            )
            ProfileScreen(
                modifier = Modifier.weight(1f),
                language = language,
                progress = progress,
                isPremium = isPremium,
                onOpenCourse = { onOpenCourseById(it, "profile") },
                onOpenSettings = onOpenSettings,
                onShowPaywall = onShowPaywall,
                onOpenFriends = { onOpenFriends() },
            )
        }
        NewGenRoute.Path -> Column(modifier = modifier.fillMaxSize()) {
            NewGenBackHeader(
                language = language,
                onBack = onBack,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp),
            )
            LearningPathScreen(
                language = language,
                progress = progress,
                isCovered = pathCovered,
                onOpenCourse = { onOpenCourseById(it, "path") },
                onOpenQuiz = onOpenPathQuiz,
                modifier = Modifier.weight(1f),
            )
        }
        NewGenRoute.Training -> Column(modifier = modifier.fillMaxSize()) {
            NewGenBackHeader(
                language = language,
                onBack = onBack,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp),
            )
            TrainingScreen(
                modifier = Modifier.weight(1f),
                language = language,
                isPremium = isPremium,
                progress = progress,
                progressManager = progressManager,
                storeViewModel = storeViewModel,
                onPremiumUnlocked = { storeViewModel.refresh() },
            )
        }
    }
}

/** Un id que le catalogue de la langue ne connaît pas (contenu en avance sur l'app) : rien à montrer. */
@Composable
private fun MissingRoute(language: AppLanguage, onBack: () -> Unit, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    Column(modifier = modifier.fillMaxSize().padding(20.dp)) {
        NewGenBackHeader(language = language, onBack = onBack)
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text(
                text = StringStore.text(context, "library.empty.title", language),
                fontFamily = PlusJakartaSans,
                fontSize = 17.sp,
                color = DS.inkSecondary,
                textAlign = TextAlign.Center,
            )
        }
    }
}
