import Foundation

@MainActor
final class CourseSessionTracker {
    let courseId: String
    let subject: Subject
    let lessonCount: Int
    private let startedAt = Date()

    var maxLessonIndex = 0
    var continueTaps = 0
    var scrolledOnFirstLesson = false
    var completed = false

    init(course: Course) {
        courseId = course.id
        subject = course.subject
        lessonCount = course.lessons.count
    }

    func recordLessonIndex(_ index: Int) {
        maxLessonIndex = max(maxLessonIndex, index)
    }

    func recordContinueTap() {
        continueTaps += 1
    }

    func markCompleted() {
        completed = true
    }

    func finish(exitReason: String) {
        let duration = max(0, Int(Date().timeIntervalSince(startedAt)))
        let lessonsReached = maxLessonIndex + 1
        let tier = AnalyticsService.engagementTier(
            durationSeconds: duration,
            lessonsReached: lessonsReached,
            lessonCount: lessonCount,
            continueTaps: continueTaps,
            scrolledOnFirstLesson: scrolledOnFirstLesson,
            completed: completed
        )
        AnalyticsService.trackCourseSessionEnded(
            courseId: courseId,
            subject: subject,
            durationSeconds: duration,
            lessonsReached: lessonsReached,
            lessonCount: lessonCount,
            continueTaps: continueTaps,
            scrolledOnFirstLesson: scrolledOnFirstLesson,
            engagementTier: tier,
            exitReason: exitReason
        )
    }
}
