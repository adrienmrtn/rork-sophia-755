import Foundation
import Observation

/// One narration: a course in one language. Also the object path in the bucket
/// (`fr/course_5_…`) and the file path on the phone, minus the extension.
nonisolated struct AudioTrackKey: Hashable, Codable, Sendable {
    let courseId: String
    let language: AudioLanguage

    var path: String { "\(language.rawValue)/\(courseId)" }

    init(courseId: String, language: AudioLanguage) {
        self.courseId = courseId
        self.language = language
    }

    init?(path: String) {
        let parts = path.split(separator: "/", maxSplits: 1).map(String.init)
        guard parts.count == 2, let language = AudioLanguage(rawValue: parts[0]), !parts[1].isEmpty else {
            return nil
        }
        self.init(courseId: parts[1], language: language)
    }
}

/// Where downloaded narrations live: `Application Support/CourseAudio/<lang>/<course_id>.mp3`.
///
/// Not Caches: the system empties Caches when space runs low, and a download the listener
/// asked for must still be there in the plane. Excluded from iCloud backup instead, like
/// podcasts: it can always be fetched again.
nonisolated enum CourseAudioStorage {
    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("CourseAudio", isDirectory: true)
    }

    static func fileURL(for key: AudioTrackKey) -> URL {
        directory
            .appendingPathComponent(key.language.rawValue, isDirectory: true)
            .appendingPathComponent(key.courseId + ".mp3")
    }

    static func prepareDirectory(for key: AudioTrackKey) throws {
        let folder = fileURL(for: key).deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var root = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? root.setResourceValues(values)
    }

    static func fileSize(_ url: URL) -> Int64 {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return (attributes?[.size] as? NSNumber)?.int64Value ?? 0
    }
}

/// Offline narrations: download, progress, delete.
///
/// A plain foreground `URLSession`: a narration is a few megabytes and finishes while the
/// listener is still looking at the player. What is on disk is the truth; nothing is
/// persisted besides the files themselves.
@Observable
final class CourseAudioDownloads {
    static let shared = CourseAudioDownloads()

    struct Item: Identifiable, Hashable {
        let key: AudioTrackKey
        let bytes: Int64
        var id: String { key.path }
    }

    enum State: Equatable {
        case none
        case downloading(Double)
        case downloaded
    }

    private(set) var downloaded: Set<AudioTrackKey> = []
    /// Fraction received, per download in flight (0 until the size is known).
    private(set) var inFlight: [AudioTrackKey: Double] = [:]
    /// Last attempt failed; cleared by the next attempt.
    private(set) var failed: Set<AudioTrackKey> = []

    @ObservationIgnored private var tasks: [AudioTrackKey: URLSessionDownloadTask] = [:]
    @ObservationIgnored private let delegate: CourseAudioDownloadDelegate
    @ObservationIgnored private let session: URLSession

    private init() {
        let delegate = CourseAudioDownloadDelegate()
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.urlCache = nil
        self.delegate = delegate
        session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        downloaded = Self.scanDisk()
        delegate.onProgress = { key, fraction in
            Task { @MainActor in CourseAudioDownloads.shared.updateProgress(key, fraction) }
        }
        delegate.onFinished = { key, outcome in
            Task { @MainActor in CourseAudioDownloads.shared.finish(key, outcome) }
        }
    }

    // MARK: - Queries

    func state(courseId: String, language: AudioLanguage) -> State {
        let key = AudioTrackKey(courseId: courseId, language: language)
        if downloaded.contains(key) { return .downloaded }
        if let fraction = inFlight[key] { return .downloading(fraction) }
        return .none
    }

    func isDownloaded(courseId: String, language: AudioLanguage) -> Bool {
        downloaded.contains(AudioTrackKey(courseId: courseId, language: language))
    }

