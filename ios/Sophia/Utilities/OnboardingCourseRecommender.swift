import Foundation

/// Hand-picked onboarding recommendations per subject — stable IDs, strong hooks.
enum OnboardingCourseRecommender {
  private static let picksBySubject: [String: [String]] = [
    "histoire": [
      "course_12_la_strategie_de_napoleon_a_ulm_1805",
      "course_29_la_chute_du_mur_de_berlin_1989",
      "course_9_l_empire_azteque",
      "course_16_la_bataille_de_verdun_1916",
    ],
    "sciences": [
      "course_67_qu_est_ce_qu_un_trou_noir",
      "course_51_la_decouverte_de_la_penicilline_fleming",
      "course_65_pourquoi_la_lune_ne_tombe_t_elle_pas_sur",
      "course_52_la_decouverte_de_l_electricite_et_ses_ap",
    ],
    "litterature": [
      "course_97_le_mythe_de_sisyphe_camus",
      "course_198_sindbad_le_marin",
      "course_a_la_recherche_du_temps_perdu_proust",
      "course_cent_ans_de_solitude_garcia_marquez",
    ],
    "art": [
      "course_150_la_nuit_etoilee_van_gogh",
      "course_124_rembrandt_et_le_clair_obscur",
      "course_125_le_romantisme_en_peinture_delacroix_geri",
      "course_123_le_caravage_et_le_clair_obscur",
    ],
    "mythologie": [
      "course_184_romulus_et_remus_la_fondation_de_rome",
      "course_162_promethee_le_voleur_de_feu",
      "course_169_tantale_et_son_supplice",
      "course_189_dionysos_le_dieu_du_vin_et_de_l_exces",
    ],
    "comprendreLeMonde": [
      "course_204_le_concept_de_monde_multipolaire",
      "course_32_la_guerre_du_vietnam_1955_1975",
      "course_31_le_plan_marshall_1947_1952",
      "course_22_la_crise_des_missiles_de_cuba_1962",
    ],
  ]

  static func recommendedCourses(
    interests: Set<String>,
    language: AppLanguage,
    limit: Int = 4
  ) -> [Course] {
    let orderedKeys = Subject.allCases.map(\.storageKey).filter { interests.contains($0) }
    var ids: [String] = []
    var pickIndex = 0

    while ids.count < limit {
      var added = false
      for key in orderedKeys {
        guard let pool = picksBySubject[key], pickIndex < pool.count else { continue }
        let id = pool[pickIndex]
        if !ids.contains(id) {
          ids.append(id)
          added = true
          if ids.count >= limit { break }
        }
      }
      if !added { break }
      pickIndex += 1
    }

    if ids.count < limit {
      for fallbackId in CuratedStarterCourses.ids where ids.count < limit {
        if !ids.contains(fallbackId) { ids.append(fallbackId) }
      }
    }

    return ids.compactMap { ContentCatalog.course(withId: $0, language: language) }
  }
}
