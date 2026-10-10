package app.rork.sophia.ui.onboarding

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.drag
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.progressBarRangeInfo
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.setProgress
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Subject
import kotlin.math.roundToInt
import kotlinx.coroutines.delay

/**
 * The « about you » pages of the iOS 1.1.8 onboarding, right before the objectives: first
 * name, age, general knowledge (slider), motivation; then, after the objectives, the
 * subjects of interest (six squares). The first name is not repeated in the questions: it
 * comes back where it carries (« Sophia will help you… », loading, profile, after the account).
 */

internal const val FIRST_NAME_MAX_LENGTH = 24
internal val AGE_RANGE_KEYS = listOf("under18", "18to24", "25to34", "35to44", "45to54", "55plus")
internal const val KNOWLEDGE_LEVEL_COUNT = 4
private val KNOWLEDGE_EMOJI = listOf("😅", "🙂", "😎", "🤓")
internal val MOTIVATION_KEYS = listOf("grow", "conversations", "career", "sharp", "world")
private val MOTIVATION_EMOJI = mapOf(
    "grow" to "🌱",
    "conversations" to "💬",
    "career" to "💼",
    "sharp" to "🧠",
    "world" to "🌍",
)
internal val SUBJECT_EMOJI = mapOf(
    Subject.HISTOIRE to "🗽",
    Subject.SCIENCES to "🦠",
    Subject.LITTERATURE to "📖",
    Subject.ART to "🎨",
    Subject.MYTHOLOGIE to "⚡",
    Subject.COMPRENDRE_LE_MONDE to "🌍",
)

/**
 * `key` with the first name in it: the `<key>Named` string (with `{name}` filled in) when a
 * name was given and the table has that string, otherwise `key` as it is.
 */
internal fun personalizedText(
    context: android.content.Context,
    key: String,
    name: String,
    language: AppLanguage,
): String {
    val trimmed = name.trim()
    if (trimmed.isNotEmpty()) {
        val namedKey = key + "Named"
        val named = StringStore.text(context, namedKey, language)
        if (named != namedKey) return named.replace("{name}", trimmed)
    }
    return StringStore.text(context, key, language)
}

/** Title and subtitle of a question page. */
@Composable
private fun QuestionHeader(title: String, subtitle: String?) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 28.dp)
            .ov2Reveal(100),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(text = title, style = OV2.title, textAlign = TextAlign.Center)
        if (subtitle != null) {
            Text(text = subtitle, style = OV2.body, textAlign = TextAlign.Center)
        }
    }
}

/** Rows revealed one after the other, 70 ms apart. */
@Composable
private fun rememberRowReveal(count: Int): Int {
    var revealed by remember { mutableIntStateOf(0) }
    LaunchedEffect(count) {
        delay(150)
        repeat(count) { i ->
            revealed = i + 1
            delay(70)
        }
    }
    return revealed
}

/**
 * One answer among several: optional emoji badge, label, round check on the right. Same
 * drawing as the objectives rows, with a circle in place of the box.
 */
@Composable
private fun ChoiceRow(
    label: String,
    selected: Boolean,
    visible: Boolean,
    emoji: String? = null,
    onClick: () -> Unit,
) {
    val alpha by animateFloatAsState(if (visible) 1f else 0f, tween(320), label = "choiceAlpha")
    val offsetY by animateFloatAsState(
        targetValue = if (visible) 0f else 18f,
        animationSpec = spring(dampingRatio = 0.8f, stiffness = Spring.StiffnessMediumLow),
        label = "choiceY",
    )
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .graphicsLayer { this.alpha = alpha; translationY = offsetY * density }
            .clip(OV2Shapes.control)
            .background(if (selected) OV2.accentSoft.copy(alpha = 0.06f) else OV2.surface)
            .border(
                width = if (selected) 2.dp else 1.dp,
                color = if (selected) OV2.accent else OV2.hairline,
                shape = OV2Shapes.control,
            )
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = if (emoji == null) 16.dp else 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        if (emoji != null) {
            OnboardingCircleBadge(
                size = 44.dp,
                background = if (selected) OV2.accent.copy(alpha = 0.16f) else OV2.accentSoft.copy(alpha = 0.12f),
            ) {
                Text(emoji, fontSize = 22.sp)
            }
        }
        Text(
            text = label,
            style = OV2.body.copy(color = OV2.ink, fontWeight = FontWeight.SemiBold),
            modifier = Modifier.weight(1f),
        )
        RadioMark(selected = selected)
    }
}

