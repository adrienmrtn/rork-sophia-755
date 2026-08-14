package app.rork.sophia.ui.library

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
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

    Column(modifier = modifier.fillMaxSize().background(DS.canvas).padding(horizontal = DS.Space.l)) {
        Text(
            text = StringStore.text(context, "library.title", language),
            style = SophiaTypography.titleLarge,
            modifier = Modifier.padding(top = DS.Space.m, bottom = DS.Space.s),
        )
        OutlinedTextField(
            value = query,
            onValueChange = { query = it },
            modifier = Modifier.fillMaxWidth(),
            leadingIcon = { Icon(Icons.Filled.Search, null, tint = DS.inkTertiary) },
            placeholder = {
                Text(StringStore.text(context, "library.search.placeholder", language))
            },
            singleLine = true,
            shape = RoundedCornerShape(DS.Radius.control),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = DS.accent,
                unfocusedBorderColor = DS.hairline,
                focusedContainerColor = DS.surface,
                unfocusedContainerColor = DS.surface,
            ),
        )
        Text(
            text = "${filtered.size} · ${progress.courseProgress.count { it.value.isCompleted }} ✓",
            style = SophiaTypography.labelMedium,
            modifier = Modifier.padding(vertical = DS.Space.s),
        )
        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            contentPadding = PaddingValues(bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.fillMaxSize(),
        ) {
            items(filtered, key = { it.id }) { course ->
                CourseGridCard(course = course, onClick = { onOpenCourse(course.id) })
            }
        }
    }
}

@Composable
private fun CourseGridCard(course: CourseSummary, onClick: () -> Unit) {
    Column(
        modifier = Modifier
            .clip(DS.cardShape)
            .background(DS.surface)
            .clickable(onClick = onClick),
    ) {
        CourseImage(
            courseId = course.id,
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(4f / 3f)
                .clip(RoundedCornerShape(topStart = 22.dp, topEnd = 22.dp)),
            contentScale = ContentScale.Crop,
            maxEdgePx = 360,
        )
        Column(modifier = Modifier.padding(12.dp)) {
            Text(
                text = course.subjectEnum.storageKey,
                fontFamily = PlusJakartaSans,
                fontSize = 11.sp,
                color = course.subjectEnum.color,
                fontWeight = FontWeight.SemiBold,
            )
            Text(
                text = course.title,
                style = SophiaTypography.titleMedium,
                fontSize = 14.sp,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}
