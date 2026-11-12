package app.rork.sophia.ui.duels

import android.content.Context
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.DuelRoundKind
import app.rork.sophia.domain.uppercaseIn
import app.rork.sophia.ui.components.DSCheckBadge
import app.rork.sophia.ui.components.DSOptionState
import app.rork.sophia.ui.components.dsOptionCard
import app.rork.sophia.ui.components.dsPopIn
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans

/**
 * Le nom d'une matière de manche dans la langue de l'app : celui de la matière correspondante
 * de l'app (comme iOS), sinon le nom de secours des duels.
 */
internal fun duelSubjectName(context: Context, key: String, language: AppLanguage): String {
    val stringKey = when (key) {
        "history" -> "subject.histoire"
        "science" -> "subject.sciences"
        "literature" -> "subject.litterature"
        "art" -> "subject.art"
        "mythology" -> "subject.mythologie"
        "world" -> "subject.comprendreLeMonde"
        else -> return DuelSubjects.of(key).name
    }
    // Une clé absente de la table revient telle quelle : le nom de secours vaut mieux.
    return StringStore.text(context, stringKey, language).takeIf { it != stringKey } ?: DuelSubjects.of(key).name
}

/**
 * La croix qui ouvre « Quitter le duel ? », sur l'en-tête de la partie et sur ses annonces. Elle
 * ne vibre pas d'elle-même : la question qu'elle pose le fait déjà (`DuelHaptic.Tap`).
 */
@Composable
internal fun DuelQuitButton(language: AppLanguage, onClick: () -> Unit, modifier: Modifier = Modifier) {
    DuelRoundIconButton(
        icon = Icons.Filled.Close,
        contentDescription = StringStore.text(LocalContext.current, "duel.quit.title", language),
        onClick = onClick,
        modifier = modifier,
        haptic = false,
    )
}

/**
 * L'annonce d'une manche, par-dessus l'écran de jeu : trois matières au choix (et le temps qui
 * reste pour choisir), la matière que l'adversaire est en train de choisir puis celle qu'il a
 * retenue, ou le sprint final. Fond blanc, comme le reste du duel. Même contenu que
 * `ios/Sophia/Views/Duels/DuelRoundIntroView.swift`.
 */
@Composable
internal fun DuelRoundIntroOverlay(
    model: DuelGameModel,
    intro: DuelRoundAnnouncement,
    opponentHandle: String,
    language: AppLanguage,
    /** L'annonce couvre l'écran de jeu : elle porte son propre bouton pour quitter le duel. */
    onQuit: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    fun text(key: String, vararg args: Any): String = StringStore.text(context, key, language, *args)

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas.copy(alpha = 0.98f))
            // L'annonce prend les touches : pas de réponse donnée à travers elle.
            .pointerInput(Unit) {},
    ) {
        Column(
            modifier = Modifier
                .align(Alignment.Center)
                .widthIn(max = 520.dp)
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp, vertical = 60.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            Text(
                text = text("duel.round.title", intro.number).uppercaseIn(language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 12.sp,
                letterSpacing = 1.6.sp,
                color = DS.accent,
            )
            when (intro.kind) {
                DuelRoundKind.PICK -> if (intro.mine) {
                    MyPick(model = model, intro = intro, language = language)
                } else {
                    TheirPick(intro = intro, opponentHandle = opponentHandle, language = language)
                }
                DuelRoundKind.SPRINT -> Sprint(language = language)
                DuelRoundKind.MIXED -> Unit
            }
        }

        // Même place que le bouton de l'écran de jeu, qu'elle recouvre.
        DuelQuitButton(
            language = language,
            onClick = onQuit,
            modifier = Modifier.align(Alignment.TopStart).padding(start = 24.dp, top = 8.dp),
        )
    }
}

// ---------------------------------------------------------------- à moi de choisir

@Composable
private fun MyPick(model: DuelGameModel, intro: DuelRoundAnnouncement, language: AppLanguage) {
    val context = LocalContext.current
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(18.dp)) {
        Text(
            text = StringStore.text(context, "duel.round.pick.title", language),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 26.sp,
            lineHeight = 32.sp,
            color = DS.ink,
            textAlign = TextAlign.Center,
        )

        // Le temps qui reste pour choisir ; la place reste prise une fois le choix fait.
        val deadline = intro.deadlineMs
        if (deadline != null && intro.chosen == null) {
            PickCountdownBar(model = model, opensAtMs = intro.opensAtMs, deadlineMs = deadline)
        } else {
            Spacer(Modifier.height(5.dp))
        }

        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            intro.options.forEachIndexed { index, subject ->
                SubjectCard(
                    subject = subject,
                    language = language,
                    selected = intro.chosen == subject,
                    dimmed = intro.chosen != null && intro.chosen != subject,
                    modifier = Modifier
                        .dsStagger(index, stepMillis = 70, baseMillis = 100)
                        // Le choix vibre déjà (`DuelHaptic.Lock`).
                        .pressable(
                            onClick = { model.pickSubject(subject) },
                            enabled = intro.chosen == null,
                            haptic = false,
                        ),
                )
            }
        }
    }
}

