package app.rork.sophia.ui.course

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.CourseAuthor
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.rememberCourseSummaries
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.components.CircleIconButton
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.onboarding.readableWidth
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import app.rork.sophia.ui.theme.uppercaseInApp

/**
 * The professor's page: portrait, pedigree, biography, and every course they wrote.
 * Mirrors iOS `AuthorView`. Opened from the byline or the "written by" card of a course.
 */
@Composable
fun AuthorScreen(
    author: CourseAuthor,
    language: AppLanguage,
    progress: UserProgress,
    currentCourseId: String?,
    onOpenCourse: (String) -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val summaries = rememberCourseSummaries(language)
    val courses = remember(summaries, author) {
        val wanted = author.courseIds.toSet()
        summaries.filter { it.id in wanted }
    }
    val countLabel = if (courses.size == 1) {
        StringStore.text(context, "author.courses.one", language)
    } else {
        StringStore.text(context, "author.courses.many", language, courses.size)
    }

    Column(
        modifier = modifier.fillMaxSize().background(DS.canvas),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        LazyColumn(
            modifier = Modifier.weight(1f).fillMaxWidth().readableWidth(),
            contentPadding = PaddingValues(start = DS.Space.l, end = DS.Space.l, top = DS.Space.s, bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item {
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                    CircleIconButton(icon = Icons.Filled.Close, onClick = onBack, size = 44.dp)
                }
            }
            item {
                Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    AuthorAvatar(author = author, size = 96.dp)
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(
                            text = author.name,
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 28.sp,
                            color = DS.ink,
                        )
                        author.title(language)?.let { title ->
                            Text(
                                text = title,
                                fontFamily = PlusJakartaSans,
                                fontWeight = FontWeight.Medium,
                                fontSize = 15.sp,
                                color = DS.inkSecondary,
                            )
                        }
                        author.institution?.takeIf { it.isNotBlank() }?.let { institution ->
                            Text(
                                text = institution,
                                fontFamily = PlusJakartaSans,
                                fontSize = 12.sp,
                                color = DS.inkTertiary,
                            )
                        }
                    }
                    author.bio(language)?.let { bio ->
                        Text(text = bio, style = SophiaTypography.bodyLarge, color = DS.inkSecondary)
                    }
                }
            }
            item {
                Spacer(Modifier.height(8.dp))
                Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = StringStore.text(context, "author.courses.title", language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 17.sp,
                        color = DS.ink,
                        modifier = Modifier.weight(1f),
                    )
                    Text(
                        text = countLabel,
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Medium,
                        fontSize = 14.sp,
                        color = DS.inkTertiary,
                    )
                }
            }
            items(courses, key = { it.id }) { course ->
                val entry = progress.courseProgress[course.id]
                AuthorCourseRow(
                    course = course,
                    language = language,
                    completed = entry?.isCompleted == true,
                    inProgress = entry != null && !entry.isCompleted && entry.lastLessonIndex > 0,
                    isCurrent = course.id == currentCourseId,
                    onClick = { onOpenCourse(course.id) },
                )
            }
        }
    }
}

@Composable
private fun AuthorCourseRow(
    course: CourseSummary,
    language: AppLanguage,
    completed: Boolean,
    inProgress: Boolean,
    isCurrent: Boolean,
    onClick: () -> Unit,
) {
    val context = LocalContext.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .sophiaCard()
            .softPress(onClick = onClick)
            .padding(12.dp)
            .alpha(if (isCurrent) 0.7f else 1f),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        CourseImage(
            courseId = course.id,
            modifier = Modifier.size(56.dp).clip(DS.controlShape),
            contentScale = ContentScale.Crop,
            maxEdgePx = 240,
        )
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                text = StringStore.text(context, "subject.${course.subjectEnum.storageKey}.short", language)
                    .uppercaseInApp(),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 11.sp,
                letterSpacing = 1.sp,
                color = DS.accentSoft,
            )
            Text(
                text = course.title,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 15.sp,
                color = DS.ink,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            if (isCurrent) {
                Text(
                    text = StringStore.text(context, "author.currentCourse", language),
                    fontFamily = PlusJakartaSans,
                    fontSize = 12.sp,
                    color = DS.inkTertiary,
                )
            }
        }
        Box(
            modifier = Modifier
                .size(34.dp)
                .clip(CircleShape)
                .background(if (completed) DS.successTint else DS.accent),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = when {
                    completed -> Icons.Filled.Check
                    inProgress -> Icons.AutoMirrored.Filled.ArrowForward
                    else -> Icons.Filled.PlayArrow
                },
                contentDescription = null,
                tint = if (completed) DS.success else Color.White,
                modifier = Modifier.size(16.dp),
            )
        }
    }
}
