package app.rork.sophia.ui.onboarding

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
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
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.course.AuthorAvatar
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
 * « Suivre » / « Abonné ». Toute la ligne est le bouton.
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
                    val following = author.slug in progress.followedCreatorSlugs
                    FollowCreatorRow(
                        author = author,
                        language = language,
                        following = following,
                        modifier = Modifier.dsStagger(index, stepMillis = 50, baseMillis = 140),
                        onToggle = {
                            haptics.select()
                            progressManager.toggleFollow(author.slug)
                            Analytics.log(
                                if (following) "unfollow" else "follow",
                                screen = "onboarding",
                                props = mapOf("creator" to author.slug),
                            )
                        },
                    )
                }
            }
        }
        Spacer(Modifier.height(28.dp))
    }
}

@Composable
private fun FollowCreatorRow(
    author: CourseAuthor,
    language: AppLanguage,
    following: Boolean,
    onToggle: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            // `toggleFollow` est déjà accompagné de sa vibration : pas celle de la pression.
            .pressable(onClick = onToggle, haptic = false)
            .semantics(mergeDescendants = true) {
                role = Role.Button
                selected = following
            }
            .ov2EndCard()
            .padding(horizontal = 12.dp, vertical = 9.dp),
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
        FollowPill(following = following, language = language)
    }
}

/** Pastille de suivi : pleine et bleue une fois abonné, cerclée de bleu sinon. */
@Composable
private fun FollowPill(following: Boolean, language: AppLanguage) {
    val context = LocalContext.current
    val fill by animateColorAsState(if (following) DS.accent else DS.surface, DSMotion.snappy(), label = "followFill")
    val foreground by animateColorAsState(if (following) Color.White else DS.accent, DSMotion.snappy(), label = "followText")
    val pop by animateFloatAsState(if (following) 1f else 0f, DSMotion.pop(), label = "followPop")
    Box(
        modifier = Modifier
            .graphicsLayer {
                // Un léger rebond quand la pastille se remplit.
                val scale = 1f + 0.06f * kotlin.math.sin(pop.coerceIn(0f, 1f) * kotlin.math.PI.toFloat())
                scaleX = scale
                scaleY = scale
            }
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
