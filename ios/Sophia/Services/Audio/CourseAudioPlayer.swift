import AVFoundation
import MediaPlayer
import Observation
import SwiftUI
import UIKit

/// A narration waiting in the queue, or the one playing.
nonisolated struct AudioQueueItem: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let courseId: String
    let language: AudioLanguage

    init(courseId: String, language: AudioLanguage) {
        self.id = UUID()
        self.courseId = courseId
        self.language = language
    }

    var key: AudioTrackKey { AudioTrackKey(courseId: courseId, language: language) }
}

/// What survives a relaunch: the narration on screen and the queue behind it.
nonisolated private struct SavedAudioSession: Codable {
    var current: AudioQueueItem?
    var queue: [AudioQueueItem]
}

/// The app's one audio player: course narrations, played like a podcast.
///
/// Native on purpose — `AVPlayer` with the `.playback` session, so the narration keeps
/// going with the screen locked or in another app, and `MPNowPlayingInfoCenter` +
/// `MPRemoteCommandCenter`, so the lock screen, Control Centre, the Dynamic Island,
/// AirPods, CarPlay and the Apple Watch all show the course cover and drive playback.
///
/// Premium only. The gate lives in the `request…` entry points that the UI calls; the
/// lock-screen commands skip it, since they only act on something already playing.
///
/// Listening past `completionThreshold` completes the course like reading it does (see
/// `onListenedToEnd`, wired by `ContentView`), and every narration resumes where it was
/// left, per course and per language.
@Observable
final class CourseAudioPlayer {
    static let shared = CourseAudioPlayer()

    static let speedRange: ClosedRange<Double> = 0.5...2.0
    static let speedStep: Double = 0.05
    static let skipInterval: Double = 15
    /// Share of a narration that counts as having listened to the course.
    static let completionThreshold: Double = 0.9

    private(set) var current: AudioQueueItem?
    /// Up next, in order. `current` is never in it.
    private(set) var queue: [AudioQueueItem] = []
    /// What the listener asked for: true from the tap on play, loading included.
    private(set) var isPlaying = false
    private(set) var isBuffering = false
    private(set) var currentTime: Double = 0
    private(set) var duration: Double = 0
    private(set) var failedToLoad = false
    private(set) var rate: Double

    /// Mirrored from `StoreViewModel` by `ContentView`.
    var isPremium = false
    /// Opens the audio paywall; set by `ContentView`.
    @ObservationIgnored var onPaywallNeeded: (() -> Void)?
    /// Paywall hooks of screens presented over `ContentView` (the course reader), which
    /// cannot show a cover from the root. The last one wins.
    @ObservationIgnored private var paywallHandlers: [(id: UUID, handler: () -> Void)] = []
    /// The course a free user wanted to hear, for the paywall's cover.
    @ObservationIgnored private(set) var paywallCourseId: String?
    /// A course was listened to the end (once per playthrough); set by `ContentView`,
    /// which owns the progress.
    @ObservationIgnored var onListenedToEnd: ((String) -> Void)?
    /// Whether a course is already done, so suggestions put unread courses first; set by
    /// `ContentView`, which owns the progress.
    @ObservationIgnored var isCourseCompleted: ((String) -> Bool)?

    @ObservationIgnored private let player = AVPlayer()
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var itemStatusObservation: NSKeyValueObservation?
    @ObservationIgnored private var timeControlObservation: NSKeyValueObservation?
    @ObservationIgnored private var endObserver: NSObjectProtocol?
    @ObservationIgnored private var failObserver: NSObjectProtocol?
    @ObservationIgnored private var interruptionObserver: NSObjectProtocol?
    /// The queue item the `AVPlayer` currently holds. Nil after a relaunch: the restored
    /// narration is only loaded when the listener presses play.
    @ObservationIgnored private var loadedItemID: UUID?
    @ObservationIgnored private var pendingStartTime: Double?
    @ObservationIgnored private var playWhenReady = false
    @ObservationIgnored private var reportedCompletion = false
    /// Whether to pick up again when a call or an alarm ends: only if it was playing.
    @ObservationIgnored private var wasPlayingBeforeInterruption = false
    @ObservationIgnored private var lastPositionSave = Date.distantPast
    @ObservationIgnored private var remoteCommandsConfigured = false
    @ObservationIgnored private var artworkCourseId: String?
    @ObservationIgnored private var artwork: MPMediaItemArtwork?
    @ObservationIgnored private var positions: [String: Double]

    private static let sessionKey = "sophia_audio_session"
    private static let positionsKey = "sophia_audio_positions"
    private static let rateKey = "sophia_audio_rate"

