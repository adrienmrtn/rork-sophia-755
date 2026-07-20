import Foundation

enum AppConfig {
    static let EXPO_PUBLIC_REVENUECAT_IOS_API_KEY: String = "appl_uGsIMbbdKdSEmAoLNJFcfveiQgC"
    static let EXPO_PUBLIC_REVENUECAT_TEST_API_KEY: String = "test_LaMUBJriSlDtBOIRKsZjkPgKbUB"
    static let MIXPANEL_TOKEN: String = "d2e043bfcdd8f53a7ec613d378667519"
    static let FORMSPREE_ENDPOINT: String = "https://formspree.io/f/xwvdybwb"
    static let FORMSPREE_AMBASSADOR_ENDPOINT: String = "https://formspree.io/f/xpqvqnwb"

    // MARK: - Supabase (auth + sync)
    //
    // URL et clé publishable/anon sont publiques par design (clés client). La sécurité
    // repose sur les Row Level Security policies côté Supabase, pas sur le secret de ces clés.
    // Ne jamais mettre ici la `service_role` key, le secret Google (GOCSPX-…) ou la clé Apple `.p8`.
    static let SUPABASE_URL: String = "https://afnmcoovdvbtkgohtdij.supabase.co"
    static let SUPABASE_ANON_KEY: String = "sb_publishable_eNzCyPFfEuKC0tKWr0Hjag_lJ_qsWRw"

    // MARK: - Google Sign-In
    //
    // Client iOS : utilisé par le SDK GoogleSignIn sur l'appareil (aussi déclaré via GIDClientID dans Info.plist).
    // Client web : `serverClientID` transmis à Google pour que l'idToken cible aussi le client web
    // enregistré côté Supabase (Google provider → Client IDs = web,ios).
    static let GOOGLE_IOS_CLIENT_ID: String = "716867958674-pkkmuij2frvfv1313k1jgp3p5ldqor2o.apps.googleusercontent.com"
    static let GOOGLE_WEB_CLIENT_ID: String = "716867958674-b9ql8ap6fna2lu9caublcjajdh7978q2.apps.googleusercontent.com"
}
