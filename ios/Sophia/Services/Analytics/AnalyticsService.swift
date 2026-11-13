import Foundation
import Supabase
import UIKit

// MARK: - Vocabulaire (docs/events.md)

/// Les noms d'événements, identiques sur iOS et Android. Un nom absent de cette liste est
/// refusé par la base (contrainte `course_events_name_check`).
nonisolated enum AnalyticsEventName: String, Sendable {
    case appOpen = "app_open"
    case onboardingStep = "onboarding_step"
    case cardImpression = "card_impression"
    case cardSkip = "card_skip"
    case cardOpen = "card_open"
    case courseOpen = "course_open"
    case sectionView = "section_view"
    case courseComplete = "course_complete"
    case glossaryOpen = "glossary_open"
    case funfactOpen = "funfact_open"
    case audioPlay = "audio_play"
    case quizStart = "quiz_start"
    case quizAnswer = "quiz_answer"
    case quizComplete = "quiz_complete"
    case like
    case unlike
    case save
    case unsave
    case share
    case follow
    case unfollow
    case notInterested = "not_interested"
    case report
    case paywallView = "paywall_view"
    case purchaseStarted = "purchase_started"
    case purchaseCompleted = "purchase_completed"
    case purchaseFailed = "purchase_failed"
}

/// D'où un cours a été ouvert. Posé par l'écran d'origine juste avant d'ouvrir le lecteur
/// (`AnalyticsService.shared.pendingCourseOpenSource`), consommé par `ContentView`.
nonisolated enum CourseOpenSource: String, Sendable {
    case feed, library, subject, path, favorites, profile
    case myCourses = "my_courses"
    case notification, widget, blocker, author, search, unknown
    /// Depuis la page d'un événement (collection d'une campagne).
    case event
    /// Depuis le lien web d'un cours partagé (lien universel, ou repris après installation).
    case sharedLink = "shared_link"
}

/// Valeur scalaire d'une propriété d'événement (`props`).
nonisolated enum AnalyticsValue: Codable, Sendable, ExpressibleByStringLiteral,
    ExpressibleByIntegerLiteral, ExpressibleByBooleanLiteral, ExpressibleByFloatLiteral {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    init(stringLiteral value: String) { self = .string(value) }
    init(integerLiteral value: Int) { self = .int(value) }
    init(booleanLiteral value: Bool) { self = .bool(value) }
    init(floatLiteral value: Double) { self = .double(value) }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else {
            self = .string(try container.decode(String.self))
        }
    }
}

/// Une ligne de `public.course_events`. Les clés suivent les colonnes.
nonisolated struct AnalyticsEventRow: Codable, Sendable {
    var event_id: UUID
    /// Vide tant que l'utilisateur n'est pas connecté (premiers écrans de l'onboarding) ;
    /// rempli au premier envoi.
    var user_id: UUID?
    var install_id: UUID
    var session_id: UUID
    var name: String
    var course_id: String?
    var lang: String
    var country: String?
    var platform: String
    var app_version: String
    var premium_status: String
    var screen: String?
    var position: Int?
    var algo_version: String?
    var props: [String: AnalyticsValue]
    /// ISO 8601 avec fractions de seconde, UTC.
    var ts: String
}

/// Une ligne de `public.subscriber_snapshots`.
nonisolated struct SubscriberSnapshotRow: Codable, Sendable {
    var user_id: UUID
    var is_active: Bool
    var period_type: String?
    var product_id: String?
    var store: String?
    var expires_at: String?
    var will_renew: Bool?
    var platform: String
    var app_version: String
    var reported_at: String
}

// MARK: - Service

