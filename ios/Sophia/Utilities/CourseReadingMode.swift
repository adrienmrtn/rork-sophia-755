import Foundation

/// Comment le texte d'un cours se présente dans le lecteur.
///
/// Depuis novembre 2026, par défaut, un cours se lit **pas à pas** : un seul fil vertical où
/// chaque passage (paragraphe, frise, citation, encart) apparaît au tap sur « Continuer », avec
/// un ressort, un défilement automatique et un retour haptique (`CourseStepReaderView`,
/// docs/lecture-pas-a-pas.md). L'ancien lecteur **par pages** (une page par partie, glissement
/// horizontal) reste disponible : le lecteur choisit dans le menu du lecteur ou dans Réglages,
/// et le choix est conservé sur l'appareil.
enum CourseReadingMode: String, CaseIterable, Identifiable {
    /// Un fil vertical, révélé passage par passage.
    case steps
    /// Une page par partie, le lecteur historique.
    case pages

    var id: String { rawValue }

    static let storageKey = "sophia_course_reading_mode"

    /// Le mode choisi sur cet appareil ; `steps` tant que rien n'a été choisi.
    static var current: CourseReadingMode {
        get {
            guard let raw = UserDefaults.standard.string(forKey: storageKey),
                  let mode = CourseReadingMode(rawValue: raw) else { return .steps }
            return mode
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: storageKey) }
    }

    /// Clé du nom affiché (« Pas à pas », « Par pages »).
    var titleKey: String {
        switch self {
        case .steps: "course.readingMode.steps"
        case .pages: "course.readingMode.pages"
        }
    }

    /// Clé de la phrase qui explique le mode, sous le sélecteur des Réglages.
    var hintKey: String {
        switch self {
        case .steps: "course.readingMode.steps.hint"
        case .pages: "course.readingMode.pages.hint"
        }
    }

    var systemImage: String {
        switch self {
        case .steps: "text.line.first.and.arrowtriangle.forward"
        case .pages: "rectangle.portrait.on.rectangle.portrait"
        }
    }
}
