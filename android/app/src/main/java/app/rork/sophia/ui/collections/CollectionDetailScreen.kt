package app.rork.sophia.ui.collections

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.rememberCourseSummaries
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.LearningCollection
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.components.CircleIconButton
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.SophiaTypography

@Composable
fun CollectionDetailScreen(
    collection: LearningCollection,
    language: AppLanguage,
    progress: UserProgress,
    onBack: () -> Unit,
    onOpenCourse: (String) -> Unit,
) {
    val context = LocalContext.current
    val summaries = rememberCourseSummaries(language)
    val byId = summaries.associateBy { it.id }
    val done = collection.courseIds.count { progress.courseProgress[it]?.isCompleted == true }
    val total = collection.courseIds.size.coerceAtLeast(1)
    val complete = done >= collection.courseIds.size && collection.courseIds.isNotEmpty()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState())
            .padding(bottom = 40.dp),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = DS.Space.s, vertical = DS.Space.s),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            CircleIconButton(icon = Icons.AutoMirrored.Filled.ArrowBack, onClick = onBack)
            Spacer(Modifier.weight(1f))
            Text(
                text = StringStore.text(context, "collections.progress", language, done, collection.courseIds.size),
                style = SophiaTypography.labelMedium,
            )
        }

        Column(modifier = Modifier.padding(horizontal = DS.Space.l)) {
            CollectionCover(
                collection = collection,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(190.dp)
                    .clip(DS.cardShape),
            )
            Spacer(Modifier.height(16.dp))
            Text(text = collection.title, style = SophiaTypography.titleLarge)
            Spacer(Modifier.height(8.dp))
            Text(text = collection.description, style = SophiaTypography.bodyLarge)
            Spacer(Modifier.height(14.dp))
            LinearProgressIndicator(
                progress = { done.toFloat() / total },
                modifier = Modifier.fillMaxWidth().clip(DS.controlShape),
                color = DS.accent,
                trackColor = DS.hairline,
                strokeCap = StrokeCap.Round,
            )
            Spacer(Modifier.height(22.dp))
            Text(
                text = StringStore.text(context, "collections.path", language).uppercase(),
                style = SophiaTypography.labelMedium,
            )
            Spacer(Modifier.height(12.dp))
        }

        collection.courseIds.forEachIndexed { index, courseId ->
            val summary = byId[courseId]
            val completed = progress.courseProgress[courseId]?.isCompleted == true
            Row(
                modifier = Modifier
                    .padding(horizontal = DS.Space.l)
                    .fillMaxWidth()
                    .softPress(onClick = { onOpenCourse(courseId) })
                    .sophiaCard(shape = DS.controlShape, elevation = 3.dp)
                    .padding(10.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                Box(
                    modifier = Modifier
                        .size(52.dp)
                        .clip(DS.controlShape)
                        .background(DS.surfaceMuted),
                ) {
                    CourseImage(
                        courseId = courseId,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop,
                        maxEdgePx = 240,
                    )
                }
                Column(modifier = Modifier.weight(1f)) {
                    if (summary != null) {
                        Text(
                            text = summary.subjectEnum.name.lowercase().replaceFirstChar { it.titlecase() },
                            style = SophiaTypography.labelMedium,
                            color = DS.accentSoft,
                        )
                    }
                    Text(
                        text = summary?.title ?: courseId,
                        style = SophiaTypography.titleMedium,
                        color = if (completed) DS.inkSecondary else DS.ink,
                    )
                }
                if (completed) {
                    Icon(Icons.Filled.CheckCircle, contentDescription = null, tint = DS.accentSoft)
                } else {
                    Icon(Icons.Filled.ChevronRight, contentDescription = null, tint = DS.inkTertiary)
                }
            }
            if (index != collection.courseIds.lastIndex) {
                Box(
                    modifier = Modifier
                        .padding(start = DS.Space.l + 35.dp)
                        .size(width = 2.dp, height = 14.dp)
                        .background(DS.hairline),
                )
            }
        }

        if (complete) {
            Row(
                modifier = Modifier
                    .padding(DS.Space.l)
                    .fillMaxWidth()
                    .clip(DS.controlShape)
                    .background(DS.accentTint)
                    .padding(DS.Space.m),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Icon(Icons.Filled.CheckCircle, contentDescription = null, tint = DS.accentSoft)
                Text(
                    text = StringStore.text(context, "collections.pathComplete", language),
                    style = SophiaTypography.titleMedium,
                )
            }
        }
    }
}
