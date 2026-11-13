// Panorama sets: one wide canvas (440 pt per panel) so that tilted phones and characters can
// sit across two neighbouring App Store screenshots. Coordinates are points on the wide canvas.
const P = (i) => 440 * i;          // left edge of panel i
const mid = (i) => 440 * i + 220;  // centre of panel i

const COPY_FR = {
  hero: ["Moins de scroll, plus de culture", "La culture générale en 10 minutes par jour"],
  home: ["Un cours par jour", "Choisi pour vous, lu en 5 minutes"],
  reader: ["Courts, clairs, illustrés", "Des cours qui vont à l’essentiel"],
  quiz: ["Un quiz à chaque cours", "Pour retenir ce que vous venez de lire"],
  blocker: ["Anti-scroll", "Vos apps se débloquent après un cours"],
  duels: ["Duels", "Défiez vos amis en culture générale"],
  explore: ["Plus de 300 cours", "Histoire, sciences, art, littérature…"],
  profile: ["Votre série", "Un peu plus de culture chaque jour"],
  leagues: ["30 ligues à gravir", "D’Ésope à Einstein"],
  time: ["Reprenez votre temps", "Moins d’écran, plus d’idées"],
};

const order = ["home", "reader", "quiz", "blocker", "duels", "explore", "profile"];

