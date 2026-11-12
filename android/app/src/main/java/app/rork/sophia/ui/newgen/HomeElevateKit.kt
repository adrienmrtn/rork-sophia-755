package app.rork.sophia.ui.newgen

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.drawOutline
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import kotlinx.coroutines.delay

// Briques « Elevate arrondi » propres à l'accueil, à l'onglet Explorer, aux pages événement /
// créateur et à la barre d'onglets, comme `HomeElevateKit.swift` : la carte dont on choisit la
// bordure, les onglets soulignés du fil, le libellé de CTA posé dans une carte déjà cliquable,
// l'apparition pilotée par l'écran (pour les pages d'un pager, où `dsStagger` rejouerait) et la
// barre d'onglets du bas.

// MARK: - Cadre de carte

/**
 * Carte du style : fond, contenu rogné au rayon, bordure nette de 1,5 dp et léger rebord bas.
 * Comme `sophiaCard()`, mais la couleur de la bordure se choisit (champ de recherche actif,
 * puce sélectionnée). N'ajoute ni marge ni largeur.
 */
fun Modifier.homeCard(
    shape: Shape = DS.cardShape,
    fill: Color = DS.surface,
    border: Color = DS.hairline,
): Modifier = this
    .drawBehind {
        val outline = shape.createOutline(size, layoutDirection, this)
        translate(top = 1.5.dp.toPx()) { drawOutline(outline, border) }
    }
    .clip(shape)
    .background(fill)
    .border(1.5.dp, border, shape)

// MARK: - Onglets soulignés

/**
 * Les onglets du fil (« Pour toi » / « Abonnements ») : chacun prend la même largeur, sur toute
 * la ligne, et un trait bleu glisse sous l'onglet actif. Un point signale du nouveau derrière
 * un onglet qui n'est pas affiché ([dotLabel] : ce que TalkBack en dit).
 */
@Composable
fun HomeFeedTabs(
    items: List<String>,
    selection: Int,
    onSelect: (Int) -> Unit,
    modifier: Modifier = Modifier,
    dotOn: Int? = null,
    dotLabel: String? = null,
) {
    val haptics = rememberHaptics()
    val count = items.size.coerceAtLeast(1)
    BoxWithConstraints(modifier = modifier.fillMaxWidth().height(46.dp)) {
        val tabWidth = maxWidth / count
        val underlineWidth = 56.dp
        val underlineX by animateDpAsState(
            targetValue = tabWidth * selection.coerceIn(0, count - 1) + (tabWidth - underlineWidth) / 2,
            animationSpec = DSMotion.snappy(),
            label = "feedTabUnderline",
        )
        Box(modifier = Modifier.align(Alignment.BottomStart).fillMaxWidth().height(1.dp).background(DS.hairline))
        Row(modifier = Modifier.fillMaxSize()) {
            items.forEachIndexed { index, item ->
                val selected = selection == index
                val color by animateColorAsState(
                    targetValue = if (selected) DS.ink else DS.inkTertiary,
                    animationSpec = DSMotion.snappy(),
                    label = "feedTabText",
                )
                Row(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxHeight()
                        .selectable(
                            selected = selected,
                            interactionSource = remember { MutableInteractionSource() },
                            indication = null,
                            role = Role.Tab,
                            onClick = {
                                if (!selected) {
                                    haptics.select()
                                    onSelect(index)
                                }
                            },
                        )
                        .padding(horizontal = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center,
                ) {
                    Text(
                        text = item,
                        fontFamily = PlusJakartaSans,
                        fontWeight = if (selected) FontWeight.Bold else FontWeight.SemiBold,
                        fontSize = 15.sp,
                        color = color,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f, fill = false),
                    )
                    if (dotOn == index && !selected) {
                        Spacer(Modifier.width(6.dp))
                        Box(
                            modifier = Modifier
                                .size(7.dp)
                                .clip(CircleShape)
                                .background(DS.accent)
                                .then(
                                    if (dotLabel != null) {
                                        Modifier.semantics { contentDescription = dotLabel }
                                    } else {
                                        Modifier
                                    },
                                ),
                        )
                    }
                }
            }
        }
        Box(
            modifier = Modifier
                .align(Alignment.BottomStart)
                .offset(x = underlineX)
                .size(width = underlineWidth, height = 3.dp)
                .clip(CircleShape)
                .background(DS.accent),
        )
    }
}

// MARK: - CTA

/**
 * L'apparence du CTA bleu (54 dp, rayon 16) pour une carte entièrement cliquable : ce n'est pas
 * un bouton, c'est la carte qui reçoit le geste.
 */
