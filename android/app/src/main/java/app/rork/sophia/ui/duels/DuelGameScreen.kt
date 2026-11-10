package app.rork.sophia.ui.duels

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.DuelQuestionKind
import app.rork.sophia.domain.uppercaseIn
import app.rork.sophia.ui.components.ConfirmDialog
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans

/**
 * L'écran de jeu : les deux joueurs et leur score en haut, le chrono entre eux, le fil des 20
 * questions, puis la question et ses réponses. On voit l'adversaire répondre (pastille sur son
 * avatar), puis ce qu'il a choisi et s'il a marqué à la révélation. La partie elle-même tourne
 * dans [DuelFlow] ; cet écran la montre et transmet les gestes du joueur.
 * Même écran que `ios/Sophia/Views/Duels/DuelGameView.swift`.
 */
@Composable
internal fun DuelGameScreen(
    model: DuelGameModel,
    player: DuelPlayerIdentity,
    language: AppLanguage,
    onAbandon: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val view = LocalView.current
    fun text(key: String, vararg args: Any): String = StringStore.text(context, key, language, *args)
    var confirmQuit by remember { mutableStateOf(false) }
    val askToQuit = {
        view.duelHaptic(DuelHaptic.Tap)
        confirmQuit = true
    }

    // Le retour système ne ferme pas la partie d'un geste : il pose la même question que la croix.
    BackHandler { askToQuit() }

    Box(modifier = modifier.fillMaxSize().background(DS.canvas)) {
        Column(modifier = Modifier.fillMaxSize()) {
            GameHeader(model = model, player = player, language = language, onQuit = askToQuit)

            AnimatedContent(
                targetState = model.index,
                modifier = Modifier.weight(1f).fillMaxWidth(),
                transitionSpec = {
                    (slideInHorizontally(duelSpring(response = 0.5f, damping = 0.86f)) { it } + fadeIn())
                        .togetherWith(slideOutHorizontally(duelSpring(response = 0.5f, damping = 0.86f)) { -it } + fadeOut())
                },
                contentAlignment = Alignment.TopCenter,
                label = "duelQuestion",
            ) { shownIndex ->
                // La question qui sort garde sa dernière image, celle de la révélation.
                val live = shownIndex == model.index
                val held = remember { arrayOfNulls<DuelQuestionUi>(1) }
                if (live) held[0] = model.questionUi()
                val ui = held[0] ?: model.questionUi()
                QuestionArea(ui = ui, model = model, live = live, language = language)
            }

            StatusLine(model = model, language = language, modifier = Modifier.padding(horizontal = 20.dp).padding(bottom = 10.dp))
        }

        // L'annonce d'une manche garde son contenu le temps de s'effacer.
        val lastIntro = remember { arrayOfNulls<DuelRoundAnnouncement>(1) }
        model.roundIntro?.let { lastIntro[0] = it }
        AnimatedVisibility(
            visible = model.phase == DuelPhase.RoundIntro && model.roundIntro != null,
            enter = fadeIn(tween(250)),
            exit = fadeOut(tween(250)),
        ) {
            val intro = model.roundIntro ?: lastIntro[0]
            if (intro != null) {
                DuelRoundIntroOverlay(
                    model = model,
                    intro = intro,
                    opponentHandle = model.match.opponent.handle,
                    language = language,
                    onQuit = askToQuit,
                )
            }
        }

        AnimatedVisibility(
            visible = model.phase == DuelPhase.SuddenDeathIntro,
            enter = scaleIn(duelSpring(response = 0.5f, damping = 0.7f), initialScale = 0.6f) + fadeIn(),
            exit = scaleOut(tween(250), targetScale = 0.6f) + fadeOut(tween(250)),
        ) {
            SuddenDeathBanner(model = model, language = language)
        }
    }

    if (confirmQuit) {
        ConfirmDialog(
            title = text("duel.quit.title"),
            message = text("duel.quit.body"),
            confirm = text("duel.quit.confirm"),
            cancel = text("duel.quit.stay"),
            onConfirm = {
                confirmQuit = false
                onAbandon()
            },
            onDismiss = { confirmQuit = false },
        )
    }
}

// ---------------------------------------------------------------- en-tête

