import Foundation

nonisolated struct CourseProgress: Codable, Sendable {
    var lastLessonIndex: Int
    var isCompleted: Bool
    var bestQuizScore: Int
    var lastQuizDate: String?

    init(lastLessonIndex: Int, isCompleted: Bool, bestQuizScore: Int, lastQuizDate: String? = nil) {
        self.lastLessonIndex = lastLessonIndex
        self.isCompleted = isCompleted
        self.bestQuizScore = bestQuizScore
        self.lastQuizDate = lastQuizDate
    }
}

/// A quiz question with its randomized-for-display state resolved, ready to render.
/// Built once per question via `QuizShuffler.shuffle(_:)`. Fields not relevant to
/// `type` are left at harmless defaults (empty array / 0) rather than optional, since
/// this struct is only ever constructed by the shuffler, which always fills in the
/// fields the given `type` needs.
nonisolated struct ShuffledQuestion: Sendable, Identifiable {
    let id: String
    let type: QuizQuestionType
    let question: String
    let explanation: String
    let maxPoints: Int

    // .mcq / .trueFalse — `options` already shuffled, `correctIndex` updated to match.
    let options: [String]
    let correctIndex: Int

    // .chronological — `items` already shuffled for display. `originalIndices[i]` is
    // the position (0-based) that the item currently at display slot `i` should end up
    // in once correctly ordered; i.e. the learner's answer is correct once they arrange
    // the displayed items so that `originalIndices[userOrder] == [0, 1, 2, ...]`.
    let items: [String]
    let originalIndices: [Int]

    // .numericSlider / .percentageSlider
    let sliderMin: Double
    let sliderMax: Double
    let correctValue: Double
    let tolerance: Double
    let unit: String
}

/// The learner's answer to a single question, shaped to match its `QuizQuestionType`.
nonisolated enum QuizAnswer: Sendable, Equatable {
    /// `.mcq` / `.trueFalse` — index into `ShuffledQuestion.options`.
    case singleChoice(Int)
    /// `.chronological` — the display-slot index chosen for each position, in the
    /// order the learner placed them (i.e. `order[0]` is the display index the
    /// learner put first).
    case order([Int])
    /// `.numericSlider` / `.percentageSlider` — the value the learner picked on the slider.
    case value(Double)
}

