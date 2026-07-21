import Foundation
import SwiftUI

nonisolated enum GlobalRank: String, Codable, CaseIterable, Sendable {
    case curieux = "Curieux"
    case erudit = "Érudit"
    case savant = "Savant"
    case maitre = "Maître"
    case legende = "Légende"

    var lowerLevel: Int {
        switch self {
        case .curieux: 1
        case .erudit: 20
        case .savant: 40
        case .maitre: 60
        case .legende: 80
        }
    }

    var upperLevel: Int {
        switch self {
        case .curieux: 19
        case .erudit: 39
        case .savant: 59
        case .maitre: 79
        case .legende: 100
        }
    }

    var next: GlobalRank? {
        switch self {
        case .curieux: .erudit
        case .erudit: .savant
        case .savant: .maitre
        case .maitre: .legende
        case .legende: nil
        }
    }

    var symbolName: String {
        switch self {
        case .curieux: "sparkles"
        case .erudit: "book.closed.fill"
        case .savant: "brain.head.profile"
        case .maitre: "crown.fill"
        case .legende: "star.circle.fill"
        }
    }

    var primaryColor: Color {
        switch self {
        case .curieux: Color(red: 0.74, green: 0.90, blue: 1.0)
        case .erudit: Color(red: 0.82, green: 0.78, blue: 1.0)
        case .savant: Color(red: 0.70, green: 0.95, blue: 0.80)
        case .maitre: Color(red: 1.0, green: 0.78, blue: 0.36)
        case .legende: Color(red: 1.0, green: 0.68, blue: 0.82)
        }
    }

    var secondaryColor: Color {
        switch self {
        case .curieux: Color(red: 0.50, green: 0.75, blue: 1.0)
        case .erudit: Color(red: 0.62, green: 0.48, blue: 1.0)
        case .savant: Color(red: 0.38, green: 0.86, blue: 0.62)
        case .maitre: Color(red: 1.0, green: 0.52, blue: 0.18)
        case .legende: Color(red: 1.0, green: 0.84, blue: 0.35)
        }
    }

    var storageKey: String {
        switch self {
        case .curieux: "curieux"
        case .erudit: "erudit"
        case .savant: "savant"
        case .maitre: "maitre"
        case .legende: "legende"
        }
    }

    func localizedName(language: AppLanguage) -> String {
        AppLocalizable.string("globalRank.\(storageKey)", language: language)
    }

    var displayName: String {
        localizedName(language: AppLanguage.currentPersisted())
    }
}

nonisolated enum GlobalXPReason: Sendable {
    case courseCompleted(courseId: String)
    case quizCompleted(courseId: String)
    case collectionCompleted(id: String)

    var analyticsKey: String {
        switch self {
        case .courseCompleted: "course_completed"
        case .quizCompleted: "quiz_completed"
        case .collectionCompleted: "collection_completed"
        }
    }
}

nonisolated struct GlobalLevelProgress: Sendable {
    let xp: Int
    let level: Int
    let rank: GlobalRank
    let currentRankLowerXP: Int
    let nextRankXP: Int?

    var progressToNextRank: Double {
        guard let nextRankXP else { return 1.0 }
        let span = max(1, nextRankXP - currentRankLowerXP)
        return min(1.0, max(0.0, Double(xp - currentRankLowerXP) / Double(span)))
    }

    var xpToNextRank: Int? {
        guard let nextRankXP else { return nil }
        return max(0, nextRankXP - xp)
    }
}

nonisolated struct GlobalXPAwardResult: Sendable {
    let awardedXP: Int
    let previousXP: Int
    let newXP: Int
    let previousLevel: Int
    let newLevel: Int
    let previousRank: GlobalRank
    let newRank: GlobalRank

    var didRankUp: Bool { previousRank != newRank }
}

nonisolated struct CollectionProgressEvent: Identifiable, Sendable {
    var id: String { collection.id }
    let collection: LearningCollection
    let previousCompletedCount: Int
    let newCompletedCount: Int
    let totalCount: Int

    var didCompleteCollection: Bool {
        previousCompletedCount < totalCount && newCompletedCount == totalCount
    }
}

nonisolated struct QuizStatsSummary: Sendable {
    let completedQuizCount: Int
    /// Points earned (best attempt per course), not a raw count of correct answers —
    /// question types other than mcq/trueFalse can award partial credit.
    let earnedPoints: Int
    /// Sum of `course.quiz.maxPoints` across every completed-quiz course.
    let totalPoints: Int

    var successPercent: Int {
        guard totalPoints > 0 else { return 0 }
        return Int((Double(earnedPoints) / Double(totalPoints) * 100).rounded())
    }
}

