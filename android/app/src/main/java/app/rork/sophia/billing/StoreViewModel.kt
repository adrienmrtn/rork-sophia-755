package app.rork.sophia.billing

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import app.rork.sophia.AppConfig
import com.revenuecat.purchases.CustomerInfo
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesConfiguration
import com.revenuecat.purchases.PurchasesError
import com.revenuecat.purchases.interfaces.ReceiveCustomerInfoCallback
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class StoreViewModel(app: Application) : AndroidViewModel(app) {
    private val _isPremium = MutableStateFlow(false)
    val isPremium: StateFlow<Boolean> = _isPremium.asStateFlow()

    private val _configured = MutableStateFlow(false)
    val configured: StateFlow<Boolean> = _configured.asStateFlow()

    init {
        configureIfNeeded()
        refresh()
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
                    _isPremium.value =
                        customerInfo.entitlements[AppConfig.PREMIUM_ENTITLEMENT]?.isActive == true
                }

                override fun onError(error: PurchasesError) {
                    // Keep last known state.
                }
            })
        }
    }

    fun setPremiumDebug(value: Boolean) {
        _isPremium.value = value
    }
}