@Composable
fun HomeCtaLabel(
    text: String,
    modifier: Modifier = Modifier,
    leadingIcon: ImageVector? = null,
    trailingIcon: ImageVector? = null,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(54.dp)
            .clip(DS.controlShape)
            .background(DS.accent)
            .padding(horizontal = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(7.dp, Alignment.CenterHorizontally),
    ) {
        if (leadingIcon != null) {
            Icon(imageVector = leadingIcon, contentDescription = null, tint = Color.White, modifier = Modifier.size(17.dp))
        }
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 16.sp,
            color = Color.White,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center,
            modifier = Modifier.weight(1f, fill = false),
        )
        if (trailingIcon != null) {
            Icon(imageVector = trailingIcon, contentDescription = null, tint = Color.White, modifier = Modifier.size(17.dp))
        }
    }
}

/** Le CTA bleu en bouton : pression élastique et vibration franche à l'appui. */
@Composable
fun HomeCtaButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    leadingIcon: ImageVector? = null,
    trailingIcon: ImageVector? = null,
) {
    val haptics = rememberHaptics()
    HomeCtaLabel(
        text = text,
        leadingIcon = leadingIcon,
        trailingIcon = trailingIcon,
        modifier = modifier.pressable(
            onClick = {
                haptics.confirm()
                onClick()
            },
            scaleDown = 0.96f,
            haptic = false,
        ),
    )
}

// MARK: - Apparition pilotée

/**
 * Apparition en cascade dont l'état vit chez le parent : la page d'un pager peut être détruite
 * puis recréée au défilement sans rejouer son entrée. [index] décale l'entrée (0 d'abord, puis
 * 1…) ; repasser [shown] à faux cache d'un coup, pour rejouer.
 */
@Composable
fun Modifier.homeReveal(shown: Boolean, index: Int = 0): Modifier {
    val progress = remember { Animatable(if (shown) 1f else 0f) }
    LaunchedEffect(shown) {
        if (!shown) {
            progress.snapTo(0f)
        } else if (progress.value < 1f) {
            delay(40L + index.coerceAtLeast(0) * 80L)
            progress.animateTo(1f, DSMotion.reveal())
        }
    }
    val offsetPx = with(LocalDensity.current) { 16.dp.toPx() }
    return this.graphicsLayer {
        alpha = progress.value.coerceIn(0f, 1f)
        translationY = (1f - progress.value) * offsetPx
    }
}

// MARK: - Barre d'onglets

/** Un onglet de [SophiaBottomBar] : son index, son libellé, son icône au repos et active. */
data class SophiaBottomTab(
    val index: Int,
    val label: String,
    val icon: ImageVector,
    val selectedIcon: ImageVector = icon,
)

/**
 * La barre d'onglets du design : fond blanc, filet en haut, icône et libellé bleus pour l'onglet
 * actif, gris sinon. L'icône de l'onglet choisi rebondit et le téléphone fait un cran.
 */
@Composable
fun SophiaBottomBar(
    tabs: List<SophiaBottomTab>,
    selectedIndex: Int,
    onSelect: (Int) -> Unit,
    modifier: Modifier = Modifier,
    labelSize: TextUnit = 11.sp,
) {
    val haptics = rememberHaptics()
    Column(modifier = modifier.fillMaxWidth().background(DS.surface)) {
        Box(modifier = Modifier.fillMaxWidth().height(1.dp).background(DS.hairline))
        Row(modifier = Modifier.fillMaxWidth().height(58.dp).padding(horizontal = 4.dp)) {
            tabs.forEach { tab ->
                val selected = selectedIndex == tab.index
                val tint by animateColorAsState(
                    targetValue = if (selected) DS.accent else DS.inkSecondary,
                    animationSpec = DSMotion.snappy(),
                    label = "tabTint",
                )
                // Le rebond ne joue qu'au passage à l'onglet, pas à la première composition.
                val bounce = remember { Animatable(1f) }
                var wasSelected by remember { mutableStateOf(selected) }
                LaunchedEffect(selected) {
                    if (selected && !wasSelected) {
                        bounce.snapTo(0.74f)
                        bounce.animateTo(1f, DSMotion.pop())
                    }
                    wasSelected = selected
                }
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxHeight()
                        .selectable(
                            selected = selected,
                            interactionSource = remember { MutableInteractionSource() },
                            indication = null,
                            role = Role.Tab,
                            onClick = {
                                if (!selected) haptics.select()
                                onSelect(tab.index)
                            },
                        )
                        .padding(top = 2.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                ) {
                    Icon(
                        imageVector = if (selected) tab.selectedIcon else tab.icon,
                        contentDescription = null,
                        tint = tint,
                        modifier = Modifier
                            .size(24.dp)
                            .graphicsLayer {
                                scaleX = bounce.value
                                scaleY = bounce.value
                            },
                    )
                    Spacer(Modifier.height(3.dp))
                    Text(
                        text = tab.label,
                        fontFamily = PlusJakartaSans,
                        fontSize = labelSize,
                        fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Medium,
                        color = tint,
                        maxLines = 1,
                        softWrap = false,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
        }
    }
}
