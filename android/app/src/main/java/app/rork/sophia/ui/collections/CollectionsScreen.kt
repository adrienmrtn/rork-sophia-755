package app.rork.sophia.ui.collections

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Course
import app.rork.sophia.domain.LearningCollection
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.SophiaTypography

@Composable
fun CollectionsScreen(
    modifier: Modifier = Modifier,
    language: AppLanguage,
    progress: UserProgress,
    onOpenCourse: (Course) -> Unit,
) {
    val context = LocalContext.current
    val collections = remember(language) { ContentCatalog.collections(context, language) }
    val coursesById = remember(language) {
        ContentCatalog.courses(context, language).associateBy { it.id }
    }

    Column(modifier = modifier.fillMaxSize().background(DS.canvas)) {
        Text(
            text = StringStore.text(context, "tab.collections", language),
            style = SophiaTypography.titleLarge,
            modifier = Modifier.padding(horizontal = DS.Space.l, vertical = DS.Space.m),
        )
        LazyColumn(
            contentPadding = PaddingValues(horizontal = DS.Space.l, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            items(collections, key = { it.id }) { collection ->
                CollectionCard(
                    collection = collection,
                    progress = progress,
                    onClick = {
                        collection.courseIds.firstOrNull()
                            ?.let { coursesById[it] }
                            ?.let(onOpenCourse)
                    },
                )
            }
        }
    }
}

@Composable
private fun CollectionCard(
    collection: LearningCollection,
    progress: UserProgress,
    onClick: () -> Unit,
) {
    val done = collection.courseIds.count { progress.courseProgress[it]?.isCompleted == true }
    val total = collection.courseIds.size.coerceAtLeast(1)
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(DS.cardShape)
            .background(DS.surface)
            .clickable(onClick = onClick)
            .padding(DS.Space.m),
    ) {
        Text(text = collection.title, style = SophiaTypography.titleMedium)
        Text(
            text = collection.description,
            style = SophiaTypography.bodyMedium,
            modifier = Modifier.padding(top = 6.dp, bottom = 12.dp),
        )
        LinearProgressIndicator(
            progress = { done.toFloat() / total },
            modifier = Modifier.fillMaxWidth().clip(DS.controlShape),
            color = DS.accent,
            trackColor = DS.hairline,
            strokeCap = StrokeCap.Round,
        )
        Text(
            text = "$done / $total",
            style = SophiaTypography.labelMedium,
            modifier = Modifier.padding(top = 8.dp),
        )
    }
}
