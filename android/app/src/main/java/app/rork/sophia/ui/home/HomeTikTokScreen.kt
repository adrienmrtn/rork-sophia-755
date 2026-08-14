package app.rork.sophia.ui.home

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
import androidx.compose.foundation.pager.VerticalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.DeviceCapabilities
import app.rork.sophia.data.ShareHelper
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.TutorialFlags
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.components.FirstOpenExplanation
import app.rork.sophia.ui.theme.DS
import kotlinx.coroutines.delay

@Composable
fun HomeTikTokScreen(
    modifier: Modifier = Modifier,
    language: AppLanguage,
    favoriteIds: Set<String>,
    autoSwipeCourseId: String?,
    onAutoSwipeConsumed: () -> Unit,
    onToggleFavorite: (String) -> Unit,
    onStartCourse: (String) -> Unit,
    onUserSwipe: () -> Unit = {},
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val lowRam = remember { DeviceCapabilities.isLowRam(context) }
    val cached = remember(language) {
        ContentCatalog.cachedSummaries(language).orEmpty()
    }
    var cards by remember(language) { mutableStateOf(cached) }
    var catalogReady by remember(language) { mutableStateOf(cached.isNotEmpty()) }
    var showExplain by remember { mutableStateOf(false) }
    var suppressSwipeCount by remember { mutableStateOf(false) }
    val pagerState = rememberPagerState(pageCount = { cards.size.coerceAtLeast(1) })

    LaunchedEffect(language) {
        if (cards.isEmpty()) {
            cards = ContentCatalog.summariesAsync(context.applicationContext, language).shuffled()
        } else if (cards === cached && cached.isNotEmpty()) {
            cards = cached.shuffled()
        }
        catalogReady = true
        if (!lowRam && !app.tutorialFlags.seen(TutorialFlags.Id.HOME_SWIPE)) {
            delay(900)
            showExplain = true
        }
    }

    LaunchedEffect(autoSwipeCourseId, cards) {
        val id = autoSwipeCourseId ?: return@LaunchedEffect
        val found = cards.indexOfFirst { it.id == id }
        if (found >= 0 && found + 1 < cards.size) {
            suppressSwipeCount = true
            pagerState.animateScrollToPage(found + 1)
        }
        onAutoSwipeConsumed()
    }

    LaunchedEffect(pagerState.settledPage) {
        if (suppressSwipeCount) {
            suppressSwipeCount = false
        } else if (pagerState.settledPage > 0) {
            onUserSwipe()
        }
    }

    Box(modifier = modifier.fillMaxSize()) {
        Column(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = DS.Space.l, vertical = DS.Space.s),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = "Sophia",
                    fontFamily = FontFamily.SansSerif,
                    fontWeight = FontWeight.Bold,
                    fontSize = 22.sp,
                    color = DS.ink,
                )
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Filled.LocalFireDepartment,
                        contentDescription = null,
                        tint = DS.warm,
                        modifier = Modifier.size(20.dp),
                    )
                }
            }

            if (!catalogReady) {
                Box(modifier = Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
                    Text("…", fontFamily = FontFamily.SansSerif, color = DS.inkSecondary)
                }
            } else if (cards.isEmpty()) {
                Box(modifier = Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
                    Text(
                        text = StringStore.text(context, "home.allCaughtUp", language)
                            .takeIf { it != "home.allCaughtUp" }
                            ?: "Tous les cours sont faits — bravo !",
                        fontFamily = FontFamily.SansSerif,
                        color = DS.ink,
                    )
                }
            } else {
                VerticalPager(
                    state = pagerState,
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .padding(bottom = 8.dp),
                    beyondViewportPageCount = 0,
                    pageSpacing = 12.dp,
                ) { page ->
                    val course = cards.getOrNull(page) ?: return@VerticalPager
                    TikTokCourseCard(
                        course = course,
                        language = language,
                        isFavorite = course.id in favoriteIds,
                        onToggleFavorite = { onToggleFavorite(course.id) },
                        onShare = { ShareHelper.shareCourse(context, course.id, course.title) },
                        onStart = { onStartCourse(course.id) },
                    )
                }
            }
        }
        if (showExplain && catalogReady && cards.isNotEmpty()) {
            FirstOpenExplanation(
                language = language,
                icon = "👆",
                titleKey = "explain.home.title",
                bodyKey = "explain.home.body",
                onDismiss = {
                    app.tutorialFlags.markSeen(TutorialFlags.Id.HOME_SWIPE)
                    showExplain = false
                },
            )
        }
    }
}

