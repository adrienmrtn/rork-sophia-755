package app.rork.sophia

import app.rork.sophia.data.analytics.Analytics
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Ce que le client Supabase envoie réellement. Il sérialise avec ses propres réglages
 * (`Json { ignoreUnknownKeys = true }`, donc sans les valeurs par défaut), pas avec ceux
 * d'`Analytics` : une colonne obligatoire portée par une valeur par défaut disparaît de la
 * requête, et la base refuse tout le lot.
 */
class AnalyticsPayloadTest {
    // Les réglages par défaut de supabase-kt (SupabaseClientBuilder.defaultSerializer).
    private val supabaseJson = Json { ignoreUnknownKeys = true }

    @Test
    fun `an event row always carries its platform`() {
        val row = Analytics.CourseEventRow(
            event_id = "e", user_id = "u", install_id = "i", session_id = "s", name = "app_open",
            lang = "fr", app_version = "1.0.6", premium_status = "free",
            props = JsonObject(emptyMap()), ts = "2026-11-13T10:00:00.000Z",
        )
        val sent = supabaseJson.encodeToJsonElement(ListSerializer(Analytics.CourseEventRow.serializer()), listOf(row))
            .jsonArray.first().jsonObject
        assertEquals("android", sent.getValue("platform").jsonPrimitive.content)
        // Les colonnes non nulles de course_events sans valeur par défaut côté base.
        listOf("event_id", "user_id", "name", "platform", "ts").forEach { assert(it in sent) { "colonne absente : $it" } }
    }

    @Test
    fun `a subscriber snapshot always carries its platform`() {
        val row = Analytics.SubscriberSnapshotRow(
            user_id = "u", is_active = true, app_version = "1.0.6", reported_at = "2026-11-13T10:00:00.000Z",
        )
        val sent = supabaseJson.encodeToJsonElement(Analytics.SubscriberSnapshotRow.serializer(), row).jsonObject
        assertEquals("android", sent.getValue("platform").jsonPrimitive.content)
    }
}
