package app.rork.sophia.ui.onboarding

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.AuthorStore
import app.rork.sophia.data.CourseAuthor
import app.rork.sophia.data.LocalCounters
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.analytics.Analytics
import app.rork.sophia.data.rememberCourseSummaries
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.components.DSEyebrow
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.course.AuthorAvatar
import app.rork.sophia.ui.newgen.FollowButton
import app.rork.sophia.ui.newgen.VerifiedCheck
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans

/** Au-delà, la page devient une liste à faire défiler plus qu'un choix. */
private const val MAX_AUTHORS = 12

/**
 * Les créateurs proposés par « Suis des profs » : d'abord ceux qui écrivent dans les matières
 * choisies, puis les plus suivis ; le slug départage. Comme `suggestedAuthors` sur iOS.
 */
internal fun suggestedAuthors(
    authors: List<CourseAuthor>,
    subjectByCourseId: Map<String, String>,
    chosenSubjects: Set<String>,
    followers: (String) -> Int = LocalCounters::followers,
    limit: Int = MAX_AUTHORS,
): List<CourseAuthor> =
    authors
        .filter { it.courseIds.isNotEmpty() }
        .map { author ->
            Triple(author, author.courseIds.any { subjectByCourseId[it] in chosenSubjects }, followers(author.slug))
        }
        .sortedWith(
            compareByDescending<Triple<CourseAuthor, Boolean, Int>> { it.second }
                .thenByDescending { it.third }
                .thenBy { it.first.slug },
        )
        .take(limit)
        .map { it.first }

/**
 * Page « Suis des profs » : une douzaine de créateurs à suivre d'un geste, pour que l'onglet
 * Abonnements de l'accueil ne soit pas vide au premier lancement. Rien n'est obligatoire :
 * « Continuer » marche sans avoir suivi personne.
 *
 * Une carte par prof : portrait, nom, titre ou spécialité (ceux du catalogue), et la pastille
 * « Suivre » / « Abonné ». Toucher le prof ouvre sa fiche ([CreatorPopup]) : portrait, nom,
 * présentation et ses cours ; la pastille, elle, suit ou ne suit plus sans quitter la liste.
 */
@Composable
internal fun FollowCreatorsStep(
    language: AppLanguage,
    chosenSubjects: Set<String>,
    progressManager: ProgressManager,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val progress by progressManager.progress.collectAsState()
    val summaries = rememberCourseSummaries(language)
    // La liste est figée à l'arrivée : suivre quelqu'un ne la réordonne pas sous le doigt.
    val authors = remember(summaries.isEmpty()) {
        suggestedAuthors(
            authors = AuthorStore.all(context.applicationContext),
            subjectByCourseId = summaries.associate { it.id to it.subject },
            chosenSubjects = chosenSubjects,
        )
    }
    // Le prof dont la fiche est ouverte (son slug : il survit à une rotation) ; null sinon.
    var openSlug by rememberSaveable { mutableStateOf<String?>(null) }

    // Suivre ou ne plus suivre, depuis la liste comme depuis la fiche.
    fun toggleFollow(author: CourseAuthor) {
        val wasFollowing = progressManager.isFollowing(author.slug)
        progressManager.toggleFollow(author.slug)
        Analytics.log(
            if (wasFollowing) "unfollow" else "follow",
            screen = "onboarding",
            props = mapOf("creator" to author.slug),
        )
    }

    OnboardingPage(
        contentArrangement = Arrangement.Top,
        footer = {
            Box {
                // La liste s'efface sous le bouton au lieu d'être coupée net.
                OV2EndBottomFade(modifier = Modifier.align(Alignment.TopCenter))
                OnboardingCta(StringStore.text(context, "common.continue", language), onContinue)
            }
        },
    ) {
        Spacer(Modifier.height(OV2End.topWithoutHeader))
        OV2EndTitle(
            text = StringStore.text(context, "onboardingV2.follow.title", language),
            modifier = Modifier.padding(horizontal = OV2End.side).dsStagger(0),
        )
        Spacer(Modifier.height(10.dp))
        OV2EndSubtitle(
            text = StringStore.text(context, "onboardingV2.follow.subtitle", language),
            modifier = Modifier.padding(horizontal = OV2End.side).dsStagger(1),
        )
        Spacer(Modifier.height(18.dp))
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = OV2End.side),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            authors.forEachIndexed { index, author ->
                key(author.slug) {
                    FollowCreatorRow(
                        author = author,
                        language = language,
                        following = author.slug in progress.followedCreatorSlugs,
                        modifier = Modifier.dsStagger(index, stepMillis = 50, baseMillis = 140),
                        onOpen = { openSlug = author.slug },
                        onToggle = {
                            haptics.select()
                            toggleFollow(author)
                        },
                    )
                }
            }
        }
        Spacer(Modifier.height(28.dp))
    }

    val opened = openSlug?.let { slug -> authors.firstOrNull { it.slug == slug } }
    if (opened != null) {
        CreatorPopup(
            author = opened,
            language = language,
            // Ses cours, dans l'ordre du catalogue, comme sur la page du créateur.
            courses = remember(summaries, opened.slug) {
                opened.courseIds.mapNotNull { id -> summaries.firstOrNull { it.id == id } }
            },
            following = opened.slug in progress.followedCreatorSlugs,
            onToggle = { toggleFollow(opened) },
            onDismiss = { openSlug = null },
        )
    }
}