@Observable
@MainActor
class ProgressManager {
    var progress: UserProgress = .empty

    private let key = "sophia_user_progress"
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init() {
        load()
        updateStreak()
        ProgressSyncService.shared.attach(self)
    }

    /// Remplace la progression locale par celle venant du cloud (sync). Persiste sans
    /// re-déclencher d'envoi vers le cloud (les données viennent déjà de là).
    func applyRemoteProgress(_ remote: UserProgress) {
        progress = remote
        persistLocally()
    }

    var streak: Int { progress.streak }

    static let globalCourseCompletionXP = 50
    static let globalQuizCompletionXP = 50
    static let globalCollectionXPPerCourse = 25

    private static let globalLevelXPRequirements: [Int] = {
        (1..<100).map { level in
            switch level {
            case 1..<10: 100
            case 10..<30: 150
            case 30..<60: 250
            case 60..<80: 400
            default: 700
            }
        }
    }()

    static func xpThreshold(forGlobalLevel level: Int) -> Int {
        let clamped = min(100, max(1, level))
        guard clamped > 1 else { return 0 }
        return globalLevelXPRequirements.prefix(clamped - 1).reduce(0, +)
    }

    static func globalLevel(for xp: Int) -> Int {
        let safeXP = max(0, xp)
        var level = 1
        var cumulativeXP = 0
        for requirement in globalLevelXPRequirements {
            if safeXP < cumulativeXP + requirement { break }
            cumulativeXP += requirement
            level += 1
        }
        return min(100, level)
    }

    static func globalRank(forLevel level: Int) -> GlobalRank {
        switch level {
        case 1...19: .curieux
        case 20...39: .erudit
        case 40...59: .savant
        case 60...79: .maitre
        default: .legende
        }
    }

    var globalLevelProgress: GlobalLevelProgress {
        Self.globalLevelProgress(for: progress.globalXP)
    }

    static func globalLevelProgress(for xp: Int) -> GlobalLevelProgress {
        let level = globalLevel(for: xp)
        let rank = globalRank(forLevel: level)
        let lowerXP = xpThreshold(forGlobalLevel: rank.lowerLevel)
        let nextRankXP = rank.next.map { xpThreshold(forGlobalLevel: $0.lowerLevel) }
        return GlobalLevelProgress(
            xp: max(0, xp),
            level: level,
            rank: rank,
            currentRankLowerXP: lowerXP,
            nextRankXP: nextRankXP
        )
    }

    func courseStatus(for courseId: String) -> CourseStatus {
        guard let cp = progress.courseProgress[courseId] else { return .notStarted }
        if cp.isCompleted { return .completed }
        return .inProgress
    }

    func lastLessonIndex(for courseId: String) -> Int {
        progress.courseProgress[courseId]?.lastLessonIndex ?? 0
    }

    func bestScore(for courseId: String) -> Int? {
        progress.courseProgress[courseId]?.bestQuizScore
    }

    func updateLessonProgress(courseId: String, lessonIndex: Int) {
        var cp = progress.courseProgress[courseId] ?? CourseProgress(lastLessonIndex: 0, isCompleted: false, bestQuizScore: 0)
        if lessonIndex > cp.lastLessonIndex {
            cp.lastLessonIndex = lessonIndex
        }
        progress.courseProgress[courseId] = cp
        save()
    }

    func completeCourse(courseId: String, quizScore: Int, completedQuiz: Bool = false) {
        var cp = progress.courseProgress[courseId] ?? CourseProgress(lastLessonIndex: 0, isCompleted: false, bestQuizScore: 0)
        cp.isCompleted = true
        if quizScore > cp.bestQuizScore {
            cp.bestQuizScore = quizScore
        }
        if completedQuiz {
            cp.lastQuizDate = ISO8601DateFormatter().string(from: Date())
            if !progress.completedQuizCourseIds.contains(courseId) {
                progress.completedQuizCourseIds.append(courseId)
            }
        }
        progress.courseProgress[courseId] = cp
        recordActivity()
        save()
    }

