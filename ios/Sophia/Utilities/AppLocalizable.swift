import Foundation

enum AppLocalizable {
    static func string(_ key: String, language: AppLanguage) -> String {
        let table = language == .french ? french : english
        return table[key] ?? english[key] ?? key
    }

    // MARK: - French

    private static let french: [String: String] = [
        "tab.home": "Home",
        "tab.library": "Biblio",
        "tab.profile": "Profil",

        "language.section": "Langue",
        "language.french": "Français",
        "language.english": "English",

        "onboarding.intro.title": "Deviens cultivé\nen 10 minutes\npar jour",
        "onboarding.intro.cta": "Commencer",

        "settings.title": "Options",
        "settings.section.progress": "Progression",
        "settings.section.premium": "Premium",
        "settings.section.data": "Données",
        "settings.section.legal": "Légal",
        "settings.section.about": "À propos",
        "settings.section.developer": "Développeur",
        "settings.courses.completed": "%d cours terminés",
        "settings.courses.available": "sur %d disponibles",
        "settings.streak.title": "%d jours de suite",
        "settings.streak.subtitle": "Continue comme ça !",
        "settings.premium.title": "Passer à Premium",
        "settings.premium.subtitle": "Cours et quiz illimités",
        "settings.reset.title": "Réinitialiser la progression",
        "settings.terms.title": "Conditions générales",
        "settings.privacy.title": "Politique de confidentialité",
        "settings.restore.title": "Restaurer les achats",
        "settings.about.version": "Version",
        "settings.about.courses": "Cours disponibles",
        "settings.debug.resetOnboarding": "Refaire l'onboarding",
        "settings.debug.resetDaily": "Reset cours du jour",
        "settings.debug.daily.done": "Fait aujourd'hui",
        "settings.debug.daily.pending": "Pas encore fait",
        "settings.footer": "Made with ♥ — Sophia",
        "settings.reset.alert.title": "Réinitialiser ?",
        "settings.reset.alert.cancel": "Annuler",
        "settings.reset.alert.confirm": "Réinitialiser",
        "settings.reset.alert.message": "Toute ta progression sera effacée. Cette action est irréversible.",
        "settings.onboarding.alert.title": "Refaire l'onboarding ?",
        "settings.onboarding.alert.confirm": "Relancer",
        "settings.onboarding.alert.message": "L'onboarding sera relancé depuis le début (DEBUG uniquement).",

        "legal.terms.title": "Conditions",
        "legal.privacy.title": "Confidentialité",

        "subject.histoire": "Histoire",
        "subject.sciences": "Sciences",
        "subject.litterature": "Littérature",
        "subject.art": "Art",
        "subject.mythologie": "Mythologie",
        "subject.comprendreLeMonde": "Comprendre le monde actuel",
        "subject.histoire.short": "Histoire",
        "subject.sciences.short": "Sciences",
        "subject.litterature.short": "Littérature",
        "subject.art.short": "Art",
        "subject.mythologie.short": "Mythologie",
        "subject.comprendreLeMonde.short": "Monde actuel",

        "rarity.commune": "Commune",
        "rarity.rare": "Rare",
        "rarity.epique": "Épique",
        "rarity.legendaire": "Légendaire",
    ]

    // MARK: - English

    private static let english: [String: String] = [
        "tab.home": "Home",
        "tab.library": "Library",
        "tab.profile": "Profile",

        "language.section": "Language",
        "language.french": "Français",
        "language.english": "English",

        "onboarding.intro.title": "Become cultured\nin 10 minutes\na day",
        "onboarding.intro.cta": "Get started",

        "settings.title": "Settings",
        "settings.section.progress": "Progress",
        "settings.section.premium": "Premium",
        "settings.section.data": "Data",
        "settings.section.legal": "Legal",
        "settings.section.about": "About",
        "settings.section.developer": "Developer",
        "settings.courses.completed": "%d courses completed",
        "settings.courses.available": "out of %d available",
        "settings.streak.title": "%d-day streak",
        "settings.streak.subtitle": "Keep it up!",
        "settings.premium.title": "Upgrade to Premium",
        "settings.premium.subtitle": "Unlimited courses and quizzes",
        "settings.reset.title": "Reset progress",
        "settings.terms.title": "Terms of Service",
        "settings.privacy.title": "Privacy Policy",
        "settings.restore.title": "Restore purchases",
        "settings.about.version": "Version",
        "settings.about.courses": "Available courses",
        "settings.debug.resetOnboarding": "Restart onboarding",
        "settings.debug.resetDaily": "Reset daily course",
        "settings.debug.daily.done": "Done today",
        "settings.debug.daily.pending": "Not yet done",
        "settings.footer": "Made with ♥ — Sophia",
        "settings.reset.alert.title": "Reset?",
        "settings.reset.alert.cancel": "Cancel",
        "settings.reset.alert.confirm": "Reset",
        "settings.reset.alert.message": "All your progress will be erased. This cannot be undone.",
        "settings.onboarding.alert.title": "Restart onboarding?",
        "settings.onboarding.alert.confirm": "Restart",
        "settings.onboarding.alert.message": "Onboarding will start over from the beginning (DEBUG only).",

        "legal.terms.title": "Terms",
        "legal.privacy.title": "Privacy",

        "subject.histoire": "History",
        "subject.sciences": "Science",
        "subject.litterature": "Literature",
        "subject.art": "Art",
        "subject.mythologie": "Mythology",
        "subject.comprendreLeMonde": "Understanding today's world",
        "subject.histoire.short": "History",
        "subject.sciences.short": "Science",
        "subject.litterature.short": "Literature",
        "subject.art.short": "Art",
        "subject.mythologie.short": "Mythology",
        "subject.comprendreLeMonde.short": "Current affairs",

        "rarity.commune": "Common",
        "rarity.rare": "Rare",
        "rarity.epique": "Epic",
        "rarity.legendaire": "Legendary",
    ]
}
