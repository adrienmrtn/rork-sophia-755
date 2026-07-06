import Foundation

/// Ten hand-picked starter courses shown first on the home deck for all users.
///
/// Criteria: strong intros, visual appeal, and subject diversity (TikTok-friendly hooks).
/// IDs are stable across locales. Order here is logical only — the deck shuffles this block.
enum CuratedStarterCourses {
    static let ids: [String] = [
        "course_12_la_strategie_de_napoleon_a_ulm_1805",       // Histoire — Napoléon
        "course_67_qu_est_ce_qu_un_trou_noir",                 // Sciences — trous noirs
        "course_162_promethee_le_voleur_de_feu",               // Mythologie — Prométhée
        "course_150_la_nuit_etoilee_van_gogh",                 // Art — Van Gogh
        "course_9_l_empire_azteque",                           // Histoire — Aztèques
        "course_184_romulus_et_remus_la_fondation_de_rome",    // Mythologie — Rome
        "course_29_la_chute_du_mur_de_berlin_1989",             // Histoire — Mur de Berlin
        "course_97_le_mythe_de_sisyphe_camus",                 // Littérature — Camus
        "course_51_la_decouverte_de_la_penicilline_fleming",   // Sciences — pénicilline
        "course_204_le_concept_de_monde_multipolaire",           // Monde actuel — géopolitique
    ]
}
