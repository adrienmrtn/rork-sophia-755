package app.rork.sophia.billing

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import app.rork.sophia.AppConfig
import com.revenuecat.purchases.CustomerInfo
import com.revenuecat.purchases.EntitlementInfo
import com.revenuecat.purchases.Offering
import com.revenuecat.purchases.Offerings
import com.revenuecat.purchases.Package
import com.revenuecat.purchases.PeriodType
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesConfiguration
import com.revenuecat.purchases.PurchasesError
import com.revenuecat.purchases.getOfferingsWith
import com.revenuecat.purchases.interfaces.ReceiveCustomerInfoCallback
import com.revenuecat.purchases.paywalls.events.CustomPaywallImpressionParams
import com.revenuecat.purchases.restorePurchasesWith
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.text.NumberFormat
import java.util.Calendar
import java.util.Currency
import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit

class StoreViewModel(app: Application) : AndroidViewModel(app) {
    private val _isPremium = MutableStateFlow(false)
    val isPremium: StateFlow<Boolean> = _isPremium.asStateFlow()

    /** Active Premium entitlement currently in a free-trial period. */
    private val _isInFreeTrial = MutableStateFlow(false)
    val isInFreeTrial: StateFlow<Boolean> = _isInFreeTrial.asStateFlow()

    /** True when the free trial expires tomorrow (calendar day) — drives the in-app mini banner. */
    private val _trialExpiresInOneDay = MutableStateFlow(false)
    val trialExpiresInOneDay: StateFlow<Boolean> = _trialExpiresInOneDay.asStateFlow()

    private val _configured = MutableStateFlow(false)
    val configured: StateFlow<Boolean> = _configured.asStateFlow()

    private val _offerings = MutableStateFlow<Offerings?>(null)
    val offerings: StateFlow<Offerings?> = _offerings.asStateFlow()

    /** True once an offerings fetch completed (success or empty). Null offerings before that. */
    private val _offeringsLoaded = MutableStateFlow(false)
    val offeringsLoaded: StateFlow<Boolean> = _offeringsLoaded.asStateFlow()

    init {
        configureIfNeeded()
        refresh()
        fetchOfferings()
    }

    private fun applyCustomerInfo(customerInfo: CustomerInfo) {
        val entitlement = customerInfo.entitlements[AppConfig.PREMIUM_ENTITLEMENT]
        val active = entitlement?.isActive == true
        _isPremium.value = active
        _isInFreeTrial.value = active && entitlement?.periodType == PeriodType.TRIAL
        _trialExpiresInOneDay.value = isTrialExpiringInOneDay(entitlement)
    }

    /** Calendar-day check: trial is active and expires tomorrow. */
    private fun isTrialExpiringInOneDay(entitlement: EntitlementInfo?): Boolean {
        if (entitlement == null || !entitlement.isActive) return false
        if (entitlement.periodType != PeriodType.TRIAL) return false
        val expiration = entitlement.expirationDate ?: return false
        val startToday = startOfDay(Date())
        val startExpiration = startOfDay(expiration)
        val days = TimeUnit.MILLISECONDS.toDays(startExpiration.time - startToday.time)
        return days == 1L
    }

    private fun startOfDay(date: Date): Date {
        val calendar = Calendar.getInstance()
        calendar.time = date
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.time
    }

    private fun configureIfNeeded() {
        if (Purchases.isConfigured) {
            _configured.value = true
            return
        }
        val key = AppConfig.revenueCatApiKey
        if (key.contains("REPLACE_ME")) {
            // Billing not wired yet — app runs in free mode until you add goog_ key.
            _configured.value = false
            return
        }
        Purchases.configure(
            PurchasesConfiguration.Builder(getApplication(), key).build(),
        )
        _configured.value = true
    }

