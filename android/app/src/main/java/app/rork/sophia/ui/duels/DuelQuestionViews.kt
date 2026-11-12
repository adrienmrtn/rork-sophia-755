package app.rork.sophia.ui.duels

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.drag
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.DuelBotAnswer
import app.rork.sophia.domain.DuelMatch
import app.rork.sophia.domain.DuelOpponent
import app.rork.sophia.domain.DuelQuestion
import app.rork.sophia.domain.DuelQuestionKind
import app.rork.sophia.ui.components.DSCheckBadge
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.DSOptionState
import app.rork.sophia.ui.components.dsOptionCard
import app.rork.sophia.ui.components.dsPopIn
import app.rork.sophia.ui.components.dsShake
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.newgen.AvatarCircle
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import coil.compose.AsyncImage
import kotlin.math.PI
import kotlin.math.ceil
import kotlin.math.sin
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.Image
import coil.compose.AsyncImagePainter
import coil.compose.rememberAsyncImagePainter

// Les réponses d'une question, le chrono et le fil du score : mêmes états et mêmes proportions
// que `ios/Sophia/Views/Duels/DuelQuestionViews.swift`.

/**
 * Ce que l'écran montre d'une question à un instant donné. La question qui sort de l'écran
 * garde sa dernière image (dévoilée) pendant que la suivante arrive : l'état de la partie, lui,
 * est déjà remis à zéro.
 */
internal data class DuelQuestionUi(
    val question: DuelQuestion,
    /** La matière de la manche au choix en cours. */
    val subject: String?,
    val revealed: Boolean,
    val playerLocked: Boolean,
    val selectedChoice: Int?,
    val sliderValue: Double,
    /** La réponse de l'adversaire, montrée à la révélation. */
    val opponentAnswer: DuelBotAnswer,
)

internal fun DuelGameModel.questionUi(): DuelQuestionUi = DuelQuestionUi(
    question = question,
    subject = currentSubject,
    // Une question dévoilée le reste sous l'annonce qui la suit, jusqu'à la question suivante.
    revealed = phase != DuelPhase.Answering && lastRound != null,
    playerLocked = playerLocked,
    selectedChoice = selectedChoice,
    sliderValue = sliderValue,
    opponentAnswer = opponentAnswer,
)

// ---------------------------------------------------------------- options (QCM, vrai/faux, image)

/** L'état d'une option à l'écran. */
internal enum class DuelOptionState {
    /** Le chrono tourne, rien n'est choisi. */
    Idle,

    /** Choisie par le joueur, en attente de la révélation. */
    Selected,

    /** La bonne réponse, dévoilée. */
    Correct,

    /** Un mauvais choix dévoilé : celui du joueur, ou celui de l'adversaire. */
    Wrong,

    /** Une option ni choisie ni juste : en retrait. */
    Dimmed,
}

internal fun duelOptionState(option: Int, ui: DuelQuestionUi): DuelOptionState = when {
    ui.revealed -> when (option) {
        ui.question.correctIndex -> DuelOptionState.Correct
        ui.selectedChoice -> DuelOptionState.Wrong
        // Le mauvais choix de l'adversaire se lit aussi en rouge, sous son avatar.
        ui.opponentAnswer.choice -> DuelOptionState.Wrong
        else -> DuelOptionState.Dimmed
    }
    ui.playerLocked -> if (option == ui.selectedChoice) DuelOptionState.Selected else DuelOptionState.Dimmed
    else -> DuelOptionState.Idle
}

/**
 * Une réponse en carte : blanche bordée au repos, bleue une fois choisie, verte avec sa coche
 * quand elle est juste, rouge quand elle est fausse. À la révélation, « Toi » marque le choix
 * du joueur et l'avatar de l'adversaire le sien.
 */
