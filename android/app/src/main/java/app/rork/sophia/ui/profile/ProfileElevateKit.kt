package app.rork.sophia.ui.profile

import android.content.Context
import android.provider.Settings
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.Icon
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
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Campaign
import app.rork.sophia.domain.Subject
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.components.DSCountUp
import app.rork.sophia.ui.components.DSMotion
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.newgen.NewGenFormat
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.uppercaseInApp
import kotlinx.coroutines.delay
import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * Briques « Elevate arrondi » propres à la zone profil (progression, amis, badges, réglages,
 * compte), le pendant Android de `ProfileElevateKit.swift`. Ce qui est commun à toute l'app vit
 * dans `ElevateKit.kt` ; ici, seulement ce que ces écrans partagent entre eux : l'identité du
 * lecteur, les titres de section, les rangées, les barres qui se remplissent à l'apparition et
 * les compteurs qui respectent le réglage « Supprimer les animations ».
 */

// region Identité du lecteur

/**
 * Les deux lignes d'identité qui ne viennent pas du compte : le titre tiré des centres
 * d'intérêt (« Amoureux de Littérature ») et le mois d'arrivée dans l'app.
 */
object ProfileIdentity {
    /** Le titre choisi à l'onboarding d'après la première matière cochée ; sinon le titre par défaut. */
    fun rankTitle(context: Context, language: AppLanguage): String {
        val app = context.applicationContext as SophiaApplication
        val interests = app.onboardingStore.answers().topics.toSet()
        val first = Subject.entries.map { it.storageKey }.firstOrNull { it in interests }
        return if (first == null) {
            StringStore.text(context, "onboarding.program.nickname.default", language)
        } else {
            StringStore.text(context, "onboarding.program.nickname.$first", language)
        }
    }

    /**
     * Le mois du premier cours ouvert, faute de date de création de compte ; `null` tant
     * qu'aucun cours n'a été ouvert (la ligne « membre depuis » est alors omise).
     */
    fun memberSince(progress: UserProgress, language: AppLanguage): String? =
        progress.courseProgress.values.mapNotNull { it.startedAt }.minOrNull()
            ?.let { Campaign.parseDay(it) }
            ?.let { NewGenFormat.monthYear(it, language) }
}

/** Vrai quand le téléphone a coupé les animations (« Supprimer les animations »). */
@Composable
fun rememberProfileReduceMotion(): Boolean {
    val context = LocalContext.current
    return remember {
        runCatching {
            Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f
        }.getOrDefault(false)
    }
}

// endregion

// region Titres

/**
 * Titre de section des écrans du profil (« Par matière », « Badges ») : graisse moyenne, avec
 * un complément gris facultatif (« · 2 », « 0/5 ») et un lien de fin de ligne.
 */
@Composable
fun ProfileSectionHeader(
    title: String,
    modifier: Modifier = Modifier,
    detail: String? = null,
    trailing: (@Composable () -> Unit)? = null,
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Row(
            modifier = Modifier.weight(1f).semantics(mergeDescendants = true) { heading() },
            verticalAlignment = Alignment.Bottom,
            horizontalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Text(
                text = title,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 20.sp,
                lineHeight = 26.sp,
                color = DS.ink,
                modifier = Modifier.weight(1f, fill = false),
            )
            if (detail != null) {
                Text(
                    text = detail,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 20.sp,
                    lineHeight = 26.sp,
                    color = DS.inkSecondary,
                    maxLines = 1,
                )
            }
        }
        if (trailing != null) trailing()
    }
}

/** Sur-titre de groupe des réglages (« COMPTE », « LANGUE ») : petites capitales espacées, grises. */
@Composable
fun ProfileGroupLabel(text: String, modifier: Modifier = Modifier) {
    Text(
        text = text.uppercaseInApp(),
        modifier = modifier.semantics { heading() },
        fontFamily = PlusJakartaSans,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 12.sp,
        letterSpacing = 0.8.sp,
        color = DS.inkSecondary,
    )
}

