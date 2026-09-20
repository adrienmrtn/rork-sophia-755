import Foundation

/// What the deck knows about a reader, gathered in one place so the builder stays a
/// pure function: everything below already lives in `ProgressManager` or
/// `UserDefaults`, and passing it in is what lets the deck be tested without one.
nonisolated struct DeckContext: Sendable {
    /// Courses finished, keyed by `Subject.storageKey`. The only preference signal
    /// that is actually the reader's — favourites are not, since the onboarding swipe
    /// writes its likes straight into them.
    var completedBySubject: [String: Int]

    /// Courses read most recently, most recent first. Only `recentWindow` are used.
    var recentCourseIds: [String]

    /// Subjects behind the objective picked during onboarding. A hint for the first
    /// few cards, nothing more — see `objectiveFadesAfter`.
    var objectiveSubjects: Set<String>

    /// How many times each course has been dealt and swiped past without opening.
    var skipCounts: [String: Int]

    init(
        completedBySubject: [String: Int] = [:],
        recentCourseIds: [String] = [],
        objectiveSubjects: Set<String> = [],
        skipCounts: [String: Int] = [:]
    ) {
        self.completedBySubject = completedBySubject
        self.recentCourseIds = recentCourseIds
        self.objectiveSubjects = objectiveSubjects
        self.skipCounts = skipCounts
    }

    /// A reader the app knows nothing about yet — the deck is then the base weights
    /// and observed quality alone, which is still far from the shuffle it replaced.
    static let empty = DeckContext()
}

/// Builds the home course deck: which subject each card comes from, and which course
/// within it.
///
/// It replaces `courses.shuffled()`. The shuffle was not merely weak — it dealt one
/// card in six from mythology to a reader who only ever finishes science, and under
/// the freemium gate (one free course a day) the first card decides that reader's
/// day. What it *was* good for is that it exposed all 238 courses equally, which is
/// what makes `CourseAffinity`'s numbers trustworthy. That is why a quarter of the
/// deck is still dealt at random: the day the model is refreshed, it must not have
/// been trained on its own recommendations.
///
/// Three rules shape the result:
///
/// - **Quotas, never filters.** No subject is ever excluded, whatever the reader's
///   objective or history. The onboarding objective stopped being a filter because
///   it never deserved to be one: roughly half the readers of *every* subject also
///   read science, so science belongs in everyone's deck from the first card.
/// - **A pattern, not a ranking.** Sorting by score would deal ten science cards in a
///   row. Subjects are drawn by weight instead, and never three times consecutively.
/// - **A floor under every subject.** Without it a subject disappears from a reader's
///   deck, nothing more is ever learned about it, and 40 courses quietly die.
enum HomeDeckBuilder {
    // MARK: - Tuning

    /// One card in four is drawn at random from outside the dominant subject. This is
    /// the exploration that keeps the log usable and the reader out of a rut.
    static let explorationEvery = 4

    /// No subject ever falls below this share of the deck.
    static let subjectFloor = 0.05

    /// How hard a reader's own history bends the base weights. At 1.5, someone who
    /// finishes nothing but science roughly doubles science's share.
    static let affinityStrength = 1.5

    /// Multiplier applied to the subjects of the onboarding objective…
    static let objectiveBonus = 1.2

    /// …until this many courses have been finished, after which what the reader reads
    /// replaces what they once ticked.
    static let objectiveFadesAfter = 3

    /// How many recently read courses pull their neighbours up.
    static let recentWindow = 5

    /// Beyond this many cards of one subject in a row, that subject is skipped.
    static let maxConsecutiveSameSubject = 2

    /// A neighbour this many times more read than chance contributes the full boost.
    private static let liftForFullBoost = 10.0
    private static let neighbourBoostCeiling = 0.8
    private static let fatiguePerSkip = 0.15
    private static let fatigueCeiling = 0.6
    /// Quality of a course the model has never seen — the middle, not zero, so a
    /// newly added course is neither buried nor promoted before anyone has read it.
    private static let unknownQuality = 0.5

    // MARK: - Public API

    /// The deck for this visit, unfinished courses only, best first.
    static func deck(
        from courses: [Course],
        context: DeckContext = .empty,
        isCompleted: (String) -> Bool
    ) -> [Course] {
        var generator = SystemRandomNumberGenerator()
        return deck(from: courses, context: context, isCompleted: isCompleted, using: &generator)
    }

