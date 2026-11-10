package app.rork.sophia.ui.duels

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
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
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.newgen.AvatarCircle
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import coil.compose.AsyncImage
import kotlin.math.ceil

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

    /** Le mauvais choix du joueur, dévoilé. */
    Wrong,

    /** Une option ni choisie ni juste : en retrait. */
    Dimmed,
}

internal fun duelOptionState(option: Int, ui: DuelQuestionUi): DuelOptionState = when {
    ui.revealed -> when (option) {
        ui.question.correctIndex -> DuelOptionState.Correct
        ui.selectedChoice -> DuelOptionState.Wrong
        else -> DuelOptionState.Dimmed
    }
    ui.playerLocked -> if (option == ui.selectedChoice) DuelOptionState.Selected else DuelOptionState.Dimmed
    else -> DuelOptionState.Idle
}

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
) {
    val fill by animateColorAsState(
        targetValue = when (state) {
            DuelOptionState.Idle, DuelOptionState.Dimmed -> DS.surface
            DuelOptionState.Selected -> DS.accentTint
            DuelOptionState.Correct -> DS.successTint
            DuelOptionState.Wrong -> DS.dangerTint
        },
        animationSpec = tween(220),
        label = "duelOptionFill",
    )
    val border by animateColorAsState(
        targetValue = when (state) {
            DuelOptionState.Idle, DuelOptionState.Dimmed -> DS.hairline
            DuelOptionState.Selected -> DS.accent
            DuelOptionState.Correct -> DS.success
            DuelOptionState.Wrong -> DS.danger
        },
        animationSpec = tween(220),
        label = "duelOptionBorder",
    )
    val foreground = when (state) {
        DuelOptionState.Idle, DuelOptionState.Selected -> DS.ink
        DuelOptionState.Correct -> DS.success
        DuelOptionState.Wrong -> DS.danger
        DuelOptionState.Dimmed -> DS.inkTertiary
    }
    val scale by animateFloatAsState(
        targetValue = when (state) {
            DuelOptionState.Correct -> 1.02f
            DuelOptionState.Selected -> 0.985f
            else -> 1f
        },
        animationSpec = duelSpring(response = 0.38f, damping = 0.62f),
        label = "duelOptionScale",
    )
    val plain = state == DuelOptionState.Idle || state == DuelOptionState.Dimmed
    Box(
        modifier = modifier.graphicsLayer {
            scaleX = scale
            scaleY = scale
        },
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .alpha(if (state == DuelOptionState.Dimmed) 0.55f else 1f)
                .softPress(onClick = onClick, enabled = state == DuelOptionState.Idle)
                .heightIn(min = minHeight)
                .background(fill, DS.controlShape)
                .border(if (plain) 1.dp else 2.dp, border, DS.controlShape)
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            if (icon != null) {
                Icon(icon, contentDescription = null, tint = foreground, modifier = Modifier.size(20.dp))
            }
            DuelShrinkText(
                text = text,
                fontSize = 16.sp,
                fontWeight = FontWeight.SemiBold,
                color = foreground,
                maxLines = 2,
                modifier = Modifier.weight(1f),
            )
            when (state) {
                DuelOptionState.Correct ->
                    Icon(Icons.Filled.CheckCircle, contentDescription = null, tint = foreground, modifier = Modifier.size(22.dp))
                DuelOptionState.Wrong ->
                    Icon(Icons.Filled.Cancel, contentDescription = null, tint = foreground, modifier = Modifier.size(22.dp))
                else -> Unit
            }
        }
        // L'avatar de l'adversaire se pose sur le coin de l'option, hors du texte : dans la grille
        // 2 × 2 d'une question à image, il ne prend pas la place d'un nom déjà à l'étroit.
        AnimatedVisibility(
            visible = showsOpponent,
            enter = scaleIn(duelSpring(response = 0.38f, damping = 0.62f), initialScale = 0.2f) + fadeIn(),
            exit = fadeOut(tween(100)),
            modifier = Modifier.align(Alignment.TopEnd).offset(x = 7.dp, y = (-9).dp),
        ) {
            DuelOpponentMarker(opponent)
        }
    }
}

/** Le petit avatar de l'adversaire, cerclé de sa couleur : là où il a répondu. */
@Composable
internal fun DuelOpponentMarker(opponent: DuelOpponent, modifier: Modifier = Modifier) {
    Box(modifier = modifier.size(26.dp)) {
        AvatarCircle(avatarId = opponent.avatarId, initial = opponent.initial, size = 26.dp)
        Box(modifier = Modifier.matchParentSize().border(2.dp, DuelPalette.coral, CircleShape))
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
    onChoose: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val options = ui.question.options.orEmpty()
    when (ui.question.kind) {
        DuelQuestionKind.TRUE_FALSE -> Row(
            modifier = modifier.fillMaxWidth().height(IntrinsicSize.Min),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            options.indices.forEach { index ->
                ChoiceOption(
                    ui, index, opponent, onChoose,
                    modifier = Modifier.weight(1f).fillMaxHeight(),
                    icon = if (index == 0) Icons.Filled.Check else Icons.Filled.Close,
                    minHeight = 84.dp,
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
                            ui, index, opponent, onChoose,
                            modifier = Modifier.weight(1f).fillMaxHeight(),
                            icon = null,
                            minHeight = 60.dp,
                        )
                    }
                    // Un nombre impair d'options : la dernière garde la largeur d'une colonne.
                    if (pair.size == 1) Spacer(Modifier.weight(1f))
                }
            }
        }
        else -> Column(modifier = modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            options.indices.forEach { index ->
                ChoiceOption(ui, index, opponent, onChoose, modifier = Modifier.fillMaxWidth(), icon = null, minHeight = 56.dp)
            }
        }
    }
}

