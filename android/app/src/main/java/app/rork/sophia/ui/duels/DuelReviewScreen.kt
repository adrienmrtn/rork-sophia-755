package app.rork.sophia.ui.duels

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.DuelOpponent
import app.rork.sophia.domain.DuelQuestion
import app.rork.sophia.domain.DuelQuestionKind
import app.rork.sophia.domain.uppercaseIn
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.newgen.AvatarCircle
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import coil.compose.rememberAsyncImagePainter

/**
 * Ce que la relecture écrit pour une question : la bonne réponse, ma réponse et celle de
 * l'adversaire, en clair. Sans rien d'affichage, pour être vérifié par des tests.
 */
internal object DuelReviewText {
    /** La bonne réponse : l'option juste, ou la valeur exacte au curseur. */
    fun correct(question: DuelQuestion): String? =
        if (question.kind == DuelQuestionKind.SLIDER) {
            question.correctValue?.let { DuelFormat.sliderValue(it, question.unit) }
        } else {
            option(question, question.correctIndex)
        }

    /** Ma réponse ; rien si je n'ai pas répondu. */
    fun mine(entry: DuelReviewEntry): String? =
        if (entry.question.kind == DuelQuestionKind.SLIDER) {
            entry.mine?.v?.let { DuelFormat.sliderValue(it, entry.question.unit) }
        } else {
            option(entry.question, entry.mine?.c)
        }

    /** La réponse de l'adversaire ; rien s'il n'a pas répondu ou si l'app ne la connaît pas. */
    fun theirs(entry: DuelReviewEntry): String? =
        if (entry.question.kind == DuelQuestionKind.SLIDER) {
            entry.theirs?.value?.let { DuelFormat.sliderValue(it, entry.question.unit) }
        } else {
            option(entry.question, entry.theirs?.choice)
        }

    private fun option(question: DuelQuestion, index: Int?): String? =
        if (index == null) null else question.options?.getOrNull(index)
}

/**
 * « Revoir les questions » : chaque question de la partie, la bonne réponse, ce que j'ai répondu
 * et ce que l'adversaire a répondu. Tout vient de [DuelSummary.review], rempli par
 * [DuelGameModel] pendant la partie : aucun appel au serveur. Même page que
 * `ios/Sophia/Views/Duels/DuelReviewView.swift`.
 */
@Composable
internal fun DuelReviewScreen(
    entries: List<DuelReviewEntry>,
    /** Le nombre de questions de la partie, hors question décisive. */
    questionCount: Int,
    player: DuelPlayerIdentity,
    opponent: DuelOpponent,
    language: AppLanguage,
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    fun text(key: String, vararg args: Any): String = StringStore.text(context, key, language, *args)

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            // La relecture couvre le résultat : ses boutons ne répondent plus dessous.
            .pointerInput(Unit) {},
    ) {
        Column(modifier = Modifier.align(Alignment.TopCenter).widthIn(max = 640.dp).fillMaxSize()) {
            Row(
                modifier = Modifier.fillMaxWidth().padding(start = 20.dp, end = 20.dp, top = 16.dp, bottom = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                DuelShrinkText(
                    text = text("duel.review.open"),
                    fontSize = 22.sp,
                    fontWeight = FontWeight.ExtraBold,
                    color = DS.ink,
                    maxLines = 2,
                    minScale = 0.7f,
                    modifier = Modifier.weight(1f),
                )
                DuelRoundIconButton(
                    icon = Icons.Filled.Close,
                    contentDescription = text("duel.result.done"),
                    onClick = onClose,
                    size = 40.dp,
                )
            }

            LazyColumn(
                modifier = Modifier.fillMaxWidth().weight(1f),
                contentPadding = PaddingValues(start = 20.dp, end = 20.dp, top = 8.dp, bottom = 28.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(entries, key = { it.index }) { entry ->
                    // « Question 3 / 20 », ou « Mort subite » pour la question décisive.
                    val counter = if (entry.isTiebreak) {
                        text("duel.suddenDeath.title")
                    } else {
                        text("duel.game.counter", entry.index + 1, questionCount)
                    }
                    ReviewCard(
                        entry = entry,
                        counter = counter.uppercaseIn(language),
                        youLabel = text("duel.you"),
                        noAnswerLabel = text("duel.review.noAnswer"),
                        player = player,
                        opponent = opponent,
                    )
                }
            }
        }
    }
}

/** Une question : son rang, son texte (et son image), la bonne réponse, puis chaque joueur. */
@Composable
private fun ReviewCard(
    entry: DuelReviewEntry,
    counter: String,
    youLabel: String,
    noAnswerLabel: String,
    player: DuelPlayerIdentity,
    opponent: DuelOpponent,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .sophiaCard(elevation = 0.dp)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Text(
            text = counter,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 11.sp,
            letterSpacing = 0.8.sp,
            color = if (entry.isTiebreak) DS.accent else DS.inkSecondary,
        )

        Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.Top) {
            val imageUrl = entry.question.imageUrl
            if (entry.question.kind == DuelQuestionKind.PORTRAIT && !imageUrl.isNullOrBlank()) {
                ReviewImage(url = imageUrl)
            }
            Text(
                text = entry.question.question,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 16.sp,
                lineHeight = 22.sp,
                color = DS.ink,
                modifier = Modifier.weight(1f),
            )
        }

        DuelReviewText.correct(entry.question)?.let { correct ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(DS.successTint, RoundedCornerShape(12.dp))
                    .padding(horizontal = 12.dp, vertical = 9.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Icon(
                    imageVector = Icons.Filled.Check,
                    contentDescription = null,
                    tint = DS.success,
                    modifier = Modifier.size(18.dp),
                )
                Text(
                    text = correct,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 15.sp,
                    lineHeight = 20.sp,
                    color = DS.success,
                    modifier = Modifier.weight(1f),
                )
            }
        }

        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            AnswerRow(
                avatarId = player.avatarId,
                initial = player.initial,
                name = youLabel,
                text = DuelReviewText.mine(entry),
                noAnswerLabel = noAnswerLabel,
                answered = entry.iAnswered,
                point = entry.playerPoint,
            )
            AnswerRow(
                avatarId = opponent.avatarId,
                initial = opponent.initial,
                name = "@${opponent.handle}",
                text = DuelReviewText.theirs(entry),
                noAnswerLabel = noAnswerLabel,
                answered = entry.theyAnswered,
                point = entry.opponentPoint,
            )
        }
    }
}

