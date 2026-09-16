package app.rork.sophia.ui.library

import androidx.compose.foundation.background
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.rememberCourseSummaries
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseProgress
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.components.CalmProgressBar
import app.rork.sophia.ui.components.CircleIconButton
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.components.ScreenTitle
import app.rork.sophia.ui.components.SophiaPrimaryButton
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.onboarding.readableWidth
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography

/**
 * Everything the user has read, in two tabs.
 *
 * Before this there was nowhere to find a course again: the home feed only moves forwards
 * and hides what is finished, and the library is the whole catalogue rather than your own
 * history. Reached from the button next to the streak badge on home.
 */
@Composable
fun MyCoursesScreen(
    language: AppLanguage,
    progress: UserProgress,
    onOpenCourse: (String) -> Unit,
    onDiscover: () -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val summaries = rememberCourseSummaries(language)
    var showCompleted by remember { mutableStateOf(false) }

    val byId = remember(summaries) { summaries.associateBy { it.id } }
    // Most advanced first while reading, most recently finished first once done — which is
    // the order each list is actually looked at in.
    val inProgress = remember(progress, byId) {
        progress.courseProgress
            .filter { !it.value.isCompleted && it.value.lastLessonIndex > 0 }
            .mapNotNull { (id, entry) -> byId[id]?.let { it to entry } }
            .sortedWith(
                compareByDescending<Pair<CourseSummary, CourseProgress>> { it.second.fraction }
                    .thenByDescending { it.second.startedAt ?: "" },
            )
    }
    val completed = remember(progress, byId) {
        progress.courseProgress
            .filter { it.value.isCompleted }
            .mapNotNull { (id, entry) -> byId[id]?.let { it to entry } }
            // Progress saved before completion dates existed sorts last rather than first,
            // which is the honest place for a date nobody recorded.
            .sortedByDescending { it.second.completedAt ?: "" }
    }
    val rows = if (showCompleted) completed else inProgress

    Column(
        modifier = modifier.fillMaxSize().background(DS.canvas),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .readableWidth()
                .padding(horizontal = DS.Space.l)
                .padding(top = DS.Space.s),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            ScreenTitle(
                text = StringStore.text(context, "myCourses.title", language),
                modifier = Modifier.weight(1f),
            )
            CircleIconButton(icon = Icons.Filled.Close, onClick = onBack, size = 44.dp)
        }

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .readableWidth()
                .padding(horizontal = DS.Space.l, vertical = DS.Space.s),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            MyCoursesTab(
                label = StringStore.text(context, "myCourses.tab.inProgress", language),
                count = inProgress.size,
                selected = !showCompleted,
                onClick = { showCompleted = false },
                modifier = Modifier.weight(1f),
            )
            MyCoursesTab(
                label = StringStore.text(context, "myCourses.tab.completed", language),
                count = completed.size,
                selected = showCompleted,
                onClick = { showCompleted = true },
                modifier = Modifier.weight(1f),
            )
        }

        if (rows.isEmpty()) {
            MyCoursesEmptyState(
                language = language,
                onDiscover = onDiscover,
                modifier = Modifier.weight(1f).readableWidth(),
            )
        } else {
            LazyColumn(
                modifier = Modifier.weight(1f).fillMaxWidth().readableWidth(),
                contentPadding = androidx.compose.foundation.layout.PaddingValues(
                    start = DS.Space.l,
                    end = DS.Space.l,
                    bottom = 24.dp,
                ),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                items(rows, key = { it.first.id }) { (course, entry) ->
                    MyCourseRow(
                        course = course,
                        entry = entry,
                        language = language,
                        showCompleted = showCompleted,
                        onClick = { onOpenCourse(course.id) },
                    )
                }
            }
        }
    }
}

/** How far through a course the reader got, 0…1. Unknown page count reads as "just started". */
private val CourseProgress.fraction: Float
    get() = if (lessonCount <= 0) 0f else (lastLessonIndex + 1f) / lessonCount

@Composable
private fun MyCoursesTab(
    label: String,
    count: Int,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .clip(DS.controlShape)
            .background(if (selected) DS.accent else DS.surface)
            .softPress(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 11.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = if (count > 0) "$label · $count" else label,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 14.sp,
            color = if (selected) Color.White else DS.inkSecondary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

@Composable
private fun MyCourseRow(
    course: CourseSummary,
    entry: CourseProgress,
    language: AppLanguage,
    showCompleted: Boolean,
    onClick: () -> Unit,
) {
    val context = LocalContext.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .sophiaCard(shape = DS.controlShape, elevation = 4.dp)
            .softPress(onClick = onClick)
            .padding(10.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        CourseImage(
            courseId = course.id,
            modifier = Modifier.size(64.dp).clip(DS.controlShape),
            contentScale = ContentScale.Crop,
            maxEdgePx = 240,
        )
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            Text(
                text = StringStore.text(
                    context,
                    "subject.${course.subjectEnum.storageKey}.short",
                    language,
                ),
                style = SophiaTypography.labelMedium.copy(
                    fontSize = 11.sp,
                    color = DS.accentSoft,
                    fontWeight = FontWeight.SemiBold,
                ),
                maxLines = 1,
            )
            Text(
                text = course.title,
                style = SophiaTypography.bodyLarge.copy(fontSize = 15.sp),
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            if (showCompleted) {
                if (entry.bestQuizScore > 0) {
                    Text(
                        text = StringStore.text(
                            context,
                            "myCourses.quizScore",
                            language,
                            entry.bestQuizScore,
                            entry.quizMaxPoints,
                        ),
                        style = SophiaTypography.labelMedium.copy(fontSize = 12.sp),
                    )
                }
            } else if (entry.lessonCount > 0) {
                Text(
                    text = StringStore.text(
                        context,
                        "myCourses.progress",
                        language,
                        (entry.lastLessonIndex + 1).coerceAtMost(entry.lessonCount),
                        entry.lessonCount,
                    ),
                    style = SophiaTypography.labelMedium.copy(fontSize = 12.sp),
                )
                CalmProgressBar(fraction = entry.fraction.coerceIn(0f, 1f))
            }
        }
    }
}

@Composable
private fun MyCoursesEmptyState(
    language: AppLanguage,
    onDiscover: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    Column(
        modifier = modifier.fillMaxWidth().padding(DS.Space.l),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier.size(96.dp).clip(CircleShape).background(DS.accentTint),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                Icons.AutoMirrored.Filled.MenuBook,
                contentDescription = null,
                tint = DS.accent,
                modifier = Modifier.size(40.dp),
            )
        }
        Spacer(Modifier.height(20.dp))
        Text(
            text = StringStore.text(context, "myCourses.empty.title", language),
            style = SophiaTypography.titleMedium,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(24.dp))
        SophiaPrimaryButton(
            text = StringStore.text(context, "myCourses.empty.cta", language),
            onClick = onDiscover,
        )
    }
}
