import Foundation

/// Keeps narration MP3s on disk so a course can be heard in the metro or on a
/// plane. Streaming-only would make the feature half-useful: people listen
/// exactly where there is no network.
///
/// Files live in Application Support, excluded from iCloud backup — they are
/// re-downloadable, and Apple rejects apps that back up such content.
@MainActor
@Observable
final class AudioDownloadManager {
    static let shared = AudioDownloadManager()

    enum State: Equatable {
        case absent
        case downloading(Double)
        case ready
    }

    private(set) var states: [String: State] = [:]
    private var tasks: [String: Task<Void, Never>] = [:]

    private init() {
        indexExistingFiles()
    }

    // MARK: - Paths

    private static var root: URL? {
        guard let support = try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        ) else { return nil }
        return support.appendingPathComponent("CourseAudio", isDirectory: true)
    }

    private static func fileURL(courseId: String, language: AppLanguage) -> URL? {
        root?
            .appendingPathComponent(language.rawValue, isDirectory: true)
            .appendingPathComponent("\(courseId).mp3")
    }

    private func key(_ courseId: String, _ language: AppLanguage) -> String {
        "\(language.rawValue)/\(courseId)"
    }

    // MARK: - Queries

    func state(courseId: String, language: AppLanguage) -> State {
        states[key(courseId, language)] ?? .absent
    }

    /// On-disk file if the download finished, else nil.
    func localURL(courseId: String, language: AppLanguage) -> URL? {
        guard case .ready = state(courseId: courseId, language: language),
              let url = Self.fileURL(courseId: courseId, language: language),
              FileManager.default.fileExists(atPath: url.path)
        else { return nil }
        return url
    }

    /// What the player should actually open: the local copy when there is one,
    /// the bucket otherwise.
    func playbackURL(courseId: String, language: AppLanguage) -> URL? {
        localURL(courseId: courseId, language: language)
            ?? CourseAudioCatalog.url(courseId: courseId, language: language)
    }

    var totalBytes: Int64 {
        guard let root = Self.root,
              let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.fileSizeKey])
        else { return 0 }
        var total: Int64 = 0
        for case let url as URL in walker {
            total += Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return total
    }

    // MARK: - Actions

    func download(courseId: String, language: AppLanguage) {
        let id = key(courseId, language)
        guard tasks[id] == nil, state(courseId: courseId, language: language) != .ready else { return }
        guard let remote = CourseAudioCatalog.url(courseId: courseId, language: language),
              let destination = Self.fileURL(courseId: courseId, language: language)
        else { return }

        states[id] = .downloading(0)
        tasks[id] = Task { [weak self] in
            defer { self?.tasks[id] = nil }
            do {
                try await Self.fetch(remote, to: destination) { fraction in
                    Task { @MainActor in
                        // A finished download flips to .ready below; don't let a
                        // late progress callback drag it back to .downloading.
                        if case .downloading = self?.states[id] {
                            self?.states[id] = .downloading(fraction)
                        }
                    }
                }
                self?.states[id] = .ready
            } catch {
                self?.states[id] = .absent
                try? FileManager.default.removeItem(at: destination)
            }
        }
    }

    func cancel(courseId: String, language: AppLanguage) {
        let id = key(courseId, language)
        tasks[id]?.cancel()
        tasks[id] = nil
        states[id] = .absent
        if let url = Self.fileURL(courseId: courseId, language: language) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func remove(courseId: String, language: AppLanguage) {
        cancel(courseId: courseId, language: language)
    }

    func removeAll() {
        for task in tasks.values { task.cancel() }
        tasks.removeAll()
        states.removeAll()
        if let root = Self.root {
            try? FileManager.default.removeItem(at: root)
        }
    }

    // MARK: - Internals

    private func indexExistingFiles() {
        guard let root = Self.root,
              let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        else { return }
        for case let url as URL in walker where url.pathExtension == "mp3" {
            let language = url.deletingLastPathComponent().lastPathComponent
            states["\(language)/\(url.deletingPathExtension().lastPathComponent)"] = .ready
        }
    }

    private static func fetch(
        _ remote: URL,
        to destination: URL,
        onProgress: @escaping (Double) -> Void
    ) async throws {
        let (stream, response) = try await URLSession.shared.bytes(from: remote)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        // Assemble in a sibling temp file: a cancelled or failed download must
        // never leave a truncated MP3 sitting where `localURL` would serve it.
        let temporary = destination.appendingPathExtension("part")
        try? FileManager.default.removeItem(at: temporary)
        FileManager.default.createFile(atPath: temporary.path, contents: nil)
        guard let handle = try? FileHandle(forWritingTo: temporary) else {
            throw URLError(.cannotCreateFile)
        }
        defer { try? handle.close() }

        let expected = Double(http.expectedContentLength)
        var buffer = Data()
        buffer.reserveCapacity(64 * 1024)
        var written = 0.0

        for try await byte in stream {
            buffer.append(byte)
            if buffer.count >= 64 * 1024 {
                try handle.write(contentsOf: buffer)
                written += Double(buffer.count)
                buffer.removeAll(keepingCapacity: true)
                if expected > 0 { onProgress(min(written / expected, 1)) }
            }
        }
        if !buffer.isEmpty {
            try handle.write(contentsOf: buffer)
        }
        try handle.close()

        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: temporary, to: destination)

        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutable = destination
        try? mutable.setResourceValues(values)

        onProgress(1)
    }
}
