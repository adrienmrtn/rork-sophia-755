package app.rork.sophia.billing

import android.app.Application
import android.content.Context
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import app.rork.sophia.AppConfig
import app.rork.sophia.BuildConfig
import app.rork.sophia.SophiaApplication
import app.rork.sophia.data.DiscountBucket
import app.rork.sophia.data.TrialReminderScheduler
import app.rork.sophia.domain.locale
import com.revenuecat.purchases.CustomerInfo
import com.revenuecat.purchases.LogLevel
import com.revenuecat.purchases.EntitlementInfo
import com.revenuecat.purchases.Offering
import com.revenuecat.purchases.Offerings
import com.revenuecat.purchases.Package
import com.revenuecat.purchases.PackageType
import com.revenuecat.purchases.PeriodType
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesConfiguration
import com.revenuecat.purchases.PurchasesError
import com.revenuecat.purchases.getOfferingsWith
import com.revenuecat.purchases.interfaces.ReceiveCustomerInfoCallback
import com.revenuecat.purchases.interfaces.UpdatedCustomerInfoListener
import com.revenuecat.purchases.models.Period
import com.revenuecat.purchases.paywalls.events.CustomPaywallImpressionParams
import com.revenuecat.purchases.restorePurchasesWith
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.text.DecimalFormat
import java.text.NumberFormat
import java.util.Calendar
import java.util.Currency
import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit

class StoreViewModel(app: Application) : AndroidViewModel(app) {
    /**
     * Debug builds only: Premium forced on from the settings, to test the Premium side of the
     * app on an emulator, where Play sells nothing. Kept across launches. Always false in a
     * release build, where `BuildConfig.DEBUG` is a compile-time false.
     */
    private val debugPrefs = app.getSharedPreferences(DEBUG_PREFS, Context.MODE_PRIVATE)
    private val _debugPremium = MutableStateFlow(BuildConfig.DEBUG && debugPrefs.getBoolean(KEY_DEBUG_PREMIUM, false))
    val debugPremium: StateFlow<Boolean> = _debugPremium.asStateFlow()

    /** What the store says, before the debug switch is laid over it. */
    private var entitledPremium = false

    private val _isPremium = MutableStateFlow(_debugPremium.value)
    val isPremium: StateFlow<Boolean> = _isPremium.asStateFlow()

    /** Active Premium entitlement currently in a free-trial period. */
    private val _isInFreeTrial = MutableStateFlow(false)
    val isInFreeTrial: StateFlow<Boolean> = _isInFreeTrial.asStateFlow()

    /** True when the free trial expires tomorrow (calendar day) — drives the in-app mini banner. */
    private val _trialExpiresInOneDay = MutableStateFlow(false)
    val trialExpiresInOneDay: StateFlow<Boolean> = _trialExpiresInOneDay.asStateFlow()

