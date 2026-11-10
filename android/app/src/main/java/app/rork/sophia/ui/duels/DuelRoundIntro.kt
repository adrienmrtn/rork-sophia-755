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
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.CheckCircle
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
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.DuelRoundKind
import app.rork.sophia.domain.uppercaseIn
import app.rork.sophia.ui.components.softPress
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

/** La croix qui ouvre « Quitter le duel ? », sur l'en-tête de la partie et sur ses annonces. */
@Composable
internal fun DuelQuitButton(language: AppLanguage, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val label = StringStore.text(LocalContext.current, "duel.quit.title", language)
    Box(
        modifier = modifier
            .size(32.dp)
            .clip(CircleShape)
            .background(Color.White.copy(alpha = 0.14f))
            .clickable(role = Role.Button, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Icon(Icons.Filled.Close, contentDescription = label, tint = Color.White.copy(alpha = 0.85f), modifier = Modifier.size(16.dp))
    }
}

/**
 * L'annonce d'une manche, par-dessus l'écran de jeu : trois matières au choix (et le temps qui
 * reste pour choisir), la matière que l'adversaire est en train de choisir puis celle qu'il a
 * retenue, ou le sprint final. Même contenu que
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
            .background(DuelPalette.night.copy(alpha = 0.96f))
            // L'annonce prend les touches : pas de réponse donnée à travers elle.
            .pointerInput(Unit) {},
    ) {
        Column(
            modifier = Modifier
                .align(Alignment.Center)
                .widthIn(max = 520.dp)
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 28.dp, vertical = 48.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(22.dp),
        ) {
            Text(
                text = text("duel.round.title", intro.number).uppercaseIn(language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 15.sp,
                letterSpacing = 2.2.sp,
                color = DuelPalette.saffron,
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

        DuelQuitButton(
            language = language,
            onClick = onQuit,
            modifier = Modifier.align(Alignment.TopStart).padding(start = 16.dp, top = 6.dp),
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
            fontWeight = FontWeight.ExtraBold,
            fontSize = 30.sp,
            lineHeight = 36.sp,
            color = Color.White,
            textAlign = TextAlign.Center,
        )

        // Le temps qui reste pour choisir ; la place reste prise une fois le choix fait.
        val deadline = intro.deadlineMs
        if (deadline != null && intro.chosen == null) {
            var remaining by remember(deadline) { mutableFloatStateOf(1f) }
            LaunchedEffect(deadline) {
                val window = maxOf(deadline - intro.opensAtMs, 100L).toFloat()
                while (true) {
                    remaining = (maxOf(deadline - model.nowMs(), 0L) / window).coerceIn(0f, 1f)
                    withFrameNanos { }
                }
            }
            DuelProgressBar(
                progress = remaining,
                tint = DuelPalette.saffron,
                track = Color.White.copy(alpha = 0.18f),
                height = 5.dp,
            )
        } else {
            Spacer(Modifier.height(5.dp))
        }

        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            intro.options.forEach { subject ->
                SubjectCard(
                    subject = subject,
                    language = language,
                    selected = intro.chosen == subject,
                    dimmed = intro.chosen != null && intro.chosen != subject,
                    modifier = Modifier.softPress(
                        onClick = { model.pickSubject(subject) },
                        enabled = intro.chosen == null,
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
                    color = Color.White.copy(alpha = 0.85f),
                    textAlign = TextAlign.Center,
                )
                SubjectCard(subject = chosen, language = language, selected = true, dimmed = false)
            } else {
                DuelPulseRings(color = Color.White, modifier = Modifier.padding(vertical = 26.dp).size(64.dp))
                Text(
                    text = StringStore.text(context, "duel.round.pick.theirs", language, opponentHandle),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 22.sp,
                    lineHeight = 28.sp,
                    color = Color.White,
                    textAlign = TextAlign.Center,
                )
            }
        }
    }
}

// ---------------------------------------------------------------- sprint

@Composable
private fun Sprint(language: AppLanguage) {
    val context = LocalContext.current
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Icon(Icons.Filled.Bolt, contentDescription = null, tint = DuelPalette.saffron, modifier = Modifier.size(60.dp))
        Text(
            text = StringStore.text(context, "duel.round.sprint.title", language),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 34.sp,
            lineHeight = 40.sp,
            color = Color.White,
            textAlign = TextAlign.Center,
        )
        Text(
            text = StringStore.text(context, "duel.round.sprint.body", language),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Medium,
            fontSize = 17.sp,
            lineHeight = 23.sp,
            color = Color.White.copy(alpha = 0.8f),
            textAlign = TextAlign.Center,
        )
    }
}

// ---------------------------------------------------------------- une matière

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
    val shape = RoundedCornerShape(20.dp)
    val scale by animateFloatAsState(
        targetValue = if (selected) 1.02f else 1f,
        animationSpec = duelSpring(response = 0.35f, damping = 0.7f),
        label = "duelSubjectScale",
    )
    val opacity by animateFloatAsState(
        targetValue = if (dimmed) 0.4f else 1f,
        animationSpec = tween(200),
        label = "duelSubjectAlpha",
    )
    Row(
        modifier = modifier
            .fillMaxWidth()
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            }
            .alpha(opacity)
            .background(Color.White.copy(alpha = if (selected) 0.18f else 0.1f), shape)
            .border(
                width = if (selected) 2.5.dp else 1.dp,
                color = if (selected) DuelPalette.saffron else Color.White.copy(alpha = 0.14f),
                shape = shape,
            )
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Box(modifier = Modifier.size(48.dp).background(look.color, CircleShape), contentAlignment = Alignment.Center) {
            Icon(look.icon, contentDescription = null, tint = Color.White, modifier = Modifier.size(24.dp))
        }
        DuelShrinkText(
            text = duelSubjectName(context, subject, language),
            fontSize = 19.sp,
            fontWeight = FontWeight.ExtraBold,
            color = Color.White,
            maxLines = 2,
            modifier = Modifier.weight(1f),
        )
        if (selected) {
            Icon(Icons.Filled.CheckCircle, contentDescription = null, tint = DuelPalette.saffron, modifier = Modifier.size(26.dp))
        }
    }
}
