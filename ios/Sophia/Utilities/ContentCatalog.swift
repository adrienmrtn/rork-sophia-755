import Foundation

/// Locale-aware access to bundled learning content.
enum ContentCatalog {
    static func courses(for language: AppLanguage) -> [Course] {
        switch language {
        case .french:
            return CourseData.allCourses
        case .english:
            return LocalizedContentLoader.courses(for: .english)
        case .german:
            return LocalizedContentLoader.courses(for: .german)
        }
    }

    static func collections(for language: AppLanguage) -> [LearningCollection] {
        switch language {
        case .french:
            return CollectionData.allCollections
        case .english:
            return LocalizedContentLoader.collections(for: .english)
        case .german:
            return LocalizedContentLoader.collections(for: .german)
        }
    }

    static func cards(for language: AppLanguage) -> [CollectibleCard] {
        switch language {
        case .french:
            return CardData.allCards
        case .english:
            return LocalizedContentLoader.cards(for: .english)
        case .german:
            return LocalizedContentLoader.cards(for: .german)
        }
    }

    static var activeCourses: [Course] {
        courses(for: AppLanguage.currentPersisted())
    }

    static var activeCollections: [LearningCollection] {
        collections(for: AppLanguage.currentPersisted())
    }

    static var activeCards: [CollectibleCard] {
        cards(for: AppLanguage.currentPersisted())
    }

    static var activeCardsByCourseId: [String: [CollectibleCard]] {
        var map: [String: [CollectibleCard]] = [:]
        for card in activeCards {
            for courseId in card.courseIds {
                map[courseId, default: []].append(card)
            }
        }
        return map
    }

    static func course(withId id: String, language: AppLanguage? = nil) -> Course? {
        let language = language ?? AppLanguage.currentPersisted()
        return courses(for: language).first { $0.id == id }
    }
}