@Composable
internal fun DuelOptionButton(
    text: String,
    state: DuelOptionState,
    opponent: DuelOpponent,
    /** L'avatar de l'adversaire, posé sur l'option qu'il a choisie à la révélation. */
    showsOpponent: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    minHeight: Dp = 56.dp,
    /** L'option que le joueur a choisie. */
    isPlayerChoice: Boolean = false,
    /** Carte étroite (grille 2 × 2, vrai/faux) : les marques se réduisent aux pastilles. */
    compact: Boolean = false,
    /** « Toi », écrit à côté de la marque du joueur quand la carte est assez large. */
    youLabel: String = "",
) {
    val cardState = when (state) {
        DuelOptionState.Idle -> DSOptionState.Idle
        DuelOptionState.Selected -> DSOptionState.Selected
        DuelOptionState.Correct -> DSOptionState.Correct
        DuelOptionState.Wrong -> DSOptionState.Wrong
        DuelOptionState.Dimmed -> DSOptionState.Dimmed
    }
    val foreground by animateColorAsState(
        targetValue = when (state) {
            DuelOptionState.Idle, DuelOptionState.Selected, DuelOptionState.Wrong -> DS.ink
            DuelOptionState.Correct -> DS.success
            DuelOptionState.Dimmed -> DS.inkTertiary
        },
        animationSpec = DSMotion.snappy(),
        label = "duelOptionInk",
    )
    val weight = when (state) {
        DuelOptionState.Idle, DuelOptionState.Wrong -> FontWeight.SemiBold
        DuelOptionState.Selected -> FontWeight.Bold
        DuelOptionState.Correct -> FontWeight.ExtraBold
        DuelOptionState.Dimmed -> FontWeight.Medium
    }
    // La couleur des marques (« Toi », pseudo de l'adversaire) sur une carte dévoilée.
    val tagColor = when (state) {
        DuelOptionState.Correct -> DS.success
        DuelOptionState.Wrong -> DS.danger
        else -> DS.inkSecondary
    }
    // Le joueur a choisi cette option et son verdict est tombé.
    val playerRevealed = isPlayerChoice && (state == DuelOptionState.Correct || state == DuelOptionState.Wrong)
    val scale by animateFloatAsState(
        targetValue = when (state) {
            DuelOptionState.Correct -> 1.02f
            DuelOptionState.Selected -> 0.985f
            else -> 1f
        },
        animationSpec = DSMotion.pop(),
        label = "duelOptionScale",
    )
    Row(
        modifier = modifier
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            }
            // Le verrouillage de la réponse vibre déjà (`DuelHaptic.Lock`).
            .pressable(onClick = onClick, enabled = state == DuelOptionState.Idle, haptic = false)
            .heightIn(min = minHeight)
            .dsOptionCard(cardState)
            .padding(horizontal = if (compact) 12.dp else 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        if (icon != null) {
            Icon(icon, contentDescription = null, tint = foreground, modifier = Modifier.size(18.dp))
        }
        DuelShrinkText(
            text = text,
            fontSize = 16.sp,
            fontWeight = weight,
            color = foreground,
            maxLines = if (compact) 3 else 2,
            modifier = Modifier.weight(1f),
        )
        // L'avatar de l'adversaire (et son pseudo quand il y a la place) sur l'option qu'il a choisie.
        AnimatedVisibility(
            visible = showsOpponent,
            enter = scaleIn(DSMotion.pop(), initialScale = 0.2f) + fadeIn(),
            exit = fadeOut(tween(100)),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                if (!compact && !playerRevealed && opponent.handle.isNotEmpty()) {
                    Text(
                        text = "@${opponent.handle}",
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 12.sp,
                        color = tagColor,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.widthIn(max = 110.dp),
                    )
                }
                DuelOpponentMarker(opponent)
            }
        }
        // La coche de la bonne réponse, ou la croix du mauvais choix du joueur, précédée de « Toi ».
        if (state == DuelOptionState.Correct || (state == DuelOptionState.Wrong && isPlayerChoice)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                if (playerRevealed && !compact && youLabel.isNotEmpty()) {
                    Text(
                        text = youLabel,
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 12.sp,
                        color = tagColor,
                        maxLines = 1,
                    )
                }
                if (state == DuelOptionState.Correct) {
                    DSCheckBadge(size = 26.dp, fill = DS.success)
                } else {
                    Box(
                        modifier = Modifier.dsPopIn().size(26.dp).background(DS.danger, CircleShape),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(Icons.Filled.Close, contentDescription = null, tint = Color.White, modifier = Modifier.size(14.dp))
                    }
                }
            }
        }
    }
}

