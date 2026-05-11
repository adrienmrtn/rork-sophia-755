import Foundation
import Combine
import UserNotifications

@MainActor
final class ProgressManager: ObservableObject {
    @Published var progress: UserProgress = .empty
    @Published var didBreakStreakToday: Bool = false
    @Published var didUseShieldToday: Bool = false

    private let key = "sophia_user_progress"
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init() {
        load()
        applyThemeRegressionIfNeeded()
        updateStreak()
        didBreakStreakToday = progress.streakBrokenDate == dateFormatter.string(from: Date())
        didUseShieldToday = progress.shieldUsedDate == dateFormatter.string(from: Date())
    }

    var streak: Int { progress.streak }
    var shieldCount: Int { progress.shieldCount }
    var shieldProtectedStreakValue: Int? { progress.shieldProtectedStreak }
    var hasCompletedDailyFreeCourseToday: Bool {
        let today = dateFormatter.string(from: Date())
        return progress.dailyFreeCourseCompletedDate == today
    }

    var hasDoneAnyCourseToday: Bool {
        let today = dateFormatter.string(from: Date())
        return progress.lastActiveDate == today
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
        var cp = progress.courseProgress[courseId] ?? CourseProgress(lastLessonIndex: 0, isCompleted: false, bestQuizScore: 0, completedDate: nil)
        if lessonIndex > cp.lastLessonIndex {
            cp.lastLessonIndex = lessonIndex
        }
        progress.courseProgress[courseId] = cp
        save()
    }

    func completeCourse(courseId: String, quizScore: Int) {
        var cp = progress.courseProgress[courseId] ?? CourseProgress(lastLessonIndex: 0, isCompleted: false, bestQuizScore: 0, completedDate: nil)
        let wasCompleted = cp.isCompleted
        cp.isCompleted = true
        if cp.completedDate == nil {
            cp.completedDate = dateFormatter.string(from: Date())
        }
        if quizScore > cp.bestQuizScore {
            cp.bestQuizScore = quizScore
        }
        progress.courseProgress[courseId] = cp
        recordActivity()
        markDailyFreeCourseCompletedIfNeeded(courseId: courseId)
        awardThemeProgressIfNeeded(courseId: courseId, quizScore: quizScore)
        save()

        if !wasCompleted, completedCount == 3 {
            NotificationCenter.default.post(name: .sophiaRequestReview, object: nil)
        }
    }

    func recordReadingActivity() {
        recordActivity()
        let objective = UserDefaults.standard.string(forKey: "sophia_onboarding_primary_objective")
        rescheduleDailyNotifications(primaryObjective: objective)
    }

    func canOpenFreeCourseToday(courseId: String) -> Bool {
        resetDailyFreeCourseIfNeeded()
        if hasCompletedDailyFreeCourseToday { return false }
        guard let lockedId = progress.dailyFreeCourseId else { return true }
        return lockedId == courseId
    }

    func reserveTodayFreeCourseIfNeeded(courseId: String) {
        resetDailyFreeCourseIfNeeded()
        if progress.dailyFreeCourseId == nil {
            progress.dailyFreeCourseId = courseId
            progress.dailyFreeCourseDate = dateFormatter.string(from: Date())
            save()
        }
    }

    func resetProgress() {
        progress = .empty
        save()
    }

    var completedCount: Int {
        progress.courseProgress.values.filter(\.isCompleted).count
    }

