package app.rork.sophia.ui.course

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.data.CourseCoverUrls
import app.rork.sophia.data.CourseImagePrefetch
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.components.CoursePalette
import app.rork.sophia.ui.components.RichTextWithGlossary
import app.rork.sophia.ui.components.inlineRichText
import app.rork.sophia.ui.components.sophiaCard
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.uppercaseInApp
import app.rork.sophia.ui.theme.PlusJakartaSans
import coil.compose.AsyncImage
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonArray

/**
 * A lesson block as authored in the course's V2 content (the `content` of its catalogue
 * bundle, `starter_pack/{lang}/courses/{courseId}.json` or downloaded), mirroring the
 * iOS `ContentBlockV2` cases. Anything missing here is dropped from the reader, so
 * it has to stay in sync with the content pipeline.
 */
sealed interface ReaderBlock {
    data class Heading(val text: String) : ReaderBlock
    data class Paragraph(val text: String) : ReaderBlock
    data class Image(
        val asset: String,
        /** Width / height, or null for `"auto"` — the authored ratio is unknown. */
        val ratio: Float?,
        val caption: String?,
    ) : ReaderBlock

    data class Timeline(val events: List<TimelineEvent>) : ReaderBlock
    data class FunFact(val text: String) : ReaderBlock
    data class Takeaway(val text: String) : ReaderBlock
    data class Quote(val text: String, val attribution: String?) : ReaderBlock
}

data class TimelineEvent(val date: String, val title: String, val detail: String?)

/** Glossary markup (`[[term]]`) only ever appears in the prose blocks. */
val ReaderBlock.proseText: String?
    get() = when (this) {
        is ReaderBlock.Paragraph -> text
        is ReaderBlock.FunFact -> text
        is ReaderBlock.Takeaway -> text
        else -> null
    }

fun parseReaderBlocks(blocks: JsonArray): List<ReaderBlock> = blocks.mapNotNull { element ->
    val block = element as? JsonObject ?: return@mapNotNull null
    when (block.string("type")) {
        "heading" -> block.string("text")?.let { ReaderBlock.Heading(it) }
        "paragraph" -> block.string("text")?.let { ReaderBlock.Paragraph(it) }
        "funFact" -> block.string("text")?.let { ReaderBlock.FunFact(it) }
        "takeaway" -> block.string("text")?.let { ReaderBlock.Takeaway(it) }
        "quote" -> block.string("text")?.let {
            ReaderBlock.Quote(it, block.string("attribution"))
        }

        "image" -> block.string("asset")?.let { asset ->
            ReaderBlock.Image(
                asset = asset,
                ratio = aspectRatio(block.string("ratio")),
                caption = block.string("caption"),
            )
        }

        "timeline" -> {
            val events = block["events"]?.jsonArray.orEmpty().mapNotNull { raw ->
                val event = raw as? JsonObject ?: return@mapNotNull null
                TimelineEvent(
                    date = event.string("date") ?: return@mapNotNull null,
                    title = event.string("title") ?: return@mapNotNull null,
                    detail = event.string("detail"),
                )
            }
            events.takeIf { it.isNotEmpty() }?.let { ReaderBlock.Timeline(it) }
        }

        else -> null
    }
}

private fun JsonObject.string(key: String): String? =
    (this[key] as? JsonPrimitive)?.contentOrNull?.takeIf { it.isNotBlank() }

/** `"4:3"` → 1.333…; `"auto"` and anything unparsable → null. */
private fun aspectRatio(raw: String?): Float? {
    val parts = raw?.split(':')?.takeIf { it.size == 2 } ?: return null
    val width = parts[0].trim().toFloatOrNull() ?: return null
    val height = parts[1].trim().toFloatOrNull() ?: return null
    return if (width > 0f && height > 0f) width / height else null
}

@Composable
fun ReaderBlockView(
    block: ReaderBlock,
    language: AppLanguage,
    courseId: String,
    locked: Boolean,
) {
    val context = LocalContext.current
    val prose = if (locked) DS.inkTertiary else DS.ink
    when (block) {
        is ReaderBlock.Heading -> Text(
            text = block.text,
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.SemiBold,
            fontSize = 20.sp,
            lineHeight = 27.sp,
            color = prose,
            modifier = Modifier.semantics { heading() },
        )

        is ReaderBlock.Paragraph -> RichTextWithGlossary(
            raw = block.text,
            language = language,
            courseId = courseId,
            color = prose,
        )

        is ReaderBlock.Image -> ImageBlock(block)

        is ReaderBlock.Timeline -> TimelineBlock(block.events)

        is ReaderBlock.FunFact -> FunFactCard(
            label = StringStore.text(context, "course.funFact", language),
        ) {
            RichTextWithGlossary(
                raw = block.text,
                language = language,
                courseId = courseId,
                color = prose,
            )
        }

        is ReaderBlock.Takeaway -> TakeawayCard(
            label = StringStore.text(context, "course.keyTakeaway", language),
        ) {
            RichTextWithGlossary(
                raw = block.text,
                language = language,
                courseId = courseId,
                color = prose,
            )
        }

        is ReaderBlock.Quote -> QuoteBlock(block, prose)
    }
}

