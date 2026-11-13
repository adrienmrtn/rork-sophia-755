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
};
if (typeof module !== "undefined") module.exports = { PANOS };