@Composable
private fun ChoiceOption(
    ui: DuelQuestionUi,
    index: Int,
    opponent: DuelOpponent,
    onChoose: (Int) -> Unit,
    modifier: Modifier,
    icon: ImageVector?,
    minHeight: Dp,
) {
    DuelOptionButton(
        text = ui.question.options.orEmpty().getOrNull(index).orEmpty(),
        state = duelOptionState(index, ui),
        opponent = opponent,
        showsOpponent = ui.revealed && ui.opponentAnswer.choice == index,
        onClick = { onChoose(index) },
        modifier = modifier,
        icon = icon,
        minHeight = minHeight,
    )
}

/**
 * L'image d'une question (portrait, drapeau, tableau, monument) dans un cadre 4:5 qu'elle
 * remplit. Elle est déjà en cache, chargée pendant la présentation de l'adversaire ; tant
 * qu'elle n'est pas là, le cadre reste vide.
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
        modifier = modifier
            .size(width = 184.dp * scale, height = 230.dp * scale)
            .sophiaCard(shape = RoundedCornerShape(20.dp), fill = DS.surfaceMuted),
    ) {
        if (!url.isNullOrBlank()) {
            val request = remember(url) { duelQuestionImageRequest(context, url) }
            AsyncImage(
                model = request,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize(),
            )
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
            color = DS.ink,
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
                            .background(DS.surfaceMuted, CircleShape),
                    )
                    Box(
                        modifier = Modifier
                            .align(Alignment.CenterStart)
                            .width(SLIDER_THUMB / 2 + position)
                            .height(12.dp)
                            .background(DS.accentSoft.copy(alpha = 0.55f), CircleShape),
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
                        Box(
                            modifier = Modifier.size(SLIDER_MARKER).background(DS.success, CircleShape),
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(Icons.Filled.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(15.dp))
                        }
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
                            .shadow(6.dp, CircleShape)
                            .size(SLIDER_THUMB)
                            .background(if (ui.playerLocked) DS.accent else Color.White, CircleShape)
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
            // Validé, le bouton reste en place, éteint : la valeur ne bouge plus.
            DuelPlayButton(
                text = StringStore.text(context, if (ui.playerLocked) "duel.game.locked" else "duel.game.lock", language),
                onClick = { if (canMove) onLock() },
                fill = if (ui.playerLocked) DS.surfaceMuted else DuelPalette.saffron,
                edge = if (ui.playerLocked) DS.hairline else DuelPalette.playEdge,
                foreground = if (ui.playerLocked) DS.inkSecondary else DuelPalette.night,
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
            .softPress(onClick = onClick, enabled = enabled)
            .background(DS.surface, CircleShape)
            .border(1.dp, DS.hairline, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, contentDescription = description, tint = DS.ink, modifier = Modifier.size(18.dp))
    }
}

// ---------------------------------------------------------------- chrono

/**
 * Le cadran du chrono : un anneau qui se vide, et les secondes restantes au centre. Il vire au
 * rouge dans les trois dernières secondes, et se fige à la révélation.
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
    val scale by animateFloatAsState(
        targetValue = if (urgent) 1.08f else 1f,
        animationSpec = duelSpring(response = 0.25f, damping = 0.55f),
        label = "duelTimerScale",
    )
    val tint = if (urgent) DuelPalette.coral else DuelPalette.saffron
    Box(
        modifier = modifier
            .size(size)
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            }
            // Le chrono change à chaque image : la ligne d'état dit l'essentiel à la lecture d'écran.
            .clearAndSetSemantics {},
        contentAlignment = Alignment.Center,
    ) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            val stroke = 5.dp.toPx()
            val inset = stroke / 2
            val arcSize = Size(this.size.width - stroke, this.size.height - stroke)
            drawArc(
                color = Color.White.copy(alpha = 0.18f),
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
            color = if (urgent) DuelPalette.coral else Color.White,
            maxLines = 1,
        )
    }
}

// ---------------------------------------------------------------- fil du score

/**
 * Les 20 questions en une ligne de segments par camp, groupés par manche : vert quand il a
 * marqué, rouge sinon, vide tant que la question n'est pas jouée.
 */
@Composable
internal fun DuelScoreStrip(marks: List<Boolean?>, current: Int, modifier: Modifier = Modifier) {
    val groups = marks.indices.chunked(DuelMatch.QUESTIONS_PER_ROUND)
    Row(
        modifier = modifier.fillMaxWidth().clearAndSetSemantics {},
        horizontalArrangement = Arrangement.spacedBy(9.dp),
    ) {
        groups.forEach { group ->
            Row(modifier = Modifier.weight(1f), horizontalArrangement = Arrangement.spacedBy(3.dp)) {
                group.forEach { index ->
                    val color = when (marks[index]) {
                        true -> DuelPalette.scored
                        false -> DuelPalette.coral
                        null -> Color.White.copy(alpha = if (index == current) 0.75f else 0.2f)
                    }
                    Box(modifier = Modifier.weight(1f).height(5.dp).clip(CircleShape).background(color))
                }
            }
        }
    }
}
