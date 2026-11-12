import Foundation

extension AppLocalizableAdditions {
    /// Textes ajoutés avec le design « Elevate arrondi » de l'accueil et de l'onglet Explorer :
    /// deux libellés d'accessibilité. Clé → code de langue → texte ; une langue absente retombe
    /// sur l'anglais.
    static let elevateHome: Table = [
        // Le point bleu de l'onglet « Abonnements » (VoiceOver).
        "home.following.newDot": [
            "fr": "Nouveautés",
            "en": "New courses",
            "es": "Novedades",
            "de": "Neuigkeiten",
            "it": "Novità",
            "pt": "Novidades",
            "pt-PT": "Novidades",
        ],
        // Le bouton qui vide le champ de recherche de l'onglet Explorer (VoiceOver).
        "explore.search.clear": [
            "fr": "Effacer la recherche",
            "en": "Clear search",
            "es": "Borrar la búsqueda",
            "de": "Suche löschen",
            "it": "Cancella la ricerca",
            "pt": "Limpar a pesquisa",
            "pt-PT": "Limpar a pesquisa",
        ],
    ]
}
