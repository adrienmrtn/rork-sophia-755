import DeviceActivity
import ManagedSettings

/// Ends an unlock window.
///
/// `TikTokBlockerManager` starts monitoring a one-shot interval that runs for the unlock
/// duration. iOS wakes this extension when it ends, whether or not Sophia is running, and
/// the shield goes back up.
final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard activity.rawValue == TikTokBlockerShared.unlockActivityName else { return }
        TikTokBlockerShared.unlockedUntil = nil
        TikTokBlockerShared.reconcileShield()
    }
}
