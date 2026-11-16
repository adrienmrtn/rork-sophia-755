package app.rork.sophia.data

import android.content.Context
import android.util.Log
import app.rork.sophia.AppConfig
import app.rork.sophia.BuildConfig
import app.rork.sophia.domain.DeckTuning
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.doubleOrNull
import java.net.HttpURLConnection
import java.net.URL

/**
 * The home deck's tuning, read from Supabase (`app_config`, key `home_deck`):
 * `{"head_pool": 5, "exploration_every": 4}`. Same mechanics as [PaywallExperiment]: the last
 * value known to the device is used at once, a fresh one is read in the background, and a
 * missing row or a dead network leaves the defaults of [DeckTuning].
 */
object HomeDeckConfig {
    const val KEY = "home_deck"
    private const val TAG = "HomeDeckConfig"
    private const val PREFS = "sophia_home_deck_config"

    private val json = Json { ignoreUnknownKeys = true; isLenient = true }
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    @Volatile
    var tuning: DeckTuning = DeckTuning.DEFAULT
        private set

    fun start(context: Context) {
        val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        prefs.getString(KEY, null)?.let { saved -> parseValue(saved)?.let { tuning = it } }
        scope.launch {
            val body = fetch() ?: return@launch
            val value = firstValue(body) ?: return@launch
            val parsed = parse(value) ?: return@launch
            tuning = parsed
            prefs.edit().putString(KEY, value.toString()).apply()
        }
    }

    /** The `value` of the row as text (what is kept on the device), or null when unreadable. */
    fun parseValue(text: String): DeckTuning? = try {
        parse(json.parseToJsonElement(text))
    } catch (_: Exception) {
        null
    }

    private fun parse(element: JsonElement): DeckTuning? {
        // A `text` column would hand the JSON over as a string: read through it.
        if (element is JsonPrimitive && element.isString) return parseValue(element.content)
        val value = element as? JsonObject ?: return null
        return DeckTuning.clamped(
            headPool = whole(value["head_pool"]),
            explorationEvery = whole(value["exploration_every"]),
        )
    }

    private fun whole(element: JsonElement?): Int? =
        (element as? JsonPrimitive)?.doubleOrNull?.takeIf { it.isFinite() }?.toInt()

    private fun firstValue(body: String): JsonElement? = try {
        ((json.parseToJsonElement(body) as? JsonArray)?.firstOrNull() as? JsonObject)?.get("value")
    } catch (_: Exception) {
        null
    }

    private fun fetch(): String? {
        var connection: HttpURLConnection? = null
        return try {
            val url = "${AppConfig.SUPABASE_URL.trimEnd('/')}/rest/v1/app_config?key=eq.$KEY&select=value"
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
