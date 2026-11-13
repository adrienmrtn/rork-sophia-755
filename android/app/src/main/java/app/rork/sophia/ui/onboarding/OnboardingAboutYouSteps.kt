package app.rork.sophia.ui.onboarding

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Bolt
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.Eco
import androidx.compose.material.icons.outlined.Public
import androidx.compose.material.icons.outlined.WorkOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.R
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Subject
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.newgen.AvatarCircle
import app.rork.sophia.ui.newgen.Avatars
import app.rork.sophia.ui.theme.DS
import kotlinx.coroutines.delay
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.PageSize
import androidx.compose.foundation.pager.PagerDefaults
import androidx.compose.foundation.pager.PagerSnapDistance
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.snapshotFlow
import kotlinx.coroutines.launch
import kotlin.math.abs

/**
 * The « about you » pages of the onboarding, right before the objectives: first name, age,
 * general knowledge, motivation; then, after the objectives, the subjects of interest (six
 * rows to tick). The first name is not repeated in the questions: it comes back where it
 * carries (« Sophia will help you… », loading, profile, after the account).
 *
 * Shared layout (« Elevate arrondi » style): centred title in a medium weight, grey subtitle,
 * a round illustration when the height allows, then the answers as option cards
 * ([OV2CoreOptionRow]) and the pinned call to action. The header (back arrow, progress) is
 * laid out by the coordinator.
 */

internal const val FIRST_NAME_MAX_LENGTH = 24
internal val AGE_RANGE_KEYS = listOf("under18", "18to24", "25to34", "35to44", "45to54", "55plus")
internal const val KNOWLEDGE_LEVEL_COUNT = 4
internal val MOTIVATION_KEYS = listOf("grow", "conversations", "career", "sharp", "world")
internal val SUBJECT_EMOJI = mapOf(
    Subject.HISTOIRE to "🗽",
    Subject.SCIENCES to "🦠",
    Subject.LITTERATURE to "📖",
    Subject.ART to "🎨",
    Subject.MYTHOLOGIE to "⚡",
    Subject.COMPRENDRE_LE_MONDE to "🌍",
)

/** Line pictogram of each motivation, in its own colour. */
private fun motivationIcon(key: String): ImageVector = when (key) {
    "grow" -> Icons.Outlined.Eco
    "conversations" -> Icons.Outlined.ChatBubbleOutline
    "career" -> Icons.Outlined.WorkOutline
    "sharp" -> Icons.Outlined.Bolt
    "world" -> Icons.Outlined.Public
    else -> Icons.Outlined.Public
}

private fun motivationColor(key: String): Color = when (key) {
    "grow" -> DS.success
    "conversations" -> DS.danger
    "career" -> Color(0xFF8A5A00)
    "sharp" -> Color(0xFF6B3FA0)
    else -> DS.accent
}

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

/** The option cards of a question, 10 dp apart, under the title (and the illustration). */
@Composable
private fun OptionRows(topPadding: Dp, content: @Composable () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = OV2Core.sideInset)
            .padding(top = topPadding, bottom = 16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        content()
    }
}

// MARK: - First name

/** Diamètre de l'avatar choisi, au centre du carrousel de la page du prénom ; ses voisins sont réduits. */
private val NAME_AVATAR_SIZE = 116.dp

/**
 * « What's your name? »: one field, the keyboard coming up by itself, « Continue » as soon as
 * there is a name, and « Skip » for anyone who would rather not say.
 *
 * On y choisit aussi son avatar : un carrousel sur toute la largeur, l'avatar choisi en grand
 * au centre, que l'on change en balayant à gauche ou à droite. Un avatar est toujours proposé d'entrée ([initialAvatarId],
 * sinon un tiré au hasard) ; il est rendu avec le prénom, que l'on continue ou que l'on
 * passe.
 */