@Composable
private fun RadioMark(selected: Boolean) {
    val scale by animateFloatAsState(
        targetValue = if (selected) 1f else 0f,
        animationSpec = spring(dampingRatio = 0.6f, stiffness = Spring.StiffnessMedium),
        label = "radio",
    )
    Box(
        modifier = Modifier
            .size(22.dp)
            .border(2.dp, if (selected) OV2.accent else OV2.hairline, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer { scaleX = scale; scaleY = scale; alpha = scale }
                .background(OV2.accent, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(13.dp))
        }
    }
}

/** A single-choice question: header, scrolling rows, « Continue » once something is picked. */
@Composable
private fun SingleChoiceStep(
    title: String,
    subtitle: String,
    options: List<Pair<String, String>>,
    emojis: Map<String, String>?,
    selected: String?,
    continueLabel: String,
    onSelect: (String) -> Unit,
    onContinue: () -> Unit,
) {
    val haptics = rememberOnboardingHaptics()
    val revealed = rememberRowReveal(options.size)
    Column(modifier = Modifier.fillMaxSize()) {
        Spacer(Modifier.height(72.dp))
        QuestionHeader(title = title, subtitle = subtitle)
        Spacer(Modifier.height(24.dp))
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp)
                .padding(bottom = 12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            options.forEachIndexed { index, (key, label) ->
                ChoiceRow(
                    label = label,
                    emoji = emojis?.get(key),
                    selected = key == selected,
                    visible = index < revealed,
                    onClick = {
                        haptics.selection()
                        onSelect(key)
                    },
                )
            }
        }
        OnboardingCta(text = continueLabel, onClick = onContinue, enabled = selected != null)
    }
}

// MARK: - First name

/**
 * « What's your name? »: one field, the keyboard coming up by itself, « Continue » as soon as
 * there is a name, and a quiet « Skip » for anyone who would rather not say.
 */
@Composable
internal fun NameStep(
    language: AppLanguage,
    initialName: String,
    onSubmit: (String) -> Unit,
) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    val keyboard = LocalSoftwareKeyboardController.current
    val focusRequester = remember { FocusRequester() }
    var name by rememberSaveable { mutableStateOf(initialName) }
    var focused by remember { mutableStateOf(false) }
    val trimmed = name.trim()

    LaunchedEffect(Unit) {
        // The keyboard comes up once the page transition is over.
        delay(650)
        runCatching { focusRequester.requestFocus() }
    }

    fun commit() {
        if (trimmed.isEmpty()) return
        keyboard?.hide()
        onSubmit(trimmed)
    }

    // The keyboard takes half of a small screen: the content scrolls, the CTA stays above it.
    OnboardingPage(
        modifier = Modifier.imePadding(),
        contentArrangement = Arrangement.Top,
        footer = {
            OnboardingCta(
                text = StringStore.text(context, "common.continue", language),
                onClick = { commit() },
                enabled = trimmed.isNotEmpty(),
            )
            Text(
                text = StringStore.text(context, "onboardingV2.name.skip", language),
                style = OV2.subheadline.copy(fontWeight = FontWeight.SemiBold, textDecoration = TextDecoration.Underline),
                modifier = Modifier
                    .padding(bottom = 24.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .clickable {
                        keyboard?.hide()
                        haptics.selection()
                        onSubmit("")
                    }
                    .padding(horizontal = 12.dp, vertical = 4.dp),
            )
        },
    ) {
        Spacer(Modifier.height(72.dp))
        QuestionHeader(
            title = StringStore.text(context, "onboardingV2.name.title", language),
            subtitle = StringStore.text(context, "onboardingV2.name.subtitle", language),
        )
        Spacer(Modifier.height(36.dp))
        val borderColor by animateColorAsState(if (focused) OV2.accent else OV2.hairline, tween(200), label = "nameBorder")
        val fieldStyle = OV2.title.copy(fontSize = 22.sp, lineHeight = 28.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center)
        BasicTextField(
            value = name,
            onValueChange = { name = it.take(FIRST_NAME_MAX_LENGTH) },
            singleLine = true,
            textStyle = fieldStyle,
            cursorBrush = SolidColor(OV2.accent),
            keyboardOptions = KeyboardOptions(
                capitalization = KeyboardCapitalization.Words,
                autoCorrectEnabled = false,
                imeAction = ImeAction.Next,
            ),
            keyboardActions = KeyboardActions(onNext = { commit() }, onDone = { commit() }),
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .ov2Reveal(250)
                .focusRequester(focusRequester)
                .onFocusChanged { focused = it.isFocused },
            decorationBox = { inner ->
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(OV2Shapes.control)
                        .background(OV2.surface)
                        .border(if (focused) 2.dp else 1.dp, borderColor, OV2Shapes.control)
                        .padding(horizontal = 18.dp, vertical = 18.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    if (name.isEmpty()) {
                        Text(
                            text = StringStore.text(context, "onboardingV2.name.placeholder", language),
                            style = fieldStyle.copy(color = OV2.inkTertiary),
                            modifier = Modifier.fillMaxWidth(),
                        )
                    }
                    inner()
                }
            },
        )
        Spacer(Modifier.height(24.dp))
    }
}

