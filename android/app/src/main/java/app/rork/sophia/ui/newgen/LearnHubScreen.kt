package app.rork.sophia.ui.newgen

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.rememberCollections
import app.rork.sophia.data.rememberCourseSummaries
import app.rork.sophia.data.stripInlineMarkup
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.LearningPathEngine
import app.rork.sophia.domain.LearningPathSnapshot
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.components.CalmProgressBar
import app.rork.sophia.ui.components.ScreenTitle
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.uppercaseInApp

/**
 * L'onglet « Apprendre » : ce qui est commencé, puis deux portes vers les pages qui ne
 * changent pas, le Parcours (style Duolingo) et l'Entraînement.
 */
@Composable
fun LearnHubScreen(
    modifier: Modifier = Modifier,
    language: AppLanguage,
    progress: UserProgress,
    progressManager: ProgressManager,
    onResumeCourse: (CourseSummary) -> Unit,
    onOpenPath: () -> Unit,
    onOpenTraining: () -> Unit,
) {
    val context = LocalContext.current
    val summaries = rememberCourseSummaries(language)
    val collections = rememberCollections(language)
    val snapshot = remember(summaries, collections, progress.courseProgress, progress.pathLevelResults) {
        if (summaries.isEmpty() || collections.isEmpty()) {
            LearningPathSnapshot.EMPTY
        } else {
            val byId = summaries.associateBy { it.id }
            LearningPathEngine.snapshot(
                collections = collections,
                coursesById = byId,
                isCourseCompleted = { progress.courseProgress[it]?.isCompleted == true },
                isLevelPassed = { progress.pathLevelResults[it]?.isPassed == true },
            )
        }
    }
    val dueCount = remember(progress.trainingQuestionStates) { progressManager.dueTrainingQuestionIds().size }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState())
            .padding(bottom = 32.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp),
    ) {
        Column(
            modifier = Modifier.padding(start = 20.dp, end = 20.dp, top = 8.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            ScreenTitle(text = StringStore.text(context, "tab.learn", language))
            Text(
                text = StringStore.text(context, "learn.subtitle", language),
                fontFamily = PlusJakartaSans,
                fontSize = 17.sp,
                lineHeight = 24.sp,
                color = DS.inkSecondary,
            )
        }

        ResumeCoursesSection(language = language, progress = progress, summaries = summaries, onResume = onResumeCourse)

        // Parcours.
        val level = snapshot.activeLevel
        Column(
            modifier = Modifier
                .padding(horizontal = 20.dp)
                .fillMaxWidth()
                .softPress(onClick = onOpenPath)
                .sophiaCard()
                .padding(22.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            HubKicker(StringStore.text(context, "tab.path", language))
            if (level != null) {
                val completed = level.completedCourseCount
                val total = maxOf(1, level.courseCount)
                HubTitle(StringStore.text(context, "path.levelCaption", language, level.number))
                HubBody(StringStore.text(context, "learn.path.remaining", language, maxOf(0, level.courseCount - level.completedCourseCount)))
                CalmProgressBar(
                    fraction = completed.toFloat() / total,
                    height = 8.dp,
                    color = DS.accentSoft,
                    modifier = Modifier.padding(top = 4.dp),
                )
            } else {
                HubTitle(StringStore.text(context, if (snapshot.isEverythingPassed) "path.end.doneTitle" else "path.title", language))
                HubBody(StringStore.text(context, if (snapshot.isEverythingPassed) "path.end.doneBody" else "explain.path.body", language))
            }
        }

        // Entraînement.
        Column(
            modifier = Modifier
                .padding(horizontal = 20.dp)
                .fillMaxWidth()
                .softPress(onClick = onOpenTraining)
                .sophiaCard()
                .padding(22.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            HubKicker(StringStore.text(context, "tab.training", language))
            HubTitle(
                if (dueCount > 0) {
                    StringStore.text(context, "learn.training.due", language, dueCount)
                } else {
                    StringStore.text(context, "training.emptyTitle", language)
                },
            )
            HubBody(StringStore.text(context, "learn.training.body", language))
        }
    }
}

@Composable
private fun HubKicker(text: String) {
    Text(
        text = text.uppercaseInApp(),
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.Bold,
        fontSize = 12.sp,
        letterSpacing = 0.8.sp,
        color = DS.accentSoft,
    )
}

@Composable
private fun HubTitle(text: String) {
    Text(
        text = text,
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 28.sp,
        lineHeight = 34.sp,
        color = DS.ink,
    )
}

@Composable
private fun HubBody(text: String) {
    Text(
        text = text,
        fontFamily = PlusJakartaSans,
        fontSize = 17.sp,
        lineHeight = 24.sp,
        color = DS.inkSecondary,
    )
}

/**
 * « Reprendre » : les cours commencés, du plus avancé au moins avancé, en cartes horizontales
 * avec leur barre de progression. Partagé par l'onglet Apprendre et le profil.
 */
@Composable
fun ResumeCoursesSection(
    language: AppLanguage,
    progress: UserProgress,
    summaries: List<CourseSummary>,
    onResume: (CourseSummary) -> Unit,
    modifier: Modifier = Modifier,
    /** Marge du titre et des bords de la rangée ; 0 quand l'écran parent a déjà la sienne. */
    horizontalPadding: Dp = 20.dp,
) {
    val context = LocalContext.current
    val inProgress = remember(progress.courseProgress, summaries) {
        val byId = summaries.associateBy { it.id }
        progress.courseProgress.mapNotNull { (id, courseProgress) ->
            if (courseProgress.isCompleted || courseProgress.lastLessonIndex <= 0) return@mapNotNull null
            val course = byId[id] ?: return@mapNotNull null
            val count = maxOf(courseProgress.lessonCount, 1)
            Triple(course, courseProgress.lastLessonIndex, count)
        }.sortedByDescending { it.second.toDouble() / it.third }
    }
    if (inProgress.isEmpty()) return
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        NewGenSectionTitle(
            text = StringStore.text(context, "common.resume", language),
            modifier = Modifier.padding(horizontal = horizontalPadding),
        )
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState())
                .padding(horizontal = horizontalPadding, vertical = 4.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            inProgress.forEach { (course, index, count) ->
                ResumeCourseCard(
                    course = course,
                    language = language,
                    sectionIndex = index,
                    sectionCount = count,
                    onTap = { onResume(course) },
                )
            }
        }
    }
}

