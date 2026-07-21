import Foundation
import Observation

/// Manages the 60-minute "offre_discount" flash promo.
///
/// Flow:
/// 1. Free user swipes cards on Home. After `swipesBeforeGift` swipes a surprise gift
///    appears over the app (`isGiftPending`). The user taps it open to reveal the offer.
/// 2. Opening the gift calls `triggerIfNeeded()` which starts the 60 min clock and shows the paywall.
/// 3. While `isActive == true`, a timer badge is shown on Home; tapping it re-opens the paywall.
/// 4. Once the 60 min elapse the offer is marked expired forever (locally, persists across app launches).
/// 5. The start date is persisted in UserDefaults so the clock keeps ticking even when the app is closed
///    or the user leaves and comes back later (e.g. 30 min later → 30 min already consumed).
/// 6. Resets on uninstall (UserDefaults is wiped).
@Observable
@MainActor
class DiscountOfferManager {
    private let startKey: String = "sophia_discount_offer_start"
    private let expiredKey: String = "sophia_discount_offer_expired"
    private let swipeCountKey: String = "sophia_discount_swipe_count"
    private let giftPendingKey: String = "sophia_discount_gift_pending"
    /// Jour (yyyy-MM-dd) où l'offre a été montrée pour la dernière fois — l'offre n'apparaît
    /// qu'une seule fois par jour.
    private let lastShownDayKey: String = "sophia_discount_last_shown_day"
    /// Jour auquel se rapporte `swipeCount` — remis à zéro à chaque nouveau jour.
    private let swipeDayKey: String = "sophia_discount_swipe_day"

    /// Total promo duration: 60 minutes.
    static let duration: TimeInterval = 60 * 60

    /// Number of card swipes a free user must perform before the surprise gift appears.
    static let swipesBeforeGift: Int = 3

    private(set) var startDate: Date?
    private(set) var isExpiredForever: Bool = false

    /// Free-user card swipe count (persisted). Drives the surprise-gift reveal.
    private(set) var swipeCount: Int = 0

    /// True once the surprise gift is on screen waiting to be opened. Persisted so it
    /// survives the user leaving and coming back before tapping it open.
    private(set) var isGiftPending: Bool = false

    /// Day (yyyy-MM-dd) the offer was last shown, and the day `swipeCount` belongs to.
    private var lastShownDay: String?
    private var swipeDay: String?

    /// Today as a stable `yyyy-MM-dd` string (device calendar).
    private static func dayString(_ date: Date = Date()) -> String {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }

    /// True if the discount offer has already been shown today (once-per-day cap).
    var wasShownToday: Bool {
        lastShownDay == Self.dayString()
    }

    /// Records that the discount paywall was shown today (called at each presentation).
    func markShownToday() {
        lastShownDay = Self.dayString()
        save()
    }

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

    /// Registers a free-user card swipe. Once `swipesBeforeGift` swipes are reached,
    /// the surprise gift becomes pending (shown over the app) — but the discount clock
    /// only starts when the user actually opens the gift (`triggerIfNeeded`).
    func registerSwipe() {
        // Once-per-day: if the offer already appeared today, don't build toward it again.
        if wasShownToday { return }
        resetForNewDayIfNeeded()
        guard !isExpiredForever, startDate == nil, !isGiftPending else { return }
        swipeCount += 1
        if swipeCount >= Self.swipesBeforeGift {
            isGiftPending = true
        }
        save()
    }

    /// Fresh day → reset the swipe counter and any prior offer state so the discount can be
    /// re-earned (via the 3rd swipe) exactly once on the new day.
    private func resetForNewDayIfNeeded() {
        let today = Self.dayString()
        guard swipeDay != today else { return }
        swipeDay = today
        swipeCount = 0
        isGiftPending = false
        startDate = nil
        isExpiredForever = false
        stopTicker()
        save()
    }

    /// Consumes the pending gift (called when the user finishes opening it).
    func consumeGift() {
        guard isGiftPending else { return }
        isGiftPending = false
        save()
    }

    /// Starts the 60-minute offer if it hasn't been triggered yet.
    /// No-op if it was already triggered or expired.
    func triggerIfNeeded() {
        guard startDate == nil, !isExpiredForever else { return }
        startDate = Date()
        save()
        startTickerIfNeeded()
    }

    /// Re-arms the 60-minute clock from now and clears any expiry, so the flash offer looks
    /// fresh each time it re-pops on app open. The timer is purely psychological here — it no
    /// longer gates whether the discount paywall can be shown again.
    func restart() {
        startDate = Date()
        isExpiredForever = false
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
        swipeCount = defaults.integer(forKey: swipeCountKey)
        isGiftPending = defaults.bool(forKey: giftPendingKey)
        lastShownDay = defaults.string(forKey: lastShownDayKey)
        swipeDay = defaults.string(forKey: swipeDayKey)
    }

    private func save() {
        let defaults = UserDefaults.standard
        if let startDate {
            defaults.set(startDate, forKey: startKey)
        }
        defaults.set(isExpiredForever, forKey: expiredKey)
        defaults.set(swipeCount, forKey: swipeCountKey)
        defaults.set(isGiftPending, forKey: giftPendingKey)
        defaults.set(lastShownDay, forKey: lastShownDayKey)
        defaults.set(swipeDay, forKey: swipeDayKey)
    }
}
