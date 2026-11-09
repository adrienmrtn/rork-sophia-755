package app.rork.sophia.ui.newgen

import android.content.Context
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.DirectionsRun
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.AcUnit
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.CardGiftcard
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.Eco
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.filled.Palette
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.Public
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.Science
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.AuthorStore
import app.rork.sophia.data.CourseAuthor
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.stripInlineMarkup
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.Subject
import app.rork.sophia.domain.locale
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.course.AuthorAvatar
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import java.text.SimpleDateFormat
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Date

// Briques des écrans « Sophia nouvelle génération » (maquette prompt 2) : identité d'un
// créateur, pastilles, compteurs, lignes de cours compactes, segments. Mêmes pièces que
// `NewGenComponents.swift` ; les prompts 6, 7 et 10 n'ont qu'à brancher les vraies données.

// MARK: - Créateur

/**
 * Qui signe un cours sur une carte : un auteur de [AuthorStore], ou l'équipe Sophia pour les
 * cours maison (la majorité du catalogue n'a pas encore d'auteur nommé).
 */
sealed class CreatorIdentity {
    data class Author(val value: CourseAuthor) : CreatorIdentity()
    data object House : CreatorIdentity()

    val author: CourseAuthor? get() = (this as? Author)?.value

    val slug: String? get() = author?.slug

    val name: String get() = author?.name ?: "Sophia"

    val isVerified: Boolean get() = author?.isVerified ?: true

    /** Les créateurs peuvent être suivis ; l'équipe Sophia n'a pas de page. */
    val isFollowable: Boolean get() = author != null

    fun pedigree(context: Context, language: AppLanguage): String? =
        author?.title(language) ?: StringStore.text(context, "creator.house.pedigree", language)

    companion object {
        fun forCourse(context: Context, courseId: String): CreatorIdentity {
            val author = AuthorStore.authorForCourse(context, courseId)
            return if (author != null) Author(author) else House
        }
    }
}

/** Portrait ou initiales d'un auteur ; la marque Sophia pour les cours maison. */
@Composable
fun CreatorAvatar(identity: CreatorIdentity, size: Dp, modifier: Modifier = Modifier) {
    when (identity) {
        is CreatorIdentity.Author -> AuthorAvatar(author = identity.value, size = size, modifier = modifier)
        CreatorIdentity.House -> Box(
            modifier = modifier.size(size).clip(CircleShape).background(DS.accent),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                text = "S",
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = (size.value * 0.46f).sp,
                color = Color.White,
            )
        }
    }
}

/** Coche bleue des experts vérifiés, à côté du nom. */
@Composable
fun VerifiedCheck(language: AppLanguage, size: Dp = 14.dp, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    Icon(
        imageVector = Icons.Filled.Verified,
        contentDescription = StringStore.text(context, "creator.badge.verified", language),
        tint = DS.accentSoft,
        modifier = modifier.size(size),
    )
}

/** « Expert vérifié » (bleu) ou « Créateur » (violet) : le statut d'un créateur, en capsule. */
@Composable
fun CreatorBadge(verified: Boolean, language: AppLanguage, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val tint = if (verified) DS.accentSoft else Color(0xFF4D1C94)
    val background = if (verified) DS.accentTint else Color(0xFFF2EDFA)
    Row(
        modifier = modifier
            .clip(CircleShape)
            .background(background)
            .padding(horizontal = 12.dp, vertical = 7.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Icon(
            imageVector = if (verified) Icons.Filled.Verified else Icons.Filled.Edit,
            contentDescription = null,
            tint = tint,
            modifier = Modifier.size(14.dp),
        )
        Text(
            text = StringStore.text(context, if (verified) "creator.badge.verified" else "creator.badge.creator", language),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 14.sp,
            color = tint,
        )
    }
}

/** Avatar, nom avec coche, pedigree : la ligne « qui a écrit ça » des cartes et des fiches. */
@Composable
fun CreatorLine(
    identity: CreatorIdentity,
    language: AppLanguage,
    modifier: Modifier = Modifier,
    avatarSize: Dp = 36.dp,
    showsPedigree: Boolean = true,
    onTap: (() -> Unit)? = null,
) {
    val context = LocalContext.current
    val clickable = onTap != null && identity.isFollowable
    Row(
        modifier = modifier
            .fillMaxWidth()
            .then(if (clickable) Modifier.softPress(onClick = { onTap?.invoke() }) else Modifier),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        CreatorAvatar(identity = identity, size = avatarSize)
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    text = identity.name,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp,
                    color = DS.ink,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f, fill = false),
                )
                if (identity.isVerified) VerifiedCheck(language = language, size = 13.dp)
            }
            if (showsPedigree) {
                identity.pedigree(context, language)?.let { pedigree ->
                    Text(
                        text = pedigree,
                        fontFamily = PlusJakartaSans,
                        fontSize = 12.sp,
                        color = DS.inkSecondary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
        }
    }
}

