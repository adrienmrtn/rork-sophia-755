package app.rork.sophia.ui.theme

import android.content.Context
import android.content.res.Configuration
import androidx.compose.runtime.Composable
import androidx.compose.runtime.RememberObserver
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue

/**
 * User-chosen appearance, as on iOS: light by default, Night, or Automatic (the phone's
 * mode). The factory default stays light until the reader picks something else.
 */
enum class AppearancePreference(val storageKey: String, val labelKey: String) {
    LIGHT("light", "settings.appearance.light"),
    DARK("dark", "settings.appearance.dark"),
    SYSTEM("system", "settings.appearance.automatic"),
}

/**
 * Whether the app draws dark right now. [DS] reads [isDark] on every colour, and the
 * reads are snapshot state, so every screen redraws when the preference, the phone's mode
 * or a forced-light screen changes it.
 */
object SophiaAppearance {
    private const val PREFS = "sophia_appearance"
    private const val KEY_PREFERENCE = "preference"

    var preference by mutableStateOf(AppearancePreference.LIGHT)
        private set

    /** The phone's own mode, kept current by [SophiaTheme] for Automatic. */
    internal var systemDark by mutableStateOf(false)

    /**
     * A screen paints a dark backdrop behind the system bars (the flash-offer gradient), so
     * their icons must be light whatever the appearance. Read by [SophiaTheme], which owns
     * the bar icons; setting the window directly lost to the theme on the next recomposition.
     */
    var darkBackdropBehindBars by mutableStateOf(false)

    /** Screens on screen that are designed light-only (onboarding, paywalls), as on iOS. */
    private var forcedLightScreens by mutableIntStateOf(0)

    val isDark: Boolean
        get() = forcedLightScreens == 0 &&
            (preference == AppearancePreference.DARK || (preference == AppearancePreference.SYSTEM && systemDark))

    /** Read once at launch, before the first frame, so a dark reader never sees a light flash. */
    fun load(context: Context) {
        val stored = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY_PREFERENCE, null)
        preference = AppearancePreference.entries.firstOrNull { it.storageKey == stored } ?: AppearancePreference.LIGHT
        systemDark = isSystemDark(context)
    }

    fun setPreference(context: Context, value: AppearancePreference) {
        if (preference == value) return
        preference = value
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY_PREFERENCE, value.storageKey).apply()
    }

    fun isSystemDark(context: Context): Boolean =
        (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

    internal fun pushForcedLight() {
        forcedLightScreens += 1
    }

    internal fun popForcedLight() {
        forcedLightScreens = (forcedLightScreens - 1).coerceAtLeast(0)
    }
}

/**
 * Keeps the app light while the calling screen is in the composition. Counted from the
 * moment the screen is composed (not after it, as an effect would), so the screen's own
 * first frame is already light; the tabs behind it turn light too, unseen.
 */
@Composable
fun ForceLightAppearance() {
    remember { ForcedLightToken() }
}

private class ForcedLightToken : RememberObserver {
    private var active = true

    init {
        SophiaAppearance.pushForcedLight()
    }

    private fun release() {
        if (!active) return
        active = false
        SophiaAppearance.popForcedLight()
    }

    override fun onRemembered() = Unit
    override fun onForgotten() = release()
    override fun onAbandoned() = release()
}
