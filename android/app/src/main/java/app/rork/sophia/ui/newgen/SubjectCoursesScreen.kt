package app.rork.sophia.ui.newgen

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.rememberCourseSummaries
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.Subject
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans

/**
 * Les cours d'une matière, ouverts depuis la grille de l'onglet Explorer : une liste de lignes
 * compactes (créateur · sous-catégorie, coche « lu »), chacune menant à la fiche du cours.
 * iOS a `SubjectCoursesView` pour cela ; Android n'avait pas d'écran par matière.
 */
@Composable
fun SubjectCoursesScreen(
    subject: Subject,
    language: AppLanguage,
    progress: UserProgress,
    onBack: () -> Unit,
    onOpenCourse: (CourseSummary) -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val summaries = rememberCourseSummaries(language)
    val courses = remember(summaries, subject) { summaries.filter { it.subjectEnum == subject } }
    val name = StringStore.text(context, "subject.${subject.storageKey}.short", language)

    LazyColumn(
        modifier = modifier.fillMaxSize().background(DS.canvas),
        contentPadding = PaddingValues(start = 20.dp, end = 20.dp, top = 12.dp, bottom = 32.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item(key = "header") {
            NewGenBackHeader(language = language, onBack = onBack, title = name)
        }
        item(key = "count") {
            Row(
                modifier = Modifier.fillMaxWidth().padding(bottom = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Box(modifier = Modifier.size(10.dp).clip(CircleShape).background(subject.color))
                Text(
                    text = StringStore.text(context, "subject.courses.count", language, courses.size),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 13.sp,
                    color = DS.inkSecondary,
                )
            }
        }
        items(courses, key = { it.id }) { course ->
            val identity = remember(course.id) { CreatorIdentity.forCourse(context.applicationContext, course.id) }
            val completed = progress.courseProgress[course.id]?.isCompleted == true
            val detail = if (completed) {
                StringStore.text(context, "common.read", language)
            } else {
                course.subcategory.takeIf { it.isNotBlank() }
            }
            CompactCourseRow(
                course = course,
                meta = listOfNotNull(identity.name, detail).joinToString(" · "),
                onTap = { onOpenCourse(course) },
                trailing = if (completed) ({ ReadCheck(language = language) }) else null,
            )
        }
    }
}