@Composable
private fun GameHeader(model: DuelGameModel, player: DuelPlayerIdentity, language: AppLanguage, onQuit: () -> Unit) {
    val context = LocalContext.current
    val opponent = model.match.opponent
    val revealed = model.phase == DuelPhase.Reveal
    val answering = model.phase == DuelPhase.Answering
    val counter = if (model.isSuddenDeath) {
        StringStore.text(context, "duel.suddenDeath.title", language).uppercaseIn(language)
    } else {
        // « Manche 2 · 7 / 20 »
        val round = StringStore.text(context, "duel.round.title", language, model.roundNumber)
        "$round · ${minOf(model.index + 1, model.questionCount)} / ${model.questionCount}"
    }

    // Moi à gauche, l'adversaire à droite, dans toutes les langues : c'est un tableau de score.
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(DuelPalette.night, RoundedCornerShape(bottomStart = 26.dp, bottomEnd = 26.dp))
                .padding(horizontal = 16.dp)
                .padding(top = 6.dp, bottom = 14.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Row(modifier = Modifier.widthIn(max = 640.dp).fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                DuelQuitButton(language = language, onClick = onQuit)
                Text(
                    text = counter,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 13.sp,
                    letterSpacing = 0.6.sp,
                    color = Color.White.copy(alpha = 0.85f),
                    textAlign = TextAlign.Center,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f).padding(horizontal = 8.dp),
                )
                Spacer(Modifier.size(32.dp))
            }

            Row(
                modifier = Modifier.widthIn(max = 640.dp).fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                PlayerSide(
                    avatarId = player.avatarId,
                    initial = player.initial,
                    name = StringStore.text(context, "duel.you", language),
                    score = model.playerScore,
                    ring = DuelPalette.saffron,
                    answered = model.playerLocked && answering,
                    scored = if (revealed) model.lastRound?.player else null,
                    mirrored = false,
                    modifier = Modifier.weight(1f),
                )
                DuelTimerRing(model = model)
                PlayerSide(
                    avatarId = opponent.avatarId,
                    initial = opponent.initial,
                    name = "@${opponent.handle}",
                    score = model.opponentScore,
                    ring = DuelPalette.coral,
                    answered = model.opponentAnswered && answering,
                    scored = if (revealed) model.lastRound?.opponent else null,
                    mirrored = true,
                    modifier = Modifier.weight(1f),
                )
            }

            Column(modifier = Modifier.widthIn(max = 640.dp).fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                DuelScoreStrip(marks = model.playerMarks, current = model.index)
                DuelScoreStrip(marks = model.opponentMarks, current = model.index)
            }
        }
    }
}

/** Un camp : avatar, nom, score. `scored` vaut vrai ou faux pendant la révélation. */
@Composable
private fun PlayerSide(
    avatarId: String?,
    initial: String,
    name: String,
    score: Int,
    ring: Color,
    answered: Boolean,
    scored: Boolean?,
    mirrored: Boolean,
    modifier: Modifier = Modifier,
) {
    val avatarScale by animateFloatAsState(
        targetValue = if (answered) 1.06f else 1f,
        animationSpec = duelSpring(response = 0.3f, damping = 0.6f),
        label = "duelSideAvatar",
    )
    val scoreScale by animateFloatAsState(
        targetValue = if (scored == true) 1.18f else 1f,
        animationSpec = duelSpring(response = 0.38f, damping = 0.62f),
        label = "duelSideScore",
    )

    val avatar: @Composable () -> Unit = {
        Box(
            modifier = Modifier.graphicsLayer {
                scaleX = avatarScale
                scaleY = avatarScale
            },
        ) {
            DuelAvatar(
                avatarId = avatarId,
                initial = initial,
                size = 50.dp,
                ring = when (scored) {
                    null -> ring
                    true -> DuelPalette.scored
                    false -> DuelPalette.coral
                },
                ringWidth = if (scored == null) 3.dp else 4.dp,
            )
            // La pastille « a répondu », au coin de l'avatar côté centre.
            androidx.compose.animation.AnimatedVisibility(
                visible = answered,
                enter = scaleIn(duelSpring(response = 0.3f, damping = 0.6f), initialScale = 0.1f) + fadeIn(),
                exit = scaleOut(tween(120), targetScale = 0.1f) + fadeOut(tween(120)),
                modifier = Modifier
                    .align(if (mirrored) Alignment.BottomStart else Alignment.BottomEnd)
                    .offset(x = if (mirrored) (-4).dp else 4.dp, y = 4.dp),
            ) {
                Box(
                    modifier = Modifier
                        .size(20.dp)
                        .background(DuelPalette.saffron, CircleShape)
                        .border(2.dp, DuelPalette.night, CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(Icons.Filled.Check, contentDescription = null, tint = DuelPalette.night, modifier = Modifier.size(12.dp))
                }
            }
        }
    }
    val labels: @Composable (Modifier) -> Unit = { labelsModifier ->
        Column(modifier = labelsModifier, horizontalAlignment = if (mirrored) Alignment.End else Alignment.Start) {
            DuelShrinkText(
                text = name,
                fontSize = 12.sp,
                fontWeight = FontWeight.SemiBold,
                color = Color.White.copy(alpha = 0.7f),
                minScale = 0.7f,
            )
            Text(
                text = score.toString(),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 30.sp,
                lineHeight = 34.sp,
                style = DuelTabularDigits,
                color = Color.White,
                maxLines = 1,
                modifier = Modifier.graphicsLayer {
                    scaleX = scoreScale
                    scaleY = scoreScale
                    transformOrigin = TransformOrigin(if (mirrored) 1f else 0f, 0.5f)
                },
            )
        }
    }

    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp, if (mirrored) Alignment.End else Alignment.Start),
    ) {
        if (mirrored) {
            labels(Modifier.weight(1f, fill = false))
            avatar()
        } else {
            avatar()
            labels(Modifier.weight(1f, fill = false))
        }
    }
}