    /** Exact end of the running free trial, when RevenueCat knows it. Aims the local reminder. */
    private val _trialExpirationDate = MutableStateFlow<Date?>(null)
    val trialExpirationDate: StateFlow<Date?> = _trialExpirationDate.asStateFlow()

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
        val inTrial = active && entitlement?.periodType == PeriodType.TRIAL
        entitledPremium = active
        publishPremium()
        _isInFreeTrial.value = inTrial
        _trialExpiresInOneDay.value = isTrialExpiringInOneDay(entitlement)
        val trialEnd = if (inTrial) entitlement?.expirationDate else null
        _trialExpirationDate.value = trialEnd
        // Pending alarms are dropped on reboot, the trial may have started on another device,
        // and the purchase path can only assume a 3-day trial. Re-aim the reminder from the
        // authoritative expiry every time it lands; an unchanged target is a no-op.
        if (trialEnd != null) {
            TrialReminderScheduler.scheduleTrialEndingReminder(getApplication(), trialEnd)
        } else if (entitlement != null) {
            // This customer has an entitlement on record and it is not in a trial: either it
            // converted to paid, or it was bought with no trial at all, or it lapsed. Nothing
            // is ending, so a pending "your trial ends tomorrow" alarm has to go.
            //
            // Deliberately not cancelling when `entitlement` is null: that is also what a
            // brand-new purchase looks like in the seconds before RevenueCat reports the
            // trial, and the onboarding has just armed an assumed 3-day reminder that this
            // would silently throw away.
            TrialReminderScheduler.cancel(getApplication())
        }
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
            observeCustomerInfo()
            attachSignedInUser()
            reportDiscountBucket()
            return
        }
        val key = AppConfig.revenueCatApiKey
        if (key.contains("REPLACE_ME")) {
            // Billing not wired yet — app runs in free mode until you add goog_ key.
            _configured.value = false
            return
        }
        if (BuildConfig.DEBUG) {
            Purchases.logLevel = LogLevel.DEBUG
        }
        Purchases.configure(
            PurchasesConfiguration.Builder(getApplication(), key).build(),
        )
        _configured.value = true
        observeCustomerInfo()
        attachSignedInUser()
        reportDiscountBucket()
    }

    /**
     * AuthService restores the session from Application.onCreate, before this view model
     * exists, so its own attempt to identify the RevenueCat user can run while Purchases is
     * still unconfigured. Ask again now that it is.
     */
    private fun attachSignedInUser() {
        runCatching {
            (getApplication() as? SophiaApplication)?.authService?.linkRevenueCatIfNeeded()
        }
    }

    /**
     * Tells RevenueCat which discount bucket this customer is in (see [DiscountBucket]).
     * Sent at every launch: attributes are cheap, RevenueCat ignores unchanged values, and a
     * re-send after `logIn` keeps the identified customer tagged as well as the anonymous one.
     */
    private fun reportDiscountBucket() {
        runCatching {
            Purchases.sharedInstance.setAttributes(
                mapOf("discount_bucket" to DiscountBucket.get(getApplication())),
            )
        }
    }

    /**
     * The entitlement can change without this app doing anything: the subscription may have
     * been bought on iOS and arrive when [Purchases.logIn] attaches the Supabase user id, or
     * be renewed or cancelled while the app sits in the background. Listening keeps Premium
     * in sync instead of waiting for the next manual refresh.
     */
    private fun observeCustomerInfo() {
        Purchases.sharedInstance.updatedCustomerInfoListener = UpdatedCustomerInfoListener { info ->
            applyCustomerInfo(info)
        }
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

    /**
     * Offering a context paywall (`quizz`, `debloquer_cours`, `entrainement`) actually displays.
     *
     * RevenueCat experiments work by swapping the **current** offering, and the context
     * offerings carry the same products as `fin_onboarding`: they exist for attribution, not
     * to sell another price. So a context paywall shows and charges the current offering
     * whenever it has an annual package, and only falls back to its own offering when the
     * current one has none — otherwise a customer enrolled in a 59,99 € variant could buy at
     * 39,99 € from any course. The discount paywall never goes through here: see [promoOffering].
     */
    fun displayedOffering(contextIdentifier: String?): Offering? {
        val all = _offerings.value ?: return null
        val current = all.current
        if (current != null && annualOf(current) != null) return current
        return offering(contextIdentifier)
    }

    private fun annualOf(offering: Offering): Package? =
        offering.annual
            ?: offering.availablePackages.firstOrNull {
                it.packageType.name.contains("ANNUAL", ignoreCase = true)
            }

    fun annualPackage(offeringIdentifier: String? = null): Package? {
        val offering = displayedOffering(offeringIdentifier) ?: return null
        return annualOf(offering)
    }

    fun monthlyPackage(offeringIdentifier: String? = null): Package? {
        return displayedOffering(offeringIdentifier)?.monthly
    }

    fun weeklyPackage(offeringIdentifier: String? = null): Package? {
        return displayedOffering(offeringIdentifier)?.weekly
    }

    /**
     * The plan sold next to the annual one on the comparison paywall: the monthly plan, or the
     * weekly plan when the served offering carries a weekly package instead (a RevenueCat
     * experiment can swap one for the other without an app update).
     */
    fun shortPlanPackage(offeringIdentifier: String? = null): Package? =
        monthlyPackage(offeringIdentifier) ?: weeklyPackage(offeringIdentifier)

    fun isWeekly(pkg: Package?): Boolean = pkg?.packageType == PackageType.WEEKLY

    /**
     * Offering behind the flash discount paywall: the bucket's offering, or `offre_discount`
     * while the bucket's own offering does not exist yet in RevenueCat. Explicit by design: it
     * is never the current offering, so an experiment on the onboarding price leaves it
     * untouched.
     */
    fun promoOffering(): Offering? {
        val all = _offerings.value ?: return null
        val bucket = DiscountBucket.get(getApplication())
        return all.getOffering(DiscountBucket.offeringIdentifier(bucket))
            ?: all.getOffering(DiscountBucket.offeringIdentifier(DiscountBucket.A))
    }

    fun promoPackage(): Package? = promoOffering()?.let { annualOf(it) }

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
     * Days of free trial a package's product ships, or null when it has none. Read from the
     * store rather than assumed, so copy that names the number follows whatever the served
     * product carries — a 7-day variant included.
     */
    fun trialDays(pkg: Package?): Int? {
        val period = pkg?.product?.subscriptionOptions?.freeTrial?.freePhase?.billingPeriod ?: return null
        val unitDays = when (period.unit) {
            Period.Unit.DAY -> 1
            Period.Unit.WEEK -> 7
            Period.Unit.MONTH -> 30
            Period.Unit.YEAR -> 365
            else -> 1
        }
        return (period.value * unitDays).coerceAtLeast(1)
    }

    /** Days of the annual plan's free trial, for copy; 3 until the products are loaded. */
    fun annualTrialDays(): Int = trialDays(annualPackage(null)) ?: 3

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
        // The offering reported must be the one on screen, or a customer enrolled in an
        // experiment is never counted as exposed: resolved the same way the paywall picks
        // its package.
        trackPaywallImpressionForOffering(paywallId, displayedOffering(offeringIdentifier)?.identifier)
    }

    /** Same, for a paywall that knows exactly which offering it displays (the discount one). */
    fun trackPaywallImpressionForOffering(paywallId: String, offeringId: String?) {
        if (!Purchases.isConfigured) return
        try {
            val resolvedId = offeringId
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

    /**
     * Twelfth of an annual plan's price, written the way this phone writes that currency.
     *
     * Two different things decide how it reads, and they are not the same thing:
     *
     *  - **Digits and separators** follow the language the paywall is being read in. The
     *    device locale put Arabic-Indic digits in a French price on an Arabic phone.
     *  - **The currency symbol** comes from the device's own locale, because that is the
     *    country whose store served the price. ICU only prints a currency's local symbol
     *    when the *language* is that currency's own: asking for Turkish lira in French
     *    gives "33,33 TRY", so a Turkish customer reading the app in French saw the annual
     *    price as "₺399,99" (Play's own string) next to a monthly "33,33 TRY" — the same
     *    currency written two ways on one card. Taking the symbol from the device matches
     *    what Play printed. Adding the region to the reading locale does not work: fr-TR
     *    still gives "TRY".
     */
    fun formattedYearlyPerMonth(pkg: Package?, fallbackYearly: String): String =
        formattedYearlyPerPeriod(pkg, 12, fallbackYearly)

    /** Fifty-second of the annual price, for the comparison card next to a weekly plan. */
    fun formattedYearlyPerWeek(pkg: Package?, fallbackYearly: String): String =
        formattedYearlyPerPeriod(pkg, 52, fallbackYearly)

    private fun formattedYearlyPerPeriod(pkg: Package?, periodsPerYear: Int, fallbackYearly: String): String {
        val price = pkg?.product?.price ?: return fallbackYearly
        val monthlyMicros = price.amountMicros / periodsPerYear.toDouble()
        return formatAmount(monthlyMicros / 1_000_000.0, price.currencyCode) ?: fallbackYearly
    }

    /**
     * « 0,00 € » in the currency of the store that serves [pkg]: what tapping the button
     * costs today while a free trial is served. Empty when no price has arrived yet.
     */
    fun formattedZeroPrice(pkg: Package?): String {
        val price = pkg?.product?.price ?: return ""
        return formatAmount(0.0, price.currencyCode).orEmpty()
    }

    /** [amount] with the reading language's digits and the device's currency symbol (see above). */
    private fun formatAmount(amount: Double, currencyCode: String): String? = try {
        val appLanguage = (getApplication() as? SophiaApplication)
            ?.languageManager?.current?.value
        val currency = Currency.getInstance(currencyCode)
        val format = NumberFormat.getCurrencyInstance(appLanguage?.locale ?: Locale.getDefault())
        format.currency = currency
        (format as? DecimalFormat)?.let { decimal ->
            decimal.decimalFormatSymbols = decimal.decimalFormatSymbols.apply {
                currencySymbol = currency.getSymbol(Locale.getDefault())
            }
        }
        format.format(amount)
    } catch (_: Exception) {
        null
    }

    /**
     * « -58 % » style badge comparing the annual plan to twelve monthly ones. Null when
     * either price is missing or the annual plan isn't actually cheaper.
     */
    fun discountBadge(annual: Package?, shortPlan: Package?, periodsPerYear: Int = 12): String? {
        val annualMicros = annual?.product?.price?.amountMicros ?: return null
        val monthlyMicros = shortPlan?.product?.price?.amountMicros ?: return null
        if (monthlyMicros <= 0) return null
        val yearOfMonthly = monthlyMicros * periodsPerYear.toDouble()
        if (annualMicros >= yearOfMonthly) return null
        val percent = ((1.0 - annualMicros / yearOfMonthly) * 100).toInt()
        return if (percent <= 0) null else "-$percent%"
    }

    /**
     * « -50 % » badge of the discount paywall: how much the promo annual saves against the
     * regular annual. Null unless both prices are known and the promo is actually cheaper,
     * so the paywall never advertises a discount that the store would not honour.
     */
    fun percentOff(promo: Package?, regular: Package?): String? {
        val promoMicros = promo?.product?.price?.amountMicros ?: return null
        val regularMicros = regular?.product?.price?.amountMicros ?: return null
        if (regularMicros <= 0 || promoMicros >= regularMicros) return null
        val percent = ((1.0 - promoMicros.toDouble() / regularMicros) * 100).toInt()
        return if (percent <= 0) null else "-$percent%"
    }

    fun setPremiumDebug(value: Boolean) {
        entitledPremium = value
        publishPremium()
    }

    /** The settings switch of debug builds; does nothing in a release build. */
    fun setDebugPremium(enabled: Boolean) {
        if (!BuildConfig.DEBUG) return
        _debugPremium.value = enabled
        debugPrefs.edit().putBoolean(KEY_DEBUG_PREMIUM, enabled).apply()
        publishPremium()
    }

    private fun publishPremium() {
        _isPremium.value = entitledPremium || _debugPremium.value
    }

    /**
     * Outcome of a restore, as something the screen can put in front of the user. The old
     * signature handed back a raw RevenueCat message — untranslated, and empty on the happy
     * path, which is why tapping Restore used to look like nothing had happened.
     */
    enum class RestoreResult { RESTORED, NOTHING_FOUND, FAILED }

    fun restore(onResult: (RestoreResult) -> Unit = {}) {
        if (!Purchases.isConfigured) {
            onResult(RestoreResult.FAILED)
            return
        }
        Purchases.sharedInstance.restorePurchasesWith(
            onError = { onResult(RestoreResult.FAILED) },
            onSuccess = { info ->
                applyCustomerInfo(info)
                onResult(
                    if (entitledPremium) RestoreResult.RESTORED else RestoreResult.NOTHING_FOUND,
                )
            },
        )
    }

    /** True when the entitlement this app sells is active right now on this customer info. */
    fun isEntitlementActive(customerInfo: CustomerInfo): Boolean =
        customerInfo.entitlements[AppConfig.PREMIUM_ENTITLEMENT]?.isActive == true

    companion object {
        /**
         * What a paywall shows before Play has answered, or when it never does: no number at
         * all. The old fallback was a hard-coded « 39,99 € » per language, wrong the moment a
         * price experiment or a country tier serves anything else.
         */
        const val UNKNOWN_PRICE = "…"

        private const val DEBUG_PREFS = "sophia_debug"
        private const val KEY_DEBUG_PREMIUM = "forcePremium"
    }
}