@Composable
private fun ResumeCourseCard(
    course: CourseSummary,
    language: AppLanguage,
    sectionIndex: Int,
    sectionCount: Int,
    onTap: () -> Unit,
) {
    val context = LocalContext.current
    val identity = remember(course.id) { CreatorIdentity.forCourse(context.applicationContext, course.id) }
    val shape = RoundedCornerShape(18.dp)
    Column(
        modifier = Modifier
            .width(220.dp)
            .softPress(onClick = onTap)
            .clip(shape)
            .background(DS.surface)
            .border(1.dp, DS.hairline, shape)
            .padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        CourseCover(courseId = course.id, modifier = Modifier.fillMaxWidth().aspectRatio(16f / 9f), cornerRadius = 14.dp)
        Text(
            text = stripInlineMarkup(course.title),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 15.sp,
            lineHeight = 20.sp,
            color = DS.ink,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            text = identity.name + " · " +
                NewGenFormat.section(context, minOf(sectionIndex + 1, sectionCount), sectionCount, language),
            fontFamily = PlusJakartaSans,
            fontSize = 12.sp,
            color = DS.inkSecondary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        CalmProgressBar(fraction = sectionIndex.toFloat() / maxOf(1, sectionCount), height = 6.dp, color = DS.accentSoft)
    }
}
