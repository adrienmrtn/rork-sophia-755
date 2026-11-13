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

// Real course covers for the catalogue wall (ios/Sophia/CourseImages), five rows of four.
const WALL = [
        ["eiffel_tower_1889_universal_exhibition", "la_joconde", "apollo_11_aldrin_us_flag_lunar_module_1969", "achille_le_talon_et_l_invulnerabilite"],
        ["l_expressionnisme_munch_et_le_cri", "la_nuit_etoilee_van_gogh", "crab_nebula_supernova_remnant_hubble", "aesop_fox_kylix_vatican_470_bc"],
        ["giza_pyramids_khufu_khafre_menkaure_wide_view", "dna_double_helix_3d_render_blue", "la_guerre_de_troie_et_le_cheval_de_bois", "hms_agamemnon_laying_atlantic_telegraph_cable_1858"],
        ["l_odyssee_homere", "beethoven_genie_et_surdite", "comment_se_forment_les_eclairs", "la_decouverte_de_l_amerique_1492"],
        ["la_decouverte_du_micro_ondes", "icare_et_dedale", "fresh_coriander_cilantro_bunch_leaves", "la_montee_des_eaux"],
      ];

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
      hero: ["Scrollez moins.<br>Sachez plus."],
      promise: ["Plus malin en <b>10\u00a0min</b><br>par jour"],
      reader: ["Comment naît<br>un éclair\u00a0?", "La réponse en 5\u00a0minutes, images à l’appui"],
      quiz: ["Lu, c’est bien.<br>Retenu, c’est mieux.", "Un quiz à la fin de chaque cours"],
      duels: ["Battez vos amis<br>à plate couture", "Des duels de culture générale"],
      blocker: ["Pas de cours,<br>pas de scroll", "Vos apps restent bloquées jusqu’à votre cours du jour"],
      explore: ["De Kafka<br>aux trous noirs", "Histoire, sciences, art, mythologie…"],
      profile: ["24 jours d’affilée.<br>Et vous\u00a0?", "Gardez votre série en vie"],
      wall: ["Plus de 300 cours.<br>Zéro ennui."],
      love: ["Les gens adorent<br>Sophia"],
      // Real five-star reviews from the French App Store (public RSS feed, read on 13 Nov 2026),
      // quoted as written; « […] » marks a cut. Do not edit the wording or add invented ones.
      reviews: [
        ["«\u00a0Une appli simple d’utilisation et hyper pratique pour se cultiver au quotidien\u00a0!\u00a0»", "gab24738 · App Store"],
        ["«\u00a0Meilleur appli pour devenir plus cultivé et en apprendre plus sur tout mais de manière drôle et pas «\u00a0scolaire\u00a0». […] Bref, j’adore\u00a0»", "Leo•go · App Store"],
        ["«\u00a0Difficile de se lasser face à la pléthore de cours et d’informations nouvelles à retenir et à apprécier.\u00a0»", "Simon B. · App Store"],
      ],
    }) },
    panels: [
      { theme: "blue", logo: "big", bubble: "hero" },
      { theme: "blue", text: "promise", cls: "center" },
      ...["reader", "quiz", "duels", "blocker", "explore", "profile"].map((s) => ({ theme: "pale", text: s, cls: "center" })),
      { theme: "pale", text: "wall", cls: "center", grid: WALL },
      { theme: "pale", text: "love", cls: "center", reviews: "reviews" },
    ],
    phones: ["home", "reader", "quiz", "duels", "blocker", "explore", "profile"].map((s, k) => ({
      screen: s, cx: mid(k + 1), cy: 232 + (956 * 0.78 + 21) / 2, s: 0.78,
      frame: k === 0 ? "#cdd9f5" : "#2e62c4", band: k === 0 ? "#e9effb" : "#dbe5f8" })),
    people: [
      // opening collage
      { name: "prop_saturn", x: 232, b: 118, h: 118, r: -12 },
      { name: "prop_portrait", x: 92, b: 262, h: 250, r: -9 },
      { name: "prop_bust", x: 356, b: 318, h: 262, r: 7 },
      { name: "prop_rocket", x: 214, b: 338, h: 176, r: 14 },
      { name: "prop_mask", x: 84, b: 356, h: 78, r: -7 },
      { name: "prop_telescope", x: 92, b: 790, h: 150, r: -4 },
      { name: "prop_globe", x: 318, b: 800, h: 168, r: 9 },
      { name: "lying", x: 146, b: 968, h: 205, r: -2 },
      { name: "prop_amphora", x: 300, b: 1010, h: 215, r: -7 },
      { name: "reader_walking", x: P(1) - 8, b: 962, h: 265, z: 4 },
      { name: "phone_away", x: P(5) + 372, b: 975, h: 215, flip: true },
      { name: "waving", x: P(7) + 398, b: 966, h: 210, flip: true },
      { name: "headphones", x: P(9) + 88, b: 975, h: 235, r: -3 },
      { name: "trophy", x: P(9) + 250, b: 985, h: 200 },
    ],
    extras: [
      { x: P(9) + 22, y: 96, html: '<svg width="40" height="40" viewBox="0 0 24 22" style="transform:rotate(-12deg)"><path fill="#f4a3c4" d="M12 21C5 16 1 12 1 7.500 1 4 3.700 1.500 7 1.500c2 0 3.800 1 5 2.700 1.200-1.700 3-2.700 5-2.700 3.300 0 6 2.500 6 6 0 4.500-4 8.500-11 13.500Z"/></svg>' },
      { x: P(9) + 372, y: 62, html: '<svg width="54" height="54" viewBox="0 0 24 22" style="transform:rotate(14deg)"><path fill="#f4a3c4" d="M12 21C5 16 1 12 1 7.500 1 4 3.700 1.500 7 1.500c2 0 3.800 1 5 2.700 1.200-1.700 3-2.700 5-2.700 3.300 0 6 2.500 6 6 0 4.500-4 8.500-11 13.500Z"/></svg>' },
      { x: P(9) + 384, y: 880, html: '<svg width="44" height="44" viewBox="0 0 24 22" style="transform:rotate(10deg)"><path fill="#f4a3c4" d="M12 21C5 16 1 12 1 7.500 1 4 3.700 1.500 7 1.500c2 0 3.800 1 5 2.700 1.200-1.700 3-2.700 5-2.700 3.300 0 6 2.500 6 6 0 4.500-4 8.500-11 13.500Z"/></svg>' },
      { x: 150, y: 150, html: '<svg width="26" height="26" viewBox="0 0 24 24"><path fill="#fef5e9" d="M12 0c1 7 4 10 12 12-8 2-11 5-12 12-1-7-4-10-12-12 8-2 11-5 12-12Z"/></svg>' },
      { x: 300, y: 60, html: '<svg width="18" height="18" viewBox="0 0 24 24"><path fill="#f2b134" d="M12 0c1 7 4 10 12 12-8 2-11 5-12 12-1-7-4-10-12-12 8-2 11-5 12-12Z"/></svg>' },
      { x: 330, y: 470, html: '<svg width="20" height="20" viewBox="0 0 24 24"><path fill="#f2b134" d="M12 0c1 7 4 10 12 12-8 2-11 5-12 12-1-7-4-10-12-12 8-2 11-5 12-12Z"/></svg>' },
      { x: 392, y: 360, html: '<svg width="24" height="24" viewBox="0 0 24 24"><path fill="#fef5e9" d="M12 0c1 7 4 10 12 12-8 2-11 5-12 12-1-7-4-10-12-12 8-2 11-5 12-12Z"/></svg>' },
      { x: 196, y: 660, html: '<svg width="22" height="22" viewBox="0 0 24 24"><path fill="#fef5e9" d="M12 0c1 7 4 10 12 12-8 2-11 5-12 12-1-7-4-10-12-12 8-2 11-5 12-12Z"/></svg>' },
      { x: 400, y: 640, html: '<svg width="16" height="16" viewBox="0 0 24 24"><path fill="#f2b134" d="M12 0c1 7 4 10 12 12-8 2-11 5-12 12-1-7-4-10-12-12 8-2 11-5 12-12Z"/></svg>' },
      { x: 30, y: 640, html: '<svg width="14" height="14" viewBox="0 0 24 24"><path fill="#fef5e9" d="M12 0c1 7 4 10 12 12-8 2-11 5-12 12-1-7-4-10-12-12 8-2 11-5 12-12Z"/></svg>' },
      { x: 470, y: 150, html: '<svg width="16" height="16" viewBox="0 0 24 24"><path fill="#fef5e9" d="M12 0c1 7 4 10 12 12-8 2-11 5-12 12-1-7-4-10-12-12 8-2 11-5 12-12Z"/></svg>' },
      { x: P(4) + 8, y: 420, html: '<img src="../../../ios/Sophia/Assets.xcassets/avatar_49.imageset/avatar_49.jpg" style="width:96px;height:96px;border-radius:50%;border:5px solid #fff;box-shadow:0 0 0 4px #2e62c4">' },
      { x: P(4) + 336, y: 560, html: '<img src="../../../ios/Sophia/Assets.xcassets/avatar_42.imageset/avatar_42.jpg" style="width:96px;height:96px;border-radius:50%;border:5px solid #fff;box-shadow:0 0 0 4px #dc6048">' },
    ],
  },
  // English set, same look as "vitrine" with a calmer opening on cream (colour logo) and the
  // order asked for: promise, open course, catalogue wall and reviews early, then the features.
  showcase: {
    dir: "-showcase", lang: "en", titles: "loud", copy: { "en-US": {
      hero: ["Scroll less.<br>Know more."],
      home: ["Get smarter<br>every day", "One course a day, picked for you"],
      reader: ["Learn in<br><b>10\u00a0minutes</b>", "Short courses, straight to the point"],
      wall: ["300+ courses.<br>Zero boredom."],
      love: ["People love<br>Sophia"],
      // Real App Store reviews of Sophia written in English (public customer-reviews feeds of the
      // French and UK stores, read on 13 Nov 2026), quoted as written, with their real star
      // rating; “[…]” marks a cut. Do not edit the wording or add invented ones.
      reviews: [
        ["“Exactly what I’ve been looking for to expand my knowledge. Great app, simple & easy to use, no hassle. Amazing work.”", "Alex K. · App Store", 5],
        ["“This app is very intuitive and enables me to learn interesting facts, have a broader vision of what’s happening in today’s world. […]”", "Merlin.G · App Store", 5],
        ["“I think this is great. I like that the courses are short and written by people who are trained in their fields rather than using AI. […]”", "Hsbyznsjsj · App Store", 4],
      ],
      quiz: ["Read it.<br>Remember it.", "A quiz at the end of every course"],
      duels: ["Beat your friends", "General-knowledge duels, head to head"],
      blocker: ["No course,<br>no scrolling", "Your apps stay locked until today’s course"],
      profs: ["Written by<br>professors", "Real scholars, real credentials"],
      // Real authors and their credentials from content/authors.json; the portraits are the
      // site's illustrated avatars, deliberately not their real faces.
      authors: [
        ["Angela Bouma", "History professor, Barton Community College", "avatar_17"],
        ["Mark N. Hoffman", "PhD in Political Science, professor at Saint Xavier University", "avatar_08"],
        ["Stacy Jankowski", "PhD in Biomedical Science, Boston University", "avatar_05"],
        ["Simon Lea", "PhD in Philosophy, independent scholar", "avatar_02"],
      ],
    } },
    panels: [
      { theme: "cream", logo: "brand", bubble: "hero" },
      { theme: "blue", text: "home", cls: "center" },
      { theme: "pale", text: "reader", cls: "center" },
      { theme: "pale", text: "wall", cls: "center", grid: WALL },
      { theme: "pale", text: "love", cls: "center", reviews: "reviews" },
      { theme: "pale", text: "quiz", cls: "center" },
      { theme: "pale", text: "duels", cls: "center" },
      { theme: "pale", text: "blocker", cls: "center" },
      { theme: "pale", text: "profs", cls: "center", profs: "authors" },
    ],
    phones: [["home", 1], ["reader", 2], ["quiz", 5], ["duels", 6], ["blocker", 7]].map(([s, i]) => ({
      screen: s, cx: mid(i), cy: 232 + (956 * 0.78 + 21) / 2, s: 0.78,
      frame: i === 1 ? "#cdd9f5" : "#2e62c4", band: i === 1 ? "#e9effb" : "#dbe5f8" })),
    people: [
      // opening panel: logo, bubble, and the before / after pair (a boy slumped over his phone, a girl reading)
      // sitting on the bottom edge, both on
      // the same green floor (the band in `extras`, the colour of the "before" drawing's own floor)
      { name: "boy_before", x: 112, b: 956, h: 232, z: 1 },
      { name: "girl_after", x: 322, b: 943, h: 216, z: 1 },
      { name: "trophy", x: P(4) + 220, b: 1000, h: 185 },
      { name: "idea", x: P(8) + 330, b: 990, h: 240, flip: true },
      { name: "books", x: P(8) + 96, b: 975, h: 235 },
    ],
    extras: [
      { x: 0, y: 931.5, z: 0, html: '<div style="width:440px;height:24.5px;background:#1e8e73"></div>' },
      { x: P(4) + 22, y: 96, html: '<svg width="40" height="40" viewBox="0 0 24 22" style="transform:rotate(-12deg)"><path fill="#f4a3c4" d="M12 21C5 16 1 12 1 7.500 1 4 3.700 1.500 7 1.500c2 0 3.800 1 5 2.700 1.200-1.700 3-2.700 5-2.700 3.300 0 6 2.500 6 6 0 4.500-4 8.500-11 13.500Z"/></svg>' },
      { x: P(4) + 372, y: 62, html: '<svg width="54" height="54" viewBox="0 0 24 22" style="transform:rotate(14deg)"><path fill="#f4a3c4" d="M12 21C5 16 1 12 1 7.500 1 4 3.700 1.500 7 1.500c2 0 3.800 1 5 2.700 1.200-1.700 3-2.700 5-2.700 3.300 0 6 2.500 6 6 0 4.500-4 8.500-11 13.500Z"/></svg>' },
      { x: P(4) + 384, y: 880, html: '<svg width="44" height="44" viewBox="0 0 24 22" style="transform:rotate(10deg)"><path fill="#f4a3c4" d="M12 21C5 16 1 12 1 7.500 1 4 3.700 1.500 7 1.500c2 0 3.800 1 5 2.700 1.200-1.700 3-2.700 5-2.700 3.300 0 6 2.500 6 6 0 4.500-4 8.500-11 13.500Z"/></svg>' },
      { x: P(6) + 8, y: 420, html: '<img src="../../../ios/Sophia/Assets.xcassets/avatar_49.imageset/avatar_49.jpg" style="width:96px;height:96px;border-radius:50%;border:5px solid #fff;box-shadow:0 0 0 4px #2e62c4">' },
      { x: P(6) + 336, y: 560, html: '<img src="../../../ios/Sophia/Assets.xcassets/avatar_42.imageset/avatar_42.jpg" style="width:96px;height:96px;border-radius:50%;border:5px solid #fff;box-shadow:0 0 0 4px #dc6048">' },
    ],
  },
};
if (typeof module !== "undefined") module.exports = { PANOS };
