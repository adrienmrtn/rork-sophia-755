import Foundation

nonisolated enum CollectibleCardRarity: String, Codable, CaseIterable, Sendable {
    case commune = "Commune"
    case rare = "Rare"
    case epique = "Épique"
    case legendaire = "Légendaire"

    var xpReward: Int {
        switch self {
        case .commune: 10
        case .rare: 25
        case .epique: 50
        case .legendaire: 100
        }
    }
}

nonisolated struct CollectibleCard: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let rarity: CollectibleCardRarity
    let imageAssetName: String
    let courseIds: [String]
}

nonisolated enum CardData {
    static let allCards: [CollectibleCard] = [
        CollectibleCard(
            id: "k_fv51zsinebhn",
            name: "Enkidu",
            rarity: .rare,
            imageAssetName: "card_enkidu",
            courseIds: ["course_183_gilgamesh_le_premier_heros_de_l_histoire"]
        ),
        CollectibleCard(
            id: "k_x573a31hebhn",
            name: "Horus",
            rarity: .legendaire,
            imageAssetName: "card_horus",
            courseIds: ["course_182_osiris_et_set_mythologie_egyptienne"]
        ),
        CollectibleCard(
            id: "k_obj2aln3ebhn",
            name: "Isis",
            rarity: .legendaire,
            imageAssetName: "card_isis",
            courseIds: ["course_182_osiris_et_set_mythologie_egyptienne", "course_200_re_et_la_creation_du_monde_egypte"]
        ),
        CollectibleCard(
            id: "k_ieqsp8y2ebhn",
            name: "Erich von Falkenhayn",
            rarity: .commune,
            imageAssetName: "card_erich_von_falkenhayn",
            courseIds: ["course_16_la_bataille_de_verdun_1916"]
        ),
        CollectibleCard(
            id: "k_98ttzi6hebhn",
            name: "Hécatonchires",
            rarity: .commune,
            imageAssetName: "card_hecatonchires",
            courseIds: ["course_161_la_naissance_des_dieux_grecs_cronos_zeus", "course_188_les_titans_vs_les_dieux_titanomachie", "course_199_les_titans_vs_les_dieux_la_titanomachie"]
        ),
        CollectibleCard(
            id: "k_hndjjet9ebhn",
            name: "Jocaste",
            rarity: .rare,
            imageAssetName: "card_jocaste",
            courseIds: ["course_83_dipe_roi_sophocle", "course_177_dipe_et_le_sphinx"]
        ),
        CollectibleCard(
            id: "k_w21mq76febhn",
            name: "Tirésias",
            rarity: .rare,
            imageAssetName: "card_tiresias",
            courseIds: ["course_83_dipe_roi_sophocle", "course_84_antigone_sophocle", "course_178_antigone_devoir_familial_vs_loi_de_l_eta", "course_166_narcisse_et_echo"]
        ),
        CollectibleCard(
            id: "k_ovpp78boebhn",
            name: "Hémon",
            rarity: .commune,
            imageAssetName: "card_hemon",
            courseIds: ["course_84_antigone_sophocle", "course_178_antigone_devoir_familial_vs_loi_de_l_eta"]
        ),
        CollectibleCard(
            id: "k_noy1lpmbebhn",
            name: "Ismène",
            rarity: .commune,
            imageAssetName: "card_ismene",
            courseIds: ["course_84_antigone_sophocle", "course_178_antigone_devoir_familial_vs_loi_de_l_eta"]
        ),
        CollectibleCard(
            id: "k_aaco2w1jebhn",
            name: "Innocent III",
            rarity: .rare,
            imageAssetName: "card_innocent_iii",
            courseIds: ["course_5_la_magna_carta_1215"]
        ),
        CollectibleCard(
            id: "k_9leefxjqebhn",
            name: "Godefroy de Bouillon",
            rarity: .rare,
            imageAssetName: "card_godefroy_de_bouillon",
            courseIds: ["course_2_l_appel_d_urbain_ii_et_la_1re_croisade_1"]
        ),
        CollectibleCard(
            id: "k_56gablwrebhn",
            name: "Alexis Ier Comnène",
            rarity: .commune,
            imageAssetName: "card_alexis_ier_comnene",
            courseIds: ["course_2_l_appel_d_urbain_ii_et_la_1re_croisade_1"]
        ),
        CollectibleCard(
            id: "k_fg0m9859ebhn",
            name: "Umar",
            rarity: .rare,
            imageAssetName: "card_umar",
            courseIds: ["course_1_la_naissance_de_l_islam_622"]
        ),
        CollectibleCard(
            id: "k_dctp0svtebhn",
            name: "Abu Bakr",
            rarity: .rare,
            imageAssetName: "card_abu_bakr",
            courseIds: ["course_1_la_naissance_de_l_islam_622"]
        ),
        CollectibleCard(
            id: "k_d8a98ncmebhn",
            name: "Ali",
            rarity: .rare,
            imageAssetName: "card_ali",
            courseIds: ["course_1_la_naissance_de_l_islam_622"]
        ),
        CollectibleCard(
            id: "k_t8acp06webhn",
            name: "Khadija",
            rarity: .rare,
            imageAssetName: "card_khadija",
            courseIds: ["course_1_la_naissance_de_l_islam_622"]
        ),
        CollectibleCard(
            id: "k_seakzzrr7udi",
            name: "Bruce Springsteen",
            rarity: .legendaire,
            imageAssetName: "card_bruce_springsteen",
            courseIds: ["course_29_la_chute_du_mur_de_berlin_1989"]
        ),
        CollectibleCard(
            id: "k_21oehq8h7udi",
            name: "Muhammad",
            rarity: .legendaire,
            imageAssetName: "card_muhammad",
            courseIds: ["course_1_la_naissance_de_l_islam_622"]
        ),
        CollectibleCard(
            id: "k_wtnvf16cooie",
            name: "Satoshi Nakamoto",
            rarity: .rare,
            imageAssetName: "card_satoshi_nakamoto",
            courseIds: ["course_232_la_blockchain_et_les_cryptomonnaies"]
        ),
        CollectibleCard(
            id: "k_hc75qe7uo6r2",
            name: "Deng Xiaoping",
            rarity: .rare,
            imageAssetName: "card_deng_xiaoping",
            courseIds: ["course_240_la_chine_et_son_modele_economique"]
        ),
        CollectibleCard(
            id: "k_6ej3vu1pknwx",
            name: "Clément Attlee",
            rarity: .rare,
            imageAssetName: "card_clement_attlee",
            courseIds: ["course_34_la_decolonisation_panorama_1945_1975"]
        ),
        CollectibleCard(
            id: "k_akzmgdp9knwx",
            name: "Talaat Pacha",
            rarity: .commune,
            imageAssetName: "card_talaat_pacha",
            courseIds: ["course_25_le_genocide_armenien_1915_1916"]
        ),
        CollectibleCard(
            id: "k_o5gu57xuknwx",
            name: "Enver Pacha",
            rarity: .commune,
            imageAssetName: "card_enver_pacha",
            courseIds: ["course_25_le_genocide_armenien_1915_1916"]
        ),
        CollectibleCard(
            id: "k_efzxix81knwx",
            name: "Philippe Pétain",
            rarity: .rare,
            imageAssetName: "card_philippe_petain",
            courseIds: ["course_16_la_bataille_de_verdun_1916", "course_30_la_blitzkrieg_1940"]
        ),
        CollectibleCard(
            id: "k_kri3e219knwx",
            name: "Jean Moulin",
            rarity: .legendaire,
            imageAssetName: "card_jean_moulin",
            courseIds: ["course_30_la_blitzkrieg_1940"]
        ),
        CollectibleCard(
            id: "k_pvl2e9ydknwx",
            name: "Joseph Staline",
            rarity: .legendaire,
            imageAssetName: "card_joseph_staline",
            courseIds: ["course_17_la_revolution_russe_1917", "course_19_la_bataille_de_stalingrad_1942_1943"]
        ),
        CollectibleCard(
            id: "k_d4xdfwq9knwx",
            name: "Ulysses S. Grant",
            rarity: .rare,
            imageAssetName: "card_ulysses_s_grant",
            courseIds: ["course_40_la_guerre_de_secession_americaine_1861_1"]
        ),
        CollectibleCard(
            id: "k_th8s1n1pknwx",
            name: "Robert E. Lee",
            rarity: .rare,
            imageAssetName: "card_robert_e_lee",
            courseIds: ["course_40_la_guerre_de_secession_americaine_1861_1"]
        ),
        CollectibleCard(
            id: "k_7h5vm83hknwx",
            name: "Jefferson Davis",
            rarity: .rare,
            imageAssetName: "card_jefferson_davis",
            courseIds: ["course_40_la_guerre_de_secession_americaine_1861_1"]
        ),
        CollectibleCard(
            id: "k_l89k6p83knwx",
            name: "Franklin D. Roosevelt",
            rarity: .legendaire,
            imageAssetName: "card_franklin_d_roosevelt",
            courseIds: ["course_18_la_grande_depression_1929"]
        ),
        CollectibleCard(
            id: "k_7gxrm1gvknwx",
            name: "John Maynard Keynes",
            rarity: .rare,
            imageAssetName: "card_john_maynard_keynes",
            courseIds: ["course_18_la_grande_depression_1929"]
        ),
        CollectibleCard(
            id: "k_ioq088lbknwx",
            name: "Suleiman le Magnifique",
            rarity: .legendaire,
            imageAssetName: "card_suleiman_le_magnifique",
            courseIds: ["course_8_la_chute_de_constantinople_1453"]
        ),
        CollectibleCard(
            id: "k_v9vm9jyxknwx",
            name: "Jean Monnet",
            rarity: .rare,
            imageAssetName: "card_jean_monnet",
            courseIds: ["course_27_la_naissance_de_l_ue_de_la_ceca_a_maastr"]
        ),
        CollectibleCard(
            id: "k_sl825i0xjnyk",
            name: "David Ben Gourion",
            rarity: .rare,
            imageAssetName: "card_david_ben_gourion",
            courseIds: ["course_201_la_naissance_du_conflit_israelo_palestin"]
        ),
        CollectibleCard(
            id: "k_x9i4i5v6jnyk",
            name: "Hadès",
            rarity: .rare,
            imageAssetName: "card_hades",
            courseIds: ["course_164_demeter_et_persephone_les_saisons"]
        ),
        CollectibleCard(
            id: "k_gs97msdzjnyk",
            name: "Louis Pasteur",
            rarity: .legendaire,
            imageAssetName: "card_louis_pasteur",
            courseIds: ["course_70_comment_fonctionne_un_vaccin"]
        ),
        CollectibleCard(
            id: "k_r9y0tpcyjnyk",
            name: "Robert Schuman",
            rarity: .rare,
            imageAssetName: "card_robert_schuman",
            courseIds: ["course_27_la_naissance_de_l_ue_de_la_ceca_a_maastr"]
        ),
        CollectibleCard(
            id: "k_t61ypzg3jnyk",
            name: "Grigori Raspoutine",
            rarity: .rare,
            imageAssetName: "card_grigori_raspoutine",
            courseIds: ["course_17_la_revolution_russe_1917"]
        ),
        CollectibleCard(
            id: "k_zoykdaxwjnyk",
            name: "Jules César",
            rarity: .legendaire,
            imageAssetName: "card_jules_cesar",
            courseIds: ["course_191_enee_et_la_fondation_de_rome_virgile"]
        ),
        CollectibleCard(
            id: "k_2999c25zjnyk",
            name: "Alexandre le Grand",
            rarity: .legendaire,
            imageAssetName: "card_alexandre_le_grand",
            courseIds: ["course_158_la_tragedie_grecque_et_le_theatre_antiqu"]
        ),
        CollectibleCard(
            id: "k_tgqvnd1zjnyk",
            name: "Martin Luther King Jr.",
            rarity: .legendaire,
            imageAssetName: "card_martin_luther_king_jr",
            courseIds: ["course_21_rosa_parks_et_montgomery_1955"]
        ),
        CollectibleCard(
            id: "k_kbt6e5mdjnyk",
            name: "Marc Antoine",
            rarity: .rare,
            imageAssetName: "card_marc_antoine",
            courseIds: ["course_191_enee_et_la_fondation_de_rome_virgile"]
        ),
        CollectibleCard(
            id: "k_8lkhkiwienj7",
            name: "Enrico Fermi",
            rarity: .rare,
            imageAssetName: "card_enrico_fermi",
            courseIds: ["course_20_hiroshima_et_nagasaki_1945"]
        ),
        CollectibleCard(
            id: "k_b7w32ewnenj7",
            name: "Saladin",
            rarity: .rare,
            imageAssetName: "card_saladin",
            courseIds: ["course_2_l_appel_d_urbain_ii_et_la_1re_croisade_1"]
        ),
        CollectibleCard(
            id: "k_pnlz2a6genj7",
            name: "Xi Jinping",
            rarity: .legendaire,
            imageAssetName: "card_xi_jinping",
            courseIds: ["course_202_la_rivalite_chine_etats_unis", "course_240_la_chine_et_son_modele_economique"]
        ),
        CollectibleCard(
            id: "k_yprjq5fmenj7",
            name: "Volodymyr Zelensky",
            rarity: .legendaire,
            imageAssetName: "card_volodymyr_zelensky",
            courseIds: ["course_210_la_guerre_en_ukraine_expliquee"]
        ),
        CollectibleCard(
            id: "k_7r4t75noenj7",
            name: "Théodore Herlz",
            rarity: .commune,
            imageAssetName: "card_theodore_herlz",
            courseIds: ["course_201_la_naissance_du_conflit_israelo_palestin"]
        ),
        CollectibleCard(
            id: "k_8jzmh570enj7",
            name: "Reine Victoria",
            rarity: .legendaire,
            imageAssetName: "card_reine_victoria",
            courseIds: ["course_15_la_belle_epoque_1871_1914"]
        ),
        CollectibleCard(
            id: "k_sbt7ehtqenj7",
            name: "Nikita Khrouchtchev",
            rarity: .rare,
            imageAssetName: "card_nikita_khrouchtchev",
            courseIds: ["course_22_la_crise_des_missiles_de_cuba_1962"]
        ),
        CollectibleCard(
            id: "k_4eeh4oxtenj6",
            name: "Fidel Castro",
            rarity: .legendaire,
            imageAssetName: "card_fidel_castro",
            courseIds: ["course_22_la_crise_des_missiles_de_cuba_1962"]
        ),
        CollectibleCard(
            id: "k_rbd56821enj6",
            name: "Léon Trotski",
            rarity: .rare,
            imageAssetName: "card_leon_trotski",
            courseIds: ["course_17_la_revolution_russe_1917"]
        ),
        CollectibleCard(
            id: "k_pdaexjgvenj6",
            name: "Nicolas II",
            rarity: .rare,
            imageAssetName: "card_nicolas_ii",
            courseIds: ["course_17_la_revolution_russe_1917"]
        ),
        CollectibleCard(
            id: "k_qlckfgbienj6",
            name: "Louis XVI",
            rarity: .legendaire,
            imageAssetName: "card_louis_xvi",
            courseIds: ["course_11_la_prise_de_la_bastille_1789"]
        ),
        CollectibleCard(
            id: "k_g7gf1nppenj6",
            name: "Sancho Panza",
            rarity: .rare,
            imageAssetName: "card_sancho_panza",
            courseIds: ["course_109_don_quichotte_cervantes"]
        ),
        CollectibleCard(
            id: "k_ensj0jgwenj6",
            name: "Gavroche",
            rarity: .rare,
            imageAssetName: "card_gavroche",
            courseIds: ["course_91_les_miserables_victor_hugo", "course_152_la_liberte_guidant_le_peuple_delacroix"]
        ),
        CollectibleCard(
            id: "k_wz5uunkmenj6",
            name: "Javert",
            rarity: .rare,
            imageAssetName: "card_javert",
            courseIds: ["course_91_les_miserables_victor_hugo"]
        ),
        CollectibleCard(
            id: "k_vdzoatm8enj6",
            name: "Cosette",
            rarity: .rare,
            imageAssetName: "card_cosette",
            courseIds: ["course_91_les_miserables_victor_hugo"]
        ),
        CollectibleCard(
            id: "k_hri0022nenj6",
            name: "Pangloss",
            rarity: .commune,
            imageAssetName: "card_pangloss",
            courseIds: ["course_94_candide_voltaire"]
        ),
        CollectibleCard(
            id: "k_u05rcmh9enj6",
            name: "Guy Montag",
            rarity: .rare,
            imageAssetName: "card_guy_montag",
            courseIds: ["course_114_fahrenheit_451_bradbury"]
        ),
        CollectibleCard(
            id: "k_ggzgmrkzenj6",
            name: "Gandalf",
            rarity: .legendaire,
            imageAssetName: "card_gandalf",
            courseIds: ["course_113_le_seigneur_des_anneaux_tolkien"]
        ),
        CollectibleCard(
            id: "k_dnh7i0ovenj6",
            name: "Frodon Sacquet",
            rarity: .legendaire,
            imageAssetName: "card_frodon_sacquet",
            courseIds: ["course_113_le_seigneur_des_anneaux_tolkien"]
        ),
        CollectibleCard(
            id: "k_6l9ew771enj6",
            name: "Atticus Finch",
            rarity: .rare,
            imageAssetName: "card_atticus_finch",
            courseIds: ["course_111_to_kill_a_mockingbird_harper_lee"]
        ),
        CollectibleCard(
            id: "k_7giotpwuenj6",
            name: "Raskolnikov",
            rarity: .rare,
            imageAssetName: "card_raskolnikov",
            courseIds: ["course_107_crime_et_chatiment_dostoievski"]
        ),
        CollectibleCard(
            id: "k_kvy4lo3senj6",
            name: "Mustapha Mond",
            rarity: .commune,
            imageAssetName: "card_mustapha_mond",
            courseIds: ["course_105_le_meilleur_des_mondes_aldous_huxley"]
        ),
        CollectibleCard(
            id: "k_3e098262enj6",
            name: "Winston Smith",
            rarity: .rare,
            imageAssetName: "card_winston_smith",
            courseIds: ["course_101_1984_george_orwell"]
        ),
        CollectibleCard(
            id: "k_jk4921seenj6",
            name: "Capitaine Achab",
            rarity: .rare,
            imageAssetName: "card_capitaine_achab",
            courseIds: ["course_118_moby_dick_melville"]
        ),
        CollectibleCard(
            id: "k_y54bytr8enj6",
            name: "Virgile",
            rarity: .commune,
            imageAssetName: "card_virgile",
            courseIds: ["course_191_enee_et_la_fondation_de_rome_virgile"]
        ),
        CollectibleCard(
            id: "k_06kqqaslenj6",
            name: "Sphinx",
            rarity: .commune,
            imageAssetName: "card_sphinx",
            courseIds: ["course_177_dipe_et_le_sphinx"]
        ),
        CollectibleCard(
            id: "k_0ztgkna6enj6",
            name: "Créon",
            rarity: .commune,
            imageAssetName: "card_creon",
            courseIds: ["course_84_antigone_sophocle", "course_178_antigone_devoir_familial_vs_loi_de_l_eta"]
        ),
        CollectibleCard(
            id: "k_nzl2a2rxenj6",
            name: "Pénélope",
            rarity: .commune,
            imageAssetName: "card_penelope",
            courseIds: ["course_81_l_odyssee_homere"]
        ),
        CollectibleCard(
            id: "k_94wafcfpenj6",
            name: "Hélène de Troie",
            rarity: .commune,
            imageAssetName: "card_helene_de_troie",
            courseIds: ["course_179_la_guerre_de_troie_et_le_cheval_de_bois"]
        ),
        CollectibleCard(
            id: "k_blexv5vmenj6",
            name: "Pâris",
            rarity: .commune,
            imageAssetName: "card_paris",
            courseIds: ["course_179_la_guerre_de_troie_et_le_cheval_de_bois"]
        ),
        CollectibleCard(
            id: "k_uiuto3qfenj6",
            name: "Héctor",
            rarity: .commune,
            imageAssetName: "card_hector",
            courseIds: ["course_82_l_iliade_homere", "course_179_la_guerre_de_troie_et_le_cheval_de_bois"]
        ),
        CollectibleCard(
            id: "k_zutx4z59enj6",
            name: "Polyphème",
            rarity: .commune,
            imageAssetName: "card_polypheme",
            courseIds: ["course_173_ulysse_et_le_cyclope"]
        ),
        CollectibleCard(
            id: "k_y3l7j485enj6",
            name: "Eurydice",
            rarity: .commune,
            imageAssetName: "card_eurydice",
            courseIds: ["course_165_orphee_et_eurydice"]
        ),
        CollectibleCard(
            id: "k_9tivxzmienj6",
            name: "Cronos",
            rarity: .commune,
            imageAssetName: "card_cronos",
            courseIds: ["course_161_la_naissance_des_dieux_grecs_cronos_zeus", "course_188_les_titans_vs_les_dieux_titanomachie"]
        ),
        CollectibleCard(
            id: "k_c4e0tg9acm0y",
            name: "Périclès",
            rarity: .commune,
            imageAssetName: "card_pericles",
            courseIds: ["course_39_la_democratie_athenienne"]
        ),
        CollectibleCard(
            id: "k_511bjpy9cm0y",
            name: "Abraham Lincoln",
            rarity: .legendaire,
            imageAssetName: "card_abraham_lincoln",
            courseIds: ["course_40_la_guerre_de_secession_americaine_1861_1"]
        ),
        CollectibleCard(
            id: "k_3g79sg21cm0y",
            name: "Guenièvre",
            rarity: .commune,
            imageAssetName: "card_guenievre",
            courseIds: ["course_195_lancelot_guenievre_et_la_table_ronde"]
        ),
        CollectibleCard(
            id: "k_cdwysl61cm0y",
            name: "Shiva",
            rarity: .legendaire,
            imageAssetName: "card_shiva",
            courseIds: ["course_185_vishnou_et_shiva_mythologie_hindoue"]
        ),
        CollectibleCard(
            id: "k_qd0899ytcm0y",
            name: "Vishnou",
            rarity: .legendaire,
            imageAssetName: "card_vishnou",
            courseIds: ["course_185_vishnou_et_shiva_mythologie_hindoue"]
        ),
        CollectibleCard(
            id: "k_axk6yms8cm0y",
            name: "Set",
            rarity: .commune,
            imageAssetName: "card_set",
            courseIds: ["course_182_osiris_et_set_mythologie_egyptienne"]
        ),
        CollectibleCard(
            id: "k_8dmkzdlkcm0y",
            name: "Minotaure",
            rarity: .commune,
            imageAssetName: "card_minotaure",
            courseIds: ["course_172_thesee_et_le_minotaure"]
        ),
        CollectibleCard(
            id: "k_j2vx29w3cm0y",
            name: "Héphaïstos",
            rarity: .commune,
            imageAssetName: "card_hephaistos",
            courseIds: ["course_163_pandore_et_la_boite", "course_162_promethee_le_voleur_de_feu"]
        ),
        CollectibleCard(
            id: "k_tgyj8vbvcm0y",
            name: "Persée",
            rarity: .commune,
            imageAssetName: "card_persee",
            courseIds: ["course_170_meduse_et_persee"]
        ),
        CollectibleCard(
            id: "k_oyjt0lq6cm0y",
            name: "Dédale",
            rarity: .commune,
            imageAssetName: "card_dedale",
            courseIds: ["course_167_icare_et_dedale"]
        ),
        CollectibleCard(
            id: "k_y8oqgtp2cm0y",
            name: "Moctezuma II",
            rarity: .commune,
            imageAssetName: "card_moctezuma_ii",
            courseIds: ["course_9_l_empire_azteque"]
        ),
        CollectibleCard(
            id: "k_3imy57g7cm0y",
            name: "Robert Oppenheimer",
            rarity: .commune,
            imageAssetName: "card_robert_oppenheimer",
            courseIds: ["course_20_hiroshima_et_nagasaki_1945"]
        ),
        CollectibleCard(
            id: "k_iupi7oa1cm0y",
            name: "Lénine",
            rarity: .legendaire,
            imageAssetName: "card_lenine",
            courseIds: ["course_17_la_revolution_russe_1917"]
        ),
        CollectibleCard(
            id: "k_vbbosp6jcm0y",
            name: "Mehmed II",
            rarity: .commune,
            imageAssetName: "card_mehmed_ii",
            courseIds: ["course_8_la_chute_de_constantinople_1453"]
        ),
        CollectibleCard(
            id: "k_xzvwjrl8cm0y",
            name: "Constantin XI",
            rarity: .commune,
            imageAssetName: "card_constantin_xi",
            courseIds: ["course_8_la_chute_de_constantinople_1453"]
        ),
        CollectibleCard(
            id: "k_5xlg998yzjjr",
            name: "Mikhaïl Gorbatchev",
            rarity: .epique,
            imageAssetName: "card_mikhail_gorbatchev",
            courseIds: ["course_29_la_chute_du_mur_de_berlin_1989", "course_64_la_catastrophe_de_tchernobyl_1986"]
        ),
        CollectibleCard(
            id: "k_adut669nzjjr",
            name: "John F. Kennedy",
            rarity: .epique,
            imageAssetName: "card_john_f_kennedy",
            courseIds: ["course_22_la_crise_des_missiles_de_cuba_1962"]
        ),
        CollectibleCard(
            id: "k_xnb909ztzjjr",
            name: "Ho Chi Minh",
            rarity: .commune,
            imageAssetName: "card_ho_chi_minh",
            courseIds: ["course_24_la_bataille_de_dien_bien_phu_1954", "course_34_la_decolonisation_panorama_1945_1975"]
        ),
        CollectibleCard(
            id: "k_676gqpy1zjjr",
            name: "Harry S. Truman",
            rarity: .commune,
            imageAssetName: "card_harry_s_truman",
            courseIds: ["course_20_hiroshima_et_nagasaki_1945", "course_31_le_plan_marshall_1947_1952"]
        ),
        CollectibleCard(
            id: "k_8ti7fz02zjjr",
            name: "Charles de Gaulle",
            rarity: .epique,
            imageAssetName: "card_charles_de_gaulle",
            courseIds: ["course_30_la_blitzkrieg_1940", "course_34_la_decolonisation_panorama_1945_1975", "course_23_la_guerre_d_algerie_1954_1962"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1qf3l",
            name: "Urbain II",
            rarity: .commune,
            imageAssetName: "card_urbain_ii",
            courseIds: ["course_2_l_appel_d_urbain_ii_et_la_1re_croisade_1"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2nw7n",
            name: "Alaric",
            rarity: .commune,
            imageAssetName: "card_alaric",
            courseIds: ["course_3_la_prise_de_rome_par_les_wisigoths_410"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_3tcd9",
            name: "Charlemagne",
            rarity: .epique,
            imageAssetName: "card_charlemagne",
            courseIds: ["course_4_le_couronnement_de_charlemagne_800"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_45zh4",
            name: "Léon III",
            rarity: .commune,
            imageAssetName: "card_leon_iii",
            courseIds: ["course_4_le_couronnement_de_charlemagne_800"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_5vji0",
            name: "Jean sans Terre",
            rarity: .commune,
            imageAssetName: "card_jean_sans_terre",
            courseIds: ["course_5_la_magna_carta_1215"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_6k4jo",
            name: "Jeanne d'Arc",
            rarity: .epique,
            imageAssetName: "card_jeanne_d_arc",
            courseIds: ["course_7_jeanne_d_arc_et_la_guerre_de_cent_ans_14"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_7voeu",
            name: "Christophe Colomb",
            rarity: .epique,
            imageAssetName: "card_christophe_colomb",
            courseIds: ["course_10_la_decouverte_de_l_amerique_1492"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_8f3k9",
            name: "Napoléon Bonaparte",
            rarity: .epique,
            imageAssetName: "card_napoleon_bonaparte",
            courseIds: ["course_12_la_strategie_de_napoleon_a_ulm_1805", "course_13_la_bataille_de_waterloo_1815", "course_93_le_rouge_et_le_noir_stendhal"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_9ua1p",
            name: "Duc de Wellington",
            rarity: .commune,
            imageAssetName: "card_duc_de_wellington",
            courseIds: ["course_13_la_bataille_de_waterloo_1815"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_a0yhn",
            name: "Maréchal Blücher",
            rarity: .commune,
            imageAssetName: "card_marechal_blucher",
            courseIds: ["course_13_la_bataille_de_waterloo_1815"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_bnz9p",
            name: "Rosa Parks",
            rarity: .commune,
            imageAssetName: "card_rosa_parks",
            courseIds: ["course_21_rosa_parks_et_montgomery_1955"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_coto2",
            name: "George Marshall",
            rarity: .commune,
            imageAssetName: "card_george_marshall",
            courseIds: ["course_31_le_plan_marshall_1947_1952"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_d5dug",
            name: "Nelson Mandela",
            rarity: .epique,
            imageAssetName: "card_nelson_mandela",
            courseIds: ["course_35_l_apartheid_et_mandela_1948_1994"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_eebm6",
            name: "Mao Zedong",
            rarity: .epique,
            imageAssetName: "card_mao_zedong",
            courseIds: ["course_36_la_revolution_culturelle_en_chine_1966_1"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_f5cv8",
            name: "Alexander Fleming",
            rarity: .commune,
            imageAssetName: "card_alexander_fleming",
            courseIds: ["course_51_la_decouverte_de_la_penicilline_fleming"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_g6uj4",
            name: "Wilhelm Röntgen",
            rarity: .commune,
            imageAssetName: "card_wilhelm_rontgen",
            courseIds: ["course_53_la_decouverte_des_rayons_x_rontgen_1895"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_hfud3",
            name: "Isaac Newton",
            rarity: .epique,
            imageAssetName: "card_isaac_newton",
            courseIds: ["course_55_la_theorie_de_la_gravitation_newton_1687", "course_68_la_theorie_de_la_relativite_pour_tous"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_ihh74",
            name: "Marie Curie",
            rarity: .epique,
            imageAssetName: "card_marie_curie",
            courseIds: ["course_56_la_decouverte_de_la_radioactivite_marie"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_jlyf3",
            name: "James Watson",
            rarity: .commune,
            imageAssetName: "card_james_watson",
            courseIds: ["course_58_la_structure_de_l_adn_watson_crick_1953"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_k2vzh",
            name: "Francis Crick",
            rarity: .commune,
            imageAssetName: "card_francis_crick",
            courseIds: ["course_58_la_structure_de_l_adn_watson_crick_1953"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_l550l",
            name: "Charles Darwin",
            rarity: .epique,
            imageAssetName: "card_charles_darwin",
            courseIds: ["course_60_la_theorie_de_l_evolution_de_darwin_1859"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_ms1zg",
            name: "Albert Einstein",
            rarity: .epique,
            imageAssetName: "card_albert_einstein",
            courseIds: ["course_67_qu_est_ce_qu_un_trou_noir", "course_68_la_theorie_de_la_relativite_pour_tous"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_ne1ty",
            name: "Homère",
            rarity: .epique,
            imageAssetName: "card_homere",
            courseIds: ["course_81_l_odyssee_homere", "course_82_l_iliade_homere", "course_89_les_travaux_et_les_jours_hesiode", "course_179_la_guerre_de_troie_et_le_cheval_de_bois"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_o9a0x",
            name: "Ulysse",
            rarity: .epique,
            imageAssetName: "card_ulysse",
            courseIds: ["course_81_l_odyssee_homere", "course_173_ulysse_et_le_cyclope", "course_174_ulysse_et_les_sirenes"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_p5hdr",
            name: "Sophocle",
            rarity: .commune,
            imageAssetName: "card_sophocle",
            courseIds: ["course_83_dipe_roi_sophocle", "course_84_antigone_sophocle", "course_178_antigone_devoir_familial_vs_loi_de_l_eta"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_q9t83",
            name: "Œdipe",
            rarity: .commune,
            imageAssetName: "card_dipe",
            courseIds: ["course_83_dipe_roi_sophocle", "course_177_dipe_et_le_sphinx", "course_178_antigone_devoir_familial_vs_loi_de_l_eta"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_r47o7",
            name: "Antigone",
            rarity: .commune,
            imageAssetName: "card_antigone",
            courseIds: ["course_84_antigone_sophocle", "course_178_antigone_devoir_familial_vs_loi_de_l_eta"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_s24ac",
            name: "Platon",
            rarity: .epique,
            imageAssetName: "card_platon",
            courseIds: ["course_85_le_banquet_platon", "course_86_la_republique_platon", "course_87_l_apologie_de_socrate_platon"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_te9vw",
            name: "Socrate",
            rarity: .epique,
            imageAssetName: "card_socrate",
            courseIds: ["course_86_la_republique_platon", "course_87_l_apologie_de_socrate_platon"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_u83z2",
            name: "Aristote",
            rarity: .epique,
            imageAssetName: "card_aristote",
            courseIds: ["course_83_dipe_roi_sophocle", "course_88_la_poetique_aristote"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_vihiv",
            name: "Hésiode",
            rarity: .commune,
            imageAssetName: "card_hesiode",
            courseIds: ["course_89_les_travaux_et_les_jours_hesiode"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_wbro4",
            name: "Euripide",
            rarity: .commune,
            imageAssetName: "card_euripide",
            courseIds: ["course_90_medee_euripide"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_xb49q",
            name: "Médée",
            rarity: .commune,
            imageAssetName: "card_medee",
            courseIds: ["course_90_medee_euripide"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_yw77m",
            name: "Victor Hugo",
            rarity: .epique,
            imageAssetName: "card_victor_hugo",
            courseIds: ["course_91_les_miserables_victor_hugo"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_zacl3",
            name: "Jean Valjean",
            rarity: .commune,
            imageAssetName: "card_jean_valjean",
            courseIds: ["course_91_les_miserables_victor_hugo"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_10cpy6",
            name: "Gustave Flaubert",
            rarity: .epique,
            imageAssetName: "card_gustave_flaubert",
            courseIds: ["course_92_madame_bovary_flaubert"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_11k4kx",
            name: "Emma Bovary",
            rarity: .commune,
            imageAssetName: "card_emma_bovary",
            courseIds: ["course_92_madame_bovary_flaubert"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_12wag1",
            name: "Stendhal",
            rarity: .commune,
            imageAssetName: "card_stendhal",
            courseIds: ["course_93_le_rouge_et_le_noir_stendhal"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_13jcyt",
            name: "Julien Sorel",
            rarity: .commune,
            imageAssetName: "card_julien_sorel",
            courseIds: ["course_93_le_rouge_et_le_noir_stendhal"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_14frbd",
            name: "Voltaire",
            rarity: .epique,
            imageAssetName: "card_voltaire",
            courseIds: ["course_94_candide_voltaire"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_15wczf",
            name: "Jean-Jacques Rousseau",
            rarity: .epique,
            imageAssetName: "card_jean_jacques_rousseau",
            courseIds: ["course_95_les_confessions_rousseau"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_164vl6",
            name: "Albert Camus",
            rarity: .epique,
            imageAssetName: "card_albert_camus",
            courseIds: ["course_96_l_etranger_camus", "course_97_le_mythe_de_sisyphe_camus"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1783r1",
            name: "Meursault",
            rarity: .commune,
            imageAssetName: "card_meursault",
            courseIds: ["course_96_l_etranger_camus"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_18gljr",
            name: "Marcel Proust",
            rarity: .epique,
            imageAssetName: "card_marcel_proust",
            courseIds: ["course_98_a_la_recherche_du_temps_perdu_proust"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_19hly1",
            name: "Honoré de Balzac",
            rarity: .epique,
            imageAssetName: "card_honore_de_balzac",
            courseIds: ["course_99_le_pere_goriot_balzac"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1aryty",
            name: "Le Père Goriot",
            rarity: .commune,
            imageAssetName: "card_le_pere_goriot",
            courseIds: ["course_99_le_pere_goriot_balzac"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1bsk51",
            name: "Charles Baudelaire",
            rarity: .epique,
            imageAssetName: "card_charles_baudelaire",
            courseIds: ["course_100_les_fleurs_du_mal_baudelaire"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1cieb3",
            name: "George Orwell",
            rarity: .epique,
            imageAssetName: "card_george_orwell",
            courseIds: ["course_101_1984_george_orwell", "course_102_la_ferme_des_animaux_george_orwell"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1dncjb",
            name: "Big Brother",
            rarity: .commune,
            imageAssetName: "card_big_brother",
            courseIds: ["course_101_1984_george_orwell"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1e6aud",
            name: "William Shakespeare",
            rarity: .epique,
            imageAssetName: "card_william_shakespeare",
            courseIds: ["course_103_hamlet_shakespeare", "course_104_romeo_et_juliette_shakespeare", "course_159_le_theatre_de_shakespeare"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1fwap9",
            name: "Hamlet",
            rarity: .commune,
            imageAssetName: "card_hamlet",
            courseIds: ["course_103_hamlet_shakespeare"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1g0t6k",
            name: "Roméo",
            rarity: .commune,
            imageAssetName: "card_romeo",
            courseIds: ["course_104_romeo_et_juliette_shakespeare"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1hr893",
            name: "Juliette",
            rarity: .commune,
            imageAssetName: "card_juliette",
            courseIds: ["course_104_romeo_et_juliette_shakespeare"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1ircss",
            name: "Aldous Huxley",
            rarity: .commune,
            imageAssetName: "card_aldous_huxley",
            courseIds: ["course_105_le_meilleur_des_mondes_aldous_huxley"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1jgt08",
            name: "Mary Shelley",
            rarity: .commune,
            imageAssetName: "card_mary_shelley",
            courseIds: ["course_106_frankenstein_mary_shelley"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1kk26z",
            name: "Victor Frankenstein",
            rarity: .commune,
            imageAssetName: "card_victor_frankenstein",
            courseIds: ["course_106_frankenstein_mary_shelley"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1l5owy",
            name: "Fiodor Dostoïevski",
            rarity: .epique,
            imageAssetName: "card_fiodor_dostoievski",
            courseIds: ["course_107_crime_et_chatiment_dostoievski"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1mgfv7",
            name: "Franz Kafka",
            rarity: .epique,
            imageAssetName: "card_franz_kafka",
            courseIds: ["course_108_le_proces_kafka", "course_116_la_metamorphose_kafka"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1nuijl",
            name: "Josef K.",
            rarity: .commune,
            imageAssetName: "card_josef_k",
            courseIds: ["course_108_le_proces_kafka"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1ony8e",
            name: "Miguel de Cervantès",
            rarity: .epique,
            imageAssetName: "card_miguel_de_cervantes",
            courseIds: ["course_109_don_quichotte_cervantes"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1p2dxy",
            name: "Don Quichotte",
            rarity: .epique,
            imageAssetName: "card_don_quichotte",
            courseIds: ["course_109_don_quichotte_cervantes"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1q1855",
            name: "John Steinbeck",
            rarity: .commune,
            imageAssetName: "card_john_steinbeck",
            courseIds: ["course_110_les_raisins_de_la_colere_steinbeck"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1r214f",
            name: "Harper Lee",
            rarity: .commune,
            imageAssetName: "card_harper_lee",
            courseIds: ["course_111_to_kill_a_mockingbird_harper_lee"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1s15gd",
            name: "F. Scott Fitzgerald",
            rarity: .commune,
            imageAssetName: "card_f_scott_fitzgerald",
            courseIds: ["course_112_le_grand_gatsby_fitzgerald"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1tdl2f",
            name: "Jay Gatsby",
            rarity: .commune,
            imageAssetName: "card_jay_gatsby",
            courseIds: ["course_112_le_grand_gatsby_fitzgerald"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1ujxuw",
            name: "J.R.R. Tolkien",
            rarity: .epique,
            imageAssetName: "card_j_r_r_tolkien",
            courseIds: ["course_113_le_seigneur_des_anneaux_tolkien"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1v8zp8",
            name: "Ray Bradbury",
            rarity: .commune,
            imageAssetName: "card_ray_bradbury",
            courseIds: ["course_114_fahrenheit_451_bradbury"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1wq2t4",
            name: "Gabriel García Márquez",
            rarity: .commune,
            imageAssetName: "card_gabriel_garcia_marquez",
            courseIds: ["course_115_cent_ans_de_solitude_garcia_marquez"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1x2is5",
            name: "Gregor Samsa",
            rarity: .commune,
            imageAssetName: "card_gregor_samsa",
            courseIds: ["course_116_la_metamorphose_kafka"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1ywoml",
            name: "Mikhaïl Boulgakov",
            rarity: .commune,
            imageAssetName: "card_mikhail_boulgakov",
            courseIds: ["course_117_le_maitre_et_marguerite_boulgakov"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_1zt86w",
            name: "Herman Melville",
            rarity: .commune,
            imageAssetName: "card_herman_melville",
            courseIds: ["course_118_moby_dick_melville"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_208lh7",
            name: "Antoine de Saint-Exupéry",
            rarity: .epique,
            imageAssetName: "card_antoine_de_saint_exupery",
            courseIds: ["course_119_le_petit_prince_saint_exupery"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_21ibna",
            name: "Le Petit Prince",
            rarity: .rare,
            imageAssetName: "card_le_petit_prince",
            courseIds: ["course_119_le_petit_prince_saint_exupery"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_22rdie",
            name: "Paulo Coelho",
            rarity: .commune,
            imageAssetName: "card_paulo_coelho",
            courseIds: ["course_120_l_alchimiste_paulo_coelho"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_23r9qk",
            name: "Claude Monet",
            rarity: .rare,
            imageAssetName: "card_claude_monet",
            courseIds: ["course_122_la_naissance_de_l_impressionnisme", "course_154_impression_soleil_levant_monet"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_24kuff",
            name: "Le Caravage",
            rarity: .commune,
            imageAssetName: "card_le_caravage",
            courseIds: ["course_123_le_caravage_et_le_clair_obscur"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_25p4or",
            name: "Rembrandt",
            rarity: .rare,
            imageAssetName: "card_rembrandt",
            courseIds: ["course_124_rembrandt_et_l_ecole_flamande"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_26sr6p",
            name: "Eugène Delacroix",
            rarity: .commune,
            imageAssetName: "card_eugene_delacroix",
            courseIds: ["course_125_le_romantisme_en_peinture_delacroix_geri", "course_152_la_liberte_guidant_le_peuple_delacroix"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_27yl4z",
            name: "Théodore Géricault",
            rarity: .commune,
            imageAssetName: "card_theodore_gericault",
            courseIds: ["course_125_le_romantisme_en_peinture_delacroix_geri"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_28ndlh",
            name: "Pablo Picasso",
            rarity: .rare,
            imageAssetName: "card_pablo_picasso",
            courseIds: ["course_126_le_cubisme_picasso_et_braque", "course_151_guernica_picasso", "course_156_les_demoiselles_d_avignon_picasso"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_29g3v9",
            name: "Georges Braque",
            rarity: .commune,
            imageAssetName: "card_georges_braque",
            courseIds: ["course_126_le_cubisme_picasso_et_braque"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2aen6y",
            name: "Salvador Dalí",
            rarity: .rare,
            imageAssetName: "card_salvador_dali",
            courseIds: ["course_127_le_surrealisme_dali_et_magritte", "course_157_la_persistance_de_la_memoire_dali"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2bvl75",
            name: "René Magritte",
            rarity: .commune,
            imageAssetName: "card_rene_magritte",
            courseIds: ["course_127_le_surrealisme_dali_et_magritte"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2cno65",
            name: "Edvard Munch",
            rarity: .commune,
            imageAssetName: "card_edvard_munch",
            courseIds: ["course_128_l_expressionnisme_munch_et_le_cri"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2dowsp",
            name: "Wassily Kandinsky",
            rarity: .commune,
            imageAssetName: "card_wassily_kandinsky",
            courseIds: ["course_129_l_art_abstrait_kandinsky_et_mondrian"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2e9f4f",
            name: "Piet Mondrian",
            rarity: .commune,
            imageAssetName: "card_piet_mondrian",
            courseIds: ["course_129_l_art_abstrait_kandinsky_et_mondrian"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2flyhe",
            name: "Andy Warhol",
            rarity: .rare,
            imageAssetName: "card_andy_warhol",
            courseIds: ["course_130_le_pop_art_warhol_et_lichtenstein"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2g1nqn",
            name: "Roy Lichtenstein",
            rarity: .commune,
            imageAssetName: "card_roy_lichtenstein",
            courseIds: ["course_130_le_pop_art_warhol_et_lichtenstein"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2hwava",
            name: "Bob Dylan",
            rarity: .rare,
            imageAssetName: "card_bob_dylan",
            courseIds: ["course_132_bob_dylan_et_la_folk_protest"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2irvrj",
            name: "Giuseppe Verdi",
            rarity: .commune,
            imageAssetName: "card_giuseppe_verdi",
            courseIds: ["course_134_l_opera_de_verdi"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2jbnzj",
            name: "Wolfgang Amadeus Mozart",
            rarity: .rare,
            imageAssetName: "card_wolfgang_amadeus_mozart",
            courseIds: ["course_135_mozart_enfant_prodige_et_vie_tragique"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2k3jnf",
            name: "Ludwig van Beethoven",
            rarity: .rare,
            imageAssetName: "card_ludwig_van_beethoven",
            courseIds: ["course_136_beethoven_genie_et_surdite"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2lm8xi",
            name: "Johann Sebastian Bach",
            rarity: .rare,
            imageAssetName: "card_johann_sebastian_bach",
            courseIds: ["course_138_bach_et_la_musique_baroque"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2mopkr",
            name: "Charlie Chaplin",
            rarity: .rare,
            imageAssetName: "card_charlie_chaplin",
            courseIds: ["course_142_charlie_chaplin_et_le_cinema_muet"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2ngk9s",
            name: "Orson Welles",
            rarity: .commune,
            imageAssetName: "card_orson_welles",
            courseIds: ["course_143_orson_welles_et_citizen_kane"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2ooou3",
            name: "Stanley Kubrick",
            rarity: .commune,
            imageAssetName: "card_stanley_kubrick",
            courseIds: ["course_145_kubrick_2001_l_odyssee_de_l_espace"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2pdkn8",
            name: "Alfred Hitchcock",
            rarity: .rare,
            imageAssetName: "card_alfred_hitchcock",
            courseIds: ["course_146_hitchcock_et_le_suspense"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2q0zwi",
            name: "Léonard de Vinci",
            rarity: .rare,
            imageAssetName: "card_leonard_de_vinci",
            courseIds: ["course_149_la_joconde"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2rb4ua",
            name: "Vincent Van Gogh",
            rarity: .rare,
            imageAssetName: "card_vincent_van_gogh",
            courseIds: ["course_150_la_nuit_etoilee_van_gogh"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2sgxy6",
            name: "Michel-Ange",
            rarity: .rare,
            imageAssetName: "card_michel_ange",
            courseIds: ["course_153_la_creation_d_adam_michel_ange"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2tuyyf",
            name: "Edward Hopper",
            rarity: .commune,
            imageAssetName: "card_edward_hopper",
            courseIds: ["course_155_nighthawks_hopper"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2u2262",
            name: "Zeus",
            rarity: .rare,
            imageAssetName: "card_zeus",
            courseIds: ["course_163_pandore_et_la_boite", "course_188_les_titans_vs_les_dieux_titanomachie"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2ve1ko",
            name: "Prométhée",
            rarity: .commune,
            imageAssetName: "card_promethee",
            courseIds: ["course_162_promethee_le_voleur_de_feu"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2wker6",
            name: "Pandore",
            rarity: .commune,
            imageAssetName: "card_pandore",
            courseIds: ["course_163_pandore_et_la_boite"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2xvfg9",
            name: "Déméter",
            rarity: .commune,
            imageAssetName: "card_demeter",
            courseIds: ["course_164_demeter_et_persephone_les_saisons"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2y8oag",
            name: "Perséphone",
            rarity: .commune,
            imageAssetName: "card_persephone",
            courseIds: ["course_164_demeter_et_persephone_les_saisons"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_2zid7i",
            name: "Orphée",
            rarity: .commune,
            imageAssetName: "card_orphee",
            courseIds: ["course_165_orphee_et_eurydice"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_306uzt",
            name: "Narcisse",
            rarity: .commune,
            imageAssetName: "card_narcisse",
            courseIds: ["course_166_narcisse_et_echo"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_31xp2u",
            name: "Icare",
            rarity: .commune,
            imageAssetName: "card_icare",
            courseIds: ["course_167_icare_et_dedale"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_322s83",
            name: "Sisyphe",
            rarity: .commune,
            imageAssetName: "card_sisyphe",
            courseIds: ["course_97_le_mythe_de_sisyphe_camus", "course_168_sisyphe_punition_eternelle"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_33k5d2",
            name: "Tantale",
            rarity: .commune,
            imageAssetName: "card_tantale",
            courseIds: ["course_169_tantale_et_son_supplice"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_348stm",
            name: "Méduse",
            rarity: .commune,
            imageAssetName: "card_meduse",
            courseIds: ["course_170_meduse_et_persee"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_350sh9",
            name: "Hercule",
            rarity: .rare,
            imageAssetName: "card_hercule",
            courseIds: ["course_171_hercule_et_ses_12_travaux"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_36i31c",
            name: "Thésée",
            rarity: .commune,
            imageAssetName: "card_thesee",
            courseIds: ["course_172_thesee_et_le_minotaure"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_37f9ct",
            name: "Jason",
            rarity: .commune,
            imageAssetName: "card_jason",
            courseIds: ["course_175_jason_et_la_toison_d_or"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_38ftpe",
            name: "Achille",
            rarity: .commune,
            imageAssetName: "card_achille",
            courseIds: ["course_176_achille_le_talon_et_l_invulnerabilite"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_39pbrr",
            name: "Thor",
            rarity: .rare,
            imageAssetName: "card_thor",
            courseIds: ["course_180_thor_et_loki_mythologie_nordique"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_3ai3i6",
            name: "Loki",
            rarity: .commune,
            imageAssetName: "card_loki",
            courseIds: ["course_180_thor_et_loki_mythologie_nordique"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_3bvoe4",
            name: "Osiris",
            rarity: .commune,
            imageAssetName: "card_osiris",
            courseIds: ["course_182_osiris_et_set_mythologie_egyptienne"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_3ctx3u",
            name: "Gilgamesh",
            rarity: .commune,
            imageAssetName: "card_gilgamesh",
            courseIds: ["course_183_gilgamesh_le_premier_heros_de_l_histoire"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_3dhjhk",
            name: "Romulus",
            rarity: .commune,
            imageAssetName: "card_romulus",
            courseIds: ["course_184_romulus_et_remus_la_fondation_de_rome"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_3ekptk",
            name: "Rémus",
            rarity: .commune,
            imageAssetName: "card_remus",
            courseIds: ["course_184_romulus_et_remus_la_fondation_de_rome"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_3fvao3",
            name: "Odin",
            rarity: .commune,
            imageAssetName: "card_odin",
            courseIds: ["course_186_les_valkyries_et_le_valhalla"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_3go8r8",
            name: "Dionysos",
            rarity: .commune,
            imageAssetName: "card_dionysos",
            courseIds: ["course_189_dionysos_le_dieu_du_vin_et_de_l_exces"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_3hcarf",
            name: "Énée",
            rarity: .commune,
            imageAssetName: "card_enee",
            courseIds: ["course_191_enee_et_la_fondation_de_rome_virgile"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_3ib4ze",
            name: "Quetzalcoatl",
            rarity: .commune,
            imageAssetName: "card_quetzalcoatl",
            courseIds: ["course_193_quetzalcoatl"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_3jybz6",
            name: "Lancelot",
            rarity: .commune,
            imageAssetName: "card_lancelot",
            courseIds: ["course_195_lancelot_guenievre_et_la_table_ronde"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_3krbi6",
            name: "Merlin",
            rarity: .rare,
            imageAssetName: "card_merlin",
            courseIds: ["course_196_merlin_l_enchanteur"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_3ln0h0",
            name: "Shéhérazade",
            rarity: .commune,
            imageAssetName: "card_sheherazade",
            courseIds: ["course_197_les_mille_et_une_nuits_sheherazade"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_3md901",
            name: "Sindbad le marin",
            rarity: .commune,
            imageAssetName: "card_sindbad_le_marin",
            courseIds: ["course_198_sindbad_le_marin"]
        ),
        CollectibleCard(
            id: "g_mpzyw5pq_3nfhpx",
            name: "Vladimir Poutine",
            rarity: .rare,
            imageAssetName: "card_vladimir_poutine",
            courseIds: ["course_209_la_russie_de_poutine"]
        )
    ]

    static let cardsByCourseId: [String: [CollectibleCard]] = {
        var out: [String: [CollectibleCard]] = [:]
        for card in allCards {
            for courseId in card.courseIds {
                out[courseId, default: []].append(card)
            }
        }
        return out
    }()
}
