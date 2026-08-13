package app.rork.sophia.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.ShareHelper
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.TutorialFlags
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Course
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.components.FirstOpenExplanation
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography

@Composable
fun HomeTikTokScreen(
    modifier: Modifier = Modifier,
    language: AppLanguage,
    favoriteIds: Set<String>,
    autoSwipeCourseId: String?,
    onAutoSwipeConsumed: () -> Unit,
    onToggleFavorite: (String) -> Unit,
    onStartCourse: (Course) -> Unit,
    onUserSwipe: () -> Unit = {},
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    var cards by remember(language) { mutableStateOf<List<Course>>(emptyList()) }
    var catalogReady by remember(language) { mutableStateOf(false) }
    val pagerState = rememberPagerState(pageCount = { cards.size })
    var suppressSwipeCount by remember { mutableStateOf(false) }
    var showExplain by remember {
        mutableStateOf(!app.tutorialFlags.seen(TutorialFlags.Id.HOME_SWIPE))
    }

    LaunchedEffect(language) {
        catalogReady = false
        cards = ContentCatalog.coursesAsync(context.applicationContext, language).shuffled()
        catalogReady = true
    }

    LaunchedEffect(autoSwipeCourseId, cards) {
        val id = autoSwipeCourseId ?: return@LaunchedEffect
        val index = cards.indexOfFirst { it.id == id }
        if (index >= 0 && index + 1 < cards.size) {
            suppressSwipeCount = true
            pagerState.animateScrollToPage(index + 1)
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
                    style = SophiaTypography.titleLarge,
                    fontWeight = FontWeight.ExtraBold,
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
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("…", style = SophiaTypography.bodyLarge, color = DS.inkSecondary)
                }
            } else if (cards.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text(
                        text = StringStore.text(context, "home.allCaughtUp", language)
                            .takeIf { it != "home.allCaughtUp" }
                            ?: "Tous les cours sont faits — bravo !",
                        style = SophiaTypography.bodyLarge,
                    )
                }
            } else {
                VerticalPager(
                    state = pagerState,
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(bottom = 96.dp),
                    pageSpacing = 12.dp,
                    beyondViewportPageCount = 1,
                ) { page ->
                    val course = cards[page]
                    TikTokCourseCard(
                        course = course,
                        language = language,
                        isFavorite = course.id in favoriteIds,
                        onToggleFavorite = { onToggleFavorite(course.id) },
                        onShare = { ShareHelper.shareCourse(context, course) },
                        onStart = { onStartCourse(course) },
                    )
                }
            }
        }
        if (showExplain) {
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
    course: Course,
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
                modifier = Modifier.fillMaxWidth()
                .weight(1f)
                .clip(RoundedCornerShape(topStart = 22.dp, topEnd = 22.dp)),
        ) {
            CourseImage(
                courseId = course.id,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop,
            )
            Box(
                    modifier = Modifier.fillMaxSize()
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
                    fontFamily = PlusJakartaSans,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium,
                )
                Spacer(Modifier.height(4.dp))
                Text(
                    text = course.title,
                    color = Color.White,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 24.sp,
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }

        Column(modifier = Modifier.padding(DS.Space.m)) {
            Text(
                text = course.description,
                style = SophiaTypography.bodyMedium,
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
                    text = course.readsCountShort,
                    style = SophiaTypography.labelMedium,
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
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 16.sp,
                )
            }
        }
    }
}