/** Le petit avatar de l'adversaire, cerclé de sa couleur (safran) : là où il a répondu. */
@Composable
internal fun DuelOpponentMarker(opponent: DuelOpponent, modifier: Modifier = Modifier) {
    Box(modifier = modifier.size(26.dp)) {
        AvatarCircle(avatarId = opponent.avatarId, initial = opponent.initial, size = 26.dp)
        Box(modifier = Modifier.matchParentSize().border(2.dp, DuelPalette.saffron, CircleShape))
    }
}

/**
 * Les options d'une question à choix : une colonne pour un QCM (deux options comprises), une
 * grille 2 × 2 sous une image, deux grandes tuiles pour un vrai/faux.
 */
@Composable
internal fun DuelChoiceAnswers(
    ui: DuelQuestionUi,
    opponent: DuelOpponent,
    language: AppLanguage,
    onChoose: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val options = ui.question.options.orEmpty()
    val youLabel = StringStore.text(LocalContext.current, "duel.you", language)
    when (ui.question.kind) {
        DuelQuestionKind.TRUE_FALSE -> Row(
            modifier = modifier.fillMaxWidth().height(IntrinsicSize.Min),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            options.indices.forEach { index ->
                ChoiceOption(
                    ui, index, opponent, youLabel, onChoose,
                    modifier = Modifier.weight(1f).fillMaxHeight(),
                    icon = if (index == 0) Icons.Filled.Check else Icons.Filled.Close,
                    minHeight = 84.dp,
                    compact = true,
                )
            }
        }
        DuelQuestionKind.PORTRAIT -> Column(modifier = modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            options.indices.chunked(2).forEach { pair ->
                Row(
                    modifier = Modifier.fillMaxWidth().height(IntrinsicSize.Min),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    pair.forEach { index ->
                        ChoiceOption(
                            ui, index, opponent, youLabel, onChoose,
                            modifier = Modifier.weight(1f).fillMaxHeight(),
                            icon = null,
                            minHeight = 60.dp,
                            compact = true,
                        )
                    }
                    // Un nombre impair d'options : la dernière garde la largeur d'une colonne.
                    if (pair.size == 1) Spacer(Modifier.weight(1f))
                }
            }
        }
        else -> Column(modifier = modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            options.indices.forEach { index ->
                ChoiceOption(
                    ui, index, opponent, youLabel, onChoose,
                    modifier = Modifier.fillMaxWidth(),
                    icon = null,
                    minHeight = 56.dp,
                    compact = false,
                )
            }
        }
    }
}

@Composable
private fun ChoiceOption(
    ui: DuelQuestionUi,
    index: Int,
    opponent: DuelOpponent,
    youLabel: String,
    onChoose: (Int) -> Unit,
    modifier: Modifier,
    icon: ImageVector?,
    minHeight: Dp,
    compact: Boolean,
) {
    val mine = ui.selectedChoice == index
    // Le mauvais choix du joueur est dévoilé : sa carte tremble. La vibration du verdict vient
    // du déroulé (`DuelHaptic.Wrong`).
    val mineWrong = ui.revealed && mine && index != ui.question.correctIndex
    var shakes by remember { mutableIntStateOf(0) }
    LaunchedEffect(mineWrong) {
        if (mineWrong) shakes += 1
    }
    DuelOptionButton(
        text = ui.question.options.orEmpty().getOrNull(index).orEmpty(),
        state = duelOptionState(index, ui),
        opponent = opponent,
        showsOpponent = ui.revealed && ui.opponentAnswer.choice == index,
        onClick = { onChoose(index) },
        modifier = modifier
            .dsStagger(index, stepMillis = 50, baseMillis = 60, offset = 10.dp)
            .dsShake(trigger = shakes),
        icon = icon,
        minHeight = minHeight,
        isPlayerChoice = mine,
        compact = compact,
        youLabel = youLabel,
    )
}

/**
 * L'image d'une question (portrait, drapeau, tableau, monument) : montrée entière, à ses
 * proportions, coins arrondis, sans fond, comme sur iOS. Un drapeau arrive rogné de sa marge
 * beige ([DuelTrimTransformation]) et se pose à même la page, avec un filet pour que ses bords
 * blancs se détachent. L'image est déjà en cache, chargée pendant la présentation de
 * l'adversaire ; tant qu'elle n'est pas là, la place reste vide.
 */
