import Foundation

/// Les badges du profil (docs/badges.md).
///
/// Trois sortes : les badges permanents (série, lecture, matières, quiz, duels, social), un badge
/// par ligue de duel atteinte, un badge par événement. Un badge est gagné quand sa mesure atteint
/// sa cible ; il est alors enregistré avec sa date dans la progression (`UserProgress.earnedBadges`)
/// et ne se perd plus. Le lecteur en choisit trois au plus à afficher sur son profil.

nonisolated enum BadgeFamily: String, CaseIterable, Sendable {
    case streak, reading, subjects, quiz, duels, leagues, social, events

    var titleKey: String { "badges.family.\(rawValue)" }

    /// Duels et ligues n'existent que là où l'onglet Duels est ouvert.
    var needsDuels: Bool { self == .duels || self == .leagues }
}

/// Ce qu'un badge mesure. La valeur courante vient de `BadgeStats`.
nonisolated enum BadgeMetric: Hashable, Sendable {
    case streak
    case courses
    case earlyCourse
    case lateCourse
    case coursesInOneDay
    case subject(String)
    case subjectsCovered
    case quizzes
    case duelWins
    case duelBestScore
    case duelBestMargin
    case duelTiebreakWins
    case duelBestWinStreak
    case rivalWins
    case follows
    case likes
    case friends
    case league
    case event(slug: String)
}

nonisolated struct Badge: Identifiable, Hashable, Sendable {
    let id: String
    let family: BadgeFamily
    let metric: BadgeMetric
    let target: Int
    /// Symbole système, montré tant que l'illustration n'est pas là.
    let symbol: String
    /// Illustration embarquée (catalogue d'images de l'app), papier découpé.
    var imageName: String? = nil
    /// Illustration hébergée (badges d'événement, choisie dans l'admin du site).
    var imageURL: String? = nil
    /// Badge de ligue : le nom de la figure (« Vermeer »). Badge d'événement : son nom par langue.
    var leagueName: String? = nil
    var eventNames: [String: String]? = nil
    var eventTitles: [String: String]? = nil

    @MainActor
    func title(language: AppLanguage) -> String {
        if let leagueName {
            return String(format: AppLocalizable.string("duel.league.name", language: language), leagueName)
        }
        if let eventNames {
            return Campaign.localized(eventNames, language: language)
        }
        return AppLocalizable.string("badge.name.\(id)", language: language)
    }

    /// Ce qu'il faut faire pour l'obtenir.
    @MainActor
    func condition(language: AppLanguage) -> String {
        func text(_ key: String) -> String { AppLocalizable.string("badge.cond.\(key)", language: language) }
        switch metric {
        case .streak: return String(format: text("streak"), target)
        case .courses: return target == 1 ? text("firstCourse") : String(format: text("courses"), target)
        case .earlyCourse: return text("early")
        case .lateCourse: return text("late")
        case .coursesInOneDay: return String(format: text("binge"), target)
        case .subject(let key):
            let name = Subject.from(storageKey: key)?.localizedName(language: language) ?? key
            return String(format: text("subject"), target, name)
        case .subjectsCovered: return text("allSubjects")
        case .quizzes: return String(format: text("quiz"), target)
        case .duelWins: return target == 1 ? text("firstDuel") : String(format: text("duelWins"), target)
        case .duelBestScore: return target >= 20 ? text("duelPerfect") : String(format: text("duelScore"), target)
        case .duelBestMargin: return String(format: text("duelMargin"), target)
        case .duelTiebreakWins: return text("duelTiebreak")
        case .duelBestWinStreak: return String(format: text("duelStreak"), target)
        case .rivalWins: return text("rival")
        case .follows: return String(format: text("follows"), target)
        case .likes: return String(format: text("likes"), target)
        case .friends: return String(format: text("friends"), target)
        case .league: return String(format: text("league"), leagueName ?? "")
        case .event:
            let event = eventTitles.map { Campaign.localized($0, language: language) } ?? ""
            return String(format: text("event"), target, event)
        }
    }
}

// MARK: - Catalogue

