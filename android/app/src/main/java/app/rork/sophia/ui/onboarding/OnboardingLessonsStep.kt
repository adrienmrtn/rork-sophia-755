package app.rork.sophia.ui.onboarding

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
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
import androidx.compose.ui.semantics.contentDescription
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
import app.rork.sophia.data.ContentCatalog
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
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
 * Les cours qui défilent dans la carte « une leçon Sophia » : des cours lus, aux titres
 * courts et aux matières variées. Un cours absent d'une langue est simplement sauté.
 */
private val LESSON_COURSE_IDS = listOf(
    OnboardingIntroCatalog.DREAM_COURSE_ID,
    OnboardingIntroCatalog.BLACK_HOLE_COURSE_ID,
    "course_149_la_joconde",
    "course_264_qui_a_vraiment_construit_les_pyramides",
    "course_150_la_nuit_etoilee_van_gogh",
    "course_241_pourquoi_voulait_on_demolir_la_tour_eiffel",
)

/** Temps d'affichage d'un cours dans la carte avant le suivant, en millisecondes. */
private const val LESSON_ROTATION_MILLIS = 1500L

/** Hauteur de la pile de livres ; la flèche est centrée dessus. */
private val LESSON_PILE_HEIGHT = 168.dp

/** Largeur de la colonne du milieu (la flèche et ses marges), la même sur les trois rangées. */
private val LESSON_ARROW_SLOT = 50.dp

/** Les cours de la carte que la langue possède ; à défaut, le cours d'exemple habituel. */
private fun lessonCourses(all: List<CourseSummary>): List<CourseSummary> {
    val byId = all.associateBy { it.id }
    return LESSON_COURSE_IDS.mapNotNull { byId[it] }
        .ifEmpty { listOfNotNull(OnboardingIntroCatalog.pick(all, OnboardingIntroCatalog.DREAM_COURSE_ID)) }
}

/**
 * Screen 3 — Lessons. A pile of books (« a whole book, hours of reading ») facing the card
 * of a real lesson of the catalogue (« a Sophia lesson, 10 minutes »), then the promise:
 * exciting 10-minute lessons, made for you.
 *
 * La comparaison est posée sur une grille de trois rangées (titres, détails, illustrations)
 * et de trois colonnes (livre, flèche, leçon) : les deux légendes partagent ainsi les mêmes
 * lignes, quelle que soit la hauteur de ce qu'il y a dessous. Une fois la carte posée, le
 * cours qu'elle montre change toutes les 1,5 seconde.
 */
