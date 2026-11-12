package app.rork.sophia.ui.course

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
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
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Icon
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
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawOutline
import androidx.compose.ui.graphics.drawscope.translate
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
import app.rork.sophia.ui.components.CourseGoldPill
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.components.CoursePrimaryButton
import app.rork.sophia.ui.components.CourseRoundIconButton
import app.rork.sophia.ui.components.CourseSubjectAvatar
import app.rork.sophia.ui.components.CourseXPBar
import app.rork.sophia.ui.components.DSCheckBadge
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.dsPopIn
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.newgen.CreatorIdentity
import app.rork.sophia.ui.newgen.LikeHeartIcon
import app.rork.sophia.ui.newgen.LikedTint
import app.rork.sophia.ui.onboarding.readableWidth
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans

/**
 * End-of-course celebration, mirroring the iOS `CourseCompletedView`: the cover with a check
 * that draws itself, the title, the XP just earned on a golden bar that fills, then
 * close / quiz. The phone celebrates when the screen arrives.
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
    val haptics = rememberHaptics()
    var appeared by remember(course.id) { mutableStateOf(false) }
    val scale by animateFloatAsState(
        targetValue = if (appeared) 1f else 0.6f,
        animationSpec = DSMotion.pop(),
        label = "coverScale",
    )
    // The golden bar starts where the level stood before these XP, then fills up to now.
    val xpFraction = if (xpForLevel <= 0) 1f else (xpIntoLevel.toFloat() / xpForLevel).coerceIn(0f, 1f)
    val xpStart = if (xpForLevel <= 0) 1f else ((xpIntoLevel - earnedXP).toFloat() / xpForLevel).coerceIn(0f, xpFraction)
    val xpBar = remember(course.id) { Animatable(xpStart) }
    LaunchedEffect(course.id) {
        appeared = true
        // The cover lands, the check draws itself, the phone celebrates.
        haptics.celebrate()
        xpBar.animateTo(xpFraction, tween(durationMillis = 800, delayMillis = 900))
    }

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
                .padding(horizontal = 24.dp, vertical = 28.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(modifier = Modifier.size(152.dp).scale(scale)) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .clip(RoundedCornerShape(28.dp))
                        .background(DS.accentTint),
                ) {
                    CourseImage(
                        courseId = course.id,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop,
                        maxEdgePx = 480,
                    )
                }
                // The green check draws itself once the cover has landed.
                Box(
                    modifier = Modifier
                        .align(Alignment.BottomEnd)
                        .offset(x = 8.dp, y = 8.dp)
                        .background(DS.surface, CircleShape)
                        .padding(3.dp),
                ) {
                    DSCheckBadge(size = 34.dp, delayMillis = 300)
                }
            }
            Spacer(Modifier.height(22.dp))
            Text(
                text = StringStore.text(context, "course.completed", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 26.sp,
                lineHeight = 33.sp,
                color = DS.ink,
                textAlign = TextAlign.Center,
                modifier = Modifier.dsStagger(1),
            )
            Spacer(Modifier.height(18.dp))
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .dsStagger(3, stepMillis = 110)
                    .sophiaCard()
                    .padding(DS.Space.m),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Text(
                    text = course.title,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Medium,
                    fontSize = 14.sp,
                    lineHeight = 20.sp,
                    color = DS.inkSecondary,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    CourseSubjectAvatar(subject = course.subjectEnum, size = 36.dp)
                    Text(
                        // The translated subject, as iOS shows it; the enum name printed « Litterature »
                        // and « Comprendre_le_monde » in every language.
                        text = StringStore.text(context, "subject.${course.subjectEnum.storageKey}.short", language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 16.sp,
                        color = DS.ink,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f),
                    )
                    Text(
                        text = StringStore.text(context, "common.levelShort", language, level),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 12.sp,
                        color = DS.ink,
                        maxLines = 1,
                        modifier = Modifier
                            .clip(RoundedCornerShape(10.dp))
                            .background(DS.accentTint)
                            .padding(horizontal = 10.dp, vertical = 4.dp),
                    )
                }
                Text(
                    text = "$xpIntoLevel / $xpForLevel XP",
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp,
                    color = DS.ink,
                )
                CourseXPBar(fraction = xpBar.value, height = 8.dp)
                CourseGoldPill(
                    text = StringStore.text(context, "common.xpEarned", language, earnedXP),
                    modifier = Modifier.dsPopIn(delayMillis = 1100),
                )
            }
            if (progress != null && progressManager != null) {
                Spacer(Modifier.height(18.dp))
                CourseEndSocialRow(
                    course = course,
                    language = language,
                    progress = progress,
                    progressManager = progressManager,
                    modifier = Modifier.dsStagger(4, stepMillis = 110),
                )
            }
            if (freemiumNote != null) {
                Spacer(Modifier.height(18.dp))
                Row(
                    modifier = Modifier
                        .dsStagger(5, stepMillis = 110)
                        .clip(DS.cardShape)
                        .background(DS.accentTint)
                        .padding(horizontal = 14.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Icon(Icons.Filled.Lock, contentDescription = null, tint = DS.accent, modifier = Modifier.size(15.dp))
                    Text(
                        text = freemiumNote,
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 13.sp,
                        lineHeight = 18.sp,
                        color = DS.ink,
                        modifier = Modifier.weight(1f, fill = false),
                    )
                }
            }
        }
        // The actions, anchored at the bottom of the screen. Both vibrate by their style.
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .readableWidth()
                .padding(start = 24.dp, end = 24.dp, bottom = 24.dp)
                .dsStagger(7, stepMillis = 110),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            CourseRoundIconButton(
                icon = Icons.Filled.Close,
                onClick = onClose,
                contentDescription = StringStore.text(context, "common.close", language),
                size = 56.dp,
            )
            if (showQuizCta) {
                CoursePrimaryButton(
                    text = StringStore.text(context, "common.miniQuiz", language),
                    onClick = onQuiz,
                    leadingIcon = if (quizLocked) Icons.Filled.Lock else null,
                    trailingIcon = Icons.AutoMirrored.Filled.ArrowForward,
                    modifier = Modifier.weight(1f),
                )
            } else {
                CoursePrimaryButton(
                    text = StringStore.text(context, "course.finish", language),
                    onClick = onClose,
                    leadingIcon = Icons.Filled.Check,
                    modifier = Modifier.weight(1f),
                )
            }
        }
    }
}

/** The chrome of a button of the « like / follow » row: a bordered card with its bottom edge. */
@Composable
private fun Modifier.socialChrome(fill: Color, border: Color): Modifier {
    val shape = DS.cardShape
    val animatedFill by animateColorAsState(fill, DSMotion.snappy(), label = "socialFill")
    val animatedBorder by animateColorAsState(border, DSMotion.snappy(), label = "socialBorder")
    return this
        .drawBehind {
            val outline = shape.createOutline(size, layoutDirection, this)
            translate(top = 1.5.dp.toPx()) { drawOutline(outline, animatedBorder) }
        }
        .clip(shape)
        .background(DS.surface)
        .background(animatedFill)
        .border(1.5.dp, animatedBorder, shape)
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
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val author = remember(course.id) { CreatorIdentity.forCourse(context.applicationContext, course.id).author }
    val liked = course.id in progress.likedCourseIds
    var likeBurst by remember(course.id) { mutableIntStateOf(0) }

    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Row(
            modifier = Modifier
                .weight(1f)
                .height(50.dp)
                // The choice vibrates as a selection; the press itself stays silent.
                .pressable(haptic = false, onClick = {
                    haptics.select()
                    val wasLiked = progressManager.isLiked(course.id)
                    progressManager.toggleLike(course.id)
                    if (!wasLiked) likeBurst++
                    Analytics.log(if (wasLiked) "unlike" else "like", courseId = course.id, screen = "course_end")
                })
                .socialChrome(
                    fill = if (liked) LikedTint.copy(alpha = 0.1f) else DS.surface,
                    border = if (liked) LikedTint.copy(alpha = 0.55f) else DS.hairline,
                )
                .padding(horizontal = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            LikeHeartIcon(liked = liked, burst = likeBurst, size = 17.dp, idleTint = LikedTint)
            Text(
                text = StringStore.text(context, if (liked) "course.end.liked" else "course.end.like", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 15.sp,
                color = if (liked) LikedTint else DS.ink,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f, fill = false),
            )
        }

        if (author != null) {
            val following = author.slug in progress.followedCreatorSlugs
            val firstName = author.name.split(" ").firstOrNull()?.takeIf { it.isNotBlank() } ?: author.name
            Row(
                modifier = Modifier
                    .weight(1f)
                    .height(50.dp)
                    .pressable(haptic = false, onClick = {
                        haptics.select()
                        val wasFollowing = progressManager.isFollowing(author.slug)
                        progressManager.toggleFollow(author.slug)
                        Analytics.log(if (wasFollowing) "unfollow" else "follow", courseId = course.id, screen = "course_end", props = mapOf("creator" to author.slug))
                    })
                    .socialChrome(
                        fill = if (following) DS.accentTint else DS.surface,
                        border = if (following) DS.accent else DS.hairline,
                    )
                    .padding(horizontal = 12.dp),
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
                    color = if (following) DS.accent else DS.ink,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f, fill = false),
                )
            }
        }
    }
}
