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

private struct LocaleCardDTO: Decodable {
    let id: String
    let name: String
    let rarity: String
    let courseIds: [String]
}

enum LocalizedContentLoader {
    private static let localeFolder = "Locales/en"
    private static var cachedCourses: [Course]?
    private static var cachedGlossary: [String: GlossaryEntry]?
    private static var cachedCollections: [LearningCollection]?
    private static var cachedCards: [CollectibleCard]?

    static func resetCache() {
        cachedCourses = nil
        cachedGlossary = nil
        cachedCollections = nil
        cachedCards = nil
    }

    static func courses() -> [Course] {
        if let cachedCourses { return cachedCourses }
        let decoded: [LocaleCourseDTO] = load("courses") ?? []
        let mapped = decoded.compactMap { $0.toCourse() }
        cachedCourses = mapped
        return mapped
    }

    static func glossaryEntries() -> [String: GlossaryEntry] {
        if let cachedGlossary { return cachedGlossary }
        let decoded: [String: LocaleGlossaryEntryDTO] = load("glossary") ?? [:]
        var mapped: [String: GlossaryEntry] = [:]
        for (key, dto) in decoded {
            if let entry = dto.toEntry() {
                mapped[key] = entry
            }
        }
        cachedGlossary = mapped
        return mapped
    }

    static func collections() -> [LearningCollection] {
        if let cachedCollections { return cachedCollections }
        let decoded: [LocaleCollectionDTO] = load("collections") ?? []
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
        cachedCollections = mapped
        return mapped
    }

    static func cards() -> [CollectibleCard] {
        if let cachedCards { return cachedCards }
        let decoded: [LocaleCardDTO] = load("cards") ?? []
        let mapped = decoded.compactMap { dto -> CollectibleCard? in
            guard let base = CardData.allCards.first(where: { $0.id == dto.id }),
                  let rarity = CollectibleCardRarity(catalogKey: dto.rarity) else {
                return nil
            }
            return CollectibleCard(
                id: dto.id,
                name: dto.name,
                rarity: rarity,
                imageAssetName: base.imageAssetName,
                courseIds: dto.courseIds
            )
        }
        cachedCards = mapped
        return mapped
    }

    private static func load<T: Decodable>(_ name: String) -> T? {
        let url = Bundle.main.url(
            forResource: name,
            withExtension: "json",
            subdirectory: localeFolder
        ) ?? Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "Resources/\(localeFolder)")

        guard let url else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            assertionFailure("Failed to load \(name).json: \(error)")
            return nil
        }
    }
}
