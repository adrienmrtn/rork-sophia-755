package app.rork.sophia

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/**
 * Guards the plural tables `StringStore` resolves against.
 *
 * At runtime the category comes from ICU's rules for the user's language. If the table is
 * missing the category ICU asks for, the lookup silently falls back to `.other` and the bug
 * this replaced — "1 courses completed", and the wrong form for most Russian and Polish
 * numbers — comes straight back with nothing to show for it. Asserting the categories here
 * catches that at build time rather than in a screenshot from a user.
 */
class PluralStringsTest {

    /** CLDR plural categories each language actually uses for integers. */
    private val categories = mapOf(
        "en" to setOf("one", "other"),
        "fr" to setOf("one", "other"),
        "es" to setOf("one", "other"),
        "de" to setOf("one", "other"),
        "it" to setOf("one", "other"),
        "pt" to setOf("one", "other"),
        "nl" to setOf("one", "other"),
        "sv" to setOf("one", "other"),
        "da" to setOf("one", "other"),
        "nb" to setOf("one", "other"),
        "fi" to setOf("one", "other"),
        "et" to setOf("one", "other"),
        "el" to setOf("one", "other"),
        "hu" to setOf("one", "other"),
        "tr" to setOf("one", "other"),
        "bg" to setOf("one", "other"),
        "ru" to setOf("one", "few", "many", "other"),
        "pl" to setOf("one", "few", "many", "other"),
        "cs" to setOf("one", "few", "many", "other"),
        "sk" to setOf("one", "few", "many", "other"),
        "hr" to setOf("one", "few", "other"),
        "sr" to setOf("one", "few", "other"),
        "sl" to setOf("one", "two", "few", "other"),
        "ro" to setOf("one", "few", "other"),
        "ar" to setOf("zero", "one", "two", "few", "many", "other"),
        "he" to setOf("one", "two", "many", "other"),
    )

    private val pluralKeys = listOf(
        "settings.courses.completed",
        "subject.courses.count",
        "profile.favorites.count",
        "training.dueCount",
        "settings.streak.title",
        "favorites.badge.count",
        "onboardingV2.weeks.title",
    )

    private fun table(code: String): Map<String, String> {
        val file = File("src/main/assets/strings/$code.json")
        assertTrue("missing string table for $code", file.exists())
        return Json.parseToJsonElement(file.readText())
            .let { it as JsonObject }
            .mapValues { (_, v) -> v.jsonPrimitive.content }
    }

    @Test
    fun `every language carries the plural categories its grammar needs`() {
        val problems = mutableListOf<String>()
        for ((code, needed) in categories) {
            val strings = table(code)
            for (key in pluralKeys) {
                for (category in needed) {
                    if ("$key.$category" !in strings) {
                        problems += "$code is missing $key.$category"
                    }
                }
            }
        }
        assertTrue(problems.joinToString("\n"), problems.isEmpty())
    }

    @Test
    fun `no plural variant is written for a category the language never selects`() {
        val known = setOf("zero", "one", "two", "few", "many", "other")
        val problems = mutableListOf<String>()
        for ((code, needed) in categories) {
            val strings = table(code)
            for (key in pluralKeys) {
                strings.keys
                    .filter { it.startsWith("$key.") }
                    .map { it.removePrefix("$key.") }
                    .filter { it in known }
                    .forEach { category ->
                        if (category !in needed) {
                            problems += "$code has an unreachable $key.$category"
                        }
                    }
            }
        }
        assertTrue(problems.joinToString("\n"), problems.isEmpty())
    }

    @Test
    fun `the bare key still resolves for callers that pass no count`() {
        val problems = mutableListOf<String>()
        for (code in categories.keys) {
            val strings = table(code)
            for (key in pluralKeys) {
                if (key !in strings) problems += "$code is missing the bare $key"
            }
        }
        assertTrue(problems.joinToString("\n"), problems.isEmpty())
    }
}
