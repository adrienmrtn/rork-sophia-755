package app.rork.sophia

import app.rork.sophia.data.PaywallExperiment
import app.rork.sophia.data.PaywallExperiment.Config
import app.rork.sophia.data.PaywallExperiment.Variant
import java.util.Random
import java.util.UUID
import kotlin.math.abs
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PaywallExperimentTest {
    private val zero = "00000000-0000-0000-0000-000000000000"

    /** The frozen reference shared with iOS: SHA-256 starts `4304fee0`, so u = 0x4304fee0 / 2^32. */
    @Test
    fun referenceValueIsFrozen() {
        assertEquals(0x4304fee0L.toDouble() / 4294967296.0, PaywallExperiment.unitInterval(zero), 0.0)
        assertEquals(0.2617949768900871, PaywallExperiment.unitInterval(zero), 1e-15)
        assertEquals(Variant.REVIEWS, PaywallExperiment.variant(zero, Config(shareReviews = 0.5)))
        assertEquals(Variant.BONHOMME, PaywallExperiment.variant(zero, Config(shareReviews = 0.25)))
    }

    /** iOS writes its UUIDs in capitals: the draw must not depend on the case. */
    @Test
    fun drawIgnoresTheCaseOfTheIdentifier() {
        val id = "3F2504E0-4F89-41D3-9A0C-0305E82C3301"
        assertEquals(PaywallExperiment.unitInterval(id.lowercase()), PaywallExperiment.unitInterval(id), 0.0)
    }

    @Test
    fun sameInstallAlwaysGetsTheSameVariant() {
        val config = Config()
        repeat(200) {
            val id = UUID.randomUUID().toString()
            val first = PaywallExperiment.variant(id, config)
            repeat(5) { assertEquals(first, PaywallExperiment.variant(id, config)) }
        }
    }

    @Test
    fun splitFollowsShareReviews() {
        val random = Random(42)
        val ids = List(10_000) { UUID(random.nextLong(), random.nextLong()).toString() }
        for (share in listOf(0.5, 0.2, 0.9)) {
            val reviews = ids.count { PaywallExperiment.variant(it, Config(shareReviews = share)) == Variant.REVIEWS }
            assertTrue("share $share gave $reviews", abs(reviews / 10_000.0 - share) < 0.03)
        }
        assertTrue(ids.none { PaywallExperiment.variant(it, Config(shareReviews = 0.0)) == Variant.REVIEWS })
        assertTrue(ids.all { PaywallExperiment.variant(it, Config(shareReviews = 1.0)) == Variant.REVIEWS })
    }

    @Test
    fun stoppedTestServesTheDefaultVariant() {
        assertEquals(Variant.BONHOMME, PaywallExperiment.variant(zero, Config(enabled = false, shareReviews = 1.0)))
        assertEquals(
            Variant.REVIEWS,
            PaywallExperiment.variant(zero, Config(enabled = false, shareReviews = 0.0, defaultVariant = Variant.REVIEWS)),
        )
    }

    @Test
    fun settingIsReadLeniently() {
        assertEquals(Config(), PaywallExperiment.parseValue("""{"enabled": true, "share_reviews": 0.5}"""))
        assertEquals(Config(), PaywallExperiment.parseValue("{}"))
        assertEquals(
            Config(enabled = false, shareReviews = 0.3, defaultVariant = Variant.REVIEWS),
            PaywallExperiment.parseValue("""{"enabled": false, "share_reviews": 0.3, "default_variant": "reviews"}"""),
        )
        assertEquals(1.0, PaywallExperiment.parseValue("""{"share_reviews": 7}""")!!.shareReviews, 0.0)
        assertNull(PaywallExperiment.parseValue("""{"default_variant": "other"}""")!!.defaultVariant)
        assertNull(PaywallExperiment.parseValue("not json"))
        assertNull(PaywallExperiment.parseValue("[1, 2]"))
    }
}
