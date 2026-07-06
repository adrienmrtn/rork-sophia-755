import Foundation

/// Centralized freemium rules for V7.
///
/// Free users can open any course and read lesson 1 (intro). Lessons 2+ show a
/// blurred teaser with an in-course unlock CTA. Course completion and quizzes
/// require premium.
enum FreemiumGate {
    /// Lesson index 0 is the free intro; pages 2+ are teaser-only for free users.
    static func isLessonContentLocked(lessonIndex: Int, isPremium: Bool) -> Bool {
        !isPremium && lessonIndex >= 1
    }

    static func canCompleteCourse(isPremium: Bool) -> Bool {
        isPremium
    }
}
