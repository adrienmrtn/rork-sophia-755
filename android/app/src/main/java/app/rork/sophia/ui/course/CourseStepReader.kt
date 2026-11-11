package app.rork.sophia.ui.course

import android.content.Context
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.background
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import app.rork.sophia.ui.theme.DS

/**
 * Comment le texte d'un cours se présente dans le lecteur, comme sur iOS (`CourseReadingMode`).
 *
 * Par défaut, un cours se lit **pas à pas** : un seul fil vertical où chaque passage
 * (paragraphe, image, frise, citation, encart) apparaît au tap sur « Continuer », avec une
 * animation d'entrée, un défilement automatique et un retour haptique (docs/lecture-pas-a-pas.md).
 * L'ancien lecteur **par pages** (une page par partie, glissement horizontal) reste disponible :
 * le choix se fait dans l'en-tête du lecteur et est conservé sur l'appareil.
 */
enum class CourseReadingMode(val raw: String, val titleKey: String) {
    /** Un fil vertical, révélé passage par passage. */
    STEPS("steps", "course.readingMode.steps"),

    /** Une page par partie, le lecteur historique. */
    PAGES("pages", "course.readingMode.pages");

    companion object {
        private const val PREFS = "sophia_prefs"
        private const val KEY = "sophia_course_reading_mode"

        /** Le mode choisi sur cet appareil ; `STEPS` tant que rien n'a été choisi. */
        fun current(context: Context): CourseReadingMode {
            val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)
            return entries.firstOrNull { it.raw == raw } ?: STEPS
        }

        fun save(context: Context, mode: CourseReadingMode) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, mode.raw).apply()
        }
    }
}

/**
 * Un passage du lecteur pas à pas : ce qui apparaît à un tap sur « Continuer ». L'unité est le
 * bloc (une image est un passage à part entière), un titre de section ouvre un chapitre.
 */
internal sealed class ReaderStep {
    abstract val id: String

    /** Index de la section (0 = intro). */
    abstract val sectionIndex: Int

    /** L'en-tête de la section : titre (et signature, mention de traduction pour l'intro). */
    data class Header(override val id: String, override val sectionIndex: Int) : ReaderStep()

    /**
     * Un bloc du cours tel quel. Un intertitre s'affiche avec le bloc qui le suit plutôt que
     * d'occuper un tap à lui seul.
     */
    data class Block(
        override val id: String,
        override val sectionIndex: Int,
        val block: ReaderBlock,
        val heading: String?,
    ) : ReaderStep()

    /** La carte auteur et les sources, après la dernière section. */
    data class Footer(override val id: String, override val sectionIndex: Int) : ReaderStep()

    /** Une section réservée : la page floutée et le cadenas, en un seul passage. */
    data class Locked(override val id: String, override val sectionIndex: Int) : ReaderStep()

    /** Vrai quand le passage montre une image : son entrée gagne une légère montée d'échelle. */
    val showsPicture: Boolean get() = this is Block && block is ReaderBlock.Image

    /** Un passage qui ouvre un chapitre : la vibration est plus marquée. */
    val opensChapter: Boolean get() = this is Header || this is Locked
}

/**
 * Les passages d'un cours, dans l'ordre de lecture. Les sections verrouillées pour ce lecteur
 * tiennent en un passage.
 */
internal fun buildReaderSteps(
    pages: List<ReaderPage>,
    isLocked: (Int) -> Boolean,
    hasFooter: Boolean,
): List<ReaderStep> {
    val steps = ArrayList<ReaderStep>()
    pages.forEachIndexed { index, page ->
        if (isLocked(index)) {
            steps += ReaderStep.Locked("$index#locked", index)
            return@forEachIndexed
        }
        steps += ReaderStep.Header("$index#header", index)
        var pendingHeading: String? = null
        page.blocks.forEachIndexed { blockIndex, block ->
            if (block is ReaderBlock.Heading) {
                pendingHeading?.let { waiting ->
                    steps += ReaderStep.Block("$index#$blockIndex-heading", index, ReaderBlock.Heading(waiting), null)
                }
                pendingHeading = block.text
                return@forEachIndexed
            }
            steps += ReaderStep.Block("$index#$blockIndex", index, block, pendingHeading)
            pendingHeading = null
        }
        pendingHeading?.let { heading ->
            steps += ReaderStep.Block("$index#end-heading", index, ReaderBlock.Heading(heading), null)
        }
        if (index == pages.lastIndex && hasFooter) {
            steps += ReaderStep.Footer("$index#footer", index)
        }
    }
    return steps
}

