import Foundation
import Mixpanel
import RevenueCat

enum AnalyticsService {
    private static let sessionGapSeconds: TimeInterval = 30 * 60
    private static let lastSessionKey = "sophia_analytics_last_session"
    private static let firstOpenKey = "sophia_analytics_first_open"

    static func configure() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        Mixpanel.initialize(
            token: AppConfig.MIXPANEL_TOKEN,
            trackAutomaticEvents: false,
            superProperties: [
                "app_version": version,
                "platform": "ios",
            ],
            serverURL: "https://api-eu.mixpanel.com"
        )

        if UserDefaults.standard.object(forKey: firstOpenKey) == nil {
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: firstOpenKey)
        }
    }

    static func updateUserContext(
        language: AppLanguage,
        isPremium: Bool,
        onboardingCompleted: Bool
    ) {
        let interests = Array(OnboardingViewModel.userInterestKeys()).sorted()
        let unlocked = Subject.allCases.map(\.storageKey).sorted()

        let mixpanel = Mixpanel.mainInstance()
        mixpanel.registerSuperProperties([
            "language": language.rawValue,
            "is_premium": isPremium,
            "onboarding_completed": onboardingCompleted,
            "unlocked_subjects": unlocked,
        ])
        mixpanel.people.set(properties: [
            "interests": interests,
            "is_premium": isPremium,
            "language": language.rawValue,
        ])
        linkRevenueCatUserIfNeeded()
    }

    static func linkRevenueCatUserIfNeeded() {
        guard Purchases.isConfigured else { return }
        let rcUserID = Purchases.shared.appUserID
        guard !rcUserID.isEmpty else { return }
        Mixpanel.mainInstance().identify(distinctId: rcUserID)
    }

    // MARK: - Lifecycle

    static func trackAppOpened(source: String) {
        track("app_opened", ["source": source])
    }

    static func trackSessionIfNeeded(isPremium: Bool) {
        let now = Date().timeIntervalSince1970
        let last = UserDefaults.standard.double(forKey: lastSessionKey)
        guard last == 0 || now - last >= sessionGapSeconds else { return }

        UserDefaults.standard.set(now, forKey: lastSessionKey)
        let firstOpen = UserDefaults.standard.double(forKey: firstOpenKey)
        let daysSinceInstall: Int
        if firstOpen > 0 {
            daysSinceInstall = max(0, Int((now - firstOpen) / 86_400))
        } else {
            daysSinceInstall = 0
        }

        track("session_started", [
            "days_since_install": daysSinceInstall,
            "is_premium": isPremium,
        ])
    }

    // MARK: - Onboarding

    static func trackOnboardingStarted() {
        track("onboarding_started")
    }

    static func trackOnboardingStepViewed(stepIndex: Int, action: String? = nil) {
        var props: [String: MixpanelType] = [
            "step_index": stepIndex,
            "step_name": onboardingStepName(for: stepIndex),
        ]
        if let action { props["action"] = action }
        track("onboarding_step_viewed", props)
    }

    static func trackOnboardingInterestsSet(_ interests: Set<String>) {
        track("onboarding_interests_set", [
            "interests": Array(interests).sorted(),
        ])
    }

    static func trackOnboardingCompleted(sawPaywall: Bool, isPremiumAtExit: Bool) {
        track("onboarding_completed", [
            "saw_paywall": sawPaywall,
            "is_premium_at_exit": isPremiumAtExit,
        ])
    }

    // MARK: - Paywall

    static func trackPaywallViewed(context: String, triggerCourseId: String? = nil) {
        var props: [String: MixpanelType] = ["context": context]
        if let triggerCourseId { props["trigger_course_id"] = triggerCourseId }
        track("paywall_viewed", props)
    }

    static func trackPaywallDismissed(context: String, durationSeconds: Int) {
        track("paywall_dismissed", [
            "context": context,
            "duration_seconds": durationSeconds,
        ])
    }

    static func trackDiscountOfferViewed(source: String) {
        track("discount_offer_viewed", ["source": source])
    }

    static func trackPurchaseCompleted(context: String, offeringId: String? = nil, packageId: String? = nil) {
        var props: [String: MixpanelType] = ["context": context]
        if let offeringId { props["offering_id"] = offeringId }
        if let packageId { props["package_id"] = packageId }
        track("purchase_completed", props)
        Mixpanel.mainInstance().people.set(property: "is_premium", to: true)
    }

    // MARK: - Course

    static func trackCourseOpened(
        courseId: String,
        subject: Subject,
        source: String,
        isFreeUser: Bool
    ) {
        track("course_opened", [
            "course_id": courseId,
            "subject": subject.storageKey,
            "source": source,
            "is_free_user": isFreeUser,
        ])
    }

    static func trackCourseCompleted(course: Course) {
        track("course_completed", [
            "course_id": course.id,
            "subject": course.subject.storageKey,
            "lesson_count": course.lessons.count,
            "has_quiz": course.hasQuiz,
        ])
    }

    static func trackCourseSessionEnded(
        courseId: String,
        subject: Subject,
        durationSeconds: Int,
        lessonsReached: Int,
        lessonCount: Int,
        continueTaps: Int,
        scrolledOnFirstLesson: Bool,
        engagementTier: String,
        exitReason: String
    ) {
        let progress = lessonCount > 0 ? Double(lessonsReached) / Double(lessonCount) : 0
        track("course_session_ended", [
            "course_id": courseId,
            "subject": subject.storageKey,
            "duration_seconds": durationSeconds,
            "lessons_reached": lessonsReached,
            "lesson_count": lessonCount,
            "progress_pct": progress,
            "continue_taps": continueTaps,
            "scrolled_on_first_lesson": scrolledOnFirstLesson,
            "engagement_tier": engagementTier,
            "exit_reason": exitReason,
        ])
    }

    // MARK: - Quiz

    static func trackQuizStarted(course: Course) {
        track("quiz_started", [
            "course_id": course.id,
            "subject": course.subject.storageKey,
            "question_count": course.quiz.count,
        ])
    }

    static func trackQuizCompleted(course: Course, score: Int, total: Int) {
        track("quiz_completed", [
            "course_id": course.id,
            "score": score,
            "total": total,
            "passed": score == total,
        ])
    }

    // MARK: - Streak & gates

    static func trackStreakUpdated(streakDays: Int, isNewRecord: Bool) {
        track("streak_updated", [
            "streak_days": streakDays,
            "is_new_record": isNewRecord,
        ])
        Mixpanel.mainInstance().people.set(property: "streak_current", to: streakDays)
    }

    static func trackFreemiumGateHit(
        gateType: String,
        subject: Subject?,
        courseId: String?
    ) {
        var props: [String: MixpanelType] = ["gate_type": gateType]
        if let subject { props["subject"] = subject.storageKey }
        if let courseId { props["course_id"] = courseId }
        track("freemium_gate_hit", props)
    }

    static func trackLockedContentTapped(subject: Subject, surface: String) {
        track("locked_content_tapped", [
            "subject": subject.storageKey,
            "surface": surface,
        ])
    }

    // MARK: - Deep links

    static func trackDeepLinkOpened(courseId: String) {
        track("deep_link_opened", ["course_id": courseId])
    }

    // MARK: - Feedback

    static func trackFeedbackOpened() {
        track("feedback_opened")
    }

    static func trackFeedbackSubmitted(category: String) {
        track("feedback_submitted", ["category": category])
    }

    static func trackFeedbackFailed(category: String) {
        track("feedback_failed", ["category": category])
    }

    // MARK: - Helpers

    static func onboardingStepName(for index: Int) -> String {
        switch index {
        case 0: "welcome"
        case 1: "language"
        case 2: "objective"
        case 3: "right_place"
        case 4: "swipe_courses"
        case 5: "phone_time"
        case 6: "weeks_lost"
        case 7: "review"
        case 8: "loading"
        case 9: "login"
        case 10: "trial_steps"
        case 11: "reminder"
        case 12: "paywall_annual"
        case 13: "paywall_comparison"
        default: "unknown"
        }
    }

    static func engagementTier(
        durationSeconds: Int,
        lessonsReached: Int,
        lessonCount: Int,
        continueTaps: Int,
        scrolledOnFirstLesson: Bool,
        completed: Bool
    ) -> String {
        if completed { return "completed" }
        let progress = lessonCount > 0 ? Double(lessonsReached) / Double(lessonCount) : 0
        if durationSeconds < 8, lessonsReached <= 1, continueTaps == 0 {
            return "bounce"
        }
        if durationSeconds < 30, lessonsReached <= 1, !scrolledOnFirstLesson, continueTaps == 0 {
            return "peek"
        }
        if progress >= 0.75 || (durationSeconds > 90 && continueTaps >= 2) {
            return "read"
        }
        if durationSeconds > 30 || scrolledOnFirstLesson || lessonsReached > 1 {
            return "skim"
        }
        return "peek"
    }

    private static func track(_ event: String, _ properties: [String: MixpanelType] = [:]) {
        Mixpanel.mainInstance().track(event: event, properties: properties)
    }
}