// MARK: - Age

/** « How old are you? »: six ranges, one answer. */
@Composable
internal fun AgeStep(
    language: AppLanguage,
    selected: String?,
    onSelect: (String) -> Unit,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    SingleChoiceStep(
        title = StringStore.text(context, "onboardingV2.age.title", language),
        subtitle = StringStore.text(context, "onboardingV2.age.subtitle", language),
        options = AGE_RANGE_KEYS.map { it to StringStore.text(context, "onboardingV2.age.$it", language) },
        emojis = null,
        selected = selected,
        continueLabel = StringStore.text(context, "common.continue", language),
        onSelect = onSelect,
        onContinue = onContinue,
    )
}

// MARK: - Motivation

/** « Why do you want to improve your general knowledge? »: five reasons, one answer. */
@Composable
internal fun MotivationStep(
    language: AppLanguage,
    selected: String?,
    onSelect: (String) -> Unit,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    SingleChoiceStep(
        title = StringStore.text(context, "onboardingV2.motivation.title", language),
        subtitle = StringStore.text(context, "onboardingV2.motivation.subtitle", language),
        options = MOTIVATION_KEYS.map { it to StringStore.text(context, "onboardingV2.motivation.$it", language) },
        emojis = MOTIVATION_EMOJI,
        selected = selected,
        continueLabel = StringStore.text(context, "common.continue", language),
        onSelect = onSelect,
        onContinue = onContinue,
    )
}

// MARK: - General knowledge

/**
 * « How would you rate your general knowledge? »: a four-notch slider, from « not great » to
 * « very good », with the notch's emoji and label above it. The thumb follows the finger
 * smoothly and settles on the nearest notch when released; the emoji, label and a tick of
 * haptics change as soon as it passes half-way to the next notch.
 */
