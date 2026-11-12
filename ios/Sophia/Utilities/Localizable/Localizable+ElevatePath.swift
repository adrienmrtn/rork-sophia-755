import Foundation

extension AppLocalizableAdditions {
    /// Textes de l'onglet « Parcours » en zigzag de cartes. Clé → code de langue → texte.
    static let elevatePath: Table = [
        // Sur-titre d'une carte de cours : « COURS 3 » (mis en capitales à l'affichage).
        "elevatePath.course.number": [
            "fr": "Cours %d",
            "en": "Course %d",
            "es": "Curso %d",
            "de": "Kurs %d",
            "pt": "Curso %d",
            "pt-PT": "Curso %d",
            "it": "Corso %d",
            "nl": "Cursus %d",
        ],
        // Pastille posée sur la couverture du cours à lire.
        "elevatePath.course.readNow": [
            "fr": "À lire maintenant",
            "en": "Read now",
            "es": "Para leer ahora",
            "de": "Jetzt lesen",
            "pt": "Para ler agora",
            "pt-PT": "Para ler agora",
            "it": "Da leggere ora",
            "nl": "Nu lezen",
        ],
        // Sous-titre de la pastille « Quiz du niveau » tant que les cours ne sont pas finis.
        "elevatePath.quiz.afterCourses": [
            "fr": "Après les %d cours",
            "en": "After the %d courses",
            "es": "Después de los %d cursos",
            "de": "Nach den %d Kursen",
            "pt": "Depois dos %d cursos",
            "pt-PT": "Depois dos %d cursos",
            "it": "Dopo i %d corsi",
            "nl": "Na de %d cursussen",
        ],
    ]
}
