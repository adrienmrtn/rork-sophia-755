package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.domain.AppLanguage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.util.concurrent.ConcurrentHashMap

@Serializable
data class LegalSection(
    val id: String,
    val title: String,
    val body: String,
)

@Serializable
private data class LegalDocumentFile(
    val terms: List<LegalSection> = emptyList(),
    val privacy: List<LegalSection> = emptyList(),
)

object LegalDocumentStore {
    private val json = Json { ignoreUnknownKeys = true }
    private val cache = ConcurrentHashMap<String, LegalDocumentFile>()

    fun terms(context: Context, language: AppLanguage): List<LegalSection> =
        document(context, language).terms.ifEmpty {
            document(context, AppLanguage.ENGLISH).terms
        }

    fun privacy(context: Context, language: AppLanguage): List<LegalSection> =
        document(context, language).privacy.ifEmpty {
            document(context, AppLanguage.ENGLISH).privacy
        }

    suspend fun termsAsync(context: Context, language: AppLanguage): List<LegalSection> =
        withContext(Dispatchers.IO) { terms(context, language) }

    suspend fun privacyAsync(context: Context, language: AppLanguage): List<LegalSection> =
        withContext(Dispatchers.IO) { privacy(context, language) }

    private fun document(context: Context, language: AppLanguage): LegalDocumentFile {
        return cache.getOrPut(language.code) {
            try {
                val text = context.assets.open("legal/${language.code}.json")
                    .bufferedReader()
                    .use { it.readText() }
                json.decodeFromString<LegalDocumentFile>(text)
            } catch (_: Exception) {
                LegalDocumentFile()
            }
        }
    }

    fun clearCache() {
        cache.clear()
    }
}
