package app.rork.sophia.data

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import app.rork.sophia.MainActivity
import app.rork.sophia.R
import app.rork.sophia.domain.AppLanguage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.Date
import java.util.concurrent.TimeUnit
import kotlin.math.abs

/**
 * One local reminder, fired 10 hours before the free trial ends.
 *
 * The copy talks about a course to discover rather than about billing. A "your trial ends
 * tomorrow" push reads as a dunning message and gets swiped away; a course nudge brings the
 * user back into the app, which is where they actually decide whether to keep Premium.
 *
 * Scheduling uses an inexact alarm on purpose: a reminder aimed 10 hours ahead does not care
 * about a few minutes of Doze slack, and staying inexact keeps the app clear of the
 * SCHEDULE_EXACT_ALARM permission and its Play Console declaration.
 */
object TrialReminderScheduler {
    const val CHANNEL_ID = "sophia_trial_reminders"
    internal const val ACTION = "app.rork.sophia.TRIAL_REMINDER"
    private const val NOTIFICATION_ID = 7101
    private const val REQUEST_CODE = 7101
    private const val PREFS = "sophia_prefs"
    private const val KEY_TRIGGER_AT = "sophia_trial_reminder_at"

    /** How long before the end of the trial the reminder lands. */
    private val LEAD_MILLIS = TimeUnit.HOURS.toMillis(10)

    /**
     * Store trials are 3 days. Only used until RevenueCat reports the real expiry, which
     * normally lands moments after the purchase but is not guaranteed to be there yet.
     */
    private val ASSUMED_TRIAL_MILLIS = TimeUnit.DAYS.toMillis(3)

    /** Small drift between two RevenueCat reads must not re-arm the alarm every time. */
    private val RESCHEDULE_TOLERANCE_MILLIS = TimeUnit.MINUTES.toMillis(5)

    /**
     * Per-process, not persisted: a new process is exactly when re-arming is worth doing,
     * since the system drops pending alarms on reboot.
     */
    @Volatile
    private var armedAt: Long = 0L

    /** Reads a string asset, so keep it off the main thread. */
    fun ensureChannel(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        val language = persistedLanguage(context)
        val channel = NotificationChannel(
            CHANNEL_ID,
            StringStore.text(context, "notification.channel.name", language),
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = StringStore.text(context, "notification.channel.description", language)
        }
        manager.createNotificationChannel(channel)
    }

    /**
     * Arms the reminder for [trialEndsAt] minus 10 hours, assuming a 3-day trial when the
     * real end date is not known yet. Safe to call repeatedly: the alarm is replaced, never
     * duplicated, and an unchanged target is skipped.
     */
    fun scheduleTrialEndingReminder(context: Context, trialEndsAt: Date? = null) {
        // A user who refused notifications must see nothing change, and arming an alarm whose
        // notification the system would drop achieves nothing either way.
        if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) return
        val endsAt = trialEndsAt?.time ?: (System.currentTimeMillis() + ASSUMED_TRIAL_MILLIS)
        val triggerAt = endsAt - LEAD_MILLIS
        // Trials shorter than the lead time, or discovered too late, leave no window.
        if (triggerAt <= System.currentTimeMillis()) return
        if (armedAt != 0L && abs(armedAt - triggerAt) <= RESCHEDULE_TOLERANCE_MILLIS) return
        val alarm = context.getSystemService(AlarmManager::class.java) ?: return
        val pending = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            Intent(context, TrialReminderReceiver::class.java).setAction(ACTION),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        runCatching {
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pending)
        }.onSuccess {
            armedAt = triggerAt
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putLong(KEY_TRIGGER_AT, triggerAt)
                .apply()
        }
    }

    /** Reads a catalog asset to pick the featured course, so keep it off the main thread. */
    fun showReminderNotification(context: Context) {
        ensureChannel(context)
        val language = persistedLanguage(context)
        val course = runCatching {
            ContentCatalog.summaries(context, language).randomOrNull()
        }.getOrNull()
        val body = if (course != null) {
            StringStore.text(context, "notification.courseNudge.body", language, course.title)
        } else {
            StringStore.text(context, "notification.courseNudge.bodyFallback", language)
        }
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(StringStore.text(context, "notification.courseNudge.title", language))
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(openAppIntent(context, course?.id))
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()
        runCatching {
            NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
        }
        armedAt = 0L
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .remove(KEY_TRIGGER_AT)
            .apply()
    }

    /** Opens the course the copy promised, falling back to the app when none was resolved. */
    private fun openAppIntent(context: Context, courseId: String?): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (courseId != null) {
                action = Intent.ACTION_VIEW
                data = Uri.parse("sophia://course/$courseId")
            }
        }
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun persistedLanguage(context: Context): AppLanguage {
        val stored = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(AppLanguage.PREFS_KEY, null)
        return AppLanguage.fromCode(stored)
    }
}

class TrialReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != TrialReminderScheduler.ACTION) return
        // Resolving the featured course parses a catalog asset, which must not run on the
        // main thread; goAsync keeps the broadcast alive while that happens.
        val result = goAsync()
        val appContext = context.applicationContext
        CoroutineScope(Dispatchers.IO).launch {
            try {
                TrialReminderScheduler.showReminderNotification(appContext)
            } finally {
                result.finish()
            }
        }
    }
}
