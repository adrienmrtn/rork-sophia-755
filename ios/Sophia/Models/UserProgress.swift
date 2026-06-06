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

nonisolated struct ShuffledQuestion: Sendable {
    let question: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
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
    /// Card IDs that already granted their one-time global unlock reward.
    var globalCardXPAwardedIds: [String]
    /// Highest global rank animation waiting to be shown.
    var pendingGlobalRankUp: PendingGlobalRankUp?

    static let empty = UserProgress(courseProgress: [:], streak: 0, lastActiveDate: nil, favoriteCourseIds: [], freeCoursesOpened: 0, hasSeenSwipeTutorial: false, hasSeenSpecialOffer: false, lastCourseCompletedDate: nil, lastStreakShownDate: nil, subjectXP: [:], globalXP: 0, globalCourseXPAwardedIds: [], globalQuizXPAwardedIds: [], globalCollectionXPAwardedIds: [], globalCardXPAwardedIds: [], pendingGlobalRankUp: nil)

    init(courseProgress: [String: CourseProgress], streak: Int, lastActiveDate: String?, favoriteCourseIds: [String] = [], freeCoursesOpened: Int = 0, hasSeenSwipeTutorial: Bool = false, hasSeenSpecialOffer: Bool = false, lastCourseCompletedDate: String? = nil, lastStreakShownDate: String? = nil, subjectXP: [String: Int] = [:], globalXP: Int = 0, globalCourseXPAwardedIds: [String] = [], globalQuizXPAwardedIds: [String] = [], globalCollectionXPAwardedIds: [String] = [], globalCardXPAwardedIds: [String] = [], pendingGlobalRankUp: PendingGlobalRankUp? = nil) {
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
        self.globalCardXPAwardedIds = globalCardXPAwardedIds
        self.pendingGlobalRankUp = pendingGlobalRankUp
    }

    enum CodingKeys: String, CodingKey {
        case courseProgress, streak, lastActiveDate, favoriteCourseIds, freeCoursesOpened
        case hasSeenSwipeTutorial, hasSeenSpecialOffer, lastCourseCompletedDate, lastStreakShownDate, subjectXP
        case globalXP, globalCourseXPAwardedIds, globalQuizXPAwardedIds, globalCollectionXPAwardedIds, globalCardXPAwardedIds, pendingGlobalRankUp
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
        self.globalCardXPAwardedIds = try c.decodeIfPresent([String].self, forKey: .globalCardXPAwardedIds) ?? []
        self.pendingGlobalRankUp = try c.decodeIfPresent(PendingGlobalRankUp.self, forKey: .pendingGlobalRankUp)
    }
}

nonisolated struct PendingGlobalRankUp: Codable, Sendable, Equatable {
    var previousRankRawValue: String
    var newRankRawValue: String
    var newLevel: Int
}