// ---------------------------------------------------------------- à l'adversaire de choisir

@Composable
private fun TheirPick(intro: DuelRoundAnnouncement, opponentHandle: String, language: AppLanguage) {
    val context = LocalContext.current
    AnimatedContent(
        targetState = intro.chosen,
        transitionSpec = {
            (scaleIn(duelSpring(response = 0.4f, damping = 0.65f), initialScale = 0.7f) + fadeIn(tween(200)))
                .togetherWith(fadeOut(tween(150)))
        },
        contentAlignment = Alignment.Center,
        modifier = Modifier.animateContentSize(),
        label = "duelTheirPick",
    ) { chosen ->
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            if (chosen != null) {
                Text(
                    text = StringStore.text(context, "duel.round.pick.theirChoice", language, opponentHandle),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 17.sp,
                    lineHeight = 22.sp,
                    color = DS.inkSecondary,
                    textAlign = TextAlign.Center,
                )
                SubjectCard(subject = chosen, language = language, selected = true, dimmed = false)
            } else {
                DuelPulseRings(color = DS.accent, modifier = Modifier.padding(vertical = 26.dp).size(64.dp))
                Text(
                    text = StringStore.text(context, "duel.round.pick.theirs", language, opponentHandle),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 20.sp,
                    lineHeight = 26.sp,
                    color = DS.ink,
                    textAlign = TextAlign.Center,
                )
                DuelWaitingDots(color = DS.accent)
            }
        }
    }
}

// ---------------------------------------------------------------- sprint

@Composable
private fun Sprint(language: AppLanguage) {
    val context = LocalContext.current
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Box(
            modifier = Modifier.dsPopIn(delayMillis = 100).size(88.dp).background(DS.accentTint, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.Bolt, contentDescription = null, tint = DS.accent, modifier = Modifier.size(40.dp))
        }
        Text(
            text = StringStore.text(context, "duel.round.sprint.title", language),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 32.sp,
            lineHeight = 38.sp,
            color = DS.ink,
            textAlign = TextAlign.Center,
        )
        Text(
            text = StringStore.text(context, "duel.round.sprint.body", language),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Medium,
            fontSize = 17.sp,
            lineHeight = 23.sp,
            color = DS.inkSecondary,
            textAlign = TextAlign.Center,
        )
    }
}

// ---------------------------------------------------------------- une matière

/**
 * Une matière en carte d'option : sa pastille de couleur, son nom, et la coche une fois
 * retenue.
 */
@Composable
private fun SubjectCard(
    subject: String,
    language: AppLanguage,
    selected: Boolean,
    dimmed: Boolean,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val look = DuelSubjects.of(subject)
    val scale by animateFloatAsState(
        targetValue = if (selected) 1.02f else 1f,
        animationSpec = duelSpring(response = 0.35f, damping = 0.7f),
        label = "duelSubjectScale",
    )
    val state = when {
        selected -> DSOptionState.Selected
        dimmed -> DSOptionState.Dimmed
        else -> DSOptionState.Idle
    }
    Row(
        modifier = modifier
            .fillMaxWidth()
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            }
            .dsOptionCard(state)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Box(modifier = Modifier.size(44.dp).background(look.color, CircleShape), contentAlignment = Alignment.Center) {
            Icon(look.icon, contentDescription = null, tint = Color.White, modifier = Modifier.size(22.dp))
        }
        DuelShrinkText(
            text = duelSubjectName(context, subject, language),
            fontSize = 17.sp,
            fontWeight = if (selected) FontWeight.Bold else FontWeight.SemiBold,
            color = DS.ink,
            maxLines = 2,
            modifier = Modifier.weight(1f),
        )
        if (selected) {
            DSCheckBadge(size = 26.dp, fill = DS.accent)
        }
    }
}

/**
 * Le temps qui reste pour choisir sa matière. À part, pour que seule cette jauge se recompose
 * à chaque image, et non les trois cartes de matière au-dessus d'elle.
 */
@Composable
private fun PickCountdownBar(model: DuelGameModel, opensAtMs: Long, deadlineMs: Long) {
    var remaining by remember(deadlineMs) { mutableFloatStateOf(1f) }
    LaunchedEffect(deadlineMs) {
        val window = maxOf(deadlineMs - opensAtMs, 100L).toFloat()
        while (true) {
            remaining = (maxOf(deadlineMs - model.nowMs(), 0L) / window).coerceIn(0f, 1f)
            withFrameNanos { }
        }
    }
    DuelProgressBar(
        progress = remaining,
        tint = DS.accent,
        track = DS.accentTint,
        height = 5.dp,
    )
}
