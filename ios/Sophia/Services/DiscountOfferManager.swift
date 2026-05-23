import Foundation
import Observation

/// Manages the 60-minute "offre_discount" flash promo.
///
/// Flow:
/// 1. Free user performs their first card swipe on Home → `triggerIfNeeded()` starts the 60 min clock.
/// 2. While `isActive == true`, a timer badge is shown on Home; tapping it re-opens the paywall.
/// 3. Once the 60 min elapse the offer is marked expired forever (locally, persists across app launches).
/// 4. The start date is persisted in UserDefaults so the clock keeps ticking even when the app is closed
///    or the user leaves and comes back later (e.g. 30 min later → 30 min already consumed).
/// 5. Resets on uninstall (UserDefaults is wiped).
@Observable
@MainActor
class DiscountOfferManager {
    private let startKey: String = "sophia_discount_offer_start"
    private let expiredKey: String = "sophia_discount_offer_expired"

    /// Total promo duration: 60 minutes.
    static let duration: TimeInterval = 60 * 60

    private(set) var startDate: Date?
    private(set) var isExpiredForever: Bool = false

    /// Bumped every second while the offer is active so SwiftUI views observing this
    /// `@Observable` instance re-render the countdown.
    var tick: Int = 0

    private var timer: Timer?

    init() {
        load()
        refreshExpiryIfNeeded()
        startTickerIfNeeded()
    }

    /// True when the timer is currently counting down and the user can still claim the offer.
    var isActive: Bool {
        guard !isExpiredForever, let start = startDate else { return false }
        return Date().timeIntervalSince(start) < Self.duration
    }

    /// True once the offer has been launched at least once (active or expired).
    var hasBeenTriggered: Bool {
        startDate != nil || isExpiredForever
    }

    var remainingSeconds: Int {
        guard let start = startDate, !isExpiredForever else { return 0 }
        let elapsed = Date().timeIntervalSince(start)
        return max(0, Int(Self.duration - elapsed))
    }

    /// Formatted countdown like "59:42".
    var formattedRemaining: String {
        let total = remainingSeconds
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }

    /// Starts the 60-minute offer if it hasn't been triggered yet.
    /// No-op if it was already triggered or expired.
    func triggerIfNeeded() {
        guard startDate == nil, !isExpiredForever else { return }
        startDate = Date()
        save()
        startTickerIfNeeded()
    }

    /// Permanently expires the offer. Used after a successful purchase.
    func markExpired() {
        isExpiredForever = true
        stopTicker()
        save()
    }

    private func refreshExpiryIfNeeded() {
        guard let start = startDate, !isExpiredForever else { return }
        if Date().timeIntervalSince(start) >= Self.duration {
            isExpiredForever = true
            save()
        }
    }

    private func startTickerIfNeeded() {
        guard isActive, timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.tick &+= 1
                if !self.isActive {
                    self.isExpiredForever = true
                    self.save()
                    self.stopTicker()
                }
            }
        }
    }

    private func stopTicker() {
        timer?.invalidate()
        timer = nil
    }

    private func load() {
        let defaults = UserDefaults.standard
        if let date = defaults.object(forKey: startKey) as? Date {
            startDate = date
        }
        isExpiredForever = defaults.bool(forKey: expiredKey)
    }

    private func save() {
        let defaults = UserDefaults.standard
        if let startDate {
            defaults.set(startDate, forKey: startKey)
        }
        defaults.set(isExpiredForever, forKey: expiredKey)
    }
}