@Composable
internal fun NameStep(
    language: AppLanguage,
    initialName: String,
    /** L'avatar déjà choisi (retour sur la page, reprise après fermeture), ou null au premier passage. */
    initialAvatarId: String?,
    onSubmit: (name: String, avatarId: String) -> Unit,
) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val keyboard = LocalSoftwareKeyboardController.current
    val focusRequester = remember { FocusRequester() }
    var name by rememberSaveable { mutableStateOf(initialName) }
    var avatarId by rememberSaveable {
        mutableStateOf(initialAvatarId?.takeIf { Avatars.drawable(it) != null } ?: Avatars.all.random())
    }
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
        onSubmit(trimmed, avatarId)
    }

    // The keyboard takes half of a small screen: the content scrolls if it must, the CTA stays
    // above the keyboard.
    OV2CorePage(
        modifier = Modifier.imePadding(),
        footer = {
            OnboardingCta(
                text = StringStore.text(context, "common.continue", language),
                onClick = { commit() },
                enabled = trimmed.isNotEmpty(),
                bottomInset = 8.dp,
            )
            // « Skip »: the secondary button of the style, pale blue outline on white.
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = OV2Core.sideInset)
                    .padding(bottom = 20.dp)
                    .semantics { role = Role.Button }
                    .pressable(
                        onClick = {
                            keyboard?.hide()
                            haptics.select()
                            onSubmit("", avatarId)
                        },
                        haptic = false,
                    )
                    .ov2CoreOutlined(edge = DS.accent.copy(alpha = 0.33f), fill = DS.surface, lip = 0.dp)
                    .heightIn(min = 54.dp)
                    .padding(horizontal = 12.dp, vertical = 8.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = StringStore.text(context, "onboardingV2.name.skip", language),
                    style = OV2.body.copy(color = DS.accent, fontWeight = FontWeight.SemiBold, letterSpacing = 0.2.sp),
                    textAlign = TextAlign.Center,
                )
            }
        },
    ) {
        OV2CoreQuestionTitle(
            title = StringStore.text(context, "onboardingV2.name.title", language),
            modifier = Modifier.padding(top = OV2Core.topInset).dsStagger(0),
        )
        // Le choix de l'avatar, à la place de l'illustration : « Choisis ton avatar » et la
        // ligne des avatars.
        val avatarLabel = StringStore.text(context, "profile.avatar.title", language)
        Text(
            text = avatarLabel,
            style = ov2CoreSubtitleStyle,
            textAlign = TextAlign.Center,
            modifier = Modifier
                .padding(horizontal = OV2Core.sideInset)
                .padding(top = 20.dp)
                .dsStagger(1),
        )
        NameAvatarCarousel(
            selected = avatarId,
            label = avatarLabel,
            onSelect = { id ->
                if (id != avatarId) {
                    haptics.select()
                    avatarId = id
                }
            },
            modifier = Modifier.padding(top = 10.dp).dsStagger(1),
        )
        val edge by animateColorAsState(if (focused) DS.accent else DS.hairline, OV2Calm.quick(), label = "nameBorder")
        val fieldStyle = OV2.headline.copy(fontSize = 17.sp, lineHeight = 23.sp, fontWeight = FontWeight.SemiBold, color = DS.ink)
        BasicTextField(
            value = name,
            onValueChange = { name = it.take(FIRST_NAME_MAX_LENGTH) },
            singleLine = true,
            textStyle = fieldStyle,
            cursorBrush = SolidColor(DS.accent),
            keyboardOptions = KeyboardOptions(
                capitalization = KeyboardCapitalization.Words,
                autoCorrectEnabled = false,
                imeAction = ImeAction.Next,
            ),
            keyboardActions = KeyboardActions(onNext = { commit() }, onDone = { commit() }),
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = OV2Core.sideInset)
                .padding(top = 22.dp)
                .dsStagger(2)
                .focusRequester(focusRequester)
                .onFocusChanged { focused = it.isFocused },
            decorationBox = { inner ->
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .ov2CoreOutlined(edge = edge, fill = DS.surface)
                        .heightIn(min = 58.dp)
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    contentAlignment = Alignment.CenterStart,
                ) {
                    if (name.isEmpty()) {
                        Text(
                            text = StringStore.text(context, "onboardingV2.name.placeholder", language),
                            style = fieldStyle.copy(color = DS.inkTertiary),
                            modifier = Modifier.fillMaxWidth(),
                        )
                    }
                    inner()
                }
            },
        )
        Spacer(Modifier.height(12.dp))
    }
}

