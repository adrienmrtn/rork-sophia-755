package app.rork.sophia

import androidx.compose.ui.graphics.Color
import app.rork.sophia.domain.DuelHome
import app.rork.sophia.domain.DuelLeague
import app.rork.sophia.domain.DuelOpponent
import app.rork.sophia.domain.DuelProfile
import app.rork.sophia.ui.duels.DuelFormat
import app.rork.sophia.ui.duels.DuelPalette
import app.rork.sophia.ui.duels.duelColor
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Ce que l'accueil des duels calcule lui-même à partir de la réponse du serveur : la ligue
 * d'un nombre de trophées, la suivante, la jauge entre les deux, le taux de victoires, le
 * drapeau et l'initiale d'un adversaire. Les mêmes règles que `DuelModels.swift` : une
 * différence ici et la carte de ligue d'Android ne dirait pas la même chose que celle d'iOS.
 */
class DuelHomeTest {

    /** Les 30 ligues et leurs seuils (docs/duels.md), de la première à la dernière. */
    private val thresholds = listOf(
        "Aesop" to 0, "Homer" to 100, "Sappho" to 200, "Confucius" to 300, "Socrates" to 400,
        "Cleopatra" to 500, "Hypatia" to 650, "Avicenna" to 800, "Murasaki" to 950, "Mansa Musa" to 1100,
        "Dante" to 1300, "Joan of Arc" to 1500, "Gutenberg" to 1700, "Leonardo" to 1900, "Michelangelo" to 2100,
        "Copernicus" to 2350, "Shakespeare" to 2600, "Galileo" to 2850, "Vermeer" to 3100, "Newton" to 3400,
        "Mozart" to 3700, "Napoleon" to 4000, "Austen" to 4300, "Darwin" to 4650, "Lovelace" to 5000,
        "Van Gogh" to 5400, "Curie" to 5800, "Einstein" to 6200, "Kahlo" to 6600, "Sophia" to 7000,
    )

    private val leagues = thresholds.mapIndexed { index, (name, min) ->
        DuelLeague(
            position = index + 1,
            slug = name.lowercase().replace(' ', '_'),
            name = name,
            minTrophies = min,
            backgroundUrl = "",
            thumbUrl = "",
            accentHex = "#1A3A6B",
        )
    }

    private fun home(trophies: Int = 0, leagues: List<DuelLeague> = this.leagues) =
        DuelHome(profile = DuelProfile(trophies = trophies), leagues = leagues)

    // ------------------------------------------------------------ ligue d'un nombre de trophées

    @Test
    fun `zero trophies is the first league`() {
        assertEquals(1, home().league(0)?.position)
    }

    @Test
    fun `a threshold belongs to the league it opens`() {
        val home = home()
        assertEquals("Aesop", home.league(99)?.name)
        assertEquals("Homer", home.league(100)?.name)
        assertEquals("Homer", home.league(199)?.name)
        assertEquals("Hypatia", home.league(650)?.name)
        assertEquals("Kahlo", home.league(6999)?.name)
        assertEquals("Sophia", home.league(7000)?.name)
    }

    @Test
    fun `trophies above the last threshold stay in the last league`() {
        assertEquals(30, home().league(1_000_000)?.position)
    }

    @Test
    fun `negative trophies count as zero`() {
        val home = home()
        assertEquals(1, home.league(-1)?.position)
        assertEquals(1, home.league(-5000)?.position)
        assertEquals(1, home.league(Int.MIN_VALUE)?.position)
    }

    @Test
    fun `current league follows the profile trophies`() {
        assertEquals("Leonardo", home(trophies = 2000).currentLeague?.name)
        assertEquals("Aesop", home(trophies = -40).currentLeague?.name)
    }

    @Test
    fun `no league at all gives no league and no crash`() {
        val empty = home(trophies = 300, leagues = emptyList())
        assertNull(empty.league(300))
        assertNull(empty.currentLeague)
        assertNull(empty.nextLeague(null))
        assertEquals(0f, empty.leagueProgress(300), 0f)
    }

    @Test
    fun `a first league that starts above zero still holds the players below it`() {
        // Aucune ligue ne convient : la première sert de repli plutôt que rien.
        val shifted = home(leagues = leagues.map { it.copy(minTrophies = it.minTrophies + 50) })
        assertEquals(1, shifted.league(0)?.position)
        assertEquals(1, shifted.league(49)?.position)
    }

