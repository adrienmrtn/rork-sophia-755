import Foundation

enum SophiaDeepLink {
    static let scheme = "sophia"

    static func courseURL(for courseId: String) -> URL? {
        URL(string: "\(scheme)://course/\(courseId)")
    }

    /// `sophia://author/<slug>` (le bouton « Follow in the app » du site) ; `creator` accepté aussi.
    static func authorURL(for slug: String) -> URL? {
        URL(string: "\(scheme)://author/\(slug)")
    }

    static func creatorSlug(from url: URL) -> String? {
        guard url.scheme == scheme, let host = url.host, host == "author" || host == "creator" else { return nil }
        let slug = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return slug.isEmpty ? nil : slug
    }

    /// `sophia://unlock`: the TikTok blocker's notification. Opening it is the same as
    /// tapping "Open Sophia" on the shield.
    static func isUnlockRequest(_ url: URL) -> Bool {
        url.scheme == scheme && url.host == "unlock"
    }

    // MARK: - Liens web (sophia-culture.com)

    /// Le site public. Ses pages `/courses/…` et `/authors/…` sont des liens universels : app
    /// installée, iOS les ouvre dans Sophia ; sinon la page montre le cours et mène au store.
    static let webHost = "sophia-culture.com"

    /// Ce que désigne une adresse du site.
    enum WebTarget: Equatable {
        /// `/courses/150` ou `/courses/150-why-does-the-sky-swirl` : le numéro du cours.
        case courseNumber(Int)
        /// `/c/<identifiant>` : l'identifiant complet, pour un cours sans numéro.
        case courseId(String)
        /// `/authors/<slug>`.
        case creator(String)
    }

    /// L'adresse à partager pour un cours : `https://sophia-culture.com/courses/150` (le site
    /// redirige vers l'adresse lisible), ou `/c/<identifiant>` quand l'identifiant n'a pas de numéro.
    static func courseWebURL(for courseId: String) -> URL? {
        if let number = courseNumber(in: courseId) {
            return URL(string: "https://\(webHost)/courses/\(number)")
        }
        guard let escaped = courseId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }
        return URL(string: "https://\(webHost)/c/\(escaped)")
    }

    static func authorWebURL(for slug: String) -> URL? {
        guard let escaped = slug.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }
        return URL(string: "https://\(webHost)/authors/\(escaped)")
    }

    /// `course_150_la_nuit_etoilee` → 150 ; nil si l'identifiant n'a pas cette forme.
    static func courseNumber(in courseId: String) -> Int? {
        let parts = courseId.split(separator: "_", maxSplits: 2)
        guard parts.count == 3, parts[0] == "course" else { return nil }
        return Int(parts[1])
    }

    /// Une adresse du site qui désigne un cours ou un créateur ; nil pour tout le reste.
    static func webTarget(from url: URL) -> WebTarget? {
        guard url.scheme == "https" || url.scheme == "http",
              let host = url.host?.lowercased(), host == webHost || host == "www.\(webHost)"
        else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count >= 2 else { return nil }
        switch parts[0] {
        case "courses":
            // Le numéro ouvre l'adresse : `150-why-does…` → 150.
            let digits = parts[1].prefix { $0.isNumber }
            guard let number = Int(digits) else { return nil }
            return .courseNumber(number)
        case "c":
            return .courseId(parts[1])
        case "authors":
            return .creator(parts[1])
        default:
            return nil
        }
    }

    /// Le texte partagé pour un cours : la phrase habituelle, suivie du lien du cours.
    @MainActor
    static func shareText(for course: Course, language: AppLanguage) -> String {
        let message = String(format: AppLocalizable.string("share.course.message", language: language), course.title.withoutInlineMarkup)
        guard let url = courseWebURL(for: course.id) else { return message }
        return "\(message) \(url.absoluteString)"
    }

    /// Le texte partagé pour un créateur : la phrase habituelle, suivie du lien de sa page.
    @MainActor
    static func shareText(for author: CourseAuthor, language: AppLanguage) -> String {
        let message = String(format: AppLocalizable.string("share.creator.message", language: language), author.name)
        guard let url = authorWebURL(for: author.slug) else { return message }
        return "\(message) \(url.absoluteString)"
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
