package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.AppConfig
import com.mixpanel.android.mpmetrics.MixpanelAPI
import org.json.JSONArray
import org.json.JSONObject

class AnalyticsService(context: Context) {
    private val prefs = context.getSharedPreferences("sophia_prefs", Context.MODE_PRIVATE)
    private val mixpanel: MixpanelAPI? = runCatching {
        MixpanelAPI.getInstance(context, AppConfig.MIXPANEL_TOKEN, true).also {
            it.setServerURL("https://api-eu.mixpanel.com")
            it.registerSuperProperties(
                JSONObject()
                    .put("platform", "android")
                    .put("app_version", "1.0.0"),
            )
        }
    }.getOrNull()

    fun updateContext(language: String, isPremium: Boolean, onboardingCompleted: Boolean) {
        mixpanel?.registerSuperProperties(
            JSONObject()
                .put("language", language)
                .put("is_premium", isPremium)
                .put("onboarding_completed", onboardingCompleted),
        )
    }

    fun identify(userId: String) {
        mixpanel?.identify(userId)
    }

    fun track(event: String, props: Map<String, Any?> = emptyMap()) {
        val json = JSONObject()
        props.forEach { (k, v) ->
            when (v) {
                null -> Unit
                is Collection<*> -> json.put(k, JSONArray(v))
                else -> json.put(k, v)
            }
        }
        mixpanel?.track(event, json)
    }

    fun trackAppOpened(source: String = "cold") = track("app_opened", mapOf("source" to source))

    fun trackSessionIfNeeded(isPremium: Boolean) {
        val now = System.currentTimeMillis() / 1000.0
        val last = prefs.getFloat(KEY_LAST_SESSION, 0f).toDouble()
        if (now - last < 30 * 60) return
        val first = prefs.getFloat(KEY_FIRST_OPEN, 0f).toDouble().let {
            if (it <= 0) {
                prefs.edit().putFloat(KEY_FIRST_OPEN, now.toFloat()).apply()
                now
            } else it
        }
        prefs.edit().putFloat(KEY_LAST_SESSION, now.toFloat()).apply()
        val days = ((now - first) / 86400).toInt().coerceAtLeast(0)
        track("session_started", mapOf("days_since_install" to days, "is_premium" to isPremium))
    }

    fun trackOnboardingStarted() = track("onboarding_started")
    fun trackOnboardingStep(stepIndex: Int, stepName: String, action: String? = null) =
        track(
            "onboarding_step_viewed",
            mapOf("step_index" to stepIndex, "step_name" to stepName, "action" to action),
        )

    fun trackOnboardingCompleted(sawPaywall: Boolean, isPremium: Boolean) =
        track(
            "onboarding_completed",
            mapOf("saw_paywall" to sawPaywall, "is_premium_at_exit" to isPremium),
        )

    fun trackPaywallViewed(context: String, courseId: String? = null) =
        track("paywall_viewed", mapOf("context" to context, "trigger_course_id" to courseId))

    fun trackPaywallDismissed(context: String, durationSeconds: Int) =
        track("paywall_dismissed", mapOf("context" to context, "duration_seconds" to durationSeconds))

    fun trackDiscountOfferViewed(source: String) =
        track("discount_offer_viewed", mapOf("source" to source))

    fun trackPurchaseCompleted(context: String, offeringId: String? = null, packageId: String? = null) {
        track(
            "purchase_completed",
            mapOf("context" to context, "offering_id" to offeringId, "package_id" to packageId),
        )
        mixpanel?.people?.set("is_premium", true)
    }

    fun trackCourseOpened(courseId: String, subject: String, source: String, isFreeUser: Boolean) =
        track(
            "course_opened",
            mapOf(
                "course_id" to courseId,
                "subject" to subject,
                "source" to source,
                "is_free_user" to isFreeUser,
            ),
        )

    fun trackCourseCompleted(courseId: String, subject: String, lessonCount: Int, hasQuiz: Boolean) =
        track(
            "course_completed",
            mapOf(
                "course_id" to courseId,
                "subject" to subject,
                "lesson_count" to lessonCount,
                "has_quiz" to hasQuiz,
            ),
        )

    fun trackQuizStarted(courseId: String, subject: String, questionCount: Int) =
        track(
            "quiz_started",
            mapOf("course_id" to courseId, "subject" to subject, "question_count" to questionCount),
        )

    fun trackQuizCompleted(courseId: String, score: Int, total: Int, passed: Boolean) =
        track(
            "quiz_completed",
            mapOf("course_id" to courseId, "score" to score, "total" to total, "passed" to passed),
        )

    fun trackStreakUpdated(streakDays: Int, isNewRecord: Boolean) {
        track("streak_updated", mapOf("streak_days" to streakDays, "is_new_record" to isNewRecord))
        mixpanel?.people?.set("streak_current", streakDays)
    }

    fun trackFreemiumGateHit(gateType: String, subject: String? = null, courseId: String? = null) =
        track(
            "freemium_gate_hit",
            mapOf("gate_type" to gateType, "subject" to subject, "course_id" to courseId),
        )

    fun trackDeepLinkOpened(courseId: String) =
        track("deep_link_opened", mapOf("course_id" to courseId))

    fun trackFeedbackOpened() = track("feedback_opened")
    fun trackFeedbackSubmitted(category: String) =
        track("feedback_submitted", mapOf("category" to category))

    fun trackFeedbackFailed(category: String) =
        track("feedback_failed", mapOf("category" to category))

    fun trackCourseSessionEnded(
        courseId: String,
        subject: String,
        lessonIndex: Int,
        lessonCount: Int,
        completed: Boolean,
    ) = track(
        "course_session_ended",
        mapOf(
            "course_id" to courseId,
            "subject" to subject,
            "lesson_index" to lessonIndex,
            "lesson_count" to lessonCount,
            "completed" to completed,
        ),
    )

    fun trackLockedContentTapped(gateType: String, courseId: String?, subject: String?) =
        track(
            "locked_content_tapped",
            mapOf("gate_type" to gateType, "course_id" to courseId, "subject" to subject),
        )

    fun trackAmbassadorOpened() = track("ambassador_opened")
    fun trackAmbassadorSubmitted() = track("ambassador_submitted")

    fun trackCollectionProgressed(collectionId: String, completed: Int, total: Int, isComplete: Boolean) =
        track(
            "collection_progressed",
            mapOf(
                "collection_id" to collectionId,
                "completed_count" to completed,
                "total_count" to total,
                "is_complete" to isComplete,
            ),
        )

    companion object {
        private const val KEY_LAST_SESSION = "sophia_analytics_last_session"
        private const val KEY_FIRST_OPEN = "sophia_analytics_first_open"
    }
}
