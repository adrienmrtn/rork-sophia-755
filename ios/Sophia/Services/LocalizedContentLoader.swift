import Foundation

private struct LocaleCourseDTO: Decodable {
    let id: String
    let title: String
    let description: String
    let subject: String
    let subcategory: String
    let lessons: [LessonPage]
    let quiz: [QuizQuestion]

    func toCourse() -> Course? {
        guard let subject = Subject.from(storageKey: subject) else { return nil }
        return Course(
            id: id,
            title: title,
            description: description,
            subject: subject,
            subcategory: subcategory,
            lessons: lessons,
            quiz: quiz
        )
    }
}

private struct LocaleGlossaryEntryDTO: Decodable {
    let displayTerm: String
    let classification: String
    let explanation: String

    func toEntry() -> GlossaryEntry? {
        guard let classification = GlossaryClassification(catalogKey: classification) else { return nil }
        return GlossaryEntry(
            displayTerm: displayTerm,
            classification: classification,
            explanation: explanation
        )
    }
}

private struct LocaleCollectionDTO: Decodable {
    let id: String
    let title: String
    let description: String
    let courseIds: [String]
}

enum LocalizedContentLoader {
    private struct Cache {
        var courses: [Course]?
        var glossary: [String: GlossaryEntry]?
        var collections: [LearningCollection]?
    }

    private static var caches: [AppLanguage: Cache] = [:]

    static func resetCache() {
        caches.removeAll()
    }

    static func courses(for language: AppLanguage) -> [Course] {
        var cache = caches[language, default: Cache()]
        if let cachedCourses = cache.courses { return cachedCourses }
        let decoded: [LocaleCourseDTO] = load("courses", language: language) ?? []
        let mapped = decoded.compactMap { $0.toCourse() }
        cache.courses = mapped
        caches[language] = cache
        return mapped
    }

    static func glossaryEntries(for language: AppLanguage) -> [String: GlossaryEntry] {
        var cache = caches[language, default: Cache()]
        if let cachedGlossary = cache.glossary { return cachedGlossary }
        let decoded: [String: LocaleGlossaryEntryDTO] = load("glossary", language: language) ?? [:]
        var mapped: [String: GlossaryEntry] = [:]
        for (key, dto) in decoded {
            if let entry = dto.toEntry() {
                mapped[key] = entry
            }
        }
        cache.glossary = mapped
        caches[language] = cache
        return mapped
    }

    static func collections(for language: AppLanguage) -> [LearningCollection] {
        var cache = caches[language, default: Cache()]
        if let cachedCollections = cache.collections { return cachedCollections }
        let decoded: [LocaleCollectionDTO] = load("collections", language: language) ?? []
        let mapped = decoded.compactMap { dto -> LearningCollection? in
            guard let base = CollectionData.allCollections.first(where: { $0.id == dto.id }) else {
                return nil
            }
            return LearningCollection(
                id: dto.id,
                title: dto.title,
                description: dto.description,
                coverAssetName: base.coverAssetName,
                courseIds: dto.courseIds
            )
        }
        cache.collections = mapped
        caches[language] = cache
        return mapped
    }

    private static func jsonURL(named name: String, language: AppLanguage) -> URL? {
        guard language != .french else { return nil }

        let code = language.rawValue
        let localizedName = "\(name).\(code)"
        let bundleSubdirectories = [
            "Resources/Locales",
            "Locales",
        ]

        for subdirectory in bundleSubdirectories {
            if let url = Bundle.main.url(
                forResource: localizedName,
                withExtension: "json",
                subdirectory: subdirectory
            ) {
                return url
            }
        }

        if let url = Bundle.main.url(forResource: localizedName, withExtension: "json") {
            return url
        }

        // Legacy layout: Locales/{code}/{name}.json
        let legacySubdirectories = [
            "Locales/\(code)",
            "Resources/Locales/\(code)",
        ]
        for subdirectory in legacySubdirectories {
            if let url = Bundle.main.url(
                forResource: name,
                withExtension: "json",
                subdirectory: subdirectory
            ) {
                return url
            }
        }

        guard let resourceURL = Bundle.main.resourceURL else { return nil }
        let legacyRelativePaths = [
            "Resources/Locales/\(localizedName).json",
            "Locales/\(localizedName).json",
            "Locales/\(code)/\(name).json",
            "Resources/Locales/\(code)/\(name).json",
        ]
        for relativePath in legacyRelativePaths {
            let candidate = resourceURL.appendingPathComponent(relativePath)
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }

        return findJSON(named: localizedName, under: resourceURL)
    }

    private static func findJSON(named resourceName: String, under root: URL) -> URL? {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        for case let fileURL as URL in enumerator {
            guard fileURL.lastPathComponent == "\(resourceName).json" else { continue }
            return fileURL
        }
        return nil
    }

    private static func load<T: Decodable>(_ name: String, language: AppLanguage) -> T? {
        guard let url = jsonURL(named: name, language: language) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            assertionFailure("Failed to load \(name).json for \(language.rawValue): \(error)")
            return nil
        }
    }
}
