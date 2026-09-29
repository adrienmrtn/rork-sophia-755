package app.rork.sophia.ui.audio

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.audio.CourseAudioDownloads
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.components.ConfirmDialog
import app.rork.sophia.ui.components.SectionLabel
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.components.softPress
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography

/** Settings › Audio downloads: what is on the phone, how much room it takes, and a way back. */
@Composable
fun AudioDownloadsScreen(language: AppLanguage, onBack: () -> Unit) {
    val context = LocalContext.current
    val downloaded by CourseAudioDownloads.downloaded.collectAsState()
    val items = remember(downloaded) { CourseAudioDownloads.items() }
    var confirmDeleteAll by remember { mutableStateOf(false) }
    fun t(key: String) = StringStore.text(context, key, language)

    SubPage(title = t("audio.downloads.title"), language = language, onBack = onBack) {
        LazyColumn(modifier = Modifier.fillMaxSize(), contentPadding = PaddingValues(DS.Space.l)) {
            item(key = "used") {
                Row(
                    modifier = Modifier.fillMaxWidth().sophiaCard(shape = DS.controlShape, elevation = 2.dp).padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(t("audio.downloads.used"), style = SophiaTypography.bodyLarge, modifier = Modifier.weight(1f))
                    Text(
                        AudioFormat.bytes(context, items.sumOf { it.bytes }),
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                        color = DS.inkSecondary,
                    )
                }
                Text(
                    t("audio.downloads.footer"),
                    style = SophiaTypography.labelMedium,
                    modifier = Modifier.padding(top = 8.dp, start = 4.dp),
                )
                Spacer(Modifier.height(20.dp))
            }
            if (items.isEmpty()) {
                item(key = "empty") {
                    Text(t("audio.downloads.empty"), style = SophiaTypography.bodyMedium)
                }
            } else {
                items(items, key = { it.key.path }) { item ->
                    val summary = rememberCourseSummary(item.key.courseId, language)
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        AudioCover(item.key.courseId, modifier = Modifier.size(44.dp), corner = 8.dp)
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                summary?.title ?: item.key.courseId,
                                fontFamily = PlusJakartaSans,
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 14.sp,
                                color = DS.ink,
                                maxLines = 2,
                                overflow = TextOverflow.Ellipsis,
                            )
                            Text(
                                "${item.key.language.label()} · ${AudioFormat.bytes(context, item.bytes)}",
                                style = SophiaTypography.labelMedium,
                            )
                        }
                        Box(
                            modifier = Modifier
                                .size(38.dp)
                                .clip(CircleShape)
                                .softPress(onClick = {
                                    CourseAudioDownloads.delete(item.key.courseId, item.key.language)
                                }),
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(Icons.Filled.Delete, contentDescription = t("audio.deleteDownload"), tint = DS.danger)
                        }
                    }
                    HorizontalDivider(color = DS.hairline)
                }
                item(key = "delete-all") {
                    Spacer(Modifier.height(20.dp))
                    SectionLabel(
                        t("audio.downloads.deleteAll"),
                        color = DS.danger,
                        modifier = Modifier.softPress(onClick = { confirmDeleteAll = true }).padding(vertical = 8.dp),
                    )
                }
            }
        }
    }

    if (confirmDeleteAll) {
        ConfirmDialog(
            title = t("audio.downloads.deleteAll.confirm"),
            message = "",
            confirm = t("audio.downloads.deleteAll"),
            cancel = t("audio.cancel"),
            onConfirm = {
                confirmDeleteAll = false
                CourseAudioDownloads.deleteAll()
            },
            onDismiss = { confirmDeleteAll = false },
        )
    }
}