    @Test
    fun `league lookup by position`() {
        val home = home()
        assertEquals("Vermeer", home.leagueAt(19)?.name)
        assertNull(home.leagueAt(0))
        assertNull(home.leagueAt(31))
    }

    // ------------------------------------------------------------ ligue suivante

    @Test
    fun `next league is the following position`() {
        val home = home()
        assertEquals("Homer", home.nextLeague(home.league(0))?.name)
        assertEquals("Sophia", home.nextLeague(home.leagueAt(29))?.name)
    }

    @Test
    fun `the last league has no next league`() {
        val home = home()
        assertNull(home.nextLeague(home.leagueAt(30)))
        assertNull(home.nextLeague(null))
    }

    // ------------------------------------------------------------ jauge vers la ligue suivante

    @Test
    fun `progress is zero on a threshold and grows to the next one`() {
        val home = home()
        assertEquals(0f, home.leagueProgress(0), 0f)
        assertEquals(0.5f, home.leagueProgress(50), 1e-6f)
        assertEquals(0.99f, home.leagueProgress(99), 1e-6f)
        // Le seuil suivant ouvre une nouvelle ligue : la jauge repart de zéro.
        assertEquals(0f, home.leagueProgress(100), 0f)
        // Ligues plus larges en haut de la route : 500 → 650.
        assertEquals(0.5f, home.leagueProgress(575), 1e-6f)
        assertEquals(0f, home.leagueProgress(6600), 0f)
        assertEquals(0.75f, home.leagueProgress(6900), 1e-6f)
    }

    @Test
    fun `progress is full in the last league`() {
        val home = home()
        assertEquals(1f, home.leagueProgress(7000), 0f)
        assertEquals(1f, home.leagueProgress(9500), 0f)
    }

    @Test
    fun `progress never leaves the gauge`() {
        val home = home()
        assertEquals(0f, home.leagueProgress(-300), 0f)
        for (trophies in -200..7500 step 7) {
            val progress = home.leagueProgress(trophies)
            assertTrue("progress $progress for $trophies trophies", progress in 0f..1f)
        }
    }

    @Test
    fun `leagues sharing a threshold do not divide by zero`() {
        // Le serveur ne devrait pas renvoyer cela ; la jauge reste pleine plutôt que 0 / 0.
        val tied = home(
            leagues = listOf(leagues[1].copy(minTrophies = 100), leagues[0].copy(minTrophies = 100)),
        )
        assertEquals(1, tied.league(100)?.position)
        assertEquals(2, tied.nextLeague(tied.league(100))?.position)
        assertEquals(1f, tied.leagueProgress(100), 0f)
        assertEquals(1f, tied.leagueProgress(150), 0f)
    }

    // ------------------------------------------------------------ taux de victoires

    @Test
    fun `win rate is absent before the first duel`() {
        assertNull(DuelProfile().winRate)
    }

    @Test
    fun `win rate is a rounded percentage`() {
        assertEquals(0, DuelProfile(games = 4, wins = 0, losses = 4).winRate)
        assertEquals(100, DuelProfile(games = 7, wins = 7).winRate)
        assertEquals(50, DuelProfile(games = 2, wins = 1, losses = 1).winRate)
        assertEquals(33, DuelProfile(games = 3, wins = 1, losses = 2).winRate)
        assertEquals(67, DuelProfile(games = 3, wins = 2, losses = 1).winRate)
        // 12,5 % s'arrondit au-dessus, comme sur iOS.
        assertEquals(13, DuelProfile(games = 8, wins = 1, losses = 7).winRate)
    }

    // ------------------------------------------------------------ adversaire

    private fun flagOf(vararg letters: Char): String =
        letters.joinToString("") { String(Character.toChars(0x1F1E6 + (it - 'A'))) }

    @Test
    fun `flag is the pair of regional indicators of the country code`() {
        assertEquals(flagOf('F', 'R'), DuelOpponent(handle = "ada", countryCode = "FR").flag)
        assertEquals(flagOf('U', 'S'), DuelOpponent(handle = "ada", countryCode = "us").flag)
        assertEquals(flagOf('G', 'B'), DuelOpponent(handle = "ada", countryCode = "Gb").flag)
        // Deux caractères au sens des émojis : quatre unités UTF-16.
        assertEquals(4, DuelOpponent(handle = "ada", countryCode = "JP").flag.length)
        assertEquals(2, DuelOpponent(handle = "ada", countryCode = "JP").flag.codePointCount(0, 4))
    }

