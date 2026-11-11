package app.rork.sophia

import app.rork.sophia.ui.duels.DuelImageTrim
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class DuelImageTrimTest {
    private val paper = (0xFF shl 24) or (232 shl 16) or (228 shl 8) or 218
    private val shade = (0xFF shl 24) or (186 shl 16) or (182 shl 8) or 174
    private val red = (0xFF shl 24) or (200 shl 16) or (30 shl 8) or 40

    private fun image(width: Int, height: Int, fill: (Int, Int) -> Int): IntArray =
        IntArray(width * height) { fill(it % width, it / width) }

    @Test
    fun paperIsRecognisedEvenInTheShadow() {
        assertTrue(DuelImageTrim.isPaper(232, 228, 218))
        assertTrue(DuelImageTrim.isPaper(186, 182, 174))
        assertFalse(DuelImageTrim.isPaper(255, 255, 255))
        assertFalse(DuelImageTrim.isPaper(200, 30, 40))
        assertFalse(DuelImageTrim.isPaper(90, 88, 84))
    }

    @Test
    fun aFlagOnItsMarginIsBoxed() {
        // Un drapeau de 60 × 30 posé en (20, 35) dans une image 100 × 100, avec une ombre dessous.
        val pixels = image(100, 100) { x, y ->
            when {
                x in 20..79 && y in 35..64 -> red
                x in 22..81 && y in 65..67 -> shade
                else -> paper
            }
        }
        assertArrayEquals(intArrayOf(20, 35, 79, 64), DuelImageTrim.bounds(pixels, 100, 100))
    }

    @Test
    fun anImageThatFillsItsFrameIsLeftAlone() {
        assertNull(DuelImageTrim.bounds(image(100, 100) { _, _ -> red }, 100, 100))
        assertNull(DuelImageTrim.bounds(image(100, 100) { _, _ -> paper }, 100, 100))
    }

    @Test
    fun onlyATrimmedImageIsFlat() {
        assertFalse(DuelImageTrim.isFlat(640f, 800f))
        assertTrue(DuelImageTrim.isFlat(600f, 400f))
        assertFalse(DuelImageTrim.isFlat(0f, 0f))
    }
}