/** Lien de fin de titre (« Tout voir › », « Voir plus › ») : gras bleu, avec son chevron. */
@Composable
fun ProfileHeaderLink(
    title: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    showsChevron: Boolean = true,
) {
    Row(
        modifier = modifier
            .pressable(onClick = onClick)
            .padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        Text(
            text = title,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 15.sp,
            color = DS.accent,
            maxLines = 1,
        )
        if (showsChevron) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = DS.accent,
                modifier = Modifier.size(18.dp),
            )
        }
    }
}

/**
 * La première ligne d'une page poussée ou d'une feuille : un bouton rond de chaque côté (ou
 * son pendant vide, pour le centrage) et le titre centré, en gras serré.
 */
@Composable
fun ProfileCenteredTitleBar(
    title: String,
    modifier: Modifier = Modifier,
    leading: (@Composable () -> Unit)? = null,
    trailing: (@Composable () -> Unit)? = null,
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Box(modifier = Modifier.size(44.dp), contentAlignment = Alignment.Center) { leading?.invoke() }
        Text(
            text = title,
            modifier = Modifier.weight(1f).semantics { heading() },
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 16.sp,
            color = DS.ink,
            textAlign = TextAlign.Center,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Box(modifier = Modifier.size(44.dp), contentAlignment = Alignment.Center) { trailing?.invoke() }
    }
}

/**
 * L'en-tête calme des pages légales et du formulaire de retour : le titre en graisse moyenne
 * à gauche, le bouton rond du design à droite.
 */
@Composable
fun ProfileSheetHeader(
    title: String,
    closeIcon: ImageVector,
    closeLabel: String,
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            text = title,
            modifier = Modifier.weight(1f).semantics { heading() },
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 28.sp,
            lineHeight = 34.sp,
            color = DS.ink,
        )
        ProfileRoundButton(icon = closeIcon, contentDescription = closeLabel, onClick = onClose)
    }
}

// endregion

// region Boutons ronds et rangées

/** Bouton rond blanc de 44 dp (fermer, retour, réglages) : bordure nette, pression élastique. */
@Composable
fun ProfileRoundButton(
    icon: ImageVector,
    contentDescription: String?,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    size: Dp = 44.dp,
    tint: Color = DS.ink,
) {
    Box(
        modifier = modifier
            .size(size)
            .pressable(onClick = onClick, scaleDown = 0.92f)
            .clip(CircleShape)
            .background(DS.surface)
            .border(1.5.dp, DS.hairline, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Icon(imageVector = icon, contentDescription = contentDescription, tint = tint, modifier = Modifier.size(18.dp))
    }
}

/** Filet entre deux rangées d'une même carte. */
@Composable
fun ProfileRowDivider(modifier: Modifier = Modifier, inset: Dp = 16.dp) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = inset)
            .height(1.dp)
            .background(DS.hairline),
    )
}

/**
 * Pression douce d'une rangée de liste : le fond se teinte et la rangée s'enfonce à peine,
 * avec la vibration légère du style. À poser sur les rangées d'une carte groupée.
 */
@Composable
fun Modifier.profileRowPress(
    onClick: () -> Unit,
    enabled: Boolean = true,
    haptic: Boolean = true,
): Modifier {
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val haptics = rememberHaptics()
    val scale by animateFloatAsState(if (pressed) 0.985f else 1f, DSMotion.press(), label = "rowPressScale")
    val rest = DS.accentTint.copy(alpha = 0f)
    val tint by animateColorAsState(
        targetValue = if (pressed) DS.accentTint.copy(alpha = 0.55f) else rest,
        animationSpec = DSMotion.press(),
        label = "rowPressTint",
    )
    LaunchedEffect(pressed) {
        if (pressed && haptic && enabled) haptics.soft()
    }
    return this
        .graphicsLayer {
            scaleX = scale
            scaleY = scale
        }
        .background(tint)
        .clickable(interactionSource = interaction, indication = null, enabled = enabled, onClick = onClick)
}

/** Chevron de fin de rangée. */
@Composable
fun ProfileRowChevron(modifier: Modifier = Modifier) {
    Icon(
        imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
        contentDescription = null,
        tint = DS.inkSecondary,
        modifier = modifier.size(20.dp),
    )
}

