import Foundation
import Combine

@MainActor
final class ProgressManager: ObservableObject {
    @Published var progress: UserProgress = .empty

    private let key = "sophia_user_progress"
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init() {
        load()
        updateStreak()
    }

    var streak: Int { progress.streak }

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

    func completeCourse(courseId: String, quizScore: Int) {
        var cp = progress.courseProgress[courseId] ?? CourseProgress(lastLessonIndex: 0, isCompleted: false, bestQuizScore: 0)
        cp.isCompleted = true
        if quizScore > cp.bestQuizScore {
            cp.bestQuizScore = quizScore
        }
        progress.courseProgress[courseId] = cp
        recordActivity()
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
        }
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
