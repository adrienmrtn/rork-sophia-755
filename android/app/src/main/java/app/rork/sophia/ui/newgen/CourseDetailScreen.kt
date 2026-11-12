package app.rork.sophia.ui.newgen

import android.content.Intent
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
import androidx.compose.material.icons.outlined.Visibility
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.CourseAuthor
import app.rork.sophia.data.LocalCounters
import app.rork.sophia.data.ProgressManager
import app.rork.sophia.data.StringStore
import app.rork.sophia.data.analytics.Analytics
import app.rork.sophia.data.catalog.CatalogStore
import app.rork.sophia.data.compactCount
import app.rork.sophia.data.rememberCourseInfo
import app.rork.sophia.data.rememberCourseSummaries
import app.rork.sophia.data.stripInlineMarkup
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.CourseSummary
import app.rork.sophia.domain.realReadsCount
import app.rork.sophia.domain.UserProgress
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.components.DSEyebrow
import app.rork.sophia.ui.components.dsStagger
import app.rork.sophia.ui.components.pressable
import app.rork.sophia.ui.components.rememberHaptics
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.uppercaseInApp
import app.rork.sophia.ui.course.TranslatedFromLine
import app.rork.sophia.domain.CourseOrigins

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
    val haptics = rememberHaptics()
    var likeBurst by remember(course.id) { mutableIntStateOf(0) }
    val identity = remember(course.id) { CreatorIdentity.forCourse(context.applicationContext, course.id) }
    val info by rememberCourseInfo(course.toStub(), language)
    val summaries = rememberCourseSummaries(language)

    // L'accroche et l'introduction viennent du paquet du cours : s'il n'est pas encore sur le
    // téléphone, on le télécharge ; `rememberCourseInfo` se relit quand il arrive.
    LaunchedEffect(course.id, language) {
        CatalogStore.ensureContent(course.id, language)
    }

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
            // Borné par le nombre de sections : un cours raccourci en ligne ne dit pas « 7 sur 5 ».
            val index = (courseProgress.lastLessonIndex + 1).coerceIn(1, sectionCount)
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
            modifier = Modifier.padding(start = 24.dp, end = 24.dp, top = 20.dp, bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Row(
                modifier = Modifier.dsStagger(0),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
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
                fontWeight = FontWeight.SemiBold,
                fontSize = 26.sp,
                lineHeight = 33.sp,
                color = DS.ink,
                modifier = Modifier.dsStagger(1),
            )
            Text(
                text = hook,
                fontFamily = PlusJakartaSans,
                fontSize = 16.sp,
                lineHeight = 23.sp,
                color = DS.inkSecondary,
                modifier = Modifier.dsStagger(2),
            )

            // Carte créateur : ligne d'identité et « Suivre » compact.
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .dsStagger(3)
                    .homeCard()
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

            // « Voir l'original » se trouve dans le cours ouvert (réservé à qui peut le lire en entier).
            CourseOrigins.translatedFromCode(course.id, info?.originalLanguage, language)?.let { code ->
                TranslatedFromLine(code = code, language = language)
            }

            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                // Sur-titre en petites capitales espacées bleues.
                DSEyebrow(text = StringStore.text(context, "course.detail.introduction", language))
                Text(
                    text = introduction,
                    fontFamily = PlusJakartaSans,
                    fontSize = 16.sp,
                    lineHeight = 25.sp,
                    color = DS.ink,
                )
            }

            // Lectures · j'aime · partager.
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(22.dp),
            ) {
                // Les vraies ouvertures (serveur) ; rien tant que le chiffre n'est pas arrivé.
                course.realReadsCount?.let { reads ->
                    StatChip(
                        icon = Icons.Outlined.Visibility,
                        text = reads.compactCount(language) + " " + StringStore.text(context, "creator.stat.reads", language),
                    )
                }
                // Le cœur rebondit et lâche son éclat quand il s'allume.
                val likeLabel = StringStore.text(context, if (liked) "common.unlike" else "common.like", language)
                Row(
                    modifier = Modifier
                        .pressable(
                            onClick = {
                                val wasLiked = progressManager.isLiked(course.id)
                                if (wasLiked) haptics.tap() else haptics.confirm()
                                progressManager.toggleLike(course.id)
                                if (!wasLiked) likeBurst++
                                Analytics.log(if (wasLiked) "unlike" else "like", courseId = course.id, screen = "course_detail")
                            },
                            scaleDown = 0.9f,
                            haptic = false,
                        )
                        .semantics { contentDescription = likeLabel }
                        .padding(vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(5.dp),
                ) {
                    LikeHeartIcon(liked = liked, burst = likeBurst, size = 16.dp)
                    Text(
                        text = LocalCounters.likesCount(course.id, liked).compactCount(language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 13.sp,
                        color = if (liked) LikedTint else DS.inkSecondary,
                        maxLines = 1,
                    )
                }
                Spacer(Modifier.weight(1f))
                Icon(
                    imageVector = Icons.Filled.Share,
                    contentDescription = null,
                    tint = DS.inkSecondary,
                    modifier = Modifier
                        .size(36.dp)
                        .pressable(onClick = {
                            Analytics.log("share", courseId = course.id, props = mapOf("channel" to "sheet", "target" to "course"))
                            // La phrase habituelle, suivie du lien du cours sur le site.
                            val message = app.rork.sophia.domain.SophiaLinks.shareText(
                                StringStore.text(context, "share.course.message", language, stripInlineMarkup(course.title)),
                                app.rork.sophia.domain.SophiaLinks.courseWebUrl(course.id),
                            )
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
                        .homeCard(shape = RoundedCornerShape(DS.Radius.small), fill = DS.successTint, border = DS.success)
                        .padding(horizontal = 16.dp, vertical = 14.dp),
                )
            }

            HomeCtaButton(text = ctaTitle, onClick = onStart)

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
                        meta = LocalCounters.statsLine(context, other.id, otherLiked, language)
                            ?: StringStore.text(context, "subject.${other.subjectEnum.storageKey}.short", language),
                        onTap = { onOpenCourse(other) },
                        trailing = if (otherCompleted) ({ ReadCheck(language = language) }) else null,
                    )
                }
            }
        }
    }
}