    private init() {
        let defaults = UserDefaults.standard
        let savedRate = defaults.double(forKey: Self.rateKey)
        rate = savedRate > 0 ? Self.snap(savedRate) : 1.0
        positions = defaults.dictionary(forKey: Self.positionsKey) as? [String: Double] ?? [:]
        if let data = defaults.data(forKey: Self.sessionKey),
           let saved = try? JSONDecoder().decode(SavedAudioSession.self, from: data) {
            current = saved.current
            queue = saved.queue
            if let current { currentTime = positions[current.key.path] ?? 0 }
        }

        player.automaticallyWaitsToMinimizeStalling = true
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            MainActor.assumeIsolated { self?.tick(time.seconds) }
        }
        timeControlObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in self?.syncPlaybackState() }
        }
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let options = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
            MainActor.assumeIsolated { self?.handleInterruption(type: type, options: options) }
        }
    }

    // MARK: - State for the UI

    var hasItem: Bool { current != nil }

    var progress: Double {
        duration > 0 ? min(1, max(0, currentTime / duration)) : 0
    }

    func isCurrent(_ courseId: String) -> Bool {
        current?.courseId == courseId
    }

    func isPlayingCourse(_ courseId: String) -> Bool {
        isCurrent(courseId) && isPlaying
    }

    func isQueued(_ courseId: String) -> Bool {
        queue.contains { $0.courseId == courseId }
    }

    // MARK: - Entry points (gated)

    /// Plays a course, or opens the paywall. Returns whether it plays.
    @discardableResult
    func requestPlay(courseId: String, language: AudioLanguage? = nil, source: String) -> Bool {
        guard isPremium else {
            AnalyticsService.trackAudioLockedTapped(courseId: courseId, source: source)
            paywallCourseId = courseId
            askForPaywall()
            return false
        }
        play(courseId: courseId, language: language, source: source)
        return true
    }

    /// Adds a course to the queue — right after the current one when `next` — or opens
    /// the paywall. With nothing playing, it simply plays.
    @discardableResult
    func requestEnqueue(courseId: String, next: Bool, source: String) -> Bool {
        guard isPremium else {
            AnalyticsService.trackAudioLockedTapped(courseId: courseId, source: source)
            paywallCourseId = courseId
            askForPaywall()
            return false
        }
        enqueue(courseId: courseId, next: next, source: source)
        return true
    }

    @discardableResult
    func requestDownload(courseId: String, language: AudioLanguage? = nil, source: String) -> Bool {
        guard isPremium else {
            AnalyticsService.trackAudioLockedTapped(courseId: courseId, source: source)
            paywallCourseId = courseId
            askForPaywall()
            return false
        }
        guard let language = language ?? CourseAudioCatalog.shared.defaultLanguage(for: courseId) else { return false }
        CourseAudioDownloads.shared.download(courseId: courseId, language: language)
        return true
    }

    /// Play / pause from the app's own buttons. Resuming goes through the gate: a
    /// subscription can lapse between two listening sessions.
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else if isPremium {
            resume()
        } else {
            paywallCourseId = current?.courseId
            askForPaywall()
        }
    }

    func pushPaywallHandler(_ handler: @escaping () -> Void) -> UUID {
        let id = UUID()
        paywallHandlers.append((id: id, handler: handler))
        return id
    }

    func removePaywallHandler(_ id: UUID) {
        paywallHandlers.removeAll { $0.id == id }
    }

    private func askForPaywall() {
        if let handler = paywallHandlers.last?.handler {
            handler()
        } else {
            onPaywallNeeded?()
        }
    }

    // MARK: - Playback

    /// Plays a course from where it was left. The language defaults to the listener's
    /// (see `CourseAudioCatalog.defaultLanguage`). Already the current narration: resumes.
    func play(courseId: String, language: AudioLanguage? = nil, source: String) {
        guard let language = language ?? CourseAudioCatalog.shared.defaultLanguage(for: courseId) else { return }
        if let current, current.courseId == courseId, current.language == language {
            resume()
            return
        }
        savePosition(force: true)
        queue.removeAll { $0.courseId == courseId }
        let item = AudioQueueItem(courseId: courseId, language: language)
        current = item
        load(item, autoplay: true)
        persistSession()
        AnalyticsService.trackAudioPlayStarted(courseId: courseId, language: language.rawValue, source: source, rate: rate)
    }

    func resume() {
        guard let current else { return }
        if loadedItemID != current.id || player.currentItem == nil || failedToLoad {
            load(current, autoplay: true)
            return
        }
        activateSession()
        // Finished and not advanced (a single narration): play it again from the top.
        if duration > 0, currentTime >= duration - 0.5 {
            seek(to: 0)
        }
        player.defaultRate = Float(rate)
        player.play()
        syncPlaybackState()
    }

    func pause() {
        playWhenReady = false
        player.pause()
        savePosition(force: true)
        syncPlaybackState()
    }

    /// Stops and empties the player: the mini-player goes away.
    func stop() {
        savePosition(force: true)
        playWhenReady = false
        player.pause()
        player.replaceCurrentItem(with: nil)
        observeItem(nil)
        loadedItemID = nil
        current = nil
        queue.removeAll()
        currentTime = 0
        duration = 0
        isPlaying = false
        isBuffering = false
        failedToLoad = false
        persistSession()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func seek(to seconds: Double) {
        let upper = duration > 0 ? duration : max(seconds, 0)
        let target = min(max(0, seconds), upper)
        currentTime = target
        if loadedItemID != nil, player.currentItem?.status == .readyToPlay, pendingStartTime == nil {
            player.seek(
                to: CMTime(seconds: target, preferredTimescale: 600),
                toleranceBefore: .zero,
                toleranceAfter: .zero
            )
        } else {
            // Not ready yet, or not loaded at all (restored after a relaunch): the start
            // position is applied once the item is ready.
            pendingStartTime = target
        }
        if duration > 0, target < duration * Self.completionThreshold {
            reportedCompletion = false
        }
        savePosition(force: true)
        updateNowPlaying()
    }

    func skip(by delta: Double) {
        seek(to: currentTime + delta)
    }

    func setRate(_ value: Double) {
        let snapped = Self.snap(value)
        guard snapped != rate else { return }
        rate = snapped
        UserDefaults.standard.set(snapped, forKey: Self.rateKey)
        player.defaultRate = Float(snapped)
        if player.rate != 0 {
            player.rate = Float(snapped)
        }
        updateNowPlaying()
    }

    /// Same course, another language. Each language keeps its own resume position.
    func switchLanguage(to language: AudioLanguage) {
        CourseAudioCatalog.shared.preferredLanguage = language
        guard let current, current.language != language else { return }
        let wasPlaying = isPlaying
        savePosition(force: true)
        let item = AudioQueueItem(courseId: current.courseId, language: language)
        self.current = item
        load(item, autoplay: wasPlaying)
        persistSession()
        AnalyticsService.trackAudioLanguageChanged(courseId: current.courseId, language: language.rawValue)
    }

    static func snap(_ value: Double) -> Double {
        let clamped = min(max(value, speedRange.lowerBound), speedRange.upperBound)
        return (clamped / speedStep).rounded() * speedStep
    }

    // MARK: - Queue

    func enqueue(courseId: String, next: Bool, source: String) {
        guard current != nil else {
            play(courseId: courseId, source: source)
            return
        }
        guard current?.courseId != courseId,
              let language = CourseAudioCatalog.shared.defaultLanguage(for: courseId) else { return }
        queue.removeAll { $0.courseId == courseId }
        let item = AudioQueueItem(courseId: courseId, language: language)
        if next {
            queue.insert(item, at: 0)
        } else {
            queue.append(item)
        }
        persistSession()
        updateNowPlaying()
        AnalyticsService.trackAudioQueued(courseId: courseId, position: next ? "next" : "end", source: source)
    }

    func removeFromQueue(atOffsets offsets: IndexSet) {
        for index in offsets.sorted(by: >) where queue.indices.contains(index) {
            queue.remove(at: index)
        }
        persistSession()
        updateNowPlaying()
    }

    func removeFromQueue(courseId: String) {
        queue.removeAll { $0.courseId == courseId }
        persistSession()
        updateNowPlaying()
    }

    func moveQueue(fromOffsets source: IndexSet, toOffset destination: Int) {
        queue.move(fromOffsets: source, toOffset: destination)
        persistSession()
    }

    func clearQueue() {
        queue.removeAll()
        persistSession()
        updateNowPlaying()
    }

    /// Plays a queued narration now; the ones before it stay queued.
    func playFromQueue(_ item: AudioQueueItem) {
        guard let index = queue.firstIndex(of: item) else { return }
        queue.remove(at: index)
        savePosition(force: true)
        current = item
        load(item, autoplay: true)
        persistSession()
    }

    /// Next narration in the queue; with an empty queue, the player closes.
    func skipToNext() {
        savePosition(force: true)
        guard !queue.isEmpty else {
            stop()
            return
        }
        let next = queue.removeFirst()
        current = next
        load(next, autoplay: true)
        persistSession()
    }

    // MARK: - Loading

    private func load(_ item: AudioQueueItem, autoplay: Bool) {
        guard let url = CourseAudioDownloads.shared.localURL(courseId: item.courseId, language: item.language)
            ?? CourseAudioCatalog.remoteURL(courseId: item.courseId, language: item.language) else {
            failedToLoad = true
            return
        }
        failedToLoad = false
        reportedCompletion = false
        duration = 0
        let resumeAt = positions[item.key.path] ?? 0
        currentTime = resumeAt
        pendingStartTime = resumeAt > 1 ? resumeAt : nil
        playWhenReady = autoplay

        let playerItem = AVPlayerItem(asset: AVURLAsset(url: url))
        // Speech: keeps the pitch natural at 1.5× and 2×.
        playerItem.audioTimePitchAlgorithm = .timeDomain
        observeItem(playerItem)
        player.replaceCurrentItem(with: playerItem)
        player.defaultRate = Float(rate)
        loadedItemID = item.id

        if autoplay {
            activateSession()
        }
        configureRemoteCommandsIfNeeded()
        syncPlaybackState()
        updateNowPlaying()
    }

    private func observeItem(_ item: AVPlayerItem?) {
        itemStatusObservation?.invalidate()
        itemStatusObservation = nil
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        if let failObserver { NotificationCenter.default.removeObserver(failObserver) }
        endObserver = nil
        failObserver = nil
        guard let item else { return }

        itemStatusObservation = item.observe(\.status, options: [.new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in self?.itemStatusChanged() }
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.itemDidEnd() }
        }
        failObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.failedToPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.itemFailed() }
        }
    }

    private func itemStatusChanged() {
        guard let item = player.currentItem else { return }
        switch item.status {
        case .readyToPlay:
            let seconds = item.duration.seconds
            if seconds.isFinite, seconds > 0 { duration = seconds }
            // Resumed past the threshold: this playthrough was already counted.
            if let start = pendingStartTime, duration > 0, start / duration >= Self.completionThreshold {
                reportedCompletion = true
            }
            if let start = pendingStartTime, duration == 0 || start < duration - 3 {
                pendingStartTime = nil
                player.seek(
                    to: CMTime(seconds: start, preferredTimescale: 600),
                    toleranceBefore: .zero,
                    toleranceAfter: .zero
                ) { [weak self] _ in
                    Task { @MainActor [weak self] in self?.startIfWanted() }
                }
            } else {
                // Left within the last seconds: start over rather than end at once.
                if pendingStartTime != nil { currentTime = 0 }
                pendingStartTime = nil
                startIfWanted()
            }
            updateNowPlaying()
        case .failed:
            itemFailed()
        default:
            break
        }
    }

    private func startIfWanted() {
        guard playWhenReady else {
            syncPlaybackState()
            return
        }
        playWhenReady = false
        player.defaultRate = Float(rate)
        player.play()
        syncPlaybackState()
    }

    private func itemFailed() {
        playWhenReady = false
        failedToLoad = true
        player.pause()
        syncPlaybackState()
    }

    private func itemDidEnd() {
        guard let current else { return }
        if !reportedCompletion { reportCompletion() }
        positions[current.key.path] = nil
        UserDefaults.standard.set(positions, forKey: Self.positionsKey)
        if queue.isEmpty {
            stop()
        } else {
            let next = queue.removeFirst()
            self.current = next
            load(next, autoplay: true)
            persistSession()
        }
    }

    // MARK: - Ticks

    private func tick(_ seconds: Double) {
        guard current != nil, loadedItemID != nil, seconds.isFinite else { return }
        // Before the resume seek lands, the item reports 0: keep showing the saved position.
        guard pendingStartTime == nil else { return }
        currentTime = seconds
        if duration <= 0, let itemDuration = player.currentItem?.duration.seconds,
           itemDuration.isFinite, itemDuration > 0 {
            duration = itemDuration
            updateNowPlaying()
        }
        if duration > 0, !reportedCompletion, seconds / duration >= Self.completionThreshold {
            reportCompletion()
        }
        savePosition()
    }

    private func reportCompletion() {
        guard let current else { return }
        reportedCompletion = true
        onListenedToEnd?(current.courseId)
        AnalyticsService.trackAudioCompleted(courseId: current.courseId, language: current.language.rawValue, rate: rate)
    }

    private func syncPlaybackState() {
        let status = player.timeControlStatus
        let loading = playWhenReady && player.currentItem?.status != .readyToPlay
        isPlaying = status != .paused || playWhenReady
        isBuffering = status == .waitingToPlayAtSpecifiedRate || loading
        updateNowPlaying()
    }

    private func handleInterruption(type: UInt?, options: UInt?) {
        guard let type, let interruption = AVAudioSession.InterruptionType(rawValue: type) else { return }
        switch interruption {
        case .began:
            // The system already paused the player (a call, an alarm).
            wasPlayingBeforeInterruption = isPlaying
            savePosition(force: true)
            syncPlaybackState()
        case .ended:
            let shouldResume = options.map { AVAudioSession.InterruptionOptions(rawValue: $0).contains(.shouldResume) } ?? false
            if shouldResume, wasPlayingBeforeInterruption, current != nil { resume() }
            wasPlayingBeforeInterruption = false
        @unknown default:
            break
        }
    }

    // MARK: - Persistence

    private func savePosition(force: Bool = false) {
        guard let current else { return }
        guard force || Date().timeIntervalSince(lastPositionSave) > 5 else { return }
        lastPositionSave = Date()
        // A narration heard to the end starts from the top next time.
        if duration > 0, currentTime >= duration - 3 {
            positions[current.key.path] = nil
        } else {
            positions[current.key.path] = currentTime
        }
        UserDefaults.standard.set(positions, forKey: Self.positionsKey)
    }

    private func persistSession() {
        let saved = SavedAudioSession(current: current, queue: queue)
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: Self.sessionKey)
        }
    }

    // MARK: - System integration

    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        // `.spokenAudio` lets other apps' navigation prompts duck us, and `.longFormAudio`
        // routes like a podcast (AirPlay, the car) rather than like a sound effect.
        try? session.setCategory(.playback, mode: .spokenAudio, policy: .longFormAudio)
        try? session.setActive(true)
    }

    private func configureRemoteCommandsIfNeeded() {
        guard !remoteCommandsConfigured else { return }
        remoteCommandsConfigured = true
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            guard let self, self.current != nil else { return .noActionableNowPlayingItem }
            self.resume()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self, self.current != nil else { return .noActionableNowPlayingItem }
            if self.isPlaying { self.pause() } else { self.resume() }
            return .success
        }

        center.skipForwardCommand.preferredIntervals = [NSNumber(value: Self.skipInterval)]
        center.skipForwardCommand.addTarget { [weak self] _ in
            self?.skip(by: Self.skipInterval)
            return .success
        }
        center.skipBackwardCommand.preferredIntervals = [NSNumber(value: Self.skipInterval)]
        center.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skip(by: -Self.skipInterval)
            return .success
        }

        center.nextTrackCommand.addTarget { [weak self] _ in
            guard let self, !self.queue.isEmpty else { return .noSuchContent }
            self.skipToNext()
            return .success
        }
        center.previousTrackCommand.isEnabled = false

        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: event.positionTime)
            return .success
        }

        center.changePlaybackRateCommand.supportedPlaybackRates = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map { NSNumber(value: $0) }
        center.changePlaybackRateCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackRateCommandEvent else { return .commandFailed }
            self?.setRate(Double(event.playbackRate))
            return .success
        }
    }

    /// Lock screen, Control Centre, Dynamic Island: title, professor, cover, position.
    private func updateNowPlaying() {
        guard let current else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        let course = ContentCatalog.course(withId: current.courseId)
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: course?.title ?? "Sophia",
            MPMediaItemPropertyArtist: AuthorStore.author(forCourseId: current.courseId)?.name ?? "Sophia",
            MPMediaItemPropertyAlbumTitle: course.map { "Sophia · \($0.subject.shortName)" } ?? "Sophia",
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: Double(player.rate),
            MPNowPlayingInfoPropertyDefaultPlaybackRate: rate,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
            MPNowPlayingInfoPropertyPlaybackQueueCount: queue.count + 1,
            MPNowPlayingInfoPropertyPlaybackQueueIndex: 0,
        ]
        if duration > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }
        if let artwork = artwork(for: current.courseId) {
            info[MPMediaItemPropertyArtwork] = artwork
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = !queue.isEmpty
    }

    private func artwork(for courseId: String) -> MPMediaItemArtwork? {
        if artworkCourseId == courseId { return artwork }
        artworkCourseId = courseId
        artwork = CourseImageMap.loadImage(for: courseId).map(Self.makeArtwork)
        return artwork
    }

    /// Built outside the main actor: MediaPlayer asks for the image on a queue of its own.
    nonisolated private static func makeArtwork(_ image: UIImage) -> MPMediaItemArtwork {
        MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }
}