    @discardableResult
    func awardGlobalXP(reason: GlobalXPReason, amount: Int) -> GlobalXPAwardResult {
        guard amount > 0 else {
            let current = Self.globalLevelProgress(for: progress.globalXP)
            return GlobalXPAwardResult(awardedXP: 0, previousXP: progress.globalXP, newXP: progress.globalXP, previousLevel: current.level, newLevel: current.level, previousRank: current.rank, newRank: current.rank)
        }

        switch reason {
        case .courseCompleted(let courseId):
            guard !progress.globalCourseXPAwardedIds.contains(courseId) else {
                return noGlobalXPAwardResult()
            }
            progress.globalCourseXPAwardedIds.append(courseId)
        case .quizCompleted(let courseId):
            guard !progress.globalQuizXPAwardedIds.contains(courseId) else {
                return noGlobalXPAwardResult()
            }
            progress.globalQuizXPAwardedIds.append(courseId)
        case .collectionCompleted(let id):
            guard !progress.globalCollectionXPAwardedIds.contains(id) else {
                return noGlobalXPAwardResult()
            }
            progress.globalCollectionXPAwardedIds.append(id)
        }

        let previousXP = progress.globalXP
        let previous = Self.globalLevelProgress(for: previousXP)
        progress.globalXP = previousXP + amount
        let new = Self.globalLevelProgress(for: progress.globalXP)
        if previous.rank != new.rank {
            progress.pendingGlobalRankUp = PendingGlobalRankUp(
                previousRankRawValue: previous.rank.rawValue,
                newRankRawValue: new.rank.rawValue,
                newLevel: new.level
            )
        }
        save()
        // Weekly friends leaderboard: mirror global XP awards into Supabase xp_events.
        SocialService.shared.logXPEvent(amount: amount, reason: reason.analyticsKey)
        return GlobalXPAwardResult(awardedXP: amount, previousXP: previousXP, newXP: progress.globalXP, previousLevel: previous.level, newLevel: new.level, previousRank: previous.rank, newRank: new.rank)
    }

    func pendingGlobalRankUp() -> (previous: GlobalRank, new: GlobalRank, newLevel: Int)? {
        guard let pending = progress.pendingGlobalRankUp,
              let previous = GlobalRank(rawValue: pending.previousRankRawValue),
              let new = GlobalRank(rawValue: pending.newRankRawValue) else { return nil }
        return (previous, new, pending.newLevel)
    }

    func clearPendingGlobalRankUp() {
        progress.pendingGlobalRankUp = nil
        save()
    }

    private func noGlobalXPAwardResult() -> GlobalXPAwardResult {
        let current = Self.globalLevelProgress(for: progress.globalXP)
        return GlobalXPAwardResult(awardedXP: 0, previousXP: progress.globalXP, newXP: progress.globalXP, previousLevel: current.level, newLevel: current.level, previousRank: current.rank, newRank: current.rank)
    }

    /// XP thresholds for subject levels: NIV 1: 0-9, 2: 10-149, 3: 150-349, 4: 350-699, 5: 700+.
    static let subjectXPTiers: [(level: Int, lower: Int, upper: Int)] = [
        (1, 0, 10),
        (2, 10, 150),
        (3, 150, 350),
        (4, 350, 700),
        (5, 700, 1400),
    ]

    /// Returns the persisted XP for a given subject.
    func xp(for subject: Subject) -> Int {
        progress.subjectXP[subject.rawValue] ?? 0
    }

    /// Adds XP to a subject and persists it. Called from the quiz when the user answers correctly.
    func addXP(subject: Subject, amount: Int) {
        guard amount > 0 else { return }
        let current = progress.subjectXP[subject.rawValue] ?? 0
        progress.subjectXP[subject.rawValue] = current + amount
        save()
    }

    /// Number of completed courses for a given subject. Used for the subject level (1–5).
    func completedCount(for subject: Subject) -> Int {
        let coursesInSubject = Set(ContentCatalog.activeCourses.filter { $0.subject == subject }.map(\.id))
        return progress.courseProgress.filter { id, cp in
            cp.isCompleted && coursesInSubject.contains(id)
        }.count
    }

    func completedCount(for collection: LearningCollection) -> Int {
        collection.courseIds.filter { courseId in
            progress.courseProgress[courseId]?.isCompleted == true
        }.count
    }

    func progressFraction(for collection: LearningCollection) -> Double {
        guard !collection.courseIds.isEmpty else { return 0 }
        return min(1, Double(completedCount(for: collection)) / Double(collection.courseIds.count))
    }

    func isCollectionCompleted(_ collection: LearningCollection) -> Bool {
        !collection.courseIds.isEmpty && completedCount(for: collection) == collection.courseIds.count
    }

    func collectionCompletionXP(for collection: LearningCollection) -> Int {
        collection.courseIds.count * Self.globalCollectionXPPerCourse
    }

