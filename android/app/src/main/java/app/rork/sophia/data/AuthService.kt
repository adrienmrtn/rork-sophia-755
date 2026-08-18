package app.rork.sophia.data

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.util.Log
import android.widget.Toast
import androidx.credentials.CredentialManager
import androidx.credentials.CredentialOption
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import app.rork.sophia.AppConfig
import app.rork.sophia.BuildConfig
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
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

    /** Supabase id currently attached to RevenueCat, so logIn is not replayed on every emission. */
    private var revenueCatUserId: String? = null

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
            runCatching {
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
    }

    /**
     * @return true when a Supabase session was created. False on cancel or failure.
     *
     * One Tap (`GetGoogleIdOption`) is tried first; on emulators and first-run devices it
     * usually throws "no credentials" with no UI. The button on screen is Sign in with Google,
     * so we fall back to `GetSignInWithGoogleOption`, which actually shows the account picker.
     */
    suspend fun signInWithGoogle(activityContext: Context): Boolean {
        val activity = activityContext.findActivity() ?: run {
            Log.e(TAG, "Google sign-in needs an Activity context")
            return false
        }
        val cm = CredentialManager.create(activity)
        val webClientId = AppConfig.GOOGLE_WEB_CLIENT_ID

        suspend fun request(option: CredentialOption): Boolean {
            val result = cm.getCredential(
                activity,
                GetCredentialRequest.Builder().addCredentialOption(option).build(),
            )
            return consumeGoogleCredential(result)
        }

        try {
            return request(
                GetGoogleIdOption.Builder()
                    .setFilterByAuthorizedAccounts(false)
                    .setServerClientId(webClientId)
                    .build(),
            )
        } catch (_: GetCredentialCancellationException) {
            return false
        } catch (e: GetCredentialException) {
            Log.w(TAG, "One Tap unavailable, falling back to Sign in with Google", e)
        } catch (e: Exception) {
            return fail(activity, e)
        }

        return try {
            request(GetSignInWithGoogleOption.Builder(webClientId).build())
        } catch (_: GetCredentialCancellationException) {
            false
        } catch (e: Exception) {
            fail(activity, e)
        }
    }

    private suspend fun consumeGoogleCredential(result: GetCredentialResponse): Boolean {
        val credential = result.credential
        if (credential !is CustomCredential ||
            credential.type != GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL
        ) {
            error("Unexpected credential type ${credential.type}")
        }
        val google = GoogleIdTokenCredential.createFrom(credential.data)
        SupabaseManager.client.auth.signInWith(IDToken) {
            idToken = google.idToken
            provider = Google
        }
        return true
    }

    private fun fail(activity: Activity, e: Exception): Boolean {
        Log.e(TAG, "Google sign-in failed", e)
        if (BuildConfig.DEBUG) {
            Toast.makeText(activity, e.message ?: "Google sign-in failed", Toast.LENGTH_LONG).show()
        }
        return false
    }

    suspend fun signOut() {
        runCatching { SupabaseManager.client.auth.signOut() }
        _userId.value = null
        // Handle, requests and leaderboard belong to the account that just left.
        runCatching { app()?.socialService?.clearLocalState() }
        revenueCatUserId = null
        if (Purchases.isConfigured) {
            // Back to an anonymous RevenueCat user. A subscription bought on this device
            // and Play account is still restorable; one bought on another device is not,
            // which is exactly what signing out means here.
            runCatching { Purchases.sharedInstance.logOut() }
        }
    }

    /**
     * Sign-in is optional on Android, so RevenueCat runs anonymous until an account shows
     * up. [Purchases] is configured by [app.rork.sophia.billing.StoreViewModel], which is
     * built after this service starts, so the first attempt can land before RevenueCat is
     * ready — hence the retry from the store once it is configured.
     */
    fun linkRevenueCatIfNeeded() {
        val uid = _userId.value ?: return
        if (!Purchases.isConfigured || revenueCatUserId == uid) return
        revenueCatUserId = uid
        // Same app user id as iOS, so a subscription bought there is recognised here.
        // StoreViewModel listens for customer-info updates, which is how the entitlement
        // arrives after this call.
        runCatching {
            Purchases.sharedInstance.logIn(
                uid,
                object : com.revenuecat.purchases.interfaces.LogInCallback {
                    override fun onReceived(
                        customerInfo: com.revenuecat.purchases.CustomerInfo,
                        created: Boolean,
                    ) {
                        // Anything bought while anonymous lives in the Play account, not in
                        // this RevenueCat user. Push the receipts across so a purchase made
                        // before signing in follows the account.
                        runCatching { Purchases.sharedInstance.syncPurchases() }
                    }

                    override fun onError(error: com.revenuecat.purchases.PurchasesError) {
                        Log.w(TAG, "RevenueCat logIn failed: ${error.message}")
                        revenueCatUserId = null
                    }
                },
            )
        }
    }

    private fun linkRevenueCat() {
        val uid = _userId.value ?: return
        linkRevenueCatIfNeeded()
        // Align Mixpanel identity with RevenueCat / Supabase user id.
        runCatching { app()?.analytics?.identify(uid) }
    }

    private fun app(): app.rork.sophia.SophiaApplication? =
        appContext.applicationContext as? app.rork.sophia.SophiaApplication

    private companion object {
        const val TAG = "SophiaAuth"
    }
}

private fun Context.findActivity(): Activity? {
    var ctx: Context = this
    while (ctx is ContextWrapper) {
        if (ctx is Activity) return ctx
        ctx = ctx.baseContext
    }
    return null
}
