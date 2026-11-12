package app.rork.sophia.ui.duels

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.SizeTransform
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.slideOutVertically
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
import androidx.compose.foundation.layout.heightIn
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
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
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
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.DuelQuestionKind
import app.rork.sophia.domain.DuelRoundKind
import app.rork.sophia.domain.uppercaseIn
import app.rork.sophia.ui.components.ConfirmDialog
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.dsPopIn
import app.rork.sophia.ui.components.dsShake
import app.rork.sophia.ui.newgen.AvatarCircle
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * L'écran de jeu (maquette AEr24) : la manche et la question en sur-titre, le bloc de score
 * (les deux joueurs, le minuteur entre eux, les bandes de résultats par manche), puis la
 * question, ses réponses en cartes et le bandeau de verdict. On voit l'adversaire répondre
 * (pastille sur son avatar), puis ce qu'il a choisi et s'il a marqué à la révélation. La partie
 * elle-même tourne dans [DuelFlow] ; cet écran la montre et transmet les gestes du joueur.
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
        Column(modifier = Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
            GameTopBar(
                model = model,
                language = language,
                onQuit = askToQuit,
                modifier = Modifier.widthIn(max = 640.dp).padding(horizontal = 24.dp).padding(top = 8.dp),
            )
            ScoreBlock(
                model = model,
                player = player,
                language = language,
                modifier = Modifier.widthIn(max = 640.dp).padding(horizontal = 24.dp).padding(top = 14.dp),
            )

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
                val heldSprint = remember { BooleanArray(1) }
                if (live) {
                    held[0] = model.questionUi()
                    heldSprint[0] = model.isSprintRound()
                }
                val ui = held[0] ?: model.questionUi()
                QuestionArea(ui = ui, sprint = heldSprint[0], model = model, live = live, language = language)
            }

            VerdictBanner(
                model = model,
                language = language,
                modifier = Modifier
                    .widthIn(max = 640.dp)
                    .padding(horizontal = 24.dp)
                    .padding(top = 6.dp, bottom = 10.dp),
            )
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

/** La manche en cours est le sprint final. */
private fun DuelGameModel.isSprintRound(): Boolean {
    if (index >= questionCount) return false
    return match.rounds.getOrNull(roundNumber - 1)?.kind == DuelRoundKind.SPRINT
}

// ---------------------------------------------------------------- en-tête

