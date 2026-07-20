import Foundation
import Supabase

/// Point d'accès unique au `SupabaseClient` partagé.
///
/// Le client est créé une seule fois avec l'URL + la clé publishable (publiques par design).
/// Toute la sécurité repose sur les Row Level Security policies côté Supabase : un utilisateur
/// authentifié ne peut lire/écrire que ses propres lignes `profiles` / `user_progress`.
enum SupabaseManager {
    static let shared: SupabaseClient = {
        guard let url = URL(string: AppConfig.SUPABASE_URL) else {
            fatalError("SUPABASE_URL invalide dans AppConfig")
        }
        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: AppConfig.SUPABASE_ANON_KEY
        )
    }()
}
