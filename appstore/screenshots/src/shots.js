// The App Store set: which screens, in which order, with which headline.
// <em> marks the highlighted words. One entry per locale in COPY; screens are in src/screens/.
const DEVICES = {
  // 6.9" iPhone: 1320 x 2868 px = 440 x 956 pt at 3x. App Store Connect scales it down
  // for the smaller iPhone sizes, so this is the only iPhone size that has to be uploaded.
  "iphone-6.9": {
    width: 440, height: 956, scale: 3,
    layout: {
      "head-top": "56px", "head-h": "152px", "head-pad": "26px", "head-size": "41px",
      "phone-top": "226px", "s": "0.72", "bezel": "9px",
    },
  },
};

const SHOTS = [
  { screen: "home", theme: "cream" },
  { screen: "reader", theme: "blue" },
  { screen: "quiz", theme: "cream" },
  { screen: "blocker", theme: "pink" },
  { screen: "duels", theme: "navy" },
  { screen: "explore", theme: "cream", layout: { "head-size": "36px" } },
  { screen: "profile", theme: "sun" },
];

const COPY = {
  "fr-FR": {
    home: "Se cultiver en<br><em>10 minutes par jour</em>",
    reader: "Des cours courts,<br><em>clairs et illustrés</em>",
    quiz: "Un quiz pour<br><em>tout retenir</em>",
    blocker: "Moins de scroll,<br><em>plus de culture</em>",
    duels: "Défier ses amis<br><em>en duel</em>",
    explore: "Histoire, sciences, art…<br><em>des centaines de cours</em>",
    profile: "Une série qui grandit<br><em>jour après jour</em>",
  },
};

// Two sets are rendered. "classic": centred headline, framed phone, coloured backgrounds
// (frame.html). "editorial": a full-colour opening panel, then cream panels with a title and a
// subtitle on the left and a flat outlined phone running off the bottom (frame-b.html).
// Editorial copy is [title, subtitle].
const SETS = {
  classic: { frame: "frame.html", dir: "", shots: SHOTS, copy: COPY },
  editorial: {
    frame: "frame-b.html", dir: "-editorial",
    shots: [
      { screen: "hero" }, { screen: "home" }, { screen: "reader" }, { screen: "quiz" },
      { screen: "blocker" }, { screen: "duels" }, { screen: "explore" }, { screen: "profile" },
    ],
    copy: {
      "fr-FR": {
        hero: ["Moins de scroll, plus de culture", "La culture générale en 10\u00a0minutes par jour"],
        home: ["Un cours par jour", "Choisi pour vous, lu en 5\u00a0minutes"],
        reader: ["Courts, clairs, illustrés", "Des cours qui vont à l’essentiel"],
        quiz: ["Un quiz à chaque cours", "Pour retenir ce que vous venez de lire"],
        blocker: ["Anti-scroll", "Vos apps se débloquent après un cours"],
        duels: ["Duels", "Défiez vos amis en culture générale"],
        explore: ["Plus de 300 cours", "Histoire, sciences, art, littérature…"],
        profile: ["Votre série", "Un peu plus de culture chaque jour"],
      },
    },
  },
};
if (typeof module !== "undefined") module.exports = { DEVICES, SHOTS, COPY, SETS };