nonisolated enum BadgeCatalog {
    /// Les 35 badges permanents, dans l'ordre d'affichage.
    static let permanent: [Badge] = {
        func make(_ id: String, _ family: BadgeFamily, _ metric: BadgeMetric, _ target: Int, _ symbol: String) -> Badge {
            Badge(id: id, family: family, metric: metric, target: target, symbol: symbol, imageName: "badge_\(id)")
        }
        return [
            make("streak_3", .streak, .streak, 3, "sparkle"),
            make("streak_7", .streak, .streak, 7, "flame.fill"),
            make("streak_30", .streak, .streak, 30, "flame.fill"),
            make("streak_100", .streak, .streak, 100, "flame.circle.fill"),
            make("streak_365", .streak, .streak, 365, "bird.fill"),

            make("courses_1", .reading, .courses, 1, "figure.walk"),
            make("courses_10", .reading, .courses, 10, "book.fill"),
            make("courses_50", .reading, .courses, 50, "books.vertical.fill"),
            make("courses_100", .reading, .courses, 100, "building.columns.fill"),
            make("early", .reading, .earlyCourse, 1, "sunrise.fill"),
            make("late", .reading, .lateCourse, 1, "moon.stars.fill"),
            make("binge", .reading, .coursesInOneDay, 5, "square.stack.3d.up.fill"),

            make("subject_histoire", .subjects, .subject("histoire"), 10, "hourglass"),
            make("subject_sciences", .subjects, .subject("sciences"), 10, "atom"),
            make("subject_litterature", .subjects, .subject("litterature"), 10, "text.book.closed.fill"),
            make("subject_art", .subjects, .subject("art"), 10, "paintpalette.fill"),
            make("subject_mythologie", .subjects, .subject("mythologie"), 10, "bolt.fill"),
            make("subject_comprendreLeMonde", .subjects, .subject("comprendreLeMonde"), 10, "globe.europe.africa.fill"),
            make("all_subjects", .subjects, .subjectsCovered, 6, "seal.fill"),

            make("quiz_10", .quiz, .quizzes, 10, "checkmark.circle.fill"),
            make("quiz_50", .quiz, .quizzes, 50, "graduationcap.fill"),

            make("duel_first", .duels, .duelWins, 1, "star.fill"),
            make("duel_wins_10", .duels, .duelWins, 10, "figure.fencing"),
            make("duel_wins_50", .duels, .duelWins, 50, "trophy.fill"),
            make("duel_wins_200", .duels, .duelWins, 200, "crown.fill"),
            make("duel_perfect", .duels, .duelBestScore, 20, "target"),
            make("duel_near", .duels, .duelBestScore, 18, "scope"),
            make("duel_margin", .duels, .duelBestMargin, 10, "water.waves"),
            make("duel_tiebreak", .duels, .duelTiebreakWins, 1, "snowflake"),
            make("duel_streak_5", .duels, .duelBestWinStreak, 5, "shield.fill"),
            make("duel_streak_10", .duels, .duelBestWinStreak, 10, "shield.lefthalf.filled"),
            make("duel_rival", .duels, .rivalWins, 1, "person.2.fill"),

            make("follows_3", .social, .follows, 3, "lamp.desk.fill"),
            make("likes_10", .social, .likes, 10, "heart.fill"),
            make("friends_3", .social, .friends, 3, "person.3.fill"),
        ]
    }()

    /// Les 30 ligues de duel, dans l'ordre (table `duel_leagues`) : identifiant et figure.
    private static let leagueFigures: [(slug: String, name: String)] = [
        ("aesop", "Aesop"), ("homer", "Homer"), ("sappho", "Sappho"), ("confucius", "Confucius"),
        ("socrates", "Socrates"), ("cleopatra", "Cleopatra"), ("hypatia", "Hypatia"), ("avicenna", "Avicenna"),
        ("murasaki", "Murasaki"), ("mansa_musa", "Mansa Musa"), ("dante", "Dante"), ("joan_of_arc", "Joan of Arc"),
        ("gutenberg", "Gutenberg"), ("leonardo", "Leonardo"), ("michelangelo", "Michelangelo"), ("copernicus", "Copernicus"),
        ("shakespeare", "Shakespeare"), ("galileo", "Galileo"), ("vermeer", "Vermeer"), ("newton", "Newton"),
        ("mozart", "Mozart"), ("napoleon", "Napoleon"), ("austen", "Austen"), ("darwin", "Darwin"),
        ("lovelace", "Lovelace"), ("van_gogh", "Van Gogh"), ("curie", "Curie"), ("einstein", "Einstein"),
        ("kahlo", "Kahlo"), ("sophia", "Sophia"),
    ]

    /// Un badge par ligue : le buste de sa figure, gagné en atteignant la ligue.
    static let leagues: [Badge] = leagueFigures.enumerated().map { index, figure in
        let position = index + 1
        return Badge(
            id: "league_\(figure.slug)",
            family: .leagues,
            metric: .league,
            target: position,
            symbol: "person.crop.circle.fill",
            imageName: String(format: "badge_league_%02d_%@", position, figure.slug),
            leagueName: figure.name
        )
    }

    /// Un badge par événement publié (le manifeste les garde un an après leur fin).
    @MainActor
    static var events: [Badge] {
        CampaignStore.all.reversed().map { campaign in
            Badge(
                id: "event_\(campaign.slug)",
                family: .events,
                metric: .event(slug: campaign.slug),
                target: campaign.challengeTarget,
                symbol: campaign.symbol ?? "sparkles",
                imageURL: campaign.badgeImageUrl,
                eventNames: campaign.badgeName,
                eventTitles: campaign.title
            )
        }
    }

    /// Tous les badges montrés dans cette langue, par famille.
    @MainActor
    static func all(language: AppLanguage) -> [Badge] {
        let duels = FeatureFlags.duelsVisible(language: language)
        return (permanent + leagues + events).filter { duels || !$0.family.needsDuels }
    }

    /// Un badge par son identifiant (profil d'un ami, badges affichés), quelle que soit la langue.
    @MainActor
    static func badge(id: String) -> Badge? {
        (permanent + leagues + events).first { $0.id == id }
    }
}

