package app.rork.sophia.ui.paywall

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.rork.sophia.billing.StoreViewModel
import app.rork.sophia.data.StringStore
import app.rork.sophia.domain.AppLanguage
import app.rork.sophia.ui.theme.DS
import app.rork.sophia.ui.theme.PlusJakartaSans
import app.rork.sophia.ui.theme.SophiaTypography
import com.revenuecat.purchases.Package
import com.revenuecat.purchases.PurchaseParams
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesError
import com.revenuecat.purchases.getOfferingsWith
import com.revenuecat.purchases.interfaces.PurchaseCallback
import com.revenuecat.purchases.models.StoreTransaction

enum class PaywallContext(val offeringId: String) {
    FIN_ONBOARDING("fin_onboarding"),
    OFFRE_DISCOUNT("offre_discount"),
    DEBLOQUER_COURS("debloquer_cours"),
    QUIZZ("quizz"),
    ENTRAINEMENT("quizz"),
}

@Composable
fun PaywallScreen(
    context: PaywallContext,
    language: AppLanguage,
    storeViewModel: StoreViewModel,
    onDismiss: () -> Unit,
    onPurchased: () -> Unit,
) {
    val appContext = LocalContext.current
    var annual by remember { mutableStateOf<Package?>(null) }
    var monthly by remember { mutableStateOf<Package?>(null) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var purchasing by remember { mutableStateOf(false) }

    LaunchedEffect(context) {
        if (!Purchases.isConfigured) return@LaunchedEffect
        Purchases.sharedInstance.getOfferingsWith(
            onError = { err: PurchasesError -> errorMessage = err.message },
            onSuccess = { offerings ->
                val offering = offerings.getOffering(context.offeringId) ?: offerings.current
                annual = offering?.annual ?: offering?.availablePackages
                    ?.firstOrNull { it.packageType.name.contains("ANNUAL", ignoreCase = true) }
                monthly = offering?.monthly
            },
        )
    }

    fun purchase(pkg: Package) {
        val activity = appContext.findActivity() ?: return
        purchasing = true
        Purchases.sharedInstance.purchase(
            PurchaseParams.Builder(activity, pkg).build(),
            object : PurchaseCallback {
                override fun onCompleted(storeTransaction: StoreTransaction, customerInfo: com.revenuecat.purchases.CustomerInfo) {
                    purchasing = false
                    storeViewModel.refresh()
                    onPurchased()
                }

                override fun onError(error: PurchasesError, userCancelled: Boolean) {
                    purchasing = false
                    if (!userCancelled) {
                        errorMessage = error.message
                    }
                }
            },
        )
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DS.canvas)
            .padding(DS.Space.l),
        verticalArrangement = Arrangement.SpaceBetween,
    ) {
        Column {
            Spacer(Modifier.height(40.dp))
            Text("Sophia Premium", style = SophiaTypography.displayLarge, fontSize = 36.sp)
            Spacer(Modifier.height(12.dp))
            Text(
                text = when (context) {
                    PaywallContext.DEBLOQUER_COURS ->
                        StringStore.text(appContext, "home.locked", language)
                    PaywallContext.QUIZZ, PaywallContext.ENTRAINEMENT ->
                        StringStore.text(appContext, "training.locked.title", language)
                    PaywallContext.OFFRE_DISCOUNT -> "Offre limitée"
                    PaywallContext.FIN_ONBOARDING ->
                        StringStore.text(appContext, "onboarding.intro.title", language)
                },
                style = SophiaTypography.titleMedium,
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = "Accès illimité aux cours, quiz et entraînement.",
                style = SophiaTypography.bodyMedium,
            )
            if (errorMessage != null) {
                Spacer(Modifier.height(12.dp))
                Text(text = errorMessage!!, color = DS.danger, style = SophiaTypography.labelMedium)
            }
            if (!Purchases.isConfigured) {
                Spacer(Modifier.height(12.dp))
                Text(
                    text = "RevenueCat non configuré (clé goog_ manquante). Mode debug : simuler premium.",
                    style = SophiaTypography.labelMedium,
                    color = DS.inkSecondary,
                )
            }
        }

        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            val annualLabel = annual?.product?.price?.formatted
                ?: "Annuel"
            Button(
                onClick = {
                    val pkg = annual
                    if (pkg != null) purchase(pkg)
                    else if (!Purchases.isConfigured) {
                        storeViewModel.setPremiumDebug(true)
                        onPurchased()
                    }
                },
                enabled = !purchasing,
                modifier = Modifier.fillMaxWidth().height(54.dp),
                shape = DS.controlShape,
                colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
            ) {
                Text(
                    text = annualLabel,
                    color = Color.White,
                    fontFamily = PlusJakartaSans,
                    fontWeight = FontWeight.SemiBold,
                )
            }
            monthly?.let { pkg ->
                Button(
                    onClick = { purchase(pkg) },
                    enabled = !purchasing,
                    modifier = Modifier.fillMaxWidth().height(54.dp),
                    shape = DS.controlShape,
                    colors = ButtonDefaults.buttonColors(containerColor = DS.ink),
                ) {
                    Text(
                        text = pkg.product.price.formatted,
                        color = Color.White,
                        fontFamily = PlusJakartaSans,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
            }
            TextButton(onClick = onDismiss, modifier = Modifier.align(Alignment.CenterHorizontally)) {
                Text(
                    text = StringStore.text(appContext, "home.skip", language),
                    textAlign = TextAlign.Center,
                    color = DS.inkSecondary,
                )
            }
        }
    }
}

private fun android.content.Context.findActivity(): android.app.Activity? {
    var ctx = this
    while (ctx is android.content.ContextWrapper) {
        if (ctx is android.app.Activity) return ctx
        ctx = ctx.baseContext
    }
    return null
}
