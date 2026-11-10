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
    /// `sophia://author/<slug>` : la page d'un créateur, ouverte par la navigation en place.
    private(set) var pendingCreatorSlug: String?
    /// `sophia://friend/<handle>` : le @ d'un lecteur à ajouter en ami (QR code du profil). Le
    /// profil le lit et propose la demande d'ami.
    private(set) var pendingFriendHandle: String?
    /// Increments on every request, so two requests for the same course are still two events.
    private(set) var token: Int = 0

    private init() {}

    /// A `sophia://` link or a sophia-culture.com page, from `onOpenURL` or a notification tap.
    /// False when it is not ours.
    @discardableResult
    func open(_ url: URL) -> Bool {
        if SophiaDeepLink.isUnlockRequest(url) {
            // Same stamp the shield writes; the home screen reads it right away.
            TikTokBlockerShared.pendingRequestAt = Date()
            requestUnlock()
            return true
        }
        if let handle = SophiaDeepLink.friendHandle(from: url) {
            requestFriend(handle)
            return true
        }
        if let slug = SophiaDeepLink.creatorSlug(from: url) {
            requestCreator(slug)
            return true
        }
        // Un lien du site (lien universel, bannière Safari, lien repris après installation).
        if let target = SophiaDeepLink.webTarget(from: url) {
            switch target {
            case .creator(let slug):
                requestCreator(slug)
            case .courseId(let id):
                requestCourse(id)
            case .courseNumber(let number):
                // Le site ne connaît que le numéro ; un numéro absent du catalogue est ignoré.
                let prefix = "course_\(number)_"
                guard let course = ContentCatalog.activeCourses.first(where: { $0.id.hasPrefix(prefix) }) else { return false }
                requestCourse(course.id)
            }
            return true
        }
        guard let courseId = SophiaDeepLink.courseId(from: url) else { return false }
        // Parked rather than delivered: the onboarding may still be on screen, and the
        // home opens it as soon as it is ready.
        requestCourse(courseId)
        return true
    }

    func requestCreator(_ slug: String) {
        pendingCreatorSlug = slug
        token += 1
    }

    /// Takes the pending creator, if there is one.
    func consumeCreator() -> String? {
        defer { pendingCreatorSlug = nil }
        return pendingCreatorSlug
    }

    func discardCreator() {
        pendingCreatorSlug = nil
    }

    func requestFriend(_ handle: String) {
        pendingFriendHandle = handle
        token += 1
    }

    /// Takes the pending friend handle, if there is one.
    func consumeFriend() -> String? {
        defer { pendingFriendHandle = nil }
        return pendingFriendHandle
    }

    func requestCourse(_ courseId: String) {
        pendingCourseId = courseId
        token += 1
    }

    /// `sophia://unlock` (TikTok blocker). The request itself lives in the App Group
    /// stamp; this only wakes the home screen so it reads the stamp now rather than on
    /// its next foreground.
    func requestUnlock() {
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