/** La vignette d'une question à image, entière dans sa place. */
@Composable
private fun ReviewImage(url: String) {
    val context = LocalContext.current
    // La même requête que pendant la partie : l'image est déjà en mémoire.
    val request = remember(url) { duelQuestionImageRequest(context, url) }
    Image(
        painter = rememberAsyncImagePainter(model = request),
        contentDescription = null,
        contentScale = ContentScale.Fit,
        modifier = Modifier.size(width = 64.dp, height = 80.dp).clip(RoundedCornerShape(10.dp)),
    )
}

/** Un joueur : son avatar, son nom, ce qu'il a répondu, et s'il a marqué. */
@Composable
private fun AnswerRow(
    avatarId: String?,
    initial: String,
    name: String,
    text: String?,
    noAnswerLabel: String,
    answered: Boolean,
    point: Boolean,
) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Box(modifier = Modifier.size(28.dp), contentAlignment = Alignment.Center) {
            AvatarCircle(avatarId = avatarId, initial = initial, size = 28.dp)
            Box(modifier = Modifier.matchParentSize().border(1.dp, DS.hairline, CircleShape))
        }
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
            Text(
                text = name,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 12.sp,
                lineHeight = 16.sp,
                color = DS.inkSecondary,
                maxLines = 1,
            )
            Text(
                text = text ?: noAnswerLabel,
                fontFamily = PlusJakartaSans,
                fontWeight = if (answered) FontWeight.SemiBold else FontWeight.Medium,
                fontSize = 15.sp,
                lineHeight = 20.sp,
                color = if (answered) DS.ink else DS.inkTertiary,
            )
        }
        ReviewMark(answered = answered, point = point)
    }
}

/**
 * La coche de celui qui a marqué, la croix d'une réponse qui n'a rien rapporté, un tiret pour
 * une question restée sans réponse.
 */
@Composable
private fun ReviewMark(answered: Boolean, point: Boolean) {
    val shape = CircleShape
    when {
        point -> Box(
            modifier = Modifier.size(24.dp).background(DS.success, shape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(15.dp))
        }
        answered -> Box(
            modifier = Modifier.size(24.dp).background(DS.danger, shape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.Close, contentDescription = null, tint = Color.White, modifier = Modifier.size(14.dp))
        }
        else -> Box(
            modifier = Modifier.size(24.dp).border(1.5.dp, DS.hairline, shape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.Remove, contentDescription = null, tint = DS.inkTertiary, modifier = Modifier.size(14.dp))
        }
    }
}
