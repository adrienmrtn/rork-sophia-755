import CryptoKit
import UIKit

/// Les créateurs de cours, lus dans le catalogue en ligne (`CatalogStore`, section `creators`),
/// et leurs portraits : embarqués (`Resources/AuthorPhotos/<photo>.jpg`) pour les auteurs du
/// pack, hébergés (`photoUrl`) pour les créateurs du Studio.
///
/// Chaque créateur porte les `courseIds` de ses cours publiés dans la langue : « les autres
/// cours de ce professeur » se répond sans décoder un seul cours.
enum AuthorStore {
    private static let photoCache = NSCache<NSString, UIImage>()

    static func resetCache() {
        photoCache.removeAllObjects()
        CatalogStore.shared.resetMemory()
    }

    static var all: [CourseAuthor] {
        CatalogStore.shared.snapshot(for: AppLanguage.currentPersisted()).authors
    }

    static func author(slug: String) -> CourseAuthor? {
        all.first { $0.slug == slug }
    }

    static func author(forCourseId courseId: String) -> CourseAuthor? {
        all.first { $0.courseIds.contains(courseId) }
    }

    /// Le portrait du créateur, ou nil quand il n'en a pas (les vues dessinent alors ses initiales).
    static func photo(for author: CourseAuthor) -> UIImage? {
        guard let name = author.photo, !name.isEmpty else { return nil }
        if let cached = photoCache.object(forKey: name as NSString) { return cached }
        guard let image = loadPhoto(named: name) else { return nil }
        photoCache.setObject(image, forKey: name as NSString)
        return image
    }

    /// Le portrait d'un créateur du Studio (`photoUrl`) quand il n'est pas embarqué : téléchargé une
    /// fois, gardé en mémoire et dans Library/Caches/AuthorPhotos ; nil sans réseau la première fois
    /// (les vues gardent alors les initiales).
    static func remotePhoto(for author: CourseAuthor) async -> UIImage? {
        if let image = photo(for: author) { return image }
        guard let raw = author.photoUrl, let url = URL(string: raw), url.scheme == "https" else { return nil }
        let key = raw as NSString
        if let cached = photoCache.object(forKey: key) { return cached }
        let file = remoteCacheURL(for: raw)
        if let file, let data = try? Data(contentsOf: file), let image = UIImage(data: data) {
            photoCache.setObject(image, forKey: key)
            return image
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        guard let result = try? await URLSession.shared.data(for: request),
              (result.1 as? HTTPURLResponse)?.statusCode == 200,
              let image = UIImage(data: result.0) else { return nil }
        photoCache.setObject(image, forKey: key)
        if let file {
            try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? result.0.write(to: file, options: .atomic)
        }
        return image
    }

    private static func remoteCacheURL(for raw: String) -> URL? {
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let name = SHA256.hash(data: Data(raw.utf8)).map { String(format: "%02x", $0) }.joined()
        return caches.appendingPathComponent("AuthorPhotos", isDirectory: true).appendingPathComponent("\(name).jpg")
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

    /// Xcode peut aplatir le dossier `Resources` ou le garder en référence de dossier : les deux
    /// dispositions sont essayées.
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
            let candidate = root.appendingPathComponent(subdirectory).appendingPathComponent("\(name).\(ext)")
            if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
        }
        return nil
    }
}
