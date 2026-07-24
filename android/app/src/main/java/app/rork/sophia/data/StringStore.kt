package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.domain.AppLanguage
import kotlinx.serialization.json.Json
import java.util.concurrent.ConcurrentHashMap

object StringStore {
    private val json = Json { ignoreUnknownKeys = true }
    private val cache = ConcurrentHashMap<String, Map<String, String>>()

    fun text(context: Context, key: String, language: AppLanguage, vararg formatArgs: Any): String {
        val primary = table(context, language.code)
        val english = table(context, AppLanguage.ENGLISH.code)
        val template = primary[key] ?: english[key] ?: key
        return if (formatArgs.isEmpty()) template else {
            try {
                // iOS-style %@ → Java %s
                val javaTemplate = template.replace("%@", "%s")
                String.format(javaTemplate, *formatArgs)
            } catch (_: Exception) {
                template
            }
        }
    }

    private fun table(context: Context, code: String): Map<String, String> {
        return cache.getOrPut(code) {
            try {
                val text = context.assets.open("strings/$code.json").bufferedReader().use { it.readText() }
                json.decodeFromString<Map<String, String>>(text)
            } catch (_: Exception) {
                emptyMap()
            }
        }
    }
}
