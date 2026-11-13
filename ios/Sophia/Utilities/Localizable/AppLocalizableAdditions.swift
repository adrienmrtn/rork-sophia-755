import Foundation

/// Les textes ajoutés après la grande table d'`AppLocalizable`, rangés par zone de l'app (un
/// fichier par zone dans ce dossier). Format : clé → code de langue (`AppLanguage.rawValue`,
/// « fr », « en », « pt-PT »…) → texte. Une langue absente retombe sur l'anglais.
/// `AppLocalizable.string` consulte ces tables quand la clé n'est pas dans la table de la langue.
enum AppLocalizableAdditions {
    typealias Table = [String: [String: String]]

    private static let tables: [Table] = [
        home, events, explore, duels, profile, progressPage, settings, badgeCelebration, invite,
        // Design « Elevate arrondi » : textes ajoutés par zone lors du passage au nouveau style.
        elevateOnboardingIntro, elevateOnboardingCore, elevateOnboardingEnd,
        elevateHome, elevateCourse, elevatePath, elevateDuels, elevateProfile,
        elevatePaywalls,
        // Onboarding de la page Entraînement : passages forts de ses titres.
        trainingOnboarding,
    ]

    static func entry(for key: String) -> [String: String]? {
        for table in tables {
            if let entry = table[key] { return entry }
        }
        return nil
    }
}
