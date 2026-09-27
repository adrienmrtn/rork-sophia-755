package app.rork.sophia.data

import android.content.Context
import kotlin.random.Random

/**
 * Which flash-discount offering this install sees. Drawn once at random, kept for the life of
 * the install, and reported to RevenueCat as the `discount_bucket` subscriber attribute so
 * revenue and conversion split by bucket in the charts. It lives in the app rather than in a
 * RevenueCat experiment because a customer can only be in one experiment at a time, and every
 * new customer is already in a price experiment on the onboarding paywall.
 */
object DiscountBucket {
    const val A = "A"
    const val B = "B"
    private const val PREFS = "sophia_prefs"
    private const val KEY = "sophia_discount_bucket"

    fun get(context: Context): String {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        prefs.getString(KEY, null)?.takeIf { it == A || it == B }?.let { return it }
        val drawn = if (Random.nextBoolean()) A else B
        prefs.edit().putString(KEY, drawn).apply()
        return drawn
    }

    /** Offering this bucket sells; bucket A keeps today's `offre_discount`. */
    fun offeringIdentifier(bucket: String): String =
        if (bucket == B) "offre_discount_2999" else "offre_discount"
}
