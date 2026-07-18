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

/// The interaction style of a quiz question. See `content/CHARTE_QUIZ.md` for the
/// authoring rules and when to use each type.
nonisolated enum QuizQuestionType: String, Codable, Sendable, CaseIterable {
    /// Classic single-choice question, 3-5 options.
    case mcq
    /// Single-choice question with exactly two options ("Vrai" / "Faux").
    case trueFalse
    /// Reorder a shuffled list of 3-5 items into the correct (usually chronological) order.
    case chronological
    /// Guess a numeric value (often a year) on a slider; awards partial credit the
    /// closer the guess is to the target, within `tolerance`.
    case numericSlider
    /// Same mechanism as `numericSlider`, fixed to a 0-100 range with a "%" unit.
    case percentageSlider
}

/// A single quiz question. `type` determines which of the fields below are populated —
/// unused fields for a given type are simply `nil`. See `content/CHARTE_QUIZ.md` for the
/// full authoring schema and worked examples of every type.
///
/// - `.mcq` / `.trueFalse`: `options` (4 for mcq, exactly 2 for trueFalse) + `correctIndex`
///   (index into `options`, before shuffling for display).
/// - `.chronological`: `items` lists the entries **already in their correct order**; they
///   are shuffled for display and the learner rebuilds the sequence.
/// - `.numericSlider` / `.percentageSlider`: `correctValue` is the target the learner is
///   guessing, `sliderMin`/`sliderMax` bound the slider, `tolerance` defines the band that
///   earns full credit (see `QuizScoring`), `unit` is shown next to the value (e.g. "ans",
///   "km", "%").
nonisolated struct QuizQuestion: Identifiable, Sendable {
    let id: String
    let type: QuizQuestionType
    let question: String
    let explanation: String

    // .mcq / .trueFalse
    let options: [String]?
    let correctIndex: Int?

    // .chronological — entries in their correct order.
    let items: [String]?

    // .numericSlider / .percentageSlider
    let correctValue: Double?
    let sliderMin: Double?
    let sliderMax: Double?
    let tolerance: Double?
    let unit: String?

    init(
        id: String,
        type: QuizQuestionType = .mcq,
        question: String,
        options: [String]? = nil,
        correctIndex: Int? = nil,
        explanation: String = "",
        items: [String]? = nil,
        correctValue: Double? = nil,
        sliderMin: Double? = nil,
        sliderMax: Double? = nil,
        tolerance: Double? = nil,
        unit: String? = nil
    ) {
        self.id = id
        self.type = type
        self.question = question
        self.options = options
        self.correctIndex = correctIndex
        self.explanation = explanation
        self.items = items
        self.correctValue = correctValue
        self.sliderMin = sliderMin
        self.sliderMax = sliderMax
        self.tolerance = tolerance
        self.unit = unit
    }

    /// Maximum points obtainable, per the tiered scoring scale: binary types (mcq,
    /// trueFalse) are right-or-wrong, the "closeness" types can award partial credit
    /// for a near-miss so they carry one extra point at stake.
    var maxPoints: Int {
        switch type {
        case .mcq, .trueFalse:
            return 2
        case .chronological, .numericSlider, .percentageSlider:
            return 3
        }
    }
}

extension QuizQuestion: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, type, question, explanation, options, correctIndex, items, correctValue, sliderMin, sliderMax, tolerance, unit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        // Older bundled content (non-FR locales, not yet migrated) has no `type` key at
        // all — it predates this schema and is always a classic MCQ.
        type = try container.decodeIfPresent(QuizQuestionType.self, forKey: .type) ?? .mcq
        question = try container.decode(String.self, forKey: .question)
        explanation = try container.decodeIfPresent(String.self, forKey: .explanation) ?? ""
        options = try container.decodeIfPresent([String].self, forKey: .options)
        correctIndex = try container.decodeIfPresent(Int.self, forKey: .correctIndex)
        items = try container.decodeIfPresent([String].self, forKey: .items)
        correctValue = try container.decodeIfPresent(Double.self, forKey: .correctValue)
        sliderMin = try container.decodeIfPresent(Double.self, forKey: .sliderMin)
        sliderMax = try container.decodeIfPresent(Double.self, forKey: .sliderMax)
        tolerance = try container.decodeIfPresent(Double.self, forKey: .tolerance)
        unit = try container.decodeIfPresent(String.self, forKey: .unit)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(question, forKey: .question)
        try container.encode(explanation, forKey: .explanation)
        try container.encodeIfPresent(options, forKey: .options)
        try container.encodeIfPresent(correctIndex, forKey: .correctIndex)
        try container.encodeIfPresent(items, forKey: .items)
        try container.encodeIfPresent(correctValue, forKey: .correctValue)
        try container.encodeIfPresent(sliderMin, forKey: .sliderMin)
        try container.encodeIfPresent(sliderMax, forKey: .sliderMax)
        try container.encodeIfPresent(tolerance, forKey: .tolerance)
        try container.encodeIfPresent(unit, forKey: .unit)
    }
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

extension Array where Element == QuizQuestion {
    /// Total points obtainable across every question — varies with question count
    /// and the mix of types, so this is always computed rather than assumed to be
    /// `count * 2` or similar.
    var maxPoints: Int {
        reduce(0) { $0 + $1.maxPoints }
    }
}