    var lastActiveDateString: String? { progress.lastActiveDate }

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
        CourseData.allCourses.filter { progress.favoriteCourseIds.contains($0.id) }
    }

    func completionDateString(for courseId: String) -> String? {
        progress.courseProgress[courseId]?.completedDate
    }

    func themePoints(for subject: Subject) -> Int {
        progress.themeProgress[subject.rawValue]?.points ?? 0
    }

    private func awardThemeProgressIfNeeded(courseId: String, quizScore: Int) {
        guard let subject = CourseData.allCourses.first(where: { $0.id == courseId })?.subject else { return }

        resetDailyFreeCourseIfNeeded()

        let base = 1
        let bonus: Int
        if quizScore >= 4 {
            bonus = 2
        } else if quizScore == 3 {
            bonus = 1
        } else {
            bonus = 0
        }
        let gain = base + bonus

        var state = progress.themeProgress[subject.rawValue] ?? .empty
        let beforeLevel = levelForPoints(state.points)
        state.points += gain
        state.lastGainDate = dateFormatter.string(from: Date())
        state.lastGainAmount = gain
        progress.themeProgress[subject.rawValue] = state

        let afterLevel = levelForPoints(state.points)
        if afterLevel != beforeLevel {
            scheduleLocalNotification(
                identifier: "sophia_levelup_\(subject.rawValue)_\(dateFormatter.string(from: Date()))",
                title: "Nouveau niveau 🎉",
                body: "Tu viens de passer \(afterLevel) en \(subject.shortName) 🎉",
                hour: 0,
                minute: 0,
                fireImmediately: true
            )
            NotificationCenter.default.post(name: .sophiaRequestReview, object: nil)
        }
    }

    private func updateStreak() {
        let today = dateFormatter.string(from: Date())
        guard let lastDate = progress.lastActiveDate else { return }

        if lastDate == today { return }

        let yesterday = dateFormatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        if lastDate != yesterday {
            let isPremium = UserDefaults.standard.bool(forKey: "sophia_is_premium")
            let dayBeforeYesterday = dateFormatter.string(from: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date())
            if isPremium, progress.shieldCount > 0, lastDate == dayBeforeYesterday {
                progress.shieldCount = max(0, progress.shieldCount - 1)
                progress.shieldUsedDate = today
                progress.shieldProtectedStreak = progress.streak
                didUseShieldToday = true
                progress.lastActiveDate = yesterday
                save()
                return
            }
            if progress.streak > 0 {
                progress.streakBrokenDate = today
                didBreakStreakToday = true
            }
            progress.streak = 0
            save()
        }
    }

    private func recordActivity() {
        let today = dateFormatter.string(from: Date())
        if progress.lastActiveDate != today {
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

            if progress.streak == 7 {
                NotificationCenter.default.post(name: .sophiaRequestReview, object: nil)
            }

            let isPremium = UserDefaults.standard.bool(forKey: "sophia_is_premium")
            if isPremium, progress.streak == 7, progress.shieldCount < 1 {
                progress.shieldCount = 1
                progress.shieldGrantedDate = today
                save()
            }
        }
    }

    private func resetDailyFreeCourseIfNeeded() {
        let today = dateFormatter.string(from: Date())
        if progress.dailyFreeCourseDate != today {
            progress.dailyFreeCourseDate = today
            progress.dailyFreeCourseId = nil
            progress.dailyFreeCourseCompletedDate = nil
            save()
        }
    }

    private func markDailyFreeCourseCompletedIfNeeded(courseId: String) {
        resetDailyFreeCourseIfNeeded()
        if progress.dailyFreeCourseId == courseId {
            progress.dailyFreeCourseCompletedDate = dateFormatter.string(from: Date())
        }
    }

    private func applyThemeRegressionIfNeeded() {
        let today = dateFormatter.string(from: Date())
        guard let lastDate = progress.lastActiveDate else { return }
        if lastDate == today { return }

        let yesterday = dateFormatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        if lastDate == yesterday { return }

        for subject in Subject.allCases {
            let key = subject.rawValue
            guard var state = progress.themeProgress[key] else { continue }
            if state.lastRegressionDate == today { continue }

            let currentLevel = levelForPoints(state.points)
            let minThreshold = minPointsForLevel(currentLevel)
            let loss = max(1, (state.lastGainAmount + 1) / 2)
            state.points = max(minThreshold, state.points - loss)
            state.lastRegressionDate = today
            progress.themeProgress[key] = state
        }
        save()
    }

    private func levelForPoints(_ points: Int) -> String {
        switch points {
        case 0...4: "Débutant"
        case 5...14: "Initié"
        case 15...29: "Érudit"
        case 30...49: "Expert"
        default: "Sage"
        }
    }

    private func minPointsForLevel(_ level: String) -> Int {
        switch level {
        case "Initié": 5
        case "Érudit": 15
        case "Expert": 30
        case "Sage": 50
        default: 0
        }
    }

    func requestNotificationsPermissionIfNeeded() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "sophia_notifications_permission_requested") { return }
        defaults.set(true, forKey: "sophia_notifications_permission_requested")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func rescheduleDailyNotifications(primaryObjective: String?) {
        let today = dateFormatter.string(from: Date())
        let ids = [
            "sophia_daily_reminder_\(today)",
            "sophia_streak_danger_\(today)",
            "sophia_regression_warning_\(today)",
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)

        if hasDoneAnyCourseToday { return }

        scheduleLocalNotification(
            identifier: "sophia_daily_reminder_\(today)",
            title: "Sophia",
            body: dailyReminderBody(primaryObjective: primaryObjective),
            hour: 19,
            minute: 0
        )

        if streak >= 2 {
            scheduleLocalNotification(
                identifier: "sophia_streak_danger_\(today)",
                title: "Sophia",
                body: "Ta série de \(streak) jours finit dans 4h — 5 min suffisent",
                hour: 20,
                minute: 0
            )
        }

        if progress.lastActiveDate != nil, daysSinceLastActive() >= 2, let theme = mostAtRiskThemeName() {
            scheduleLocalNotification(
                identifier: "sophia_regression_warning_\(today)",
                title: "Sophia",
                body: "Ta progression \(theme) commence à diminuer — reviens aujourd'hui",
                hour: 19,
                minute: 30
            )
        }
    }

    private func scheduleLocalNotification(identifier: String, title: String, body: String, hour: Int, minute: Int, fireImmediately: Bool = false) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger: UNNotificationTrigger
        if fireImmediately {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        } else {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = hour
            components.minute = minute
            components.second = 0
            if let date = Calendar.current.date(from: components), date <= Date() {
                return
            }
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }

        let req = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    private func dailyReminderBody(primaryObjective: String?) -> String {
        let v = primaryObjective ?? ""
        if v.contains("Impressionner") {
            return "Un truc à dire ce soir — ton cours t'attend"
        }
        if v.contains("scroller") || v.contains("scroll") || v.contains("Réduire") {
            return "Tu as scrollé ce matin ? Ton cours t'attend"
        }
        if v.contains("curieux") || v.contains("Curieux") || v.contains("Être plus curieux") {
            return "Quelque chose de nouveau t'attend aujourd'hui"
        }
        if v.contains("aisance") || v.contains("Aisance") || v.contains("Renforcer") {
            return "10 min pour enrichir tes conversations"
        }
        return "Quelque chose de nouveau t'attend aujourd'hui"
    }

    private func daysSinceLastActive() -> Int {
        guard let last = progress.lastActiveDate else { return 0 }
        guard let lastDate = dateFormatter.date(from: last) else { return 0 }
        let start = Calendar.current.startOfDay(for: lastDate)
        let now = Calendar.current.startOfDay(for: Date())
        return Calendar.current.dateComponents([.day], from: start, to: now).day ?? 0
    }

    private func mostAtRiskThemeName() -> String? {
        let sorted = Subject.allCases.sorted { a, b in
            themePoints(for: a) > themePoints(for: b)
        }
        return sorted.first?.shortName
    }



    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(UserProgress.self, from: data) else { return }
        progress = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

nonisolated enum CourseStatus: Sendable {
    case notStarted, inProgress, completed
}

extension Notification.Name {
    static let sophiaRequestReview = Notification.Name("sophia_request_review")
}
