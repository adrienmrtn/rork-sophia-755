import Foundation

/// La question du jour : un cours par jour, le même pour tout le monde, dont le titre est
/// une question (« Pourquoi le savon tue-t-il les bactéries ? »).
///
/// Une seule source pour la Biblio (« À la une »), la notification quotidienne, le widget
/// et le blocker TikTok, pour qu'ils parlent tous du même cours le même jour.
///
/// - **Réserve** : les cours dont le titre français contient « ? » (254 sur 309 ; les
///   titres traduits sont aussi des questions). Les œuvres (« Hamlet, Shakespeare ») et
///   les événements datés n'y entrent jamais.
/// - **Ordre fixe** : chaque matière est étalée régulièrement sur toute la suite, pour
///   qu'on n'enchaîne pas trois cours d'histoire. Le jour N (compté depuis le 1er octobre
///   2026) donne la question N.
/// - **Déjà lue** : un cours terminé n'est plus proposé ; on prend le suivant dans l'ordre.
/// - **Plan mémorisé** : le cours choisi pour une date est gardé (`planKey`). Celui du jour
///   ne bouge plus, même lu dans la journée ; ceux des jours à venir sont revus s'ils ont
///   été lus entre-temps. La notification et le widget, programmés à l'avance, annoncent
///   donc le cours que la Biblio montrera ce jour-là.
enum DailyQuestion {
    nonisolated struct Day: Hashable, Sendable {
        /// `yyyy-MM-dd`, calendrier grégorien, fuseau de l'appareil.
        let key: String
        /// Minuit, heure locale.
        let start: Date
    }

    private static let planKey = "sophia_daily_question_plan"
    /// Jours passés gardés dans le plan : leurs cours ne reviennent pas avant ce délai.
    private static let historyDays = 60

    /// Grégorien quel que soit le calendrier du téléphone : les clés et le comptage des
    /// jours doivent être les mêmes partout.
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    private static let referenceDate: Date = {
        DailyQuestion.calendar.date(from: DateComponents(year: 2026, month: 10, day: 1))
            ?? Date(timeIntervalSince1970: 0)
    }()

    static func day(for date: Date) -> Day {
        let gregorian = Self.calendar
        let start = gregorian.startOfDay(for: date)
        let parts = gregorian.dateComponents([.year, .month, .day], from: start)
        let key = String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
        return Day(key: key, start: start)
    }

    // MARK: - Réserve et ordre

    /// Les cours-questions, dans l'ordre de passage.
    static let order: [String] = {
        let questions = CourseData.allCourses.filter { $0.title.contains("?") }
        var ranked: [(position: Double, tieBreak: UInt64, id: String)] = []
        for subject in Subject.allCases {
            let ids = questions
                .filter { $0.subject == subject }
                .map(\.id)
                .sorted { DailyQuestion.stableHash($0) < DailyQuestion.stableHash($1) }
            guard !ids.isEmpty else { continue }
            // Décalage propre à la matière, pour que les six ne tombent pas toutes en tête.
            let offset = Double(DailyQuestion.stableHash(subject.rawValue) % 1000) / 1000
            for (index, id) in ids.enumerated() {
                let position = (Double(index) + offset) / Double(ids.count)
                ranked.append((position: position, tieBreak: DailyQuestion.stableHash(id), id: id))
            }
        }
        return ranked
            .sorted { ($0.position, $0.tieBreak) < ($1.position, $1.tieBreak) }
            .map(\.id)
    }()

    static let questionIds: Set<String> = Set(order)

    static func isQuestion(_ courseId: String) -> Bool {
        questionIds.contains(courseId)
    }

    /// Index du cours prévu pour ce jour quand personne n'a encore rien lu.
    private static func baseIndex(for day: Day) -> Int {
        guard !order.isEmpty else { return 0 }
        let days = Self.calendar.dateComponents([.day], from: referenceDate, to: day.start).day ?? 0
        let count = order.count
        return ((days % count) + count) % count
    }

    /// FNV-1a : stable d'un lancement à l'autre et d'un appareil à l'autre, contrairement
    /// à `hashValue`.
    static func stableHash(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }

    // MARK: - Plan

    /// La question d'aujourd'hui (et la mémorise si elle ne l'était pas encore).
    static func todayCourseId(
        now: Date = Date(),
        language: AppLanguage,
        isCompleted: (String) -> Bool
    ) -> String? {
        plan(from: now, days: 1, language: language, isCompleted: isCompleted).first?.courseId
    }

