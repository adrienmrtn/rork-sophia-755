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
}

nonisolated struct UserProgress: Codable, Sendable {
    var courseProgress: [String: CourseProgress]
    var streak: Int
    var lastActiveDate: String?
    var favoriteCourseIds: [String]
    var freeCoursesOpened: Int
    var hasSeenSwipeTutorial: Bool
    var hasSeenSpecialOffer: Bool

    static let empty = UserProgress(courseProgress: [:], streak: 0, lastActiveDate: nil, favoriteCourseIds: [], freeCoursesOpened: 0, hasSeenSwipeTutorial: false, hasSeenSpecialOffer: false)

    init(courseProgress: [String: CourseProgress], streak: Int, lastActiveDate: String?, favoriteCourseIds: [String] = [], freeCoursesOpened: Int = 0, hasSeenSwipeTutorial: Bool = false, hasSeenSpecialOffer: Bool = false) {
        self.courseProgress = courseProgress
        self.streak = streak
        self.lastActiveDate = lastActiveDate
        self.favoriteCourseIds = favoriteCourseIds
        self.freeCoursesOpened = freeCoursesOpened
        self.hasSeenSwipeTutorial = hasSeenSwipeTutorial
        self.hasSeenSpecialOffer = hasSeenSpecialOffer
    }
}
