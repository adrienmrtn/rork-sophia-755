package app.rork.sophia.ui.profile

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.GpsFixed
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.R
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.rememberCourseSummaries
import app.rork.sophia.data.stripInlineMarkup
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Subject
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.domain.formatted
import app.rork.sophia.ui.components.AnimatedFlameBadge
import app.rork.sophia.ui.components.StreakWeekStrip
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.newgen.NewGenBackHeader
import app.rork.sophia.ui.newgen.NewGenSectionTitle
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans

/** Le safran des illustrations du site. */
private val SAFFRON = Color(0xFFF2B134)

/**
 * La page « Ma progression », refaite comme sur iOS : l'illustration papier du site, le niveau
 * et sa jauge, la série avec ses sept jours, quatre compteurs, l'avancement par matière et les
 * derniers quiz. Ouverte depuis la carte illustrée du profil.
 */
@Composable
fun ProgressScreen(
    language: AppLanguage,
    progress: UserProgress,
    onBack: () -> Unit,
    onOpenCourse: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val app = context.applicationContext as SophiaApplication
    val handle by app.socialService.myHandle.collectAsState()
    val summaries = rememberCourseSummaries(language)
    val level = ProgressManager.globalLevelProgress(progress.globalXP)
    val levelFraction = if (level.xpForLevel == 0) 0f else level.xpIntoLevel.toFloat() / level.xpForLevel
    val completedIds = remember(progress.courseProgress) { progress.courseProgress.filterValues { it.isCompleted }.keys }

    // Les quiz : combien sont faits, et la part de bonnes réponses sur les meilleurs scores.
    val quizzed = remember(progress.courseProgress) { progress.courseProgress.filterValues { it.quizMaxPoints > 0 } }
    val successPercent = remember(quizzed) {
        val max = quizzed.values.sumOf { it.quizMaxPoints }
        if (max == 0) 0 else (quizzed.values.sumOf { it.bestQuizScore } * 100f / max).toInt()
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState())
            .padding(start = 20.dp, end = 20.dp, top = 12.dp, bottom = 40.dp),
        verticalArrangement = Arrangement.spacedBy(22.dp),
    ) {
        NewGenBackHeader(language = language, onBack = onBack)

        // L'illustration papier du site, en carte arrondie.
        Image(
            painter = painterResource(R.drawable.progress_hero),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(max = 300.dp)
                .aspectRatio(3f / 2f)
                .clip(RoundedCornerShape(28.dp)),
        )

        Text(
            text = StringStore.text(context, "progress.title", language),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 34.sp,
            lineHeight = 40.sp,
            color = DS.ink,
        )

        // Le niveau : sa pastille, le rang, le @, et la jauge vers le niveau suivant.
        Column(
            modifier = Modifier.fillMaxWidth().sophiaCard().padding(DS.Space.l),
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                Box {
                    Box(
                        modifier = Modifier.size(68.dp).clip(CircleShape).background(DS.accent),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(
                            text = "${level.level}",
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 26.sp,
                            color = Color.White,
                            maxLines = 1,
                        )
                    }
                    Box(
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .offset(x = 4.dp, y = (-4).dp)
                            .size(24.dp)
                            .clip(CircleShape)
                            .background(DS.surface)
                            .padding(2.dp)
                            .clip(CircleShape)
                            .background(SAFFRON),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(Icons.Filled.Star, contentDescription = null, tint = DS.accent, modifier = Modifier.size(12.dp))
                    }
                }
                Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(
                        text = StringStore.text(context, "path.levelCaption", language, level.level),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 22.sp,
                        color = DS.ink,
                    )
                    Text(
                        text = StringStore.text(context, "globalRank.${level.rank.storageKey}", language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Medium,
                        fontSize = 15.sp,
                        color = DS.inkSecondary,
                    )
                    handle?.takeIf { it.isNotBlank() }?.let {
                        Text(
                            text = "@$it",
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 15.sp,
                            color = DS.accentSoft,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                }
            }
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                ProgressPageBar(fraction = levelFraction, tint = DS.accent, height = 10)
                Text(
                    text = "${level.xpIntoLevel.formatted(language)} / ${level.xpForLevel.formatted(language)} XP",
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 13.sp,
                    color = DS.inkSecondary,
                )
            }
        }

        // La série : son compteur et ses sept jours.
        Column(
            modifier = Modifier.fillMaxWidth().sophiaCard().padding(DS.Space.l),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                AnimatedFlameBadge(size = 22.dp, showGlow = false, animated = false, modifier = Modifier.size(28.dp))
                Text(
                    text = "${progress.streak}",
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 32.sp,
                    color = DS.ink,
                )
                Text(
                    text = StringStore.text(context, "friends.stats.streak", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Medium,
                    fontSize = 15.sp,
                    color = DS.inkSecondary,
                )
            }
            StreakWeekStrip(streak = progress.streak, lastActiveDate = progress.lastActiveDate, language = language)
        }

        // Quatre compteurs, deux par ligne.
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                StatTile(Icons.AutoMirrored.Filled.MenuBook, "${completedIds.size}", StringStore.text(context, "profile.stats.coursesDone", language), Modifier.weight(1f))
                StatTile(Icons.Filled.Verified, "${progress.completedQuizCourseIds.size}", StringStore.text(context, "progress.stats.quizzes", language), Modifier.weight(1f))
            }
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                StatTile(Icons.Filled.GpsFixed, "$successPercent%", StringStore.text(context, "progress.stats.successRate", language), Modifier.weight(1f))
                StatTile(Icons.Filled.Bolt, progress.globalXP.formatted(language), StringStore.text(context, "progress.stats.xp", language), Modifier.weight(1f))
            }
        }

        // Par matière : les cours terminés sur ceux du catalogue.
        if (summaries.isNotEmpty()) {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                NewGenSectionTitle(text = StringStore.text(context, "progress.subjects.title", language))
                Column(modifier = Modifier.fillMaxWidth().sophiaCard().padding(DS.Space.l), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    Subject.entries.forEach { subject ->
                        val inSubject = remember(summaries, subject) { summaries.filter { it.subject == subject.storageKey } }
                        if (inSubject.isEmpty()) return@forEach
                        val done = inSubject.count { it.id in completedIds }
                        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = StringStore.text(context, "subject.${subject.storageKey}", language),
                                    fontFamily = PlusJakartaSans,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 15.sp,
                                    color = DS.ink,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis,
                                    modifier = Modifier.weight(1f),
                                )
                                Text(
                                    text = "$done / ${inSubject.size}",
                                    fontFamily = PlusJakartaSans,
                                    fontWeight = FontWeight.SemiBold,
                                    fontSize = 13.sp,
                                    color = DS.inkSecondary,
                                )
                            }
                            ProgressPageBar(fraction = done.toFloat() / inSubject.size, tint = subject.color, height = 8)
                        }
                    }
                }
            }
        }

        // Les derniers quiz, du plus récent au plus ancien.
        val recentQuizzes = remember(quizzed, summaries) {
            quizzed.entries
                .filter { it.value.lastQuizDate != null }
                .sortedByDescending { it.value.lastQuizDate }
                .mapNotNull { entry -> summaries.firstOrNull { it.id == entry.key }?.let { it to entry.value } }
                .take(5)
        }
        if (recentQuizzes.isNotEmpty()) {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                NewGenSectionTitle(text = StringStore.text(context, "progress.quizzes.title", language))
                Column(modifier = Modifier.fillMaxWidth().sophiaCard()) {
                    recentQuizzes.forEachIndexed { index, (course, state) ->
                        if (index > 0) Box(modifier = Modifier.fillMaxWidth().height(1.dp).background(DS.hairline))
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .softPress(onClick = { onOpenCourse(course.id) })
                                .padding(horizontal = 16.dp, vertical = 14.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp),
                        ) {
                            Text(
                                text = stripInlineMarkup(course.title),
                                fontFamily = PlusJakartaSans,
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 15.sp,
                                lineHeight = 20.sp,
                                color = DS.ink,
                                maxLines = 2,
                                overflow = TextOverflow.Ellipsis,
                                modifier = Modifier.weight(1f),
                            )
                            Text(
                                text = "${state.bestQuizScore} / ${state.quizMaxPoints}",
                                fontFamily = PlusJakartaSans,
                                fontWeight = FontWeight.ExtraBold,
                                fontSize = 15.sp,
                                color = DS.accentSoft,
                                maxLines = 1,
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun StatTile(icon: ImageVector, value: String, label: String, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier.heightIn(min = 104.dp).sophiaCard().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Box(
            modifier = Modifier.size(36.dp).clip(CircleShape).background(DS.accentTint),
            contentAlignment = Alignment.Center,
        ) {
            Icon(icon, contentDescription = null, tint = DS.accent, modifier = Modifier.size(17.dp))
        }
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                text = value,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 22.sp,
                color = DS.ink,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                text = label,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Medium,
                fontSize = 13.sp,
                lineHeight = 17.sp,
                color = DS.inkSecondary,
            )
        }
    }
}

/** Une jauge qui se remplit à sa première apparition. */
@Composable
private fun ProgressPageBar(fraction: Float, tint: Color, height: Int) {
    var shown by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { shown = true }
    val width by animateFloatAsState(
        targetValue = if (shown) fraction.coerceIn(0f, 1f) else 0f,
        animationSpec = tween(durationMillis = 800),
        label = "progressBar",
    )
    Box(modifier = Modifier.fillMaxWidth().height(height.dp).clip(CircleShape).background(DS.surfaceMuted)) {
        Box(modifier = Modifier.fillMaxWidth(width).fillMaxHeight().clip(CircleShape).background(tint))
    }
}