    func collectionProgressEvents(forNewlyCompletedCourseId courseId: String) -> [CollectionProgressEvent] {
        ContentCatalog.activeCollections.compactMap { collection in
            guard collection.courseIds.contains(courseId) else { return nil }
            let newCount = completedCount(for: collection)
            let previousCount = max(0, newCount - 1)
            guard newCount > previousCount else { return nil }
            return CollectionProgressEvent(
                collection: collection,
                previousCompletedCount: previousCount,
                newCompletedCount: newCount,
                totalCount: collection.courseIds.count
            )
        }
    }

    var quizStatsSummary: QuizStatsSummary {
        let quizCourseIds = Set(progress.completedQuizCourseIds)
        let quizCourses = ContentCatalog.activeCourses.filter { quizCourseIds.contains($0.id) && !$0.quiz.isEmpty }
        let earned = quizCourses.reduce(0) { partial, course in
            partial + (progress.courseProgress[course.id]?.bestQuizScore ?? 0)
        }
        let total = quizCourses.reduce(0) { $0 + $1.quiz.maxPoints }
        return QuizStatsSummary(
            completedQuizCount: quizCourses.count,
            earnedPoints: earned,
            totalPoints: total
        )
    }

    /// Recent quizzes (courses completed with a quiz score), most recent first.
    /// `score`/`totalPoints` are in points, not a raw correct-answer count.
    var recentQuizzes: [(course: Course, score: Int, totalPoints: Int, date: Date)] {
        let entries: [(String, CourseProgress, Date)] = progress.courseProgress.compactMap { id, cp in
            guard cp.isCompleted, progress.completedQuizCourseIds.contains(id), let dateStr = cp.lastQuizDate,
                  let date = ISO8601DateFormatter().date(from: dateStr) else { return nil }
            return (id, cp, date)
        }
        let sorted = entries.sorted { $0.2 > $1.2 }
        return sorted.compactMap { id, cp, date in
            guard let course = ContentCatalog.activeCourses.first(where: { $0.id == id }) else { return nil }
            return (course, cp.bestQuizScore, course.quiz.maxPoints, date)
        }
    }

    // MARK: - Training (spaced-repetition review of already-answered quiz questions)

    /// Days until the next review after a correct answer, indexed by how many times in a
    /// row the question has already been answered correctly (capped at the last value).
    /// A wrong answer at any point resets the question to due-immediately (index 0, no date).
    static let trainingIntervalDays: [Int] = [1, 3, 7, 14, 30]

    /// Adds any of these question ids to the review pool that aren't already tracked, due
    /// immediately. Called once a course's quiz has been completed — safe to call again on
    /// a retry, existing question states are left untouched.
    func registerTrainingQuestions(courseId: String, questionIds: [String]) {
        var didChange = false
        for questionId in questionIds where progress.trainingQuestionStates[questionId] == nil {
            progress.trainingQuestionStates[questionId] = TrainingQuestionState(courseId: courseId)
            didChange = true
        }
        if didChange { save() }
    }

    /// Questions whose scheduled review date has arrived (or that have never been reviewed
    /// yet), each paired with the course it belongs to. Looked up against the catalog in the
    /// currently active language, so a question removed from the content bundle simply
    /// drops out of the pool rather than erroring.
    var dueTrainingQuestions: [(course: Course, question: QuizQuestion)] {
        let now = Date()
        let formatter = ISO8601DateFormatter()
        let dueIds = progress.trainingQuestionStates.keys.filter { questionId in
            guard let dateStr = progress.trainingQuestionStates[questionId]?.nextReviewDate,
                  let date = formatter.date(from: dateStr) else { return true }
            return date <= now
        }
        let courses = ContentCatalog.activeCourses
        return dueIds.compactMap { questionId in
            for course in courses {
                if let question = course.quiz.first(where: { $0.id == questionId }) {
                    return (course, question)
                }
            }
            return nil
        }
    }

    /// Records the outcome of one training review. A correct answer pushes the question
    /// further out along `trainingIntervalDays`; a wrong answer resets it to due-immediately,
    /// as if it had never been reviewed — purely a memorization aid, no XP/streak impact.
    func recordTrainingAnswer(questionId: String, courseId: String, correct: Bool) {
        var state = progress.trainingQuestionStates[questionId] ?? TrainingQuestionState(courseId: courseId)
        if correct {
            let days = Self.trainingIntervalDays[min(state.intervalIndex, Self.trainingIntervalDays.count - 1)]
            let nextDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
            state.nextReviewDate = ISO8601DateFormatter().string(from: nextDate)
            state.intervalIndex = min(state.intervalIndex + 1, Self.trainingIntervalDays.count - 1)
        } else {
            state.intervalIndex = 0
            state.nextReviewDate = nil
        }
        progress.trainingQuestionStates[questionId] = state
        save()
    }