    /// Les questions des `days` prochains jours, aujourd'hui compris. Met le plan mémorisé à jour.
    @discardableResult
    static func plan(
        from now: Date = Date(),
        days: Int,
        language: AppLanguage,
        isCompleted: (String) -> Bool
    ) -> [(day: Day, courseId: String)] {
        guard !order.isEmpty, days > 0 else { return [] }
        let gregorian = Self.calendar
        let today = day(for: now)
        let available = Set(ContentCatalog.courses(for: language).map(\.id)).intersection(questionIds)
        guard !available.isEmpty else { return [] }

        let stored = storedPlan()
        let oldestKept = day(for: gregorian.date(byAdding: .day, value: -historyDays, to: today.start) ?? today.start).key
        var updated = stored.filter { $0.key >= oldestKept }
        // Les cours des jours passés ne reviennent pas tout de suite.
        var used = Set(updated.filter { $0.key < today.key }.values)
        var result: [(day: Day, courseId: String)] = []

        for offset in 0..<days {
            guard let date = gregorian.date(byAdding: .day, value: offset, to: today.start) else { continue }
            let current = day(for: date)
            if let kept = updated[current.key],
               available.contains(kept),
               offset == 0 || (!isCompleted(kept) && !used.contains(kept)) {
                used.insert(kept)
                result.append((current, kept))
                continue
            }
            let picked = pick(for: current, available: available, used: used, isCompleted: isCompleted)
            updated[current.key] = picked
            used.insert(picked)
            result.append((current, picked))
        }

        if updated != stored {
            UserDefaults.standard.set(updated, forKey: planKey)
        }
        return result
    }

    /// Premier cours non lu et pas déjà pris à partir de la place du jour ; si tout est lu,
    /// on relit, toujours sans doublon.
    private static func pick(
        for day: Day,
        available: Set<String>,
        used: Set<String>,
        isCompleted: (String) -> Bool
    ) -> String {
        let base = baseIndex(for: day)
        let count = order.count
        let rotated = (0..<count).map { order[(base + $0) % count] }.filter { available.contains($0) }
        return rotated.first { !used.contains($0) && !isCompleted($0) }
            ?? rotated.first { !used.contains($0) }
            ?? rotated.first
            ?? order[base]
    }

    private static func storedPlan() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: planKey) as? [String: String] ?? [:]
    }

    /// Cours prévus pour les jours à venir (sans aujourd'hui), pour ne pas les dévoiler ailleurs.
    static func upcomingCourseIds(now: Date = Date()) -> Set<String> {
        let todayKey = day(for: now).key
        return Set(storedPlan().filter { $0.key > todayKey }.values)
    }

    /// Vrai dès qu'une question du jour, aujourd'hui ou avant, a été lue.
    static func hasReadAQuestionOfTheDay(now: Date = Date(), isCompleted: (String) -> Bool) -> Bool {
        let todayKey = day(for: now).key
        return storedPlan().contains { $0.key <= todayKey && isCompleted($0.value) }
    }

    // MARK: - « À la une »

    /// Les autres cartes d'« À la une » : des questions non lues, tirées à partir de la
    /// date (les mêmes toute la journée), une par matière, les matières choisies dans
    /// l'onboarding d'abord.
    static func featuredCompanions(
        now: Date = Date(),
        count: Int,
        excluding: Set<String>,
        interests: Set<String>,
        language: AppLanguage,
        isCompleted: (String) -> Bool
    ) -> [Course] {
        guard count > 0 else { return [] }
        let today = day(for: now)
        let hidden = excluding.union(upcomingCourseIds(now: now))
        let catalogue = ContentCatalog.courses(for: language).filter {
            questionIds.contains($0.id) && !hidden.contains($0.id)
        }
        var generator = SeededGenerator(seed: stableHash("featured|" + today.key))
        let shuffled = catalogue.shuffled(using: &generator)
        let unread = shuffled.filter { !isCompleted($0.id) }

        let subjectOrder = Subject.allCases.shuffled(using: &generator)
        let preferred = subjectOrder.filter { interests.contains($0.storageKey) }
        let others = subjectOrder.filter { !interests.contains($0.storageKey) }

        var picks: [Course] = []
        var taken = Set<String>()
        for subject in preferred + others where picks.count < count {
            if let course = unread.first(where: { $0.subject == subject && !taken.contains($0.id) }) {
                picks.append(course)
                taken.insert(course.id)
            }
        }
        // Moins de matières que de cartes, ou tout est lu dans certaines : on complète.
        for course in unread + shuffled where picks.count < count && !taken.contains(course.id) {
            picks.append(course)
            taken.insert(course.id)
        }
        return picks
    }
}
