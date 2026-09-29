package app.rork.sophia.audio

import android.app.PendingIntent
import android.content.Intent
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService

/**
 * Hosts the media session around [CourseAudioPlayer]'s ExoPlayer. Media3 turns it into a
 * foreground service with the media notification while a narration plays, which is what
 * keeps it going with the screen off and puts the controls on the lock screen.
 */
class CourseAudioService : MediaSessionService() {
    private var session: MediaSession? = null

    override fun onCreate() {
        super.onCreate()
        val openApp = packageManager.getLaunchIntentForPackage(packageName)?.let { intent ->
            PendingIntent.getActivity(
                this,
                0,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        }
        session = MediaSession.Builder(this, CourseAudioPlayer.player(this))
            .apply { openApp?.let(::setSessionActivity) }
            .build()
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaSession? = session

    /** Swiped away from recents: keep playing if it plays, otherwise go. */
    override fun onTaskRemoved(rootIntent: Intent?) {
        val player = session?.player
        if (player == null || !player.playWhenReady || player.mediaItemCount == 0) {
            stopSelf()
        }
    }

    override fun onDestroy() {
        // The player belongs to CourseAudioPlayer and outlives the service.
        session?.release()
        session = null
        super.onDestroy()
    }
}
