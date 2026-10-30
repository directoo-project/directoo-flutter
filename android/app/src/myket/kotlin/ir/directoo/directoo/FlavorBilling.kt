package ir.directoo.directoo

import android.app.Activity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import ir.myket.billingclient.IabHelper
import ir.myket.billingclient.util.IabResult
import ir.myket.billingclient.util.Purchase

/**
 * Myket IabHelper bridge. Linked only into the myket flavor so it does not
 * clash with Poolakey's copy of IInAppBillingService.
 */
class FlavorBilling(private val activity: Activity) : MethodChannel.MethodCallHandler {
    private var helper: IabHelper? = null

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
        val billing = IabHelper(activity, rsaKey)
        billing.enableDebugLogging(false)
        helper = billing
        billing.startSetup { setup: IabResult ->
            if (setup.isSuccess) {
                result.success(null)
            } else {
                result.error("CONNECT_FAILED", setup.message ?: "اتصال به مایکت برقرار نشد.", null)
            }
        }
    }

    private fun purchase(sku: String, payload: String, result: MethodChannel.Result) {
        val billing = helper ?: return result.error("NOT_CONNECTED", "اتصال به مایکت برقرار نیست.", null)
        billing.launchPurchaseFlow(activity, sku, { purchaseResult: IabResult, purchase: Purchase? ->
            if (purchaseResult.isCancelled) {
                result.error("PURCHASE_CANCELLED", "خرید لغو شد.", null)
                return@launchPurchaseFlow
            }
            if (!purchaseResult.isSuccess || purchase == null || purchase.token.isNullOrBlank()) {
                result.error("PURCHASE_FAILED", purchaseResult.message ?: "خرید مایکت ناموفق بود.", null)
                return@launchPurchaseFlow
            }
            result.success(purchase.toMap())
        }, payload)
    }

    private fun consume(token: String, result: MethodChannel.Result) {
        val billing = helper ?: return result.error("NOT_CONNECTED", "اتصال به مایکت برقرار نیست.", null)
        billing.queryInventoryAsync(false, null) { queryResult: IabResult, inventory ->
            if (!queryResult.isSuccess || inventory == null) {
                result.error("CONSUME_FAILED", queryResult.message ?: "خرید برای مصرف پیدا نشد.", null)
                return@queryInventoryAsync
            }
            val purchase = inventory.allPurchases.firstOrNull { it.token == token }
            if (purchase == null) {
                result.success(true)
                return@queryInventoryAsync
            }
            billing.consumeAsync(purchase) { _: Purchase?, consumeResult: IabResult ->
                if (consumeResult.isSuccess) {
                    result.success(true)
                } else {
                    result.error("CONSUME_FAILED", consumeResult.message ?: "مصرف خرید ناموفق بود.", null)
                }
            }
        }
    }

    private fun purchases(result: MethodChannel.Result) {
        val billing = helper ?: return result.error("NOT_CONNECTED", "اتصال به مایکت برقرار نیست.", null)
        billing.queryInventoryAsync(false, null) { queryResult: IabResult, inventory ->
            if (!queryResult.isSuccess || inventory == null) {
                result.error("QUERY_FAILED", queryResult.message ?: "دریافت خریدها ناموفق بود.", null)
                return@queryInventoryAsync
            }
            result.success(inventory.allPurchases.filter { it.purchaseState == 0 }.map { it.toMap() })
        }
    }
}

private val IabResult.isCancelled: Boolean
    get() = response == 1 || response == -1005

private fun Purchase.toMap(): Map<String, Any?> = mapOf(
    "orderId" to orderId,
    "purchaseToken" to token,
    "productId" to sku,
    "purchaseState" to if (purchaseState == 0) "PURCHASED" else "REFUNDED",
    "payload" to developerPayload,
)
