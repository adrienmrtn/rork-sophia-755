import Foundation

extension AppLocalizableAdditions {
    /// Textes du duel en cours dans le design « Elevate arrondi » (maquette AEr24).
    /// Clé → code de langue → texte ; une langue absente retombe sur l'anglais.
    static let elevateDuels: Table = [
        // Sur-titre de l'écran de jeu : « MANCHE 2 SUR 4 ».
        "duel.round.of": [
            "fr": "Manche %1$d sur %2$d",
            "en": "Round %1$d of %2$d",
        ],
        // Étiquette courte d'une manche au-dessus des bandes de résultats : « M1 », « M2 »…
        "duel.round.short": [
            "fr": "M%d",
            "en": "R%d",
        ],
        // Bandeau de verdict, à droite : le point marqué sur la question.
        "duel.verdict.point": [
            "fr": "+1 point",
            "en": "+1 point",
        ],
        // Bandeau de verdict : le joueur est devant (son score, puis celui de l'adversaire).
        "duel.verdict.leading": [
            "fr": "tu mènes %1$d à %2$d",
            "en": "you lead %1$d–%2$d",
        ],
        // Bandeau de verdict : l'adversaire est devant (son pseudo, son score, puis celui du joueur).
        "duel.verdict.trailing": [
            "fr": "@%1$@ mène %2$d à %3$d",
            "en": "@%1$@ leads %2$d–%3$d",
        ],
        // Bandeau de verdict : les deux joueurs ont le même score.
        "duel.verdict.tied": [
            "fr": "égalité %1$d partout",
            "en": "tied at %1$d",
        ],
    ]
}
