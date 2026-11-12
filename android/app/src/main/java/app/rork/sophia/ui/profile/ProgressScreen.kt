package app.rork.sophia.ui.profile

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
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
import app.rork.sophia.domain.displayNameIn
import app.rork.sophia.domain.formatted
import app.rork.sophia.ui.components.dsPopIn
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.components.streakWeekFirstDay
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import java.time.LocalDate
import java.time.temporal.ChronoUnit

/** Le safran des illustrations du site. */
private val SAFFRON = Color(0xFFF2B134)

/** L'illustration ronde d'une matière (celle de son badge). */
private fun subjectArt(subject: Subject): Int = when (subject) {
    Subject.HISTOIRE -> R.drawable.badge_subject_histoire
    Subject.SCIENCES -> R.drawable.badge_subject_sciences
    Subject.LITTERATURE -> R.drawable.badge_subject_litterature
    Subject.ART -> R.drawable.badge_subject_art
    Subject.MYTHOLOGIE -> R.drawable.badge_subject_mythologie
    Subject.COMPRENDRE_LE_MONDE -> R.drawable.badge_subject_comprendrelemonde
}

/**
 * La page « Ma progression » dans le design « Elevate arrondi » : l'illustration papier du site
 * en bandeau, le niveau et sa jauge qui se remplit, la série avec ses sept jours, quatre
 * compteurs qui défilent, l'avancement par matière et les derniers quiz. Ouverte depuis la
 * carte illustrée du profil ; chaque bloc arrive à son tour.
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
            .padding(bottom = 40.dp),
    ) {
        // L'illustration papier du site, en bandeau bord à bord ; le retour posé dessus.
        Box(modifier = Modifier.fillMaxWidth().height(220.dp)) {
            Image(
                painter = painterResource(R.drawable.progress_hero),
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize(),
            )
            ProfileRoundButton(
                icon = Icons.AutoMirrored.Filled.ArrowBack,
                contentDescription = StringStore.text(context, "elevateProfile.back", language),
                onClick = onBack,
                modifier = Modifier.align(Alignment.TopStart).padding(start = 20.dp, top = 12.dp),
            )
        }

        Column(modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp)) {
            Text(
                text = StringStore.text(context, "progress.title", language),
                modifier = Modifier.padding(top = 18.dp).dsStagger(1).semantics { heading() },
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 28.sp,
                lineHeight = 34.sp,
                color = DS.ink,
            )

            // Le niveau : sa pastille, le rang, le @, et la jauge vers le niveau suivant.
            Column(
                modifier = Modifier.fillMaxWidth().padding(top = 14.dp).dsStagger(2).sophiaCard().padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    Box(
                        modifier = Modifier
                            .dsPopIn(delayMillis = 200)
                            .size(64.dp)
                            .clip(CircleShape)
                            .background(DS.accent)
                            .clearAndSetSemantics { },
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
                    Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Text(
                            text = StringStore.text(context, "path.levelCaption", language, level.level),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 17.sp,
                            color = DS.ink,
                        )
                        Text(
                            text = StringStore.text(context, "globalRank.${level.rank.storageKey}", language),
                            fontFamily = PlusJakartaSans,
                            fontSize = 15.sp,
                            color = DS.inkSecondary,
                        )
                        handle?.takeIf { it.isNotBlank() }?.let {
                            Text(
                                text = "@$it",
                                fontFamily = PlusJakartaSans,
                                fontWeight = FontWeight.Bold,
                                fontSize = 13.sp,
                                color = DS.accent,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                            )
                        }
                    }
                }
                ProfileFillBar(fraction = levelFraction, height = 8.dp, delayMillis = 300)
                Text(
                    text = "${level.xpIntoLevel.formatted(language)} / ${level.xpForLevel.formatted(language)} XP",
                    fontFamily = PlusJakartaSans,
                    fontSize = 13.sp,
                    color = DS.inkSecondary,
                )
            }

            // La série : son compteur et ses sept jours.
            Column(
                modifier = Modifier.fillMaxWidth().padding(top = 10.dp).dsStagger(3).sophiaCard().padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Row(
                    modifier = Modifier.semantics(mergeDescendants = true) { },
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    // Flamme fixe : pas d'animation en boucle sur cette page.
                    Icon(Icons.Filled.LocalFireDepartment, contentDescription = null, tint = SAFFRON, modifier = Modifier.size(20.dp))
                    Text(
                        text = StringStore.text(context, "friends.stats.streak", language),
                        modifier = Modifier.weight(1f),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp,
                        color = DS.ink,
                    )
                    val streakStyle = TextStyle(fontFamily = PlusJakartaSans, fontWeight = FontWeight.ExtraBold, fontSize = 15.sp)
                    ProfileCountText(value = progress.streak, style = streakStyle)
                    Text(
                        text = StringStore.text(
                            context,
                            if (progress.streak <= 1) "common.streak.day" else "common.streak.days",
                            language,
                        ),
                        style = streakStyle,
                        color = DS.ink,
                    )
                }
                ProgressWeekStrip(streak = progress.streak, lastActiveDate = progress.lastActiveDate, language = language)
            }

            // Quatre compteurs, deux par ligne.
            Column(
                modifier = Modifier.padding(top = 10.dp).dsStagger(4),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    ProgressStatTile(
                        value = completedIds.size,
                        label = StringStore.text(context, "profile.stats.coursesDone", language),
                        modifier = Modifier.weight(1f),
                    )
                    ProgressStatTile(
                        value = progress.completedQuizCourseIds.size,
                        label = StringStore.text(context, "progress.stats.quizzes", language),
                        modifier = Modifier.weight(1f),
                    )
                }
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    ProgressStatTile(
                        value = successPercent,
                        label = StringStore.text(context, "progress.stats.successRate", language),
                        modifier = Modifier.weight(1f),
                        format = { "$it%" },
                    )
                    ProgressStatTile(
                        value = progress.globalXP,
                        label = StringStore.text(context, "progress.stats.xp", language),
                        modifier = Modifier.weight(1f),
                        format = { it.formatted(language) },
                        haptics = true,
                    )
                }
            }

            // Par matière : les cours terminés sur ceux du catalogue.
            if (summaries.isNotEmpty()) {
                Column(
                    modifier = Modifier.padding(top = 24.dp).dsStagger(5),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    ProfileSectionHeader(title = StringStore.text(context, "progress.subjects.title", language))
                    var shownIndex = 0
                    Subject.entries.forEach { subject ->
                        val inSubject = remember(summaries, subject) { summaries.filter { it.subject == subject.storageKey } }
                        if (inSubject.isEmpty()) return@forEach
                        val done = inSubject.count { it.id in completedIds }
                        val barDelay = 300 + shownIndex * 60
                        shownIndex += 1
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .sophiaCard()
                                .padding(12.dp)
                                .semantics(mergeDescendants = true) { },
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp),
                        ) {
                            Image(
                                painter = painterResource(subjectArt(subject)),
                                contentDescription = null,
                                contentScale = ContentScale.Crop,
                                modifier = Modifier.size(36.dp).clip(CircleShape),
                            )
                            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
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
                                        fontWeight = FontWeight.ExtraBold,
                                        fontSize = 11.sp,
                                        color = DS.ink,
                                        maxLines = 1,
                                        modifier = Modifier
                                            .clip(CircleShape)
                                            .background(DS.accentTint)
                                            .padding(horizontal = 8.dp, vertical = 2.dp),
                                    )
                                }
                                // La barre garde la couleur de la matière.
                                ProfileFillBar(
                                    fraction = done.toFloat() / inSubject.size,
                                    height = 6.dp,
                                    tint = subject.color,
                                    delayMillis = barDelay,
                                )
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
                Column(
                    modifier = Modifier.padding(top = 24.dp).dsStagger(6),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    ProfileSectionHeader(title = StringStore.text(context, "progress.quizzes.title", language))
                    Column(modifier = Modifier.fillMaxWidth().sophiaCard()) {
                        recentQuizzes.forEachIndexed { index, (course, state) ->
                            if (index > 0) ProfileRowDivider()
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .profileRowPress(onClick = { onOpenCourse(course.id) })
                                    .padding(horizontal = 16.dp, vertical = 13.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(12.dp),
                            ) {
                                Text(
                                    text = stripInlineMarkup(course.title),
                                    fontFamily = PlusJakartaSans,
                                    fontWeight = FontWeight.Bold,
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
                                    color = DS.accent,
                                    maxLines = 1,
                                )
                                ProfileRowChevron()
                            }
                        }
                    }
                }
            }
        }
    }
}

/** Un compteur de la page : la valeur qui défile, son libellé dessous. */
@Composable
private fun ProgressStatTile(
    value: Int,
    label: String,
    modifier: Modifier = Modifier,
    format: ((Int) -> String)? = null,
    haptics: Boolean = false,
) {
    Column(
        modifier = modifier
            .heightIn(min = 80.dp)
            .sophiaCard()
            .padding(14.dp)
            .semantics(mergeDescendants = true) { },
        verticalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        ProfileCountText(
            value = value,
            format = format,
            haptics = haptics,
            style = TextStyle(fontFamily = PlusJakartaSans, fontWeight = FontWeight.ExtraBold, fontSize = 22.sp),
        )
        Text(
            text = label,
            fontFamily = PlusJakartaSans,
            fontSize = 13.sp,
            lineHeight = 17.sp,
            color = DS.inkSecondary,
        )
    }
}