@Composable
internal fun LessonsStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val reduceMotion = rememberOnboardingReduceMotion()
    var courses by remember(language) {
        mutableStateOf(ContentCatalog.cachedSummaries(language)?.let(::lessonCourses).orEmpty())
    }
    LaunchedEffect(language) {
        if (courses.isEmpty()) {
            courses = runCatching {
                lessonCourses(ContentCatalog.summariesAsync(context.applicationContext, language))
            }.getOrDefault(emptyList())
        }
    }
    // Books laid on the pile (they drop one by one, the bottom one first).
    var booksShown by remember { mutableIntStateOf(if (reduceMotion) LESSON_BOOKS.size else 0) }
    var arrowIn by remember { mutableStateOf(reduceMotion) }
    var cardIn by remember { mutableStateOf(reduceMotion) }
    var titleIn by remember { mutableStateOf(reduceMotion) }
    // The books drop on the pile, the arrow leaves, the lesson lands: hours of reading
    // brought down to ten minutes. Le tout tient en un peu plus d'une demi-seconde.
    LaunchedEffect(Unit) {
        if (reduceMotion) return@LaunchedEffect
        delay(60)
        titleIn = true
        delay(140)
        for (count in 1..LESSON_BOOKS.size) {
            booksShown = count
            haptics.tick()
            delay(55)
        }
        delay(60)
        arrowIn = true
        delay(120)
        cardIn = true
        haptics.soft()
    }
    // Le cours montré dans la carte : il change toutes les 1,5 seconde une fois la carte
    // posée. Sans animations (réglage du système), la carte garde le premier.
    var courseIndex by remember { mutableIntStateOf(0) }
    LaunchedEffect(cardIn, courses.size, reduceMotion) {
        if (!cardIn || reduceMotion || courses.size < 2) return@LaunchedEffect
        while (true) {
            delay(LESSON_ROTATION_MILLIS)
            courseIndex += 1
        }
    }
    val course = courses.getOrNull(courseIndex % courses.size.coerceAtLeast(1))

    val arrowProgress by animateFloatAsState(if (arrowIn) 1f else 0f, tween(220, easing = LinearOutSlowInEasing), label = "lessonArrow")
    val cardProgress by animateFloatAsState(if (cardIn) 1f else 0f, OV2Calm.settle(), label = "lessonCard")
    val titleProgress by animateFloatAsState(if (titleIn) 1f else 0f, tween(320, easing = LinearOutSlowInEasing), label = "lessonTitle")
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl

    val bookTitle = StringStore.text(context, "onboardingV2.elevate.lessons.book.title", language)
    val bookDetail = StringStore.text(context, "onboardingV2.elevate.lessons.book.caption", language)
    val lessonTitle = StringStore.text(context, "onboardingV2.elevate.lessons.lesson.title", language)
    val lessonDetail = StringStore.text(context, "onboardingV2.elevate.lessons.lesson.caption", language, LESSON_MINUTES)

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
            Column(modifier = Modifier.widthIn(max = 340.dp).fillMaxWidth()) {
                // Les deux titres finissent sur la même ligne…
                Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.Bottom) {
                    LessonCaptionTitle(
                        text = bookTitle,
                        color = DS.inkSecondary,
                        // Lu d'un trait avec son détail : « Un livre entier, des heures de lecture ».
                        modifier = Modifier.weight(1f).clearAndSetSemantics { contentDescription = "$bookTitle, $bookDetail" },
                    )
                    Spacer(Modifier.width(LESSON_ARROW_SLOT))
                    LessonCaptionTitle(
                        text = lessonTitle,
                        color = DS.accent,
                        modifier = Modifier.weight(1f).clearAndSetSemantics { contentDescription = "$lessonTitle, $lessonDetail" },
                    )
                }
                // … et les deux détails partent de la même ligne, juste dessous.
                Row(
                    modifier = Modifier.fillMaxWidth().padding(top = 2.dp).clearAndSetSemantics { },
                    verticalAlignment = Alignment.Top,
                ) {
                    LessonCaptionDetail(
                        text = bookDetail,
                        color = DS.inkSecondary,
                        weight = FontWeight.Normal,
                        modifier = Modifier.weight(1f),
                    )
                    Spacer(Modifier.width(LESSON_ARROW_SLOT))
                    LessonCaptionDetail(
                        text = lessonDetail,
                        color = DS.accent,
                        weight = FontWeight.SemiBold,
                        modifier = Modifier.weight(1f),
                    )
                }
                // La pile et la carte, posées sur la même ligne de sol.
                Row(
                    modifier = Modifier.fillMaxWidth().padding(top = 14.dp),
                    verticalAlignment = Alignment.Bottom,
                ) {
                    Box(modifier = Modifier.weight(1f), contentAlignment = Alignment.BottomCenter) {
                        Column(
                            modifier = Modifier.height(LESSON_PILE_HEIGHT).clearAndSetSemantics { },
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(5.dp, Alignment.Bottom),
                        ) {
                            LESSON_BOOKS.forEachIndexed { index, book ->
                                LessonBookBar(book = book, landed = LESSON_BOOKS.size - index <= booksShown)
                            }
                        }
                    }

                    Box(
                        modifier = Modifier.width(LESSON_ARROW_SLOT).height(LESSON_PILE_HEIGHT),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowForward,
                            contentDescription = null,
                            tint = DS.accent,
                            modifier = Modifier
                                .size(26.dp)
                                .graphicsLayer {
                                    alpha = arrowProgress.coerceIn(0f, 1f)
                                    translationX = (1f - arrowProgress) * 10.dp.toPx() * (if (rtl) 1f else -1f)
                                },
                        )
                    }

                    Box(modifier = Modifier.weight(1f), contentAlignment = Alignment.BottomCenter) {
                        // The card of a real lesson: its cover and its title, bordered in the accent blue.
                        Box(
                            modifier = Modifier
                                .widthIn(max = 138.dp)
                                .fillMaxWidth()
                                .graphicsLayer {
                                    alpha = cardProgress.coerceIn(0f, 1f)
                                    transformOrigin = TransformOrigin(0.5f, 1f)
                                    val scale = 0.85f + 0.15f * cardProgress
                                    scaleX = scale
                                    scaleY = scale
                                }
                                .padding(bottom = 2.dp)
                                .ov2Card(border = DS.accent, lip = 1.5.dp)
                                .padding(start = 7.dp, end = 7.dp, top = 7.dp, bottom = 12.dp),
                        ) {
                            // D'un cours au suivant : l'ancien s'efface vers le haut, le nouveau
                            // monte à sa place. La carte, elle, ne change pas de taille.
                            AnimatedContent(
                                targetState = course,
                                transitionSpec = {
                                    (fadeIn(tween(320)) + slideInVertically(tween(320, easing = LinearOutSlowInEasing)) { it / 6 }) togetherWith
                                        (fadeOut(tween(200)) + slideOutVertically(tween(240)) { -it / 6 })
                                },
                                contentKey = { it?.id },
                                label = "lessonCourse",
                            ) { shown ->
                                LessonCourseContent(course = shown)
                            }
                        }
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

/**
 * Le contenu de la carte pour un cours : sa couverture et son titre. Le titre réserve
 * toujours deux lignes, pour que la carte garde sa hauteur d'un cours à l'autre.
 */
@Composable
private fun LessonCourseContent(course: CourseSummary?) {
    val titleStyle = TextStyle(
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.Bold,
        fontSize = 13.sp,
        lineHeight = 17.sp,
        color = DS.ink,
        textAlign = TextAlign.Center,
    )
    Column(
        modifier = Modifier.fillMaxWidth(),
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
        Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
            // Deux lignes vides : la place du titre, qu'il en prenne une ou deux.
            Text(text = "", style = titleStyle, minLines = 2, modifier = Modifier.clearAndSetSemantics { })
            Text(
                text = course?.title.orEmpty(),
                style = titleStyle,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

@Composable
private fun LessonBookBar(book: LessonBook, landed: Boolean) {
    val progress by animateFloatAsState(if (landed) 1f else 0f, OV2Calm.quick(), label = "lessonBook")
    Box(
        modifier = Modifier
            .size(width = book.width, height = book.height)
            .graphicsLayer {
                alpha = progress.coerceIn(0f, 1f)
                translationY = (1f - progress) * -18.dp.toPx()
            }
            .background(book.color, RoundedCornerShape(7.dp)),
    )
}

/** Le titre d'une légende (« Un livre entier », « Une leçon Sophia »), centré dans sa colonne. */
@Composable
private fun LessonCaptionTitle(text: String, color: Color, modifier: Modifier = Modifier) {
    Text(
        text = text,
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.Bold,
        fontSize = 15.sp,
        lineHeight = 19.sp,
        color = color,
        textAlign = TextAlign.Center,
        maxLines = 2,
        overflow = TextOverflow.Ellipsis,
        modifier = modifier,
    )
}

/** Le détail d'une légende (« des heures de lecture », « 10 minutes »), centré dans sa colonne. */
@Composable
private fun LessonCaptionDetail(text: String, color: Color, weight: FontWeight, modifier: Modifier = Modifier) {
    Text(
        text = text,
        fontFamily = PlusJakartaSans,
        fontWeight = weight,
        fontSize = 13.sp,
        lineHeight = 17.sp,
        color = color,
        textAlign = TextAlign.Center,
        maxLines = 2,
        overflow = TextOverflow.Ellipsis,
        modifier = modifier,
    )
}
