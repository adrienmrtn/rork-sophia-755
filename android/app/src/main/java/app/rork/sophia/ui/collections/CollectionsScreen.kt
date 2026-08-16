package app.rork.sophia.ui.collections

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.rememberCollections
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.TutorialFlags
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.LearningCollection
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.components.FirstOpenExplanation
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.SophiaTypography

@Composable
fun CollectionsScreen(
    modifier: Modifier = Modifier,
    language: AppLanguage,
    progress: UserProgress,
    onOpenCourse: (String) -> Unit,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val collections = rememberCollections(language)
    var selected by remember { mutableStateOf<LearningCollection?>(null) }
    var showExplain by remember {
        mutableStateOf(!app.tutorialFlags.seen(TutorialFlags.Id.COLLECTIONS))
    }

    val opened = selected
    if (opened != null) {
        CollectionDetailScreen(
            collection = opened,
            language = language,
            progress = progress,
            onBack = { selected = null },
            onOpenCourse = onOpenCourse,
        )
        return
    }

    val featured = remember(collections, progress) {
        collections.firstOrNull { c ->
            val done = c.courseIds.count { progress.courseProgress[it]?.isCompleted == true }
            done > 0 && done < c.courseIds.size
        } ?: collections.firstOrNull { c ->
            c.courseIds.none { progress.courseProgress[it]?.isCompleted == true }
        } ?: collections.firstOrNull()
    }
    val rest = remember(collections, featured) {
        collections.filter { it.id != featured?.id }
    }

    Box(modifier = modifier.fillMaxSize()) {
        Column(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
            Text(
                text = StringStore.text(context, "tab.collections", language),
                style = SophiaTypography.titleLarge,
                modifier = Modifier.padding(horizontal = DS.Space.l, vertical = DS.Space.m),
            )
            LazyColumn(
                contentPadding = PaddingValues(horizontal = DS.Space.l, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                if (featured != null) {
                    item(key = "featured-${featured.id}") {
                        FeaturedCollectionCard(
                            collection = featured,
                            progress = progress,
                            language = language,
                            accentIndex = collections.indexOfFirst { it.id == featured.id }.coerceAtLeast(0),
                            onClick = { selected = featured },
                        )
                    }
                }
                if (rest.isNotEmpty()) {
                    item(key = "rest-header") {
                        Text(
                            text = StringStore.text(context, "collections.title", language).uppercase(),
                            style = SophiaTypography.labelMedium,
                            modifier = Modifier.padding(top = 8.dp),
                        )
                    }
                }
                items(rest, key = { it.id }) { collection ->
                    CollectionRowCard(
                        collection = collection,
                        progress = progress,
                        language = language,
                        accentIndex = collections.indexOfFirst { it.id == collection.id }.coerceAtLeast(0),
                        onClick = { selected = collection },
                    )
                }
            }
        }
        if (showExplain) {
            FirstOpenExplanation(
                language = language,
                icon = "📚",
                titleKey = "explain.collections.title",
                bodyKey = "explain.collections.body",
                onDismiss = {
                    app.tutorialFlags.markSeen(TutorialFlags.Id.COLLECTIONS)
                    showExplain = false
                },
            )
        }
    }
}

@Composable
private fun FeaturedCollectionCard(
    collection: LearningCollection,
    progress: UserProgress,
    language: AppLanguage,
    accentIndex: Int,
    onClick: () -> Unit,
) {
    val context = LocalContext.current
    val done = collection.courseIds.count { progress.courseProgress[it]?.isCompleted == true }
    val total = collection.courseIds.size.coerceAtLeast(1)
    val complete = done >= collection.courseIds.size && collection.courseIds.isNotEmpty()
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .softPress(onClick = onClick)
            .sophiaCard(elevation = 8.dp),
    ) {
        CollectionCover(
            collection = collection,
            accentIndex = accentIndex,
            modifier = Modifier.fillMaxWidth().height(176.dp),
        )
        Column(modifier = Modifier.padding(DS.Space.m)) {
            Text(
                text = StringStore.text(context, "collections.featured", language).uppercase(),
                style = SophiaTypography.labelMedium,
                color = DS.accentSoft,
            )
            Spacer(Modifier.height(8.dp))
            Text(text = collection.title, style = SophiaTypography.titleMedium)
            Spacer(Modifier.height(6.dp))
            Text(text = collection.description, style = SophiaTypography.bodyMedium, maxLines = 2)
            Spacer(Modifier.height(12.dp))
            LinearProgressIndicator(
                progress = { done.toFloat() / total },
                modifier = Modifier.fillMaxWidth().clip(DS.controlShape),
                color = DS.accent,
                trackColor = DS.hairline,
                strokeCap = StrokeCap.Round,
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = if (complete) {
                    StringStore.text(context, "collections.complete", language)
                } else {
                    StringStore.text(context, "collections.progress", language, done, collection.courseIds.size)
                },
                style = SophiaTypography.labelMedium,
            )
        }
    }
}

@Composable
private fun CollectionRowCard(
    collection: LearningCollection,
    progress: UserProgress,
    language: AppLanguage,
    accentIndex: Int,
    onClick: () -> Unit,
) {
    val context = LocalContext.current
    val done = collection.courseIds.count { progress.courseProgress[it]?.isCompleted == true }
    val total = collection.courseIds.size.coerceAtLeast(1)
    val complete = done >= collection.courseIds.size && collection.courseIds.isNotEmpty()
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .softPress(onClick = onClick)
            .sophiaCard(shape = DS.controlShape, elevation = 4.dp)
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        CollectionCover(
            collection = collection,
            accentIndex = accentIndex,
            modifier = Modifier
                .size(84.dp)
                .clip(RoundedCornerShape(DS.Radius.small)),
        )
        Column(modifier = Modifier.weight(1f)) {
            Text(text = collection.title, style = SophiaTypography.titleMedium, maxLines = 2)
            Spacer(Modifier.height(8.dp))
            LinearProgressIndicator(
                progress = { done.toFloat() / total },
                modifier = Modifier.fillMaxWidth().clip(DS.controlShape),
                color = DS.accent,
                trackColor = DS.hairline,
                strokeCap = StrokeCap.Round,
            )
            Spacer(Modifier.height(6.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (complete) {
                    Icon(
                        Icons.Filled.CheckCircle,
                        contentDescription = null,
                        tint = DS.accentSoft,
                        modifier = Modifier.size(14.dp),
                    )
                    Spacer(Modifier.width(5.dp))
                }
                Text(
                    text = if (complete) {
                        StringStore.text(context, "collections.complete", language)
                    } else {
                        StringStore.text(context, "collections.progress", language, done, collection.courseIds.size)
                    },
                    style = SophiaTypography.labelMedium,
                )
            }
        }
        Icon(Icons.Filled.ChevronRight, contentDescription = null, tint = DS.inkTertiary)
    }
}
