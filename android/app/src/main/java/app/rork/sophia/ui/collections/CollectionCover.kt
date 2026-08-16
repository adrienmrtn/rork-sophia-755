package app.rork.sophia.ui.collections

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ViewModule
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import app.rork.sophia.domain.LearningCollection
import app.rork.sophia.ui.theme.DS
import coil.compose.AsyncImage
import coil.request.ImageRequest

@Composable
fun CollectionCover(
    collection: LearningCollection,
    modifier: Modifier = Modifier,
    accentIndex: Int = 0,
) {
    val context = LocalContext.current
    val asset = remember(collection.id, collection.coverAssetName) {
        collection.coverAssetName.takeIf { it.isNotBlank() }?.let { name ->
            "file:///android_asset/collection_covers/$name.jpg"
        }
    }
    val palette = palettes[accentIndex.mod(palettes.size)]
    Box(
        modifier = modifier.background(Brush.linearGradient(listOf(palette.first, palette.second))),
        contentAlignment = Alignment.Center,
    ) {
        if (asset == null) {
            Icon(
                Icons.Filled.ViewModule,
                contentDescription = null,
                tint = DS.accentSoft.copy(alpha = 0.55f),
            )
        } else {
            AsyncImage(
                model = ImageRequest.Builder(context)
                    .data(asset)
                    .crossfade(true)
                    .build(),
                contentDescription = collection.title,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop,
            )
        }
    }
}

private val palettes = listOf(
    Color(0xFFE9EFF8) to Color(0xFFD4E0F2),
    Color(0xFFE6ECF6) to Color(0xFFC8D7EE),
    Color(0xFFECF2F9) to Color(0xFFCEDEEF),
    Color(0xFFE5EEF8) to Color(0xFFC4D4EC),
)
