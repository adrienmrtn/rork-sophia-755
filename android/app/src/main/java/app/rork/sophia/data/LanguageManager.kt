package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.domain.AppLanguage
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class LanguageManager(context: Context) {
    private val prefs = context.getSharedPreferences("sophia_prefs", Context.MODE_PRIVATE)
    private val _current = MutableStateFlow(resolveInitial())
    val current: StateFlow<AppLanguage> = _current.asStateFlow()

    private fun resolveInitial(): AppLanguage {
        val stored = prefs.getString(AppLanguage.PREFS_KEY, null)
        if (stored != null) {
            val language = AppLanguage.fromCode(stored)
            if (language == AppLanguage.PORTUGUESE &&
                !prefs.getBoolean(AppLanguage.PORTUGUESE_SPLIT_KEY, false)
            ) {
                // A `pt` stored before the Brazilian and European editions split (see
                // PORTUGUESE_SPLIT_KEY): readers in Portugal move to the European edition, once.
                val resolved = if (AppLanguage.deviceWantsEuropeanPortuguese()) {
                    AppLanguage.PORTUGUESE_PORTUGAL
                } else {
                    language
                }
                prefs.edit()
                    .putString(AppLanguage.PREFS_KEY, resolved.code)
                    .putBoolean(AppLanguage.PORTUGUESE_SPLIT_KEY, true)
                    .apply()
                return resolved
            }
            return language
        }
        // First launch: detect device language and persist (parity with iOS).
        val detected = AppLanguage.preferredFromDevice()
        prefs.edit()
            .putString(AppLanguage.PREFS_KEY, detected.code)
            .putBoolean(AppLanguage.PORTUGUESE_SPLIT_KEY, true)
            .apply()
        return detected
    }

    fun setLanguage(language: AppLanguage) {
        prefs.edit()
            .putString(AppLanguage.PREFS_KEY, language.code)
            .putBoolean(AppLanguage.PORTUGUESE_SPLIT_KEY, true)
            .apply()
        ContentCatalog.clearCache()
        StringStore.clearCache()
        GlossaryStore.clearCache()
        LegalDocumentStore.clearCache()
        _current.value = language
    }
}