// MARK: - Compteurs de duel

/// Ce que la progression ne contient pas : les exploits de duel (meilleur score, plus grand écart,
/// victoire à la question décisive, victoire contre un ami), la meilleure ligue et le nombre
/// d'amis. Gardés sur l'appareil ; un badge gagné, lui, part dans la progression synchronisée.
/// Victoires, série et ligue sont aussi repris du serveur à chaque lecture de la page des duels.
@MainActor
enum BadgeCounters {
    enum Key: String {
        case duelWins, duelBestScore, duelBestMargin, duelTiebreakWins, duelBestWinStreak
        case rivalWins, bestLeague, friends
    }

    private static func defaultsKey(_ key: Key) -> String { "sophia_badge_counter_\(key.rawValue)" }
    private static let lastMatchKey = "sophia_badge_last_match"
    /// Posés à la première lecture du serveur : ce qui date d'avant n'est pas fêté.
    private static let duelBaselineKey = "sophia_badge_baseline_duels"
    private static let friendsBaselineKey = "sophia_badge_baseline_friends"

    static func value(_ key: Key) -> Int {
        UserDefaults.standard.integer(forKey: defaultsKey(key))
    }

    /// Ne fait que monter : un compteur est un record.
    static func raise(_ key: Key, to value: Int) {
        guard value > Self.value(key) else { return }
        UserDefaults.standard.set(value, forKey: defaultsKey(key))
        // Un record qui monte peut faire gagner un badge : il sera fêté.
        BadgeCelebrationCenter.shared.scheduleDetection()
    }

    /// Les statistiques tenues par le serveur (`duel_home`, résultat d'une partie classée).
    static func sync(profile: DuelProfile) {
        raise(.duelWins, to: profile.wins)
        raise(.duelBestWinStreak, to: max(profile.winStreak, profile.bestWinStreak))
        raise(.bestLeague, to: profile.leaguePosition)
    }

    static func sync(home: DuelHome) {
        sync(profile: home.profile)
        if let best = home.league(forTrophies: home.profile.bestTrophies) {
            raise(.bestLeague, to: best.position)
        }
        // Première lecture : victoires et ligues d'avant cette version sont attribuées sans fête.
        if !UserDefaults.standard.bool(forKey: duelBaselineKey),
           BadgeCelebrationCenter.shared.absorb(matching: { $0.family.needsDuels }) {
            UserDefaults.standard.set(true, forKey: duelBaselineKey)
        }
    }

