package app.rork.sophia.data

import android.content.Context
import app.rork.sophia.domain.AppLanguage
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class LanguageManager(context: Context) {
    private val prefs = context.getSharedPreferences("sophia_prefs", Context.MODE_PRIVATE)
    private val _current = MutableStateFlow(
        AppLanguage.fromCode(prefs.getString(AppLanguage.PREFS_KEY, null)),
    )
    val current: StateFlow<AppLanguage> = _current.asStateFlow()

    fun setLanguage(language: AppLanguage) {
        prefs.edit().putString(AppLanguage.PREFS_KEY, language.code).apply()
        ContentCatalog.clearCache()
        _current.value = language
    }
}
