import Foundation

extension AppLocalizableAdditions {
    /// Textes de la zone « cours » (lecteur, quiz, entraînement) ajoutés avec le design
    /// « Elevate arrondi ». Clé → code de langue → texte. Une langue absente retombe sur l'anglais.
    static let elevateCourse: Table = [
        // Sur-titre du quiz et de l'entraînement : « SCIENCES · QUESTION 2 SUR 8 ».
        "elevateCourse.quiz.questionOf": [
            "fr": "Question %d sur %d",
            "en": "Question %d of %d",
            "es": "Pregunta %d de %d",
            "de": "Frage %d von %d",
            "pt": "Pergunta %d de %d",
            "pt-PT": "Pergunta %d de %d",
            "it": "Domanda %d di %d",
            "tr": "Soru %d / %d",
            "pl": "Pytanie %d z %d",
            "ro": "Întrebarea %d din %d",
            "nl": "Vraag %d van %d",
            "el": "Ερώτηση %d από %d",
            "sv": "Fråga %d av %d",
            "hu": "%d. kérdés / %d",
            "bg": "Въпрос %d от %d",
            "cs": "Otázka %d z %d",
            "da": "Spørgsmål %d af %d",
            "nb": "Spørsmål %d av %d",
            "ru": "Вопрос %d из %d",
            "hr": "Pitanje %d od %d",
            "sl": "Vprašanje %d od %d",
            "sk": "Otázka %d z %d",
            "sr": "Pitanje %d od %d",
            "ar": "السؤال %d من %d",
            "he": "שאלה %d מתוך %d",
            "fi": "Kysymys %d / %d",
            "et": "Küsimus %d / %d",
            "lt": "Klausimas %d iš %d",
            "lv": "Jautājums %d no %d",
            "ja": "第%d問 / 全%d問",
        ],
    ]
}
