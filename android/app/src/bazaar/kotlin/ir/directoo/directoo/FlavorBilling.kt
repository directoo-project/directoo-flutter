package ir.directoo.directoo

import android.app.Activity
import android.content.Intent
import androidx.activity.ComponentActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import ir.cafebazaar.poolakey.Connection
import ir.cafebazaar.poolakey.ConnectionState
import ir.cafebazaar.poolakey.Payment
import ir.cafebazaar.poolakey.config.PaymentConfiguration
import ir.cafebazaar.poolakey.config.SecurityCheck
import ir.cafebazaar.poolakey.entity.PurchaseInfo
import ir.cafebazaar.poolakey.request.PurchaseRequest

/**
 * Cafe Bazaar Poolakey bridge. The published Flutter plugin still calls jcenter(),
 * which current Gradle removed, so the app talks to Poolakey directly.
 */
class FlavorBilling(private val activity: Activity) : MethodChannel.MethodCallHandler {
    private var payment: Payment? = null
    private var connection: Connection? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "connect" -> connect(call.argument<String>("rsaKey").orEmpty(), result)
            "purchase" -> purchase(
                call.argument<String>("sku").orEmpty(),
                call.argument<String>("payload").orEmpty(),
                result,
            )
            "consume" -> consume(call.argument<String>("token").orEmpty(), result)
            "purchases" -> purchases(result)
            else -> result.notImplemented()
        }
    }

    private fun connect(rsaKey: String, result: MethodChannel.Result) {
        val security = if (rsaKey.isBlank()) {
            SecurityCheck.Disable
        } else {
            SecurityCheck.Enable(rsaPublicKey = rsaKey)
        }
        val billing = Payment(activity, PaymentConfiguration(localSecurityCheck = security))
        payment = billing
        var replied = false
        connection = billing.connect {
            connectionSucceed {
                if (!replied) {
                    replied = true
                    result.success(null)
                }
            }
            connectionFailed {
                if (!replied) {
                    replied = true
                    result.error("CONNECT_FAILED", it.message ?: "اتصال به کافه‌بازار برقرار نشد.", null)
                }
            }
            disconnected { }
        }
    }

    private fun purchase(sku: String, payload: String, result: MethodChannel.Result) {
        val billing = connectedPayment(result) ?: return
        BazaarPurchaseActivity.start(activity, billing, sku, payload, result)
    }

    private fun consume(token: String, result: MethodChannel.Result) {
        val billing = connectedPayment(result) ?: return
        billing.consumeProduct(token) {
            consumeSucceed { result.success(true) }
            consumeFailed { result.error("CONSUME_FAILED", it.message ?: "مصرف خرید ناموفق بود.", null) }
        }
    }

    private fun purchases(result: MethodChannel.Result) {
        val billing = connectedPayment(result) ?: return
        billing.getPurchasedProducts {
            querySucceed { items -> result.success(items.map { it.toMap() }) }
            queryFailed { result.error("QUERY_FAILED", it.message ?: "دریافت خریدها ناموفق بود.", null) }
        }
    }

    private fun connectedPayment(result: MethodChannel.Result): Payment? {
        val billing = payment
        if (billing == null || connection?.getState() != ConnectionState.Connected) {
            result.error("NOT_CONNECTED", "اتصال به کافه‌بازار برقرار نیست.", null)
            return null
        }
        return billing
    }
}

class BazaarPurchaseActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState != null) {
            finish()
            return
        }
        val billing = payment
        val pending = result
        if (billing == null || pending == null) {
            finish()
            return
        }
        billing.purchaseProduct(
            activityResultRegistry,
            PurchaseRequest(productId = productId, payload = payload),
        ) {
            purchaseSucceed {
                pending.success(it.toMap())
                finish()
            }
            purchaseCanceled {
                pending.error("PURCHASE_CANCELLED", "خرید لغو شد.", null)
                finish()
            }
            purchaseFailed {
                pending.error("PURCHASE_FAILED", "خرید کافه‌بازار ناموفق بود.", null)
                finish()
            }
            failedToBeginFlow {
                pending.error("PURCHASE_FAILED", it.message ?: "شروع خرید ناموفق بود.", null)
                finish()
            }
            purchaseFlowBegan { }
        }
    }

    companion object {
        private var payment: Payment? = null
        private var result: MethodChannel.Result? = null
        private var productId: String = ""
        private var payload: String = ""

        fun start(
            activity: Activity,
            billing: Payment,
            sku: String,
            developerPayload: String,
            pending: MethodChannel.Result,
        ) {
            payment = billing
            result = pending
            productId = sku
            payload = developerPayload
            activity.startActivity(Intent(activity, BazaarPurchaseActivity::class.java))
        }
    }
}

private fun PurchaseInfo.toMap(): Map<String, Any?> = mapOf(
    "orderId" to orderId,
    "purchaseToken" to purchaseToken,
    "productId" to productId,
    "purchaseState" to purchaseState.toString(),
    "payload" to payload,
    "signedData" to originalJson,
    "signature" to dataSignature,
)