/**
 * Les sept jours de la série, à partir de son premier jour : un jour tenu est un disque bleu
 * coché, aujourd'hui est cerclé de safran, les jours à venir sont estompés. Les pastilles
 * arrivent l'une après l'autre.
 */
@Composable
private fun ProgressWeekStrip(streak: Int, lastActiveDate: String?, language: AppLanguage) {
    val today = remember { LocalDate.now() }
    val last = remember(lastActiveDate) { lastActiveDate?.let { runCatching { LocalDate.parse(it) }.getOrNull() } }
    val firstDay = streakWeekFirstDay(streak, last, today)
    Row(modifier = Modifier.fillMaxWidth().clearAndSetSemantics { }) {
        repeat(7) { i ->
            val date = firstDay.plusDays(i.toLong())
            val isToday = date == today
            val isFuture = date.isAfter(today)
            val isDone = !isFuture && last != null && !date.isAfter(last) && ChronoUnit.DAYS.between(date, last) < streak
            Column(
                modifier = Modifier.weight(1f),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(5.dp),
            ) {
                Box(
                    modifier = Modifier
                        .dsPopIn(delayMillis = 250 + i * 40)
                        .alpha(if (isFuture) 0.55f else 1f)
                        .size(30.dp)
                        .clip(CircleShape)
                        .background(if (isDone) DS.accent else DS.surface)
                        .then(
                            when {
                                isToday -> Modifier.border(2.5.dp, SAFFRON, CircleShape)
                                isDone -> Modifier
                                else -> Modifier.border(1.5.dp, DS.hairline, CircleShape)
                            },
                        ),
                    contentAlignment = Alignment.Center,
                ) {
                    if (isDone) {
                        Icon(Icons.Filled.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(14.dp))
                    }
                }
                Text(
                    text = date.dayOfWeek.displayNameIn(language, java.time.format.TextStyle.NARROW),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 11.sp,
                    color = if (isToday) DS.ink else DS.inkSecondary,
                )
            }
        }
    }
}
