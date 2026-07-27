import Foundation

/// Centralized freemium rules.
///
/// Free users get **one free course per day** (the first course they open on a given local
/// day). That course is fully readable and can be completed. Every *other* course opened the
/// same day is intro-only (lesson 1): the bottom Continue button still slides between pages,
/// and lessons 2+ show a blurred teaser with a lock overlay that opens the `debloquer_cours`
/// paywall when tapped.
///
/// The quiz is always premium — even on the daily free course — and opens the `quizz` paywall.
enum FreemiumGate {
    /// Whether a lesson page must be hidden behind the blur + lock overlay.
    ///
    /// - Premium: nothing locked.
    /// - Daily free course: nothing locked (full read + completion).
    /// - Any other course that day: lesson index 0 (intro) is free, pages 2+ are locked.
    static func isLessonContentLocked(lessonIndex: Int, isPremium: Bool, isDailyFreeCourse: Bool) -> Bool {
        if isPremium || isDailyFreeCourse { return false }
        return lessonIndex >= 1
    }

    /// Whether the user may reach the course-completion screen (finish all pages).
    /// Allowed for premium users and for the daily free course.
    static func canCompleteCourse(isPremium: Bool, isDailyFreeCourse: Bool) -> Bool {
        isPremium || isDailyFreeCourse
    }
}