nonisolated struct UserProgress: Codable, Sendable {
    var courseProgress: [String: CourseProgress]
    var streak: Int
    var lastActiveDate: String?
    var favoriteCourseIds: [String]
    var freeCoursesOpened: Int
    var hasSeenSwipeTutorial: Bool
    var hasSeenSpecialOffer: Bool
    /// yyyy-MM-dd date string for the last day the user fully completed (swiped to last slide + tapped Continuer) a course. Used for the freemium daily course gate.
    var lastCourseCompletedDate: String?
    /// yyyy-MM-dd date string for the last day we displayed the streak celebration screen. Used to only show it once per day.
    var lastStreakShownDate: String?
    /// XP earned per subject (key = Subject.rawValue). Drives the per-subject level shown on the profile.
    var subjectXP: [String: Int]
    /// Global XP for the user profile level/rank system. Existing installs start at 0.
    var globalXP: Int
    /// Course IDs that already granted the one-time global course completion reward.
    var globalCourseXPAwardedIds: [String]
    /// Course IDs whose quiz already granted the one-time global quiz completion reward.
    var globalQuizXPAwardedIds: [String]
    /// Collection IDs that already granted their one-time global completion reward.
    var globalCollectionXPAwardedIds: [String]
    /// Course IDs for which the user actually completed the quiz flow.
    var completedQuizCourseIds: [String]
    /// Highest global rank animation waiting to be shown.
    var pendingGlobalRankUp: PendingGlobalRankUp?
    /// Spaced-repetition review state for the "Entraînement" tab, keyed by `QuizQuestion.id`.
    /// Populated as courses' quizzes are completed; independent of XP/streak (see `ProgressManager`).
    var trainingQuestionStates: [String: TrainingQuestionState]

    static let empty = UserProgress(courseProgress: [:], streak: 0, lastActiveDate: nil, favoriteCourseIds: [], freeCoursesOpened: 0, hasSeenSwipeTutorial: false, hasSeenSpecialOffer: false, lastCourseCompletedDate: nil, lastStreakShownDate: nil, subjectXP: [:], globalXP: 0, globalCourseXPAwardedIds: [], globalQuizXPAwardedIds: [], globalCollectionXPAwardedIds: [], completedQuizCourseIds: [], pendingGlobalRankUp: nil, trainingQuestionStates: [:])

    init(courseProgress: [String: CourseProgress], streak: Int, lastActiveDate: String?, favoriteCourseIds: [String] = [], freeCoursesOpened: Int = 0, hasSeenSwipeTutorial: Bool = false, hasSeenSpecialOffer: Bool = false, lastCourseCompletedDate: String? = nil, lastStreakShownDate: String? = nil, subjectXP: [String: Int] = [:], globalXP: Int = 0, globalCourseXPAwardedIds: [String] = [], globalQuizXPAwardedIds: [String] = [], globalCollectionXPAwardedIds: [String] = [], completedQuizCourseIds: [String] = [], pendingGlobalRankUp: PendingGlobalRankUp? = nil, trainingQuestionStates: [String: TrainingQuestionState] = [:]) {
        self.courseProgress = courseProgress
        self.streak = streak
        self.lastActiveDate = lastActiveDate
        self.favoriteCourseIds = favoriteCourseIds
        self.freeCoursesOpened = freeCoursesOpened
        self.hasSeenSwipeTutorial = hasSeenSwipeTutorial
        self.hasSeenSpecialOffer = hasSeenSpecialOffer
        self.lastCourseCompletedDate = lastCourseCompletedDate
        self.lastStreakShownDate = lastStreakShownDate
        self.subjectXP = subjectXP
        self.globalXP = globalXP
        self.globalCourseXPAwardedIds = globalCourseXPAwardedIds
        self.globalQuizXPAwardedIds = globalQuizXPAwardedIds
        self.globalCollectionXPAwardedIds = globalCollectionXPAwardedIds
        self.completedQuizCourseIds = completedQuizCourseIds
        self.pendingGlobalRankUp = pendingGlobalRankUp
        self.trainingQuestionStates = trainingQuestionStates
    }

    enum CodingKeys: String, CodingKey {
        case courseProgress, streak, lastActiveDate, favoriteCourseIds, freeCoursesOpened
        case hasSeenSwipeTutorial, hasSeenSpecialOffer, lastCourseCompletedDate, lastStreakShownDate, subjectXP
        case globalXP, globalCourseXPAwardedIds, globalQuizXPAwardedIds, globalCollectionXPAwardedIds, completedQuizCourseIds, pendingGlobalRankUp
        case trainingQuestionStates
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.courseProgress = try c.decodeIfPresent([String: CourseProgress].self, forKey: .courseProgress) ?? [:]
        self.streak = try c.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        self.lastActiveDate = try c.decodeIfPresent(String.self, forKey: .lastActiveDate)
        self.favoriteCourseIds = try c.decodeIfPresent([String].self, forKey: .favoriteCourseIds) ?? []
        self.freeCoursesOpened = try c.decodeIfPresent(Int.self, forKey: .freeCoursesOpened) ?? 0
        self.hasSeenSwipeTutorial = try c.decodeIfPresent(Bool.self, forKey: .hasSeenSwipeTutorial) ?? false
        self.hasSeenSpecialOffer = try c.decodeIfPresent(Bool.self, forKey: .hasSeenSpecialOffer) ?? false
        self.lastCourseCompletedDate = try c.decodeIfPresent(String.self, forKey: .lastCourseCompletedDate)
        self.lastStreakShownDate = try c.decodeIfPresent(String.self, forKey: .lastStreakShownDate)
        self.subjectXP = try c.decodeIfPresent([String: Int].self, forKey: .subjectXP) ?? [:]
        self.globalXP = try c.decodeIfPresent(Int.self, forKey: .globalXP) ?? 0
        self.globalCourseXPAwardedIds = try c.decodeIfPresent([String].self, forKey: .globalCourseXPAwardedIds) ?? []
        self.globalQuizXPAwardedIds = try c.decodeIfPresent([String].self, forKey: .globalQuizXPAwardedIds) ?? []
        self.globalCollectionXPAwardedIds = try c.decodeIfPresent([String].self, forKey: .globalCollectionXPAwardedIds) ?? []
        self.completedQuizCourseIds = try c.decodeIfPresent([String].self, forKey: .completedQuizCourseIds) ?? []
        self.pendingGlobalRankUp = try c.decodeIfPresent(PendingGlobalRankUp.self, forKey: .pendingGlobalRankUp)
        self.trainingQuestionStates = try c.decodeIfPresent([String: TrainingQuestionState].self, forKey: .trainingQuestionStates) ?? [:]
    }
}

extension UserProgress {
    /// `true` si la progression ne contient rien de significatif (équivalent à `.empty`,
    /// ou à une ligne cloud fraîchement créée `{}`). Sert à éviter d'écraser des données
    /// réelles avec une progression vide lors de la synchronisation.
    var isEssentiallyEmpty: Bool {
        courseProgress.isEmpty
            && favoriteCourseIds.isEmpty
            && subjectXP.isEmpty
            && completedQuizCourseIds.isEmpty
            && trainingQuestionStates.isEmpty
            && globalXP == 0
            && streak == 0
    }

    /// Score grossier « quantité de progression » utilisé pour arbitrer local vs cloud
    /// sans horodatage fiable : plus il est élevé, plus la progression est avancée.
    var syncSignalScore: Int {
        let completed = courseProgress.values.filter(\.isCompleted).count
        return completed * 100
            + globalXP
            + favoriteCourseIds.count
            + subjectXP.values.reduce(0, +)
            + completedQuizCourseIds.count
            + trainingQuestionStates.count
            + streak
    }
}

nonisolated struct PendingGlobalRankUp: Codable, Sendable, Equatable {
    var previousRankRawValue: String
    var newRankRawValue: String
    var newLevel: Int
}

/// Spaced-repetition state for a single quiz question in the "Entraînement" review pool.
/// `intervalIndex` is the position in `ProgressManager.trainingIntervalDays` to apply the
/// *next* time this question is answered correctly; `nextReviewDate` is `nil` while the
/// question is due right now (never reviewed yet, or reset after a wrong answer).
nonisolated struct TrainingQuestionState: Codable, Sendable {
    var courseId: String
    var intervalIndex: Int
    var nextReviewDate: String?

    init(courseId: String, intervalIndex: Int = 0, nextReviewDate: String? = nil) {
        self.courseId = courseId
        self.intervalIndex = intervalIndex
        self.nextReviewDate = nextReviewDate
    }
}
