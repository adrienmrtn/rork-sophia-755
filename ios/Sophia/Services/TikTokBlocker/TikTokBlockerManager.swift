import Foundation
import Observation
import FamilyControls
import ManagedSettings
import DeviceActivity
import UserNotifications
import UIKit

/// "Cultive-toi avant de scroller": TikTok stays shielded until a course and its quiz
/// are done, then opens for a while.
///
/// How the pieces fit:
///
///  1. The user ticks TikTok in Apple's `FamilyActivityPicker`. We only get an opaque
///     token, never the name, which is why the copy tells them what to tick.
///  2. `TikTokBlockerShared.applyShield()` puts a system shield on it, drawn by the
///     `SophiaShieldConfiguration` extension.
///  3. Tapping the shield's button runs the `SophiaShieldAction` extension, which stamps a
///     pending request in the App Group and posts a notification that brings the user here.
///  4. The app, on becoming active, sees the stamp and opens a course straight away
///     (`ContentView.openBlockerCourseIfNeeded`), with [session] set so the reader shows
///     a "lock active" banner.
///  5. Finishing the daily course (any course read to its last page, the same completion
///     that feeds the streak) calls [registerDailyCourseCompleted]. TikTok is unlocked at
///     once until local midnight, and a one-shot `DeviceActivity` interval is armed whose
///     end re-applies the shield from the `SophiaDeviceActivityMonitor` extension, whether
///     or not Sophia is still running.
///  6. Back on home, `ContentView` shows `TikTokUnlockedView` with the "Back to TikTok"
///     button (`tiktok://`).
///
/// A course finished *without* coming from the shield unlocks TikTok too: the deal is
/// "your daily course buys your TikTok", not "only when we sent you". Only the
/// celebration screen is reserved for the shield-originated visit.
@Observable
@MainActor
final class TikTokBlockerManager {
    static let shared = TikTokBlockerManager()

    enum AuthorizationState: Equatable {
        case notDetermined
        case denied
        case approved
    }

    /// A shield-originated visit: which course was handed out, and whether the day's
    /// course has been done since.
    struct Session: Equatable {
        var courseId: String
        var completed = false
    }

    private(set) var authorization: AuthorizationState
    private(set) var isEnabled: Bool = TikTokBlockerShared.isEnabled
    var selection: FamilyActivitySelection = TikTokBlockerShared.selection {
        didSet {
            TikTokBlockerShared.selection = selection
            reconcileShield()
        }
    }
    private(set) var unlockedUntil: Date? = TikTokBlockerShared.unlockedUntil
    private(set) var unlockCount: Int = TikTokBlockerShared.unlockCount

    /// Non-nil from the moment the shield sent the user here until the celebration
    /// screen is dismissed (or the blocker is switched off).
    private(set) var session: Session?

    /// Set when the daily course has just earned an unlock and the user came from the
    /// shield; the home screen shows `TikTokUnlockedView` and clears it.
    var showUnlockedScreen = false

    private let center = AuthorizationCenter.shared

    private init() {
        // `self` is off limits until every stored property is set, so the singleton is
        // read directly rather than through `center`.
        authorization = Self.map(AuthorizationCenter.shared.authorizationStatus)
    }

    // MARK: - Derived state

    var hasSelection: Bool {
        !(selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty && selection.webDomainTokens.isEmpty)
    }

    var isUnlockWindowOpen: Bool {
        guard let unlockedUntil else { return false }
        return unlockedUntil > Date()
    }

    /// Everything is in place for the shield to be up (or to come back up when the
    /// current unlock window ends).
    var isArmed: Bool {
        isEnabled && authorization == .approved && hasSelection
    }

    /// The shield is on TikTok right now.
    var isShieldActive: Bool {
        isArmed && !isUnlockWindowOpen
    }

    /// TikTok is installed, so the "Back to TikTok" button can do something.
    var canOpenTikTok: Bool {
        UIApplication.shared.canOpenURL(TikTokBlockerShared.tiktokURL)
    }

    // MARK: - Authorization

    /// Screen Time permission (system sheet). `.individual`: the user restricts their own
    /// phone, no Family Sharing involved.
    func requestAuthorization() async -> Bool {
        do {
            try await center.requestAuthorization(for: .individual)
        } catch {
            refreshAuthorization()
            return false
        }
        refreshAuthorization()
        return authorization == .approved
    }

    func refreshAuthorization() {
        authorization = Self.map(center.authorizationStatus)
    }

    private static func map(_ status: FamilyControls.AuthorizationStatus) -> AuthorizationState {
        switch status {
        case .approved: .approved
        case .denied: .denied
        case .notDetermined: .notDetermined
        @unknown default: .notDetermined
        }
    }

    // MARK: - Enable / disable

    func setEnabled(_ enabled: Bool) {
        guard enabled != isEnabled else { return }
        isEnabled = enabled
        TikTokBlockerShared.isEnabled = enabled
        if enabled {
            reconcileShield()
        } else {
            stopUnlockTimer()
            TikTokBlockerShared.unlockedUntil = nil
            unlockedUntil = nil
            TikTokBlockerShared.pendingRequestAt = nil
            session = nil
            showUnlockedScreen = false
            TikTokBlockerShared.clearShield()
        }
    }

