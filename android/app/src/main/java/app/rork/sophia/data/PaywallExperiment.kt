package app.rork.sophia.data

import android.content.Context
import android.util.Log
import app.rork.sophia.AppConfig
import app.rork.sophia.BuildConfig
import app.rork.sophia.data.analytics.Analytics
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest

/**
 * The A/B test of the course paywall, steered from Supabase and **read-only** on the phone.
 *
 * The setting is the row `course_paywall_ab` of `public.app_config` (the table `CatalogStore`
 * already reads its `catalog` key from): `{"enabled": true, "share_reviews": 0.5}`. It is
 * fetched once at launch and the last value read is kept on the device; a missing row, no
 * network or an unreadable value all mean the default (test on, half and half) — never an
 * error, never a wait.
 *
 * The draw is stable per install and identical on iOS: `u` = the first four bytes of
 * SHA-256(`"course_paywall_ab:" + installId` in lower case), read as an unsigned big-endian integer,
 * divided by 2^32. The install gets [Variant.REVIEWS] when `u < share_reviews`.
 */
object PaywallExperiment {
    const val EXPERIMENT = "course_paywall_ab"

    private const val TAG = "PaywallExperiment"
    private const val PREFS = "sophia_paywall_experiment"
    private const val KEY_VALUE = "course_paywall_ab"

    enum class Variant(val id: String) {
        BONHOMME("bonhomme"),
        REVIEWS("reviews"),
        ;

        /** The paywall identifier reported to RevenueCat and to `paywall_view`. */
        val paywallId: String get() = "native_course_unlock_$id"

        companion object {
            fun fromId(id: String?): Variant? = entries.firstOrNull { it.id == id }
        }
    }

    data class Config(
        val enabled: Boolean = true,
        /** Share of the installs (0 to 1) that get [Variant.REVIEWS]. */
        val shareReviews: Double = 0.5,
        /** Served to everyone once the test is stopped (`enabled: false`). */
        val defaultVariant: Variant? = null,
    )

    private val json = Json { ignoreUnknownKeys = true; isLenient = true }
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    @Volatile
    var config: Config = Config()
        private set

    /** Loads the last value kept on the device, then re-reads the setting in the background. */
    fun start(context: Context) {
        val appContext = context.applicationContext
        val prefs = appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        prefs.getString(KEY_VALUE, null)?.let { saved -> parseValue(saved)?.let { config = it } }
        scope.launch {
            val body = fetch() ?: return@launch
            // No row yet: the default stands, and so does whatever was read before.
            val value = firstValue(body) ?: return@launch
            val parsed = parseConfig(value) ?: return@launch
            config = parsed
            prefs.edit().putString(KEY_VALUE, value.toString()).apply()
        }
    }

    /** The variant of this install under the current setting. */
    fun courseVariant(): Variant = variant(Analytics.installIdentifier, config)

    /** The analytics properties that carry the variant on the existing paywall events. */
    fun analyticsProps(variant: Variant): Map<String, Any?> =
        mapOf("experiment" to EXPERIMENT, "variant" to variant.id)

    // region Pure draw (unit-tested, mirrored on iOS)

    fun variant(installId: String, config: Config): Variant {
        if (!config.enabled) return config.defaultVariant ?: Variant.BONHOMME
        return if (unitInterval(installId) < config.shareReviews) Variant.REVIEWS else Variant.BONHOMME
    }

    /** A number in [0, 1), always the same for the same install. */
    fun unitInterval(installId: String): Double {
        // Lower-cased: iOS writes its UUIDs in capitals, and both platforms must hash the same text.
        val text = "$EXPERIMENT:${installId.lowercase(java.util.Locale.ROOT)}"
        val digest = MessageDigest.getInstance("SHA-256").digest(text.toByteArray(Charsets.UTF_8))
        var value = 0L
        for (i in 0 until 4) value = (value shl 8) or (digest[i].toLong() and 0xFF)
        return value.toDouble() / 4294967296.0
    }

    /** The `value` of the row as text (what is kept on the device), or null when unreadable. */
    fun parseValue(text: String): Config? = try {
        parseConfig(json.parseToJsonElement(text))
    } catch (_: Exception) {
        null
    }

    private fun parseConfig(element: JsonElement): Config? {
        // A `text` column would hand the JSON over as a string: read through it.
        if (element is JsonPrimitive && element.isString) return parseValue(element.content)
        val value = element as? JsonObject ?: return null
        val share = (value["share_reviews"] as? JsonPrimitive)?.doubleOrNull
        return Config(
            enabled = (value["enabled"] as? JsonPrimitive)?.booleanOrNull ?: true,
            shareReviews = (share?.takeIf { !it.isNaN() } ?: 0.5).coerceIn(0.0, 1.0),
            defaultVariant = Variant.fromId((value["default_variant"] as? JsonPrimitive)?.content),
        )
    }

    // endregion

    private fun firstValue(body: String): JsonElement? = try {
        ((json.parseToJsonElement(body) as? JsonArray)?.firstOrNull() as? JsonObject)?.get("value")
    } catch (_: Exception) {
        null
    }

    /** `rest/v1/app_config?key=eq.course_paywall_ab&select=value`, a plain public read. */
    private fun fetch(): String? {
        var connection: HttpURLConnection? = null
        return try {
            val url = "${AppConfig.SUPABASE_URL.trimEnd('/')}/rest/v1/app_config?key=eq.$KEY_VALUE&select=value"
            val conn = URL(url).openConnection() as HttpURLConnection
            connection = conn
            conn.connectTimeout = 15_000
            conn.readTimeout = 15_000
            conn.useCaches = false
            conn.requestMethod = "GET"
            conn.setRequestProperty("Accept", "application/json")
            conn.setRequestProperty("apikey", AppConfig.SUPABASE_ANON_KEY)
            conn.setRequestProperty("Authorization", "Bearer ${AppConfig.SUPABASE_ANON_KEY}")
            if (conn.responseCode != HttpURLConnection.HTTP_OK) return null
            conn.inputStream.bufferedReader().use { it.readText() }
        } catch (e: Exception) {
            if (BuildConfig.DEBUG) Log.w(TAG, "lecture impossible : ${e.message}")
            null
        } finally {
            connection?.disconnect()
        }
    }
}
