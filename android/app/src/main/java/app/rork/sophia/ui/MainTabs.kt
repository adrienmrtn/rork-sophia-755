package app.rork.sophia.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoStories
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.RestartAlt
import androidx.compose.material.icons.filled.ViewModule
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Course
import app.rork.sophia.ui.collections.CollectionsScreen
import app.rork.sophia.ui.course.CourseScreen
import app.rork.sophia.ui.home.HomeTikTokScreen
import app.rork.sophia.ui.library.LibraryScreen
import app.rork.sophia.ui.profile.ProfileScreen
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.training.TrainingScreen

@Composable
fun MainTabs(
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    deepLinkCourseId: String?,
    onDeepLinkConsumed: () -> Unit,
    onResetOnboarding: () -> Unit,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val isPremium by storeViewModel.isPremium.collectAsState()
    val progress by app.progressManager.progress.collectAsState()
    var selectedTab by remember { mutableIntStateOf(0) }
    var selectedCourse by remember { mutableStateOf<Course?>(null) }
    var autoSwipeCourseId by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(deepLinkCourseId, language) {
        val id = deepLinkCourseId ?: return@LaunchedEffect
        ContentCatalog.course(context, language, id)?.let { selectedCourse = it }
        onDeepLinkConsumed()
    }

    fun openCourse(course: Course) {
        if (!isPremium) {
            app.progressManager.incrementFreeCoursesOpened()
            app.progressManager.claimDailyFreeCourseIfNeeded(course.id)
        }
        selectedCourse = course
    }

    if (selectedCourse != null) {
        CourseScreen(
            course = selectedCourse!!,
            language = language,
            isPremium = isPremium,
            isDailyFreeCourse = app.progressManager.isDailyFreeCourse(selectedCourse!!.id),
            progressManager = app.progressManager,
            onDismiss = {
                val id = selectedCourse!!.id
                selectedCourse = null
                autoSwipeCourseId = id
            },
            onRequestPaywall = { /* paywalls wired in next iteration */ },
        )
        return
    }

    val tabs = listOf(
        Triple("tab.home", Icons.Filled.Home, 0),
        Triple("tab.library", Icons.Filled.AutoStories, 1),
        Triple("tab.collections", Icons.Filled.ViewModule, 2),
        Triple("tab.training", Icons.Filled.RestartAlt, 3),
        Triple("tab.profile", Icons.Filled.Person, 4),
    )

    Scaffold(
        containerColor = DS.canvas,
        bottomBar = {
            NavigationBar(containerColor = DS.canvas, contentColor = DS.accent) {
                tabs.forEach { (key, icon, index) ->
                    NavigationBarItem(
                        selected = selectedTab == index,
                        onClick = { selectedTab = index },
                        icon = { Icon(icon, contentDescription = null) },
                        label = {
                            Text(
                                text = StringStore.text(context, key, language),
                                fontFamily = PlusJakartaSans,
                                fontSize = 11.sp,
                                fontWeight = if (selectedTab == index) FontWeight.SemiBold else FontWeight.Normal,
                            )
                        },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = DS.accent,
                            selectedTextColor = DS.accent,
                            unselectedIconColor = DS.inkTertiary,
                            unselectedTextColor = DS.inkTertiary,
                            indicatorColor = DS.accentTint,
                        ),
                    )
                }
            }
        },
    ) { padding ->
        when (selectedTab) {
            0 -> HomeTikTokScreen(
                modifier = Modifier.padding(padding),
                language = language,
                favoriteIds = progress.favoriteCourseIds.toSet(),
                autoSwipeCourseId = autoSwipeCourseId,
                onAutoSwipeConsumed = { autoSwipeCourseId = null },
                onToggleFavorite = { app.progressManager.toggleFavorite(it) },
                onStartCourse = { openCourse(it) },
            )
            1 -> LibraryScreen(
                modifier = Modifier.padding(padding),
                language = language,
                progress = progress,
                onOpenCourse = { openCourse(it) },
            )
            2 -> CollectionsScreen(
                modifier = Modifier.padding(padding),
                language = language,
                progress = progress,
                onOpenCourse = { openCourse(it) },
            )
            3 -> TrainingScreen(
                modifier = Modifier.padding(padding),
                language = language,
                isPremium = isPremium,
                progress = progress,
            )
            4 -> ProfileScreen(
                modifier = Modifier.padding(padding),
                language = language,
                progress = progress,
                isPremium = isPremium,
                onLanguageChange = { app.languageManager.setLanguage(it) },
                onResetOnboarding = onResetOnboarding,
                onOpenCourse = { openCourse(it) },
            )
        }
    }
}