/** Le bouton pour quitter, et au centre « MANCHE 2 SUR 4 » au-dessus de « Question 7 / 20 ». */
@Composable
private fun GameTopBar(model: DuelGameModel, language: AppLanguage, onQuit: () -> Unit, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val eyebrow = if (model.isSuddenDeath) {
        StringStore.text(context, "duel.suddenDeath.title", language)
    } else {
        StringStore.text(context, "duel.round.of", language, model.roundNumber, model.match.rounds.size)
    }
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        DuelQuitButton(language = language, onClick = onQuit)
        Column(
            modifier = Modifier.weight(1f),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(1.dp),
        ) {
            DuelShrinkText(
                text = eyebrow.uppercaseIn(language),
                fontSize = 11.sp,
                fontWeight = FontWeight.ExtraBold,
                color = DS.accent,
                textAlign = TextAlign.Center,
                minScale = 0.7f,
                letterSpacing = 1.sp,
            )
            if (!model.isSuddenDeath) {
                // « Question 7 / 20 » : le numéro en gras, le total en gris à partir de la barre oblique.
                val number = minOf(model.index + 1, model.questionCount)
                val full = StringStore.text(context, "duel.game.counter", language, number, model.questionCount)
                val slash = full.indexOf('/')
                Text(
                    text = buildAnnotatedString {
                        if (slash < 0) {
                            append(full)
                        } else {
                            append(full.substring(0, slash))
                            withStyle(SpanStyle(color = DS.inkTertiary, fontWeight = FontWeight.Medium)) {
                                append(full.substring(slash))
                            }
                        }
                    },
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp,
                    style = DuelTabularDigits,
                    color = DS.ink,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        // Le pendant de la croix, pour que le titre reste au centre.
        Spacer(Modifier.size(44.dp))
    }
}

// ---------------------------------------------------------------- bloc de score

@Composable
private fun ScoreBlock(model: DuelGameModel, player: DuelPlayerIdentity, language: AppLanguage, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val opponent = model.match.opponent
    val revealed = model.phase == DuelPhase.Reveal
    val answering = model.phase == DuelPhase.Answering

    // Moi à gauche, l'adversaire à droite, dans toutes les langues : c'est un tableau de score.
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Ltr) {
        Column(
            modifier = modifier
                .fillMaxWidth()
                .background(DuelTheme.scoreBlock, RoundedCornerShape(20.dp))
                .padding(start = 14.dp, end = 14.dp, top = 14.dp, bottom = 12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                ScoreSide(
                    avatarId = player.avatarId,
                    initial = player.initial,
                    name = StringStore.text(context, "duel.you", language),
                    score = model.playerScore,
                    tint = DS.accent,
                    scoreColor = DS.accent,
                    isPlayer = true,
                    answered = model.playerLocked && answering,
                    scored = if (revealed) model.lastRound?.player else null,
                    mirrored = false,
                    modifier = Modifier.weight(1f),
                )
                DuelTimerRing(model = model)
                ScoreSide(
                    avatarId = opponent.avatarId,
                    initial = opponent.initial,
                    name = "@${opponent.handle}",
                    score = model.opponentScore,
                    tint = DuelPalette.saffron,
                    scoreColor = DS.inkTertiary,
                    isPlayer = false,
                    answered = model.opponentAnswered && answering,
                    scored = if (revealed) model.lastRound?.opponent else null,
                    mirrored = true,
                    modifier = Modifier.weight(1f),
                )
            }

            Box(modifier = Modifier.fillMaxWidth().height(1.dp).background(DuelTheme.scoreRule))

            DuelScoreBoard(
                playerMarks = model.playerMarks,
                opponentMarks = model.opponentMarks,
                current = model.index,
                currentRound = if (model.index < model.questionCount) model.roundNumber else 0,
                opponentName = opponent.handle,
                language = language,
            )
        }
    }
}

/**
 * Un camp dans le bloc de score : l'avatar cerclé, le score en grand et le nom dessous. Le
 * score rebondit quand il monte ; le cercle passe au vert ou au rouge pendant la révélation
 * (`scored` vaut alors vrai ou faux).
 */
@Composable
private fun ScoreSide(
    avatarId: String?,
    initial: String,
    name: String,
    score: Int,
    /** La couleur du camp (cercle de l'avatar). */
    tint: Color,
    scoreColor: Color,
    isPlayer: Boolean,
    /** Le camp a répondu, la révélation n'est pas encore tombée. */
    answered: Boolean,
    scored: Boolean?,
    /** Le camp de droite : nom et score à gauche de l'avatar, alignés à droite. */
    mirrored: Boolean,
    modifier: Modifier = Modifier,
) {
    val avatarScale by animateFloatAsState(
        targetValue = if (answered) 1.06f else 1f,
        animationSpec = duelSpring(response = 0.3f, damping = 0.6f),
        label = "duelSideAvatar",
    )
    val ringColor by animateColorAsState(
        targetValue = when (scored) {
            null -> tint
            true -> DuelTheme.stripRight
            false -> DuelTheme.stripWrong
        },
        animationSpec = DSMotion.snappy(),
        label = "duelSideRing",
    )
    // Le score qui monte : il gonfle d'un coup, puis revient sur un ressort.
    val bump = remember { Animatable(1f) }
    val lastScore = remember { IntArray(1) { score } }
    LaunchedEffect(score) {
        val rose = score > lastScore[0]
        lastScore[0] = score
        if (rose) {
            launch { bump.animateTo(1.3f, DSMotion.pop()) }
            delay(220)
            bump.animateTo(1f, DSMotion.snappy())
        }
    }

    val avatar: @Composable () -> Unit = {
        Box(
            modifier = Modifier.graphicsLayer {
                scaleX = avatarScale
                scaleY = avatarScale
            },
        ) {
            AvatarCircle(avatarId = avatarId, initial = initial, size = 48.dp)
            Box(modifier = Modifier.matchParentSize().border(if (scored == null) 3.dp else 4.dp, ringColor, CircleShape))
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
                        .size(18.dp)
                        .background(DS.accent, CircleShape)
                        .border(2.dp, DuelTheme.scoreBlock, CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(Icons.Filled.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(10.dp))
                }
            }
        }
    }
    val labels: @Composable (Modifier) -> Unit = { labelsModifier ->
        Column(
            modifier = labelsModifier,
            horizontalAlignment = if (mirrored) Alignment.End else Alignment.Start,
            verticalArrangement = Arrangement.spacedBy(1.dp),
        ) {
            // Le chiffre défile vers le haut quand le score change.
            AnimatedContent(
                targetState = score,
                transitionSpec = {
                    (slideInVertically(DSMotion.snappy()) { it / 2 } + fadeIn(tween(160)))
                        .togetherWith(slideOutVertically(tween(160)) { -it / 2 } + fadeOut(tween(120)))
                        .using(SizeTransform(clip = false))
                },
                contentAlignment = if (mirrored) Alignment.CenterEnd else Alignment.CenterStart,
                modifier = Modifier.graphicsLayer {
                    scaleX = bump.value
                    scaleY = bump.value
                    transformOrigin = TransformOrigin(if (mirrored) 1f else 0f, 1f)
                },
                label = "duelSideScore",
            ) { shown ->
                Text(
                    text = shown.toString(),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 36.sp,
                    lineHeight = 38.sp,
                    style = DuelTabularDigits,
                    color = scoreColor,
                    maxLines = 1,
                )
            }
            DuelShrinkText(
                text = name,
                fontSize = 12.sp,
                fontWeight = if (isPlayer) FontWeight.Bold else FontWeight.SemiBold,
                color = if (isPlayer) DS.ink else DS.inkSecondary,
                minScale = 0.7f,
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

/** Le sur-titre de la question : la matière de la manche au choix, ou « Sprint final ». */
@Composable
private fun QuestionEyebrow(subject: String?, sprint: Boolean, language: AppLanguage) {
    val context = LocalContext.current
    if (subject != null) {
        val look = DuelSubjects.of(subject)
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Box(modifier = Modifier.size(20.dp).background(look.color, CircleShape), contentAlignment = Alignment.Center) {
                Icon(look.icon, contentDescription = null, tint = Color.White, modifier = Modifier.size(12.dp))
            }
            Text(
                text = duelSubjectName(context, subject, language).uppercaseIn(language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 12.sp,
                letterSpacing = 0.8.sp,
                color = DS.accent,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
    } else if (sprint) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Icon(Icons.Filled.Bolt, contentDescription = null, tint = DS.accent, modifier = Modifier.size(14.dp))
            Text(
                text = StringStore.text(context, "duel.round.sprint.title", language).uppercaseIn(language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 12.sp,
                letterSpacing = 0.8.sp,
                color = DS.accent,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

@Composable
private fun QuestionArea(ui: DuelQuestionUi, sprint: Boolean, model: DuelGameModel, live: Boolean, language: AppLanguage) {
    val question = ui.question
    val portrait = question.kind == DuelQuestionKind.PORTRAIT
    // Une question longue ou accompagnée d'une image prend un corps plus petit.
    val compactTitle = portrait || question.question.length > 90
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp)
            .padding(top = 20.dp, bottom = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Column(
            modifier = Modifier.widthIn(max = 592.dp).fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            QuestionEyebrow(subject = ui.subject, sprint = sprint, language = language)

            if (portrait) DuelQuestionImage(url = question.imageUrl)

            Text(
                text = question.question,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = if (compactTitle) 21.sp else 25.sp,
                lineHeight = if (compactTitle) 27.sp else 31.sp,
                color = DS.ink,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(bottom = 10.dp),
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
                    language = language,
                    onChoose = { if (live) model.choose(it) },
                )
            }
        }
    }
}

// ---------------------------------------------------------------- bandeau de verdict

/** Le ton du bandeau : vert quand le joueur marque, rouge sinon, neutre hors verdict. */
private enum class VerdictTone { Neutral, Good, Bad }

/**
 * Le bandeau du bas : ce que fait l'adversaire pendant la question (trois points sautillent
 * quand on l'attend), puis le verdict à la révélation et où en est le score.
 */
@Composable
private fun VerdictBanner(model: DuelGameModel, language: AppLanguage, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    fun text(key: String, vararg args: Any): String = StringStore.text(context, key, language, *args)
    val handle = model.match.opponent.handle
    val round = model.lastRound

    val status = when {
        // L'adversaire vient de quitter la partie : la victoire suit.
        model.opponentForfeited -> text("duel.friend.left", handle)
        model.phase == DuelPhase.Answering -> when {
            // Entre amis : l'ami a quitté la partie, on la finit seul.
            model.opponentLeft -> text("duel.friend.left", handle)
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
    val verdict = model.phase == DuelPhase.Reveal && !model.opponentForfeited && round != null
    val tone = when {
        !verdict -> VerdictTone.Neutral
        round?.player == true -> VerdictTone.Good
        else -> VerdictTone.Bad
    }
    // La partie droite, à la révélation : « +1 point · tu mènes 4 à 3 ». Rien pour la question
    // décisive, qui ne compte pas au score.
    val detail = if (verdict && !model.isSuddenDeath) {
        val mine = model.playerScore
        val theirs = model.opponentScore
        val standing = when {
            mine > theirs -> text("duel.verdict.leading", mine, theirs)
            theirs > mine -> text("duel.verdict.trailing", handle, theirs, mine)
            else -> text("duel.verdict.tied", mine)
        }
        if (round?.player == true) text("duel.verdict.point") + " · " + standing else standing
    } else {
        null
    }
    // Le joueur a répondu et attend l'adversaire.
    val waiting = model.phase == DuelPhase.Answering && !model.opponentForfeited && !model.opponentLeft &&
        model.playerLocked && !model.opponentAnswered

    // Le joueur perd la question sans carte à secouer (temps écoulé, curseur) : c'est le bandeau
    // qui tremble. La vibration du verdict vient du déroulé (`DuelHaptic.Wrong`).
    val lostWithoutCard = tone == VerdictTone.Bad &&
        (model.question.kind == DuelQuestionKind.SLIDER || model.selectedChoice == null)
    var shakes by remember { mutableIntStateOf(0) }
    LaunchedEffect(lostWithoutCard, model.index) {
        if (lostWithoutCard) shakes += 1
    }

    val visible = status.isNotBlank()
    val ink by animateColorAsState(
        targetValue = when (tone) {
            VerdictTone.Neutral -> DS.inkSecondary
            VerdictTone.Good -> DS.success
            VerdictTone.Bad -> DS.danger
        },
        animationSpec = DSMotion.snappy(),
        label = "duelVerdictInk",
    )
    val fill by animateColorAsState(
        targetValue = when (tone) {
            VerdictTone.Neutral -> DuelTheme.scoreBlock
            VerdictTone.Good -> DS.successTint
            VerdictTone.Bad -> DS.dangerTint
        },
        animationSpec = DSMotion.snappy(),
        label = "duelVerdictFill",
    )
    val shown by animateFloatAsState(if (visible) 1f else 0f, DSMotion.snappy(), label = "duelVerdictShown")
    // Le dernier texte reste écrit le temps que le bandeau s'efface.
    val lastStatus = remember { arrayOf("") }
    if (visible) lastStatus[0] = status

    Row(
        modifier = modifier
            .fillMaxWidth()
            .dsShake(trigger = shakes)
            .graphicsLayer {
                alpha = shown.coerceIn(0f, 1f)
                val scale = 0.97f + 0.03f * shown
                scaleX = scale
                scaleY = scale
            }
            .heightIn(min = 48.dp)
            .background(fill, DS.cardShape)
            .padding(horizontal = 16.dp, vertical = 12.dp)
            .then(if (visible) Modifier.semantics(mergeDescendants = true) {} else Modifier.clearAndSetSemantics {}),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        DuelShrinkText(
            text = if (visible) status else lastStatus[0],
            fontSize = 16.sp,
            fontWeight = FontWeight.ExtraBold,
            color = ink,
            maxLines = 2,
            modifier = Modifier.weight(1f),
        )
        if (detail != null) {
            DuelShrinkText(
                text = detail,
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold,
                color = ink,
                maxLines = 2,
                textAlign = TextAlign.End,
                modifier = Modifier.widthIn(max = 190.dp),
            )
        } else if (waiting) {
            DuelWaitingDots(color = DS.inkSecondary)
        }
    }
}

// ---------------------------------------------------------------- question décisive

@Composable
private fun SuddenDeathBanner(model: DuelGameModel, language: AppLanguage) {
    val context = LocalContext.current
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas.copy(alpha = 0.97f))
            .pointerInput(Unit) {},
        contentAlignment = Alignment.Center,
    ) {
        Column(
            modifier = Modifier.widthIn(max = 520.dp).padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Box(
                modifier = Modifier.dsPopIn(delayMillis = 100).size(88.dp).background(DS.accentTint, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Filled.Bolt, contentDescription = null, tint = DS.accent, modifier = Modifier.size(40.dp))
            }
            Text(
                text = StringStore.text(context, "duel.suddenDeath.title", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 32.sp,
                lineHeight = 38.sp,
                color = DS.ink,
                textAlign = TextAlign.Center,
            )
            Text(
                text = StringStore.text(context, "duel.suddenDeath.body", language, model.playerScore, model.opponentScore),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Medium,
                fontSize = 17.sp,
                lineHeight = 23.sp,
                color = DS.inkSecondary,
                textAlign = TextAlign.Center,
            )
        }
    }
}
