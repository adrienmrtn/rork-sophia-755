package app.rork.sophia.ui.course

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.analytics.Analytics
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Course
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.components.AnimatedRewardBadge
import app.rork.sophia.ui.components.RewardBadgeKind
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.newgen.CreatorIdentity
import app.rork.sophia.ui.newgen.LikeHeartIcon
import app.rork.sophia.ui.newgen.LikedTint
import app.rork.sophia.ui.onboarding.readableWidth
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography

/**
 * End-of-course celebration, mirroring the iOS `CourseCompletedView`: cover, title,
 * the XP just earned, then close / quiz.
 */
@Composable
fun CourseCompletedScreen(
    course: Course,
    language: AppLanguage,
    earnedXP: Int,
    level: Int,
    xpIntoLevel: Int,
    xpForLevel: Int,
    showQuizCta: Boolean,
    quizLocked: Boolean,
    freemiumNote: String? = null,
    /** Quand ils sont fournis, la rangée « Aimer ce cours · Suivre le créateur » apparaît sous la carte XP. */
    progress: UserProgress? = null,
    progressManager: ProgressManager? = null,
    onClose: () -> Unit,
    onQuiz: () -> Unit,
) {
    val context = LocalContext.current
    var appeared by remember(course.id) { mutableStateOf(false) }
    val scale by animateFloatAsState(
        targetValue = if (appeared) 1f else 0.7f,
        animationSpec = spring(dampingRatio = 0.6f),
        label = "coverScale",
    )
    LaunchedEffect(course.id) { appeared = true }

    Column(
        modifier = Modifier.fillMaxSize().background(DS.canvas),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        // Cover, XP ring and freemium note together overflow a short phone at a large font
        // scale, and the weighted spacers then collapsed to nothing and pushed the buttons
        // off the bottom — leaving the reader with no way out of the course.
        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .readableWidth()
                .verticalScroll(rememberScrollState())
                .padding(DS.Space.l),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
        Box(
            modifier = Modifier
                .size(168.dp)
                .scale(scale)
                .clip(DS.cardShape),
        ) {
            CourseImage(
                courseId = course.id,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop,
                maxEdgePx = 480,
            )
        }
        Spacer(Modifier.height(22.dp))
        Text(
            text = StringStore.text(context, "course.completed", language),
            style = SophiaTypography.displayLarge,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(20.dp))
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(DS.cardShape)
                .background(DS.surface)
                .padding(DS.Space.m),
        ) {
            Text(text = course.title, style = SophiaTypography.titleMedium, maxLines = 2)
            Spacer(Modifier.height(10.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    // The translated subject, as iOS shows it; the enum name printed « Litterature »
                    // and « Comprendre_le_monde » in every language.
                    text = StringStore.text(context, "subject.${course.subjectEnum.storageKey}.short", language),
                    style = SophiaTypography.labelMedium,
                    modifier = Modifier.weight(1f),
                )
                AnimatedRewardBadge(
                    kind = RewardBadgeKind.Xp,
                    size = 16.dp,
                    showGlow = false,
                    modifier = Modifier.size(20.dp),
                )
                Spacer(Modifier.width(4.dp))
                Text(
                    text = "+$earnedXP XP",
                    style = SophiaTypography.titleMedium,
                    color = DS.accentSoft,
                )
            }
            Spacer(Modifier.height(10.dp))
            LinearProgressIndicator(
                progress = {
                    if (xpForLevel <= 0) 1f else (xpIntoLevel.toFloat() / xpForLevel).coerceIn(0f, 1f)
                },
                modifier = Modifier.fillMaxWidth().clip(DS.controlShape),
                color = DS.accent,
                trackColor = DS.hairline,
                strokeCap = StrokeCap.Round,
            )
            Spacer(Modifier.height(6.dp))
            Text(
                text = StringStore.text(context, "common.levelShort", language, level) +
                    " · $xpIntoLevel / $xpForLevel XP",
                style = SophiaTypography.labelMedium,
            )
        }
        if (progress != null && progressManager != null) {
            Spacer(Modifier.height(12.dp))
            CourseEndSocialRow(course = course, language = language, progress = progress, progressManager = progressManager)
        }
        if (freemiumNote != null) {
            Spacer(Modifier.height(14.dp))
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(DS.controlShape)
                    .background(DS.accentTint)
                    .padding(14.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Text("🔒", fontSize = 15.sp)
                Text(text = freemiumNote, style = SophiaTypography.labelMedium)
            }
        }
        }
        Row(
            modifier = Modifier.fillMaxWidth().readableWidth().padding(DS.Space.l),
            horizontalArrangement = Arrangement.spacedBy(14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(
                onClick = onClose,
                modifier = Modifier.size(56.dp).clip(CircleShape).background(DS.surface),
            ) {
                Icon(Icons.Filled.Close, contentDescription = null, tint = DS.inkSecondary)
            }
            if (showQuizCta) {
                Button(
                    onClick = onQuiz,
                    modifier = Modifier.weight(1f).height(56.dp),
                    shape = DS.controlShape,
                    colors = ButtonDefaults.buttonColors(containerColor = DS.accent, contentColor = Color.White),
                ) {
                    Text(
                        text = if (quizLocked) {
                            "🔒 " + StringStore.text(context, "common.miniQuiz", language)
                        } else {
                            StringStore.text(context, "common.miniQuiz", language)
                        },
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 16.sp,
                    )
                }
            } else {
                Button(
                    onClick = onClose,
                    modifier = Modifier.weight(1f).height(56.dp),
                    shape = DS.controlShape,
                    colors = ButtonDefaults.buttonColors(containerColor = DS.accent, contentColor = Color.White),
                ) {
                    Text(
                        text = StringStore.text(context, "course.finish", language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 16.sp,
                    )
                }
            }
        }
    }
}

