package app.rork.sophia.ui.newgen

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.ArrowOutward
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Public
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.AppConfig
import app.rork.sophia.R
import app.rork.sophia.data.AuthorStore
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.course.AuthorAvatar
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans

/**
 * La page « Deviens créateur » : l'illustration papier du site, la promesse, les trois étapes,
 * puis la sortie vers le Hub des créateurs dans la langue de l'app ([AppConfig.creatorHubUrl]).
 * Ouverte par les cartes du fil, du profil et des pages d'événement (`BecomeCreatorView` sur iOS).
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun BecomeCreatorScreen(
    language: AppLanguage,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val authors = remember { AuthorStore.all(context.applicationContext).take(5) }
    val languagesCount = AppLanguage.entries.size

    Column(modifier = modifier.fillMaxSize().background(DS.canvas)) {
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp)
                .padding(top = 8.dp, bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(22.dp),
        ) {
            // L'illustration dans un cadre de carte, avec le retour posé dessus.
            Box(modifier = Modifier.dsStagger(0)) {
                Image(
                    painter = painterResource(R.drawable.creator_poster),
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier
                        .fillMaxWidth()
                        .aspectRatio(4f / 3f)
                        .homeCard(),
                )
                RoundIconButton(
                    icon = Icons.AutoMirrored.Filled.ArrowBack,
                    onClick = onBack,
                    contentDescription = StringStore.text(context, "common.close", language),
                    modifier = Modifier.padding(12.dp),
                )
            }

            Column(modifier = Modifier.dsStagger(1), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                if (authors.isNotEmpty()) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        // Les portraits se chevauchent de 10 dp, cerclés de la couleur du fond.
                        Row {
                            authors.forEachIndexed { index, author ->
                                AuthorAvatar(
                                    author = author,
                                    size = 32.dp,
                                    modifier = Modifier
                                        .offset(x = (-10 * index).dp)
                                        .border(2.dp, DS.canvas, CircleShape),
                                )
                            }
                        }
                        Text(
                            text = StringStore.text(context, "creator.invite.kicker", language),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 12.sp,
                            color = DS.inkSecondary,
                            maxLines = 2,
                            modifier = Modifier.offset(x = (-10 * (authors.size - 1)).dp),
                        )
                    }
                }

                Text(
                    text = StringStore.text(context, "creator.invite.title", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 28.sp,
                    lineHeight = 35.sp,
                    color = DS.ink,
                )
                Text(
                    text = StringStore.text(context, "creator.invite.body", language, languagesCount),
                    fontFamily = PlusJakartaSans,
                    fontSize = 16.sp,
                    lineHeight = 24.sp,
                    color = DS.inkSecondary,
                )
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.padding(top = 2.dp),
                ) {
                    Perk(Icons.Filled.Edit, StringStore.text(context, "creator.invite.perk.write", language))
                    Perk(Icons.Filled.Public, StringStore.text(context, "creator.invite.perk.languages", language, languagesCount))
                    Perk(Icons.Filled.BarChart, StringStore.text(context, "creator.invite.perk.paid", language))
                }
            }

            // Les trois étapes.
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .dsStagger(2)
                    .homeCard()
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    Image(
                        painter = painterResource(R.drawable.creator_writing),
                        contentDescription = null,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.size(72.dp).clip(RoundedCornerShape(DS.Radius.small)),
                    )
                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text(
                            text = StringStore.text(context, "profile.creator.title", language),
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 20.sp,
                            color = DS.ink,
                        )
                        Text(
                            text = StringStore.text(context, "profile.creator.subtitle", language),
                            fontFamily = PlusJakartaSans,
                            fontSize = 15.sp,
                            color = DS.inkSecondary,
                        )
                    }
                }
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Step(1, StringStore.text(context, "profile.creator.step1", language))
                    Step(2, StringStore.text(context, "profile.creator.step2", language, languagesCount))
                    Step(3, StringStore.text(context, "profile.creator.step3", language))
                }
            }
        }

        // La sortie vers le Hub, toujours visible en bas de page.
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(DS.canvas)
                .padding(horizontal = 24.dp)
                .padding(top = 10.dp, bottom = 8.dp),
        ) {
            // Le CTA fournit la pression élastique et la vibration.
            HomeCtaButton(
                text = StringStore.text(context, "creator.invite.cta", language),
                trailingIcon = Icons.Filled.ArrowOutward,
                onClick = {
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(AppConfig.creatorHubUrl(language)))
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    runCatching { context.startActivity(intent) }
                },
            )
        }
    }
}

@Composable
private fun Step(number: Int, text: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Box(
            modifier = Modifier.size(26.dp).clip(CircleShape).background(DS.accentTint),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = "$number",
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 13.sp,
                color = DS.accent,
            )
        }
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontSize = 15.sp,
            lineHeight = 21.sp,
            color = DS.ink,
            modifier = Modifier.weight(1f).padding(top = 2.dp),
        )
    }
}

@Composable
private fun Perk(icon: ImageVector, text: String) {
    Row(
        modifier = Modifier
            .height(32.dp)
            .clip(CircleShape)
            .background(DS.accentTint)
            .padding(horizontal = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Icon(imageVector = icon, contentDescription = null, tint = DS.accent, modifier = Modifier.size(14.dp))
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 13.sp,
            color = DS.ink,
            maxLines = 1,
        )
    }
}
