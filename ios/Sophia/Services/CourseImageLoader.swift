import UIKit

/// Where a course image comes from, and the cache in front of it.
///
/// Two homes, like on Android:
///  - the **covers** (the hero of each course, also the card on the home) stay in the
///    bundle under `CourseImages/`, so the home and the free intro page work offline;
///  - every **other** course image is served by the public Supabase bucket
///    `course-images`, the same objects Android reads. They used to weigh 100 MB in the
///    app for pictures most readers never open.
///
/// A slug is resolved through `CourseImageAliases` to the object name, which is also
/// the file name in the bundle. Downloads are kept in the Caches directory, so an image
/// is fetched once per install; the memory cache covers the paging back and forth.
enum CourseImageLoader {
    private static let memory: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 60
        return cache
    }()

    private static let bucketURL: URL? = {
        URL(string: AppConfig.SUPABASE_URL)?
            .appendingPathComponent("storage/v1/object/public/course-images")
    }()

    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        // The file cache below is the durable one; a second copy in URLCache is waste.
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 20
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }()

    private static let fetcher = Fetcher()

    // MARK: - Resolution

    /// Object name in the bucket, which is also the file name in the bundle.
    static func objectName(for rawSlug: String) -> String {
        let slug = CourseInlineImage.slug(rawSlug)
        return CourseImageAliases.map[slug] ?? slug
    }

    static func remoteURL(for rawSlug: String) -> URL? {
        bucketURL?.appendingPathComponent(objectName(for: rawSlug) + ".jpg")
    }

    // MARK: - Synchronous fast paths

    /// The image when no network is needed: bundled cover, memory cache, or a file this
    /// install already downloaded. Views start from this so a cached image never flashes.
    static func cached(_ rawSlug: String) -> UIImage? {
        let name = objectName(for: rawSlug)
        if let image = memory.object(forKey: name as NSString) { return image }
        if let image = CourseInlineImage.loadImage(named: CourseInlineImage.slug(rawSlug)) {
            memory.setObject(image, forKey: name as NSString)
            return image
        }
        if let image = diskCached(name) {
            memory.setObject(image, forKey: name as NSString)
            return image
        }
        return nil
    }

    // MARK: - Loading

    /// The image from wherever it is, nil when it exists nowhere or the network failed.
    static func image(for rawSlug: String) async -> UIImage? {
        if let image = cached(rawSlug) { return image }
        return await fetcher.fetch(objectName(for: rawSlug))
    }

    /// Warms the images of a course while the reader shows its first page, so paging
    /// forward finds them already on disk. Fire and forget.
    static func prefetch(courseId: String, language: AppLanguage = AppLanguage.currentPersisted()) {
        guard let content = CourseContentStore.content(courseId: courseId, language: language) else { return }
        var slugs: [String] = []
        for section in content.sections {
            for case .image(let block) in section.blocks {
                slugs.append(block.asset)
            }
        }
        prefetch(slugs)
    }

    static func prefetch(_ rawSlugs: [String]) {
        let pending = rawSlugs.filter { cached($0) == nil }
        guard !pending.isEmpty else { return }
        Task.detached(priority: .utility) {
            for slug in pending {
                _ = await CourseImageLoader.image(for: slug)
            }
        }
    }

    // MARK: - Disk cache

    private static let cacheDirectory: URL? = {
        guard let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let directory = base.appendingPathComponent("CourseImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }()

    private static func cacheFile(_ name: String) -> URL? {
        cacheDirectory?.appendingPathComponent(name + ".jpg")
    }

    private static func diskCached(_ name: String) -> UIImage? {
        guard let file = cacheFile(name),
              let data = try? Data(contentsOf: file),
              let image = UIImage(data: data) else { return nil }
        return image
    }

    fileprivate static func store(_ data: Data, image: UIImage, name: String) {
        memory.setObject(image, forKey: name as NSString)
        if let file = cacheFile(name) {
            try? data.write(to: file, options: .atomic)
        }
    }

    fileprivate static func download(_ name: String) async -> UIImage? {
        guard let url = bucketURL?.appendingPathComponent(name + ".jpg") else { return nil }
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let image = UIImage(data: data) else { return nil }
            store(data, image: image, name: name)
            return image
        } catch {
            return nil
        }
    }

    /// One download per object at a time: the hero, the prefetch and a block that asks
    /// for the same picture share the request instead of racing for it.
    private actor Fetcher {
        private var inFlight: [String: Task<UIImage?, Never>] = [:]

        func fetch(_ name: String) async -> UIImage? {
            if let task = inFlight[name] { return await task.value }
            let task = Task { await CourseImageLoader.download(name) }
            inFlight[name] = task
            let image = await task.value
            inFlight[name] = nil
            return image
        }
    }
}
