import Foundation

extension AppLocalizableAdditions {
    /// Textes de l'onboarding de la page Entraînement (`TrainingOnboardingView`), ajoutés avec
    /// son passage au style « Elevate arrondi ». Clé → code de langue → texte.
    ///
    /// Les clés `…Highlight` ne sont pas des phrases : c'est le passage du titre existant
    /// (`training.ob.…`) à mettre en gras bleu. Il est cherché tel quel dans le titre de la
    /// langue ; s'il ne s'y trouve plus (titre retraduit), le titre s'affiche simplement sans
    /// passage surligné. Aucune phrase n'est donc dupliquée ici.
    static let trainingOnboarding: Table = [
        // Passage fort du titre « mémorisation active » (training.ob.recall.title).
        "training.ob.recall.titleHighlight": [
            "fr": "mémorisation active",
            "en": "active recall",
            "es": "memorización activa",
            "de": "aktives Erinnern",
            "pt": "memorização ativa",
            "pt-PT": "memorização ativa",
            "it": "memorizzazione attiva",
            "tr": "aktif hatırlamayı",
            "pl": "aktywne przypominanie",
            "ro": "memorarea activă",
            "nl": "actief ophalen",
            "el": "ενεργή ανάκληση",
            "sv": "aktiv återkallning",
            "hu": "aktív felidézés",
            "bg": "активното припомняне",
            "cs": "aktivní vybavování",
            "da": "aktiv genkaldelse",
            "nb": "aktiv gjenkalling",
            "ru": "активное припоминание",
            "hr": "aktivnim prisjećanjem",
            "sl": "aktivni priklic",
            "sk": "aktívne vybavovanie z pamäti",
            "sr": "aktivno prisećanje",
            "ar": "الاستذكار النشط",
            "he": "בשליפה פעילה",
            "fi": "aktiivista kertausta",
            "et": "aktiivset meenutamist",
            "lt": "aktyvų įsiminimą",
            "lv": "aktīvo iegaumēšanu",
            "ja": "能動的な記憶法",
        ],
        // Passage fort du titre de l'algorithme (training.ob.algo.title).
        "training.ob.algo.titleHighlight": [
            "fr": "en continu",
            "en": "keeps testing you",
            "es": "sin parar",
            "de": "laufend",
            "pt": "sem parar",
            "pt-PT": "sem parar",
            "it": "di continuo",
            "tr": "durmadan",
            "pl": "stale",
            "ro": "continuu",
            "nl": "blijft je testen",
            "el": "συνέχεια",
            "sv": "hela tiden",
            "hu": "folyamatosan",
            "bg": "непрекъснато",
            "cs": "průběžně",
            "da": "hele tiden",
            "nb": "hele tiden",
            "ru": "постоянно",
            "hr": "neprestano",
            "sl": "neprestano",
            "sk": "neustále",
            "sr": "stalno",
            "ar": "باستمرار",
            "he": "כל הזמן",
            "fi": "jatkuvasti",
            "et": "pidevalt",
            "lt": "nuolat",
            "lv": "nepārtraukti",
            "ja": "常にテスト",
        ],
    ]
}
