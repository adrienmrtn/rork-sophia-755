import SwiftUI

/// Une image hébergée (https) : téléchargée une fois, gardée en mémoire et dans
/// Library/Caches/RemoteImages ; rien n'est dessiné tant qu'elle n'est pas là, le fond du parent
/// reste visible. Même approche que le portrait hébergé d'un créateur (`AuthorStore.remotePhoto`).
struct RemoteImage: View {
    let url: String?
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .task(id: url) {
            guard let url else {
                image = nil
                return
            }
            if let cached = RemoteImageLoader.cached(url) {
                image = cached
                return
            }
            image = await RemoteImageLoader.image(url)
        }
        .accessibilityHidden(true)
    }
}

enum RemoteImageLoader {
    private static let cache = NSCache<NSString, UIImage>()

    static func cached(_ raw: String) -> UIImage? {
        cache.object(forKey: raw as NSString)
    }

    static func image(_ raw: String) async -> UIImage? {
        guard let url = URL(string: raw), url.scheme == "https" else { return nil }
        let key = raw as NSString
        if let cached = cache.object(forKey: key) { return cached }
        let file = cacheURL(for: raw)
        if let file, let data = try? Data(contentsOf: file), let image = UIImage(data: data) {
            cache.setObject(image, forKey: key)
            return image
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        guard let result = try? await URLSession.shared.data(for: request),
              (result.1 as? HTTPURLResponse)?.statusCode == 200,
              let image = UIImage(data: result.0) else { return nil }
        cache.setObject(image, forKey: key)
        if let file {
            try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? result.0.write(to: file, options: .atomic)
        }
        return image
    }

    private static func cacheURL(for raw: String) -> URL? {
        guard let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let safe = String(raw.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? Character($0) : "_" }).suffix(120)
        return base.appendingPathComponent("RemoteImages").appendingPathComponent("\(safe).img")
    }
}

extension Int {
    /// « 12 840 », « 12,840 » : le nombre groupé dans la langue de l'app (même chose qu'Android).
    func formatted(language: AppLanguage) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = language.foundationLocale
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