    /// Une partie vient de finir. Compté une fois par partie. Les exploits (score, écart,
    /// question décisive) ne comptent qu'en duel classé ; un duel amical gagné compte pour « Rival ».
    static func record(_ summary: DuelSummary) {
        let matchId = summary.match.matchId.uuidString
        guard UserDefaults.standard.string(forKey: lastMatchKey) != matchId else { return }
        UserDefaults.standard.set(matchId, forKey: lastMatchKey)
        guard summary.won, !summary.abandoned, !summary.draw else { return }
        if summary.friendly {
            raise(.rivalWins, to: value(.rivalWins) + 1)
            return
        }
        // Une victoire par déconnexion compte comme une victoire, pas comme un exploit.
        guard !summary.forfeit else { return }
        raise(.duelBestScore, to: summary.playerScore)
        raise(.duelBestMargin, to: summary.playerScore - summary.opponentScore)
        if summary.tiebreak {
            raise(.duelTiebreakWins, to: value(.duelTiebreakWins) + 1)
        }
    }

    static func recordFriends(count: Int) {
        raise(.friends, to: count)
        // Première lecture : les amis déjà là sont comptés sans fête.
        if !UserDefaults.standard.bool(forKey: friendsBaselineKey),
           BadgeCelebrationCenter.shared.absorb(matching: { $0.metric == .friends }) {
            UserDefaults.standard.set(true, forKey: friendsBaselineKey)
        }
    }
}

// MARK: - Mesures

/// Les valeurs courantes de toutes les mesures, lues une fois pour évaluer tous les badges.
@MainActor
struct BadgeStats {
    private let progressManager: ProgressManager
    private let completionDates: [Date]

    init(progressManager: ProgressManager) {
        self.progressManager = progressManager
        completionDates = progressManager.progress.courseProgress.values
            .filter(\.isCompleted)
            .compactMap { $0.completedAt.flatMap { ProgressManager.isoFormatter.date(from: $0) } }
    }

    func value(for metric: BadgeMetric) -> Int {
        let progress = progressManager.progress
        let calendar = Calendar.current
        switch metric {
        case .streak:
            return progressManager.streak
        case .courses:
            return progressManager.completedCount
        case .earlyCourse:
            return completionDates.contains { calendar.component(.hour, from: $0) < 8 } ? 1 : 0
        case .lateCourse:
            return completionDates.contains { calendar.component(.hour, from: $0) >= 23 } ? 1 : 0
        case .coursesInOneDay:
            let perDay = Dictionary(grouping: completionDates) { calendar.startOfDay(for: $0) }
            return perDay.values.map(\.count).max() ?? 0
        case .subject(let key):
            guard let subject = Subject.from(storageKey: key) else { return 0 }
            return progressManager.completedCount(for: subject)
        case .subjectsCovered:
            return Subject.allCases.filter { progressManager.completedCount(for: $0) > 0 }.count
        case .quizzes:
            return progress.completedQuizCourseIds.count
        case .duelWins: return BadgeCounters.value(.duelWins)
        case .duelBestScore: return BadgeCounters.value(.duelBestScore)
        case .duelBestMargin: return BadgeCounters.value(.duelBestMargin)
        case .duelTiebreakWins: return BadgeCounters.value(.duelTiebreakWins)
        case .duelBestWinStreak: return BadgeCounters.value(.duelBestWinStreak)
        case .rivalWins: return BadgeCounters.value(.rivalWins)
        case .follows: return progress.followedCreatorSlugs.count
        case .likes: return progress.likedCourseIds.count
        case .friends: return BadgeCounters.value(.friends)
        case .league: return BadgeCounters.value(.bestLeague)
        case .event(let slug):
            guard let campaign = CampaignStore.all.first(where: { $0.slug == slug }) else { return 0 }
            return CampaignStore.challengeProgress(for: campaign, progressManager: progressManager)
        }
    }

    /// La valeur bornée à la cible, pour la barre de progression (« 4 sur 10 »).
    func progress(for badge: Badge) -> Int {
        min(value(for: badge.metric), badge.target)
    }

    func isReached(_ badge: Badge) -> Bool {
        value(for: badge.metric) >= badge.target
    }
}