    /// Deck built with a caller-supplied source of randomness.
    ///
    /// Tests pass a seeded generator; `OnboardingCourseRecommender` passes one derived
    /// from the install, so that a recommendation recomputed during a SwiftUI layout
    /// pass comes back identical instead of reshuffling under the reader.
    static func deck<G: RandomNumberGenerator>(
        from courses: [Course],
        context: DeckContext,
        isCompleted: (String) -> Bool,
        using generator: inout G
    ) -> [Course] {
        let candidates = courses.filter { !isCompleted($0.id) }
        guard !candidates.isEmpty else { return [] }

        let weights = subjectWeights(context: context)
        let dominant = weights.max { $0.value < $1.value }?.key

        // Best-scoring course first within each subject; the draw below only ever
        // takes the head, so the ordering is done once here rather than per card.
        var pools: [String: [Course]] = [:]
        for course in candidates {
            pools[course.subject.storageKey, default: []].append(course)
        }
        for (key, pool) in pools {
            pools[key] = pool.sorted { score($0, context: context) > score($1, context: context) }
        }

        var deck: [Course] = []
        deck.reserveCapacity(candidates.count)
        var recentSubjects: [String] = []

        while !pools.isEmpty {
            let blocked = blockedSubject(recentSubjects)
            let isExploration = (deck.count + 1) % explorationEvery == 0

            let key: String
            if isExploration,
               let explored = explorationSubject(
                   in: pools, avoiding: blocked, dominant: dominant, using: &generator
               ) {
                key = explored
            } else if let drawn = drawSubject(
                in: pools, weights: weights, avoiding: blocked, using: &generator
            ) {
                key = drawn
            } else {
                break
            }

            guard var pool = pools[key], !pool.isEmpty else {
                pools[key] = nil
                continue
            }
            // Exploration deliberately ignores the score: a card nobody would have
            // ranked highly is the only kind that teaches the model something new.
            let index = isExploration ? Int.random(in: 0..<pool.count, using: &generator) : 0
            deck.append(pool.remove(at: index))
            pools[key] = pool.isEmpty ? nil : pool

            recentSubjects.append(key)
            if recentSubjects.count > maxConsecutiveSameSubject {
                recentSubjects.removeFirst()
            }
        }

        return deck
    }

    // MARK: - Weights

    /// How much of the deck each subject gets, summing to 1.
    ///
    /// Starts from what every reader does on average (`CourseAffinity.subjectBaseWeight`
    /// — roughly a third science), bends it by how the reader's own finished courses
    /// differ from that average, nudges the objective's subjects while the reader is
    /// still new, and finally lifts anything under `subjectFloor`.
    static func subjectWeights(context: DeckContext) -> [String: Double] {
        let keys = Subject.allCases.map(\.storageKey)
        let base = keys.reduce(into: [String: Double]()) { result, key in
            result[key] = CourseAffinity.subjectBaseWeight[key] ?? (1.0 / Double(keys.count))
        }

        let totalCompleted = context.completedBySubject.values.reduce(0, +)
        var weights: [String: Double] = [:]
        for key in keys {
            let baseWeight = base[key] ?? 0
            var weight = baseWeight
            if totalCompleted > 0 {
                let share = Double(context.completedBySubject[key] ?? 0) / Double(totalCompleted)
                let affinity = min(max(share - baseWeight, -1), 1)
                weight = baseWeight * (1 + affinityStrength * affinity)
            }
            if totalCompleted < objectiveFadesAfter, context.objectiveSubjects.contains(key) {
                weight *= objectiveBonus
            }
            weights[key] = max(weight, 0)
        }

        return applyFloor(to: normalised(weights))
    }

    private static func normalised(_ weights: [String: Double]) -> [String: Double] {
        let total = weights.values.reduce(0, +)
        guard total > 0 else {
            let equal = 1.0 / Double(max(weights.count, 1))
            return weights.mapValues { _ in equal }
        }
        return weights.mapValues { $0 / total }
    }

    /// Lifts every subject to `subjectFloor`, paid for by those above it in
    /// proportion to how far above they are.
    ///
    /// Not `max(weight, floor)` followed by a re-normalisation: that pushes the
    /// floored subjects back under the floor, and would have to be iterated. This is
    /// exact in one pass — the result still sums to 1 — and leaves the weights
    /// untouched when nothing is under the floor, which is the usual case.
    private static func applyFloor(to weights: [String: Double]) -> [String: Double] {
        let deficit = weights.values.reduce(0.0) { $0 + max(0, subjectFloor - $1) }
        guard deficit > 0 else { return weights }
        let surplus = weights.values.reduce(0.0) { $0 + max(0, $1 - subjectFloor) }
        guard surplus > 0 else {
            let equal = 1.0 / Double(max(weights.count, 1))
            return weights.mapValues { _ in equal }
        }
        let scale = 1 - deficit / surplus
        return weights.mapValues { weight in
            weight <= subjectFloor ? subjectFloor : subjectFloor + (weight - subjectFloor) * scale
        }
    }

