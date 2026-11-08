package app.rork.sophia.ui.newgen

import android.content.Intent
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.Public
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Visibility
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.CourseAuthor
import app.rork.sophia.data.LocalCounters
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.analytics.Analytics
import app.rork.sophia.data.compactCount
import app.rork.sophia.data.rememberCourseInfo
import app.rork.sophia.data.rememberCourseSummaries
import app.rork.sophia.data.stripInlineMarkup
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.uppercaseInApp

/**
 * La fiche d'un cours (écran « Cours » de la maquette) : couverture, matière et durée, titre,
 * accroche, carte créateur avec « Suivre », introduction, compteurs, puis le bouton qui ouvre
 * le lecteur (« Lire le cours », « Reprendre · section n sur N », « Relire »), et les autres
 * cours du même créateur.
 */
@Composable
fun CourseDetailScreen(
    course: CourseSummary,
    language: AppLanguage,
    progress: UserProgress,
    progressManager: ProgressManager,
    onBack: () -> Unit,
    onStart: () -> Unit,
    onOpenCreator: (CourseAuthor) -> Unit,
    onOpenCourse: (CourseSummary) -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val identity = remember(course.id) { CreatorIdentity.forCourse(context.applicationContext, course.id) }
    val info by rememberCourseInfo(course.toStub(), language)
    val summaries = rememberCourseSummaries(language)
    var showOriginal by remember { mutableStateOf(false) }

    val saved = course.id in progress.favoriteCourseIds
    val liked = course.id in progress.likedCourseIds
    val courseProgress = progress.courseProgress[course.id]
    val completed = courseProgress?.isCompleted == true
    val sectionCount = maxOf(1, info?.sectionCount ?: 1)
    val hook = info?.hook ?: stripInlineMarkup(course.description)
    val introduction = info?.introduction ?: stripInlineMarkup(course.description)
    val otherCourses = remember(identity, summaries, course.id) {
        val author = identity.author ?: return@remember emptyList<CourseSummary>()
        author.courseIds.filter { it != course.id }.mapNotNull { id -> summaries.firstOrNull { it.id == id } }
    }

    val ctaTitle = when {
        completed -> StringStore.text(context, "course.detail.reread", language)
        courseProgress != null -> {
            val index = minOf(sectionCount, courseProgress.lastLessonIndex + 1)
            StringStore.text(context, "common.resume", language) + " · " +
                NewGenFormat.section(context, index, sectionCount, language)
        }
        else -> StringStore.text(context, "course.detail.read", language)
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DS.canvas)
            .verticalScroll(rememberScrollState()),
    ) {
        // Couverture pleine largeur, boutons retour et enregistrer posés dessus.
        Box(modifier = Modifier.fillMaxWidth().height(290.dp)) {
            CourseImage(courseId = course.id, modifier = Modifier.fillMaxSize())
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 16.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                RoundIconButton(
                    icon = Icons.AutoMirrored.Filled.ArrowBack,
                    onClick = onBack,
                    contentDescription = StringStore.text(context, "common.close", language),
                )
                Spacer(Modifier.weight(1f))
                RoundIconButton(
                    icon = if (saved) Icons.Filled.Bookmark else Icons.Filled.BookmarkBorder,
                    tint = if (saved) DS.accent else DS.ink,
                    contentDescription = StringStore.text(context, if (saved) "common.unsave" else "common.save", language),
                    onClick = {
                        val wasSaved = progressManager.isFavorite(course.id)
                        progressManager.toggleFavorite(course.id)
                        Analytics.log(if (wasSaved) "unsave" else "save", courseId = course.id, screen = "course_detail")
                    },
                )
            }
        }

        Column(
            modifier = Modifier.padding(start = 20.dp, end = 20.dp, top = 20.dp, bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                SubjectPill(subject = course.subjectEnum, language = language)
                info?.let { details ->
                    Text(
                        text = StringStore.text(context, "course.detail.meta", language, details.sectionCount, details.minutes),
                        fontFamily = PlusJakartaSans,
                        fontSize = 15.sp,
                        color = DS.inkSecondary,
                        maxLines = 1,
                    )
                }
            }
            Text(
                text = stripInlineMarkup(course.title),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 28.sp,
                lineHeight = 34.sp,
                color = DS.ink,
            )
            Text(
                text = hook,
                fontFamily = PlusJakartaSans,
                fontSize = 17.sp,
                lineHeight = 24.sp,
                color = DS.inkSecondary,
            )

            // Carte créateur : ligne d'identité et « Suivre » compact.
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(18.dp))
                    .background(DS.surface)
                    .border(1.dp, DS.hairline, RoundedCornerShape(18.dp))
                    .padding(14.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                CreatorLine(
                    identity = identity,
                    language = language,
                    modifier = Modifier.weight(1f),
                    avatarSize = 44.dp,
                    onTap = identity.author?.let { author -> { onOpenCreator(author) } },
                )
                identity.author?.let { author ->
                    val following = author.slug in progress.followedCreatorSlugs
                    FollowButton(
                        isFollowing = following,
                        language = language,
                        compact = true,
                        onClick = {
                            val wasFollowing = progressManager.isFollowing(author.slug)
                            progressManager.toggleFollow(author.slug)
                            Analytics.log(
                                if (wasFollowing) "unfollow" else "follow",
                                courseId = course.id,
                                screen = "course_detail",
                                props = mapOf("creator" to author.slug),
                            )
                        },
                    )
                }
            }

            info?.originalLanguage?.takeIf { it != language.code }?.let { code ->
                TranslationPanel(
                    code = code,
                    language = language,
                    showOriginal = showOriginal,
                    onToggle = { showOriginal = !showOriginal },
                )
            }

            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(
                    text = StringStore.text(context, "course.detail.introduction", language).uppercaseInApp(),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.Bold,
                    fontSize = 12.sp,
                    letterSpacing = 0.6.sp,
                    color = DS.inkSecondary,
                )
                Text(
                    text = introduction,
                    fontFamily = PlusJakartaSans,
                    fontSize = 17.sp,
                    lineHeight = 27.sp,
                    color = DS.ink,
                )
            }

            // Lectures · j'aime · partager.
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(22.dp),
            ) {
                StatChip(
                    icon = Icons.Filled.Visibility,
                    text = course.readsCount.compactCount(language) + " " + StringStore.text(context, "creator.stat.reads", language),
                )
                StatChip(
                    icon = if (liked) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder,
                    text = LocalCounters.likesCount(course.id, liked).compactCount(language),
                    tint = if (liked) LikedTint else DS.inkSecondary,
                    modifier = Modifier.softPress(onClick = {
                        val wasLiked = progressManager.isLiked(course.id)
                        progressManager.toggleLike(course.id)
                        Analytics.log(if (wasLiked) "unlike" else "like", courseId = course.id, screen = "course_detail")
                    }),
                )
                Spacer(Modifier.weight(1f))
                Icon(
                    imageVector = Icons.Filled.Share,
                    contentDescription = null,
                    tint = DS.inkSecondary,
                    modifier = Modifier
                        .size(36.dp)
                        .softPress(onClick = {
                            Analytics.log("share", courseId = course.id, props = mapOf("channel" to "sheet", "target" to "course"))
                            val message = StringStore.text(context, "share.course.message", language, stripInlineMarkup(course.title))
                            val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, message)
                            runCatching { context.startActivity(Intent.createChooser(send, null)) }
                        })
                        .padding(8.dp),
                )
            }

            if (completed) {
                Text(
                    text = StringStore.text(context, "course.detail.done", language),
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 15.sp,
                    color = DS.success,
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .background(DS.successTint)
                        .padding(horizontal = 16.dp, vertical = 14.dp),
                )
            }

            NewGenPrimaryButton(text = ctaTitle, onClick = onStart, height = 54.dp, fontSize = 17.sp)

            if (otherCourses.isNotEmpty()) {
                NewGenSectionTitle(
                    text = StringStore.text(context, "course.detail.sameCreator", language),
                    modifier = Modifier.padding(top = 8.dp),
                )
                otherCourses.forEach { other ->
                    val otherLiked = other.id in progress.likedCourseIds
                    val otherCompleted = progress.courseProgress[other.id]?.isCompleted == true
                    CompactCourseRow(
                        course = other,
                        meta = other.readsCount.compactCount(language) + " " +
                            StringStore.text(context, "creator.stat.reads", language) + " · " +
                            LocalCounters.likesCount(other.id, otherLiked).compactCount(language) + " " +
                            StringStore.text(context, "common.likes", language),
                        onTap = { onOpenCourse(other) },
                        trailing = if (otherCompleted) ({ ReadCheck(language = language) }) else null,
                    )
                }
            }
        }
    }
}

/**
 * « Traduit · original en anglais » avec « Voir l'original ». Le texte original n'est pas
 * encore livré avec les cours (prompt 3) : le bouton ne fait que basculer son libellé.
 */
@Composable
private fun TranslationPanel(code: String, language: AppLanguage, showOriginal: Boolean, onToggle: () -> Unit) {
    val context = LocalContext.current
    val name = AppLanguage.entries.firstOrNull { it.code.equals(code, ignoreCase = true) }?.displayName
        ?: code.uppercase()
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(DS.accentTint)
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Icon(imageVector = Icons.Filled.Public, contentDescription = null, tint = DS.accent, modifier = Modifier.size(16.dp))
        Text(
            text = StringStore.text(context, "course.translatedFrom", language, name),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 13.sp,
            color = DS.ink,
            modifier = Modifier.weight(1f),
        )
        Text(
            text = StringStore.text(context, if (showOriginal) "course.seeTranslation" else "course.seeOriginal", language),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.Bold,
            fontSize = 13.sp,
            color = DS.accentSoft,
            modifier = Modifier.softPress(onClick = onToggle),
        )
    }
}
