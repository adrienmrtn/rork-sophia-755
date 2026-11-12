package app.rork.sophia.ui.onboarding

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.dsHighlighted
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlinx.coroutines.delay

/** Length of a lesson, in minutes (the « 10 min » shown everywhere in the onboarding). */
private const val LESSON_MINUTES = 10

/** A book of the pile: width, thickness and grey of the illustration. */
private class LessonBook(val width: Dp, val height: Dp, val color: Color)

private val LESSON_BOOKS = listOf(
    LessonBook(84.dp, 20.dp, Color(0xFFD5DAE2)),
    LessonBook(106.dp, 24.dp, Color(0xFFAEB5C0)),
    LessonBook(92.dp, 20.dp, Color(0xFFDADDE2)),
    LessonBook(114.dp, 26.dp, Color(0xFFBEC5CF)),
    LessonBook(98.dp, 22.dp, Color(0xFFCDD2DA)),
)

/**
 * Screen 3 — Lessons. A pile of books (« a whole book, hours of reading ») facing the card
 * of a real lesson of the catalogue (« a Sophia lesson, 10 minutes »), then the promise:
 * exciting 10-minute lessons, made for you.
 */
@Composable
internal fun LessonsStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val reduceMotion = rememberOnboardingReduceMotion()
    var course by remember(language) {
        mutableStateOf(OnboardingIntroCatalog.cachedCourse(language, OnboardingIntroCatalog.DREAM_COURSE_ID))
    }
    LaunchedEffect(language) {
        if (course == null) {
            course = OnboardingIntroCatalog.course(context, language, OnboardingIntroCatalog.DREAM_COURSE_ID)
        }
    }
    // Books laid on the pile (they drop one by one, the bottom one first).
    var booksShown by remember { mutableIntStateOf(if (reduceMotion) LESSON_BOOKS.size else 0) }
    var arrowIn by remember { mutableStateOf(reduceMotion) }
    var cardIn by remember { mutableStateOf(reduceMotion) }
    var titleIn by remember { mutableStateOf(reduceMotion) }
    // The books drop on the pile, the arrow leaves, the lesson lands: hours of reading
    // brought down to ten minutes.
    LaunchedEffect(Unit) {
        if (reduceMotion) return@LaunchedEffect
        delay(100)
        titleIn = true
        delay(300)
        for (count in 1..LESSON_BOOKS.size) {
            booksShown = count
            haptics.tick()
            delay(100)
        }
        delay(120)
        arrowIn = true
        delay(220)
        cardIn = true
        haptics.soft()
    }
    val arrowProgress by animateFloatAsState(if (arrowIn) 1f else 0f, DSMotion.reveal(), label = "lessonArrow")
    val cardProgress by animateFloatAsState(if (cardIn) 1f else 0f, DSMotion.pop(), label = "lessonCard")
    val titleProgress by animateFloatAsState(if (titleIn) 1f else 0f, DSMotion.reveal(), label = "lessonTitle")
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl

    OnboardingPage(
        footer = {
            OnboardingCta(StringStore.text(context, "common.continue", language), onContinue)
        },
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = ONBOARDING_SIDE_INSET, vertical = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(44.dp),
        ) {
            // A book against a lesson.
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.Bottom,
                horizontalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterHorizontally),
            ) {
                Column(
                    modifier = Modifier
                        .weight(1f, fill = false)
                        .widthIn(max = 132.dp)
                        .semantics(mergeDescendants = true) { },
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    LessonCaption(
                        title = StringStore.text(context, "onboardingV2.elevate.lessons.book.title", language),
                        detail = StringStore.text(context, "onboardingV2.elevate.lessons.book.caption", language),
                        color = DS.inkSecondary,
                        detailWeight = FontWeight.Normal,
                    )
                    Column(
                        modifier = Modifier.height(168.dp).clearAndSetSemantics { },
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(5.dp, Alignment.Bottom),
                    ) {
                        LESSON_BOOKS.forEachIndexed { index, book ->
                            LessonBookBar(book = book, landed = LESSON_BOOKS.size - index <= booksShown)
                        }
                    }
                }

                Icon(
                    Icons.AutoMirrored.Filled.ArrowForward,
                    contentDescription = null,
                    tint = DS.accent,
                    modifier = Modifier
                        .padding(bottom = 72.dp)
                        .size(26.dp)
                        .graphicsLayer {
                            alpha = arrowProgress.coerceIn(0f, 1f)
                            translationX = (1f - arrowProgress) * 10.dp.toPx() * (if (rtl) 1f else -1f)
                        },
                )

                Column(
                    modifier = Modifier
                        .weight(1f, fill = false)
                        .widthIn(max = 150.dp)
                        .semantics(mergeDescendants = true) { },
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    LessonCaption(
                        title = StringStore.text(context, "onboardingV2.elevate.lessons.lesson.title", language),
                        detail = StringStore.text(
                            context,
                            "onboardingV2.elevate.lessons.lesson.caption",
                            language,
                            LESSON_MINUTES,
                        ),
                        color = DS.accent,
                        detailWeight = FontWeight.SemiBold,
                    )
                    // The card of a real lesson: its cover and its title, bordered in the accent blue.
                    Column(
                        modifier = Modifier
                            .widthIn(max = 138.dp)
                            .fillMaxWidth()
                            .graphicsLayer {
                                alpha = cardProgress.coerceIn(0f, 1f)
                                transformOrigin = TransformOrigin(0.5f, 1f)
                                val scale = 0.6f + 0.4f * cardProgress
                                scaleX = scale
                                scaleY = scale
                            }
                            .padding(bottom = 2.dp)
                            .ov2Card(border = DS.accent, lip = 1.5.dp)
                            .padding(start = 7.dp, end = 7.dp, top = 7.dp, bottom = 12.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(9.dp),
                    ) {
                        OnboardingCover(
                            courseId = course?.id,
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(112.dp)
                                .clip(RoundedCornerShape(11.dp))
                                .clearAndSetSemantics { },
                        )
                        Text(
                            text = course?.title.orEmpty(),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 13.sp,
                            lineHeight = 17.sp,
                            color = DS.ink,
                            textAlign = TextAlign.Center,
                            maxLines = 3,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                }
            }

            OnboardingShrinkText(
                text = dsHighlighted(StringStore.text(context, "onboardingV2.intro.lessons.title", language), DS.accent),
                style = TextStyle(
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Normal,
                    fontSize = 28.sp,
                    lineHeight = 36.sp,
                    color = DS.ink,
                ),
                maxLines = 6,
                modifier = Modifier
                    .fillMaxWidth()
                    .graphicsLayer {
                        alpha = titleProgress.coerceIn(0f, 1f)
                        translationY = (1f - titleProgress) * 14.dp.toPx()
                    }
                    .semantics { heading() },
            )
        }
    }
}

@Composable
private fun LessonBookBar(book: LessonBook, landed: Boolean) {
    val progress by animateFloatAsState(if (landed) 1f else 0f, DSMotion.snappy(), label = "lessonBook")
    Box(
        modifier = Modifier
            .size(width = book.width, height = book.height)
            .graphicsLayer {
                alpha = progress.coerceIn(0f, 1f)
                translationY = (1f - progress) * -26.dp.toPx()
            }
            .background(book.color, RoundedCornerShape(7.dp)),
    )
}

@Composable
private fun LessonCaption(title: String, detail: String, color: Color, detailWeight: FontWeight) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(1.dp)) {
        Text(
            text = title,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 15.sp,
            lineHeight = 19.sp,
            color = color,
            textAlign = TextAlign.Center,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            text = detail,
            fontFamily = PlusJakartaSans,
            fontWeight = detailWeight,
            fontSize = 13.sp,
            lineHeight = 17.sp,
            color = color,
            textAlign = TextAlign.Center,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
    }
}