const PANOS = {
  // Cream panels, phones leaning one way then the other at uneven heights, a character
  // standing on every seam between two screenshots.
  penche: {
    dir: "-penche", copy: { "fr-FR": COPY_FR },
    panels: [{ theme: "coral", logo: true, text: "hero", cls: "big" }, ...order.map((s) => ({ theme: "cream", text: s }))],
    phones: order.map((s, k) => ({ screen: s, cx: mid(k + 1) + [6, -8, 4, -4, 8, -6, 2][k], cy: [612, 640, 606, 636, 610, 642, 614][k], s: 0.74, r: [-4, 3.5, -3, 4, -3.5, 3, -4][k] })),
    people: [
      { name: "lying", x: 160, b: 925, h: 285, r: -3 },
      { name: "headphones", x: 250, b: 640, h: 255, r: 3 },
      { name: "reader_walking", x: P(1) + 6, b: 962, h: 270 },
      { name: "reader_sitting", x: P(2), b: 966, h: 185 },
      { name: "thinker", x: P(3), b: 962, h: 225 },
      { name: "phone_away", x: P(4), b: 968, h: 215 },
      { name: "trophy", x: P(5), b: 962, h: 215 },
      { name: "books", x: P(6), b: 962, h: 230 },
      { name: "waving", x: P(7), b: 962, h: 245 },
    ],
  },
  // A colour per panel, bigger phones tilted harder and running off the bottom.
  couleurs: {
    dir: "-couleurs", copy: { "fr-FR": COPY_FR },
    panels: [{ theme: "coral", logo: true, text: "hero", cls: "big" },
      ...order.map((s, k) => ({ theme: ["cream", "navy", "sun", "pink", "blue", "cream", "sun"][k], text: s }))],
    phones: order.map((s, k) => ({ screen: s, cx: mid(k + 1) + [8, -8, 8, -8, 8, -8, 6][k], cy: [668, 690, 664, 692, 668, 690, 666][k], s: 0.77, r: [7, -6, 6, -7, 6, -6, 7][k] })),
    people: [
      { name: "headphones", x: 120, b: 940, h: 330, r: -2 },
      { name: "reader_walking", x: 330, b: 950, h: 360 },
      { name: "reader_sitting", x: P(2) + 6, b: 968, h: 200 },
      { name: "idea", x: P(3), b: 975, h: 240 },
      { name: "phone_away", x: P(4) + 4, b: 972, h: 255, flip: true },
      { name: "trophy", x: P(5), b: 965, h: 250 },
      { name: "books", x: P(6), b: 965, h: 265 },
      { name: "waving", x: P(7) - 4, b: 965, h: 280, flip: true },
    ],
  },
  // Ten panels in five pairs: one big phone sits across the seam of each pair, with a title
  // on each side and a character in each free corner.
  duo: {
    dir: "-duo", copy: { "fr-FR": COPY_FR },
    panels: [
      { theme: "coral", logo: true, text: "hero", cls: "big" }, { theme: "coral", text: "home", cls: "right" },
      { theme: "cream", text: "reader" }, { theme: "cream", text: "explore", cls: "right" },
      { theme: "sun", text: "quiz" }, { theme: "sun", text: "profile", cls: "right" },
      { theme: "navy", text: "duels" }, { theme: "navy", text: "leagues", cls: "right" },
      { theme: "cream", text: "blocker" }, { theme: "cream", text: "time", cls: "right" },
    ],
    phones: ["home", "reader", "quiz", "duels", "blocker"].map((s, k) => ({ screen: s, cx: P(2 * k + 1) + [26, -6, 6, -6, 6][k], cy: [742, 650, 656, 648, 654][k], s: 0.84, r: [6, -5, 5, -6, 5][k] })),
    people: [
      { name: "lying", x: 118, b: 940, h: 200, r: -2 },
      { name: "reader_walking", x: P(1) + 320, b: 962, h: 330 },
      { name: "reader_sitting", x: P(2) + 118, b: 950, h: 225 },
      { name: "books", x: P(3) + 318, b: 962, h: 300 },
      { name: "thinker", x: P(4) + 112, b: 962, h: 290 },
      { name: "waving", x: P(5) + 322, b: 962, h: 310 },
      { name: "trophy", x: P(6) + 116, b: 962, h: 270 },
      { name: "headphones", x: P(7) + 330, b: 962, h: 330 },
      { name: "phone_away", x: P(8) + 112, b: 968, h: 270 },
      { name: "idea", x: P(9) + 318, b: 975, h: 260, flip: true },
    ],
  },
  // Brand-colour opening (characters, big logo, speech bubble), a second blue panel with the
  // promise, then pale panels: centred title and subtitle, upright phone in a thick blue frame
  // running off the bottom, and a wall of real course covers to close.
  vitrine: {
    dir: "-vitrine", copy: { "fr-FR": Object.assign({}, COPY_FR, {
      hero: ["Moins de scroll,<br>plus de culture"],
      promise: ["Se cultiver en <b>10 min</b><br>par jour"],
      home: ["Un cours par jour", "Choisi pour vous"],
      reader: ["Des cours courts<br>et illustrés", "Qui vont à l’essentiel"],
      quiz: ["Un quiz<br>à chaque cours", "Pour retenir ce que vous lisez"],
      duels: ["Défiez vos amis<br>en duel", "La culture générale, en match"],
      blocker: ["Bloquez le scroll", "Vos apps se débloquent après un cours"],
      explore: ["Tous les savoirs", "Histoire, sciences, art, littérature…"],
      profile: ["Suivez votre série", "Un peu plus de culture chaque jour"],
      wall: ["Plus de 300 cours<br>illustrés"],
    }) },
    panels: [
      { theme: "blue", logo: "big", bubble: "hero" },
      { theme: "blue", text: "promise", cls: "center" },
      ...["reader", "quiz", "duels", "blocker", "explore", "profile"].map((s) => ({ theme: "pale", text: s, cls: "center" })),
      { theme: "pale", text: "wall", cls: "center", grid: [
        ["eiffel_tower_1889_universal_exhibition", "la_joconde", "apollo_11_aldrin_us_flag_lunar_module_1969", "achille_le_talon_et_l_invulnerabilite"],
        ["l_expressionnisme_munch_et_le_cri", "la_nuit_etoilee_van_gogh", "crab_nebula_supernova_remnant_hubble", "aesop_fox_kylix_vatican_470_bc"],
        ["giza_pyramids_khufu_khafre_menkaure_wide_view", "dna_double_helix_3d_render_blue", "la_guerre_de_troie_et_le_cheval_de_bois", "hms_agamemnon_laying_atlantic_telegraph_cable_1858"],
        ["l_odyssee_homere", "beethoven_genie_et_surdite", "comment_se_forment_les_eclairs", "la_decouverte_de_l_amerique_1492"],
        ["la_decouverte_du_micro_ondes", "icare_et_dedale", "fresh_coriander_cilantro_bunch_leaves", "la_montee_des_eaux"],
      ] },
    ],
    phones: ["home", "reader", "quiz", "duels", "blocker", "explore", "profile"].map((s, k) => ({
      screen: s, cx: mid(k + 1), cy: 232 + (956 * 0.78 + 21) / 2, s: 0.78,
      frame: k === 0 ? "#cdd9f5" : "#2e62c4", band: k === 0 ? "#e9effb" : "#dbe5f8" })),
    people: [
      { name: "thinker", x: 112, b: 332, h: 262 },
      { name: "headphones", x: 345, b: 352, h: 292, r: 3 },
      { name: "lying", x: 150, b: 930, h: 235, r: -2 },
      { name: "reader_walking", x: P(1) - 22, b: 962, h: 275 },
      { name: "phone_away", x: P(5) + 372, b: 975, h: 215, flip: true },
      { name: "waving", x: P(7) + 398, b: 966, h: 210, flip: true },
    ],
    extras: [
      { x: P(4) + 8, y: 420, html: '<img src="../../../ios/Sophia/Assets.xcassets/avatar_49.imageset/avatar_49.jpg" style="width:96px;height:96px;border-radius:50%;border:5px solid #fff;box-shadow:0 0 0 4px #2e62c4">' },
      { x: P(4) + 336, y: 560, html: '<img src="../../../ios/Sophia/Assets.xcassets/avatar_42.imageset/avatar_42.jpg" style="width:96px;height:96px;border-radius:50%;border:5px solid #fff;box-shadow:0 0 0 4px #dc6048">' },
    ],
  },
};
if (typeof module !== "undefined") module.exports = { PANOS };
