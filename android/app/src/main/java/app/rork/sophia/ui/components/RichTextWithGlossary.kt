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
import androidx.compose.ui.text.AnnotatedString
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
    color: Color = DS.ink,
) {
    val context = LocalContext.current
    val segments = remember(raw, language, courseId) {
        parseSegments(raw) { term -> GlossaryStore.hasEntry(language, courseId, term) }
    }
    var openEntry by remember { mutableStateOf<GlossaryEntry?>(null) }

    // Parsing only asks whether a term exists, which is a map hit on a preloaded
    // table; the entry itself is read on tap. Scanning the 2k glossary rows per
    // [[term]] during composition is what froze MainActivity for 15s on course open.
    val annotated = remember(segments) {
        buildAnnotatedString {
            segments.forEach { seg ->
                if (seg.term != null) {
                    pushStringAnnotation(tag = "glossary", annotation = seg.term)
                    withStyle(
                        SpanStyle(
                            color = DS.accentSoft,
                            textDecoration = TextDecoration.Underline,
                            fontWeight = FontWeight.SemiBold,
                        ),
                    ) { append(seg.text) }
                    pop()
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
                openEntry = GlossaryStore.entry(context, language, courseId, ann.item)
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

/**
 * Same authoring markers as the reader — `**bold**`, `==highlight==`, `[[term]]` — resolved
 * for a plain [Text], with no glossary sheet. Card descriptions come from the translated
 * catalogs, where roughly 180 of 238 entries per language carry `**` (French has none, which
 * is why the raw asterisks only ever showed up in the other locales).
 */
fun inlineRichText(raw: String): AnnotatedString = buildAnnotatedString {
    parseSegments(raw) { false }.forEach { seg ->
        if (seg.bold) {
            withStyle(SpanStyle(fontWeight = FontWeight.SemiBold)) { append(seg.text) }
        } else {
            append(seg.text)
        }
    }
}

private fun parseSegments(raw: String, hasEntry: (String) -> Boolean): List<TextSeg> {
    val out = mutableListOf<TextSeg>()
    appendSegments(raw.replace(Regex("==([^=]+)=="), "$1"), bold = false, out = out, hasEntry = hasEntry)
    return out
}

/**
 * Glossary terms are often authored bold (`**[[Term]]**`). Descending into the bold
 * span rather than treating it as opaque is what keeps those clickable instead of
 * printing the brackets.
 */
private fun appendSegments(
    s: String,
    bold: Boolean,
    out: MutableList<TextSeg>,
    hasEntry: (String) -> Boolean,
) {
    var i = 0
    while (i < s.length) {
        val nextTerm = s.indexOf("[[", i)
        val nextBold = if (bold) -1 else s.indexOf("**", i)
        val next = when {
            nextTerm < 0 -> nextBold
            nextBold < 0 -> nextTerm
            else -> minOf(nextTerm, nextBold)
        }
        if (next < 0) {
            out += TextSeg(s.substring(i), bold = bold)
            return
        }
        if (next > i) out += TextSeg(s.substring(i, next), bold = bold)
        if (next == nextTerm) {
            val end = s.indexOf("]]", next + 2)
            // A marker with no closing partner is malformed authoring. Drop it and
            // keep parsing rather than printing the brackets at the reader.
            if (end < 0) {
                i = next + 2
                continue
            }
            val term = s.substring(next + 2, end).trim()
            out += when {
                term.isEmpty() -> TextSeg(s.substring(next, end + 2), bold = bold)
                hasEntry(term) -> TextSeg(term, term = term, bold = bold)
                else -> TextSeg(term, bold = bold)
            }
            i = end + 2
        } else {
            val end = s.indexOf("**", next + 2)
            if (end < 0) {
                i = next + 2
                continue
            }
            appendSegments(s.substring(next + 2, end), bold = true, out = out, hasEntry = hasEntry)
            i = end + 2
        }
    }
}
