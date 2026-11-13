package app.rork.sophia.data

import app.rork.sophia.AppConfig
import app.rork.sophia.BuildConfig
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.postgrest.from
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

object FeedbackService {
    /**
     * Une ligne de `app_feedback` (docs/events.md). Aucun champ n'a de valeur par défaut : le
     * client Supabase n'envoie pas les valeurs par défaut, et `platform` est obligatoire.
     */
    @Serializable
    data class AppFeedbackRow(
        val user_id: String,
        val category: String,
        val message: String,
        val has_email: Boolean,
        val lang: String,
        val platform: String,
        val app_version: String,
        val os_version: String,
        val device: String,
        val is_premium: Boolean,
    )

    /**
     * La copie du retour gardée chez Sophia, sans l'adresse e-mail (elle reste chez
     * Formspree). Un échec ici ne se montre pas à l'utilisateur : son message est déjà parti.
     */
    private suspend fun storeCopy(message: String, category: String, language: String, isPremium: Boolean, hasEmail: Boolean) {
        runCatching {
            val userId = SupabaseManager.client.auth.currentUserOrNull()?.id ?: return
            SupabaseManager.client.from("app_feedback").insert(
                AppFeedbackRow(
                    user_id = userId,
                    category = category,
                    message = message.trim().take(5000),
                    has_email = hasEmail,
                    lang = language,
                    platform = "android",
                    app_version = BuildConfig.VERSION_NAME.take(32),
                    os_version = android.os.Build.VERSION.RELEASE.orEmpty().take(32),
                    device = android.os.Build.MODEL.orEmpty().take(64),
                    is_premium = isPremium,
                ),
            )
        }
    }

    /**
     * Deliberately loose: the point is to catch "jean@gmail" and "jean.gmail.com" before the
     * form provider rejects the whole submission, not to adjudicate RFC 5322.
     */
    private fun isPlausibleEmail(raw: String): Boolean {
        val value = raw.trim()
        val at = value.indexOf('@')
        if (at <= 0 || at != value.lastIndexOf('@')) return false
        val domain = value.substring(at + 1)
        return domain.length >= 3 &&
            domain.contains('.') &&
            !domain.startsWith('.') &&
            !domain.endsWith('.') &&
            value.none { it.isWhitespace() }
    }

    suspend fun submitFeedback(
        message: String,
        category: String,
        language: String,
        isPremium: Boolean,
        email: String? = null,
    ): Result<Unit> = withContext(Dispatchers.IO) {
        if (message.isBlank()) return@withContext Result.failure(IllegalArgumentException("empty"))
        // Formspree rejects the whole submission when `_replyto` is not a valid address, so a
        // typo in an optional field used to throw away the message the user actually wrote.
        // It is checked before sending, and reported as its own failure.
        if (!email.isNullOrBlank() && !isPlausibleEmail(email)) {
            return@withContext Result.failure(IllegalArgumentException("email"))
        }
        val body = JSONObject()
            .put("message", message.trim())
            .put("category", category)
            .put("_subject", "Sophia Android feedback")
            // Was hardcoded, so every report from every build claimed to be 1.0.0 — which
            // made "is this already fixed?" unanswerable.
            .put("app_version", BuildConfig.VERSION_NAME)
            .put("android_version", android.os.Build.VERSION.RELEASE)
            .put("device", android.os.Build.MODEL)
            .put("language", language)
            .put("is_premium", isPremium)
        if (!email.isNullOrBlank()) {
            body.put("email", email.trim())
            body.put("_replyto", email.trim())
        }
        val result = post(AppConfig.FORMSPREE_ENDPOINT, body)
        if (result.isSuccess) storeCopy(message, category, language, isPremium, hasEmail = !email.isNullOrBlank())
        result
    }

    private fun post(endpoint: String, body: JSONObject): Result<Unit> {
        return try {
            val conn = (URL(endpoint).openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                setRequestProperty("Content-Type", "application/json")
                setRequestProperty("Accept", "application/json")
                doOutput = true
                connectTimeout = 15000
                readTimeout = 15000
            }
            conn.outputStream.use { it.write(body.toString().toByteArray(Charsets.UTF_8)) }
            val code = conn.responseCode
            if (code in 200..299) Result.success(Unit)
            else Result.failure(IllegalStateException("HTTP $code"))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
