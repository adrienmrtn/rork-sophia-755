package app.rork.sophia.ui.onboarding

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.absoluteOffset
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.LearningCollection
import app.rork.sophia.domain.PathNodeState
import app.rork.sophia.ui.path.PathPalette
import app.rork.sophia.ui.path.PathPodFace
import app.rork.sophia.ui.path.PathPulseHalo
import app.rork.sophia.ui.path.pathIcon
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans

private val PREVIEW_PLATE_DEPTH = 6.dp

/** Horizontal shift of each row, as a fraction of the amplitude: left, right, left. */
private val PREVIEW_ZIGZAG = listOf(-0.55f, 0.6f, -0.55f)

private val PREVIEW_STATES = listOf(PathNodeState.COMPLETED, PathNodeState.AVAILABLE, PathNodeState.LOCKED)

/**
 * Preview of the Parcours for the « personalized route » page, as on iOS
 * (`OnboardingV2PathPreview`): three pods joined by the trail (a finished course, the course
 * to play with its halo, the next one locked), titled with the first three courses of the
 * first level. Same drawing as the tab, tightened to fit the page, without banner.
 */
@Composable
internal fun OnboardingPathPreview(
    language: AppLanguage,
    width: Dp,
    height: Dp,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    var courses by remember(language) {
        mutableStateOf(
            previewCourses(
                ContentCatalog.cachedCollections(language),
                ContentCatalog.cachedSummaries(language)?.associateBy { it.id },
            ),
        )
    }
    LaunchedEffect(language) {
        if (courses.isNotEmpty()) return@LaunchedEffect
        val collections = ContentCatalog.collectionsAsync(context.applicationContext, language)
        val summaries = ContentCatalog.summariesAsync(context.applicationContext, language)
        courses = previewCourses(collections, summaries.associateBy { it.id })
    }

    // Three rows in the height given; below 72 dp a row (a very short window) the titles go
    // rather than overlap the next row.
    val rowHeight = (height / 3).coerceIn(56.dp, 112.dp)
    val podSize = when {
        rowHeight >= 100.dp -> 60.dp
        rowHeight >= 84.dp -> 54.dp
        else -> 44.dp
    }
    val amplitude = minOf(72.dp, width * 0.2f)
    val podAreaHeight = podSize + PREVIEW_PLATE_DEPTH + 8.dp
    val showsCaptions = rowHeight >= 72.dp
    val captionLines = if (rowHeight >= 100.dp) 2 else 1

    Box(
        modifier = modifier
            .size(width = width, height = height)
            .clearAndSetSemantics {},
        contentAlignment = Alignment.Center,
    ) {
        if (courses.isEmpty()) return@Box
        Box(modifier = Modifier.width(width).height(rowHeight * courses.size)) {
            val base = DS.hairline
            val doneTint = PathPalette.tint(courses.first().subjectEnum)
            Canvas(modifier = Modifier.width(width).height(rowHeight * courses.size)) {
                val stroke = Stroke(width = 4.dp.toPx(), cap = StrokeCap.Round)
                fun center(step: Int) = Offset(
                    x = size.width / 2f + (amplitude * PREVIEW_ZIGZAG[step % PREVIEW_ZIGZAG.size]).toPx(),
                    y = (rowHeight * step).toPx() + ((podAreaHeight - PREVIEW_PLATE_DEPTH) / 2).toPx(),
                )
                drawPath(segments(0, courses.size - 1, ::center), base, style = stroke)
                // The coloured line behind the finished course, up to the one to play.
                if (courses.size > 1) drawPath(segments(0, 1, ::center), doneTint, style = stroke)
            }
            courses.forEachIndexed { index, course ->
                val state = PREVIEW_STATES[minOf(index, PREVIEW_STATES.lastIndex)]
                val tint = PathPalette.tint(course.subjectEnum)
                val isCurrent = state == PathNodeState.AVAILABLE
                // No fixed height: as on iOS, a two-line title may run below its row, beside
                // the next pod rather than cut to one line.
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .absoluteOffset(
                            x = amplitude * PREVIEW_ZIGZAG[index % PREVIEW_ZIGZAG.size],
                            y = rowHeight * index,
                        )
                        .zIndex(if (isCurrent) 1f else 0f),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Box(modifier = Modifier.height(podAreaHeight), contentAlignment = Alignment.Center) {
                        if (isCurrent) {
                            PathPulseHalo(
                                tint = tint,
                                diameter = podSize,
                                modifier = Modifier.offset(y = -PREVIEW_PLATE_DEPTH / 2),
                            )
                        }
                        Box(modifier = Modifier.size(width = podSize, height = podSize + PREVIEW_PLATE_DEPTH)) {
                            Box(
                                modifier = Modifier
                                    .offset(y = PREVIEW_PLATE_DEPTH)
                                    .size(podSize)
                                    .clip(CircleShape)
                                    .background(
                                        when (state) {
                                            PathNodeState.LOCKED -> PathPalette.lockedPlate
                                            PathNodeState.AVAILABLE -> PathPalette.availablePlate
                                            PathNodeState.COMPLETED -> PathPalette.plate(tint)
                                        },
                                    ),
                            )
                            PathPodFace(
                                state = state,
                                tint = tint,
                                icon = course.subjectEnum.pathIcon,
                                diameter = podSize,
                            )
                        }
                    }
                    if (showsCaptions) {
                        Spacer(Modifier.height(6.dp))
                        Text(
                            text = course.title,
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 11.sp,
                            lineHeight = 14.sp,
                            color = if (state == PathNodeState.LOCKED) DS.inkTertiary else DS.inkSecondary,
                            textAlign = TextAlign.Center,
                            maxLines = captionLines,
                            overflow = TextOverflow.Ellipsis,
                            modifier = Modifier.width(130.dp),
                        )
                    }
                }
            }
        }
    }
}

/** The curves joining rows [from] to [to], with the preview's geometry. */
private fun DrawScope.segments(from: Int, to: Int, center: (Int) -> Offset): Path {
    val path = Path()
    for (step in from until to) {
        val start = center(step)
        val end = center(step + 1)
        val midY = (start.y + end.y) / 2f
        path.moveTo(start.x, start.y)
        path.cubicTo(start.x, midY, end.x, midY, end.x, end.y)
    }
    return path
}

/**
 * The first three courses of the first Parcours level (the first collection with three
 * courses the language carries, else the first with any), or none until both lists are in.
 */
private fun previewCourses(
    collections: List<LearningCollection>?,
    coursesById: Map<String, CourseSummary>?,
): List<CourseSummary> {
    if (collections == null || coursesById == null) return emptyList()
    val resolved = collections.map { collection -> collection.courseIds.mapNotNull { coursesById[it] } }
    val level = resolved.firstOrNull { it.size >= 3 } ?: resolved.firstOrNull { it.isNotEmpty() } ?: return emptyList()
    return level.take(3)
}