/** « Suivre » plein ou « Abonné » en contour. Le geste reste local jusqu'au prompt 6. */
@Composable
fun FollowButton(
    isFollowing: Boolean,
    language: AppLanguage,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    compact: Boolean = false,
) {
    val context = LocalContext.current
    val shape = RoundedCornerShape(if (compact) 10.dp else 14.dp)
    Box(
        modifier = modifier
            .then(if (compact) Modifier else Modifier.fillMaxWidth())
            .height(if (compact) 34.dp else 44.dp)
            .softPress(onClick = onClick)
            .clip(shape)
            .background(if (isFollowing) DS.surface else DS.accent)
            .then(if (isFollowing) Modifier.border(1.dp, DS.hairline, shape) else Modifier)
            .padding(horizontal = if (compact) 14.dp else 18.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = StringStore.text(context, if (isFollowing) "creator.following" else "creator.follow", language),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = if (compact) 13.sp else 15.sp,
            color = if (isFollowing) DS.accent else Color.White,
            maxLines = 1,
        )
    }
}

// MARK: - Pastilles et chips

/**
 * Pastille blanche « ● Histoire » (point de la couleur de la matière), avec un complément
 * optionnel (« · 1916 »).
 */
@Composable
fun SubjectPill(subject: Subject, language: AppLanguage, modifier: Modifier = Modifier, extra: String? = null) {
    val context = LocalContext.current
    val name = StringStore.text(context, "subject.${subject.storageKey}.short", language)
    Row(
        modifier = modifier
            .height(30.dp)
            .clip(CircleShape)
            .background(DS.surface)
            .border(1.dp, DS.hairline, CircleShape)
            .padding(horizontal = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Box(modifier = Modifier.size(8.dp).clip(CircleShape).background(subject.color))
        Text(
            text = if (extra != null) "$name · $extra" else name,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 13.sp,
            color = DS.ink,
            maxLines = 1,
        )
    }
}

enum class TagPillStyle { ACCENT, WARM }

/** Étiquette pleine : « Nouveau » (bleu nuit) ou le nom d'un événement (or). */
@Composable
fun TagPill(text: String, modifier: Modifier = Modifier, style: TagPillStyle = TagPillStyle.ACCENT) {
    Box(
        modifier = modifier
            .height(30.dp)
            .clip(CircleShape)
            .background(if (style == TagPillStyle.ACCENT) DS.accent else DS.warm)
            .padding(horizontal = 10.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 13.sp,
            color = if (style == TagPillStyle.ACCENT) Color.White else DS.ink,
            maxLines = 1,
        )
    }
}

/** Icône + valeur, pour les lignes de statistiques des cartes (lectures, j'aime, durée). */
@Composable
fun StatChip(icon: ImageVector, text: String, modifier: Modifier = Modifier, tint: Color = DS.inkSecondary) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(5.dp),
    ) {
        Icon(imageVector = icon, contentDescription = null, tint = tint, modifier = Modifier.size(16.dp))
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 13.sp,
            color = tint,
            maxLines = 1,
        )
    }
}