// endregion

// region Onglets en pastilles

/**
 * Onglets en pastilles de la maquette (« 7 jours · Tout », « À lire · Lus · Aimés ») : la
 * pastille active en bleu plein, les autres en bleu pâle. [fills] les étire sur la largeur.
 */
@Composable
fun ProfilePillTabs(
    items: List<String>,
    selectedIndex: Int,
    onSelect: (Int) -> Unit,
    modifier: Modifier = Modifier,
    fills: Boolean = false,
) {
    val haptics = rememberHaptics()
    val shape = RoundedCornerShape(14.dp)
    Row(
        modifier = if (fills) modifier.fillMaxWidth() else modifier,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        items.forEachIndexed { index, item ->
            val isSelected = index == selectedIndex
            val fill by animateColorAsState(if (isSelected) DS.accent else DS.accentTint, DSMotion.snappy(), label = "pillFill")
            val ink by animateColorAsState(if (isSelected) Color.White else DS.ink, DSMotion.snappy(), label = "pillInk")
            Box(
                modifier = (if (fills) Modifier.weight(1f) else Modifier)
                    .height(40.dp)
                    .pressable(
                        onClick = {
                            if (!isSelected) {
                                haptics.select()
                                onSelect(index)
                            }
                        },
                        haptic = false,
                    )
                    .clip(shape)
                    .background(fill)
                    .semantics {
                        selected = isSelected
                        role = Role.Tab
                    }
                    .padding(horizontal = 14.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = item,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp,
                    color = ink,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    textAlign = TextAlign.Center,
                )
            }
        }
    }
}

// endregion

// region Barre qui se remplit

/**
 * Barre de progression arrondie qui se remplit à l'apparition (XP d'un niveau, cours d'une
 * matière, avancement d'un badge), puis suit sa valeur. [delayMillis] décale le remplissage,
 * pour une cascade de barres.
 */
@Composable
fun ProfileFillBar(
    fraction: Float,
    modifier: Modifier = Modifier,
    height: Dp = 8.dp,
    tint: Color = DS.accent,
    track: Color = DS.hairline,
    delayMillis: Int = 200,
) {
    var shown by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(delayMillis.toLong())
        shown = true
    }
    val clamped = if (fraction.isNaN()) 0f else fraction.coerceIn(0f, 1f)
    val width by animateFloatAsState(if (shown) clamped else 0f, DSMotion.reveal(), label = "fillBar")
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(height)
            .clip(CircleShape)
            .background(track)
            .clearAndSetSemantics { },
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth(width.coerceIn(0f, 1f))
                .fillMaxHeight()
                .clip(CircleShape)
                .background(tint),
        )
    }
}

// endregion

// region Compteur

/**
 * Un nombre qui défile jusqu'à sa valeur, figé quand le téléphone a coupé les animations.
 * [format] écrit le nombre dans son texte (« 3 j », « 12 400 ») : quand le nombre y figure tel
 * quel, [DSCountUp] le fait défiler et le reste ne bouge pas ; sinon (séparateur de milliers,
 * chiffres d'une autre écriture) chaque étape est réécrite par [format].
 */
@Composable
fun ProfileCountText(
    value: Int,
    modifier: Modifier = Modifier,
    style: TextStyle = TextStyle(fontFamily = PlusJakartaSans, fontWeight = FontWeight.ExtraBold, fontSize = 22.sp),
    color: Color = DS.ink,
    haptics: Boolean = false,
    format: ((Int) -> String)? = null,
) {
    val reduceMotion = rememberProfileReduceMotion()
    val finalText = format?.invoke(value) ?: "$value"
    if (reduceMotion || value <= 0) {
        Text(text = finalText, modifier = modifier, style = style, color = color, maxLines = 1)
        return
    }
    val plain = "$value"
    val at = finalText.indexOf(plain)
    if (at >= 0) {
        DSCountUp(
            value = value,
            modifier = modifier,
            durationMillis = 700,
            style = style,
            color = color,
            prefix = finalText.substring(0, at),
            suffix = finalText.substring(at + plain.length),
            haptics = haptics,
        )
        return
    }
    // Même cadence que DSCountUp, mais chaque étape passe par le format de la langue.
    var shown by remember { mutableIntStateOf(0) }
    val feedback = rememberHaptics()
    LaunchedEffect(value) {
        val start = shown
        val delta = value - start
        if (delta == 0) return@LaunchedEffect
        val steps = abs(delta).coerceAtMost(24)
        for (step in 1..steps) {
            delay((700 / steps).toLong())
            shown = start + (delta.toFloat() * step / steps).roundToInt()
            if (haptics && step % 3 == 0) feedback.tick()
        }
        shown = value
        if (haptics) feedback.soft()
    }
    Text(
        text = format?.invoke(shown) ?: "$shown",
        modifier = modifier,
        style = style,
        color = color,
        maxLines = 1,
    )
}

