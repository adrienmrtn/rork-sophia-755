import Foundation

nonisolated struct CourseProgress: Codable, Sendable {
    var lastLessonIndex: Int
    var isCompleted: Bool
    var bestQuizScore: Int
    var completedDate: String?
}

nonisolated struct ShuffledQuestion: Sendable {
    let question: String
    let options: [String]
    let correctIndex: Int
}

nonisolated struct ThemeProgressState: Codable, Sendable {
    var points: Int
    var lastGainDate: String?
    var lastGainAmount: Int
    var lastRegressionDate: String?

    static let empty = ThemeProgressState(points: 0, lastGainDate: nil, lastGainAmount: 0, lastRegressionDate: nil)
}

nonisolated struct UserProgress: Codable, Sendable {
    var courseProgress: [String: CourseProgress]
    var streak: Int
    var lastActiveDate: String?
    var streakBrokenDate: String?
    var shieldCount: Int
    var shieldGrantedDate: String?
    var shieldUsedDate: String?
    var shieldProtectedStreak: Int?
    var favoriteCourseIds: [String]
    var freeCoursesOpened: Int
    var dailyFreeCourseDate: String?
    var dailyFreeCourseId: String?
    var dailyFreeCourseCompletedDate: String?
    var themeProgress: [String: ThemeProgressState]
    var hasSeenSwipeTutorial: Bool
    var hasSeenSpecialOffer: Bool

    static let empty = UserProgress(courseProgress: [:], streak: 0, lastActiveDate: nil, streakBrokenDate: nil, shieldCount: 0, shieldGrantedDate: nil, shieldUsedDate: nil, shieldProtectedStreak: nil, favoriteCourseIds: [], freeCoursesOpened: 0, dailyFreeCourseDate: nil, dailyFreeCourseId: nil, dailyFreeCourseCompletedDate: nil, themeProgress: [:], hasSeenSwipeTutorial: false, hasSeenSpecialOffer: false)

    init(courseProgress: [String: CourseProgress], streak: Int, lastActiveDate: String?, streakBrokenDate: String? = nil, shieldCount: Int = 0, shieldGrantedDate: String? = nil, shieldUsedDate: String? = nil, shieldProtectedStreak: Int? = nil, favoriteCourseIds: [String] = [], freeCoursesOpened: Int = 0, dailyFreeCourseDate: String? = nil, dailyFreeCourseId: String? = nil, dailyFreeCourseCompletedDate: String? = nil, themeProgress: [String: ThemeProgressState] = [:], hasSeenSwipeTutorial: Bool = false, hasSeenSpecialOffer: Bool = false) {
        self.courseProgress = courseProgress
        self.streak = streak
        self.lastActiveDate = lastActiveDate
        self.streakBrokenDate = streakBrokenDate
        self.shieldCount = shieldCount
        self.shieldGrantedDate = shieldGrantedDate
        self.shieldUsedDate = shieldUsedDate
        self.shieldProtectedStreak = shieldProtectedStreak
        self.favoriteCourseIds = favoriteCourseIds
        self.freeCoursesOpened = freeCoursesOpened
        self.dailyFreeCourseDate = dailyFreeCourseDate
        self.dailyFreeCourseId = dailyFreeCourseId
        self.dailyFreeCourseCompletedDate = dailyFreeCourseCompletedDate
        self.themeProgress = themeProgress
        self.hasSeenSwipeTutorial = hasSeenSwipeTutorial
        self.hasSeenSpecialOffer = hasSeenSpecialOffer
    }

    enum CodingKeys: String, CodingKey {
        case courseProgress
        case streak
        case lastActiveDate
        case streakBrokenDate
        case shieldCount
        case shieldGrantedDate
        case shieldUsedDate
        case shieldProtectedStreak
        case favoriteCourseIds
        case freeCoursesOpened
        case dailyFreeCourseDate
        case dailyFreeCourseId
        case dailyFreeCourseCompletedDate
        case themeProgress
        case hasSeenSwipeTutorial
        case hasSeenSpecialOffer
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        courseProgress = try c.decode([String: CourseProgress].self, forKey: .courseProgress)
        streak = try c.decode(Int.self, forKey: .streak)
        lastActiveDate = try c.decodeIfPresent(String.self, forKey: .lastActiveDate)
        streakBrokenDate = try c.decodeIfPresent(String.self, forKey: .streakBrokenDate)
        shieldCount = try c.decodeIfPresent(Int.self, forKey: .shieldCount) ?? 0
        shieldGrantedDate = try c.decodeIfPresent(String.self, forKey: .shieldGrantedDate)
        shieldUsedDate = try c.decodeIfPresent(String.self, forKey: .shieldUsedDate)
        shieldProtectedStreak = try c.decodeIfPresent(Int.self, forKey: .shieldProtectedStreak)
        favoriteCourseIds = try c.decodeIfPresent([String].self, forKey: .favoriteCourseIds) ?? []
        freeCoursesOpened = try c.decodeIfPresent(Int.self, forKey: .freeCoursesOpened) ?? 0
        dailyFreeCourseDate = try c.decodeIfPresent(String.self, forKey: .dailyFreeCourseDate)
        dailyFreeCourseId = try c.decodeIfPresent(String.self, forKey: .dailyFreeCourseId)
        dailyFreeCourseCompletedDate = try c.decodeIfPresent(String.self, forKey: .dailyFreeCourseCompletedDate)
        themeProgress = try c.decodeIfPresent([String: ThemeProgressState].self, forKey: .themeProgress) ?? [:]
        hasSeenSwipeTutorial = try c.decodeIfPresent(Bool.self, forKey: .hasSeenSwipeTutorial) ?? false
        hasSeenSpecialOffer = try c.decodeIfPresent(Bool.self, forKey: .hasSeenSpecialOffer) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(courseProgress, forKey: .courseProgress)
        try c.encode(streak, forKey: .streak)
        try c.encodeIfPresent(lastActiveDate, forKey: .lastActiveDate)
        try c.encodeIfPresent(streakBrokenDate, forKey: .streakBrokenDate)
        try c.encode(shieldCount, forKey: .shieldCount)
        try c.encodeIfPresent(shieldGrantedDate, forKey: .shieldGrantedDate)
        try c.encodeIfPresent(shieldUsedDate, forKey: .shieldUsedDate)
        try c.encodeIfPresent(shieldProtectedStreak, forKey: .shieldProtectedStreak)
        try c.encode(favoriteCourseIds, forKey: .favoriteCourseIds)
        try c.encode(freeCoursesOpened, forKey: .freeCoursesOpened)
        try c.encodeIfPresent(dailyFreeCourseDate, forKey: .dailyFreeCourseDate)
        try c.encodeIfPresent(dailyFreeCourseId, forKey: .dailyFreeCourseId)
        try c.encodeIfPresent(dailyFreeCourseCompletedDate, forKey: .dailyFreeCourseCompletedDate)
        try c.encode(themeProgress, forKey: .themeProgress)
        try c.encode(hasSeenSwipeTutorial, forKey: .hasSeenSwipeTutorial)
        try c.encode(hasSeenSpecialOffer, forKey: .hasSeenSpecialOffer)
    }
}
