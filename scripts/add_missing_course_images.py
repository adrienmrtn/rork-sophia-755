#!/usr/bin/env python3
"""
Add a themed illustration to courses that had NO inline image at all after the V2
migration, even though a matching image exists in the bundle (e.g. the black hole
course had `black_hole_accretion_disk_galaxy` available but referenced no image).

Inserts one image block (real bundled asset + short caption) after the first
paragraph of the chosen section, in both the source and bundled V2 JSON.
"""
import json
import os

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_DIR = os.path.join(REPO, "content/courses/fr")
BUILT_DIR = os.path.join(REPO, "ios/Sophia/Resources/CoursesV2")
IMAGES_DIR = os.path.join(REPO, "ios/Sophia/CourseImages")

# course_id -> (section_index, image_slug, caption)
PLAN = {
    "course_44_pourquoi_l_eau_de_mer_est_elle_salee": (1, "ocean_sea_salt_evaporation", "Marais salants : l'évaporation concentre le sel dissous dans l'eau de mer."),
    "course_45_pourquoi_y_a_t_il_des_saisons": (1, "earth_summer_winter_seasons_illustration", "L'inclinaison de l'axe de la Terre explique le cycle des saisons."),
    "course_46_comment_les_avions_volent_ils": (1, "airplane_wing_cross_section_flight", "Le profil de l'aile crée la portance qui soulève l'avion."),
    "course_61_le_big_bang": (1, "big_bang_universe_expansion_galaxies", "L'expansion de l'Univers depuis le Big Bang."),
    "course_62_pourquoi_les_volcans_entrent_ils_en_erup": (1, "volcano_eruption_lava", "Une éruption : la remontée du magma jusqu'à la surface."),
    "course_63_comment_se_forment_les_tremblements_de_t": (1, "earthquake_collapsed_buildings_urban", "Les séismes libèrent d'un coup l'énergie accumulée le long des failles."),
    "course_64_la_catastrophe_de_tchernobyl_1986": (1, "pripyat_abandoned_city_chernobyl", "Le dôme de confinement du réacteur n°4, entouré par les immeubles abandonnés de Pripyat."),
    "course_66_y_a_t_il_de_la_vie_ailleurs_dans_l_unive": (1, "radio_telescope_seti", "Les radiotélescopes scrutent le ciel, à l'écoute d'un éventuel signal."),
    "course_67_qu_est_ce_qu_un_trou_noir": (1, "black_hole_accretion_disk_galaxy", "Un trou noir entouré de son disque d'accrétion incandescent."),
    "course_68_la_theorie_de_la_relativite_pour_tous": (1, "albert_einstein_portrait_princeton", "Albert Einstein, auteur de la théorie de la relativité."),
    "course_71_qu_est_ce_que_l_effet_de_serre_vraiment": (1, "factory_chimneys_greenhouse_gas_emissions", "Les émissions industrielles renforcent l'effet de serre."),
    "course_72_pourquoi_dort_on": (1, "sleeping_person_bedroom_night", "Le sommeil, indispensable à la récupération du cerveau et du corps."),
    "course_73_comment_le_cerveau_stocke_t_il_les_souve": (1, "hippocampus_memory_brain", "L'hippocampe joue un rôle central dans la formation des souvenirs."),
    "course_75_la_photosynthese_expliquee_simplement": (1, "leaf_photosynthesis_sunlight_chloroplasts", "Les feuilles captent la lumière du Soleil pour la photosynthèse."),
    "course_76_pourquoi_les_feuilles_changent_elles_de": (1, "leaf_color_change_autumn_chlorophyll", "En automne, la chlorophylle disparaît et révèle les couleurs des feuilles."),
    "course_77_qu_est_ce_que_la_matiere_noire": (1, "dark_matter_galaxy_cluster", "La matière noire trahit sa présence par son effet gravitationnel sur les amas de galaxies."),
    "course_78_comment_fonctionne_l_electricite_dans_no": (1, "neuron_electrical_signal_brain", "Les neurones communiquent par de brèves impulsions électriques."),
    "course_234_la_securite_alimentaire_mondiale": (1, "famine_sub_saharan_africa_malnutrition_child", "La faim touche encore des centaines de millions de personnes, surtout en Afrique subsaharienne."),
    "course_65_pourquoi_la_lune_ne_tombe_t_elle_pas_sur": (1, "newton_cannonball_orbit_thought_experiment", "L'expérience de pensée du boulet de canon de Newton : la clé pour comprendre l'orbite."),
    "course_74_pourquoi_certaines_especes_sont_elles_im": (1, "chromosome_dna_telomere_aging_cell", "Les télomères, aux extrémités des chromosomes, raccourcissent à chaque division cellulaire."),
    "course_80_pourquoi_les_saisons_existent_sur_d_autr": (1, "uranus_planet_nasa", "Uranus, inclinée à environ 98°, connaît des saisons extrêmes de 42 ans."),
}

# Courses that still have no inline image at all: no existing bundled asset was found to be
# both thematically accurate AND visually correct (see the Chernobyl fix above for what
# happens when a "close enough" filename match doesn't actually depict the right thing).
# Left as cover-only until better source images are curated.
STILL_MISSING_NO_GOOD_MATCH = [
    "course_4_le_couronnement_de_charlemagne_800",       # no image of Leo III's coronation / Aachen available
    "course_34_la_decolonisation_panorama_1945_1975",    # no decolonization-specific image available
    "course_79_pourquoi_certains_sons_nous_donnent_ils", # no strong "musical frisson" match available
]


def load(path):
    with open(path, encoding="utf-8-sig") as f:
        return json.load(f)


def insert_into(path, section_idx, slug, caption):
    d = load(path)
    sections = d.get("sections", [])
    if section_idx >= len(sections):
        section_idx = len(sections) - 1
    if section_idx < 0:
        return False
    blocks = sections[section_idx].get("blocks", [])
    block = {"type": "image", "asset": slug, "ratio": "auto", "caption": caption}
    # Insert right after the first paragraph of the section (keeps any trailing takeaway last).
    insert_at = None
    for i, b in enumerate(blocks):
        if b.get("type") == "paragraph":
            insert_at = i + 1
            break
    if insert_at is None:
        # no paragraph: put it after a heading, else at the start
        insert_at = 1 if blocks and blocks[0].get("type") == "heading" else 0
    blocks.insert(insert_at, block)
    sections[section_idx]["blocks"] = blocks
    with open(path, "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False, indent=2)
        f.write("\n")
    return True


def main():
    imgs = set(os.path.splitext(x)[0] for x in os.listdir(IMAGES_DIR) if x.endswith(".jpg"))
    for cid, (sec, slug, caption) in PLAN.items():
        if slug not in imgs:
            raise SystemExit(f"ERROR: unknown image slug '{slug}' for {cid}")
    n = 0
    for cid, (sec, slug, caption) in PLAN.items():
        for base, suffix in ((SRC_DIR, ".json"), (BUILT_DIR, ".fr.json")):
            path = os.path.join(base, cid + suffix)
            if os.path.exists(path):
                insert_into(path, sec, slug, caption)
        n += 1
    print(f"added images to {n} courses")


if __name__ == "__main__":
    main()