@Composable
private fun TikTokCourseCard(
    course: CourseSummary,
    language: AppLanguage,
    isFavorite: Boolean,
    onToggleFavorite: () -> Unit,
    onShare: () -> Unit,
    onStart: () -> Unit,
) {
    val context = LocalContext.current
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = DS.Space.l)
            .clip(DS.cardShape)
            .background(DS.surface)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f)
                .clip(RoundedCornerShape(topStart = 22.dp, topEnd = 22.dp)),
        ) {
            CourseImage(
                courseId = course.id,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop,
            )
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            listOf(Color.Transparent, Color.Black.copy(alpha = 0.55f)),
                        ),
                    ),
            )
            Row(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(8.dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                IconButton(
                    onClick = onShare,
                    modifier = Modifier.background(Color.Black.copy(alpha = 0.35f), CircleShape),
                ) {
                    Icon(Icons.Filled.Share, contentDescription = null, tint = Color.White)
                }
                IconButton(
                    onClick = onToggleFavorite,
                    modifier = Modifier.background(Color.Black.copy(alpha = 0.35f), CircleShape),
                ) {
                    Icon(
                        if (isFavorite) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder,
                        contentDescription = null,
                        tint = if (isFavorite) Color(0xFFFF5A7A) else Color.White,
                    )
                }
            }
            Column(
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .padding(DS.Space.m),
            ) {
                Text(
                    text = course.subjectEnum.name.lowercase().replaceFirstChar { it.titlecase() },
                    color = Color.White.copy(alpha = 0.85f),
                    fontFamily = FontFamily.SansSerif,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium,
                )
                Spacer(Modifier.height(4.dp))
                Text(
                    text = course.title,
                    color = Color.White,
                    fontFamily = FontFamily.SansSerif,
                    fontWeight = FontWeight.Bold,
                    fontSize = 24.sp,
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }

        Column(modifier = Modifier.padding(DS.Space.m)) {
            Text(
                text = course.description,
                fontFamily = FontFamily.SansSerif,
                fontSize = 14.sp,
                color = DS.inkSecondary,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
            )
            Spacer(Modifier.height(DS.Space.s))
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Icon(Icons.Filled.Visibility, null, tint = DS.inkTertiary, modifier = Modifier.size(16.dp))
                Text(
                    text = readsCountShort(course.id),
                    fontFamily = FontFamily.SansSerif,
                    fontSize = 12.sp,
                    color = DS.inkTertiary,
                )
            }
            Spacer(Modifier.height(DS.Space.m))
            Button(
                onClick = onStart,
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = DS.controlShape,
                colors = ButtonDefaults.buttonColors(containerColor = DS.accent, contentColor = Color.White),
            ) {
                Text(
                    text = StringStore.text(context, "home.start", language)
                        .takeIf { it != "home.start" } ?: "Commencer",
                    fontFamily = FontFamily.SansSerif,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 16.sp,
                )
            }
        }
    }
}

private fun readsCountShort(id: String): String {
    var hash = 0xcbf29ce484222325UL
    for (byte in id.encodeToByteArray()) {
        hash = hash xor byte.toULong()
        hash *= 0x100000001b3UL
    }
    val count = 7_000 + (hash % 243_000UL).toInt()
    val rounded = (count / 100) * 100
    return if (rounded < 10_000) {
        String.format("%.1f k", rounded / 1000.0).replace('.', ',')
    } else {
        "${rounded / 1000} k"
    }
}