@Composable
private fun ImageBlock(block: ReaderBlock.Image) {
    val context = LocalContext.current
    val url = remember(block.asset) { CourseCoverUrls.blockUrl(context, block.asset) }
    Column(modifier = Modifier.fillMaxWidth()) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                // "auto" has no authored ratio and the intrinsic size is only known
                // once decoded, so reserve 4:3 and fit inside it rather than crop.
                .aspectRatio(block.ratio ?: (4f / 3f))
                .clip(DS.cardShape)
                .background(DS.surfaceMuted)
                .border(1.5.dp, DS.hairline, DS.cardShape),
        ) {
            if (url != null) {
                AsyncImage(
                    model = CourseImagePrefetch.request(context, block.asset, url),
                    contentDescription = block.caption?.let { inlineRichText(it).text },
                    modifier = Modifier.fillMaxSize(),
                    contentScale = if (block.ratio == null) ContentScale.Fit else ContentScale.Crop,
                )
            }
        }
        block.caption?.let { caption ->
            Spacer(Modifier.height(8.dp))
            Text(
                // Captions are authored with the same markers as body text, so printed raw
                // they showed `**` and `[[ ]]` under the picture.
                text = inlineRichText(caption),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.Normal,
                fontSize = 13.sp,
                lineHeight = 19.sp,
                color = DS.inkSecondary,
                modifier = Modifier.padding(horizontal = 4.dp),
            )
        }
    }
}

@Composable
private fun TimelineBlock(events: List<TimelineEvent>) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .sophiaCard()
            .padding(DS.Space.m),
    ) {
        events.forEachIndexed { index, event ->
            val isLast = index == events.lastIndex
            val dot = DS.accent
            val rail = DS.hairline
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    // The rail is painted rather than laid out, so it always spans the
                    // real row height instead of a guessed one.
                    .drawBehind {
                        val x = 5.dp.toPx()
                        val y = 10.dp.toPx()
                        if (!isLast) {
                            drawLine(
                                color = rail,
                                start = Offset(x, y),
                                end = Offset(x, size.height),
                                strokeWidth = 1.5.dp.toPx(),
                            )
                        }
                        drawCircle(color = dot, radius = 5.dp.toPx(), center = Offset(x, y))
                    }
                    .padding(start = 24.dp, bottom = if (isLast) 0.dp else 20.dp),
            ) {
                Text(
                    text = event.date,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.ExtraBold,
                    fontSize = 13.sp,
                    color = DS.accent,
                )
                Spacer(Modifier.height(4.dp))
                Text(
                    text = event.title,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 17.sp,
                    lineHeight = 23.sp,
                    color = DS.ink,
                )
                event.detail?.let { detail ->
                    Spacer(Modifier.height(4.dp))
                    Text(
                        text = detail,
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.Normal,
                        fontSize = 15.sp,
                        lineHeight = 22.sp,
                        color = DS.inkSecondary,
                    )
                }
            }
        }
    }
}

@Composable
private fun QuoteBlock(block: ReaderBlock.Quote, prose: Color) {
    val rule = DS.accent
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .drawBehind {
                drawRoundRect(
                    color = rule,
                    size = Size(3.dp.toPx(), size.height),
                    cornerRadius = CornerRadius(2.dp.toPx()),
                )
            }
            .padding(start = 18.dp),
    ) {
        Text(
            text = block.text,
            fontFamily = PlusJakartaSans,
            fontSize = 20.sp,
            fontStyle = FontStyle.Italic,
            color = prose,
            lineHeight = 29.sp,
        )
        block.attribution?.let { attribution ->
            Spacer(Modifier.height(10.dp))
            Text(
                text = attribution.uppercaseInApp(),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 12.sp,
                letterSpacing = 0.8.sp,
                color = DS.inkSecondary,
            )
        }
    }
}

/** « Le savais-tu ? »: a white bordered card, a golden bulb and its label, then the text. */
@Composable
private fun FunFactCard(
    label: String,
    content: @Composable () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .sophiaCard()
            .padding(14.dp),
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Icon(
                imageVector = Icons.Filled.Lightbulb,
                contentDescription = null,
                tint = CoursePalette.goldDeep,
                modifier = Modifier.size(20.dp),
            )
            Text(
                text = label.uppercaseInApp(),
                fontFamily = PlusJakartaSans,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 12.sp,
                letterSpacing = 0.8.sp,
                color = DS.ink,
            )
        }
        Spacer(Modifier.height(DS.Space.s))
        content()
    }
}

/** « À retenir »: a pale green card, a solid green label, then the text. */
@Composable
private fun TakeawayCard(
    label: String,
    content: @Composable () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(DS.cardShape)
            .background(DS.successTint)
            .padding(DS.Space.m),
    ) {
        Text(
            text = label.uppercaseInApp(),
            fontFamily = PlusJakartaSans,
            fontWeight = FontWeight.ExtraBold,
            fontSize = 12.sp,
            letterSpacing = 0.6.sp,
            color = Color.White,
            modifier = Modifier
                .clip(RoundedCornerShape(10.dp))
                .background(DS.success)
                .padding(horizontal = 10.dp, vertical = 3.dp),
        )
        Spacer(Modifier.height(10.dp))
        content()
    }
}
