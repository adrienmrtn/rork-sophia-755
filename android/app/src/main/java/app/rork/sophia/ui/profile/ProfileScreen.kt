package app.rork.sophia.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Course
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.SophiaTypography

@Composable
fun ProfileScreen(
    modifier: Modifier = Modifier,
    language: AppLanguage,
    progress: UserProgress,
    isPremium: Boolean,
    onLanguageChange: (AppLanguage) -> Unit,
    onResetOnboarding: () -> Unit,
    onOpenCourse: (Course) -> Unit,
) {
    val context = LocalContext.current
    val favorites = progress.favoriteCourseIds.mapNotNull {
        ContentCatalog.course(context, language, it)
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState())
            .padding(DS.Space.l),
    ) {
        Text(
            text = StringStore.text(context, "tab.profile", language),
            style = SophiaTypography.titleLarge,
        )
        Spacer(Modifier.height(16.dp))
        StatCard(
            title = "XP",
            value = progress.globalXP.toString(),
            subtitle = if (isPremium) "Premium" else "Free · streak ${progress.streak}",
        )
        Spacer(Modifier.height(16.dp))
        Text(text = StringStore.text(context, "language.section", language), style = SophiaTypography.titleMedium)
        Spacer(Modifier.height(8.dp))
        AppLanguage.entries.forEach { lang ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(DS.controlShape)
                    .background(if (lang == language) DS.accentTint else DS.surface)
                    .clickable { onLanguageChange(lang) }
                    .padding(horizontal = 14.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Text(text = lang.flag)
                Text(text = lang.displayName, style = SophiaTypography.bodyLarge)
            }
            Spacer(Modifier.height(6.dp))
        }
        Spacer(Modifier.height(16.dp))
        Text(text = "Favorites (${favorites.size})", style = SophiaTypography.titleMedium)
        favorites.take(8).forEach { course ->
            Text(
                text = course.title,
                style = SophiaTypography.bodyMedium,
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onOpenCourse(course) }
                    .padding(vertical = 8.dp),
            )
            HorizontalDivider(color = DS.hairline)
        }
        Spacer(Modifier.height(24.dp))
        Text(
            text = "Reset onboarding (debug)",
            style = SophiaTypography.labelLarge,
            color = DS.danger,
            modifier = Modifier.clickable(onClick = onResetOnboarding),
        )
    }
}

@Composable
private fun StatCard(title: String, value: String, subtitle: String) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(DS.cardShape)
            .background(DS.surface)
            .padding(DS.Space.m),
    ) {
        Text(text = title, style = SophiaTypography.labelMedium)
        Text(text = value, style = SophiaTypography.displayLarge)
        Text(text = subtitle, style = SophiaTypography.bodyMedium)
    }
}