@Composable
internal fun KnowledgeStep(
    language: AppLanguage,
    initialLevel: Int,
    onContinue: (Int) -> Unit,
) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    var step by rememberSaveable { mutableIntStateOf(initialLevel.coerceIn(0, KNOWLEDGE_LEVEL_COUNT - 1)) }
    var level by remember { mutableFloatStateOf(step.toFloat()) }
    var dragging by remember { mutableStateOf(false) }
    val settled by animateFloatAsState(
        targetValue = if (dragging) level else step.toFloat(),
        animationSpec = if (dragging) spring(stiffness = 100_000f) else spring(dampingRatio = 0.75f, stiffness = Spring.StiffnessMediumLow),
        label = "knowledgeThumb",
    )
    val thumbScale by animateFloatAsState(
        targetValue = if (dragging) 1.12f else 1f,
        animationSpec = spring(dampingRatio = 0.7f, stiffness = Spring.StiffnessMedium),
        label = "knowledgeThumbScale",
    )

    fun move(value: Float) {
        level = value
        val s = value.roundToInt().coerceIn(0, KNOWLEDGE_LEVEL_COUNT - 1)
        if (s != step) {
            step = s
            haptics.selection()
        }
    }

    fun label(i: Int) = StringStore.text(context, "onboardingV2.knowledge.level${i + 1}", language)

    OnboardingPage(
        contentArrangement = Arrangement.Top,
        footer = {
            OnboardingCta(StringStore.text(context, "common.continue", language), { onContinue(step) })
        },
    ) {
        Spacer(Modifier.height(72.dp))
        QuestionHeader(
            title = StringStore.text(context, "onboardingV2.knowledge.title", language),
            subtitle = StringStore.text(context, "onboardingV2.knowledge.subtitle", language),
        )
        Spacer(Modifier.height(36.dp))
        AnimatedContent(
            targetState = step,
            transitionSpec = {
                (scaleIn(spring(dampingRatio = 0.78f, stiffness = Spring.StiffnessMedium), initialScale = 0.6f) + fadeIn()) togetherWith
                    (scaleOut(targetScale = 0.6f) + fadeOut())
            },
            modifier = Modifier.height(150.dp).ov2Reveal(250),
            label = "knowledgeLevel",
        ) { s ->
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterVertically),
                modifier = Modifier.fillMaxWidth().height(150.dp),
            ) {
                Text(KNOWLEDGE_EMOJI[s], fontSize = 64.sp)
                Text(text = label(s), style = OV2.title.copy(color = OV2.accent), textAlign = TextAlign.Center)
            }
        }
        Spacer(Modifier.height(28.dp))

        val thumbSize = 30.dp
        // A scale from « not great » to « very good » laid out by hand: kept left to right in
        // every language, so the finger and the thumb always agree.
        CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
        BoxWithConstraints(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 36.dp)
                .ov2Reveal(350),
        ) {
            val density = LocalDensity.current
            val widthPx = with(density) { maxWidth.toPx() }
            val insetPx = with(density) { (thumbSize / 2).toPx() }
            val spanPx = (widthPx - insetPx * 2).coerceAtLeast(1f)
            fun tickX(i: Int) = insetPx + spanPx * i / (KNOWLEDGE_LEVEL_COUNT - 1)
            val thumbX = insetPx + spanPx * settled / (KNOWLEDGE_LEVEL_COUNT - 1)
            val labelWidth = with(density) { (spanPx / (KNOWLEDGE_LEVEL_COUNT - 1)).toDp() } - 6.dp
            val title = StringStore.text(context, "onboardingV2.knowledge.title", language)

            Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(thumbSize + 8.dp)
                        .semantics {
                            contentDescription = title
                            stateDescription = label(step)
                            progressBarRangeInfo = androidx.compose.ui.semantics.ProgressBarRangeInfo(
                                current = step.toFloat(),
                                range = 0f..(KNOWLEDGE_LEVEL_COUNT - 1).toFloat(),
                                steps = KNOWLEDGE_LEVEL_COUNT - 2,
                            )
                            setProgress { target ->
                                val s = target.roundToInt().coerceIn(0, KNOWLEDGE_LEVEL_COUNT - 1)
                                move(s.toFloat())
                                true
                            }
                        }
                        .pointerInput(spanPx) {
                            awaitEachGesture {
                                val down = awaitFirstDown()
                                dragging = true
                                move(((down.position.x - insetPx) / spanPx).coerceIn(0f, 1f) * (KNOWLEDGE_LEVEL_COUNT - 1))
                                drag(down.id) { change ->
                                    change.consume()
                                    move(((change.position.x - insetPx) / spanPx).coerceIn(0f, 1f) * (KNOWLEDGE_LEVEL_COUNT - 1))
                                }
                                dragging = false
                                level = step.toFloat()
                            }
                        },
                    contentAlignment = Alignment.CenterStart,
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(6.dp)
                            .background(OV2.hairline, CircleShape),
                    )
                    Box(
                        modifier = Modifier
                            .width(with(density) { thumbX.toDp() })
                            .height(6.dp)
                            .background(OV2.accent, CircleShape),
                    )
                    repeat(KNOWLEDGE_LEVEL_COUNT) { i ->
                        Box(
                            modifier = Modifier
                                .offset { IntOffset((tickX(i) - 7.dp.toPx()).roundToInt(), 0) }
                                .size(14.dp)
                                .background(if (i <= step) OV2.accent else OV2.hairline, CircleShape)
                                .border(2.dp, OV2.bg, CircleShape),
                        )
                    }
                    Box(
                        modifier = Modifier
                            .offset { IntOffset((thumbX - (thumbSize / 2).toPx()).roundToInt(), 0) }
                            .graphicsLayer { scaleX = thumbScale; scaleY = thumbScale }
                            .size(thumbSize)
                            .shadow(6.dp, CircleShape)
                            .background(Color.White, CircleShape)
                            .border(3.dp, OV2.accent, CircleShape),
                    )
                }
                // One label centred under each notch, all the same width, two lines at most.
                Box(modifier = Modifier.fillMaxWidth().height(36.dp)) {
                    repeat(KNOWLEDGE_LEVEL_COUNT) { i ->
                        Text(
                            text = label(i),
                            style = OV2.caption.copy(
                                fontSize = 12.sp,
                                lineHeight = 15.sp,
                                fontWeight = if (i == step) FontWeight.Bold else FontWeight.Medium,
                                color = if (i == step) OV2.accent else OV2.inkTertiary,
                            ),
                            textAlign = TextAlign.Center,
                            maxLines = 2,
                            modifier = Modifier
                                .width(labelWidth)
                                .offset { IntOffset((tickX(i) - labelWidth.toPx() / 2f).roundToInt(), 0) },
                        )
                    }
                }
            }
        }
        }
        Spacer(Modifier.height(24.dp))
    }
}

// MARK: - Subjects

