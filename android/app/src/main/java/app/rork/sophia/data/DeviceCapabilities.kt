package app.rork.sophia.data

import android.app.ActivityManager
import android.content.Context
import android.os.Build

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

    fun analyticsProps(context: Context): Map<String, Any?> = mapOf(
        "low_ram" to isLowRam(context),
        "memory_class_mb" to memoryClassMb(context),
        "model" to Build.MODEL,
        "manufacturer" to Build.MANUFACTURER,
        "release" to Build.VERSION.RELEASE,
        "sdk" to Build.VERSION.SDK_INT,
    )
}