/**
 * Deux gestes à chaud, juste après la lecture : le cœur sur le cours, et l'abonnement au
 * créateur. Rapportés avec l'écran `course_end`, comme sur iOS.
 */
@Composable
private fun CourseEndSocialRow(
    course: Course,
    language: AppLanguage,
    progress: UserProgress,
    progressManager: ProgressManager,
) {
    val context = LocalContext.current
    val author = remember(course.id) { CreatorIdentity.forCourse(context.applicationContext, course.id).author }
    val liked = course.id in progress.likedCourseIds
    var likeBurst by remember(course.id) { mutableIntStateOf(0) }
    val shape = RoundedCornerShape(14.dp)

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(
            modifier = Modifier
                .weight(1f)
                .height(48.dp)
                .softPress(onClick = {
                    val wasLiked = progressManager.isLiked(course.id)
                    progressManager.toggleLike(course.id)
                    if (!wasLiked) likeBurst++
                    Analytics.log(if (wasLiked) "unlike" else "like", courseId = course.id, screen = "course_end")
                })
                .clip(shape)
                .background(if (liked) LikedTint.copy(alpha = 0.1f) else DS.surface)
                .border(1.dp, if (liked) LikedTint.copy(alpha = 0.45f) else DS.hairline, shape)
                .padding(horizontal = 14.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            LikeHeartIcon(liked = liked, burst = likeBurst, size = 16.dp, idleTint = DS.ink)
            Text(
                text = StringStore.text(context, if (liked) "course.end.liked" else "course.end.like", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 15.sp,
                color = if (liked) LikedTint else DS.ink,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }

        if (author != null) {
            val following = author.slug in progress.followedCreatorSlugs
            val firstName = author.name.split(" ").firstOrNull()?.takeIf { it.isNotBlank() } ?: author.name
            Row(
                modifier = Modifier
                    .weight(1f)
                    .height(48.dp)
                    .softPress(onClick = {
                        val wasFollowing = progressManager.isFollowing(author.slug)
                        progressManager.toggleFollow(author.slug)
                        Analytics.log(if (wasFollowing) "unfollow" else "follow", courseId = course.id, screen = "course_end", props = mapOf("creator" to author.slug))
                    })
                    .clip(shape)
                    .background(if (following) DS.surface else DS.accent)
                    .then(if (following) Modifier.border(1.dp, DS.hairline, shape) else Modifier)
                    .padding(horizontal = 14.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                AuthorAvatar(author = author, size = 24.dp)
                Text(
                    text = if (following) {
                        StringStore.text(context, "creator.following", language)
                    } else {
                        StringStore.text(context, "course.end.follow", language, firstName)
                    },
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp,
                    color = if (following) DS.ink else Color.White,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
    }
}
