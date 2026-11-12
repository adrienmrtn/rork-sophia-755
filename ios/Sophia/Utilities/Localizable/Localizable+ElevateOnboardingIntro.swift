import Foundation

extension AppLocalizableAdditions {
    /// Textes du début de l'onboarding « Elevate arrondi » (leçons, carrousel de
    /// présentation). Clé → code de langue → texte ; une langue absente retombe sur l'anglais.
    static let elevateOnboardingIntro: Table = [
        // MARK: Leçons (un livre entier contre une leçon)
        "onboardingV2.elevate.lessons.book.title": [
            "fr": "Un livre entier",
            "en": "A whole book",
        ],
        "onboardingV2.elevate.lessons.book.caption": [
            "fr": "des heures de lecture",
            "en": "hours of reading",
        ],
        "onboardingV2.elevate.lessons.lesson.title": [
            "fr": "Une leçon Sophia",
            "en": "A Sophia course",
        ],
        "onboardingV2.elevate.lessons.lesson.caption": [
            "fr": "%d minutes",
            "en": "%d minutes",
        ],

        // MARK: Carrousel — quiz (exemple montré quand le catalogue n'a pas de question à offrir)
        "onboardingV2.elevate.quiz.sample.question": [
            "fr": "Comment définit-on un trou noir ?",
            "en": "How is a black hole defined?",
        ],
        "onboardingV2.elevate.quiz.sample.correct": [
            "fr": "Une région où la gravité est si intense que même la lumière ne peut s'en échapper",
            "en": "A region where gravity is so strong that not even light can escape",
        ],
        "onboardingV2.elevate.quiz.sample.wrong1": [
            "fr": "Un tunnel qui relie deux points éloignés de l'univers",
            "en": "A tunnel linking two distant points in the universe",
        ],
        "onboardingV2.elevate.quiz.sample.wrong2": [
            "fr": "Une étoile particulièrement froide et sombre",
            "en": "An unusually cold, dark star",
        ],

        // MARK: Carrousel — parcours
        "onboardingV2.elevate.path.course": [
            "fr": "Cours %d",
            "en": "Course %d",
        ],
        "onboardingV2.elevate.path.toRead": [
            "fr": "À lire",
            "en": "Up next",
        ],

        // MARK: Carrousel — duels
        "onboardingV2.elevate.duels.title": [
            "fr": "Affronte tes amis en **duel**",
            "en": "Challenge your friends to a **duel**",
        ],
        "onboardingV2.elevate.duels.subtitle": [
            "fr": "20 questions, environ 4 minutes. Gagne des trophées et grimpe de ligue en ligue.",
            "en": "20 questions, about 4 minutes. Win trophies and climb from league to league.",
        ],
        // Pseudos d'exemple du classement montré en illustration (aucun compte réel).
        "onboardingV2.elevate.duels.sample.handle1": [
            "fr": "camille",
            "en": "camille",
        ],
        "onboardingV2.elevate.duels.sample.handle2": [
            "fr": "leo.m",
            "en": "leo.m",
        ],
        "onboardingV2.elevate.duels.sample.handle3": [
            "fr": "ines",
            "en": "ines",
        ],
        "onboardingV2.elevate.duels.sample.handle4": [
            "fr": "noa_b",
            "en": "noa_b",
        ],

        // MARK: Carrousel — audio
        "onboardingV2.elevate.audio.title": [
            "fr": "**Écoute** tes cours quand tu ne peux pas les lire.",
            "en": "**Listen** to your courses when you can't read them.",
        ],
        "onboardingV2.elevate.audio.subtitle": [
            "fr": "Dans le métro, en marchant, en cuisinant : tes cours existent aussi en audio.",
            "en": "On the subway, on a walk, while cooking: your courses come in audio too.",
        ],

        // MARK: Bienvenue — accroche de marque, traduite dans chaque langue
        "onboardingV2.elevate.welcome.tagline": [
            "fr": "Remplace le scroll par **un apprentissage addictif.**",
            "en": "Replace scrolling with **addictive learning.**",
            "ar": "استبدل التمرير **بتعلّمٍ تدمن عليه.**",
            "bg": "Замени скролването с **пристрастяващо учене.**",
            "cs": "Vyměň scrollování za **návykové učení.**",
            "da": "Skift scrolleriet ud med **vanedannende læring.**",
            "de": "Ersetze das Scrollen durch **Lernen, das süchtig macht.**",
            "el": "Αντικατάστησε το σκρολάρισμα με **εθιστική μάθηση.**",
            "es": "Cambia el scroll por **un aprendizaje adictivo.**",
            "et": "Vaheta kerimine **sõltuvust tekitava õppimise vastu.**",
            "fi": "Vaihda selailu **koukuttavaan oppimiseen.**",
            "he": "החלף את הגלילה **בלמידה ממכרת.**",
            "hr": "Zamijeni skrolanje **učenjem koje stvara ovisnost.**",
            "hu": "Cseréld a görgetést **függőséget okozó tanulásra.**",
            "it": "Sostituisci lo scroll con **un apprendimento che crea dipendenza.**",
            "ja": "スクロールを**やみつきになる学びに。**",
            "lt": "Pakeisk naršymą **įtraukiančiu mokymusi.**",
            "lv": "Aizstāj ritināšanu ar **aizraujošu mācīšanos.**",
            "nb": "Bytt ut scrollingen med **avhengighetsskapende læring.**",
            "nl": "Vervang scrollen door **verslavend leren.**",
            "pl": "Zamień scrollowanie na **wciągającą naukę.**",
            "pt": "Troque o scroll por **um aprendizado viciante.**",
            "pt-PT": "Troca o scroll por **uma aprendizagem viciante.**",
            "ro": "Înlocuiește scrollul cu **învățare care dă dependență.**",
            "ru": "Замени скроллинг на **затягивающее обучение.**",
            "sk": "Vymeň scrollovanie za **návykové učenie.**",
            "sl": "Zamenjaj skrolanje z **zasvojljivim učenjem.**",
            "sr": "Zameni skrolovanje **učenjem koje stvara zavisnost.**",
            "sv": "Byt ut scrollandet mot **beroendeframkallande lärande.**",
            "tr": "Kaydırmayı bırak, **bağımlılık yapan öğrenmeye geç.**",
        ],
    ]
}
