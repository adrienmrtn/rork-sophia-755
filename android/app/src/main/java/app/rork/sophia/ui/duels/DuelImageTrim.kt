package app.rork.sophia.ui.duels

import android.graphics.Bitmap
import coil.size.Size
import coil.transform.Transformation
import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * Les drapeaux hébergés sont des fichiers 640 × 800 où le drapeau est posé sur une marge beige
 * (« papier », cuite dans l'image par scripts/duels_images.py) : affichés tels quels, ils gardent
 * ce fond beige derrière eux, en clair comme en sombre. On ne peut pas réécrire les fichiers ;
 * l'app rogne donc la marge et ne garde que le drapeau, posé à même la page. Une image sans cette
 * marge (portrait, tableau, monument) ressort inchangée. Même règle que `DuelImageTrimmer` sur iOS.
 */
internal object DuelImageTrim {
    /** La largeur de la copie réduite où les bords sont cherchés (à deux points près). */
    const val SCAN_WIDTH = 320

    /** La couleur de la marge (232, 228, 218), ou la même assombrie par l'ombre portée du drapeau. */
    fun isPaper(red: Int, green: Int, blue: Int): Boolean {
        val level = red / 232.0
        if (level < 0.55 || level > 1.06) return false
        return abs(green / 228.0 - level) < 0.035 && abs(blue / 218.0 - level) < 0.045
    }

    /**
     * Le cadre du drapeau dans une image [width] × [height] (pixels ARGB) : `[gauche, haut,
     * droite, bas]`, bords inclus. `null` si le pourtour n'est pas de la marge (l'image occupe
     * tout son cadre : rien à rogner).
     */
    fun bounds(pixels: IntArray, width: Int, height: Int): IntArray? {
        if (width < 8 || height < 8 || pixels.size < width * height) return null
        var ring = 0
        var ringPaper = 0
        val rows = IntArray(height)
        val columns = IntArray(width)
        for (y in 0 until height) {
            for (x in 0 until width) {
                val pixel = pixels[y * width + x]
                val paper = isPaper((pixel shr 16) and 0xFF, (pixel shr 8) and 0xFF, pixel and 0xFF)
                if (y < 2 || y >= height - 2 || x < 2 || x >= width - 2) {
                    ring++
                    if (paper) ringPaper++
                }
                if (!paper) {
                    rows[y]++
                    columns[x]++
                }
            }
        }
        if (ring == 0 || ringPaper.toDouble() / ring < 0.97) return null

        // Le drapeau : les lignes et les colonnes nettement hors marge (l'ombre n'en fait pas partie).
        val rowFloor = (rows.maxOrNull() ?: 0) * 0.4
        val columnFloor = (columns.maxOrNull() ?: 0) * 0.4
        if (rowFloor <= 0 || columnFloor <= 0) return null
        val top = rows.indexOfFirst { it >= rowFloor }
        val bottom = rows.indexOfLast { it >= rowFloor }
        val left = columns.indexOfFirst { it >= columnFloor }
        val right = columns.indexOfLast { it >= columnFloor }
        if (top < 0 || left < 0 || bottom <= top || right <= left) return null
        return intArrayOf(left, top, right, bottom)
    }

    /** Vrai pour une image rognée (un drapeau) : elle n'a plus les proportions 4:5 des fichiers. */
    fun isFlat(width: Float, height: Float): Boolean =
        width > 0f && height > 0f && abs(width / height - 0.8f) > 0.03f
}

/** Rogne la marge beige d'une image de question (un drapeau) ; laisse les autres telles quelles. */
internal class DuelTrimTransformation : Transformation {
    override val cacheKey: String = "duelTrim-v1"

    override suspend fun transform(input: Bitmap, size: Size): Bitmap {
        if (input.width < 64 || input.height < 64) return input
        val width = DuelImageTrim.SCAN_WIDTH
        val height = maxOf((input.height.toDouble() / input.width * width).roundToInt(), 1)
        val small = Bitmap.createScaledBitmap(input, width, height, true)
        val pixels = IntArray(width * height)
        small.getPixels(pixels, 0, width, 0, 0, width, height)
        if (small !== input) small.recycle()
        val box = DuelImageTrim.bounds(pixels, width, height) ?: return input

        // Retour aux points du fichier, trois de moins de chaque côté : le filet noir du bord part avec.
        val scaleX = input.width.toDouble() / width
        val scaleY = input.height.toDouble() / height
        val inset = 3.0
        val left = (box[0] * scaleX + inset).roundToInt().coerceIn(0, input.width - 1)
        val top = (box[1] * scaleY + inset).roundToInt().coerceIn(0, input.height - 1)
        val cropWidth = ((box[2] + 1 - box[0]) * scaleX - inset * 2).roundToInt().coerceAtMost(input.width - left)
        val cropHeight = ((box[3] + 1 - box[1]) * scaleY - inset * 2).roundToInt().coerceAtMost(input.height - top)
        if (cropWidth < input.width * 0.3 || cropHeight < input.height * 0.12) return input
        return Bitmap.createBitmap(input, left, top, cropWidth, cropHeight)
    }
}