@Composable
internal fun DuelQuestionImage(url: String?, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    // Sur un écran court (moins de 700 dp de haut), l'image rétrécit pour que les quatre
    // réponses restent à l'écran sans défiler : le chrono tourne, on ne cherche pas ses réponses.
    val screenHeight = LocalConfiguration.current.screenHeightDp
    val scale = when {
        screenHeight < 600 -> 0.56f
        screenHeight < 700 -> 0.68f
        else -> 1f
    }
    Box(
        modifier = modifier.size(width = 230.dp * scale, height = 230.dp * scale),
        contentAlignment = Alignment.Center,
    ) {
        if (!url.isNullOrBlank()) {
            val request = remember(url) { duelQuestionImageRequest(context, url) }
            val painter = rememberAsyncImagePainter(model = request)
            val intrinsic = painter.intrinsicSize
            if (painter.state is AsyncImagePainter.State.Success && intrinsic.width > 0f && intrinsic.height > 0f) {
                // Un drapeau rogné : coins moins ronds et filet.
                val flat = DuelImageTrim.isFlat(intrinsic.width, intrinsic.height)
                val shape = RoundedCornerShape(if (flat) 8.dp else 16.dp)
                Image(
                    painter = painter,
                    contentDescription = null,
                    contentScale = ContentScale.Fit,
                    modifier = Modifier
                        .padding(vertical = if (flat) 8.dp else 0.dp)
                        .aspectRatio(intrinsic.width / intrinsic.height)
                        .clip(shape)
                        .then(if (flat) Modifier.border(1.5.dp, DS.hairline, shape) else Modifier),
                )
            } else {
                // Le peintre doit être posé pour charger : une place vide, sans rien dessiner.
                Image(painter = painter, contentDescription = null, modifier = Modifier.size(1.dp).alpha(0f))
            }
        }
    }
}

// ---------------------------------------------------------------- curseur

private val SLIDER_THUMB = 34.dp
private val SLIDER_MARKER = 26.dp

/**
 * Une question au curseur : une valeur à estimer, le plus proche de la bonne marque. Le joueur
 * glisse (ou ajuste d'un cran avec − et +), puis valide. À la révélation, la bonne valeur et
 * celle de l'adversaire viennent se poser sur la piste.
 */
