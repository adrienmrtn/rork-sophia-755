package app.rork.sophia.ui.library

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Search
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
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.rememberCourseSummaries
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.components.ScreenTitle
import app.rork.sophia.ui.components.SophiaEmptyState
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography

@Composable
fun LibraryScreen(
    modifier: Modifier = Modifier,
    language: AppLanguage,
    progress: UserProgress,
    onOpenCourse: (String) -> Unit,
) {
    val context = LocalContext.current
    val courses = rememberCourseSummaries(language)
    var query by remember { mutableStateOf("") }
    val filtered = remember(courses, query) {
        if (query.isBlank()) courses
        else courses.filter {
            it.title.contains(query, ignoreCase = true) ||
                it.description.contains(query, ignoreCase = true) ||
                it.subcategory.contains(query, ignoreCase = true)
        }
    }

    Column(modifier = modifier.fillMaxSize().background(DS.canvas)) {
        ScreenTitle(
            text = StringStore.text(context, "library.title", language),
            modifier = Modifier.padding(start = DS.Space.l, end = DS.Space.l, top = DS.Space.m, bottom = DS.Space.s),
        )
        SearchField(
            query = query,
            onQueryChange = { query = it },
            placeholder = StringStore.text(context, "library.search.placeholder", language),
            modifier = Modifier.padding(horizontal = DS.Space.l),
        )
        Spacer(Modifier.height(DS.Space.s))
        Text(
            text = StringStore.text(context, "subject.courses.count", language, filtered.size) +
                " · " +
                StringStore.text(
                    context,
                    "subject.completed.plural",
                    language,
                    progress.courseProgress.count { it.value.isCompleted },
                ),
            style = SophiaTypography.labelMedium,
            modifier = Modifier.padding(horizontal = DS.Space.l),
        )
        Spacer(Modifier.height(DS.Space.s))
        if (filtered.isEmpty()) {
            SophiaEmptyState(
                icon = Icons.Filled.Search,
                title = StringStore.text(context, "library.empty.title", language),
                subtitle = StringStore.text(context, "library.empty.subtitle", language),
            )
        } else {
            LazyVerticalGrid(
                columns = GridCells.Fixed(2),
                contentPadding = PaddingValues(start = DS.Space.l, end = DS.Space.l, bottom = 28.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
                horizontalArrangement = Arrangement.spacedBy(14.dp),
                modifier = Modifier.fillMaxSize(),
            ) {
                items(filtered, key = { it.id }) { course ->
                    val courseProgress = progress.courseProgress[course.id]
                    CourseGridCard(
                        course = course,
                        language = language,
                        completed = courseProgress?.isCompleted == true,
                        inProgress = courseProgress != null && courseProgress.isCompleted.not() &&
                            courseProgress.lastLessonIndex > 0,
                        onClick = { onOpenCourse(course.id) },
                    )
                }
                item(span = { GridItemSpan(2) }) { Spacer(Modifier.height(4.dp)) }
            }
        }
    }
}

@Composable
private fun SearchField(
    query: String,
    onQueryChange: (String) -> Unit,
    placeholder: String,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(DS.controlShape)
            .background(DS.surface)
            .border(1.dp, DS.hairline, DS.controlShape)
            .padding(horizontal = 16.dp, vertical = 13.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Icon(Icons.Filled.Search, contentDescription = null, tint = DS.inkTertiary, modifier = Modifier.size(18.dp))
        Box(modifier = Modifier.weight(1f), contentAlignment = Alignment.CenterStart) {
            if (query.isEmpty()) {
                Text(text = placeholder, style = SophiaTypography.bodyMedium, color = DS.inkTertiary)
            }
            BasicTextField(
                value = query,
                onValueChange = onQueryChange,
                singleLine = true,
                textStyle = SophiaTypography.bodyMedium.copy(color = DS.ink),
                cursorBrush = SolidColor(DS.accentSoft),
                modifier = Modifier.fillMaxWidth(),
            )
        }
        if (query.isNotEmpty()) {
            Icon(
                Icons.Filled.Close,
                contentDescription = null,
                tint = DS.inkTertiary,
                modifier = Modifier.size(18.dp).softPress(onClick = { onQueryChange("") }),
            )
        }
    }
}

@Composable
private fun CourseGridCard(
    course: CourseSummary,
    language: AppLanguage,
    completed: Boolean,
    inProgress: Boolean,
    onClick: () -> Unit,
) {
    val context = LocalContext.current
    Column(
        modifier = Modifier
            .softPress(onClick = onClick)
            .sophiaCard(shape = DS.controlShape, elevation = 4.dp),
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(4f / 3f)
                .clip(RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp))
                .background(DS.surfaceMuted),
        ) {
            CourseImage(
                courseId = course.id,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop,
                maxEdgePx = 360,
            )
            if (completed || inProgress) {
                StatusBadge(
                    label = StringStore.text(
                        context,
                        if (completed) "library.status.done" else "library.status.inProgress",
                        language,
                    ),
                    icon = if (completed) Icons.Filled.Check else Icons.Filled.PlayArrow,
                    onAccent = completed,
                    modifier = Modifier.align(Alignment.TopStart).padding(8.dp),
                )
            }
        }
        Column(modifier = Modifier.padding(horizontal = 12.dp, vertical = 12.dp)) {
            Text(
                text = StringStore.text(
                    context,
                    "subject.${course.subjectEnum.storageKey}.short",
                    language,
                ).uppercase(),
                fontFamily = PlusJakartaSans,
                fontSize = 11.sp,
                letterSpacing = 1.sp,
                color = DS.accentSoft,
                fontWeight = FontWeight.SemiBold,
            )
            Spacer(Modifier.height(6.dp))
            Text(
                text = course.title,
                style = SophiaTypography.titleMedium.copy(fontSize = 15.sp, lineHeight = 20.sp),
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

@Composable
private fun StatusBadge(
    label: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    onAccent: Boolean,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .clip(CircleShape)
            .background(if (onAccent) DS.accent else DS.surface)
            .then(if (onAccent) Modifier else Modifier.border(1.dp, DS.hairline, CircleShape))
            .padding(horizontal = 8.dp, vertical = 5.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Icon(
            icon,
            contentDescription = null,
            tint = if (onAccent) Color.White else DS.accentSoft,
            modifier = Modifier.size(11.dp),
        )
        Text(
            text = label,
            fontFamily = PlusJakartaSans,
            fontSize = 10.sp,
            fontWeight = FontWeight.SemiBold,
            letterSpacing = 0.3.sp,
            color = if (onAccent) Color.White else DS.accentSoft,
        )
    }
}