    /// The file to play from, when the narration is on the phone.
    func localURL(courseId: String, language: AudioLanguage) -> URL? {
        let key = AudioTrackKey(courseId: courseId, language: language)
        guard downloaded.contains(key) else { return nil }
        let url = CourseAudioStorage.fileURL(for: key)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Every download with its size, largest first, for the settings screen.
    var items: [Item] {
        downloaded
            .map { Item(key: $0, bytes: CourseAudioStorage.fileSize(CourseAudioStorage.fileURL(for: $0))) }
            .sorted { $0.bytes > $1.bytes }
    }

    var totalBytes: Int64 {
        items.reduce(0) { $0 + $1.bytes }
    }

    // MARK: - Actions

    func download(courseId: String, language: AudioLanguage) {
        let key = AudioTrackKey(courseId: courseId, language: language)
        guard !downloaded.contains(key), tasks[key] == nil,
              let url = CourseAudioCatalog.remoteURL(courseId: courseId, language: language) else { return }
        failed.remove(key)
        inFlight[key] = 0
        let task = session.downloadTask(with: url)
        task.taskDescription = key.path
        tasks[key] = task
        task.resume()
        AnalyticsService.trackAudioDownloadStarted(courseId: courseId, language: language.rawValue)
    }

    func cancel(courseId: String, language: AudioLanguage) {
        let key = AudioTrackKey(courseId: courseId, language: language)
        tasks[key]?.cancel()
        tasks[key] = nil
        inFlight[key] = nil
    }

    func delete(courseId: String, language: AudioLanguage) {
        let key = AudioTrackKey(courseId: courseId, language: language)
        cancel(courseId: courseId, language: language)
        try? FileManager.default.removeItem(at: CourseAudioStorage.fileURL(for: key))
        downloaded.remove(key)
    }

    func deleteAll() {
        for task in tasks.values { task.cancel() }
        tasks.removeAll()
        inFlight.removeAll()
        try? FileManager.default.removeItem(at: CourseAudioStorage.directory)
        downloaded.removeAll()
    }

    // MARK: - Delegate relay

    private func updateProgress(_ key: AudioTrackKey, _ fraction: Double) {
        // A late progress event must not resurrect a download that was just cancelled.
        guard tasks[key] != nil else { return }
        inFlight[key] = fraction
    }

    private func finish(_ key: AudioTrackKey, _ outcome: CourseAudioDownloadDelegate.Outcome) {
        // `cancel` already cleaned up; a late callback must not clear a download restarted since.
        if case .cancelled = outcome { return }
        tasks[key] = nil
        inFlight[key] = nil
        switch outcome {
        case .saved:
            downloaded.insert(key)
        case .failed:
            failed.insert(key)
        case .cancelled:
            break
        }
    }

    private static func scanDisk() -> Set<AudioTrackKey> {
        var found: Set<AudioTrackKey> = []
        let fm = FileManager.default
        for language in AudioLanguage.allCases {
            let folder = CourseAudioStorage.directory.appendingPathComponent(language.rawValue, isDirectory: true)
            guard let names = try? fm.contentsOfDirectory(atPath: folder.path) else { continue }
            for name in names where name.hasSuffix(".mp3") {
                found.insert(AudioTrackKey(courseId: String(name.dropLast(4)), language: language))
            }
        }
        return found
    }
}

/// URLSession callbacks, off the main actor. The finished file is moved before the callback
/// returns, as URLSession deletes it right after.
nonisolated final class CourseAudioDownloadDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    enum Outcome: Sendable {
        case saved
        case failed
        case cancelled
    }

    var onProgress: (@Sendable (AudioTrackKey, Double) -> Void)?
    var onFinished: (@Sendable (AudioTrackKey, Outcome) -> Void)?

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0,
              let key = AudioTrackKey(path: downloadTask.taskDescription ?? "") else { return }
        onProgress?(key, min(1, Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)))
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let key = AudioTrackKey(path: downloadTask.taskDescription ?? "") else { return }
        // A 404 still "downloads" its error page: only a 200 is a narration.
        guard (downloadTask.response as? HTTPURLResponse)?.statusCode == 200 else {
            onFinished?(key, .failed)
            return
        }
        let destination = CourseAudioStorage.fileURL(for: key)
        do {
            try CourseAudioStorage.prepareDirectory(for: key)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: location, to: destination)
            onFinished?(key, .saved)
        } catch {
            onFinished?(key, .failed)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // Success already reported from `didFinishDownloadingTo`.
        guard let error, let key = AudioTrackKey(path: task.taskDescription ?? "") else { return }
        let cancelled = (error as? URLError)?.code == .cancelled
        onFinished?(key, cancelled ? .cancelled : .failed)
    }
}
