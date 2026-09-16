package app.rork.sophia.data

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.credentials.CredentialManager
import androidx.credentials.CredentialOption
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.GetCredentialProviderConfigurationException
import androidx.credentials.exceptions.NoCredentialException
import app.rork.sophia.AppConfig
import app.rork.sophia.BuildConfig
import app.rork.sophia.domain.AppLanguage
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.revenuecat.purchases.Purchases
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.Google
import io.github.jan.supabase.auth.providers.builtin.IDToken
import io.github.jan.supabase.auth.status.SessionStatus
import io.github.jan.supabase.functions.functions
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.security.MessageDigest

/**
 * What a sign-in attempt actually did. The screen needs to tell these apart: a cancellation
 * is silent, a missing provider means "this phone cannot do Google at all", and only a real
 * failure deserves an error with a Retry button.
 */
sealed interface SignInOutcome {
    data object Success : SignInOutcome

    /** User dismissed the sheet, or the caller left the screen. Say nothing. */
    data object Cancelled : SignInOutcome

    /** No Google Play services / no credential provider: offer the no-account path instead. */
    data object Unavailable : SignInOutcome

    /** Something went wrong; [message] is already localized and safe to show. */
    data class Failure(val message: String) : SignInOutcome
}

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
     * Runs the Google account picker and, on success, opens a Supabase session.
     *
     * One Tap (`GetGoogleIdOption`) is tried first; on emulators and first-run devices it
     * usually throws "no credentials" with no UI. The button on screen is Sign in with Google,
     * so we fall back to `GetSignInWithGoogleOption`, which actually shows the account picker.
     *
     * Never shows anything itself: the caller owns the screen and decides what a failure
     * looks like there. A [SignInOutcome.Cancelled] is silent by contract — a user who
     * dismissed the sheet, or who left the screen while it was open (the coroutine is then
     * cancelled and `CancellationException` surfaces here), must not be shown an error.
     */
    suspend fun signInWithGoogle(activityContext: Context): SignInOutcome {
        val activity = activityContext.findActivity() ?: run {
            Log.e(TAG, "Google sign-in needs an Activity context")
            return SignInOutcome.Failure(localizedError(activityContext))
        }
        if (!DeviceCapabilities.hasGooglePlayServices(activity)) {
            Log.w(TAG, "No Google Play services on this device")
            return SignInOutcome.Unavailable
        }
        val cm = CredentialManager.create(activity)
        val webClientId = AppConfig.GOOGLE_WEB_CLIENT_ID

        suspend fun request(option: CredentialOption): SignInOutcome {
            val result = cm.getCredential(
                activity,
                GetCredentialRequest.Builder().addCredentialOption(option).build(),
            )
            consumeGoogleCredential(result)
            return SignInOutcome.Success
        }

        try {
            return request(
                GetGoogleIdOption.Builder()
                    .setFilterByAuthorizedAccounts(false)
                    .setServerClientId(webClientId)
                    .build(),
            )
        } catch (e: CancellationException) {
            // The composition left while the sheet was up. Not an error, and rethrowing
            // keeps structured concurrency honest.
            throw e
        } catch (e: GetCredentialCancellationException) {
            // Google also reports some refusals as a cancellation, so this branch used to
            // swallow real configuration errors. Log it, stay quiet on screen.
            Log.i(TAG, "One Tap dismissed or cancelled", e)
            return SignInOutcome.Cancelled
        } catch (e: GetCredentialException) {
            Log.w(TAG, "One Tap unavailable, falling back to Sign in with Google", e)
        } catch (e: Exception) {
            return fail(activity, e)
        }

        return try {
            request(GetSignInWithGoogleOption.Builder(webClientId).build())
        } catch (e: CancellationException) {
            throw e
        } catch (e: GetCredentialCancellationException) {
            Log.i(TAG, "Sign in with Google dismissed or cancelled", e)
            logSigningIdentity(activity)
            SignInOutcome.Cancelled
        } catch (e: Exception) {
            fail(activity, e)
        }
    }

    /**
     * Google matches the request against a package name plus the SHA-1 of the certificate the
     * installed app is actually signed with — for a Play build, Play's app signing key, not the
     * upload key. Getting that pair wrong looks exactly like a user cancelling: the picker
     * appears, the tap returns nothing. Printing what the app really is turns that into a fact
     * you can compare against the Android OAuth client.
     */
    private fun logSigningIdentity(context: Context) {
        val sha1 = runCatching {
            val pm = context.packageManager
            @Suppress("DEPRECATION")
            val certificate = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                pm.getPackageInfo(context.packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                    .signingInfo
                    ?.apkContentsSigners
                    ?.firstOrNull()
            } else {
                pm.getPackageInfo(context.packageName, PackageManager.GET_SIGNATURES)
                    .signatures
                    ?.firstOrNull()
            } ?: return@runCatching null
            MessageDigest.getInstance("SHA-1")
                .digest(certificate.toByteArray())
                .joinToString(":") { "%02X".format(it) }
        }.getOrNull()
        Log.w(TAG, "package=${context.packageName} signingSha1=$sha1 serverClientId=${AppConfig.GOOGLE_WEB_CLIENT_ID}")
    }

    private suspend fun consumeGoogleCredential(result: GetCredentialResponse) {
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
    }

    /**
     * A dead button is the worst outcome: the account picker completes, Supabase rejects the
     * token, and the user sees nothing. So the failure is always returned to the screen, and
     * the technical cause always logged under [TAG] — `adb logcat -s SophiaAuth` on a Play
     * build.
     *
     * A provider that is missing or misconfigured is reported as [SignInOutcome.Unavailable]:
     * retrying cannot help, so the screen offers the no-account path instead of a Retry button.
     */
    private fun fail(activity: Activity, e: Exception): SignInOutcome {
        Log.e(TAG, "Google sign-in failed", e)
        logSigningIdentity(activity)
        if (e is NoCredentialException || e is GetCredentialProviderConfigurationException) {
            return SignInOutcome.Unavailable
        }
        val message = if (BuildConfig.DEBUG) {
            e.message ?: "Google sign-in failed"
        } else {
            localizedError(activity)
        }
        return SignInOutcome.Failure(message)
    }

    private fun localizedError(context: Context): String {
        val language = app()?.languageManager?.current?.value ?: AppLanguage.FRENCH
        return StringStore.text(context, "auth.error.generic", language)
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
        // The trial belonged to the account that just left, so its reminder has to go too:
        // a pending alarm outlives the session and would otherwise fire for a stranger.
        runCatching { TrialReminderScheduler.cancel(appContext) }
    }

    /**
     * Permanently deletes the account through the `delete-user` Edge Function — the same
     * server-side path iOS uses, running under the service role so the row cascade
     * (`profiles`, `user_progress`) happens where the client cannot reach. Google Play
     * requires an in-app deletion route, and the terms promise it lives in settings.
     *
     * Throws when the call fails, so the screen can keep the user signed in and say so.
     * On success everything local goes too: the cloud copy is gone, keeping a local one
     * would silently resurrect the profile on the next sign-in.
     */
    suspend fun deleteAccount() {
        SupabaseManager.client.functions.invoke("delete-user")
        signOut()
        val app = app()
        runCatching { app?.progressManager?.resetProgress() }
        runCatching { app?.progressSyncService?.clearPendingConflict() }
        runCatching { app?.discountManager?.clearLocalState() }
        runCatching { app?.analytics?.reset() }
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
