import Foundation

/// Locale-aware access to bundled learning content.
enum ContentCatalog {
    /// Courses withheld from a language. They are absent from the catalogue as if they
    /// had never been bundled: no home card, no library row, no collection slot, no
    /// deep link, no blocker pick. Switching language brings them back.
    ///
    /// Sensitive subjects, decided on 02/11/2026 after reader complaints: the Armenian
    /// genocide in Turkish; the birth of Islam (historical, not religious, telling) in
    /// Turkish and Arabic; the Israeli-Palestinian conflict in Arabic and Hebrew; Putin's
    /// Russia and the war in Ukraine in Russian; the break-up of Yugoslavia in Serbian and
    /// Croatian.
    static let withheldCourseIds: [AppLanguage: Set<String>] = [
        .turkish: [
            "course_25_le_genocide_armenien_1915_1916",
            "course_1_la_naissance_de_l_islam_622",
        ],
        .arabic: [
            "course_1_la_naissance_de_l_islam_622",
            "course_201_la_naissance_du_conflit_israelo_palestin",
        ],
        .hebrew: ["course_201_la_naissance_du_conflit_israelo_palestin"],
        .russian: [
            "course_209_la_russie_de_poutine",
            "course_210_la_guerre_en_ukraine_expliquee",
        ],
        .serbian: ["course_270_pourquoi_la_yougoslavie_a_t_elle_eclate"],
        .croatian: ["course_270_pourquoi_la_yougoslavie_a_t_elle_eclate"],
    ]

    /// Courses withheld by the phone's region, whatever the app language: a reader in
    /// Türkiye with the app in English or French still saw the Armenian genocide course.
    static let withheldCourseIdsByRegion: [String: Set<String>] = [
        "TR": ["course_25_le_genocide_armenien_1915_1916"],
    ]

    /// Everything withheld for this language on this phone.
    static func withheldIds(for language: AppLanguage) -> Set<String> {
        let byLanguage = withheldCourseIds[language] ?? []
        guard let region = Locale.current.region?.identifier,
              let byRegion = withheldCourseIdsByRegion[region] else { return byLanguage }
        return byLanguage.union(byRegion)
    }

    static func isWithheld(_ courseId: String, language: AppLanguage) -> Bool {
        withheldIds(for: language).contains(courseId)
    }

    static func courses(for language: AppLanguage) -> [Course] {
        // Le catalogue en ligne exclut déjà les cours retenus pour la langue ; la liste locale
        // reste pour la région du téléphone, que le serveur ne connaît pas.
        let all = LocalizedContentLoader.courses(for: language)
        let withheld = withheldIds(for: language)
        guard !withheld.isEmpty else { return all }
        return all.filter { !withheld.contains($0.id) }
    }

    /// Collections lose their withheld courses too, so their counts and completion
    /// maths only see what the reader can open.
    static func collections(for language: AppLanguage) -> [LearningCollection] {
        let all = LocalizedContentLoader.collections(for: language)
        let withheld = withheldIds(for: language)
        guard !withheld.isEmpty else { return all }
        return all.map { collection in
            let kept = collection.courseIds.filter { !withheld.contains($0) }
            guard kept.count != collection.courseIds.count else { return collection }
            return LearningCollection(
                id: collection.id,
                title: collection.title,
                description: collection.description,
                coverAssetName: collection.coverAssetName,
                courseIds: kept
            )
        }
    }

    static var activeCourses: [Course] {
        courses(for: AppLanguage.currentPersisted())
    }

    static var activeCollections: [LearningCollection] {
        collections(for: AppLanguage.currentPersisted())
    }

    static func course(withId id: String, language: AppLanguage? = nil) -> Course? {
        let language = language ?? AppLanguage.currentPersisted()
        guard !isWithheld(id, language: language) else { return nil }
        return CatalogStore.shared.snapshot(for: language).courseById[id]
    }

    // MARK: - Structured (v2) content

    /// Whether a course has structured block content bundled for the active language.
    /// When true, `CourseView` renders it with `BlockContentView` instead of the legacy renderer.
    static func hasStructuredContent(courseId: String, language: AppLanguage? = nil) -> Bool {
        CourseContentStore.hasContent(
            courseId: courseId,
            language: language ?? AppLanguage.currentPersisted()
        )
    }

    static func structuredContent(courseId: String, language: AppLanguage? = nil) -> CourseContentV2? {
        CourseContentStore.content(
            courseId: courseId,
            language: language ?? AppLanguage.currentPersisted()
        )
    }
}
