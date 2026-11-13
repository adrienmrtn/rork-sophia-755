// The App Store set: which screens, in which order, with which headline.
// <em> marks the highlighted words. One entry per locale in COPY; screens are in src/screens/.
const DEVICES = {
  // 6.9" iPhone: 1320 x 2868 px = 440 x 956 pt at 3x. App Store Connect scales it down
  // for the smaller iPhone sizes, so this is the only iPhone size that has to be uploaded.
  "iphone-6.9": {
    width: 440, height: 956, scale: 3,
    layout: {
      "head-top": "54px", "head-h": "168px", "head-pad": "26px", "head-size": "41px",
      "phone-top": "232px", "s": "0.732", "bezel": "9px",
    },
  },
};

const SHOTS = [
  { screen: "home", theme: "cream" },
  { screen: "reader", theme: "blue" },
  { screen: "quiz", theme: "cream" },
  { screen: "blocker", theme: "pink" },
  { screen: "duels", theme: "navy" },
  { screen: "explore", theme: "cream" },
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
if (typeof module !== "undefined") module.exports = { DEVICES, SHOTS, COPY };
