package app.rork.sophia.ui.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
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
import app.rork.sophia.ui.course.AuthorAvatar
import app.rork.sophia.ui.newgen.FollowButton
import app.rork.sophia.ui.newgen.VerifiedCheck
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
 */
@Composable
internal fun FollowCreatorsStep(
    language: AppLanguage,
    chosenSubjects: Set<String>,
    progressManager: ProgressManager,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
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
        footer = { OnboardingCta(StringStore.text(context, "common.continue", language), onContinue) },
    ) {
        Spacer(Modifier.height(72.dp))
        Text(
            text = StringStore.text(context, "onboardingV2.follow.title", language),
            style = OV2.title,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp).ov2Reveal(50),
        )
        Spacer(Modifier.height(10.dp))
        Text(
            text = StringStore.text(context, "onboardingV2.follow.subtitle", language),
            style = OV2.body,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp).ov2Reveal(50),
        )
        Spacer(Modifier.height(22.dp))
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp).ov2Reveal(140),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            authors.forEach { author ->
                val following = author.slug in progress.followedCreatorSlugs
                val shape = RoundedCornerShape(18.dp)
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(shape)
                        .background(OV2.surface)
                        .border(if (following) 1.5.dp else 1.dp, if (following) OV2.accent else OV2.hairline, shape)
                        .padding(12.dp),
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
                                color = OV2.ink,
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
                                color = OV2.inkSecondary,
                                maxLines = 2,
                                overflow = TextOverflow.Ellipsis,
                            )
                        }
                    }
                    FollowButton(
                        isFollowing = following,
                        language = language,
                        compact = true,
                        onClick = {
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
        Spacer(Modifier.height(20.dp))
    }
}
