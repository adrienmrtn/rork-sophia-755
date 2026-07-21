import Foundation

/// Maps inline/hero image slugs (from course JSON) to on-disk `CourseImages/` filenames
/// when the slug normalizer and asset naming diverge (accents, abbreviations, etc.).
enum CourseImageAliases {
    static let map: [String: String] = [
        "african_mask_influence_cubism": "african_mask_oceania_tribal_art_ethnographic",
        "american_diner_night_neon": "nighthawks_hopper_diner_new_york_night",
        "antoine_de_saint_exupery_portrait_photograph": "antoine_de_saint_exupe_u0301ry_portrait_photograph",
        "cap_de_creus_catalonia_landscape": "cap_de_creus_costa_brava_dali_landscape",
        "cartier_bresson_decisive_moment": "henri_cartier_bresson_decisive_moment_paris",
        "creation_of_adam_hands_detail": "creation_of_adam_fresco_michelangelo_detail",
        "dali_persistence_of_memory_moma": "persistence_of_memory_dali_small_painting_moma",
        "delacroix_liberty_leading_people_louvre": "delacroix_liberty_leading_the_people_painting",
        "don_quixote_windmills_gustave_dore_illustration": "don_quixote_windmills_gustave_dore_u0301_illustration",
        "epidaurus_ancient_theatre": "epidaurus_ancient_greek_theater_seats",
        "gabriel_garcia_marquez_portrait_photograph": "gabriel_garci_u0301a_ma_u0301rquez_portrait_photograph",
        "globe_theatre_london_reconstruction": "globe_theatre_london_shakespeare_elizabethan",
        "greek_theatre_masks_tragedy": "greek_tragedy_masks_sophocles_aeschylus_euripides",
        "guernica_bombing_aftermath_1937": "guernica_spanish_civil_war_bombing_1937",
        "guernica_picasso_painting_detail": "picasso_guernica_horse_bull_painting",
        "hermann_goring_nuremberg_trial": "hermann_go_u0308ring_nuremberg_trial",
        "honore_de_balzac_portrait_photograph": "honore_u0301_de_balzac_portrait_photograph",
        "hopper_nighthawks_painting": "nighthawks_hopper",
        "july_revolution_1830_barricades": "three_glorious_days_1830_revolution_paris",
        "le_havre_port_19th_century": "monet_impression_sunrise_le_havre_painting",
        "little_prince_original_illustration_saint_exupery": "little_prince_original_illustration_saint_exupe_u0301ry",
        "monet_impression_sunrise_painting": "impression_soleil_levant_monet",
        "photojournalism_war_correspondent_camera": "robert_capa_war_photographer_magnum",
        "picasso_demoiselles_avignon_moma": "demoiselles_d_avignon_picasso_moma",
        "santa_maria_caravel_ship": "santa_mari_u0301a_caravel_ship",
        "shakespeare_first_folio_1623": "william_shakespeare_portrait",
        "sistine_chapel_ceiling_overview": "sistine_chapel_ceiling_michelangelo_fingers",
        "sugarhill_gang_rappers_delight_1979_record": "sugarhill_gang_rapper_s_delight_1979_record",
        "voie_sacree_verdun_trucks": "voie_sacre_u0301e_verdun_trucks",
    ]
}