@Composable
internal fun DuelSliderAnswer(
    ui: DuelQuestionUi,
    opponent: DuelOpponent,
    language: AppLanguage,
    /** Le joueur peut encore agir : la question est en cours, pas en train de sortir de l'écran. */
    interactive: Boolean,
    onSet: (Double) -> Unit,
    onNudge: (Double) -> Unit,
    onLock: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val question = ui.question
    val lower = question.sliderMin ?: 0.0
    val upper = question.sliderMax ?: 100.0
    val canMove = interactive && !ui.playerLocked && !ui.revealed

    fun fraction(value: Double): Float {
        if (upper <= lower) return 0f
        return ((value - lower) / (upper - lower)).coerceIn(0.0, 1.0).toFloat()
    }

    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        Text(
            text = DuelFormat.sliderValue(ui.sliderValue, question.unit),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 44.sp,
            lineHeight = 50.sp,
            style = DuelTabularDigits,
            color = DS.accent,
            maxLines = 1,
        )

        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            SliderStepButton(Icons.Filled.Remove, description = "−", enabled = canMove) { onNudge(-1.0) }

            // La piste se lit de gauche à droite dans toutes les langues, comme ses bornes.
            CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
                BoxWithConstraints(
                    modifier = Modifier
                        .weight(1f)
                        .height(96.dp)
                        .pointerInput(canMove, lower, upper) {
                            if (!canMove) return@pointerInput
                            val thumb = SLIDER_THUMB.toPx()
                            fun move(x: Float) {
                                val usable = maxOf(size.width - thumb, 1f)
                                val ratio = ((x - thumb / 2) / usable).coerceIn(0f, 1f)
                                onSet(lower + ratio * (upper - lower))
                            }
                            awaitEachGesture {
                                // Dès le doigt posé, sans seuil : la valeur suit tout de suite.
                                val down = awaitFirstDown(requireUnconsumed = false)
                                move(down.position.x)
                                down.consume()
                                drag(down.id) { change ->
                                    move(change.position.x)
                                    // Le glissement appartient au curseur, pas au défilement de la page.
                                    change.consume()
                                }
                            }
                        },
                ) {
                    val usable = maxOf(maxWidth - SLIDER_THUMB, 1.dp)
                    val position = usable * fraction(ui.sliderValue)

                    Box(
                        modifier = Modifier
                            .align(Alignment.CenterStart)
                            .fillMaxWidth()
                            .height(12.dp)
                            .background(DS.accentTint, CircleShape),
                    )
                    Box(
                        modifier = Modifier
                            .align(Alignment.CenterStart)
                            .width(SLIDER_THUMB / 2 + position)
                            .height(12.dp)
                            .background(DS.accent, CircleShape),
                    )

                    val correct = question.correctValue
                    androidx.compose.animation.AnimatedVisibility(
                        visible = ui.revealed && correct != null,
                        enter = scaleIn(
                            duelSpring(response = 0.38f, damping = 0.62f),
                            initialScale = 0.2f,
                            transformOrigin = TransformOrigin(0.5f, 1f),
                        ) + fadeIn(),
                        exit = fadeOut(tween(100)),
                        modifier = Modifier
                            .align(Alignment.CenterStart)
                            .offset(
                                x = usable * fraction(correct ?: lower) + SLIDER_THUMB / 2 - SLIDER_MARKER / 2,
                                y = (-30).dp,
                            ),
                    ) {
                        DSCheckBadge(size = SLIDER_MARKER, fill = DS.success)
                    }
                    val theirs = ui.opponentAnswer.value
                    androidx.compose.animation.AnimatedVisibility(
                        visible = ui.revealed && theirs != null,
                        enter = scaleIn(
                            duelSpring(response = 0.38f, damping = 0.62f),
                            initialScale = 0.2f,
                            transformOrigin = TransformOrigin(0.5f, 0f),
                        ) + fadeIn(),
                        exit = fadeOut(tween(100)),
                        modifier = Modifier
                            .align(Alignment.CenterStart)
                            .offset(
                                x = usable * fraction(theirs ?: lower) + SLIDER_THUMB / 2 - SLIDER_MARKER / 2,
                                y = 30.dp,
                            ),
                    ) {
                        DuelOpponentMarker(opponent)
                    }

                    Box(
                        modifier = Modifier
                            .align(Alignment.CenterStart)
                            .offset(x = position)
                            .size(SLIDER_THUMB)
                            .background(if (ui.playerLocked) DS.accent else DS.surface, CircleShape)
                            .border(3.dp, DS.accent, CircleShape),
                    )
                }
            }

            SliderStepButton(Icons.Filled.Add, description = "+", enabled = canMove) { onNudge(1.0) }
        }

        // Les bornes, sous les extrémités de la piste (entre les deux boutons).
        CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
            Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 56.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                listOf(lower, upper).forEach { bound ->
                    Text(
                        text = DuelFormat.sliderValue(bound, question.unit),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 12.sp,
                        color = DS.inkTertiary,
                        maxLines = 1,
                    )
                }
            }
        }

        if (ui.revealed) {
            val appear = remember { androidx.compose.animation.core.MutableTransitionState(false) }.apply { targetState = true }
            androidx.compose.animation.AnimatedVisibility(
                visibleState = appear,
                enter = slideInVertically(duelSpring(response = 0.38f, damping = 0.62f)) { it / 2 } + fadeIn(),
            ) {
                Column(
                    modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    question.correctValue?.let { correct ->
                        Text(
                            text = StringStore.text(
                                context, "duel.game.sliderAnswer", language,
                                DuelFormat.sliderValue(correct, question.unit),
                            ),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Bold,
                            fontSize = 17.sp,
                            color = DS.success,
                            textAlign = TextAlign.Center,
                        )
                    }
                    ui.opponentAnswer.value?.let { theirs ->
                        Text(
                            text = StringStore.text(
                                context, "duel.game.sliderTheirs", language,
                                opponent.handle, DuelFormat.sliderValue(theirs, question.unit),
                            ),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.Medium,
                            fontSize = 15.sp,
                            color = DS.inkSecondary,
                            textAlign = TextAlign.Center,
                        )
                    }
                }
            }
        } else {
            // Validé, le bouton reste en place, éteint : la valeur ne bouge plus. La validation
            // vibre d'elle-même (`DuelHaptic.Lock`).
            DuelPlayButton(
                text = StringStore.text(context, if (ui.playerLocked) "duel.game.locked" else "duel.game.lock", language),
                onClick = { if (canMove) onLock() },
                fill = if (ui.playerLocked) DS.accentTint else DS.accent,
                foreground = if (ui.playerLocked) DS.inkSecondary else Color.White,
            )
        }
    }
}