@Composable
private fun FollowCreatorRow(
    author: CourseAuthor,
    language: AppLanguage,
    following: Boolean,
    onOpen: () -> Unit,
    onToggle: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .ov2EndCard()
            .padding(start = 12.dp, end = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        // Le prof : portrait, nom et titre. Le toucher ouvre sa fiche.
        Row(
            modifier = Modifier
                .weight(1f)
                .pressable(onClick = onOpen)
                .semantics(mergeDescendants = true) { role = Role.Button }
                .padding(vertical = 9.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(11.dp),
        ) {
            AuthorAvatar(author = author, size = 46.dp)
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
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
        }
        // La pastille : un bouton à part, avec une cible d'au moins 48 dp de haut.
        Box(
            modifier = Modifier
                .heightIn(min = 48.dp)
                // `toggleFollow` est déjà accompagné de sa vibration : pas celle de la pression.
                .pressable(onClick = onToggle, haptic = false)
                .semantics(mergeDescendants = true) {
                    role = Role.Button
                    selected = following
                },
            contentAlignment = Alignment.Center,
        ) {
            FollowPill(following = following, language = language)
        }
    }
}

/** Pastille de suivi : pleine et bleue une fois abonné, cerclée de bleu sinon. Sans rebond. */
@Composable
private fun FollowPill(following: Boolean, language: AppLanguage) {
    val context = LocalContext.current
    val fill by animateColorAsState(if (following) DS.accent else DS.surface, OnboardingMotion.quick(), label = "followFill")
    val foreground by animateColorAsState(if (following) Color.White else DS.accent, OnboardingMotion.quick(), label = "followText")
    Box(
        modifier = Modifier
            .height(34.dp)
            .background(fill, CircleShape)
            .border(1.5.dp, DS.accent, CircleShape)
            .padding(horizontal = 13.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = StringStore.text(context, if (following) "creator.following" else "creator.follow", language),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 13.sp,
            color = foreground,
            maxLines = 1,
        )
    }
}

// MARK: - Fiche d'un prof

/** Au-delà, la rangée de cours de la fiche devient un catalogue. */
private const val POPUP_MAX_COURSES = 12

/** Côté d'une couverture dans la rangée de cours de la fiche. */
private val POPUP_COVER_SIZE = 116.dp

/**
 * La fiche d'un prof, dans une feuille qui monte du bas de l'écran : son portrait, son nom (et le badge
 * vérifié), son titre, sa présentation, puis ses cours — couverture et titre — dans une rangée
 * à faire défiler. Les textes viennent du catalogue, comme sur la page du créateur
 * (`CourseAuthor.title` / `bio`, `courseIds`). On peut y suivre le prof ; la croix, un glissement
 * vers le bas, un toucher hors de la feuille ou le retour la referment.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CreatorPopup(
    author: CourseAuthor,
    language: AppLanguage,
    courses: List<CourseSummary>,
    following: Boolean,
    onToggle: () -> Unit,
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        // Ouverte en entier : la présentation et le bouton « Suivre » sont visibles d'emblée.
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = DS.canvas,
        shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
    ) {
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            // La croix, en haut à la fin.
            Row(
                modifier = Modifier.fillMaxWidth().padding(top = 8.dp, end = 8.dp),
                horizontalArrangement = Arrangement.End,
            ) {
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .pressable(onClick = onDismiss)
                        .semantics { role = Role.Button },
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        imageVector = Icons.Filled.Close,
                        contentDescription = StringStore.text(context, "common.close", language),
                        tint = DS.inkSecondary,
                        modifier = Modifier.size(20.dp),
                    )
                }
            }
            // Le corps défile quand la présentation est longue ou l'écran court ; le bouton
            // « Suivre » reste épinglé dessous.
            Column(
                modifier = Modifier
                    .weight(1f, fill = false)
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                AuthorAvatar(author = author, size = 88.dp)
                Spacer(Modifier.height(12.dp))
                Row(
                    modifier = Modifier.padding(horizontal = 24.dp).semantics(mergeDescendants = true) { heading() },
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    Text(
                        text = author.name,
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 20.sp,
                        lineHeight = 26.sp,
                        color = DS.ink,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.weight(1f, fill = false),
                    )
                    if (author.isVerified) VerifiedCheck(language = language, size = 17.dp)
                }
                author.title(language)?.let { pedigree ->
                    Text(
                        text = pedigree,
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Medium,
                        fontSize = 13.sp,
                        lineHeight = 18.sp,
                        color = DS.inkSecondary,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 24.dp).padding(top = 4.dp),
                    )
                }
                author.bio(language)?.let { bio ->
                    Text(
                        text = bio,
                        fontFamily = PlusJakartaSans,
                        fontSize = 15.sp,
                        lineHeight = 22.sp,
                        color = DS.inkSecondary,
                        modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp).padding(top = 14.dp),
                    )
                }
                if (courses.isNotEmpty()) {
                    DSEyebrow(
                        text = StringStore.text(context, "author.courses.title", language),
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 24.dp)
                            .padding(top = 20.dp, bottom = 10.dp)
                            .semantics { heading() },
                    )
                    LazyRow(
                        modifier = Modifier.fillMaxWidth(),
                        contentPadding = PaddingValues(horizontal = 24.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        items(courses.take(POPUP_MAX_COURSES), key = { it.id }) { course ->
                            CreatorPopupCourse(course = course)
                        }
                    }
                }
                Spacer(Modifier.height(18.dp))
            }
            FollowButton(
                isFollowing = following,
                language = language,
                onClick = onToggle,
                modifier = Modifier.padding(start = 24.dp, end = 24.dp, bottom = 20.dp),
            )
        }
    }
}

/** Un cours du prof dans sa fiche : la couverture carrée, puis le titre sur trois lignes au plus. */
@Composable
private fun CreatorPopupCourse(course: CourseSummary) {
    Column(
        modifier = Modifier.width(POPUP_COVER_SIZE).semantics(mergeDescendants = true) { },
        verticalArrangement = Arrangement.spacedBy(7.dp),
    ) {
        CourseImage(
            courseId = course.id,
            modifier = Modifier.size(POPUP_COVER_SIZE).clip(RoundedCornerShape(14.dp)),
            contentScale = ContentScale.Crop,
            maxEdgePx = 360,
            letterSize = 30.sp,
        )
        Text(
            text = course.title,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 13.sp,
            lineHeight = 17.sp,
            color = DS.ink,
            maxLines = 3,
            overflow = TextOverflow.Ellipsis,
        )
    }
}
