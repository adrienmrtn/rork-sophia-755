package app.rork.sophia.data

import app.rork.sophia.AppConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

object FeedbackService {
    suspend fun submitFeedback(
        message: String,
        category: String,
        language: String,
        isPremium: Boolean,
        email: String? = null,
    ): Result<Unit> = withContext(Dispatchers.IO) {
        if (message.isBlank()) return@withContext Result.failure(IllegalArgumentException("empty"))
        val body = JSONObject()
            .put("message", message.trim())
            .put("category", category)
            .put("_subject", "Sophia Android feedback")
            .put("app_version", "1.0.0")
            .put("android_version", android.os.Build.VERSION.RELEASE)
            .put("device", android.os.Build.MODEL)
            .put("language", language)
            .put("is_premium", isPremium)
        if (!email.isNullOrBlank()) {
            body.put("email", email)
            body.put("_replyto", email)
        }
        post(AppConfig.FORMSPREE_ENDPOINT, body)
    }

    suspend fun submitAmbassador(
        email: String,
        age: Int,
        presentation: String,
        wantsSlideshow: Boolean,
        wantsUgc: Boolean,
        countryConfirmed: Boolean,
        language: String,
    ): Result<Unit> = withContext(Dispatchers.IO) {
        if (!email.contains("@") || !email.contains(".")) {
            return@withContext Result.failure(IllegalArgumentException("email"))
        }
        if (age !in 16..120 || presentation.trim().length < 10 || !countryConfirmed) {
            return@withContext Result.failure(IllegalArgumentException("validation"))
        }
        if (!wantsSlideshow && !wantsUgc) {
            return@withContext Result.failure(IllegalArgumentException("roles"))
        }
        val roleValue = when {
            wantsSlideshow && wantsUgc -> "slideshow+ugc"
            wantsSlideshow -> "slideshow"
            else -> "ugc"
        }
        val body = JSONObject()
            .put("email", email.trim())
            .put("_replyto", email.trim())
            .put("age", age)
            .put("presentation", presentation.trim())
            .put("roles", roleValue)
            .put("wants_slideshow", wantsSlideshow)
            .put("wants_ugc", wantsUgc)
            .put("country_confirmed", countryConfirmed)
            .put("eligible_countries", "FR,CA,BE,CH")
            .put("_subject", "Sophia Android ambassador")
            .put("app_version", "1.0.0")
            .put("android_version", android.os.Build.VERSION.RELEASE)
            .put("device", android.os.Build.MODEL)
            .put("language", language)
        post(AppConfig.FORMSPREE_AMBASSADOR_ENDPOINT, body)
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
