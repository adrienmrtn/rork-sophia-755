package app.rork.sophia.domain

import java.text.NumberFormat
import java.time.format.TextStyle
import java.util.Locale

/**
 * Every piece of text the app formats itself — a number, a month, an uppercase label — has to
 * follow the language the user picked *in Sophia*, never the phone's.
 *
 * The three bugs this exists to stop, all reported from real phones:
 *
 *  - `String.uppercase()` with no locale uses the default one, so a section label read
 *    "HİSTORY" on a Turkish phone (`i` uppercases to a dotted `İ` in Turkish) whatever
 *    language the app itself was in.
 *  - `NumberFormat.getInstance()` on an Arabic phone returns Arabic-Indic digits (٤٢), so a
 *    French reader saw a score they could not read. Sophia's own Arabic strings are written
 *    with Latin digits throughout, so the Latin numbering system is pinned for every
 *    language — consistent with the copy it sits next to.
 *  - Serbian resolves to Cyrillic by default, so a reader of the Latin `sr` table got
 *    Cyrillic month names next to Latin text. The script is pinned to match the table.
 */
val AppLanguage.locale: Locale
    get() = Locale.forLanguageTag(bcp47Tag)

private val AppLanguage.bcp47Tag: String
    get() = when (this) {
        // The `sr` string table is Serbian in Latin script; without the subtag, dates and
        // month names would come back in Cyrillic.
        AppLanguage.SERBIAN -> "sr-Latn-u-nu-latn"
        AppLanguage.NORWEGIAN -> "nb-NO-u-nu-latn"
        else -> "$code-u-nu-latn"
    }

/** Uppercase in the app's language, never the device's. */
fun String.uppercaseIn(language: AppLanguage): String = uppercase(language.locale)

fun String.lowercaseIn(language: AppLanguage): String = lowercase(language.locale)

/** Integer with the app language's grouping separator and Latin digits. */
fun Int.formatted(language: AppLanguage): String =
    NumberFormat.getIntegerInstance(language.locale).format(this)

/**
 * Decimal with exactly [decimals] fraction digits. Used by the quiz sliders, where a value
 * that reads "23" when the answer is 23.5 makes the question impossible to get right.
 */
fun Double.formatted(language: AppLanguage, decimals: Int): String =
    NumberFormat.getNumberInstance(language.locale).apply {
        minimumFractionDigits = decimals
        maximumFractionDigits = decimals
        isGroupingUsed = decimals == 0
    }.format(this)

/** Month name in the app's language — `java.time` would otherwise use the device locale. */
fun java.time.Month.displayNameIn(language: AppLanguage, style: TextStyle = TextStyle.FULL): String =
    getDisplayName(style, language.locale)

/** Day-of-week name in the app's language. */
fun java.time.DayOfWeek.displayNameIn(
    language: AppLanguage,
    style: TextStyle = TextStyle.SHORT,
): String = getDisplayName(style, language.locale)