// ---------------------------------------------------------------- question

@Composable
private fun QuestionArea(ui: DuelQuestionUi, model: DuelGameModel, live: Boolean, language: AppLanguage) {
    val context = LocalContext.current
    val question = ui.question
    val portrait = question.kind == DuelQuestionKind.PORTRAIT
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp)
            .padding(top = 18.dp, bottom = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Column(
            modifier = Modifier.widthIn(max = 640.dp).fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            ui.subject?.let { subject ->
                // La matière de la manche au choix en cours.
                Row(
                    modifier = Modifier
                        .background(DS.accentTint, CircleShape)
                        .padding(horizontal = 12.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    Icon(DuelSubjects.of(subject).icon, contentDescription = null, tint = DS.accentSoft, modifier = Modifier.size(14.dp))
                    Text(
                        text = duelSubjectName(context, subject, language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Bold,
                        fontSize = 12.sp,
                        color = DS.accentSoft,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }

            if (portrait) DuelQuestionImage(url = question.imageUrl)

            Text(
                text = question.question,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = if (portrait) 20.sp else 22.sp,
                lineHeight = if (portrait) 26.sp else 28.sp,
                color = DS.ink,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(vertical = if (portrait) 0.dp else 10.dp),
            )

            if (question.kind == DuelQuestionKind.SLIDER) {
                DuelSliderAnswer(
                    ui = ui,
                    opponent = model.match.opponent,
                    language = language,
                    interactive = live,
                    onSet = { if (live) model.setSlider(it) },
                    onNudge = { if (live) model.nudgeSlider(it) },
                    onLock = { if (live) model.lockSlider() },
                )
            } else {
                DuelChoiceAnswers(
                    ui = ui,
                    opponent = model.match.opponent,
                    onChoose = { if (live) model.choose(it) },
                )
            }
        }
    }
}

// ---------------------------------------------------------------- ligne d'état

@Composable
private fun StatusLine(model: DuelGameModel, language: AppLanguage, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    fun text(key: String, vararg args: Any): String = StringStore.text(context, key, language, *args)
    val handle = model.match.opponent.handle
    val round = model.lastRound

    val status = when {
        // L'adversaire vient de quitter la partie : la victoire suit.
        model.opponentForfeited -> text("duel.friend.left", handle)
        model.phase == DuelPhase.Answering -> when {
            model.playerLocked && !model.opponentAnswered -> text("duel.game.waiting", handle)
            model.opponentAnswered && !model.playerLocked -> text("duel.game.theyAnswered", handle)
            else -> ""
        }
        model.phase == DuelPhase.Reveal && round != null -> when {
            model.question.kind == DuelQuestionKind.SLIDER -> when {
                round.player && round.opponent -> text("duel.game.sliderTie")
                round.player -> text("duel.game.sliderYou")
                else -> text("duel.game.sliderThem", handle)
            }
            round.player -> text("duel.game.correct")
            model.selectedChoice == null -> text("duel.game.timeUp")
            else -> text("duel.game.wrong")
        }
        else -> ""
    }
    val color = when {
        model.phase == DuelPhase.Reveal && round != null -> if (round.player) DS.success else DS.danger
        else -> DS.inkSecondary
    }

    Crossfade(
        targetState = status to color,
        animationSpec = tween(200),
        modifier = modifier.fillMaxWidth().height(22.dp),
        label = "duelStatus",
    ) { (shown, tint) ->
        DuelShrinkText(
            text = shown,
            fontSize = 15.sp,
            fontWeight = FontWeight.Bold,
            color = tint,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

// ---------------------------------------------------------------- question décisive

@Composable
private fun SuddenDeathBanner(model: DuelGameModel, language: AppLanguage) {
    val context = LocalContext.current
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DuelPalette.night.copy(alpha = 0.92f))
            .pointerInput(Unit) {},
        contentAlignment = Alignment.Center,
    ) {
        Column(
            modifier = Modifier.widthIn(max = 520.dp).padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Icon(Icons.Filled.Bolt, contentDescription = null, tint = DuelPalette.saffron, modifier = Modifier.size(52.dp))
            Text(
                text = StringStore.text(context, "duel.suddenDeath.title", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 34.sp,
                lineHeight = 40.sp,
                color = Color.White,
                textAlign = TextAlign.Center,
            )
            Text(
                text = StringStore.text(context, "duel.suddenDeath.body", language, model.playerScore, model.opponentScore),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Medium,
                fontSize = 17.sp,
                lineHeight = 23.sp,
                color = Color.White.copy(alpha = 0.8f),
                textAlign = TextAlign.Center,
            )
        }
    }
}