    func resetProgress() {
        progress = .empty
        save()
    }

    var completedCount: Int {
        progress.courseProgress.values.filter(\.isCompleted).count
    }

    func isFavorite(_ courseId: String) -> Bool {
        progress.favoriteCourseIds.contains(courseId)
    }

    func toggleFavorite(_ courseId: String) {
        if let index = progress.favoriteCourseIds.firstIndex(of: courseId) {
            progress.favoriteCourseIds.remove(at: index)
        } else {
            progress.favoriteCourseIds.append(courseId)
        }
        save()
    }

    /// True if the user already completed (swiped to last slide + tapped Continuer) a course today.
    /// Used for the freemium daily gate — resets at local midnight.
    var hasCompletedCourseToday: Bool {
        guard let last = progress.lastCourseCompletedDate else { return false }
        return last == dateFormatter.string(from: Date())
    }

    /// Marks today as the date the user fully completed a course. Called when the user taps
    /// the bottom button on the last lesson slide (regardless of whether a quiz follows).
    func markCourseCompletedToday() {
        progress.lastCourseCompletedDate = dateFormatter.string(from: Date())
        save()
    }

    /// True if the streak celebration screen has not been shown yet today (local day).
    /// Used to only display the streak page once per day across course/quiz completions.
    var shouldShowStreakToday: Bool {
        guard let last = progress.lastStreakShownDate else { return true }
        return last != dateFormatter.string(from: Date())
    }

    /// Marks the streak celebration screen as shown today.
    func markStreakShownToday() {
        progress.lastStreakShownDate = dateFormatter.string(from: Date())
        save()
    }

    /// DEBUG helper: clears the daily course flag so the user can read another free course immediately.
    func resetDailyCourseFlag() {
        progress.lastCourseCompletedDate = nil
        save()
    }

    var freeCoursesOpened: Int { progress.freeCoursesOpened }

    func incrementFreeCoursesOpened() {
        progress.freeCoursesOpened += 1
        save()
    }

    var hasSeenSwipeTutorial: Bool { progress.hasSeenSwipeTutorial }

    func markSwipeTutorialSeen() {
        progress.hasSeenSwipeTutorial = true
        save()
    }

    var hasSeenSpecialOffer: Bool { progress.hasSeenSpecialOffer }

    func markSpecialOfferSeen() {
        progress.hasSeenSpecialOffer = true
        save()
    }

    var favoriteCourses: [Course] {
        ContentCatalog.activeCourses.filter { progress.favoriteCourseIds.contains($0.id) }
    }

    private func updateStreak() {
        let today = dateFormatter.string(from: Date())
        guard let lastDate = progress.lastActiveDate else { return }

        if lastDate == today { return }

        let yesterday = dateFormatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        if lastDate != yesterday {
            progress.streak = 0
            save()
        }
    }

    private func recordActivity() {
        let today = dateFormatter.string(from: Date())
        if progress.lastActiveDate != today {
            let previousStreak = progress.streak
            if let lastDate = progress.lastActiveDate {
                let yesterday = dateFormatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
                if lastDate == yesterday {
                    progress.streak += 1
                } else {
                    progress.streak = 1
                }
            } else {
                progress.streak = 1
            }
            progress.lastActiveDate = today
            save()
            AnalyticsService.trackStreakUpdated(
                streakDays: progress.streak,
                isNewRecord: progress.streak > previousStreak
            )
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(UserProgress.self, from: data) else { return }
        progress = decoded
    }

    private func save() {
        persistLocally()
        ProgressSyncService.shared.schedulePush(progress)
    }

    private func persistLocally() {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    // MARK: - App Store review (once per install, first course only)

    private static let appReviewRequestedKey = "sophia_app_store_review_requested"
    private static let firstCourseOpenedKey = "sophia_first_course_opened_id"

    var hasRequestedAppStoreReview: Bool {
        UserDefaults.standard.bool(forKey: Self.appReviewRequestedKey)
    }

    func markAppStoreReviewRequested() {
        UserDefaults.standard.set(true, forKey: Self.appReviewRequestedKey)
    }

    var firstCourseOpenedId: String? {
        UserDefaults.standard.string(forKey: Self.firstCourseOpenedKey)
    }

    func registerFirstCourseOpenedIfNeeded(_ courseId: String) {
        guard firstCourseOpenedId == nil else { return }
        UserDefaults.standard.set(courseId, forKey: Self.firstCourseOpenedKey)
    }
}

nonisolated enum CourseStatus: Sendable {
    case notStarted, inProgress, completed
}
