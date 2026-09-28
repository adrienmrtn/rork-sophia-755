import Foundation

// MARK: - Rules

/// The learning path ("Parcours" tab): every collection is a level, laid out in catalogue
/// order. Inside a level the courses open one after the other, the level ends with a quiz
/// mixing questions from its courses, and passing that quiz opens the next level.
nonisolated enum LearningPathRules {
    /// Questions drawn for an end-of-level quiz. A level with fewer questions uses them all.
    static let quizQuestionCount = 20

    /// Fully correct answers needed to pass: strictly more than half, so 11 of 20.
    static func passMark(total: Int) -> Int {
        guard total > 0 else { return 0 }
        return total / 2 + 1
    }

    static func isPassing(correct: Int, total: Int) -> Bool {
        total > 0 && correct >= passMark(total: total)
    }

    /// How many questions a quiz on this collection actually draws.
    static func quizQuestionCount(for collection: LearningCollection) -> Int {
        let available = collection.courses.reduce(0) { $0 + $1.quiz.count }
        return min(quizQuestionCount, available)
    }
}

// MARK: - Nodes and levels

nonisolated enum PathNodeState: String, Codable, Sendable, Comparable {
    case locked
    case available
    case completed

    private var rank: Int {
        switch self {
        case .locked: 0
        case .available: 1
        case .completed: 2
        }
    }

    static func < (lhs: PathNodeState, rhs: PathNodeState) -> Bool {
        lhs.rank < rhs.rank
    }
}

nonisolated enum PathNodeKind: Sendable, Equatable {
    case course(Course)
    case quiz
}

/// One pod on the trail: a course of the level, or the quiz that closes it.
nonisolated struct PathNode: Identifiable, Sendable, Equatable {
    let id: String
    let kind: PathNodeKind
    let state: PathNodeState
    /// Position within the level, the quiz last.
    let index: Int

    var course: Course? {
        if case .course(let course) = kind { return course }
        return nil
    }

    var isQuiz: Bool { kind == .quiz }
}

nonisolated struct PathLevel: Identifiable, Sendable {
    let collection: LearningCollection
    /// Level number shown to the reader, from 1.
    let number: Int
    /// Course nodes in collection order, then the quiz node.
    let nodes: [PathNode]
    let isUnlocked: Bool
    let isPassed: Bool
    let completedCourseCount: Int
    /// Where the zigzag was when this level started, so the curve flows across levels.
    let wavePhase: Int

    var id: String { collection.id }
    var courseCount: Int { max(0, nodes.count - 1) }
    var quizNodeId: String { LearningPathSnapshot.quizNodeId(collectionId: collection.id) }

    /// The node the reader plays next, when this is the active level.
    var currentNodeId: String? {
        guard isUnlocked, !isPassed else { return nil }
        return nodes.first { $0.state == .available }?.id
    }
}

nonisolated struct LearningPathSnapshot: Sendable {
    let levels: [PathLevel]

    static let empty = LearningPathSnapshot(levels: [])

    /// The level being played: unlocked but not yet passed. `nil` once everything is passed.
    var activeLevel: PathLevel? {
        levels.first { $0.isUnlocked && !$0.isPassed }
    }

    var currentNodeId: String? { activeLevel?.currentNodeId }

    var isEverythingPassed: Bool {
        !levels.isEmpty && levels.allSatisfy(\.isPassed)
    }

    /// Every node's state, keyed by node id, for diffing against what the reader last saw.
    var nodeStates: [String: PathNodeState] {
        var states: [String: PathNodeState] = [:]
        for level in levels {
            for node in level.nodes {
                states[node.id] = node.state
            }
        }
        return states
    }

    var orderedNodeIds: [String] {
        levels.flatMap { $0.nodes.map(\.id) }
    }

    func level(containing nodeId: String) -> PathLevel? {
        levels.first { level in level.nodes.contains { $0.id == nodeId } }
    }

    /// A course can belong to several collections, so its node id carries the collection.
    static func courseNodeId(collectionId: String, courseId: String) -> String {
        "\(collectionId)|\(courseId)"
    }

    static func quizNodeId(collectionId: String) -> String {
        "\(collectionId)|quiz"
    }
}