/**
 * Les avatars de l'app (`avatar_01`…) en carrousel sur toute la largeur de la page : celui du
 * centre est le choix, affiché en grand et cerclé de bleu ; ses voisins, réduits et estompés,
 * dépassent de chaque côté. On change d'avatar en balayant la ligne à gauche ou à droite
 * (le défilement s'aimante sur un avatar), ou en touchant un voisin. Le carrousel s'ouvre sur
 * l'avatar déjà choisi. Mêmes ronds ([AvatarCircle]) que la feuille de choix du profil.
 */
@Composable
private fun NameAvatarCarousel(
    selected: String,
    label: String,
    onSelect: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val avatars = Avatars.all
    val pagerState = rememberPagerState(
        initialPage = avatars.indexOf(selected).coerceAtLeast(0),
        pageCount = { avatars.size },
    )
    val scope = rememberCoroutineScope()
    val choose by rememberUpdatedState(onSelect)
    // Le choix suit l'avatar du centre.
    LaunchedEffect(pagerState) {
        snapshotFlow { pagerState.currentPage }.collect { page ->
            avatars.getOrNull(page)?.let { choose(it) }
        }
    }
    BoxWithConstraints(modifier = modifier.fillMaxWidth()) {
        // L'avatar du centre est au milieu de la ligne : la même marge de chaque côté.
        val side = ((maxWidth - NAME_AVATAR_SIZE) / 2).coerceAtLeast(0.dp)
        HorizontalPager(
            state = pagerState,
            modifier = Modifier.fillMaxWidth(),
            contentPadding = PaddingValues(horizontal = side, vertical = 4.dp),
            pageSize = PageSize.Fixed(NAME_AVATAR_SIZE),
            pageSpacing = 6.dp,
            // Un grand geste peut faire défiler plusieurs avatars d'un coup.
            flingBehavior = PagerDefaults.flingBehavior(
                state = pagerState,
                pagerSnapDistance = PagerSnapDistance.atMost(6),
            ),
            verticalAlignment = Alignment.CenterVertically,
            key = { avatars[it] },
        ) { page ->
            val id = avatars[page]
            val isSelected = page == pagerState.currentPage
            AvatarCircle(
                avatarId = id,
                initial = "",
                size = NAME_AVATAR_SIZE,
                modifier = Modifier
                    .graphicsLayer {
                        // Distance au centre, en avatars : 0 au centre, 1 pour un voisin.
                        val distance = abs((pagerState.currentPage - page) + pagerState.currentPageOffsetFraction)
                            .coerceIn(0f, 1f)
                        val scale = 1f - 0.4f * distance
                        scaleX = scale
                        scaleY = scale
                        alpha = 1f - 0.45f * distance
                    }
                    // Un choix : la vibration « sélection » est donnée par la page, pas par l'appui.
                    .pressable(
                        onClick = { scope.launch { pagerState.animateScrollToPage(page) } },
                        scaleDown = 0.94f,
                        haptic = false,
                    )
                    .border(3.dp, if (isSelected) DS.accent else DS.accent.copy(alpha = 0f), CircleShape)
                    .semantics {
                        this.selected = isSelected
                        role = Role.RadioButton
                        contentDescription = "$label ${page + 1}"
                    },
            )
        }
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
    OV2CorePage(
        footer = {
            OnboardingCta(
                text = StringStore.text(context, "common.continue", language),
                onClick = onContinue,
                enabled = selected != null,
            )
        },
    ) { available ->
        val art = OV2Core.artSize(base = 124.dp, available = available, reserved = 478.dp)
        OV2CoreQuestionTitle(
            title = StringStore.text(context, "onboardingV2.age.title", language),
            modifier = Modifier.padding(top = OV2Core.topInset).dsStagger(0),
        )
        if (art > 0.dp) {
            OV2CoreIllustration(
                art = R.drawable.onb_art_mirror,
                size = art,
                modifier = Modifier.padding(top = 22.dp).ov2CalmIn(120),
            )
        }
        OptionRows(topPadding = 24.dp) {
            AGE_RANGE_KEYS.forEachIndexed { index, key ->
                OV2CoreOptionRow(
                    label = StringStore.text(context, "onboardingV2.age.$key", language),
                    selected = key == selected,
                    onClick = { onSelect(key) },
                    modifier = Modifier.dsStagger(index, baseMillis = 180),
                )
            }
        }
    }
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
    OV2CorePage(
        footer = {
            OnboardingCta(
                text = StringStore.text(context, "common.continue", language),
                onClick = onContinue,
                enabled = selected != null,
            )
        },
    ) {
        OV2CoreQuestionTitle(
            title = StringStore.text(context, "onboardingV2.motivation.title", language),
            subtitle = StringStore.text(context, "onboardingV2.motivation.subtitle", language),
            modifier = Modifier.padding(top = OV2Core.topInset).dsStagger(0),
        )
        OptionRows(topPadding = 28.dp) {
            MOTIVATION_KEYS.forEachIndexed { index, key ->
                OV2CoreOptionRow(
                    label = StringStore.text(context, "onboardingV2.motivation.$key", language),
                    selected = key == selected,
                    onClick = { onSelect(key) },
                    modifier = Modifier.dsStagger(index, baseMillis = 140),
                    leading = {
                        Icon(
                            imageVector = motivationIcon(key),
                            contentDescription = null,
                            tint = motivationColor(key),
                            modifier = Modifier.size(24.dp),
                        )
                    },
                )
            }
        }
    }
}

// MARK: - General knowledge

/**
 * « How would you rate your general knowledge? »: four levels, from « not great » to « very
 * good », one answer. The level already known is preselected, so « Continue » is always
 * available; the value handed back is the index of the level, 0 to 3, as before.
 */
@Composable
internal fun KnowledgeStep(
    language: AppLanguage,
    initialLevel: Int,
    onContinue: (Int) -> Unit,
) {
    val context = LocalContext.current
    var step by rememberSaveable { mutableIntStateOf(initialLevel.coerceIn(0, KNOWLEDGE_LEVEL_COUNT - 1)) }

    OV2CorePage(
        footer = {
            OnboardingCta(StringStore.text(context, "common.continue", language), { onContinue(step) })
        },
    ) { available ->
        val art = OV2Core.artSize(base = 124.dp, available = available, reserved = 430.dp)
        OV2CoreQuestionTitle(
            title = StringStore.text(context, "onboardingV2.knowledge.title", language),
            subtitle = StringStore.text(context, "onboardingV2.knowledge.subtitle", language),
            modifier = Modifier.padding(top = OV2Core.topInset).dsStagger(0),
        )
        if (art > 0.dp) {
            OV2CoreIllustration(
                art = R.drawable.onb_art_growth,
                size = art,
                modifier = Modifier.padding(top = 22.dp).ov2CalmIn(120),
            )
        }
        OptionRows(topPadding = 24.dp) {
            repeat(KNOWLEDGE_LEVEL_COUNT) { level ->
                OV2CoreOptionRow(
                    label = StringStore.text(context, "onboardingV2.knowledge.level${level + 1}", language),
                    selected = level == step,
                    onClick = { step = level },
                    modifier = Modifier.dsStagger(level, baseMillis = 180),
                )
            }
        }
    }
}

// MARK: - Subjects

/**
 * « Which subjects interest you most? »: the six subjects, one row each with its thumbnail and
 * a box to tick, several answers.
 */
@Composable
internal fun TopicsStep(
    language: AppLanguage,
    selected: List<String>,
    onToggle: (String) -> Unit,
    onContinue: () -> Unit,
) {
    val context = LocalContext.current
    OV2CorePage(
        footer = {
            OnboardingCta(
                text = StringStore.text(context, "common.continue", language),
                onClick = onContinue,
                enabled = selected.isNotEmpty(),
            )
        },
    ) {
        OV2CoreQuestionTitle(
            title = StringStore.text(context, "onboardingV2.topics.title", language),
            subtitle = StringStore.text(context, "onboardingV2.topics.subtitle", language),
            modifier = Modifier.padding(top = OV2Core.topInset).dsStagger(0),
        )
        OptionRows(topPadding = 28.dp) {
            Subject.entries.forEachIndexed { index, subject ->
                OV2CoreOptionRow(
                    label = StringStore.text(context, "subject.${subject.storageKey}.short", language),
                    selected = subject.storageKey in selected,
                    onClick = { onToggle(subject.storageKey) },
                    modifier = Modifier.dsStagger(index, baseMillis = 140),
                    showsCheckbox = true,
                    leading = { OV2CoreSubjectBadge(subject = subject, size = 30.dp) },
                )
            }
        }
    }
}
