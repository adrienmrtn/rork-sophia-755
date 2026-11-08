import Foundation

/// Le contenu structuré (V2) d'un cours, lu dans le catalogue en ligne (`CatalogStore`) : le
/// paquet téléchargé, ou celui du pack de départ embarqué. Les lectures sont synchrones et
/// répondent nil quand le paquet n'est pas encore sur le téléphone ; `ensureContent` va alors
/// le chercher.
enum CourseContentStore {
    static func resetCache() {
        CatalogStore.shared.resetMemory()
    }

    /// Le contenu complet d'un cours s'il est sur le téléphone, sinon nil.
    static func content(
        courseId: String,
        language: AppLanguage = AppLanguage.currentPersisted()
    ) -> CourseContentV2? {
        CatalogStore.shared.localContent(courseId: courseId, language: language)
    }

    static func hasContent(
        courseId: String,
        language: AppLanguage = AppLanguage.currentPersisted()
    ) -> Bool {
        CatalogStore.shared.hasLocalContent(courseId: courseId, language: language)
    }

    /// Le contenu, téléchargé s'il le faut. Nil : hors ligne et jamais téléchargé.
    static func ensureContent(
        courseId: String,
        language: AppLanguage = AppLanguage.currentPersisted()
    ) async -> CourseContentV2? {
        await CatalogStore.shared.ensureContent(courseId: courseId, language: language)
    }

    /// Une section, et si elle est la première (le hero, la signature) ou la dernière (la carte
    /// auteur, les sources).
    static func section(
        courseId: String,
        sectionId: String,
        language: AppLanguage = AppLanguage.currentPersisted()
    ) -> (content: CourseContentV2, section: CourseSectionV2, isFirst: Bool, isLast: Bool)? {
        guard let content = content(courseId: courseId, language: language) else { return nil }
        guard let index = content.sections.firstIndex(where: { $0.id == sectionId }) else { return nil }
        return (content, content.sections[index], index == 0, index == content.sections.count - 1)
    }
}
