package app.rork.sophia.data

import app.rork.sophia.AppConfig
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.functions.Functions
import io.github.jan.supabase.postgrest.Postgrest

object SupabaseManager {
    val client: SupabaseClient by lazy {
        createSupabaseClient(
            supabaseUrl = AppConfig.SUPABASE_URL,
            supabaseKey = AppConfig.SUPABASE_ANON_KEY,
        ) {
            install(Auth)
            install(Postgrest)
            // `delete-user` runs with the service role and is the only way an account can be
            // removed from the app, which Google Play requires.
            install(Functions)
        }
    }
}