/** « Which subjects interest you most? »: the six subjects as squares, two per row, several answers. */
@Composable
internal fun TopicsStep(
    language: AppLanguage,
    selected: List<String>,
    onToggle: (String) -> Unit,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    val haptics = rememberOnboardingHaptics()
    val subjects = Subject.entries
    val revealed = rememberRowReveal(subjects.size)
    BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
        val spacing = 12.dp
        // Two squares per row across, three rows down when it fits; never under 96dp.
        val byWidth = (minOf(maxWidth, READABLE_WIDTH) - 48.dp - spacing) / 2
        val chrome = if (maxHeight < 700.dp) 300.dp else 330.dp
        val byHeight = (maxHeight - chrome - spacing * 2) / 3
        val side = minOf(byWidth, byHeight).coerceAtLeast(96.dp)
        val topSpacing = if (maxHeight < 700.dp) 48.dp else 72.dp
        Column(modifier = Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
            Spacer(Modifier.height(topSpacing))
            QuestionHeader(
                title = StringStore.text(context, "onboardingV2.topics.title", language),
                subtitle = StringStore.text(context, "onboardingV2.topics.subtitle", language),
            )
            Spacer(Modifier.height(22.dp))
            Column(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(vertical = 8.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(spacing),
            ) {
                subjects.chunked(2).forEachIndexed { row, pair ->
                    Row(horizontalArrangement = Arrangement.spacedBy(spacing)) {
                        pair.forEachIndexed { column, subject ->
                            val index = row * 2 + column
                            TopicSquare(
                                subject = subject,
                                label = StringStore.text(context, "subject.${subject.storageKey}.short", language),
                                side = side,
                                selected = subject.storageKey in selected,
                                visible = index < revealed,
                                onClick = {
                                    haptics.selection()
                                    onToggle(subject.storageKey)
                                },
                            )
                        }
                    }
                }
            }
            OnboardingCta(
                text = StringStore.text(context, "common.continue", language),
                onClick = onContinue,
                enabled = selected.isNotEmpty(),
            )
        }
    }
}

@Composable
private fun TopicSquare(
    subject: Subject,
    label: String,
    side: androidx.compose.ui.unit.Dp,
    selected: Boolean,
    visible: Boolean,
    onClick: () -> Unit,
) {
    val shape = RoundedCornerShape(app.rork.sophia.ui.theme.DS.Radius.card)
    val progress by animateFloatAsState(
        targetValue = if (visible) 1f else 0f,
        animationSpec = spring(dampingRatio = 0.8f, stiffness = Spring.StiffnessMediumLow),
        label = "topicReveal",
    )
    val checkScale by animateFloatAsState(
        targetValue = if (selected) 1f else 0f,
        animationSpec = spring(dampingRatio = 0.75f, stiffness = Spring.StiffnessMedium),
        label = "topicCheck",
    )
    val emojiSize = with(LocalDensity.current) { (side * 0.3f).toSp() }
    Box(
        modifier = Modifier
            .size(side)
            .graphicsLayer {
                alpha = progress.coerceIn(0f, 1f)
                translationY = (1f - progress) * 18f * density
                val s = 0.94f + 0.06f * progress
                scaleX = s
                scaleY = s
            }
            .shadow(if (selected) 6.dp else 3.dp, shape, ambientColor = Color.Black.copy(alpha = 0.08f), spotColor = Color.Black.copy(alpha = 0.08f))
            .clip(shape)
            // Opaque first: a see-through tint lets the shadow underneath show as a frame.
            .background(OV2.surface)
            .background(if (selected) OV2.accentSoft.copy(alpha = 0.08f) else Color.Transparent)
            .border(if (selected) 2.dp else 1.dp, if (selected) OV2.accent else OV2.hairline, shape)
            .clickable(onClick = onClick),
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(10.dp, Alignment.CenterVertically),
        ) {
            Box(
                modifier = Modifier
                    .size(side * 0.46f)
                    .background(subject.color.copy(alpha = if (selected) 0.24f else 0.14f), CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Text(SUBJECT_EMOJI[subject].orEmpty(), fontSize = emojiSize)
            }
            Text(
                text = label,
                style = OV2.subheadline.copy(color = OV2.ink, fontWeight = FontWeight.Bold),
                textAlign = TextAlign.Center,
                maxLines = 2,
                modifier = Modifier.padding(horizontal = 8.dp),
            )
        }
        Box(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(10.dp)
                .size(24.dp)
                .graphicsLayer { scaleX = checkScale; scaleY = checkScale; alpha = checkScale }
                .background(OV2.accent, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(14.dp))
        }
    }
}
