package app.rork.sophia.ui.onboarding

import androidx.annotation.DrawableRes
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import app.rork.sophia.R
import app.rork.sophia.data.AuthorStore
import app.rork.sophia.data.CourseAuthor
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.dsHighlighted
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext

/** An author with an illustrated portrait: slug of the catalogue → drawable. */
private class ResearcherPortrait(val slug: String, @DrawableRes val art: Int)

private val RESEARCHER_PORTRAITS = listOf(
    ResearcherPortrait("stacy-jankowski", R.drawable.onb_prof_stacy),
    ResearcherPortrait("simon-lea", R.drawable.onb_prof_simon),
    ResearcherPortrait("dusan-nikolic", R.drawable.onb_prof_dusan),
    ResearcherPortrait("guido-manuel-de-la-torre-olvera", R.drawable.onb_prof_guido),
)

private val RESEARCHER_PORTRAIT_SIZE = 92.dp
private val RESEARCHER_PORTRAIT_OVERLAP = 22.dp

/** Night blue of the pills' text, on their pale blue background. */
private val RESEARCHER_PILL_INK = Color(0xFF1A3A6B)

/**
 * The institution of the author; else the first part of their title (« Docteur en
 * philosophie, chercheur indépendant » → « Docteur en philosophie »).
 */
private fun credentialOf(author: CourseAuthor, language: AppLanguage): String? {
    author.institution?.trim()?.takeIf { it.isNotEmpty() }?.let { return it }
    return author.title(language)?.substringBefore(',')?.trim()?.takeIf { it.isNotEmpty() }
}

