import Foundation

/// Les cours, le glossaire et les collections d'une langue, lus dans le snapshot du catalogue
/// en ligne (`CatalogStore`). Le nom date des JSON embarqués par langue ; l'API est restée pour
/// ses appelants, le français passe désormais par le même chemin que les autres langues.
enum LocalizedContentLoader {
    static func resetCache() {
        CatalogStore.shared.resetMemory()
    }

    static func courses(for language: AppLanguage) -> [Course] {
        CatalogStore.shared.snapshot(for: language).courses
    }

    /// Clé `"<courseId>|<terme>"`, dans toutes les langues.
    static func glossaryEntries(for language: AppLanguage) -> [String: GlossaryEntry] {
        CatalogStore.shared.snapshot(for: language).glossary
    }

    static func collections(for language: AppLanguage) -> [LearningCollection] {
        CatalogStore.shared.snapshot(for: language).collections
    }
}
