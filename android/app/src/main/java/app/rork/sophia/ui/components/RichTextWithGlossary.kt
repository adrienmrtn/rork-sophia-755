package app.rork.sophia.ui.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.ClickableText
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import app.rork.sophia.data.GlossaryEntry
import app.rork.sophia.data.GlossaryStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.SophiaTypography

private data class TextSeg(val text: String, val term: String? = null, val bold: Boolean = false)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RichTextWithGlossary(
    raw: String,
    language: AppLanguage,
    courseId: String,
    courseTitle: String,
    color: Color = DS.ink,
) {
    val context = LocalContext.current
    val segments = remember(raw, language, courseId) { parseSegments(raw) }
    var openEntry by remember { mutableStateOf<GlossaryEntry?>(null) }

    val annotated = remember(segments, language, courseId, courseTitle) {
        buildAnnotatedString {
            segments.forEach { seg ->
                if (seg.term != null) {
                    val entry = GlossaryStore.entry(context, language, courseId, courseTitle, seg.term)
                    if (entry != null) {
                        pushStringAnnotation(tag = "glossary", annotation = seg.term)
                        withStyle(
                            SpanStyle(
                                color = DS.accentSoft,
                                textDecoration = TextDecoration.Underline,
                                fontWeight = FontWeight.SemiBold,
                            ),
                        ) { append(seg.text) }
                        pop()
                    } else {
                        append(seg.text)
                    }
                } else if (seg.bold) {
                    withStyle(SpanStyle(fontWeight = FontWeight.SemiBold)) { append(seg.text) }
                } else {
                    append(seg.text)
                }
            }
        }
    }

    ClickableText(
        text = annotated,
        style = SophiaTypography.bodyLarge.copy(color = color),
        onClick = { offset ->
            annotated.getStringAnnotations("glossary", offset, offset).firstOrNull()?.let { ann ->
                openEntry = GlossaryStore.entry(context, language, courseId, courseTitle, ann.item)
            }
        },
    )

    openEntry?.let { entry ->
        ModalBottomSheet(
            onDismissRequest = { openEntry = null },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            containerColor = DS.surface,
            shape = RoundedCornerShape(topStart = 22.dp, topEnd = 22.dp),
        ) {
            Column(modifier = Modifier.fillMaxWidth().padding(DS.Space.l)) {
                Text(entry.displayTerm, style = SophiaTypography.titleLarge)
                if (entry.classification.isNotBlank()) {
                    Spacer(Modifier.height(6.dp))
                    Text(entry.classification, style = SophiaTypography.labelMedium, color = DS.accentSoft)
                }
                Spacer(Modifier.height(12.dp))
                Text(entry.explanation, style = SophiaTypography.bodyLarge)
                Spacer(Modifier.height(24.dp))
            }
        }
    }
}

private fun parseSegments(raw: String): List<TextSeg> {
    val s = raw.replace(Regex("==([^=]+)=="), "$1")
    val out = mutableListOf<TextSeg>()
    var i = 0
    while (i < s.length) {
        when {
            s.startsWith("[[", i) -> {
                val end = s.indexOf("]]", i + 2)
                if (end < 0) {
                    out += TextSeg(s.substring(i))
                    break
                }
                val term = s.substring(i + 2, end).trim()
                out += TextSeg(term, term = term)
                i = end + 2
            }
            s.startsWith("**", i) -> {
                val end = s.indexOf("**", i + 2)
                if (end < 0) {
                    out += TextSeg(s.substring(i))
                    break
                }
                out += TextSeg(s.substring(i + 2, end), bold = true)
                i = end + 2
            }
            else -> {
                val nextBracket = s.indexOf("[[", i).let { if (it < 0) Int.MAX_VALUE else it }
                val nextBold = s.indexOf("**", i).let { if (it < 0) Int.MAX_VALUE else it }
                val next = minOf(nextBracket, nextBold, s.length)
                if (next > i) out += TextSeg(s.substring(i, if (next == Int.MAX_VALUE) s.length else next))
                i = if (next == Int.MAX_VALUE) s.length else next
            }
        }
    }
    return out
}
