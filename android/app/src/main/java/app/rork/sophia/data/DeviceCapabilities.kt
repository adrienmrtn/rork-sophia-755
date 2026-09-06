package app.rork.sophia.data

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import app.rork.sophia.BuildConfig

/**
 * Runtime profile for the phone actually running the app.
 *
 * Target device (user): Xiaomi Redmi A5 — Android 15 Go, Unisoc T7250 (12 nm),
 * Mali-G57 MP1, 3 or 4 GB LPDDR4X, eMMC 5.1, 720×1640 @ 120 Hz.
 * Android Go sets [ActivityManager.isLowRamDevice] = true.
 */
object DeviceCapabilities {
    @Volatile
    private var lowRam: Boolean? = null

    @Volatile
    private var memoryClassMb: Int = -1

    fun isLowRam(context: Context): Boolean {
        lowRam?.let { return it }
        val am = context.applicationContext.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        memoryClassMb = am.memoryClass
        val value = am.isLowRamDevice || am.memoryClass <= 192
        lowRam = value
        return value
    }

    fun memoryClassMb(context: Context): Int {
        if (memoryClassMb < 0) isLowRam(context)
        return memoryClassMb
    }

    fun isEmulator(): Boolean {
        val hardware = Build.HARDWARE
        val fingerprint = Build.FINGERPRINT
        val product = Build.PRODUCT
        val model = Build.MODEL
        return hardware.contains("ranchu", ignoreCase = true) ||
            hardware.contains("goldfish", ignoreCase = true) ||
            fingerprint.startsWith("generic") ||
            fingerprint.contains("emulator", ignoreCase = true) ||
            product.contains("sdk", ignoreCase = true) ||
            model.contains("sdk", ignoreCase = true) ||
            model.contains("Emulator", ignoreCase = true)
    }

    /** Go phones + AVD/ranchu: skip Coil and heavy overlays. */
    fun isConstrained(context: Context): Boolean = isLowRam(context) || isEmulator()

    /**
     * Login bypass for local QA. `BuildConfig.DEBUG` is compile-time false in release,
     * so R8 strips the true branch from Play builds; [isEmulator] also keeps it off
     * a physical phone running a debug APK.
     */
    fun allowsLoginBypass(): Boolean = BuildConfig.DEBUG && isEmulator()

    fun analyticsProps(context: Context): Map<String, Any?> = mapOf(
        "low_ram" to isLowRam(context),
        "emulator" to isEmulator(),
        "memory_class_mb" to memoryClassMb(context),
        "model" to Build.MODEL,
        "hardware" to Build.HARDWARE,
        "manufacturer" to Build.MANUFACTURER,
        "release" to Build.VERSION.RELEASE,
        "sdk" to Build.VERSION.SDK_INT,
    )
}