// MARK: - Engine

/// Derives the whole path from the catalogue and the reader's progress. A course finished
/// anywhere in the app (home, library) counts as a completed pod.
enum LearningPathEngine {
    static func snapshot(progressManager: ProgressManager) -> LearningPathSnapshot {
        var levels: [PathLevel] = []
        var previousPassed = true
        var wavePhase = 0

        for collection in ContentCatalog.activeCollections {
            let courses = collection.courses
            guard !courses.isEmpty else { continue }

            let isPassed = progressManager.isPathLevelPassed(collection.id)
            let isUnlocked = previousPassed || isPassed
            var nodes: [PathNode] = []
            var everythingBeforeDone = true
            var completedCount = 0

            for (position, course) in courses.enumerated() {
                let isDone = progressManager.courseStatus(for: course.id) == .completed
                if isDone { completedCount += 1 }
                let state: PathNodeState
                if !isUnlocked {
                    state = .locked
                } else if isDone {
                    state = .completed
                } else if everythingBeforeDone {
                    // The first unfinished course is the one to play; the ones after wait.
                    state = .available
                } else {
                    state = .locked
                }
                everythingBeforeDone = everythingBeforeDone && isDone
                nodes.append(PathNode(
                    id: LearningPathSnapshot.courseNodeId(collectionId: collection.id, courseId: course.id),
                    kind: .course(course),
                    state: state,
                    index: position
                ))
            }

            let quizState: PathNodeState
            if !isUnlocked {
                quizState = .locked
            } else if isPassed {
                quizState = .completed
            } else if everythingBeforeDone {
                quizState = .available
            } else {
                quizState = .locked
            }
            nodes.append(PathNode(
                id: LearningPathSnapshot.quizNodeId(collectionId: collection.id),
                kind: .quiz,
                state: quizState,
                index: courses.count
            ))

            levels.append(PathLevel(
                collection: collection,
                number: levels.count + 1,
                nodes: nodes,
                isUnlocked: isUnlocked,
                isPassed: isPassed,
                completedCourseCount: completedCount,
                wavePhase: wavePhase
            ))
            wavePhase += nodes.count
            previousPassed = isPassed
        }

        return LearningPathSnapshot(levels: levels)
    }
}

// MARK: - Quiz draw

enum PathQuizBuilder {
    /// Up to `count` questions spread as evenly as possible over the level's courses, in
    /// random order. Every attempt draws afresh, so a retry is never the same quiz.
    static func questions(
        for collection: LearningCollection,
        count: Int = LearningPathRules.quizQuestionCount
    ) -> [(course: Course, question: QuizQuestion)] {
        var pools: [(course: Course, remaining: [QuizQuestion])] = collection.courses
            .filter(\.hasQuiz)
            .map { (course: $0, remaining: $0.quiz.shuffled()) }
        guard !pools.isEmpty else { return [] }
        pools.shuffle()

        var picked: [(course: Course, question: QuizQuestion)] = []
        var exhausted = false
        while picked.count < count && !exhausted {
            exhausted = true
            for index in pools.indices where picked.count < count {
                if let question = pools[index].remaining.popLast() {
                    picked.append((course: pools[index].course, question: question))
                    exhausted = false
                }
            }
        }
        return picked.shuffled()
    }
}

// MARK: - What the reader last saw

/// Node states as the reader last saw them on this device, so the next visit can animate
/// exactly what changed in between (a course finished from the home, a level passed…).
/// Deliberately outside the synchronised progress: it is a display concern.
enum LearningPathSeenStore {
    private static let key = "sophia_path_seen_node_states"

    static func load() -> [String: PathNodeState]? {
        guard let raw = UserDefaults.standard.dictionary(forKey: key) as? [String: String] else { return nil }
        var states: [String: PathNodeState] = [:]
        for (id, value) in raw {
            if let state = PathNodeState(rawValue: value) {
                states[id] = state
            }
        }
        return states
    }

    static func save(_ states: [String: PathNodeState]) {
        UserDefaults.standard.set(states.mapValues(\.rawValue), forKey: key)
    }
}