/** Le nombre de passages à révéler pour arriver à l'en-tête de [section] : les sections d'avant entières, puis le titre seul. */
internal fun revealedThroughSection(steps: List<ReaderStep>, section: Int): Int {
    val first = steps.indexOfFirst { it.sectionIndex == section }
    return if (first < 0) steps.size else first + 1
}

/** Remplissage du segment d'une section dans la barre : la part de ses passages déjà révélés. */
internal fun sectionFill(steps: List<ReaderStep>, revealed: Int, section: Int): Float {
    var total = 0
    var done = 0
    steps.forEachIndexed { index, step ->
        if (step.sectionIndex == section) {
            total++
            if (index < revealed) done++
        }
    }
    return if (total == 0) 0f else done.toFloat() / total
}

/**
 * Le fil du lecteur pas à pas : les passages révélés dans un seul défilement vertical, avec
 * l'animation d'entrée et le défilement automatique vers le dernier passage révélé.
 *
 * La vue ne décide rien : `CourseScreen` tient le nombre de passages révélés et dessine chaque
 * passage ([stepContent]). [scrollToIndex] et [scrollToken] demandent d'amener un passage en
 * vue (le jeton change à chaque demande : le même passage peut être demandé deux fois).
 */
@Composable
internal fun CourseStepReader(
    steps: List<ReaderStep>,
    revealed: Int,
    /** Les passages à partir de cet index entrent avec une animation ; ceux d'avant sont déjà là. */
    animateFrom: Int,
    scrollToIndex: Int,
    scrollToken: Int,
    onDoubleTap: () -> Unit,
    modifier: Modifier = Modifier,
    stepContent: @Composable (ReaderStep) -> Unit,
) {
    val listState = rememberLazyListState()
    val density = LocalDensity.current
    // Les passages déjà entrés : un passage qui revient à l'écran en défilant ne se rejoue pas.
    val entered = remember(steps) { HashSet<String>() }
    BoxWithConstraints(
        modifier = modifier.pointerInput(Unit) { detectTapGestures(onDoubleTap = { onDoubleTap() }) },
    ) {
        val viewport = maxHeight
        // Le haut du passage révélé vient se poser à 8 % de la hauteur du lecteur.
        val anchorPx = with(density) { (viewport * 0.08f).roundToPx() }
        LaunchedEffect(scrollToken) {
            if (scrollToken == 0 || scrollToIndex !in 0 until revealed) return@LaunchedEffect
            listState.animateScrollToItem(scrollToIndex, -anchorPx)
        }
        LazyColumn(
            state = listState,
            modifier = Modifier.fillMaxSize(),
            // De la place sous le dernier passage, pour qu'il puisse toujours monter jusqu'au
            // repère de lecture même quand rien ne le suit encore.
            contentPadding = PaddingValues(
                start = DS.Space.l,
                end = DS.Space.l,
                top = DS.Space.l,
                bottom = maxOf(160.dp, viewport * 0.85f),
            ),
            verticalArrangement = Arrangement.spacedBy(24.dp),
        ) {
            itemsIndexed(steps.take(revealed), key = { _, step -> step.id }) { index, step ->
                val animate = index >= animateFrom && step.id !in entered
                // Fondu et montée de 18 dp ; une image gagne une légère montée d'échelle.
                val progress = remember(step.id) { Animatable(if (animate) 0f else 1f) }
                LaunchedEffect(step.id) {
                    if (progress.value < 1f) {
                        progress.animateTo(1f, spring(dampingRatio = 0.8f, stiffness = Spring.StiffnessMediumLow))
                    }
                    entered += step.id
                }
                val rise = with(density) { 18.dp.toPx() }
                Box(
                    modifier = Modifier.fillMaxWidth().graphicsLayer {
                        alpha = progress.value.coerceIn(0f, 1f)
                        translationY = (1f - progress.value) * rise
                        if (step.showsPicture) {
                            val scale = 0.97f + 0.03f * progress.value
                            scaleX = scale
                            scaleY = scale
                        }
                    },
                ) {
                    stepContent(step)
                }
            }
        }
    }
}

/** La barre du lecteur pas à pas : une capsule par section, qui se remplit passage après passage. */
@Composable
internal fun SteppedProgressBar(
    fills: List<Float>,
    modifier: Modifier = Modifier,
    height: Dp = 6.dp,
    activeColor: Color = DS.accentSoft,
    trackColor: Color = DS.hairline,
) {
    Row(modifier = modifier.fillMaxWidth().height(height), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        fills.forEach { fill ->
            Box(modifier = Modifier.weight(1f).fillMaxHeight().clip(CircleShape).background(trackColor)) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth(fill.coerceIn(0f, 1f))
                        .fillMaxHeight()
                        .clip(CircleShape)
                        .background(activeColor),
                )
            }
        }
    }
}
