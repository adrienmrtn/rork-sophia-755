import SwiftUI

nonisolated enum Subject: String, Codable, CaseIterable, Sendable {
    case histoire = "Histoire"
    case sciences = "Sciences"
    case litterature = "Littérature"
    case art = "Art"
    case mythologie = "Mythologie"
    case comprendreLeMonde = "Comprendre le monde actuel"

    var color: Color {
        switch self {
        case .histoire: Color(red: 0.96, green: 0.62, blue: 0.04)
        case .sciences: Color(red: 0.20, green: 0.83, blue: 0.60)
        case .litterature: Color(red: 0.93, green: 0.35, blue: 0.45)
        case .art: Color(red: 0.85, green: 0.55, blue: 0.95)
        case .mythologie: Color(red: 0.56, green: 0.40, blue: 0.92)
        case .comprendreLeMonde: Color(red: 0.25, green: 0.72, blue: 0.85)
        }
    }

    var icon: String {
        switch self {
        case .histoire: "building.columns"
        case .sciences: "atom"
        case .litterature: "book.closed"
        case .art: "paintpalette"
        case .mythologie: "bolt.fill"
        case .comprendreLeMonde: "globe.europe.africa"
        }
    }

    var emoji: String {
        switch self {
        case .histoire: "🗽"
        case .sciences: "🦠"
        case .litterature: "📖"
        case .art: "🎨"
        case .mythologie: "⚡️"
        case .comprendreLeMonde: "🌍"
        }
    }

    var shortName: String {
        localizedShortName(language: AppLanguage.currentPersisted())
    }

    /// Stable key persisted in UserDefaults (language-independent).
    var storageKey: String {
        switch self {
        case .histoire: "histoire"
        case .sciences: "sciences"
        case .litterature: "litterature"
        case .art: "art"
        case .mythologie: "mythologie"
        case .comprendreLeMonde: "comprendreLeMonde"
        }
    }

    static func from(storageKey key: String) -> Subject? {
        allCases.first { $0.storageKey == key }
    }

    func localizedName(language: AppLanguage) -> String {
        AppLocalizable.string("subject.\(storageKey)", language: language)
    }

    func localizedShortName(language: AppLanguage) -> String {
        AppLocalizable.string("subject.\(storageKey).short", language: language)
    }
}

nonisolated struct LessonPage: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let content: String
}

nonisolated struct QuizQuestion: Codable, Identifiable, Sendable {
    let id: String
    let question: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
}

nonisolated struct Course: Codable, Identifiable, Sendable, Equatable {
    nonisolated static func == (lhs: Course, rhs: Course) -> Bool {
        lhs.id == rhs.id
    }
    let id: String
    let title: String
    let description: String
    let subject: Subject
    let subcategory: String
    let lessons: [LessonPage]
    let quiz: [QuizQuestion]

    var hasQuiz: Bool { !quiz.isEmpty }
}
