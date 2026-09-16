import Foundation
import Observation

/// Holds a `sophia://course/…` request until the home screen is in a position to open it.
///
/// Two failures this replaces:
///
///  - A link opened **during the onboarding** was written to a binding that only `ContentView`
///    observed. `ContentView` was not in the hierarchy yet, and `onChange` does not replay the
///    value it was born with, so the link was silently dropped and the user landed on home
///    with nothing to show for the tap.
///  - Opening the **same link twice** did nothing the second time. The id was cleared on open,
///    but any path that left it set — or that re-delivered the identical value inside one
///    update pass — gave `onChange` an old and new value that matched, and a request that
///    compares equal to the last one is not a change. [token] makes every request distinct,
///    so re-opening the same course is always a new request.
@Observable
@MainActor
final class DeepLinkRouter {
    static let shared = DeepLinkRouter()

    private(set) var pendingCourseId: String?
    /// Increments on every request, so two requests for the same course are still two events.
    private(set) var token: Int = 0

    private init() {}

    func requestCourse(_ courseId: String) {
        pendingCourseId = courseId
        token += 1
    }

    /// Takes the pending course, if there is one. Returns nil once it has been handled.
    func consume() -> String? {
        defer { pendingCourseId = nil }
        return pendingCourseId
    }

    /// Drops a request that cannot be served — an id no longer in the catalogue, say — so it
    /// does not sit there being retried on every appearance.
    func discard() {
        pendingCourseId = nil
    }
}