/**
 * Screen 4 — Researchers. Four « paper » portraits of real authors of the app overlapping,
 * the title « written by real researchers », and their institutions as pills. Names and
 * institutions come from the catalogue ([AuthorStore]); only the illustrated portraits are
 * bundled.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun ResearchersStep(language: AppLanguage, onContinue: () -> Unit) {
    val context = LocalContext.current
    val haptics = rememberHaptics()
    val reduceMotion = rememberOnboardingReduceMotion()
    // What the catalogue knows of the four illustrated authors. An author missing from it
    // keeps their portrait, without name or pill.
    var authors by remember {
        mutableStateOf(RESEARCHER_PORTRAITS.associate { it.slug to runCatching { AuthorStore.author(it.slug) }.getOrNull() })
    }
    LaunchedEffect(language) {
        if (authors.values.all { it != null }) return@LaunchedEffect
        authors = withContext(Dispatchers.IO) {
            val all = runCatching { AuthorStore.all(context.applicationContext) }.getOrDefault(emptyList())
            RESEARCHER_PORTRAITS.associate { portrait -> portrait.slug to all.firstOrNull { it.slug == portrait.slug } }
        }
    }
    // The pills, without duplicates (two authors may share a university).
    val credentials = remember(authors, language) {
        RESEARCHER_PORTRAITS.mapNotNull { portrait -> authors[portrait.slug]?.let { credentialOf(it, language) } }.distinct()
    }

    var portraitsShown by remember { mutableIntStateOf(if (reduceMotion) RESEARCHER_PORTRAITS.size else 0) }
    var textIn by remember { mutableStateOf(reduceMotion) }
    var pillsIn by remember { mutableStateOf(reduceMotion) }
    // The portraits land one by one, then the title, then the pills in a cascade.
    LaunchedEffect(Unit) {
        if (reduceMotion) return@LaunchedEffect
        delay(200)
        for (count in 1..RESEARCHER_PORTRAITS.size) {
            portraitsShown = count
            haptics.tick()
            delay(120)
        }
        textIn = true
        delay(250)
        pillsIn = true
        haptics.soft()
    }
    val textProgress by animateFloatAsState(if (textIn) 1f else 0f, DSMotion.reveal(), label = "researchersText")

    OnboardingPage(
        footer = {
            OnboardingCta(
                text = StringStore.text(context, "common.continue", language),
                onClick = onContinue,
                modifier = Modifier.padding(top = 14.dp),
            )
        },
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = ONBOARDING_SIDE_INSET, vertical = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(22.dp),
        ) {
            BoxWithConstraints(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                // Full size when the row fits, smaller on a narrow screen.
                val count = RESEARCHER_PORTRAITS.size
                val size = minOf(
                    RESEARCHER_PORTRAIT_SIZE,
                    (maxWidth + RESEARCHER_PORTRAIT_OVERLAP * (count - 1)) / count,
                )
                Row(horizontalArrangement = Arrangement.spacedBy(-RESEARCHER_PORTRAIT_OVERLAP)) {
                    RESEARCHER_PORTRAITS.forEachIndexed { index, portrait ->
                        val shown by animateFloatAsState(
                            targetValue = if (index < portraitsShown) 1f else 0f,
                            animationSpec = DSMotion.pop(),
                            label = "researcherPortrait",
                        )
                        Image(
                            painter = painterResource(portrait.art),
                            // The author's name, read by the screen reader; none when the catalogue does not know them.
                            contentDescription = authors[portrait.slug]?.name,
                            contentScale = ContentScale.Crop,
                            modifier = Modifier
                                .zIndex(index.toFloat())
                                .size(size)
                                .graphicsLayer {
                                    alpha = shown.coerceIn(0f, 1f)
                                    val scale = 0.3f + 0.7f * shown
                                    scaleX = scale
                                    scaleY = scale
                                }
                                .clip(CircleShape)
                                .border(4.dp, DS.surface, CircleShape),
                        )
                    }
                }
            }

            OnboardingShrinkText(
                text = dsHighlighted(StringStore.text(context, "onboardingV2.intro.researchers.title", language), DS.accent),
                style = TextStyle(
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Normal,
                    fontSize = 28.sp,
                    lineHeight = 36.sp,
                    color = DS.ink,
                ),
                maxLines = 5,
                modifier = Modifier
                    .fillMaxWidth()
                    .graphicsLayer {
                        alpha = textProgress.coerceIn(0f, 1f)
                        translationY = (1f - textProgress) * 14.dp.toPx()
                    }
                    .semantics { heading() },
            )

            if (credentials.isNotEmpty()) {
                FlowRow(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    credentials.forEachIndexed { index, credential ->
                        ResearcherPill(text = credential, shown = pillsIn, index = index)
                    }
                }
            }

            Text(
                text = StringStore.text(context, "onboardingV2.intro.researchers.subtitle", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Normal,
                fontSize = 15.sp,
                lineHeight = 22.sp,
                color = DS.inkSecondary,
                textAlign = TextAlign.Center,
                modifier = Modifier.graphicsLayer { alpha = textProgress.coerceIn(0f, 1f) },
            )
        }
    }
}

/** A pill of the cascade: each lands a little after the one before. */
@Composable
private fun ResearcherPill(text: String, shown: Boolean, index: Int) {
    var landed by remember { mutableStateOf(false) }
    LaunchedEffect(shown) {
        if (!shown) return@LaunchedEffect
        delay(index * 70L)
        landed = true
    }
    val progress by animateFloatAsState(if (landed) 1f else 0f, DSMotion.snappy(), label = "researcherPill")
    Text(
        text = text,
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.SemiBold,
        fontSize = 13.sp,
        color = RESEARCHER_PILL_INK,
        maxLines = 1,
        overflow = TextOverflow.Ellipsis,
        modifier = Modifier
            .graphicsLayer {
                alpha = progress.coerceIn(0f, 1f)
                val scale = 0.8f + 0.2f * progress
                scaleX = scale
                scaleY = scale
            }
            .background(DS.accentTint, RoundedCornerShape(16.dp))
            .padding(horizontal = 14.dp, vertical = 8.dp),
    )
}
