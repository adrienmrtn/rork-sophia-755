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

    /**
     * Metadata key an offering carries in RevenueCat to name the flash offering that goes
     * with it: `{"promo_offering": "offre_discount_b"}`, or `{"promo_offering": "none"}` for
     * no flash offer at all. Set on the offerings of a price experiment, so each arm gets a
     * discount measured against its own price rather than the one cut for the regular price.
     */
    const val METADATA_KEY = "promo_offering"
    const val NO_PROMO = "none"

    /**
     * The flash offering to sell, or null for none.
     *
     * [named] is what the offering RevenueCat currently serves says under [METADATA_KEY]. When
     * it names an offering, that one wins over the install's bucket; if it does not exist the
     * answer is no flash offer, never the bucket's: falling back would sell a discount cut for
     * another price. Without a name the bucket decides, as before.
     */
    fun promoOfferingIdentifier(named: String?, bucket: String, exists: (String) -> Boolean): String? {
        val name = named?.trim().orEmpty()
        if (name.equals(NO_PROMO, ignoreCase = true)) return null
        if (name.isNotEmpty()) return name.takeIf(exists)
        return offeringIdentifier(bucket).takeIf(exists) ?: offeringIdentifier(A).takeIf(exists)
    }
}
