package app.rork.sophia

import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.domain.locale
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.util.Locale

/**
 * Portuguese ships as two editions: `pt` (Brazil) and `pt-PT` (Portugal). A phone set to
 * Portuguese must land on the right one, and a bare `pt` is the Brazilian one, as it is
 * for Apple and Google.
 */
class AppLanguageTest {

    private fun device(tag: String) = AppLanguage.match(Locale.forLanguageTag(tag))

    @Test
    fun `phones in Portugal and the European-norm countries get the European edition`() {
        for (tag in listOf("pt-PT", "pt-AO", "pt-MZ", "pt-CV", "pt-GW", "pt-ST", "pt-TL", "pt-MO", "pt-LU")) {
            assertEquals(tag, AppLanguage.PORTUGUESE_PORTUGAL, device(tag))
        }
    }

    @Test
    fun `Brazil and a bare pt get the Brazilian edition`() {
        assertEquals(AppLanguage.PORTUGUESE, device("pt-BR"))
        assertEquals(AppLanguage.PORTUGUESE, device("pt"))
    }

    @Test
    fun `other languages still resolve, aliases included`() {
        assertEquals(AppLanguage.FRENCH, device("fr-FR"))
        assertEquals(AppLanguage.NORWEGIAN, device("nn-NO"))
        assertEquals(AppLanguage.CROATIAN, device("bs-BA"))
        assertNull(device("ja-JP"))
    }

    @Test
    fun `stored codes round-trip`() {
        assertEquals(AppLanguage.PORTUGUESE_PORTUGAL, AppLanguage.fromCode("pt-PT"))
        assertEquals(AppLanguage.PORTUGUESE, AppLanguage.fromCode("pt"))
        for (language in AppLanguage.entries) {
            assertEquals(language, AppLanguage.fromCode(language.code))
        }
    }

    @Test
    fun `each edition formats with its own region`() {
        assertEquals("BR", AppLanguage.PORTUGUESE.locale.country)
        assertEquals("PT", AppLanguage.PORTUGUESE_PORTUGAL.locale.country)
        assertEquals("pt", AppLanguage.PORTUGUESE_PORTUGAL.locale.language)
    }
}
