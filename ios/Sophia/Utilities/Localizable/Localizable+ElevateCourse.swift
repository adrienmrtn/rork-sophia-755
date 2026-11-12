import Foundation

extension AppLocalizableAdditions {
    /// Textes de la zone « cours » (lecteur, quiz, entraînement) ajoutés avec le design
    /// « Elevate arrondi ». Clé → code de langue → texte. Une langue absente retombe sur l'anglais.
    static let elevateCourse: Table = [
        // Sur-titre du quiz et de l'entraînement : « SCIENCES · QUESTION 2 SUR 8 ».
        "elevateCourse.quiz.questionOf": [
            "fr": "Question %d sur %d",
            "en": "Question %d of %d",
        ],
    ]
}
