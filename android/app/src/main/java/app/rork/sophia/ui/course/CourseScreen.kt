package app.rork.sophia.ui.course

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
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Course
import app.rork.sophia.domain.FreemiumGate
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

@Composable
fun CourseScreen(
    course: Course,
    language: AppLanguage,
    isPremium: Boolean,
    isDailyFreeCourse: Boolean,
    progressManager: ProgressManager,
    onDismiss: () -> Unit,
    onRequestPaywall: (String) -> Unit,
) {
    val context = LocalContext.current
    var showQuiz by remember { mutableStateOf(false) }
    val pages = remember(course.id, language) {
        buildPages(context, course, language)
    }
    val pagerState = rememberPagerState(pageCount = { pages.size.coerceAtLeast(1) })
    val scope = rememberCoroutineScope()

    if (showQuiz) {
        QuizScreen(
            course = course,
            language = language,
            isPremium = isPremium,
            progressManager = progressManager,
            onRequestPaywall = { onRequestPaywall("quizz") },
            onFinished = onDismiss,
        )
        return
    }

    LaunchedEffect(pagerState.currentPage) {
        progressManager.updateLessonIndex(course.id, pagerState.currentPage)
    }

    Column(modifier = Modifier.fillMaxSize().background(DS.canvas)) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 8.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(onClick = onDismiss) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = DS.ink)
            }
            Text(
                text = course.title,
                style = SophiaTypography.titleMedium,
                maxLines = 1,
                modifier = Modifier.weight(1f),
            )
        }
        LinearProgressIndicator(
            progress = {
                if (pages.isEmpty()) 0f
                else (pagerState.currentPage + 1).toFloat() / pages.size
            },
            modifier = Modifier.fillMaxWidth().padding(horizontal = DS.Space.l),
            color = DS.accent,
            trackColor = DS.hairline,
            strokeCap = StrokeCap.Round,
        )

        HorizontalPager(
            state = pagerState,
            modifier = Modifier.weight(1f),
            userScrollEnabled = true,
        ) { index ->
            val locked = FreemiumGate.isLessonContentLocked(index, isPremium, isDailyFreeCourse)
            val page = pages.getOrNull(index) ?: return@HorizontalPager
            Box(modifier = Modifier.fillMaxSize()) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .padding(DS.Space.l),
                ) {
                    Text(text = page.title, style = SophiaTypography.titleLarge)
                    Spacer(Modifier.height(16.dp))
                    Text(
                        text = page.body,
                        style = SophiaTypography.bodyLarge,
                        color = if (locked) DS.inkTertiary else DS.ink,
                    )
                }
                if (locked) {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(DS.canvas.copy(alpha = 0.92f))
                            .padding(DS.Space.l),
                        verticalArrangement = Arrangement.Center,
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        Text(
                            text = StringStore.text(context, "home.locked", language),
                            style = SophiaTypography.titleMedium,
                        )
                        Spacer(Modifier.height(12.dp))
                        Button(
                            onClick = { onRequestPaywall("debloquer_cours") },
                            colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
                            shape = DS.controlShape,
                        ) {
                            Text(
                                text = "Premium",
                                fontFamily = PlusJakartaSans,
                                fontWeight = FontWeight.SemiBold,
                                color = Color.White,
                            )
                        }
                    }
                }
            }
        }

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(DS.Space.l),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            val isLast = pagerState.currentPage >= pages.lastIndex
            Button(
                onClick = {
                    if (isLast) {
                        if (FreemiumGate.canCompleteCourse(isPremium, isDailyFreeCourse)) {
                            progressManager.markCourseCompleted(course.id)
                            if (course.hasQuiz) showQuiz = true else onDismiss()
                        } else {
                            onRequestPaywall("debloquer_cours")
                        }
                    } else {
                        scope.launch { pagerState.animateScrollToPage(pagerState.currentPage + 1) }
                    }
                },
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = DS.controlShape,
                colors = ButtonDefaults.buttonColors(containerColor = DS.accent, contentColor = Color.White),
            ) {
                Text(
                    text = when {
                        !isLast -> StringStore.text(context, "course.continue", language)
                            .takeIf { it != "course.continue" } ?: "Continuer"
                        course.hasQuiz -> StringStore.text(context, "course.quiz", language)
                            .takeIf { it != "course.quiz" } ?: "Quiz"
                        else -> StringStore.text(context, "course.finish", language)
                            .takeIf { it != "course.finish" } ?: "Terminer"
                    },
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 16.sp,
                )
            }
        }
    }
}

private data class ReaderPage(val title: String, val body: String)

private fun buildPages(
    context: android.content.Context,
    course: Course,
    language: AppLanguage,
): List<ReaderPage> {
    val raw = ContentCatalog.structuredContentJson(context, language, course.id)
    if (raw != null) {
        return try {
            val root = Json.parseToJsonElement(raw).jsonObject
            val sections = root["sections"]?.jsonArray.orEmpty()
            sections.mapNotNull { el ->
                val obj = el.jsonObject
                val title = obj["title"]?.jsonPrimitive?.content ?: return@mapNotNull null
                val blocks = obj["blocks"]?.jsonArray.orEmpty()
                val body = blocks.mapNotNull { block ->
                    val b = block.jsonObject
                    when (b["type"]?.jsonPrimitive?.content) {
                        "paragraph", "funFact", "takeaway", "quote" ->
                            b["text"]?.jsonPrimitive?.content
                        else -> null
                    }
                }.joinToString("\n\n")
                ReaderPage(title, body.ifBlank { "…" })
            }
        } catch (_: Exception) {
            null
        } ?: course.lessons.map { ReaderPage(it.title, it.content) }
    }
    return course.lessons.map { ReaderPage(it.title, it.content) }
}
