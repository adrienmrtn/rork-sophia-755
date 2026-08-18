package app.rork.sophia.data

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import app.rork.sophia.MainActivity
import app.rork.sophia.R

object TrialReminderScheduler {
    const val CHANNEL_ID = "sophia_trial_reminders"
    private const val NOTIFICATION_ID = 7101
    private const val REQUEST_CODE = 7101
    private const val ACTION = "app.rork.sophia.TRIAL_REMINDER"

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Sophia",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Rappels d'essai Premium"
        }
        manager.createNotificationChannel(channel)
    }

    /**
     * Schedule a reminder ~2 days after now (day before 3-day trial ends).
     *
     * Nothing in the app asks for POST_NOTIFICATIONS, so on API 33+ the reminder only
     * exists for users who allowed notifications from system settings. Setting an alarm
     * whose notification would be dropped is pointless, so check first.
     */
    fun scheduleTrialEndingReminder(context: Context) {
        if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) return
        ensureChannel(context)
        val alarm = context.getSystemService(AlarmManager::class.java) ?: return
        val intent = Intent(context, TrialReminderReceiver::class.java).setAction(ACTION)
        val pending = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val triggerAt = System.currentTimeMillis() + 2L * 24L * 60L * 60L * 1000L
        runCatching {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pending)
            } else {
                alarm.set(AlarmManager.RTC_WAKEUP, triggerAt, pending)
            }
        }
        context.getSharedPreferences("sophia_prefs", Context.MODE_PRIVATE)
            .edit()
            .putLong("sophia_trial_reminder_at", triggerAt)
            .apply()
    }

    fun showReminderNotification(context: Context) {
        ensureChannel(context)
        val open = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Ton essai Sophia se termine demain")
            .setContentText("Continue à apprendre — ou annule en quelques secondes.")
            .setContentIntent(open)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()
        runCatching {
            NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
        }
    }
}

class TrialReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != "app.rork.sophia.TRIAL_REMINDER") return
        TrialReminderScheduler.showReminderNotification(context)
    }
}
