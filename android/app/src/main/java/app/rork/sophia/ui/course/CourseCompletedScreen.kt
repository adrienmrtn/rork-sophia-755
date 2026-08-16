package app.rork.sophia.ui.course

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
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
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.Course
import app.rork.sophia.ui.components.CourseImage
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography

/**
 * End-of-course celebration, mirroring the iOS `CourseCompletedView`: cover, title,
 * the XP just earned, then close / quiz.
 */
@Composable
fun CourseCompletedScreen(
    course: Course,
    language: AppLanguage,
    earnedXP: Int,
    level: Int,
    xpIntoLevel: Int,
    xpForLevel: Int,
    showQuizCta: Boolean,
    quizLocked: Boolean,
    onClose: () -> Unit,
    onQuiz: () -> Unit,
) {
    val context = LocalContext.current
    var appeared by remember(course.id) { mutableStateOf(false) }
    val scale by animateFloatAsState(
        targetValue = if (appeared) 1f else 0.7f,
        animationSpec = spring(dampingRatio = 0.6f),
        label = "coverScale",
    )
    LaunchedEffect(course.id) { appeared = true }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas)
            .padding(DS.Space.l),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.weight(1f))
        Box(
            modifier = Modifier
                .size(168.dp)
                .scale(scale)
                .clip(DS.cardShape),
        ) {
            CourseImage(
                courseId = course.id,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop,
                maxEdgePx = 480,
            )
        }
        Spacer(Modifier.height(22.dp))
        Text(
            text = StringStore.text(context, "course.completed", language),
            style = SophiaTypography.displayLarge,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(20.dp))
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(DS.cardShape)
                .background(DS.surface)
                .padding(DS.Space.m),
        ) {
            Text(text = course.title, style = SophiaTypography.titleMedium, maxLines = 2)
            Spacer(Modifier.height(10.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = course.subjectEnum.name.lowercase().replaceFirstChar { it.titlecase() },
                    style = SophiaTypography.labelMedium,
                    modifier = Modifier.weight(1f),
                )
                Text(
                    text = "+$earnedXP XP",
                    style = SophiaTypography.titleMedium,
                    color = DS.accentSoft,
                )
            }
            Spacer(Modifier.height(10.dp))
            LinearProgressIndicator(
                progress = {
                    if (xpForLevel <= 0) 1f else (xpIntoLevel.toFloat() / xpForLevel).coerceIn(0f, 1f)
                },
                modifier = Modifier.fillMaxWidth().clip(DS.controlShape),
                color = DS.accent,
                trackColor = DS.hairline,
                strokeCap = StrokeCap.Round,
            )
            Spacer(Modifier.height(6.dp))
            Text(
                text = StringStore.text(context, "common.levelShort", language, level) +
                    " · $xpIntoLevel / $xpForLevel XP",
                style = SophiaTypography.labelMedium,
            )
        }
        Spacer(Modifier.weight(1f))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(
                onClick = onClose,
                modifier = Modifier.size(56.dp).clip(CircleShape).background(DS.surface),
            ) {
                Icon(Icons.Filled.Close, contentDescription = null, tint = DS.inkSecondary)
            }
            if (showQuizCta) {
                Button(
                    onClick = onQuiz,
                    modifier = Modifier.weight(1f).height(56.dp),
                    shape = DS.controlShape,
                    colors = ButtonDefaults.buttonColors(containerColor = DS.accent, contentColor = Color.White),
                ) {
                    Text(
                        text = if (quizLocked) {
                            "🔒 " + StringStore.text(context, "common.miniQuiz", language)
                        } else {
                            StringStore.text(context, "common.miniQuiz", language)
                        },
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 16.sp,
                    )
                }
            } else {
                Button(
                    onClick = onClose,
                    modifier = Modifier.weight(1f).height(56.dp),
                    shape = DS.controlShape,
                    colors = ButtonDefaults.buttonColors(containerColor = DS.accent, contentColor = Color.White),
                ) {
                    Text(
                        text = StringStore.text(context, "course.finish", language),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 16.sp,
                    )
                }
            }
        }
    }
}
