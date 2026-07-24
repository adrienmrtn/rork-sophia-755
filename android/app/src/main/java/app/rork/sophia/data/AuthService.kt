package app.rork.sophia.data

import android.content.Context
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialCancellationException
import app.rork.sophia.AppConfig
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.revenuecat.purchases.Purchases
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.Google
import io.github.jan.supabase.auth.providers.builtin.IDToken
import io.github.jan.supabase.auth.status.SessionStatus
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class AuthService(private val appContext: Context) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val _userId = MutableStateFlow<String?>(null)
    val userId: StateFlow<String?> = _userId.asStateFlow()
    val isSignedIn: Boolean get() = _userId.value != null

    private val _bootstrapping = MutableStateFlow(true)
    val bootstrapping: StateFlow<Boolean> = _bootstrapping.asStateFlow()

    fun start() {
        scope.launch {
            try {
                val session = SupabaseManager.client.auth.currentSessionOrNull()
                _userId.value = session?.user?.id
                linkRevenueCat()
            } catch (_: Exception) {
                // ignore
            } finally {
                _bootstrapping.value = false
            }
            SupabaseManager.client.auth.sessionStatus.collect { status ->
                when (status) {
                    is SessionStatus.Authenticated -> {
                        _userId.value = status.session.user?.id
                        linkRevenueCat()
                    }
                    else -> _userId.value = null
                }
            }
        }
    }

    suspend fun signInWithGoogle(activityContext: Context) {
        val googleIdOption = GetGoogleIdOption.Builder()
            .setFilterByAuthorizedAccounts(false)
            .setServerClientId(AppConfig.GOOGLE_WEB_CLIENT_ID)
            .build()
        val request = GetCredentialRequest.Builder()
            .addCredentialOption(googleIdOption)
            .build()
        val cm = CredentialManager.create(activityContext)
        try {
            val result = cm.getCredential(activityContext, request)
            val credential = result.credential
            if (credential is CustomCredential &&
                credential.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL
            ) {
                val google = GoogleIdTokenCredential.createFrom(credential.data)
                SupabaseManager.client.auth.signInWith(IDToken) {
                    idToken = google.idToken
                    provider = Google
                }
            } else {
                error("Unexpected credential type")
            }
        } catch (_: GetCredentialCancellationException) {
            // user cancelled
        }
    }

    suspend fun signOut() {
        runCatching { SupabaseManager.client.auth.signOut() }
        _userId.value = null
        if (Purchases.isConfigured) {
            runCatching { Purchases.sharedInstance.logOut() }
        }
    }

    private fun linkRevenueCat() {
        val uid = _userId.value ?: return
        if (Purchases.isConfigured) {
            runCatching { Purchases.sharedInstance.logIn(uid) }
        }
    }
}