    // MARK: - Scoring

    /// How well a course fits this reader, within its own subject.
    ///
    /// Deliberately not comparable across subjects: the weights above already carry
    /// how much more science is wanted than mythology, and `CourseAffinity.quality` is
    /// normalised inside each subject so that preference is not counted twice.
    static func score(_ course: Course, context: DeckContext) -> Double {
        let quality = CourseAffinity.quality[course.id] ?? unknownQuality
        return quality + neighbourBoost(course, context: context) - fatigue(course, context: context)
    }

    /// How strongly the courses just read pull this one up.
    ///
    /// Both directions are checked because the neighbour lists are truncated to the
    /// best eight: A can be among B's eight without B being among A's.
    private static func neighbourBoost(_ course: Course, context: DeckContext) -> Double {
        var best = 0.0
        for (position, recentId) in context.recentCourseIds.prefix(recentWindow).enumerated() {
            guard recentId != course.id else { continue }
            let lift = max(
                CourseAffinity.neighbours(of: recentId).first { $0.id == course.id }?.lift ?? 0,
                CourseAffinity.neighbours(of: course.id).first { $0.id == recentId }?.lift ?? 0
            )
            guard lift > 0 else { continue }
            // The 5th course back should not weigh as much as the last one read.
            let recency = 1 - 0.15 * Double(position)
            let strength = min(lift / liftForFullBoost, 1) * neighbourBoostCeiling * recency
            best = max(best, strength)
        }
        return best
    }

    /// How far a course has worn out its welcome, capped so it is demoted rather than
    /// banished — tastes change, and a card swiped past in a hurry is not a verdict.
    private static func fatigue(_ course: Course, context: DeckContext) -> Double {
        let skips = context.skipCounts[course.id] ?? 0
        return min(Double(skips) * fatiguePerSkip, fatigueCeiling)
    }

    // MARK: - Drawing

    /// The subject to keep out of the next draw, if the last cards were all from it.
    private static func blockedSubject(_ recentSubjects: [String]) -> String? {
        guard recentSubjects.count >= maxConsecutiveSameSubject,
              let last = recentSubjects.last,
              recentSubjects.allSatisfy({ $0 == last }) else { return nil }
        return last
    }

    private static func drawSubject<G: RandomNumberGenerator>(
        in pools: [String: [Course]],
        weights: [String: Double],
        avoiding blocked: String?,
        using generator: inout G
    ) -> String? {
        var available = pools.keys.filter { $0 != blocked }
        // Blocking must never end the deck: if the run is all that is left, the run
        // continues rather than the remaining courses being dropped.
        if available.isEmpty { available = Array(pools.keys) }
        guard !available.isEmpty else { return nil }

        let total = available.reduce(0.0) { $0 + (weights[$1] ?? 0) }
        guard total > 0 else { return available.randomElement(using: &generator) }

        var ticket = Double.random(in: 0..<total, using: &generator)
        for key in available.sorted() {  // sorted: the draw must not depend on hash order
            ticket -= weights[key] ?? 0
            if ticket <= 0 { return key }
        }
        return available.sorted().last
    }

    private static func explorationSubject<G: RandomNumberGenerator>(
        in pools: [String: [Course]],
        avoiding blocked: String?,
        dominant: String?,
        using generator: inout G
    ) -> String? {
        let available = pools.keys.filter { $0 != blocked && $0 != dominant }
        guard !available.isEmpty else { return nil }
        // Uniform over subjects rather than over courses: a subject with three
        // courses left is as worth exploring as one with thirty.
        return available.sorted().randomElement(using: &generator)
    }
}

/// Deterministic random source (SplitMix64), for decks that must come back identical.
///
/// SwiftUI recomputes a view's body freely, so a recommendation built on
/// `SystemRandomNumberGenerator` inside a computed property deals the reader a new
/// hand on every layout pass. Seeding per install keeps the hand stable while still
/// giving different people different cards — which is the whole point of no longer
/// showing everyone the same five.
nonisolated struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // 0 is a fixed point of the mixing function below: anything seeded with it
        // would return the same number forever.
        state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
