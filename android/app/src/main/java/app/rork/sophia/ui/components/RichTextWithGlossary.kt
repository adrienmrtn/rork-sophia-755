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
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import app.rork.sophia.data.GlossaryEntry
import app.rork.sophia.data.GlossaryStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.SophiaTypography

private data class TextSeg(
    val text: String,
    val term: String? = null,
    val bold: Boolean = false,
    val italic: Boolean = false,
)

/** The span style a parsed segment renders with, before glossary styling is layered on. */
private fun TextSeg.spanStyle(): SpanStyle = SpanStyle(
    fontWeight = if (bold) FontWeight.SemiBold else null,
    fontStyle = if (italic) FontStyle.Italic else null,
)

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
                } else {
                    withStyle(seg.spanStyle()) { append(seg.text) }
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
        withStyle(seg.spanStyle()) { append(seg.text) }
    }
}

private fun parseSegments(raw: String, hasEntry: (String) -> Boolean): List<TextSeg> {
    val out = mutableListOf<TextSeg>()
    appendSegments(
        raw.replace(Regex("==([^=]+)=="), "$1"),
        bold = false,
        italic = false,
        out = out,
        hasEntry = hasEntry,
    )
    return out
}

/**
 * Glossary terms are often authored bold (`**[[Term]]**`). Descending into the bold
 * span rather than treating it as opaque is what keeps those clickable instead of
 * printing the brackets.
 *
 * `*italic*` is parsed here too. Titles of works are authored that way — "*The Flowers of
 * Evil*" — and, with no rule for a single asterisk, the reader printed the asterisks
 * verbatim. It is matched after `**`, so a bold marker is never read as two italic ones.
 */
private fun appendSegments(
    s: String,
    bold: Boolean,
    italic: Boolean,
    out: MutableList<TextSeg>,
    hasEntry: (String) -> Boolean,
) {
    var i = 0
    while (i < s.length) {
        val nextTerm = s.indexOf("[[", i)
        val nextBold = if (bold) -1 else s.indexOf("**", i)
        val nextItalic = if (italic) -1 else indexOfItalicMarker(s, i)
        val next = listOf(nextTerm, nextBold, nextItalic).filter { it >= 0 }.minOrNull() ?: -1
        if (next < 0) {
            out += TextSeg(s.substring(i), bold = bold, italic = italic)
            return
        }
        if (next > i) out += TextSeg(s.substring(i, next), bold = bold, italic = italic)
        when (next) {
            nextTerm -> {
                val end = s.indexOf("]]", next + 2)
                // A marker with no closing partner is malformed authoring. Drop it and
                // keep parsing rather than printing the brackets at the reader.
                if (end < 0) {
                    i = next + 2
                    continue
                }
                val term = s.substring(next + 2, end).trim()
                out += when {
                    term.isEmpty() -> TextSeg(s.substring(next, end + 2), bold = bold, italic = italic)
                    hasEntry(term) -> TextSeg(term, term = term, bold = bold, italic = italic)
                    else -> TextSeg(term, bold = bold, italic = italic)
                }
                i = end + 2
            }
            nextBold -> {
                val end = s.indexOf("**", next + 2)
                if (end < 0) {
                    i = next + 2
                    continue
                }
                appendSegments(
                    s.substring(next + 2, end),
                    bold = true,
                    italic = italic,
                    out = out,
                    hasEntry = hasEntry,
                )
                i = end + 2
            }
            else -> {
                val end = indexOfItalicMarker(s, next + 1)
                if (end < 0) {
                    i = next + 1
                    continue
                }
                appendSegments(
                    s.substring(next + 1, end),
                    bold = bold,
                    italic = true,
                    out = out,
                    hasEntry = hasEntry,
                )
                i = end + 1
            }
        }
    }
}

/** A lone `*`: an asterisk with no asterisk either side, so `**bold**` is left to its own rule. */
private fun indexOfItalicMarker(s: String, from: Int): Int {
    var i = from
    while (i < s.length) {
        val at = s.indexOf('*', i)
        if (at < 0) return -1
        val doubled = (at > 0 && s[at - 1] == '*') || (at + 1 < s.length && s[at + 1] == '*')
        if (!doubled) return at
        // Skip the whole run of asterisks, not just this one.
        var j = at
        while (j < s.length && s[j] == '*') j++
        i = j
    }
    return -1
}