/** Les trois compteurs du profil : icône sur fond teinté, valeur, libellé. */
@Composable
fun StatCounter(
    icon: ImageVector,
    iconTint: Color,
    iconBackground: Color,
    value: String,
    label: String,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Box(
            modifier = Modifier.size(36.dp).clip(CircleShape).background(iconBackground),
            contentAlignment = Alignment.Center,
        ) {
            Icon(imageVector = icon, contentDescription = null, tint = iconTint, modifier = Modifier.size(16.dp))
        }
        Column {
            Text(
                text = value,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 17.sp,
                color = DS.ink,
                maxLines = 1,
            )
            Text(
                text = label,
                fontFamily = PlusJakartaSans,
                fontSize = 12.sp,
                color = DS.inkSecondary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

// MARK: - Cours

/** Couverture d'un cours : l'image du catalogue, sinon la tuile colorée de [CourseImage]. */
@Composable
fun CourseCover(
    courseId: String,
    modifier: Modifier = Modifier,
    cornerRadius: Dp = 14.dp,
    letterSize: TextUnit = 22.sp,
) {
    CourseImage(
        courseId = courseId,
        modifier = modifier.clip(RoundedCornerShape(cornerRadius)),
        letterSize = letterSize,
    )
}

/**
 * Ligne compacte d'une liste de cours : couverture 64, titre sur deux lignes, une ligne de
 * détail, et un ornement à droite (coche « lu », chevron…).
 */
@Composable
fun CompactCourseRow(
    course: CourseSummary,
    meta: String,
    onTap: () -> Unit,
    modifier: Modifier = Modifier,
    secondMeta: String? = null,
    trailing: (@Composable () -> Unit)? = null,
) {
    val shape = RoundedCornerShape(18.dp)
    Row(
        modifier = modifier
            .fillMaxWidth()
            .softPress(onClick = onTap)
            .clip(shape)
            .background(DS.surface)
            .border(1.dp, DS.hairline, shape)
            .padding(10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        CourseCover(courseId = course.id, modifier = Modifier.size(64.dp), cornerRadius = 14.dp)
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(
                text = stripInlineMarkup(course.title),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Bold,
                fontSize = 15.sp,
                lineHeight = 20.sp,
                color = DS.ink,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                text = meta,
                fontFamily = PlusJakartaSans,
                fontSize = 12.sp,
                color = DS.inkSecondary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            if (secondMeta != null) {
                Text(
                    text = secondMeta,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 12.sp,
                    color = DS.inkSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        if (trailing != null) trailing()
    }
}

/** Disque vert avec une coche : « lu ». */
@Composable
fun ReadCheck(language: AppLanguage, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    Box(
        modifier = modifier.size(32.dp).clip(CircleShape).background(DS.successTint),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector = Icons.Filled.Check,
            contentDescription = StringStore.text(context, "common.read", language),
            tint = DS.success,
            modifier = Modifier.size(15.dp),
        )
    }
}

// MARK: - Segments et titres

/**
 * Sélecteur à segments sur fond bleu pâle, segment actif blanc avec ombre (« Pour toi /
 * Abonnements », « Populaires / Récents / Séries », « À lire / Lus / Aimés »).
 */
@Composable
fun SegmentedPills(
    items: List<String>,
    selection: Int,
    onSelect: (Int) -> Unit,
    modifier: Modifier = Modifier,
    /** Un point bleu sur un segment : quelque chose de nouveau derrière. */
    dotOn: Int? = null,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(DS.surfaceMuted)
            .padding(4.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        items.forEachIndexed { index, item ->
            val selected = selection == index
            Row(
                modifier = Modifier
                    .weight(1f)
                    .height(40.dp)
                    .then(
                        if (selected) {
                            Modifier.sophiaCard(shape = RoundedCornerShape(12.dp), elevation = 3.dp, border = false)
                        } else {
                            Modifier
                        },
                    )
                    .softPress(onClick = { onSelect(index) })
                    .padding(horizontal = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center,
            ) {
                Text(
                    text = item,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp,
                    color = if (selected) DS.ink else DS.inkSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.weight(1f, fill = false),
                )
                if (dotOn == index && !selected) {
                    Spacer(Modifier.width(6.dp))
                    Box(modifier = Modifier.size(7.dp).clip(CircleShape).background(DS.accentSoft))
                }
            }
        }
    }
}

/** Titre de section des nouveaux écrans (20 pt, gras), avec un complément grisé (« · 3 »). */
@Composable
fun NewGenSectionTitle(text: String, modifier: Modifier = Modifier, trailing: String? = null) {
    Row(modifier = modifier.fillMaxWidth(), verticalAlignment = Alignment.Bottom) {
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 20.sp,
            color = DS.ink,
            modifier = Modifier.weight(1f, fill = false),
        )
        if (trailing != null) {
            Spacer(Modifier.width(6.dp))
            Text(
                text = trailing,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 20.sp,
                color = DS.inkTertiary,
            )
        }
    }
}

/** Bouton rond blanc (retour, fermer, partager) des nouveaux écrans. */
@Composable
fun RoundIconButton(
    icon: ImageVector,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    size: Dp = 44.dp,
    tint: Color = DS.ink,
    contentDescription: String? = null,
) {
    Box(
        modifier = modifier
            .size(size)
            .softPress(onClick = onClick)
            .clip(CircleShape)
            .background(DS.surface)
            .border(1.dp, DS.hairline, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Icon(imageVector = icon, contentDescription = contentDescription, tint = tint, modifier = Modifier.size(18.dp))
    }
}

/** La première ligne d'une page secondaire : retour, titre optionnel, et une action à droite. */
@Composable
fun NewGenBackHeader(
    language: AppLanguage,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    title: String? = null,
    trailing: (@Composable () -> Unit)? = null,
) {
    val context = LocalContext.current
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        RoundIconButton(
            icon = Icons.AutoMirrored.Filled.ArrowBack,
            onClick = onBack,
            contentDescription = StringStore.text(context, "common.close", language),
        )
        if (title != null) {
            Text(
                text = title,
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 22.sp,
                color = DS.ink,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f),
            )
        } else {
            Spacer(Modifier.weight(1f))
        }
        if (trailing != null) trailing()
    }
}

/** Bouton plein bleu nuit à coins arrondis (14) des cartes de la maquette. */
@Composable
fun NewGenPrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    height: Dp = 48.dp,
    fontSize: TextUnit = 15.sp,
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(height)
            .softPress(onClick = onClick)
            .clip(RoundedCornerShape(if (height >= 52.dp) 16.dp else 14.dp))
            .background(DS.accent)
            .padding(horizontal = 16.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = fontSize,
            color = Color.White,
            textAlign = TextAlign.Center,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

/** Bouton blanc bordé à coins arrondis (14), compagnon de [NewGenPrimaryButton]. */
@Composable
fun NewGenSecondaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    height: Dp = 48.dp,
) {
    val shape = RoundedCornerShape(14.dp)
    Box(
        modifier = modifier
            .height(height)
            .softPress(onClick = onClick)
            .clip(shape)
            .background(DS.surface)
            .border(1.dp, DS.hairline, shape)
            .padding(horizontal = 18.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 15.sp,
            color = DS.ink,
            maxLines = 1,
        )
    }
}

/** Carte blanche « rien ici » avec un titre, un texte et un bouton (fil Abonnements vide…). */
@Composable
fun NewGenEmptyCard(
    title: String,
    body: String,
    cta: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(DS.cardShape)
            .background(DS.surface)
            .border(1.dp, DS.hairline, DS.cardShape)
            .padding(22.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(
            text = title,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 17.sp,
            color = DS.ink,
        )
        Text(
            text = body,
            fontFamily = PlusJakartaSans,
            fontSize = 15.sp,
            lineHeight = 21.sp,
            color = DS.inkSecondary,
        )
        NewGenPrimaryButton(text = cta, onClick = onClick)
    }
}

/** Bordure en pointillés autour d'un contenu (annonces « en écriture », « en écriture pour »). */
fun Modifier.dashedBorder(color: Color, cornerRadius: Dp = 16.dp): Modifier = this.drawBehind {
    val stroke = Stroke(width = 1.dp.toPx(), pathEffect = PathEffect.dashPathEffect(floatArrayOf(10f, 10f), 0f))
    drawRoundRect(
        color = color,
        cornerRadius = CornerRadius(cornerRadius.toPx(), cornerRadius.toPx()),
        style = stroke,
    )
}

/**
 * Les créateurs suivis en rangée horizontale (avatar 56 + prénom), puis un disque pointillé
 * « Découvrir ». Partagée par l'onglet Abonnements du fil et le profil.
 */
@Composable
fun FollowedCreatorsRow(
    authors: List<CourseAuthor>,
    language: AppLanguage,
    onOpen: (CourseAuthor) -> Unit,
    onDiscover: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    Row(
        modifier = modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState())
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
        verticalAlignment = Alignment.Top,
    ) {
        authors.forEach { author ->
            Column(
                modifier = Modifier.width(64.dp).softPress(onClick = { onOpen(author) }),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                AuthorAvatar(author = author, size = 56.dp)
                Text(
                    text = author.name.split(' ').firstOrNull { it.isNotBlank() } ?: author.name,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 12.sp,
                    color = DS.ink,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        Column(
            modifier = Modifier.width(64.dp).softPress(onClick = onDiscover),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .drawBehind {
                        drawCircle(
                            color = DS.palette.inkTertiary,
                            style = Stroke(width = 1.5.dp.toPx(), pathEffect = PathEffect.dashPathEffect(floatArrayOf(10f, 10f), 0f)),
                        )
                    },
                contentAlignment = Alignment.Center,
            ) {
                Icon(imageVector = Icons.Filled.Add, contentDescription = null, tint = DS.inkSecondary, modifier = Modifier.size(20.dp))
            }
            Text(
                text = StringStore.text(context, "training.discover", language),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 12.sp,
                color = DS.inkSecondary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

/**
 * Le symbole d'un événement : un nom SF Symbols de la liste standard (docs/evenements.md), rendu
 * par l'icône Material correspondante. La moustache est dessinée à la main faute d'icône ; un
 * symbole inconnu retombe sur les étincelles.
 */
@Composable
fun CampaignSymbol(symbol: String?, size: Dp, tint: Color, modifier: Modifier = Modifier) {
    if (symbol == "mustache.fill") {
        MustacheGlyph(size = size, color = tint, modifier = modifier)
        return
    }
    val icon = when (symbol) {
        "heart.fill" -> Icons.Filled.Favorite
        "star.fill" -> Icons.Filled.Star
        "flame.fill" -> Icons.Filled.LocalFireDepartment
        "leaf.fill" -> Icons.Filled.Eco
        "globe.europe.africa.fill" -> Icons.Filled.Public
        "book.fill" -> Icons.AutoMirrored.Filled.MenuBook
        "flag.fill" -> Icons.Filled.Flag
        "drop.fill" -> Icons.Filled.WaterDrop
        "sun.max.fill" -> Icons.Filled.WbSunny
        "moon.fill" -> Icons.Filled.DarkMode
        "graduationcap.fill" -> Icons.Filled.School
        "brain.head.profile" -> Icons.Filled.Psychology
        "figure.run" -> Icons.AutoMirrored.Filled.DirectionsRun
        "music.note" -> Icons.Filled.MusicNote
        "paintpalette.fill" -> Icons.Filled.Palette
        "building.columns.fill" -> Icons.Filled.AccountBalance
        "snowflake" -> Icons.Filled.AcUnit
        "gift.fill" -> Icons.Filled.CardGiftcard
        "trophy.fill" -> Icons.Filled.EmojiEvents
        "atom" -> Icons.Filled.Science
        else -> Icons.Filled.AutoAwesome
    }
    Icon(imageVector = icon, contentDescription = null, tint = tint, modifier = modifier.size(size))
}

/** Une moustache en deux boucles symétriques, pleine. */
@Composable
private fun MustacheGlyph(size: Dp, color: Color, modifier: Modifier = Modifier) {
    Canvas(modifier = modifier.size(width = size, height = size * 0.5f)) {
        val w = this.size.width
        val h = this.size.height
        val path = Path()
        // Moitié gauche : du centre vers la pointe, puis retour par le dessous.
        path.moveTo(w * 0.5f, h * 0.45f)
        path.cubicTo(w * 0.42f, h * 0.05f, w * 0.22f, h * 0.0f, w * 0.12f, h * 0.35f)
        path.cubicTo(w * 0.04f, h * 0.62f, w * 0.0f, h * 0.95f, w * 0.1f, h * 0.9f)
        path.cubicTo(w * 0.2f, h * 0.85f, w * 0.3f, h * 0.55f, w * 0.5f, h * 0.9f)
        // Moitié droite, en miroir.
        path.cubicTo(w * 0.7f, h * 0.55f, w * 0.8f, h * 0.85f, w * 0.9f, h * 0.9f)
        path.cubicTo(w * 1.0f, h * 0.95f, w * 0.96f, h * 0.62f, w * 0.88f, h * 0.35f)
        path.cubicTo(w * 0.78f, h * 0.0f, w * 0.58f, h * 0.05f, w * 0.5f, h * 0.45f)
        path.close()
        drawPath(path = path, color = color)
        drawCircle(color = color, radius = h * 0.08f, center = Offset(w * 0.5f, h * 0.62f))
    }
}

/**
 * Barre de progression du lecteur : une capsule par section, remplies jusqu'à la section
 * courante (maquette). Au-delà de douze sections les capsules deviendraient des pointillés :
 * le lecteur repasse alors à la barre continue.
 */
@Composable
fun SegmentedProgressBar(
    count: Int,
    current: Int,
    modifier: Modifier = Modifier,
    height: Dp = 6.dp,
    activeColor: Color = DS.accentSoft,
    trackColor: Color = DS.hairline,
) {
    Row(
        modifier = modifier.fillMaxWidth().height(height),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        repeat(maxOf(1, count)) { index ->
            Box(
                modifier = Modifier
                    .weight(1f)
                    .height(height)
                    .clip(CircleShape)
                    .background(if (index <= current) activeColor else trackColor),
            )
        }
    }
}

// MARK: - Formats

object NewGenFormat {
    /** « 7 min » dans la langue de l'app. */
    fun minutes(context: Context, minutes: Int, language: AppLanguage): String =
        StringStore.text(context, "common.minutesShort", language, minutes)

    /** « section 3 sur 5 ». */
    fun section(context: Context, index: Int, count: Int, language: AppLanguage): String =
        StringStore.text(context, "common.sectionOf", language, index, count)

    /** Jour et mois courts dans la langue de l'app : « 30 nov. ». */
    fun shortDay(date: LocalDate, language: AppLanguage): String = localized(date, "dMMM", "d MMM", language)

    /** Jour et mois longs : « 30 novembre ». */
    fun longDay(date: LocalDate, language: AppLanguage): String = localized(date, "dMMMM", "d MMMM", language)

    /** Mois et année : « mars 2026 ». */
    fun monthYear(date: LocalDate, language: AppLanguage): String = localized(date, "yMMMM", "MMMM yyyy", language)

    /** « 6 h » ou « 45 min » de lecture cumulée. */
    fun readingTime(context: Context, seconds: Int, language: AppLanguage): String {
        val hours = seconds / 3_600
        if (hours >= 1) return StringStore.text(context, "common.hoursShort", language, hours)
        return minutes(context, maxOf(0, seconds / 60), language)
    }

    /**
     * Le format de la langue pour un squelette ICU (« dMMM » → « 30 nov. » en français,
     * « Nov 30 » en anglais), comme `setLocalizedDateFormatFromTemplate` sur iOS.
     */
    private fun localized(date: LocalDate, skeleton: String, fallbackPattern: String, language: AppLanguage): String {
        val locale = language.locale
        return try {
            val pattern = android.text.format.DateFormat.getBestDateTimePattern(locale, skeleton)
            val legacy = Date.from(date.atStartOfDay(ZoneId.systemDefault()).toInstant())
            SimpleDateFormat(pattern, locale).format(legacy)
        } catch (_: Exception) {
            try {
                DateTimeFormatter.ofPattern(fallbackPattern, locale).format(date)
            } catch (_: Exception) {
                date.toString()
            }
        }
    }
}