    fun refresh() {
        if (!Purchases.isConfigured) return
        viewModelScope.launch {
            Purchases.sharedInstance.getCustomerInfo(object : ReceiveCustomerInfoCallback {
                override fun onReceived(customerInfo: CustomerInfo) {
                    applyCustomerInfo(customerInfo)
                }

                override fun onError(error: PurchasesError) {
                    // Keep last known state.
                }
            })
        }
    }

    fun fetchOfferings() {
        if (!Purchases.isConfigured) {
            _offeringsLoaded.value = true
            return
        }
        Purchases.sharedInstance.getOfferingsWith(
            onError = { _offeringsLoaded.value = true },
            onSuccess = { result ->
                _offerings.value = result
                _offeringsLoaded.value = true
            },
        )
    }

    fun offering(identifier: String?): Offering? {
        val all = _offerings.value ?: return null
        if (identifier.isNullOrBlank()) return all.current
        return all.getOffering(identifier) ?: all.current
    }

    fun annualPackage(offeringIdentifier: String? = null): Package? {
        val offering = offering(offeringIdentifier) ?: return null
        return offering.annual
            ?: offering.availablePackages.firstOrNull {
                it.packageType.name.contains("ANNUAL", ignoreCase = true)
            }
    }

    fun monthlyPackage(offeringIdentifier: String? = null): Package? {
        return offering(offeringIdentifier)?.monthly
    }

    /**
     * Whether a package's store product ships a free-trial introductory offer.
     * Paywall copy must never promise a free trial the served product doesn't have.
     */
    fun hasFreeTrial(pkg: Package?): Boolean {
        val product = pkg?.product ?: return false
        return product.subscriptionOptions?.freeTrial != null
    }

    fun annualHasFreeTrial(offeringIdentifier: String? = null): Boolean =
        hasFreeTrial(annualPackage(offeringIdentifier))

    /**
     * When offerings aren't loaded yet, treat as "has trial" so we don't skip the trial
     * onboarding page prematurely (parity with iOS: `offerings == nil || annualHasFreeTrial`).
     */
    fun shouldShowTrialSteps(): Boolean {
        if (!_offeringsLoaded.value || _offerings.value == null) return true
        return annualHasFreeTrial(null)
    }

    /**
     * Marks the customer as exposed to their experiment variant. Call once per presentation.
     */
    fun trackPaywallImpression(paywallId: String, offeringIdentifier: String? = null) {
        if (!Purchases.isConfigured) return
        try {
            val resolvedId = offeringIdentifier
                ?: offering(null)?.identifier
            Purchases.sharedInstance.trackCustomPaywallImpression(
                CustomPaywallImpressionParams(
                    paywallId = paywallId,
                    offeringId = resolvedId,
                ),
            )
        } catch (_: Throwable) {
            // Don't crash the paywall if the RC API surface changes.
        }
    }

    fun formattedPrice(pkg: Package?, fallback: String): String =
        pkg?.product?.price?.formatted ?: fallback

    fun formattedYearlyPerMonth(pkg: Package?, fallbackYearly: String): String {
        val price = pkg?.product?.price ?: return fallbackYearly
        val monthlyMicros = price.amountMicros / 12.0
        return try {
            val format = NumberFormat.getCurrencyInstance(Locale.getDefault())
            format.currency = Currency.getInstance(price.currencyCode)
            format.format(monthlyMicros / 1_000_000.0)
        } catch (_: Exception) {
            fallbackYearly
        }
    }

    fun setPremiumDebug(value: Boolean) {
        _isPremium.value = value
    }

    fun restore(onResult: (success: Boolean, message: String?) -> Unit = { _, _ -> }) {
        if (!Purchases.isConfigured) {
            onResult(false, "RevenueCat non configuré")
            return
        }
        Purchases.sharedInstance.restorePurchasesWith(
            onError = { error -> onResult(false, error.message) },
            onSuccess = { info ->
                applyCustomerInfo(info)
                val active = _isPremium.value
                onResult(active, if (active) null else "Aucun abonnement trouvé")
            },
        )
    }
}