/// Journal d'événements produit (docs/events.md).
///
/// Les événements sont mis en file sur le téléphone puis envoyés par lots dans
/// `course_events`, directement par PostgREST : la règle RLS n'accepte que les lignes de
/// l'utilisateur connecté, et un doublon (`event_id` déjà vu) est ignoré. La file survit à
/// un redémarrage (fichier dans Application Support, hors sauvegarde) et au mode avion ;
/// elle est envoyée toutes les 30 secondes, dès 50 événements, et au passage en
/// arrière-plan.
///
/// Rien ne part vers un SDK tiers : ce journal reste chez Sophia.
@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()

    /// Version de l'algorithme qui compose le fil, tant qu'il est calculé sur le téléphone.
    static let algoVersion = "local-v1"

    private static let flushInterval: Duration = .seconds(30)
    private static let flushThreshold = 50
    private static let batchSize = 200
    private static let queueCap = 5_000
    private static let sessionTimeout: TimeInterval = 30 * 60
    /// La règle RLS refuse un événement de plus de 30 jours : on n'essaie même pas.
    private static let maxEventAge: TimeInterval = 29 * 24 * 3600

    /// `free`, `trial`, `paid` ou `unknown` ; tenu à jour par `StoreViewModel`.
    var premiumStatus: String = "unknown"
    /// D'où le prochain cours va s'ouvrir. Posé par l'écran d'origine, lu par `ContentView`.
    var pendingCourseOpenSource: CourseOpenSource?

    private let client = SupabaseManager.shared
    private let installId: UUID
    /// L'identifiant d'installation, en lecture seule : sert aussi au tirage stable des tests
    /// A/B faits dans l'app (`PaywallExperiment`).
    var installIdentifier: UUID { installId }
    private let appVersion: String
    private var sessionId = UUID()
    private var lastActiveAt = Date()
    private var queue: [AnalyticsEventRow] = []
    private var queueDirty = false
    private var isFlushing = false
    private var headFailures = 0
    private var timerTask: Task<Void, Never>?
    private var lastSnapshotKey: String?

    private static let iso: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let queueURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("sophia-analytics-queue.json")
    }()

    private init() {
        installId = Self.loadInstallId()
        appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        queue = Self.loadQueue()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.flushInterval)
                await self?.flush()
            }
        }
    }

    // MARK: Enregistrer

    func log(
        _ name: AnalyticsEventName,
        courseId: String? = nil,
        screen: String? = nil,
        position: Int? = nil,
        algoVersion: String? = nil,
        props: [String: AnalyticsValue] = [:]
    ) {
        let row = AnalyticsEventRow(
            event_id: UUID(),
            user_id: AuthService.shared.currentUser?.id,
            install_id: installId,
            session_id: sessionId,
            name: name.rawValue,
            course_id: courseId,
            lang: AppLanguage.currentPersisted().rawValue,
            country: Locale.current.region?.identifier,
            platform: "ios",
            app_version: appVersion,
            premium_status: premiumStatus,
            screen: screen,
            position: position,
            algo_version: algoVersion,
            props: props,
            ts: Self.iso.string(from: Date())
        )
        queue.append(row)
        if queue.count > Self.queueCap {
            queue.removeFirst(queue.count - Self.queueCap)
        }
        queueDirty = true
        if queue.count >= Self.flushThreshold {
            Task { await flush() }
        }
    }

    /// Lit et efface la source posée par l'écran d'origine.
    func takeCourseOpenSource() -> CourseOpenSource {
        defer { pendingCourseOpenSource = nil }
        return pendingCourseOpenSource ?? .unknown
    }

    // MARK: Cycle de vie

    /// Passage au premier plan : nouvelle session après 30 minutes d'absence, et `app_open`.
    func appDidBecomeActive() {
        let now = Date()
        if now.timeIntervalSince(lastActiveAt) > Self.sessionTimeout {
            sessionId = UUID()
        }
        lastActiveAt = now
        let source: String
        switch pendingCourseOpenSource {
        case .notification: source = "notification"
        case .widget: source = "widget"
        case .sharedLink: source = "link"
        default: source = "direct"
        }
        log(.appOpen, props: ["source": .string(source), "nav": .string(FeatureFlags.navigationVariant.rawValue)])
    }

    /// Passage en arrière-plan : la file part tout de suite, le temps qu'iOS nous laisse.
    func appDidEnterBackground() {
        lastActiveAt = Date()
        persistQueue()
        let backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "analytics-flush")
        Task {
            await flush()
            if backgroundTask != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTask)
            }
        }
    }

    // MARK: Abonnement

    /// Statut d'abonnement tel que RevenueCat le donne au client, pour `subscriber_snapshots`.
    /// Envoyé une fois par valeur distincte et par lancement.
    func reportSubscription(
        isActive: Bool,
        periodType: String?,
        productId: String?,
        store: String?,
        expiresAt: Date?,
        willRenew: Bool?
    ) {
        guard let userId = AuthService.shared.currentUser?.id else { return }
        let key = [
            userId.uuidString, String(isActive), periodType ?? "", productId ?? "",
            String(expiresAt?.timeIntervalSince1970 ?? 0), willRenew.map(String.init) ?? "",
        ].joined(separator: "|")
        guard key != lastSnapshotKey else { return }
        lastSnapshotKey = key
        let row = SubscriberSnapshotRow(
            user_id: userId,
            is_active: isActive,
            period_type: periodType,
            product_id: productId,
            store: store,
            expires_at: expiresAt.map { Self.iso.string(from: $0) },
            will_renew: willRenew,
            platform: "ios",
            app_version: appVersion,
            reported_at: Self.iso.string(from: Date())
        )
        Task {
            do {
                try await client
                    .from("subscriber_snapshots")
                    .upsert(row, onConflict: "user_id", returning: .minimal)
                    .execute()
            } catch {
                // Réessayé à la prochaine mise à jour de CustomerInfo.
                lastSnapshotKey = nil
                #if DEBUG
                print("[Analytics] snapshot failed: \(error)")
                #endif
            }
        }
    }

    // MARK: Envoi

    func flush() async {
        guard !isFlushing else { return }
        guard let userId = AuthService.shared.currentUser?.id else {
            persistIfNeeded()
            return
        }
        isFlushing = true
        defer { isFlushing = false }

        let now = Date()
        for index in queue.indices where queue[index].user_id == nil {
            queue[index].user_id = userId
        }
        // Un autre compte, ou un événement trop vieux pour la règle RLS : abandonné.
        queue.removeAll { row in
            guard row.user_id == userId, let date = Self.iso.date(from: row.ts) else { return true }
            return now.timeIntervalSince(date) > Self.maxEventAge
        }

        while !queue.isEmpty {
            let batch = Array(queue.prefix(Self.batchSize))
            do {
                try await client
                    .from("course_events")
                    .upsert(batch, onConflict: "ts,event_id", returning: .minimal, ignoreDuplicates: true)
                    .execute()
                queue.removeFirst(min(batch.count, queue.count))
                queueDirty = true
                headFailures = 0
            } catch let error as PostgrestError {
                // Refus du serveur (ligne invalide) : au bout de trois fois, le lot est
                // abandonné plutôt que de bloquer tout le journal derrière lui.
                headFailures += 1
                #if DEBUG
                print("[Analytics] batch rejected: \(error)")
                #endif
                if headFailures >= 3 {
                    queue.removeFirst(min(batch.count, queue.count))
                    queueDirty = true
                    headFailures = 0
                    continue
                }
                break
            } catch {
                // Réseau : on garde tout et on réessaie plus tard.
                break
            }
        }
        persistIfNeeded()
    }

    // MARK: Persistance

    private func persistIfNeeded() {
        guard queueDirty else { return }
        persistQueue()
    }

    private func persistQueue() {
        queueDirty = false
        let rows = queue
        let url = Self.queueURL
        Task.detached(priority: .utility) {
            do {
                try FileManager.default.createDirectory(
                    at: url.deletingLastPathComponent(), withIntermediateDirectories: true
                )
                let data = try JSONEncoder().encode(rows)
                try data.write(to: url, options: .atomic)
                var excluded = url
                var values = URLResourceValues()
                values.isExcludedFromBackup = true
                try? excluded.setResourceValues(values)
            } catch {
                #if DEBUG
                print("[Analytics] queue not saved: \(error)")
                #endif
            }
        }
    }

    private static func loadQueue() -> [AnalyticsEventRow] {
        guard let data = try? Data(contentsOf: queueURL) else { return [] }
        return (try? JSONDecoder().decode([AnalyticsEventRow].self, from: data)) ?? []
    }

    private static func loadInstallId() -> UUID {
        let key = "sophia_install_id"
        if let stored = UserDefaults.standard.string(forKey: key), let id = UUID(uuidString: stored) {
            return id
        }
        let id = UUID()
        UserDefaults.standard.set(id.uuidString, forKey: key)
        return id
    }
}
