import Foundation

enum SophiaDeepLink {
    static let scheme = "sophia"

    static func courseURL(for courseId: String) -> URL? {
        URL(string: "\(scheme)://course/\(courseId)")
    }

    /// `sophia://unlock`: the TikTok blocker's notification. Opening it is the same as
    /// tapping "Open Sophia" on the shield.
    static func isUnlockRequest(_ url: URL) -> Bool {
        url.scheme == scheme && url.host == "unlock"
    }

    static func courseId(from url: URL) -> String? {
        guard url.scheme == scheme else { return nil }

        if url.host == "course" {
            let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return id.isEmpty ? nil : id
        }

        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count >= 2, parts[0] == "course" else { return nil }
        return parts[1]
    }
}