    @Test
    fun `no flag without a two letter code`() {
        assertEquals("", DuelOpponent(handle = "ada").flag)
        assertEquals("", DuelOpponent(handle = "ada", countryCode = "").flag)
        assertEquals("", DuelOpponent(handle = "ada", countryCode = "F").flag)
        assertEquals("", DuelOpponent(handle = "ada", countryCode = "FRA").flag)
        assertEquals("", DuelOpponent(handle = "ada", countryCode = "F1").flag)
        assertEquals("", DuelOpponent(handle = "ada", countryCode = "  ").flag)
    }

    @Test
    fun `the flag does not depend on the phone language`() {
        // En turc, « i » en majuscule devient « İ » : le code « it » ne donnerait plus de drapeau.
        val previous = java.util.Locale.getDefault()
        try {
            java.util.Locale.setDefault(java.util.Locale.forLanguageTag("tr-TR"))
            assertEquals(flagOf('I', 'T'), DuelOpponent(handle = "ada", countryCode = "it").flag)
            assertEquals("I", DuelOpponent(handle = "isaac").initial)
        } finally {
            java.util.Locale.setDefault(previous)
        }
    }

    @Test
    fun `initial is the first letter of the handle in capitals`() {
        assertEquals("A", DuelOpponent(handle = "ada").initial)
        assertEquals("Z", DuelOpponent(handle = "Zeno_of_elea").initial)
        assertEquals("7", DuelOpponent(handle = "7sages").initial)
        assertEquals("", DuelOpponent(handle = "").initial)
    }

    // ------------------------------------------------------------ couleurs et valeurs affichées

    @Test
    fun `league accent colour is read from its hex`() {
        assertEquals(Color(0xFF2C4768), duelColor("#2C4768"))
        assertEquals(Color(0xFFB2AEA1), duelColor("B2AEA1"))
        assertEquals(Color(0xFFAE8606), duelColor(" #ae8606 "))
        assertEquals(Color(0xFF000000), duelColor("#000000"))
        assertEquals(Color(0xFFFFFFFF), duelColor("#FFFFFF"))
    }

    @Test
    fun `an unreadable colour falls back to the brand navy`() {
        assertEquals(DuelPalette.navy, duelColor(null))
        assertEquals(DuelPalette.navy, duelColor(""))
        assertEquals(DuelPalette.navy, duelColor("#FFF"))
        assertEquals(DuelPalette.navy, duelColor("#12345G"))
        assertEquals(DuelPalette.navy, duelColor("#1A3A6B00"))
        assertEquals(Color(0xFF1A3A6B), DuelPalette.navy)
    }

    @Test
    fun `slider value is written with its unit`() {
        assertEquals("1492", DuelFormat.sliderValue(1492.0, "year"))
        assertEquals("1492", DuelFormat.sliderValue(1492.0, null))
        assertEquals("1492", DuelFormat.sliderValue(1492.0, ""))
        assertEquals("71 %", DuelFormat.sliderValue(71.0, "%"))
        assertEquals("206 bones", DuelFormat.sliderValue(206.0, "bones"))
        assertEquals("-12", DuelFormat.sliderValue(-12.0, null))
        assertEquals("0", DuelFormat.sliderValue(0.0, null))
    }

    @Test
    fun `slider value keeps one decimal only when it has one`() {
        assertEquals("2.4", DuelFormat.sliderValue(2.4, null))
        assertEquals("36.6 °C", DuelFormat.sliderValue(36.6, "°C"))
        assertEquals("9.8 %", DuelFormat.sliderValue(9.75, "%"))
        // Le point décimal ne suit pas la langue du téléphone.
        val previous = java.util.Locale.getDefault()
        try {
            java.util.Locale.setDefault(java.util.Locale.FRANCE)
            assertEquals("2.4", DuelFormat.sliderValue(2.4, null))
        } finally {
            java.util.Locale.setDefault(previous)
        }
    }
}