    /// Mirrors the app language for the shield extension's copy.
    func syncLanguage(_ language: AppLanguage) {
        TikTokBlockerShared.language = language.rawValue
    }

    /// Brings the shield in line with the stored state. Called whenever the app comes to
    /// the foreground: the monitor extension normally re-shields at the end of a window,
    /// this is the belt to its braces.
    func reconcileShield() {
        refreshAuthorization()
        unlockedUntil = TikTokBlockerShared.unlockedUntil
        unlockCount = TikTokBlockerShared.unlockCount
        guard authorization == .approved else { return }
        TikTokBlockerShared.reconcileShield()
        unlockedUntil = TikTokBlockerShared.unlockedUntil
    }

    // MARK: - Shield-originated visit

    /// True once, when the shield asked us to open and the tap is recent. Consumes the
    /// stamp and the notification that carried it.
    func consumePendingRequest() -> Bool {
        guard let at = TikTokBlockerShared.pendingRequestAt else { return false }
        TikTokBlockerShared.pendingRequestAt = nil
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [TikTokBlockerShared.unlockNotificationId])
        guard isArmed else { return false }
        return Date().timeIntervalSince(at) < TikTokBlockerShared.pendingRequestLifetime
    }

    /// Picks the course to hand out and opens the session. A visit that already has an
    /// unfinished course keeps it: the reco reshuffles between calls, and someone who
    /// backed out halfway should find the same course, not a new one.
    func startSession(candidate: () -> Course?) -> Course? {
        if let current = session, !current.completed,
           let course = ContentCatalog.course(withId: current.courseId) {
            return course
        }
        guard let course = candidate() else { return nil }
        session = Session(courseId: course.id)
        showUnlockedScreen = false
        return course
    }

    /// The reader shows its "finish your daily course" banner while TikTok is locked.
    var showsLockBanner: Bool {
        isShieldActive
    }

    /// Called whenever a course is read to its last page (the completion that feeds the
    /// streak). Unlocks TikTok until midnight when the blocker is armed and no window is
    /// already open; the celebration screen is queued only for a shield-originated visit.
    func registerDailyCourseCompleted(courseId: String) {
        guard isArmed else { return }
        let fromShield = session != nil
        if fromShield {
            session?.completed = true
        }
        guard !isUnlockWindowOpen else {
            if fromShield, !showUnlockedScreen { showUnlockedScreen = true }
            return
        }
        grantUnlock(courseId: courseId, fromShield: fromShield)
        if fromShield { showUnlockedScreen = true }
    }

    /// The celebration screen has been seen (or skipped).
    func endSession() {
        session = nil
        showUnlockedScreen = false
    }

    /// Ends the unlock window early, from settings.
    func lockNow() {
        stopUnlockTimer()
        TikTokBlockerShared.unlockedUntil = nil
        unlockedUntil = nil
        reconcileShield()
    }

    /// Opens TikTok. Returns false when it is not installed (button hidden upstream).
    func openTikTok() -> Bool {
        guard canOpenTikTok else { return false }
        UIApplication.shared.open(TikTokBlockerShared.tiktokURL)
        return true
    }

    // MARK: - Unlock window

    private func grantUnlock(courseId: String, fromShield: Bool) {
        let until = TikTokBlockerShared.unlockWindowEnd()
        let minutes = Int(until.timeIntervalSinceNow / 60)
        TikTokBlockerShared.unlockedUntil = until
        TikTokBlockerShared.unlockCount += 1
        unlockedUntil = until
        unlockCount = TikTokBlockerShared.unlockCount
        TikTokBlockerShared.clearShield()
        armUnlockTimer(until: until)
    }

    private var unlockActivity: DeviceActivityName {
        DeviceActivityName(TikTokBlockerShared.unlockActivityName)
    }

    /// One-shot interval from now to [until]. iOS wakes the monitor extension when it
    /// ends, and the extension re-applies the shield.
    private func armUnlockTimer(until: Date) {
        let deviceCenter = DeviceActivityCenter()
        deviceCenter.stopMonitoring([unlockActivity])
        let calendar = Calendar.current
        let fields: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        // DeviceActivity wants at least 15 minutes between start and end;
        // `unlockWindowEnd` guarantees it.
        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents(fields, from: Date()),
            intervalEnd: calendar.dateComponents(fields, from: until),
            repeats: false
        )
        do {
            try deviceCenter.startMonitoring(unlockActivity, during: schedule)
        } catch {
            // No monitor: the app itself re-shields on its next foreground (reconcileShield).
            #if DEBUG
            print("[TikTokBlocker] startMonitoring failed: \(error)")
            #endif
        }
    }

    private func stopUnlockTimer() {
        DeviceActivityCenter().stopMonitoring([unlockActivity])
    }
}
