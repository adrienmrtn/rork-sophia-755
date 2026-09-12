import AVFoundation
import MediaPlayer
import SwiftUI

/// Narration playback: background, lock screen, queue, speed.
///
/// Built on a plain `AVPlayer` with a queue kept in Swift rather than on
/// `AVQueuePlayer`. The queue here is not a fire-and-forget playlist — the user
/// reorders it, jumps into the middle of it, and removes items — and driving
/// that through `AVQueuePlayer`'s insert/remove API means constantly rebuilding
/// it anyway. One player and an index is less machinery for the same result.
/// Narrations are ~4 minutes, so the lost gapless pre-roll costs nothing.
@MainActor
@Observable
final class AudioPlayerService: NSObject {
    static let shared = AudioPlayerService()

    struct Track: Identifiable, Equatable {
        let courseId: String
        let title: String
        let subject: Subject
        let language: AppLanguage

        var id: String { "\(language.rawValue)/\(courseId)" }
    }

    // MARK: - Observable state

    private(set) var queue: [Track] = []
    private(set) var index: Int = 0
    private(set) var isPlaying = false
    private(set) var isLoading = false
    private(set) var currentTime: Double = 0
    private(set) var duration: Double = 0

    /// Playback speed. One MP3 serves every speed: the engine time-stretches
    /// with pitch correction, so no extra files are needed.
    private(set) var rate: Float = UserDefaults.standard.object(forKey: rateKey) as? Float ?? 1

    static let rates: [Float] = [0.8, 1, 1.25, 1.5, 1.75, 2]
    private static let rateKey = "audioPlaybackRate.v1"

    var current: Track? { queue.indices.contains(index) ? queue[index] : nil }
    var hasNext: Bool { queue.indices.contains(index + 1) }
    var hasPrevious: Bool { queue.indices.contains(index - 1) }
    var progressFraction: Double { duration > 0 ? currentTime / duration : 0 }

    // MARK: - Private

    private let player = AVPlayer()
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var statusObservation: NSKeyValueObservation?
    private weak var progressManager: ProgressManager?

    /// Courses already credited this session, so a replay does not re-fire the
    /// completion (XP itself is idempotent, but the streak and analytics are not).
    private var creditedThisSession: Set<String> = []

    private override init() {
        super.init()
        configureSession()
        configureRemoteCommands()
        observeInterruptions()
    }

    /// Injected once from `ContentView`; the service outlives any single view.
    func attach(progressManager: ProgressManager) {
        self.progressManager = progressManager
    }

    // MARK: - Session

    private func configureSession() {
        // `.playback` is what keeps audio alive on lock and honours the ringer
        // switch being silent. It pairs with UIBackgroundModes `audio` in
        // Info.plist — without that key the sound stops the moment the screen
        // goes dark.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, policy: .longFormAudio)
    }