@Composable
private fun SliderStepButton(icon: ImageVector, description: String, enabled: Boolean, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .alpha(if (enabled) 1f else 0.4f)
            .size(44.dp)
            // Chaque cran du curseur vibre déjà (`DuelHaptic.Tick`).
            .pressable(onClick = onClick, enabled = enabled, scaleDown = 0.94f, haptic = false)
            .background(DS.surface, CircleShape)
            .border(1.5.dp, DS.hairline, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, contentDescription = description, tint = DS.ink, modifier = Modifier.size(18.dp))
    }
}

// ---------------------------------------------------------------- chrono

/**
 * Le minuteur : un anneau bleu qui se vide, et les secondes restantes au centre. Dans les trois
 * dernières secondes il vire au rouge et bat une fois par seconde (l'avertissement haptique,
 * unique, vient de `DuelHaptic.Clock`). Il se fige à la révélation.
 */
@Composable
internal fun DuelTimerRing(model: DuelGameModel, modifier: Modifier = Modifier, size: Dp = 58.dp) {
    var fraction by remember { mutableFloatStateOf(model.remainingFraction().toFloat()) }
    val answering = model.phase == DuelPhase.Answering
    LaunchedEffect(model, answering, model.index) {
        fraction = model.remainingFraction().toFloat()
        // Hors d'une question, le cadran est figé : rien à redessiner.
        while (answering) {
            withFrameNanos { }
            fraction = model.remainingFraction().toFloat()
        }
    }
    val limitSeconds = model.question.timeLimitMs / 1000.0
    val seconds by remember(limitSeconds) { derivedStateOf { ceil(fraction * limitSeconds).toInt() } }
    val urgent = answering && seconds <= DuelRules.CLOCK_SECONDS
    val reduceMotion = rememberDuelReduceMotion()
    val beats = urgent && !reduceMotion
    val tint by animateColorAsState(
        targetValue = if (urgent) DuelTheme.stripWrong else DS.accent,
        animationSpec = tween(180),
        label = "duelTimerTint",
    )
    val surface = DS.surface
    Box(
        modifier = modifier
            .size(size)
            .graphicsLayer {
                // Un battement par seconde dans les dernières secondes : nul à chaque seconde
                // pleine, au plus fort à mi-chemin.
                val beat = if (beats) {
                    val wave = sin(fraction * limitSeconds * PI).toFloat()
                    1f + 0.09f * wave * wave
                } else {
                    1f
                }
                scaleX = beat
                scaleY = beat
            }
            // Le chrono change à chaque image : le bandeau dit l'essentiel à la lecture d'écran.
            .clearAndSetSemantics {},
        contentAlignment = Alignment.Center,
    ) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            val stroke = 5.dp.toPx()
            val inset = stroke / 2
            val arcSize = Size(this.size.width - stroke, this.size.height - stroke)
            drawCircle(color = surface)
            drawArc(
                color = DuelTheme.timerTrack,
                startAngle = 0f,
                sweepAngle = 360f,
                useCenter = false,
                topLeft = Offset(inset, inset),
                size = arcSize,
                style = Stroke(width = stroke),
            )
            drawArc(
                color = tint,
                startAngle = -90f,
                sweepAngle = 360f * fraction.coerceIn(0f, 1f),
                useCenter = false,
                topLeft = Offset(inset, inset),
                size = arcSize,
                style = Stroke(width = stroke, cap = StrokeCap.Round),
            )
        }
        Text(
            text = seconds.toString(),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = (size.value * 0.38f).sp,
            style = DuelTabularDigits,
            color = if (urgent) DuelTheme.stripWrong else DS.ink,
            maxLines = 1,
        )
    }
}

// ---------------------------------------------------------------- bandes de résultats

/**
 * Une case d'une bande : verte quand le camp a marqué, rouge sinon, bleue pour la question en
 * cours, grise tant qu'elle est à venir. Elle « saute » au moment où elle prend sa couleur.
 */
