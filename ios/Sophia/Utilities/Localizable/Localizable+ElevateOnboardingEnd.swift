import Foundation

extension AppLocalizableAdditions {
    /// Textes de la fin de l'onboarding au design « Elevate arrondi » (heure de lecture →
    /// bienvenue à bord). Clé → code de langue → texte.
    ///
    /// Les clés `…Marked` sont la version à passage surligné (`**…**`, gras bleu) d'un titre qui
    /// existe déjà sans balisage dans `AppLocalizable`. Elles ne sont lues que par
    /// `OV2End.marked`, qui garde le texte existant pour les langues absentes d'ici : aucune
    /// traduction déjà en place ne retombe sur l'anglais.
    static let elevateOnboardingEnd: Table = [
        // MARK: Courbe 90 jours
        "onboardingV2.curve90.title": [
            "fr": "Les petits efforts s\u{2019}additionnent. **Dans 90\u{00A0}jours, tu ne seras plus la même personne.**",
            "en": "Small efforts add up. **In 90\u{00A0}days, you won\u{2019}t be the same person.**",
        ],
        "onboardingV2.curve90.others": [
            "fr": "À scroller sur d\u{2019}autres applis",
            "en": "Scrolling on other apps",
        ],
        "onboardingV2.curve90.today": [
            "fr": "Aujourd\u{2019}hui",
            "en": "Today",
        ],
        "onboardingV2.curve90.day7": [
            "fr": "7 jours",
            "en": "7 days",
        ],
        "onboardingV2.curve90.day30": [
            "fr": "30 jours",
            "en": "30 days",
        ],
        "onboardingV2.curve90.day90": [
            "fr": "90 jours",
            "en": "90 days",
        ],
        "onboardingV2.curve90.a11y": [
            "fr": "Avec Sophia, la progression s\u{2019}accélère au fil des 90 jours ; à scroller sur d\u{2019}autres applis, elle reste presque plate.",
            "en": "With Sophia, progress speeds up over the 90 days; scrolling on other apps, it stays almost flat.",
        ],

        // MARK: Notifications
        "onboardingV2.notifications.bubble": [
            "fr": "Je te préviens quand un cours peut **vraiment t\u{2019}intéresser.**",
            "en": "I\u{2019}ll let you know when a course is **genuinely worth your time.**",
        ],
        "onboardingV2.notifications.bubbleNote": [
            "fr": "Un rappel discret. Rien d\u{2019}autre, jamais.",
            "en": "One quiet nudge. Nothing else, ever.",
        ],
        "onboardingV2.notifications.dialog.title": [
            "fr": "«\u{00A0}Sophia\u{00A0}» souhaite vous envoyer des notifications",
            "en": "\u{201C}Sophia\u{201D} Would Like to Send You Notifications",
        ],
        "onboardingV2.notifications.dialog.body": [
            "fr": "Les notifications peuvent inclure des alertes, des sons et des pastilles d\u{2019}icônes. Vous pouvez les configurer dans Réglages.",
            "en": "Notifications may include alerts, sounds, and icon badges. These can be configured in Settings.",
        ],
        "onboardingV2.notifications.dialog.deny": [
            "fr": "Refuser",
            "en": "Don\u{2019}t Allow",
        ],
        "onboardingV2.notifications.dialog.allow": [
            "fr": "Autoriser",
            "en": "Allow",
        ],

        // MARK: Préparation
        "onboardingV2.loading.titleMarked": [
            "fr": "On prépare ton **parcours de connaissances…**",
            "en": "We\u{2019}re building your **learning path…**",
        ],
        "onboardingV2.loading.titleMarkedNamed": [
            "fr": "On prépare ton **parcours de connaissances**, {name}",
            "en": "We\u{2019}re building your **learning path**, {name}",
        ],
        "onboardingV2.loading.stepDone": [
            "fr": "Terminé",
            "en": "Done",
        ],
        "onboardingV2.loading.question.eyebrow": [
            "fr": "Pour avancer, précise",
            "en": "To move forward, tell us",
        ],
        "onboardingV2.loading.question.title": [
            "fr": "Aimes-tu apprendre en écoutant\u{00A0}?",
            "en": "Do you like learning by listening?",
        ],
        "onboardingV2.loading.question.no": [
            "fr": "Non",
            "en": "No",
        ],
        "onboardingV2.loading.question.yes": [
            "fr": "Oui",
            "en": "Yes",
        ],

        // MARK: Profil
        "onboardingV2.profile.coursesTitleMarked": [
            "fr": "Les cours qui **t\u{2019}attendent**",
            "en": "Courses **waiting for you**",
        ],
    ]
}