    private func activateSession() {
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func observeInterruptions() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
            Task { @MainActor in
                switch type {
                case .began:
                    self?.isPlaying = false
                case .ended:
                    let options = (note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt).map(
                        AVAudioSession.InterruptionOptions.init(rawValue:)
                    )
                    if options?.contains(.shouldResume) == true { self?.resume() }
                default:
                    break
                }
                self?.publishNowPlaying()
            }
        }
    }

    // MARK: - Queue

    /// Starts `course` immediately, replacing whatever was playing.
    func play(course: Course, language: AppLanguage) {
        let track = Track(courseId: course.id, title: course.title, subject: course.subject, language: language)
        queue = [track]
        index = 0
        loadCurrent(autoplay: true)
    }

    /// Appends to the queue, or starts playing if nothing is loaded.
    func enqueue(course: Course, language: AppLanguage) {
        let track = Track(courseId: course.id, title: course.title, subject: course.subject, language: language)
        guard !queue.contains(track) else { return }
        queue.append(track)
        if queue.count == 1 {
            index = 0
            loadCurrent(autoplay: true)
        }
    }

    func remove(at offsets: IndexSet) {
        let wasCurrent = current
        queue.remove(atOffsets: offsets)
        guard let wasCurrent, let stillThere = queue.firstIndex(of: wasCurrent) else {
            // The playing track was removed: stop rather than silently jumping
            // to a neighbour the user did not choose.
            if queue.isEmpty { stop() } else { index = min(index, queue.count - 1); loadCurrent(autoplay: false) }
            return
        }
        index = stillThere
    }

    func move(from source: IndexSet, to destination: Int) {
        let wasCurrent = current
        queue.move(fromOffsets: source, toOffset: destination)
        if let wasCurrent, let stillThere = queue.firstIndex(of: wasCurrent) {
            index = stillThere
        }
    }

    func jump(to target: Int) {
        guard queue.indices.contains(target) else { return }
        index = target
        loadCurrent(autoplay: true)
    }

    func next() {
        guard hasNext else { return }
        index += 1
        loadCurrent(autoplay: true)
    }

    func previous() {
        // Match every podcast player: restart the track first, step back only
        // when already near its start.
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        guard hasPrevious else { return seek(to: 0) }
        index -= 1
        loadCurrent(autoplay: true)
    }

    // MARK: - Transport

    func toggle() {
        isPlaying ? pause() : resume()
    }

    func resume() {
        guard current != nil else { return }
        activateSession()
        // `play()` would reset the rate to 1. `playImmediately(atRate:)` is the
        // only way to resume at the user's chosen speed.
        player.playImmediately(atRate: rate)
        isPlaying = true
        publishNowPlaying()
    }

    func pause() {
        player.pause()
        isPlaying = false
        publishNowPlaying()
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        queue = []
        index = 0
        isPlaying = false
        currentTime = 0
        duration = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func seek(to seconds: Double) {
        let clamped = max(0, min(seconds, duration))
        player.seek(to: CMTime(seconds: clamped, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = clamped
        publishNowPlaying()
    }

    func skipForward(_ seconds: Double = 15) { seek(to: currentTime + seconds) }
    func skipBackward(_ seconds: Double = 15) { seek(to: currentTime - seconds) }

    func setRate(_ new: Float) {
        rate = new
        UserDefaults.standard.set(new, forKey: Self.rateKey)
        if isPlaying { player.rate = new }
        publishNowPlaying()
    }

    // MARK: - Loading

    private func loadCurrent(autoplay: Bool) {
        guard let track = current,
              let url = AudioDownloadManager.shared.playbackURL(courseId: track.courseId, language: track.language)
        else { return }

        teardownItemObservers()
        isLoading = true
        currentTime = 0
        duration = 0

        let item = AVPlayerItem(url: url)
        // Must be set on every item, not once on the player: it is an item
        // property, and forgetting it on the second track of a queue is how you
        // get the first course sounding fine and the next one chipmunked.
        item.audioTimePitchAlgorithm = .timeDomain
        player.replaceCurrentItem(with: item)

        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    self.isLoading = false
                    self.duration = item.duration.seconds.isFinite ? item.duration.seconds : 0
                    if autoplay { self.resume() }
                    self.publishNowPlaying()
                case .failed:
                    self.isLoading = false
                    self.isPlaying = false
                default:
                    break
                }
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.handleTrackFinished() }
        }

        if timeObserver == nil {
            timeObserver = player.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main
            ) { [weak self] time in
                Task { @MainActor in
                    guard let self, time.seconds.isFinite else { return }
                    self.currentTime = time.seconds
                }
            }
        }

        publishNowPlaying()
    }

    private func teardownItemObservers() {
        statusObservation?.invalidate()
        statusObservation = nil
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
    }

    private func handleTrackFinished() {
        if let track = current {
            credit(track)
        }
        if hasNext {
            next()
        } else {
            isPlaying = false
            seek(to: 0)
        }
    }

    /// Finishing a narration counts like finishing the course: it marks it
    /// complete and feeds the streak. `completeCourse` awards no XP on its own
    /// and `awardGlobalXP` guards against a second award, so reading the same
    /// course afterwards cannot double-count.
    private func credit(_ track: Track) {
        guard !creditedThisSession.contains(track.id) else { return }
        creditedThisSession.insert(track.id)
        guard let progressManager else { return }

        // Same sequence CourseView runs when the last lesson is finished, so a
        // course completed by ear is indistinguishable from one completed by
        // eye. `awardGlobalXP` is idempotent per course, so reading a course
        // already heard cannot award the global XP twice.
        progressManager.completeCourse(courseId: track.courseId, quizScore: 0)
        progressManager.addXP(subject: track.subject, amount: Self.courseCompletionXP)
        progressManager.awardGlobalXP(
            reason: .courseCompleted(courseId: track.courseId),
            amount: ProgressManager.globalCourseCompletionXP
        )
        if let course = ContentCatalog.course(withId: track.courseId, language: track.language) {
            AnalyticsService.trackCourseCompleted(course: course)
        }
    }

    /// Matches `CourseView.courseCompletionXP`: finishing by ear is worth what
    /// finishing by eye is worth.
    private static let courseCompletionXP = 10

    // MARK: - Lock screen

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.resume() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.toggle() }
            return .success
        }

        center.skipForwardCommand.preferredIntervals = [15]
        center.skipForwardCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.skipForward() }
            return .success
        }
        center.skipBackwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.skipBackward() }
            return .success
        }

        center.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.next() }
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.previous() }
            return .success
        }

        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor in self?.seek(to: event.positionTime) }
            return .success
        }
    }

    private func publishNowPlaying() {
        guard let track = current else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.subject.rawValue,
            MPMediaItemPropertyAlbumTitle: "Sophia",
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            // Must reflect the real speed. Reporting 1 while playing at 1.5×
            // makes the lock-screen scrubber drift further off every minute.
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? rate : 0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: rate,
            MPNowPlayingInfoPropertyIsLiveStream: false,
        ]
        if duration > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }
        if let image = CourseImageMap.loadImage(for: track.courseId) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    nonisolated func cleanup() {
        Task { @MainActor in
            if let timeObserver { player.removeTimeObserver(timeObserver) }
            timeObserver = nil
            teardownItemObservers()
        }
    }
}