@Composable
private fun RowScope.DuelStripCell(mark: Boolean?, isCurrent: Boolean) {
    val color by animateColorAsState(
        targetValue = when (mark) {
            true -> DuelTheme.stripRight
            false -> DuelTheme.stripWrong
            null -> if (isCurrent) DS.accent else DuelTheme.stripIdle
        },
        animationSpec = DSMotion.snappy(),
        label = "duelStripColor",
    )
    val pop = remember { Animatable(0f) }
    // La marque vue à la composition précédente : seul le passage de « à venir » à « jouée » saute.
    val seen = remember { arrayOf(mark) }
    LaunchedEffect(mark) {
        val before = seen[0]
        seen[0] = mark
        if (before == null && mark != null) {
            pop.snapTo(0f)
            pop.animateTo(1f, tween(120, easing = LinearOutSlowInEasing))
            pop.animateTo(0f, DSMotion.pop())
        }
    }
    Box(
        modifier = Modifier
            .weight(1f)
            .height(5.dp)
            .graphicsLayer {
                scaleX = 1f + 0.15f * pop.value
                scaleY = 1f + 1.6f * pop.value
            }
            .clip(RoundedCornerShape(3.dp))
            .background(color),
    )
}

/** Les questions d'un camp en une ligne de cases, regroupées par manche (cinq questions). */
@Composable
internal fun DuelScoreStrip(marks: List<Boolean?>, current: Int, modifier: Modifier = Modifier) {
    val groups = marks.indices.chunked(DuelMatch.QUESTIONS_PER_ROUND)
    Row(
        modifier = modifier.fillMaxWidth().clearAndSetSemantics {},
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        groups.forEach { group ->
            Row(modifier = Modifier.weight(1f), horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                group.forEach { index ->
                    DuelStripCell(mark = marks[index], isCurrent = index == current)
                }
            }
        }
    }
}

private val SCORE_BOARD_LABEL = 52.dp

/**
 * Les deux bandes de résultats (le joueur, puis l'adversaire) sous les étiquettes des manches
 * M1…Mn ; la manche en cours est en bleu.
 *
 * [current] : l'indice de la question en cours ; [currentRound] : le numéro de la manche en
 * cours (à partir de 1), 0 quand aucune ne l'est (question décisive).
 */
@Composable
internal fun DuelScoreBoard(
    playerMarks: List<Boolean?>,
    opponentMarks: List<Boolean?>,
    current: Int,
    currentRound: Int,
    opponentName: String,
    language: AppLanguage,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val perRound = maxOf(DuelMatch.QUESTIONS_PER_ROUND, 1)
    val roundCount = maxOf((playerMarks.size + perRound - 1) / perRound, 1)
    Column(
        modifier = modifier.fillMaxWidth().clearAndSetSemantics {},
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
            Spacer(Modifier.width(SCORE_BOARD_LABEL))
            Row(modifier = Modifier.weight(1f), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                for (number in 1..roundCount) {
                    val tint by animateColorAsState(
                        targetValue = if (number == currentRound) DS.accent else DuelTheme.faint,
                        animationSpec = DSMotion.snappy(),
                        label = "duelRoundLabel",
                    )
                    Text(
                        text = StringStore.text(context, "duel.round.short", language, number),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 10.sp,
                        letterSpacing = 0.6.sp,
                        color = tint,
                        maxLines = 1,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.weight(1f),
                    )
                }
            }
        }
        ScoreBoardRow(label = StringStore.text(context, "duel.you", language), strong = true, marks = playerMarks, current = current)
        ScoreBoardRow(label = opponentName, strong = false, marks = opponentMarks, current = current)
    }
}

@Composable
private fun ScoreBoardRow(label: String, strong: Boolean, marks: List<Boolean?>, current: Int) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
        DuelShrinkText(
            text = label,
            fontSize = 11.sp,
            fontWeight = if (strong) FontWeight.Bold else FontWeight.SemiBold,
            color = if (strong) DS.ink else DS.inkSecondary,
            minScale = 0.7f,
            modifier = Modifier.width(SCORE_BOARD_LABEL),
        )
        DuelScoreStrip(marks = marks, current = current, modifier = Modifier.weight(1f))
    }
}
