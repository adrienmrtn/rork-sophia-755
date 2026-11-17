package app.rork.sophia

import app.rork.sophia.data.DiscountBucket
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class DiscountBucketTest {
    private val known = setOf("offre_discount", "offre_discount_2999", "offre_discount_b")
    private fun pick(named: String?, bucket: String, offerings: Set<String> = known): String? =
        DiscountBucket.promoOfferingIdentifier(named, bucket) { it in offerings }

    @Test
    fun withoutANameTheBucketDecides() {
        assertEquals("offre_discount", pick(null, DiscountBucket.A))
        assertEquals("offre_discount_2999", pick("", DiscountBucket.B))
        assertEquals("offre_discount_2999", pick("  ", DiscountBucket.B))
    }

    @Test
    fun bucketFallsBackToTheFirstOfferingWhileItsOwnIsMissing() {
        assertEquals("offre_discount", pick(null, DiscountBucket.B, setOf("offre_discount")))
        assertNull(pick(null, DiscountBucket.A, emptySet()))
    }

    @Test
    fun theOfferingNamedByTheCurrentOneWinsOverTheBucket() {
        assertEquals("offre_discount_b", pick("offre_discount_b", DiscountBucket.A))
        assertEquals("offre_discount_b", pick(" offre_discount_b ", DiscountBucket.B))
    }

    @Test
    fun noneMeansNoFlashOffer() {
        assertNull(pick("none", DiscountBucket.A))
        assertNull(pick("NONE", DiscountBucket.B))
    }

    /** Never the bucket's offering instead: it was cut for another regular price. */
    @Test
    fun aNamedOfferingThatDoesNotExistMeansNoFlashOffer() {
        assertNull(pick("offre_discount_c", DiscountBucket.A))
    }
}