// endregion

// region Carte illustrée

/**
 * Carte d'entrée illustrée du profil (« Entraînement », « Ma progression ») : vignette en
 * papier découpé, titre, une ligne, chevron.
 */
@Composable
fun ProfilePosterCard(
    imageRes: Int,
    title: String,
    subtitle: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .pressable(onClick = onClick)
            .sophiaCard()
            .padding(start = 10.dp, end = 14.dp, top = 10.dp, bottom = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Image(
            painter = painterResource(imageRes),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.size(60.dp).clip(RoundedCornerShape(14.dp)),
        )
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                text = title,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 17.sp,
                lineHeight = 22.sp,
                color = DS.ink,
            )
            Text(
                text = subtitle,
                fontFamily = PlusJakartaSans,
                fontSize = 13.sp,
                lineHeight = 18.sp,
                color = DS.inkSecondary,
            )
        }
        ProfileRowChevron()
    }
}

// endregion

// region Champ de saisie

/**
 * Champ de saisie du design : fond blanc, bordure nette qui passe au bleu quand le champ a le
 * focus. [prefix] précède la saisie (le « @ » d'un pseudo).
 */
@Composable
fun ProfileTextField(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    modifier: Modifier = Modifier,
    singleLine: Boolean = true,
    minHeight: Dp = 52.dp,
    prefix: String? = null,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    /** Une couleur de bordure imposée (verdict : demande partie, pseudo refusé). */
    borderOverride: Color? = null,
    fillOverride: Color? = null,
) {
    val interaction = remember { MutableInteractionSource() }
    val focused by interaction.collectIsFocusedAsState()
    val border by animateColorAsState(
        targetValue = borderOverride ?: if (focused) DS.accent else DS.hairline,
        animationSpec = DSMotion.snappy(),
        label = "fieldBorder",
    )
    val fill by animateColorAsState(fillOverride ?: DS.surface, DSMotion.snappy(), label = "fieldFill")
    val textStyle = TextStyle(fontFamily = PlusJakartaSans, fontWeight = FontWeight.Medium, fontSize = 16.sp, lineHeight = 23.sp, color = DS.ink)
    Row(
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = minHeight)
            .clip(DS.controlShape)
            .background(fill)
            .border(1.5.dp, border, DS.controlShape)
            .padding(horizontal = 14.dp, vertical = 14.dp),
        verticalAlignment = if (singleLine) Alignment.CenterVertically else Alignment.Top,
    ) {
        if (prefix != null) {
            Text(
                text = prefix,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 16.sp,
                lineHeight = 23.sp,
                color = DS.accent,
            )
            Spacer(Modifier.width(6.dp))
        }
        Box(modifier = Modifier.weight(1f)) {
            if (value.isEmpty()) {
                Text(
                    text = placeholder,
                    fontFamily = PlusJakartaSans,
                    fontSize = 16.sp,
                    lineHeight = 23.sp,
                    color = DS.inkTertiary,
                    maxLines = if (singleLine) 1 else Int.MAX_VALUE,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            BasicTextField(
                value = value,
                onValueChange = onValueChange,
                singleLine = singleLine,
                textStyle = textStyle,
                cursorBrush = SolidColor(DS.accent),
                keyboardOptions = keyboardOptions,
                interactionSource = interaction,
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }
}

// endregion
