import Foundation

/// Counts the cards a reader swipes past without opening — the `fatigue` term of
/// `HomeDeckBuilder.score`.
///
/// This is the app's only record of a course having been *shown*. Everything else it
/// knows starts at the moment a course is opened, which makes a course dealt forty
/// times and opened once indistinguishable from one nobody ever saw. Keeping the
/// count locally is the cheap half of fixing that; the useful half is a real
/// impression log, which belongs server-side and is not this.
///
/// Local on purpose, and never synced: it is a per-device browsing habit, not
/// progress, and losing it on reinstall costs nothing.
enum DeckSkipStore {
    private static let key = "sophia_deck_skip_counts"

    /// Past this, a course is demoted as far as `fatigue` allows; counting higher
    /// would only grow the stored dictionary for no effect on the deck.
    private static let maxPerCourse = 8

    /// Courses tracked at once. A reader who swipes for months would otherwise carry
    /// an entry for every course in the catalogue; the least-skipped are dropped
    /// first, since they are the ones the deck barely penalises anyway.
    private static let maxEntries = 120

    static func counts(defaults: UserDefaults = .standard) -> [String: Int] {
        defaults.dictionary(forKey: key) as? [String: Int] ?? [:]
    }

    /// Records that `courseId` was dealt and swiped past.
    static func registerSkip(_ courseId: String, defaults: UserDefaults = .standard) {
        var counts = counts(defaults: defaults)
        counts[courseId] = min((counts[courseId] ?? 0) + 1, maxPerCourse)
        if counts.count > maxEntries {
            let keep = counts.sorted { $0.value > $1.value }.prefix(maxEntries)
            counts = Dictionary(uniqueKeysWithValues: keep.map { ($0.key, $0.value) })
        }
        defaults.set(counts, forKey: key)
    }

    /// Clears a course's count once it has been opened: the reader skipped past it
    /// until they didn't, and holding the earlier refusals against it would keep
    /// burying a course they have just shown interest in.
    static func clear(_ courseId: String, defaults: UserDefaults = .standard) {
        var counts = counts(defaults: defaults)
        guard counts.removeValue(forKey: courseId) != nil else { return }
        defaults.set(counts, forKey: key)
    }

    static func reset(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
