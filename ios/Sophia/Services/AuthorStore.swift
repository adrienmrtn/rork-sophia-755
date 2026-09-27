import UIKit

/// Bundled course authors (`Resources/authors.json`) and their portraits
/// (`Resources/AuthorPhotos/<photo>.jpg`).
///
/// One file for every author: it is small, and it lets "other courses by this professor"
/// be answered from the author's `courseIds` without decoding a single course.
enum AuthorStore {
    private struct Payload: Decodable {
        let authors: [CourseAuthor]
    }

    private static var loaded: [CourseAuthor]?
    private static let photoCache = NSCache<NSString, UIImage>()

    static func resetCache() {
        loaded = nil
        photoCache.removeAllObjects()
    }

    static var all: [CourseAuthor] {
        if let loaded { return loaded }
        let authors = load()
        loaded = authors
        return authors
    }

    static func author(slug: String) -> CourseAuthor? {
        all.first { $0.slug == slug }
    }

    static func author(forCourseId courseId: String) -> CourseAuthor? {
        all.first { $0.courseIds.contains(courseId) }
    }

    /// The author's portrait, or nil when the author has none (the views then draw initials).
    static func photo(for author: CourseAuthor) -> UIImage? {
        guard let name = author.photo, !name.isEmpty else { return nil }
        if let cached = photoCache.object(forKey: name as NSString) { return cached }
        guard let image = loadPhoto(named: name) else { return nil }
        photoCache.setObject(image, forKey: name as NSString)
        return image
    }

    // MARK: - Loading

    private static func load() -> [CourseAuthor] {
        guard let url = resourceURL(name: "authors", ext: "json", subdirectories: ["Resources", ""]) else {
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Payload.self, from: data).authors
        } catch {
            assertionFailure("Failed to decode authors.json: \(error)")
            return []
        }
    }

    private static func loadPhoto(named name: String) -> UIImage? {
        for ext in ["jpg", "jpeg", "png"] {
            if let url = resourceURL(name: name, ext: ext, subdirectories: ["Resources/AuthorPhotos", "AuthorPhotos", ""]),
               let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                return image
            }
        }
        return UIImage(named: name)
    }

    /// Same tolerance as the other bundled resources: Xcode may flatten the `Resources`
    /// folder or keep it as a folder reference, so both layouts are tried.
    private static func resourceURL(name: String, ext: String, subdirectories: [String]) -> URL? {
        let bundle = Bundle.main
        for subdirectory in subdirectories {
            if subdirectory.isEmpty {
                if let url = bundle.url(forResource: name, withExtension: ext) { return url }
            } else if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
                return url
            }
        }
        guard let root = bundle.resourceURL else { return nil }
        for subdirectory in subdirectories {
            let candidate = root
                .appendingPathComponent(subdirectory)
                .appendingPathComponent("\(name).\(ext)")
            if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
        }
        return nil
    }
}
