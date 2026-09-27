package app.rork.sophia.ui.course

import androidx.compose.animation.animateContentSize
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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.automirrored.filled.OpenInNew
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.CourseAuthor
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.components.SophiaSecondaryButton
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import app.rork.sophia.ui.theme.uppercaseInApp
import coil.compose.AsyncImage

// Author-facing pieces of the reader, mirroring iOS `CourseAuthorViews.swift`: the byline
// under the first page's title, the "written by" card and the sources list at the end of
// the last page. Nothing is drawn for house content without an author.

/** A bibliographic reference under a professor-authored course. */
data class ReaderSource(val text: String, val url: String?)

/** Portrait when the author has one, initials on a tinted disc otherwise. */
@Composable
fun AuthorAvatar(author: CourseAuthor, size: Dp, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(DS.accentTint)
            .border(1.dp, DS.hairline, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = author.initials,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = (size.value * 0.38f).sp,
            color = DS.accentSoft,
        )
        author.photoModel?.let { model ->
            AsyncImage(
                model = model,
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop,
            )
        }
    }
}

/** "Par Dusan Nikolic · pedigree" under the intro title; a tap opens the author page. */
@Composable
fun AuthorByline(
    author: CourseAuthor,
    language: AppLanguage,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    Row(
        modifier = modifier
            .fillMaxWidth()
            .softPress(onClick = onClick),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        AuthorAvatar(author = author, size = 40.dp)
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = StringStore.text(context, "course.author.by", language, author.name),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 15.sp,
                color = DS.ink,
            )
            author.title(language)?.let { title ->
                Text(
                    text = title,
                    fontFamily = PlusJakartaSans,
                    fontSize = 12.sp,
                    color = DS.inkSecondary,
                    maxLines = 2,
                )
            }
        }
        Icon(
            imageVector = Icons.AutoMirrored.Filled.ArrowForward,
            contentDescription = null,
            tint = DS.inkTertiary,
            modifier = Modifier.size(16.dp),
        )
    }
}

/** The signature at the end of the course, with the door to the author's other courses. */
@Composable
fun AuthorCard(
    author: CourseAuthor,
    language: AppLanguage,
    onOpenAuthor: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    Column(
        modifier = modifier
            .fillMaxWidth()
            .sophiaCard()
            .padding(DS.Space.l),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Icon(
                imageVector = Icons.Filled.Person,
                contentDescription = null,
                tint = DS.accentSoft,
                modifier = Modifier.size(14.dp),
            )
            Text(
                text = StringStore.text(context, "course.author.writtenBy", language).uppercaseInApp(),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.SemiBold,
                fontSize = 11.sp,
                letterSpacing = 1.2.sp,
                color = DS.accentSoft,
            )
        }
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            AuthorAvatar(author = author, size = 56.dp)
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = author.name,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 19.sp,
                    color = DS.ink,
                )
                author.title(language)?.let { title ->
                    Spacer(Modifier.height(3.dp))
                    Text(text = title, style = SophiaTypography.bodyMedium, color = DS.inkSecondary)
                }
            }
        }
        author.bio(language)?.let { bio ->
            Text(
                text = bio,
                fontFamily = PlusJakartaSans,
                fontSize = 13.sp,
                lineHeight = 19.sp,
                color = DS.inkSecondary,
            )
        }
        SophiaSecondaryButton(
            text = StringStore.text(context, "author.otherCourses", language),
            onClick = onOpenAuthor,
        )
    }
}

/** References behind the course, folded until tapped, each with a link when it has one. */
@Composable
fun SourcesCard(
    sources: List<ReaderSource>,
    language: AppLanguage,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val uriHandler = LocalUriHandler.current
    var revealed by remember { mutableStateOf(false) }
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(DS.cardShape)
            .background(DS.surfaceMuted)
            .border(1.dp, DS.hairline, DS.cardShape)
            .padding(DS.Space.l)
            .animateContentSize(),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .softPress(onClick = { revealed = !revealed }),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Box(
                modifier = Modifier.size(36.dp).clip(CircleShape).background(DS.accentTint),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.MenuBook,
                    contentDescription = null,
                    tint = DS.accentSoft,
                    modifier = Modifier.size(16.dp),
                )
            }
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "${StringStore.text(context, "course.sources", language)} · ${sources.size}",
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 15.sp,
                    color = DS.ink,
                )
                if (!revealed) {
                    Text(
                        text = StringStore.text(context, "course.sources.hint", language),
                        fontFamily = PlusJakartaSans,
                        fontSize = 11.sp,
                        color = DS.inkTertiary,
                    )
                }
            }
            Icon(
                imageVector = Icons.Filled.ExpandMore,
                contentDescription = null,
                tint = DS.inkTertiary,
                modifier = Modifier.size(18.dp).rotate(if (revealed) 180f else 0f),
            )
        }
        if (revealed) {
            Spacer(Modifier.height(14.dp))
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                sources.forEachIndexed { index, source ->
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        Text(
                            text = "${index + 1}",
                            fontFamily = PlusJakartaSans,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 11.sp,
                            color = DS.accentSoft,
                            modifier = Modifier.width(18.dp),
                        )
                        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text(
                                text = source.text,
                                fontFamily = PlusJakartaSans,
                                fontSize = 13.sp,
                                lineHeight = 18.sp,
                                color = DS.inkSecondary,
                            )
                            source.url?.let { url ->
                                Row(
                                    modifier = Modifier.softPress(onClick = { runCatching { uriHandler.openUri(url) } }),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                                ) {
                                    Icon(
                                        imageVector = Icons.AutoMirrored.Filled.OpenInNew,
                                        contentDescription = null,
                                        tint = DS.accentSoft,
                                        modifier = Modifier.size(12.dp),
                                    )
                                    Text(
                                        text = StringStore.text(context, "course.sources.open", language),
                                        fontFamily = PlusJakartaSans,
                                        fontWeight = FontWeight.SemiBold,
                                        fontSize = 12.sp,
                                        color = DS.accentSoft,
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
